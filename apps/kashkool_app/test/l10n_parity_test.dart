import 'package:flutter_test/flutter_test.dart';
import 'package:kashkool_app/core/l10n/app_strings.dart';

void main() {
  test('app_strings has full key parity between ar and en', () {
    final ar = AppStrings.keysFor('ar');
    final en = AppStrings.keysFor('en');
    expect(ar.difference(en), isEmpty,
        reason: 'Keys present in ar but missing in en: ${ar.difference(en)}');
    expect(en.difference(ar), isEmpty,
        reason: 'Keys present in en but missing in ar: ${en.difference(ar)}');
    expect(ar, isNotEmpty);
  });
}
