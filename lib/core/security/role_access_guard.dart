import '../models/kashkool_models.dart';

/// Centralized Role-Based Visibility & Route Access Matrix.
class RoleAccessGuard {
  static const Map<UserRole, List<AppDestination>> _allowed = {
    UserRole.student: [
      AppDestination.home,
      AppDestination.courses,
      AppDestination.assistant,
      AppDestination.wallet,
    ],
    UserRole.secretary: [
      AppDestination.home,
      AppDestination.desk,
      AppDestination.analytics,
      AppDestination.teacher,
      AppDestination.wallet,
    ],
    UserRole.teacher: [
      AppDestination.home,
      AppDestination.teacher,
      AppDestination.analytics,
      AppDestination.courses,
      AppDestination.assistant,
      AppDestination.desk,
    ],
    UserRole.parent: [
      AppDestination.home,
      AppDestination.parent,
      AppDestination.wallet,
      AppDestination.courses,
    ],
  };

  static List<AppDestination> destinationsForRole(UserRole role) {
    return List.unmodifiable(_allowed[role] ?? const [AppDestination.home]);
  }

  static bool isDestinationAllowed(UserRole role, AppDestination dest) {
    return (_allowed[role] ?? const [AppDestination.home]).contains(dest);
  }

  static AppDestination resolveSafeDestination(
    UserRole role,
    AppDestination requested,
  ) {
    return isDestinationAllowed(role, requested)
        ? requested
        : AppDestination.home;
  }

  static bool isStaffRole(UserRole role) {
    return role == UserRole.teacher || role == UserRole.secretary;
  }

  static bool canManageFinancialLedger(UserRole role) {
    return isStaffRole(role);
  }

  static bool canAccessStudyAssistant(UserRole role) {
    return role == UserRole.student || role == UserRole.teacher;
  }
}
