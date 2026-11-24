import 'package:flutter/foundation.dart';
import 'package:kashkool_core/kashkool_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../../core/config/supabase_config.dart';
import '../../../core/security/device_guard.dart';

/// Failure reasons the UI translates. The repository never returns copy.
enum AuthErrorCode {
  invalidPhone,
  invalidEmail,
  invalidCode,
  invalidQrCode,
  tooManyRequests,
  quotaExceeded,
  network,
  notLinked,
  deviceLocked,
  notConfigured,
  unknown,
}

/// Everything a verified session needs before the app can route the user.
class SignInOutcome {
  const SignInOutcome({
    required this.tenantId,
    required this.role,
    required this.fingerprint,
  });

  final String tenantId;
  final String role;
  final String fingerprint;
}

/// Phone (OTP) sign-in plus hardware binding, backed by Supabase Auth/Postgres.
///
/// `profiles.role` and `profiles.tenant_id` replace provider-specific claims.
/// A user without a tenant has not been enrolled by any centre yet. The
/// `bind_device` RPC claims the hardware on first sign-in and refuses later
/// sign-ins from a different phone.
class AuthRepository {
  AuthRepository({sb.SupabaseClient? client}) : _client = client;

  sb.SupabaseClient? _client;
  String? _phone;
  String? _email;

  sb.SupabaseClient get _supabase => _client ??= sb.Supabase.instance.client;

  /// Phone number of the signed-in account, if there is one.
  String? get currentPhoneNumber {
    if (!SupabaseConfig.isConfigured) return null;
    try {
      return _supabase.auth.currentUser?.phone;
    } catch (_) {
      return null;
    }
  }

  /// Email address of the signed-in account, if there is one.
  String? get currentEmail {
    if (!SupabaseConfig.isConfigured) return null;
    try {
      return _supabase.auth.currentUser?.email;
    } catch (_) {
      return null;
    }
  }

  /// Starts the OTP flow. Supabase delivers the SMS asynchronously; the code
  /// is entered in the UI and exchanged through [confirmCode].
  Future<void> requestCode({
    required String phone,
    required void Function() onCodeSent,
    required void Function(SignInOutcome outcome) onSignedIn,
    required void Function(AuthErrorCode code) onError,
  }) async {
    final normalized = EgyptValidators.normalizeEgyptianPhone(phone);
    if (normalized.isEmpty) {
      onError(AuthErrorCode.invalidPhone);
      return;
    }
    final issue = SupabaseConfig.validationError;
    if (issue != null) {
      onError(AuthErrorCode.notConfigured);
      return;
    }

    _phone = normalized;
    try {
      await _supabase.auth.signInWithOtp(phone: normalized);
      onCodeSent();
    } on Object catch (error) {
      onError(_mapException(error));
    }
  }

  /// Starts the OTP flow via email (Zero-Cost, no SMS gateway required).
  /// Supabase delivers the email asynchronously; the code is entered in the UI
  /// and exchanged through [confirmCodeByEmail].
  Future<void> requestCodeByEmail({
    required String email,
    required void Function() onCodeSent,
    required void Function(SignInOutcome outcome) onSignedIn,
    required void Function(AuthErrorCode code) onError,
  }) async {
    final trimmed = email.trim().toLowerCase();
    if (trimmed.isEmpty || !trimmed.contains('@')) {
      onError(AuthErrorCode.invalidEmail);
      return;
    }
    final issue = SupabaseConfig.validationError;
    if (issue != null) {
      onError(AuthErrorCode.notConfigured);
      return;
    }

    _email = trimmed;
    try {
      await _supabase.auth.signInWithOtp(email: trimmed);
      onCodeSent();
    } on Object catch (error) {
      onError(_mapException(error));
    }
  }

  /// Exchanges the SMS code for a bound session.
  Future<SignInOutcome> confirmCode(String code) async {
    final phone = _phone;
    if (phone == null || phone.isEmpty) {
      throw StateError('Request a verification code first.');
    }
    final issue = SupabaseConfig.validationError;
    if (issue != null) {
      throw const AuthRepositoryException(AuthErrorCode.notConfigured);
    }

    try {
      await _supabase.auth.verifyOTP(
        type: sb.OtpType.sms,
        phone: phone,
        token: code.trim(),
      );
      return await _completeSignIn();
    } on AuthRepositoryException {
      rethrow;
    } on NotLinkedException {
      throw const AuthRepositoryException(AuthErrorCode.notLinked);
    } on DeviceSecurityException {
      throw const AuthRepositoryException(AuthErrorCode.deviceLocked);
    } on Object catch (error) {
      throw AuthRepositoryException(_mapException(error));
    }
  }

