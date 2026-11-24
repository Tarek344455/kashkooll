import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kashkool_core/kashkool_core.dart';

import '../../../../core/config/supabase_bootstrap.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../core/l10n/locale_provider.dart';
import '../../../../core/theme/glass_widgets.dart';
import '../providers/auth_provider.dart';
import 'auth_error_text.dart';

/// Phone sign-in: request a one-time code, then confirm it.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  bool _validatePhone(String? value) {
    return value != null && EgyptValidators.isValidEgyptianPhone(value.trim());
  }

  Future<void> _sendCode() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    await ref.read(authProvider.notifier).requestCode(_phoneController.text);
  }

  Future<void> _resend() async {
    final phone = ref.read(authProvider).phone;
    if (phone.isEmpty) return;
    await ref.read(authProvider.notifier).requestCode(phone);
  }

  Future<void> _verify() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    await ref.read(authProvider.notifier).verifyCode(_codeController.text);
  }

  void _changeNumber() {
    _codeController.clear();
    ref.read(authProvider.notifier).reset();
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(currentLocaleProvider);
    final auth = ref.watch(authProvider);
    final rtl = locale == 'ar';
    final awaitingCode =
        auth.status == AuthStatus.codeSent || auth.status == AuthStatus.verifying;

    final errorText = authErrorText(auth.errorCode, locale);
    final backendReady = SupabaseBootstrap.isReady;

    return Directionality(
      textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      AppStrings.translate('welcome', locale),
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 28),
                    if (!backendReady) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.amber.withValues(alpha: 0.35),
                          ),
                        ),
                        child: Text(
                          AppStrings.translate(
                            'authBackendUnavailable',
                            locale,
                          ),
                          style: const TextStyle(
                            color: Colors.amber,
                            fontSize: 13,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    FloatingGlassCard(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 24,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Center(
                              child: _LanguageToggle(locale: locale),
                            ),
                            const SizedBox(height: 24),
                            if (!awaitingCode) ...[
                              TextFormField(
                                controller: _phoneController,
                                keyboardType: TextInputType.phone,
                                autofillHints: const [
                                  AutofillHints.telephoneNumber,
                                ],
                                validator: (value) => _validatePhone(value)
                                    ? null
                                    : AppStrings.translate(
                                        'errInvalidPhone',
                                        locale,
                                      ),
                                decoration: InputDecoration(
                                  labelText: AppStrings.translate(
                                    'authPhoneLabel',
                                    locale,
                                  ),
                                  hintText: AppStrings.translate(
                                    'authPhoneHint',
                                    locale,
                                  ),
                                  prefixIcon: const Icon(Icons.phone),
                                ),
                              ),
                              const SizedBox(height: 20),
                              FilledButton(
                                onPressed: auth.isBusy || !backendReady
                                    ? null
                                    : _sendCode,
                                style: FilledButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: auth.status == AuthStatus.sendingCode
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Text(
                                        AppStrings.translate(
                                          'authSendCode',
                                          locale,
                                        ),
                                      ),
                              ),
                            ] else ...[
                              Text(
                                '${AppStrings.translate('authCodeSentTo', locale)} '
                                '${auth.phone}',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _codeController,
                                keyboardType: TextInputType.number,
                                maxLength: 6,
                                autofillHints: const [
                                  AutofillHints.oneTimeCode,
                                ],
                                validator: (value) =>
                                    (value ?? '').trim().length == 6
                                        ? null
                                        : AppStrings.translate(
                                            'errInvalidCode',
                                            locale,
                                          ),
                                decoration: InputDecoration(
                                  labelText: AppStrings.translate(
                                    'authCodeLabel',
                                    locale,
                                  ),
                                  prefixIcon: const Icon(Icons.lock),
                                  counterText: '',
                                ),
                              ),
                              const SizedBox(height: 18),
                              FilledButton(
                                onPressed: auth.isBusy ? null : _verify,
                                style: FilledButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: auth.status == AuthStatus.verifying
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Text(
                                        AppStrings.translate(
                                          'authVerify',
                                          locale,
                                        ),
                                      ),
                              ),
                              const SizedBox(height: 10),
                              SizedBox(
                                width: double.infinity,
                                child: Wrap(
                                  alignment: WrapAlignment.spaceBetween,
                                  runAlignment: WrapAlignment.center,
                                  crossAxisAlignment:
                                      WrapCrossAlignment.center,
                                  spacing: 8,
                                  runSpacing: 4,
                                  children: [
                                    TextButton.icon(
                                      onPressed:
                                          auth.isBusy ? null : _changeNumber,
                                      icon: const Icon(
                                        Icons.edit_outlined,
                                        size: 16,
                                      ),
                                      label: Text(
                                        AppStrings.translate(
                                          'authChangeNumber',
                                          locale,
                                        ),
                                      ),
                                      style: TextButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        minimumSize: Size.zero,
                                        tapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                      ),
                                    ),
                                    TextButton.icon(
                                      onPressed:
                                          auth.isBusy ? null : _resend,
                                      icon: const Icon(
                                        Icons.refresh_rounded,
                                        size: 16,
                                      ),
                                      label: Text(
                                        AppStrings.translate(
                                          'authResend',
                                          locale,
                                        ),
                                      ),
                                      style: TextButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        minimumSize: Size.zero,
                                        tapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            if (errorText.isNotEmpty) ...[
                              const SizedBox(height: 14),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.redAccent.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.redAccent.withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Text(
                                  errorText,
                                  style: const TextStyle(
                                    color: Colors.redAccent,
                                    fontSize: 13,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LanguageToggle extends ConsumerWidget {
  const _LanguageToggle({required this.locale});

  final String locale;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _LanguageButton(label: 'English', langCode: 'en', locale: locale),
          _LanguageButton(label: 'العربية', langCode: 'ar', locale: locale),
        ],
      ),
    );
  }
}

class _LanguageButton extends ConsumerWidget {
  const _LanguageButton({
    required this.label,
    required this.langCode,
    required this.locale,
  });

  final String label;
  final String langCode;
  final String locale;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSelected = locale == langCode;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () =>
            ref.read(currentLocaleProvider.notifier).state = langCode,
        borderRadius: BorderRadius.circular(24),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
          decoration: BoxDecoration(
            color: isSelected ? Colors.cyanAccent : Colors.transparent,
            borderRadius: BorderRadius.circular(24),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.cyanAccent.withValues(alpha: 0.3),
                      blurRadius: 8,
                      spreadRadius: 1,
                    )
                  ]
                : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.black : Colors.white70,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}
