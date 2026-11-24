import 'package:flutter_test/flutter_test.dart';
import 'package:kashkool_app/core/l10n/app_strings.dart';
import 'package:kashkool_app/features/auth/data/auth_repository.dart';
import 'package:kashkool_app/features/auth/presentation/auth_error_text.dart';

void main() {
  group('AppStrings', () {
    test('Arabic and English define exactly the same keys', () {
      final en = AppStrings.keysFor('en');
      final ar = AppStrings.keysFor('ar');

      expect(en, isNotEmpty);
      expect(ar.difference(en), isEmpty, reason: 'missing in en');
      expect(en.difference(ar), isEmpty, reason: 'missing in ar');
    });

    test('returns the key itself when a translation is missing', () {
      expect(AppStrings.translate('__not_a_key__', 'en'), '__not_a_key__');
    });
  });

  group('authErrorText', () {
    test('explains an unprovisioned project instead of a generic error', () {
      final message = authErrorText(AuthErrorCode.notConfigured, 'ar');

      expect(message, isNot('errAuthNotConfigured'));
      expect(message.contains('تسجيل الدخول'), isTrue);
    });

    test('every error code has copy in both locales', () {
      for (final locale in const ['en', 'ar']) {
        for (final code in AuthErrorCode.values) {
          final message = authErrorText(code, locale);
          expect(message, isNotEmpty, reason: '$code ($locale)');
          expect(
            message,
            isNot(equals(code.name)),
            reason: '$code ($locale) has no translation',
          );
        }
      }
    });
  });
}