  /// Exchanges the email OTP code for a bound session.
  Future<SignInOutcome> confirmCodeByEmail(String code) async {
    final email = _email;
    if (email == null || email.isEmpty) {
      throw StateError('Request an email verification code first.');
    }
    final issue = SupabaseConfig.validationError;
    if (issue != null) {
      throw const AuthRepositoryException(AuthErrorCode.notConfigured);
    }

    try {
      await _supabase.auth.verifyOTP(
        type: sb.OtpType.email,
        email: email,
        token: code.trim(),
      );
      return await _completeSignIn();
    } on AuthRepositoryException {
      rethrow;
    } on NotLinkedException {
      throw const AuthRepositoryException(AuthErrorCode.notLinked);
    } on DeviceSecurityException {
      throw const AuthRepositoryException(AuthErrorCode.deviceLocked);
    } on Object catch (error) {
      throw AuthRepositoryException(_mapException(error));
    }
  }

  Future<void> signOut() async {
    _phone = null;
    _email = null;
    if (!SupabaseConfig.isConfigured) return;
    await _supabase.auth.signOut();
  }

  /// Activates a student/parent account using a QR activation code generated
  /// locally by the centre secretary. Zero-Cost: no SMS, no email, pure
  /// local verification against the `profiles` table.
  Future<SignInOutcome> activateWithQrCode({
    required String qrCode,
    required String phone,
  }) async {
    final normalized = EgyptValidators.normalizeEgyptianPhone(phone);
    if (normalized.isEmpty) {
      throw const AuthRepositoryException(AuthErrorCode.invalidPhone);
    }
    final issue = SupabaseConfig.validationError;
    if (issue != null) {
      throw const AuthRepositoryException(AuthErrorCode.notConfigured);
    }

    _phone = normalized;
    try {
      // Validate the QR code against the profiles table (centre-generated).
      final row = await _supabase
          .from('profiles')
          .select('id, tenant_id, role, qr_activation_code, qr_activated_at')
          .eq('phone', normalized)
          .eq('qr_activation_code', qrCode.trim())
          .maybeSingle();

      if (row == null) {
        throw const AuthRepositoryException(AuthErrorCode.invalidQrCode);
      }

      // Ensure the QR code hasn't been used already.
      if (row['qr_activated_at'] != null) {
        throw const AuthRepositoryException(AuthErrorCode.invalidQrCode);
      }

      final uid = row['id'] as String;
      final tenantId = row['tenant_id'] as String?;
      final role = (row['role'] as String?) ?? 'student';

      // Mark the QR as used.
      await _supabase
          .from('profiles')
          .update({'qr_activated_at': DateTime.now().toIso8601String()})
          .eq('id', uid);

      // Sign in via OTP using the phone (Supabase will find existing user).
      await _supabase.auth.signInWithOtp(phone: normalized);

      final fingerprint = await _currentFingerprint();
      await _bindDevice(uid, tenantId ?? '', fingerprint);

      return SignInOutcome(
        tenantId: tenantId ?? '',
        role: role,
        fingerprint: fingerprint,
      );
    } on AuthRepositoryException {
      rethrow;
    } on NotLinkedException {
      throw const AuthRepositoryException(AuthErrorCode.notLinked);
    } on DeviceSecurityException {
      throw const AuthRepositoryException(AuthErrorCode.deviceLocked);
    } on Object catch (error) {
      throw AuthRepositoryException(_mapException(error));
    }
  }

  /// Re-reads the profile for an already signed-in user, e.g. after a centre
  /// enrolled them. Returns null while the account is still unassigned.
  Future<SignInOutcome?> refreshEnrollment() async {
    if (!SupabaseConfig.isConfigured) return null;
    final user = _supabase.auth.currentUser;
    if (user == null) return null;
    _phone = user.phone;
    _email = user.email;

    final profile = await _readProfile(user.id);
    final tenantId = profile.$1;
    if (tenantId == null || tenantId.isEmpty || tenantId == 'unassigned') {
      return null;
    }

    final fingerprint = await _currentFingerprint();
    await _bindDevice(user.id, tenantId, fingerprint);
    _phone = user.phone;
    _email = user.email;

    return SignInOutcome(
      tenantId: tenantId,
      role: profile.$2,
      fingerprint: fingerprint,
    );
  }

