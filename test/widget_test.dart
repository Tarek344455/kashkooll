import 'package:flutter_test/flutter_test.dart';
import 'package:kashkool_app/core/models/kashkool_models.dart';
import 'package:kashkool_app/core/security/role_access_guard.dart';
import 'package:kashkool_app/data/launch_accounts.dart';
import 'package:kashkool_app/main.dart';

void main() {
  test('RoleAccessGuard enforces strict route isolation across all 4 roles', () {
    for (final forbidden in [
      AppDestination.desk,
      AppDestination.analytics,
      AppDestination.teacher,
      AppDestination.parent,
    ]) {
      expect(
        RoleAccessGuard.isDestinationAllowed(UserRole.student, forbidden),
        isFalse,
      );
      expect(
        RoleAccessGuard.resolveSafeDestination(UserRole.student, forbidden),
        AppDestination.home,
      );
    }

    for (final forbidden in [
      AppDestination.desk,
      AppDestination.analytics,
      AppDestination.teacher,
      AppDestination.assistant,
    ]) {
      expect(
        RoleAccessGuard.isDestinationAllowed(UserRole.parent, forbidden),
        isFalse,
      );
    }

    expect(RoleAccessGuard.canManageFinancialLedger(UserRole.student), isFalse);
    expect(RoleAccessGuard.canManageFinancialLedger(UserRole.parent), isFalse);
    expect(RoleAccessGuard.canManageFinancialLedger(UserRole.teacher), isTrue);
    expect(RoleAccessGuard.canManageFinancialLedger(UserRole.secretary), isTrue);
  });

  test('LaunchAccounts authenticate every role and reject invalid credentials', () {
    for (final role in UserRole.values) {
      final acc = launchAccounts.firstWhere((a) => a.role == role);
      expect(authenticateLaunchAccount(acc.email, acc.password)?.id, acc.id);
      expect(authenticateByActivationCode(acc.activationCode)?.role, role);
      expect(authenticateLaunchAccount(acc.email, 'wrong-pass'), isNull);
    }
    expect(authenticateByActivationCode('FAKE999'), isNull);
  });

  testWidgets('KashkoolApp boots cleanly through orbital splash', (tester) async {
    await tester.pumpWidget(const KashkoolApp());
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('كشكول'), findsWidgets);
  });
}
