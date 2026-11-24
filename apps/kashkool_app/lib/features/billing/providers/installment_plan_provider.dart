import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kashkool_core/kashkool_core.dart';

import '../../../core/config/supabase_bootstrap.dart';

/// Tenant id of the signed-in profile.
final _installmentTenantIdProvider = FutureProvider<String?>((ref) async {
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

/// Student id of the signed-in profile.
final _installmentStudentIdProvider = FutureProvider<String?>((ref) async {
  final tenant = await ref.watch(_installmentTenantIdProvider.future);
  final client = SupabaseBootstrap.client;
  final user = client.auth.currentUser;
  if (tenant == null || user == null) return null;
  final student = await client
      .from('students')
      .select('id')
      .eq('tenant_id', tenant)
      .eq('user_id', user.id)
      .maybeSingle();
  return student?['id'] as String?;
});

/// Installment plans for the signed-in student.
final installmentPlansProvider =
    FutureProvider.autoDispose<List<InstallmentPlanModel>>((ref) async {
  final tenant = await ref.watch(_installmentTenantIdProvider.future);
  final studentId = await ref.watch(_installmentStudentIdProvider.future);
  final client = SupabaseBootstrap.client;
  if (tenant == null || studentId == null) return const [];

  final data = await client
      .from('installment_plans')
      .select('*')
      .eq('tenant_id', tenant)
      .eq('student_id', studentId)
      .order('created_at', ascending: false);

  return (data as List)
      .map((j) => InstallmentPlanModel.fromJson(j as Map<String, dynamic>))
      .toList();
});

/// Installment payments for a specific plan.
final installmentPaymentsProvider =
    FutureProvider.family<List<InstallmentPaymentModel>, String>((ref, planId) async {
  final tenant = await ref.watch(_installmentTenantIdProvider.future);
  final client = SupabaseBootstrap.client;
  if (tenant == null) return const [];

  final data = await client
      .from('installment_payments')
      .select('*')
      .eq('tenant_id', tenant)
      .eq('plan_id', planId)
      .order('due_date', ascending: true);

  return (data as List)
      .map((j) => InstallmentPaymentModel.fromJson(j as Map<String, dynamic>))
      .toList();
});

/// Notifier to create a new installment plan (staff only).
final createInstallmentPlanNotifierProvider =
    StateNotifierProvider.autoDispose<CreateInstallmentPlanNotifier, AsyncValue<void>>(
  (ref) => CreateInstallmentPlanNotifier(ref),
);

class CreateInstallmentPlanNotifier extends StateNotifier<AsyncValue<void>> {
  CreateInstallmentPlanNotifier(this.ref) : super(const AsyncValue.data(null));

  final Ref ref;

  Future<void> create({
    required String studentId,
    required String? groupId,
    required int totalAmountPiasters,
    required int numberOfInstallments,
    required DateTime startDate,
    required DateTime endDate,
    String description = '',
  }) async {
    state = const AsyncValue.loading();
    try {
      final client = SupabaseBootstrap.client;
      final user = client.auth.currentUser;
      await client.rpc('create_installment_plan', params: {
        'p_student_id': studentId,
        'p_group_id': groupId,
        'p_total_amount_piasters': totalAmountPiasters,
        'p_number_of_installments': numberOfInstallments,
        'p_start_date': startDate.toIso8601String(),
        'p_end_date': endDate.toIso8601String(),
        'p_description': description,
        'p_created_by': user?.id,
      });
      state = const AsyncValue.data(null);
    } catch (error, stack) {
      state = AsyncValue.error(error, stack);
      rethrow;
    }
  }
}

/// Notifier to record an installment payment (staff only).
final recordInstallmentPaymentNotifierProvider =
    StateNotifierProvider.autoDispose<RecordInstallmentPaymentNotifier, AsyncValue<void>>(
  (ref) => RecordInstallmentPaymentNotifier(ref),
);

class RecordInstallmentPaymentNotifier extends StateNotifier<AsyncValue<void>> {
  RecordInstallmentPaymentNotifier(this.ref) : super(const AsyncValue.data(null));

  final Ref ref;

  Future<void> record({
    required String paymentId,
    required int amountPiasters,
    String? submissionId,
    String note = '',
  }) async {
    state = const AsyncValue.loading();
    try {
      final client = SupabaseBootstrap.client;
      final user = client.auth.currentUser;
      await client.rpc('record_installment_payment', params: {
        'p_payment_id': paymentId,
        'p_amount_piasters': amountPiasters,
        'p_submission_id': submissionId,
        'p_reviewer_uid': user?.id,
        'p_note': note,
      });
      state = const AsyncValue.data(null);
    } catch (error, stack) {
      state = AsyncValue.error(error, stack);
      rethrow;
    }
  }
}
