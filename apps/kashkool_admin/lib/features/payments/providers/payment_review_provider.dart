import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kashkool_core/kashkool_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../../core/config/supabase_bootstrap.dart';

/// Tenant id of the signed-in admin profile.
final adminTenantIdProvider = FutureProvider<String?>((ref) async {
  final client = SupabaseBootstrap.client;
  final user = client.auth.currentUser;
  if (user == null) return null;
  final data = await client
      .from('profiles')
      .select('tenant_id, role')
      .eq('id', user.id)
      .single();
  return data['tenant_id'] as String?;
});

/// Configured payment channels for the admin's tenant (teacher / center).
final paymentChannelsProvider = FutureProvider.autoDispose<List<PaymentChannelModel>>(
  (ref) async {
    final tenant = await ref.watch(adminTenantIdProvider.future);
    if (tenant == null) return const <PaymentChannelModel>[];
    final client = SupabaseBootstrap.client;
    final data = await client
        .from('payment_channels')
        .select('*')
        .eq('tenant_id', tenant)
        .order('name');
    return (data as List)
        .map((j) => PaymentChannelModel.fromJson(j as Map<String, dynamic>))
        .toList();
  },
);

/// Pending payment receipt submissions awaiting staff review.
final pendingSubmissionsProvider =
    FutureProvider.autoDispose<List<PaymentSubmissionModel>>((ref) async {
  final tenant = await ref.watch(adminTenantIdProvider.future);
  if (tenant == null) return const <PaymentSubmissionModel>[];
  final client = SupabaseBootstrap.client;
  final data = await client
      .from('payment_submissions')
      .select('*, payment_channels(*)')
      .eq('tenant_id', tenant)
      .eq('status', 'pending')
      .order('created_at', ascending: false);
  final rows = (data as List).cast<Map<String, dynamic>>();
  return rows
      .map((row) => _mergeChannel(row))
      .map((row) => PaymentSubmissionModel.fromJson(row))
      .toList();});

Map<String, dynamic> _mergeChannel(Map<String, dynamic> row) {
  final channel = row['payment_channels'];
  if (channel is Map<String, dynamic>) {
    return Map<String, dynamic>.from(row)
      ..['payment_channels'] = channel
      ..['channel_name'] = channel['name'];
  }
  return Map<String, dynamic>.from(row)..['channel_name'] = null;
}

/// Approve / reject payment receipt submissions and manage channels.
class PaymentOpsService {
  PaymentOpsService({sb.SupabaseClient? client}) : _client = client;

  sb.SupabaseClient? _client;

  sb.SupabaseClient get _supabase => _client ??= SupabaseBootstrap.client;

  /// Atomic staff-only approval: row lock, status flip, immutable ledger
  /// insert and activation of the linked enrollment/session/reservation.
  Future<void> approve(String submissionId, {String? note}) async {
    await _supabase.rpc('approve_payment_submission', params: {
      'p_submission_id': submissionId,
      'p_reviewer_uid': _supabase.auth.currentUser?.id,
      'p_note': note ?? '',
    });
  }

  /// Atomic staff-only rejection. A reason is mandatory.
  Future<void> reject(String submissionId, String reason) async {
    await _supabase.rpc('reject_payment_submission', params: {
      'p_submission_id': submissionId,
      'p_reviewer_uid': _supabase.auth.currentUser?.id,
      'p_reason': reason,
    });
  }

  /// Activate / deactivate a payment channel.
  Future<void> setChannelActive(String channelId, bool active) async {
    await _supabase
        .from('payment_channels')
        .update({'active': active})
        .eq('id', channelId);
  }

  /// Create a new payment channel (teacher / center setup).
  Future<void> addChannel({
    required String tenantId,
    required String name,
    required String channelType,
    required String accountRef,
    required int feePiasters,
    required int minAmountPiasters,
    required int maxAmountPiasters,
    bool active = true,
  }) async {
    await _supabase.from('payment_channels').insert({
      'id': 'pch-${DateTime.now().millisecondsSinceEpoch}',
      'tenant_id': tenantId,
      'name': name,
      'channel_type': channelType,
      'account_ref': accountRef,
      'fee_piasters': feePiasters,
      'min_amount_piasters': minAmountPiasters,
      'max_amount_piasters': maxAmountPiasters,
      'active': active,
      'created_at': DateTime.now().toUtc().toIso8601String(),
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    });
  }
}

final paymentOpsServiceProvider = Provider<PaymentOpsService>((ref) {
  return PaymentOpsService();
});
