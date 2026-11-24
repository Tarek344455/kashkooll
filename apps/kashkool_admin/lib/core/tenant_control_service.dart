import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import 'config/supabase_bootstrap.dart';

final tenantControlServiceProvider = Provider<TenantControlService>((ref) {
  return TenantControlService();
});

/// Live list of tenants, sorted by name on the client so no composite index
/// is required for a brand new project.
final tenantsStreamProvider = StreamProvider.autoDispose<List<TenantSummary>>(
  (ref) => ref.watch(tenantControlServiceProvider).watchTenants(),
);

/// Newest privileged actions, newest first.
final auditTrailProvider = StreamProvider.autoDispose<List<AuditEntry>>(
  (ref) => ref.watch(tenantControlServiceProvider).watchAuditTrail(),
);

class TenantSummary {
  const TenantSummary({
    required this.tenantId,
    required this.name,
    required this.subdomain,
    required this.isActive,
    required this.tier,
    this.expiresAt,
  });

  final String tenantId;
  final String name;
  final String subdomain;
  final bool isActive;
  final String tier;
  final DateTime? expiresAt;

  bool get isExpired =>
      expiresAt != null && expiresAt!.isBefore(DateTime.now());

  factory TenantSummary.fromRow(Map<String, dynamic> row) {
    return TenantSummary(
      tenantId: (row['id'] as String?) ?? (row['tenant_id'] as String?) ?? '',
      name: (row['name'] as String?) ?? '',
      subdomain: (row['subdomain'] as String?) ?? '',
      isActive: row['is_active'] != false,
      tier: (row['subscription_tier'] as String?) ?? 'free',
      expiresAt: _parseTime(row['subscription_expires_at']),
    );
  }

  static DateTime? _parseTime(Object? raw) {
    if (raw is DateTime) return raw;
    if (raw is String) return DateTime.tryParse(raw);
    return null;
  }
}

class AuditEntry {
  const AuditEntry({
    required this.id,
    required this.tenantId,
    required this.action,
    required this.details,
    required this.actorUid,
    this.createdAt,
  });

  final String id;
  final String tenantId;
  final String action;
  final String details;
  final String actorUid;
  final DateTime? createdAt;

  factory AuditEntry.fromRow(Map<String, dynamic> row) {
    return AuditEntry(
      id: (row['id'] as String?) ?? '',
      tenantId: (row['tenant_id'] as String?) ?? '',
      action: (row['action'] as String?) ?? 'unknown',
      details: (row['details'] as String?) ?? '',
      actorUid: (row['actor_uid'] as String?) ?? 'system',
      createdAt: TenantSummary._parseTime(row['created_at']),
    );
  }
}

/// Creates and freezes centres. Every privileged action runs through an RPC
/// that writes its own audit entry in the same database transaction.
class TenantControlService {
  TenantControlService({sb.SupabaseClient? client}) : _client = client;

  sb.SupabaseClient? _client;

  static const int _auditPageSize = 200;

  sb.SupabaseClient get _supabase => _client ??= SupabaseBootstrap.client;

  /// Realtime stream with an immediate authoritative snapshot.
  Stream<List<TenantSummary>> watchTenants() =>
      _watch<TenantSummary>('admin-tenants', 'tenants', _fetchTenants);

  Stream<List<AuditEntry>> watchAuditTrail() =>
      _watch<AuditEntry>('admin-audit', 'audit_logs', _fetchAuditTrail);

  Stream<List<T>> _watch<T>(
    String channelName,
    String table,
    Future<List<T>> Function() fetch,
  ) {
    sb.RealtimeChannel? channel;
    late final StreamController<List<T>> controller;
    controller = StreamController<List<T>>.broadcast(
      onListen: () async {
        channel = _supabase
            .channel(channelName)
            .onPostgresChanges(
              event: sb.PostgresChangeEvent.all,
              schema: 'public',
              table: table,
              callback: (_) async {
                if (controller.isClosed) return;
                try {
                  controller.add(await fetch());
                } catch (_) {
                  // The last snapshot stays visible; Riverpod shows the error
                  // on the next explicit retry.
                }
              },
            )
            ..subscribe();

        if (controller.isClosed) return;
        try {
          controller.add(await fetch());
        } catch (error) {
          controller.addError(error);
        }
      },
      onCancel: () {
        if (channel != null) _supabase.removeChannel(channel!);
      },
    );
    return controller.stream;
  }

  Future<List<TenantSummary>> _fetchTenants() async {
    final rows = await _supabase
        .from('tenants')
        .select()
        .order('name', ascending: true);
    final tenants = rows
        .map((row) => TenantSummary.fromRow(Map<String, dynamic>.from(row)))
        .toList();
    tenants.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return tenants;
  }

  Future<List<AuditEntry>> _fetchAuditTrail() async {
    final rows = await _supabase
        .from('audit_logs')
        .select()
        .order('created_at', ascending: false)
        .limit(_auditPageSize);
    final entries = rows
        .map((row) => AuditEntry.fromRow(Map<String, dynamic>.from(row)))
        .toList();
    entries.sort((a, b) {
      final aTime = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bTime = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bTime.compareTo(aTime);
    });
    return entries;
  }

  /// Creates a new centre/teacher tenant with default branding.
  Future<void> createTenant({
    required String tenantId,
    required String name,
    required String subdomain,
    required String accentColor,
    required String primaryColor,
  }) async {
    await _supabase.rpc('create_tenant', params: <String, dynamic>{
      'p_tenant_id': tenantId,
      'p_name': name,
      'p_subdomain': subdomain,
      'p_accent_color': accentColor,
      'p_primary_color': primaryColor,
    });
  }

  /// Freezes a tenant (billing issues / policy violation).
  Future<void> freezeTenant(String tenantId, {String reason = ''}) async {
    await _supabase.rpc('set_tenant_active', params: <String, dynamic>{
      'p_tenant_id': tenantId,
      'p_active': false,
      'p_reason': reason,
    });
  }

  /// Unfreezes a tenant.
  Future<void> unfreezeTenant(String tenantId, {String reason = ''}) async {
    await _supabase.rpc('set_tenant_active', params: <String, dynamic>{
      'p_tenant_id': tenantId,
      'p_active': true,
      'p_reason': reason,
    });
  }

  /// Updates the billing tier for a tenant.
  Future<void> updateSubscription({
    required String tenantId,
    required String tier,
    required DateTime expiresAt,
  }) async {
    await _supabase.rpc('update_tenant_subscription', params: <String, dynamic>{
      'p_tenant_id': tenantId,
      'p_tier': tier,
      'p_expires_at': expiresAt.toUtc().toIso8601String(),
    });
  }

  /// Short-lived support token used for read-only impersonation.
  String generateGhostToken(String tenantId, String impersonateUid) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'ghost-$tenantId-$impersonateUid-$timestamp';
  }
}
