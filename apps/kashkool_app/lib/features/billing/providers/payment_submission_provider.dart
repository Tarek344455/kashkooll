import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kashkool_core/kashkool_core.dart';

import '../../../core/config/supabase_bootstrap.dart';
import '../../../core/database/db_provider.dart';
import '../../../core/database/local_db.dart';

/// Tenant id of the signed-in profile.
final _paymentTenantIdProvider = FutureProvider<String?>((ref) async {
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

/// Active payment channels for the tenant of the signed-in user.
final paymentChannelsProvider = FutureProvider.autoDispose<List<PaymentChannelModel>>((ref) async {
  final tenant = await ref.watch(_paymentTenantIdProvider.future);
  if (tenant == null) return const [];
  final client = SupabaseBootstrap.client;
  final data = await client
      .from('payment_channels')
      .select('*')
      .eq('tenant_id', tenant)
      .eq('active', true)
      .order('name');
  return (data as List)
      .map((j) => PaymentChannelModel.fromJson(j as Map<String, dynamic>))
      .toList();
});

/// Payment submissions for the signed-in student, served from the offline
/// Drift cache first (local watch) and written through from the submit /
/// approve / reject flows so status tracking survives flaky mobile data.
final paymentSubmissionsProvider =
    StreamProvider.autoDispose<List<PaymentSubmissionModel>>((ref) async* {
  final tenant = await ref.watch(_paymentTenantIdProvider.future);
  final client = SupabaseBootstrap.client;
  final user = client.auth.currentUser;
  if (tenant == null || user == null) return;

  final student = await client
      .from('students')
      .select('id')
      .eq('tenant_id', tenant)
      .eq('user_id', user.id)
      .maybeSingle();
  final studentId = student?['id'] as String?;
  if (studentId == null) return;

  final db = ref.read(localDbProvider);
  final stream = db.watchAllPaymentSubmissions().map(
        (rows) => rows
            .where((r) => r.studentId == studentId)
            .map((r) => _submissionFromLocal(r))
            .toList(),
      );
  await for (final list in stream) {
    yield list;
  }
});

PaymentSubmissionModel _submissionFromLocal(LocalPaymentSubmission row) {
  return PaymentSubmissionModel(
    id: row.submissionId,
    tenantId: row.tenantId,
    studentId: row.studentId,
    channelId: row.channelId,
    amountPiasters: row.amountPiasters,
    senderReference: row.senderReference,
    receiptUrl: row.receiptUrl,
    status: _localStatus(row.status),
    createdAt: row.createdAt,
    updatedAt: row.createdAt,
  );
}

PaymentSubmissionStatus _localStatus(String? value) {
  switch (value) {
    case 'approved':
      return PaymentSubmissionStatus.approved;
    case 'rejected':
      return PaymentSubmissionStatus.rejected;
    default:
      return PaymentSubmissionStatus.pending;
  }
}

/// All pending submissions for staff review (tenant-scoped).
final pendingSubmissionsProvider = FutureProvider.autoDispose
    .family<List<PaymentSubmissionModel>, String>((ref, tenantId) async {
  final client = SupabaseBootstrap.client;
  final data = await client
      .from('payment_submissions')
      .select('*')
      .eq('tenant_id', tenantId)
      .eq('status', 'pending')
      .order('created_at', ascending: false);
  return (data as List)
      .map((j) => PaymentSubmissionModel.fromJson(j as Map<String, dynamic>))
      .toList();
});

/// Submit a payment receipt. Uploads the receipt to Supabase Storage
/// (private `receipts` bucket, short-lived signed URL) and inserts a pending
/// submission row.
class PaymentSubmissionNotifier extends StateNotifier<AsyncValue<void>> {
  PaymentSubmissionNotifier(this._ref) : super(const AsyncValue.data(null));

  final Ref _ref;

  Future<void> submit({
    required String channelId,
    required int amountPiasters,
    required String senderReference,
    required Uint8List receiptBytes,
    required String fileName,
  }) async {
    state = const AsyncValue.loading();
    try {
      final client = SupabaseBootstrap.client;
      final user = client.auth.currentUser;
      if (user == null) {
        state = AsyncValue.error(
          Exception('غير مصرح به: سجّل الدخول أولاً'),
          StackTrace.current,
        );
        return;
      }

      // Resolve the tenant id from the caller's profile.
      final profile = await client
          .from('profiles')
          .select('tenant_id')
          .eq('id', user.id)
          .single();
      final tenant = profile['tenant_id'] as String?;
      if (tenant == null) {
        state = AsyncValue.error(
          Exception('لا يوجد سنتر مرتبط بهذا الحساب'),
          StackTrace.current,
        );
        return;
      }

      // Resolve student id.
      final student = await client
          .from('students')
          .select('id')
          .eq('tenant_id', tenant)
          .eq('user_id', user.id)
          .maybeSingle();
      if (student == null) {
        state = AsyncValue.error(
          Exception('لا يوجد سجل طالب مرتبط بهذا الحساب في هذا السنتر'),
          StackTrace.current,
        );
        return;
      }
      final studentId = student['id'] as String;

      // Upload receipt to private bucket.
      final filePath = 'receipts/$tenant/$studentId/${DateTime.now().millisecondsSinceEpoch}_$fileName';
      await client.storage.from('receipts').uploadBinary(filePath, receiptBytes);

      // Get a short-lived signed URL (5 minutes).
      final receiptUrl = await client.storage
          .from('receipts')
          .createSignedUrl(filePath, 300);

      final id = 'sub-${DateTime.now().millisecondsSinceEpoch}';
      await client.from('payment_submissions').insert({
        'id': id,
        'tenant_id': tenant,
        'student_id': studentId,
        'channel_id': channelId,
        'amount_piasters': amountPiasters,
        'sender_reference': senderReference,
        'receipt_url': receiptUrl,
        'status': 'pending',
        'created_at': DateTime.now().toUtc().toIso8601String(),
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      });

      state = const AsyncValue.data(null);
      // Write-through to the offline Drift cache (syncStatus 'completed' once
      // the immutable server insert succeeded).
      await _ref.read(localDbProvider).insertPaymentSubmission(
            LocalPaymentSubmissionsCompanion.insert(
              submissionId: id,
              tenantId: tenant,
              studentId: studentId,
              channelId: channelId,
              amountPiasters: amountPiasters,
              senderReference: senderReference,
              receiptUrl: receiptUrl,
              status: 'pending',
              syncStatus: 'completed',
              createdAt: DateTime.now(),
            ),
          );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Approve a pending submission (staff only).
  Future<void> approve(String submissionId, {String? note}) async {
    state = const AsyncValue.loading();
    try {
      final client = SupabaseBootstrap.client;
      await client.rpc('approve_payment_submission', params: {
        'p_submission_id': submissionId,
        'p_reviewer_uid': client.auth.currentUser?.id,
        'p_note': note ?? '',
      });
      await _ref
          .read(localDbProvider)
          .updatePaymentSubmissionStatus(submissionId, 'approved');
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Reject a pending submission (staff only). Reason is required.
  Future<void> reject(String submissionId, String reason) async {
    state = const AsyncValue.loading();
    try {
      final client = SupabaseBootstrap.client;
      await client.rpc('reject_payment_submission', params: {
        'p_submission_id': submissionId,
        'p_reviewer_uid': client.auth.currentUser?.id,
        'p_reason': reason,
      });
      await _ref
          .read(localDbProvider)
          .updatePaymentSubmissionStatus(submissionId, 'rejected');
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final paymentSubmissionNotifierProvider =
    StateNotifierProvider<PaymentSubmissionNotifier, AsyncValue<void>>(
  (ref) => PaymentSubmissionNotifier(ref),
);
