import '../../../core/l10n/app_strings.dart';
import '../data/auth_repository.dart';

/// Maps a failure reason to localized copy. Unknown/null renders nothing.
String authErrorText(AuthErrorCode? code, String locale) {
  switch (code) {
    case null:
      return '';
    case AuthErrorCode.invalidPhone:
      return AppStrings.translate('errInvalidPhone', locale);
    case AuthErrorCode.invalidEmail:
      return AppStrings.translate('errInvalidEmail', locale);
    case AuthErrorCode.invalidQrCode:
      return AppStrings.translate('errInvalidQrCode', locale);
    case AuthErrorCode.invalidCode:
      return AppStrings.translate('errInvalidCode', locale);
    case AuthErrorCode.tooManyRequests:
      return AppStrings.translate('errTooManyRequests', locale);
    case AuthErrorCode.quotaExceeded:
      return AppStrings.translate('errQuota', locale);
    case AuthErrorCode.network:
      return AppStrings.translate('errNetwork', locale);
    case AuthErrorCode.deviceLocked:
      return AppStrings.translate('errDeviceLocked', locale);
    case AuthErrorCode.notLinked:
      return AppStrings.translate('authNotLinkedTitle', locale);
    case AuthErrorCode.notConfigured:
      return AppStrings.translate('errAuthNotConfigured', locale);
    case AuthErrorCode.unknown:
      return AppStrings.translate('errUnknown', locale);
  }
}
