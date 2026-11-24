import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:kashkool_core/kashkool_core.dart';

import '../../../core/config/supabase_bootstrap.dart';
import '../../../core/config/supabase_config.dart';

/// Tenant id of the signed-in profile.
final _certificateTenantIdProvider = FutureProvider<String?>((ref) async {
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
final _certificateStudentIdProvider = FutureProvider<String?>((ref) async {
  final tenant = await ref.watch(_certificateTenantIdProvider.future);
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

/// Certificates for the signed-in student.
final certificatesProvider = FutureProvider.autoDispose<List<CertificateModel>>(
  (ref) async {
    final tenant = await ref.watch(_certificateTenantIdProvider.future);
    final studentId = await ref.watch(_certificateStudentIdProvider.future);
    final client = SupabaseBootstrap.client;
    if (tenant == null || studentId == null) return const [];

    final data = await client
        .from('certificates')
        .select('*')
        .eq('tenant_id', tenant)
        .eq('student_id', studentId)
        .order('issued_at', ascending: false);

    return (data as List)
        .map((j) => CertificateModel.fromJson(j as Map<String, dynamic>))
        .toList();
  },
);

/// Notifier to issue a new certificate (staff only).
final issueCertificateNotifierProvider =
    StateNotifierProvider.autoDispose<IssueCertificateNotifier, AsyncValue<void>>(
  (ref) => IssueCertificateNotifier(ref),
);

class IssueCertificateNotifier extends StateNotifier<AsyncValue<void>> {
  IssueCertificateNotifier(this.ref) : super(const AsyncValue.data(null));

  final Ref ref;

  Future<void> issue({
    required String studentId,
    required String groupId,
    required String title,
    required String certificateNumber,
    DateTime? expiresAt,
    String createdBy = '',
  }) async {
    state = const AsyncValue.loading();
    try {
      final client = SupabaseBootstrap.client;
      final user = client.auth.currentUser;
      await client.rpc('issue_certificate', params: {
        'p_student_id': studentId,
        'p_group_id': groupId,
        'p_title': title,
        'p_certificate_number': certificateNumber,
        'p_expires_at': expiresAt?.toIso8601String(),
        'p_created_by': user?.id ?? createdBy,
      });
      state = const AsyncValue.data(null);
    } catch (error, stack) {
      state = AsyncValue.error(error, stack);
      rethrow;
    }
  }
}

/// Publicly verifies a certificate by ID or number.
/// Uses the Supabase REST API directly (anon key) so it can be called
/// without authentication (public verification page).
class CertificateVerificationService {
  CertificateVerificationService._();
  static final CertificateVerificationService instance =
      CertificateVerificationService._();

  Future<CertificateVerificationResult> verify({
    required String? certificateId,
    required String? certificateNumber,
  }) async {
    final url = Uri.parse(
      '${SupabaseConfig.url}/rest/v1/rpc/verify_certificate',
    );

    final body = <String, dynamic>{};
    if (certificateId != null) {
      body['p_certificate_id'] = certificateId;
    }
    if (certificateNumber != null) {
      body['p_certificate_number'] = certificateNumber;
    }

    final response = await http.post(
      url,
      headers: {
        'apikey': SupabaseConfig.anonKey,
        'Authorization': 'Bearer ${SupabaseConfig.anonKey}',
        'Content-Type': 'application/json',
        'Prefer': 'return=representation',
      },
      body: json.encode(body),
    );

    if (response.statusCode != 200) {
      return CertificateVerificationResult(
        valid: false,
        result: 'invalid',
        message: 'Verification failed: ${response.statusCode}',
      );
    }

    final jsonBody = json.decode(response.body) as Map<String, dynamic>;
    return CertificateVerificationResult.fromJson(jsonBody);
  }
}

final certificateVerificationServiceProvider =
    Provider<CertificateVerificationService>((ref) {
  return CertificateVerificationService.instance;
});