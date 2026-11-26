import { AppDestination, UserRole } from "../../types/kashkool";

/**
 * Centralized Role-Based Visibility & Route Access Matrix.
 * Enforced across UI rendering, navigation shell, and router guards.
 */
export const ROLE_ALLOWED_DESTINATIONS: Record<UserRole, readonly AppDestination[]> = {
  [UserRole.STUDENT]: ["home", "courses", "assistant", "wallet"],
  [UserRole.SECRETARY]: ["home", "desk", "analytics", "teacher", "wallet"],
  [UserRole.TEACHER]: ["home", "teacher", "analytics", "courses", "assistant", "desk"],
  [UserRole.PARENT]: ["home", "parent", "wallet", "courses"],
};

export function destinationsForRole(role: UserRole): AppDestination[] {
  return [...(ROLE_ALLOWED_DESTINATIONS[role] ?? ["home"])];
}

export function isDestinationAllowed(role: UserRole, dest: AppDestination): boolean {
  const allowed = ROLE_ALLOWED_DESTINATIONS[role] ?? ["home"];
  return allowed.includes(dest);
}

export function resolveSafeDestination(role: UserRole, requested: AppDestination): AppDestination {
  return isDestinationAllowed(role, requested) ? requested : "home";
}

export function isStaffRole(role: UserRole): boolean {
  return role === UserRole.TEACHER || role === UserRole.SECRETARY;
}

export function canManageFinancialLedger(role: UserRole): boolean {
  return isStaffRole(role);
}

export function canAccessStudyAssistant(role: UserRole): boolean {
  return role === UserRole.STUDENT || role === UserRole.TEACHER;
}

export function canOperateAttendanceDesk(role: UserRole): boolean {
  return isStaffRole(role);
}
