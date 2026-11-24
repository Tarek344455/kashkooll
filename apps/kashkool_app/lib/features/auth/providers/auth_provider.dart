import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kashkool_core/kashkool_core.dart';

import '../../../core/config/supabase_bootstrap.dart';
import '../../../core/security/device_guard.dart';
import '../data/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.watch(authRepositoryProvider));
});

enum AuthStatus {
  /// Nothing requested yet: the phone/email form is showing.
  initial,

  /// OTP request in flight (phone or email).
  sendingCode,

  /// Code delivered: the OTP form is showing.
  codeSent,

  /// Email OTP request in flight.
  emailSent,

  /// Code submitted, waiting for Supabase Auth to confirm.
  verifying,

  /// Email code submitted, waiting for Supabase Auth to confirm.
  verifyingEmail,

  /// QR code activated locally by the centre secretary.
  qrActivated,

  /// Signed in and bound to a centre.
  onboarded,

  /// Signed in, but no centre has enrolled this number yet.
  notLinked,
}

class AuthState {
  const AuthState({
    this.status = AuthStatus.initial,
    this.phone = '',
    this.email = '',
    this.tenantId,
    this.role,
    this.fingerprint,
    this.errorCode,
  });

  final AuthStatus status;
  final String phone;
  final String email;
  final String? tenantId;
  final String? role;
  final String? fingerprint;
  final AuthErrorCode? errorCode;

  bool get isBusy =>
      status == AuthStatus.sendingCode ||
      status == AuthStatus.emailSent ||
      status == AuthStatus.verifying ||
      status == AuthStatus.verifyingEmail;

