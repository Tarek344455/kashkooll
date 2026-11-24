/// Feature Flag Service - evaluates flags per account subscription
/// Works offline-first with local cache, syncs with server

library feature_flag_service;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kashkool_core/kashkool_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import '../database/local_db.dart';
import '../database/db_provider.dart';
import 'network_client.dart';
import 'platform_gateways.dart';

final featureFlagServiceProvider = Provider<FeatureFlagService>((ref) {
  return FeatureFlagService(
    localDb: ref.read(localDbProvider),
    networkClient: ref.read(billingNetworkClientProvider),
    platformGateways: ref.read(platformGatewaysProvider),
  );
});

class FeatureFlagService {
  final LocalDb localDb;
  final BillingNetworkClient networkClient;
  final PlatformGateways platformGateways;

  /// Session cache. Supabase already keeps its own offline cache; this map
  /// avoids re-reading the same row for every flag lookup on a screen.
  final Map<String, AccountSubscription> _cache = <String, AccountSubscription>{};

  FeatureFlagService({
    required this.localDb,
    required this.networkClient,
    required this.platformGateways,
  });

  /// Check if a feature is enabled for the current account.
  ///
  /// A missing subscription means the account has not bought any paid module:
  /// the flag catalogue's free-tier default is the correct answer, not a
  /// blanket `false` that would hide every feature.
  Future<bool> isEnabled(String flagKey, {String? accountId}) async {
    final subscription = await _getSubscription(accountId);
    if (subscription == null) {
      return FeatureFlags.getFlag(flagKey)?.defaultEnabled ?? false;
    }
    return subscription.isFeatureEnabled(flagKey);
  }

  /// Check multiple flags at once
  Future<Map<String, bool>> areEnabled(List<String> flagKeys, {String? accountId}) async {
    final subscription = await _getSubscription(accountId);
    if (subscription == null) {
      return {
        for (final key in flagKeys)
          key: FeatureFlags.getFlag(key)?.defaultEnabled ?? false,
      };
    }
    return {for (final key in flagKeys) key: subscription.isFeatureEnabled(key)};
  }

  /// Get all enabled flags for current account
  Future<Set<String>> getEnabledFlags({String? accountId}) async {
    final subscription = await _getSubscription(accountId);

    final enabled = <String>{};
    for (final flag in FeatureFlags.getAllFlags().values) {
      final isOn = subscription == null
          ? flag.defaultEnabled
          : subscription.isFeatureEnabled(flag.key);
      if (isOn) enabled.add(flag.key);
    }
    return enabled;
  }

  /// Get subscription for account (from local cache or Supabase)
  Future<AccountSubscription?> _getSubscription(String? accountId) async {
    final cached = await _getCachedSubscription(accountId);
    if (cached != null && !_isStale(cached)) {
      return cached;
    }

    try {
      final fetched = await _fetchSubscriptionFromServer(accountId);
      if (fetched != null) {
        await _cacheSubscription(fetched, accountId: accountId);
        return fetched;
      }
    } catch (error) {
      debugPrint('FeatureFlagService: subscription fetch failed: $error');
    }

    return cached;
  }

  /// Reads the `subscriptions` row the billing edge functions write. Returns
  /// null when the account has no subscription yet (free-tier defaults apply).
  Future<AccountSubscription?> _fetchSubscriptionFromServer(String? accountId) async {
    final targetId = accountId ?? await _getCurrentAccountId();
    if (targetId == null || targetId.isEmpty) return null;

    try {
      final row = await sb.Supabase.instance.client
          .from('subscriptions')
          .select()
          .eq('account_id', targetId)
          .maybeSingle();
      if (row == null) return null;
      return AccountSubscription.fromJson(_mapSubscription(row));
    } on sb.PostgrestException catch (error) {
      debugPrint('FeatureFlagService: Supabase ${error.code}: ${error.message}');
      return null;
    } catch (error) {
      debugPrint('FeatureFlagService: subscription fetch failed: $error');
      return null;
    }
  }