  /// Hardware fingerprint for this session, empty on the web.
  ///
  /// A browser has no stable hardware identifier to bind to, and pretending it
  /// does would lock users out on every cache clear. Installed apps keep the
  /// anti-sharing lock; web sessions are secured by the token and RLS.
  Future<String> _currentFingerprint() async {
    if (kIsWeb) return '';
    return DeviceGuard.currentFingerprint();
  }

  Future<SignInOutcome> _completeSignIn() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw const AuthRepositoryException(AuthErrorCode.unknown);
    }

    final profile = await _readProfile(user.id);
    final tenantId = profile.$1;
    if (tenantId == null || tenantId.isEmpty || tenantId == 'unassigned') {
      throw const NotLinkedException();
    }

    final fingerprint = await _currentFingerprint();
    await _bindDevice(user.id, tenantId, fingerprint);

    return SignInOutcome(
      tenantId: tenantId,
      role: profile.$2,
      fingerprint: fingerprint,
    );
  }

  /// Role and tenant from the profile row — the Supabase equivalent of
  /// the old provider's token claims.
  Future<(String?, String)> _readProfile(String uid) async {
    try {
      final row = await _supabase
          .from('profiles')
          .select('role,tenant_id')
          .eq('id', uid)
          .maybeSingle();
      if (row == null) return (null, 'student');
      return (
        row['tenant_id'] as String?,
        (row['role'] as String?) ?? 'student',
      );
    } on Object catch (error) {
      debugPrint('AuthRepository: profile read failed: $error');
      return (null, 'student');
    }
  }

  /// First sign-in claims the hardware; later sign-ins must match it.
  Future<void> _bindDevice(String uid, String tenantId, String fingerprint) async {
    try {
      final result = await _supabase.rpc('bind_device', params: <String, dynamic>{
        'p_tenant_id': tenantId,
        'p_fingerprint': fingerprint,
      });
      final status = result is Map ? result['status'] as String? : null;
      if (status == 'not_linked') throw const NotLinkedException();
      if (status == 'locked') {
        await _supabase.auth.signOut();
        throw const DeviceSecurityException(
          'This account is locked to another device. Contact your centre.',
        );
      }
    } on NotLinkedException {
      rethrow;
    } on DeviceSecurityException {
      rethrow;
    } on Object catch (error) {
      debugPrint('AuthRepository: device binding failed: $error');
      throw const AuthRepositoryException(AuthErrorCode.network);
    }
  }

  AuthErrorCode _mapException(Object error) {
    if (error is sb.AuthException) {
      final code = (error.code ?? '').toLowerCase();
      final message = error.message.toLowerCase();
      final status = int.tryParse(error.statusCode ?? '');
      if (status == 429 || code.contains('rate_limit')) {
        return AuthErrorCode.tooManyRequests;
      }
      if (code.contains('sms_provider_disabled') ||
          code.contains('email_provider_disabled') ||
          code.contains('configuration_not_found') ||
          code.contains('signups_not_enabled') ||
          message.contains('provider is not enabled') ||
          (status == 500 && message.contains('sms'))) {
        return AuthErrorCode.notConfigured;
      }
      if (code.contains('quota') || message.contains('quota')) {
        return AuthErrorCode.quotaExceeded;
      }
      if (code.contains('invalid') ||
          code.contains('expired') ||
          code.contains('otp')) {
        return AuthErrorCode.invalidCode;
      }
      if (code.contains('network') || message.contains('network')) {
        return AuthErrorCode.network;
      }
    }
    if (error is sb.PostgrestException) {
      return error.code == 'P0002'
          ? AuthErrorCode.notLinked
          : AuthErrorCode.unknown;
    }
    final text = error.toString().toLowerCase();
    if (text.contains('socket') ||
        text.contains('clientexception') ||
        text.contains('connection')) {
      return AuthErrorCode.network;
    }
    return AuthErrorCode.unknown;
  }
}

class AuthRepositoryException implements Exception {
  const AuthRepositoryException(this.code);

  final AuthErrorCode code;

  @override
  String toString() => 'AuthRepositoryException($code)';
}

class NotLinkedException implements Exception {
  const NotLinkedException();

  @override
  String toString() => 'NotLinkedException';
}