  static const AuthState initial = AuthState();
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._repository) : super(AuthState.initial) {
    _restoreSession();
  }

  final AuthRepository _repository;

  /// Restores an existing Supabase session on cold start.
  ///
  /// Without this the app always demanded a fresh SMS code, even though the
  /// user was still signed in and already bound to a centre.
  Future<void> _restoreSession() async {
    if (!SupabaseBootstrap.isReady) return;
    try {
      final outcome = await _repository.refreshEnrollment();
      if (!mounted || outcome == null) return;
      state = _onboarded(
        outcome,
        _repository.currentPhoneNumber ?? '',
        email: _repository.currentEmail ?? '',
      );
    } catch (_) {
      // No restorable session: keep the phone/email form.
    }
  }

  /// Requests a one-time code for [phone]. Invalid numbers never hit Supabase.
  Future<void> requestCode(String phone) async {
    final normalized = EgyptValidators.normalizeEgyptianPhone(phone.trim());
    if (normalized.isEmpty) {
      state = const AuthState(errorCode: AuthErrorCode.invalidPhone);
      return;
    }

    state = AuthState(status: AuthStatus.sendingCode, phone: normalized);

    await _repository.requestCode(
      phone: normalized,
      onCodeSent: () {
        if (!mounted) return;
        state = AuthState(status: AuthStatus.codeSent, phone: normalized);
      },
      onSignedIn: (outcome) {
        if (!mounted) return;
        state = _onboarded(outcome, normalized);
      },
      onError: (code) {
        if (!mounted) return;
        if (code == AuthErrorCode.notLinked) {
          state = AuthState(status: AuthStatus.notLinked, phone: normalized);
          return;
        }
        state = AuthState(
          status: code == AuthErrorCode.invalidPhone
              ? AuthStatus.initial
              : AuthStatus.codeSent,
          phone: normalized,
          errorCode: code,
        );
      },
    );
  }

  /// Requests a one-time code via email (Zero-Cost, no SMS gateway).
  Future<void> requestCodeByEmail(String email) async {
    final trimmed = email.trim().toLowerCase();
    if (trimmed.isEmpty || !trimmed.contains('@')) {
      state = const AuthState(errorCode: AuthErrorCode.invalidEmail);
      return;
    }

    state = AuthState(
      status: AuthStatus.emailSent,
      phone: state.phone,
      email: trimmed,
    );

    await _repository.requestCodeByEmail(
      email: trimmed,
      onCodeSent: () {
        if (!mounted) return;
        state = AuthState(
          status: AuthStatus.emailSent,
          phone: state.phone,
          email: trimmed,
        );
      },
      onSignedIn: (outcome) {
        if (!mounted) return;
        state = _onboarded(outcome, state.phone, email: trimmed);
      },
      onError: (code) {
        if (!mounted) return;
        if (code == AuthErrorCode.notLinked) {
          state = AuthState(
            status: AuthStatus.notLinked,
            phone: state.phone,
            email: trimmed,
          );
          return;
        }
        state = AuthState(
          status: AuthStatus.emailSent,
          phone: state.phone,
          email: trimmed,
          errorCode: code,
        );
      },
    );
  }

  /// Confirms the SMS code and returns the bound session.
  Future<void> verifyCode(String code) async {
    final trimmed = code.trim();
    if (!RegExp(r'^\d{6}$').hasMatch(trimmed)) {
      state = AuthState(
        status: AuthStatus.codeSent,
        phone: state.phone,
        errorCode: AuthErrorCode.invalidCode,
      );
      return;
    }

    state = AuthState(status: AuthStatus.verifying, phone: state.phone);

    try {
      final outcome = await _repository.confirmCode(trimmed);
      if (!mounted) return;
      state = _onboarded(outcome, state.phone);
    } on AuthRepositoryException catch (exception) {
      if (!mounted) return;
      if (exception.code == AuthErrorCode.notLinked) {
        state = AuthState(status: AuthStatus.notLinked, phone: state.phone);
        return;
      }
      state = AuthState(
        status: AuthStatus.codeSent,
        phone: state.phone,
        errorCode: exception.code,
      );
    } catch (_) {
      if (!mounted) return;
      state = AuthState(
        status: AuthStatus.codeSent,
        phone: state.phone,
        errorCode: AuthErrorCode.unknown,
      );
    }
  }

  /// Confirms the email OTP code and returns the bound session.
  Future<void> verifyCodeByEmail(String code) async {
    final trimmed = code.trim();
    if (!RegExp(r'^\d{6}$').hasMatch(trimmed)) {
      state = AuthState(
        status: AuthStatus.emailSent,
        phone: state.phone,
        email: state.email,
        errorCode: AuthErrorCode.invalidCode,
      );
      return;
    }

    state = AuthState(
      status: AuthStatus.verifyingEmail,
      phone: state.phone,
      email: state.email,
    );

    try {
      final outcome = await _repository.confirmCodeByEmail(trimmed);
      if (!mounted) return;
      state = _onboarded(outcome, state.phone, email: state.email);
    } on AuthRepositoryException catch (exception) {
      if (!mounted) return;
      if (exception.code == AuthErrorCode.notLinked) {
        state = AuthState(
          status: AuthStatus.notLinked,
          phone: state.phone,
          email: state.email,
        );
        return;
      }
      state = AuthState(
        status: AuthStatus.emailSent,
        phone: state.phone,
        email: state.email,
        errorCode: exception.code,
      );
    } catch (_) {
      if (!mounted) return;
      state = AuthState(
        status: AuthStatus.emailSent,
        phone: state.phone,
        email: state.email,
        errorCode: AuthErrorCode.unknown,
      );
    }
  }

  /// Re-checks enrolment claims without asking for another SMS.
  Future<void> refreshEnrollment() async {
    state = AuthState(status: AuthStatus.verifying, phone: state.phone);

    try {
      final outcome = await _repository.refreshEnrollment();
      if (!mounted) return;
      if (outcome == null) {
        state = AuthState(status: AuthStatus.notLinked, phone: state.phone);
        return;
      }
      state = _onboarded(outcome, state.phone);
    } on DeviceSecurityException {
      if (!mounted) return;
      state = AuthState(
        status: AuthStatus.notLinked,
        phone: state.phone,
        errorCode: AuthErrorCode.deviceLocked,
      );
    } catch (_) {
      if (!mounted) return;
      state = AuthState(
        status: AuthStatus.notLinked,
        phone: state.phone,
        errorCode: AuthErrorCode.unknown,
      );
    }
  }

  /// Abandons the current attempt, e.g. the user typed the wrong number.
  void reset() {
    state = AuthState.initial;
  }

  Future<void> signOut() async {
    await _repository.signOut();
    if (!mounted) return;
    state = AuthState.initial;
  }

  /// Activates an account using a QR activation code from the centre secretary.
  Future<void> activateWithQrCode({
    required String qrCode,
    required String phone,
  }) async {
    final normalized = EgyptValidators.normalizeEgyptianPhone(phone.trim());
    if (normalized.isEmpty) {
      state = const AuthState(errorCode: AuthErrorCode.invalidPhone);
      return;
    }

    state = AuthState(
      status: AuthStatus.qrActivated,
      phone: normalized,
    );

    try {
      final outcome = await _repository.activateWithQrCode(
        qrCode: qrCode,
        phone: normalized,
      );
      if (!mounted) return;
      state = _onboarded(outcome, normalized);
    } on AuthRepositoryException catch (exception) {
      if (!mounted) return;
      state = AuthState(
        status: AuthStatus.initial,
        phone: normalized,
        errorCode: exception.code,
      );
    } catch (_) {
      if (!mounted) return;
      state = AuthState(
        status: AuthStatus.initial,
        phone: normalized,
        errorCode: AuthErrorCode.unknown,
      );
    }
  }

  AuthState _onboarded(SignInOutcome outcome, String phone, {String? email}) {
    return AuthState(
      status: AuthStatus.onboarded,
      phone: phone,
      email: email ?? '',
      tenantId: outcome.tenantId,
      role: outcome.role,
      fingerprint: outcome.fingerprint,
    );
  }
}
