import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/l10n/locale_provider.dart';
import '../../../../core/theme/glass_widgets.dart';
import '../providers/auth_provider.dart';
import 'auth_error_text.dart';

/// Shown when a number signed in but no centre has enrolled it yet.
class NotLinkedScreen extends ConsumerWidget {
  const NotLinkedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(currentLocaleProvider);
    final auth = ref.watch(authProvider);
    final rtl = locale == 'ar';
    final errorText = authErrorText(auth.errorCode, locale);

    return Directionality(
      textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: FloatingGlassCard(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(Icons.link_off, color: Colors.white70, size: 40),
                    const SizedBox(height: 16),
                    Text(
                      AppStrings.translate('authNotLinkedTitle', locale),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppStrings.translate('authNotLinkedBody', locale),
                      style: const TextStyle(color: Colors.white70),
                      textAlign: TextAlign.center,
                    ),
                    if (auth.phone.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        auth.phone,
                        style: const TextStyle(color: Colors.white38, fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    if (errorText.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        errorText,
                        style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: auth.isBusy
                          ? null
                          : () => ref.read(authProvider.notifier).refreshEnrollment(),
                      child: auth.status == AuthStatus.verifying
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(AppStrings.translate('authCheckAgain', locale)),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: auth.isBusy
                          ? null
                          : () => ref.read(authProvider.notifier).signOut(),
                      child: Text(AppStrings.translate('authSignOut', locale)),
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