  /// The PostgREST row uses snake_case; the core model speaks camelCase.
  Map<String, dynamic> _mapSubscription(Map<String, dynamic> row) {
    final modules = (row['active_modules'] as List?) ?? const <dynamic>[];
    final usage = (row['usage_counters'] as Map?) ?? const <dynamic, dynamic>{};
    final overrides = (row['feature_overrides'] as Map?) ?? const <dynamic, dynamic>{};
    return <String, dynamic>{
      'accountId': row['account_id'],
      'accountType': row['account_type'] ?? 'center',
      'activeModules': modules.map((e) => e.toString()).toList(),
      'billingCycle': row['billing_cycle'] ?? 'monthly',
      'expiresAt': row['expires_at'],
      'promoCode': row['promo_code'],
      'usageCounters': Map<String, int>.from(
        usage.map((key, value) => MapEntry(key.toString(), (value as num).round())),
      ),
      'featureOverrides': Map<String, bool>.from(
        overrides.map((key, value) => MapEntry(key.toString(), value == true)),
      ),
      'createdAt': row['created_at'] ?? DateTime.now().toIso8601String(),
      'updatedAt': row['updated_at'] ?? DateTime.now().toIso8601String(),
    };
  }

  /// Current account id: the profile tenant when present (billing is per
  /// centre), otherwise the signed-in user id.
  Future<String?> _getCurrentAccountId() async {
    try {
      final client = sb.Supabase.instance.client;
      final user = client.auth.currentUser;
      if (user == null) return null;
      final profile = await client
          .from('profiles')
          .select('tenant_id')
          .eq('id', user.id)
          .maybeSingle();
      final tenantId = profile?['tenant_id'] as String?;
      if (tenantId != null && tenantId.isNotEmpty) return tenantId;
      return user.id;
    } catch (_) {
      return null;
    }
  }

  /// Check if cached subscription is stale (> 1 hour)
  bool _isStale(AccountSubscription sub) {
    return DateTime.now().difference(sub.updatedAt).inHours > 1;
  }

  /// Cache subscription for this session
  Future<void> _cacheSubscription(AccountSubscription sub, {String? accountId}) async {
    final key = accountId ?? await _getCurrentAccountId() ?? '__default__';
    _cache[key] = sub;
  }

  /// Get cached subscription
  Future<AccountSubscription?> _getCachedSubscription(String? accountId) async {
    final key = accountId ?? await _getCurrentAccountId() ?? '__default__';
    return _cache[key];
  }

  /// Increment usage counter for metered billing
  Future<void> incrementUsage(String meterKey, {int count = 1, String? accountId}) async {
    final subscription = await _getSubscription(accountId);
    if (subscription == null) return;

    final newCounters = Map<String, int>.from(subscription.usageCounters);
    newCounters[meterKey] = (newCounters[meterKey] ?? 0) + count;

    final updated = subscription.copyWith(
      usageCounters: newCounters,
      updatedAt: DateTime.now(),
    );

    await _cacheSubscription(updated, accountId: accountId);
    await _syncUsageToServer(updated, accountId);
  }

  /// Usage counters are metered by the billing edge functions from the
  /// authoritative ledger. A client-side counter is only a local estimate and
  /// must never overwrite server numbers, so nothing is pushed from here.
  Future<void> _syncUsageToServer(AccountSubscription sub, String? accountId) async {
    debugPrint(
      'FeatureFlagService: local usage counters updated; '
      'server meters usage from ledger events.',
    );
  }

  /// Activate a module for account
  Future<bool> activateModule(ModuleId moduleId, {String? accountId, String? promoCode}) async {
    final subscription = await _getSubscription(accountId);
    if (subscription == null) return false;

    if (subscription.activeModules.contains(moduleId)) return true;

    final newModules = Set<ModuleId>.from(subscription.activeModules)..add(moduleId);
    final updated = subscription.copyWith(
      activeModules: newModules,
      promoCode: promoCode ?? subscription.promoCode,
      updatedAt: DateTime.now(),
    );

    await _cacheSubscription(updated);
    return await _syncSubscriptionToServer(updated, accountId);
  }

  /// Deactivate a module
  Future<bool> deactivateModule(ModuleId moduleId, {String? accountId}) async {
    final subscription = await _getSubscription(accountId);
    if (subscription == null) return false;

    if (!subscription.activeModules.contains(moduleId)) return true;

    final newModules = Set<ModuleId>.from(subscription.activeModules)..remove(moduleId);
    final updated = subscription.copyWith(
      activeModules: newModules,
      updatedAt: DateTime.now(),
    );

    await _cacheSubscription(updated);
    return await _syncSubscriptionToServer(updated, accountId);
  }

  /// Change billing cycle
  Future<bool> changeBillingCycle(BillingCycle cycle, {String? accountId}) async {
    final subscription = await _getSubscription(accountId);
    if (subscription == null) return false;

    final updated = subscription.copyWith(
      billingCycle: cycle,
      updatedAt: DateTime.now(),
    );

    await _cacheSubscription(updated);
    return await _syncSubscriptionToServer(updated, accountId);
  }

  /// Subscription rows are written only by the billing edge functions
  /// (payment webhooks and admin jobs). The client is read-only by design, so
  /// a local change cannot be published from here.
  Future<bool> _syncSubscriptionToServer(AccountSubscription sub, String? accountId) async {
    debugPrint(
      'FeatureFlagService: subscription changes are server-owned; '
      'complete the purchase through the billing flow.',
    );
    return false;
  }

  /// Calculate current monthly cost
  Future<double> getMonthlyCost({String? accountId}) async {
    final subscription = await _getSubscription(accountId);
    return subscription?.calculateMonthlyCost() ?? 0.0;
  }

  /// Get available modules for account type
  List<ModulePricing> getAvailableModules(AccountType accountType) {
    return PricingCatalog.getModulesForAccountType(accountType);
  }

  /// Validate promo code
  PromoCode? validatePromoCode(String code, {AccountType? accountType, ModuleId? moduleId}) {
    final promo = PromoCatalog.getPromo(code);
    if (promo == null) return null;
    if (!promo.isValid(accountType: accountType, moduleId: moduleId)) return null;
    return promo;
  }

  /// Apply promo code to subscription
  Future<bool> applyPromoCode(String code, {String? accountId}) async {
    final subscription = await _getSubscription(accountId);
    if (subscription == null) return false;

    final promo = validatePromoCode(code, accountType: subscription.accountType);
    if (promo == null) return false;

    final updated = subscription.copyWith(
      promoCode: code,
      updatedAt: DateTime.now(),
    );

    await _cacheSubscription(updated);
    return await _syncSubscriptionToServer(updated, accountId);
  }

  /// Get feature flag metadata
  FeatureFlag? getFlagInfo(String key) => FeatureFlags.getFlag(key);

  /// Get all flags for a module
  List<FeatureFlag> getFlagsForModule(ModuleId moduleId) => FeatureFlags.getFlagsForModule(moduleId);
}

/// Riverpod providers for easy UI access
final featureFlagProvider = FutureProvider.family<bool, String>((ref, flagKey) async {
  final service = ref.read(featureFlagServiceProvider);
  return service.isEnabled(flagKey);
});

final enabledFlagsProvider = FutureProvider<Set<String>>((ref) async {
  final service = ref.read(featureFlagServiceProvider);
  return service.getEnabledFlags();
});

final monthlyCostProvider = FutureProvider<double>((ref) async {
  final service = ref.read(featureFlagServiceProvider);
  return service.getMonthlyCost();
});

final availableModulesProvider = Provider.family<List<ModulePricing>, AccountType>((ref, accountType) {
  final service = ref.read(featureFlagServiceProvider);
  return service.getAvailableModules(accountType);
});