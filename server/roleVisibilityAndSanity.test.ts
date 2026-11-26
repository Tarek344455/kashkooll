import test from "node:test";
import assert from "node:assert/strict";
import {
  canAccessStudyAssistant,
  canManageFinancialLedger,
  canOperateAttendanceDesk,
  destinationsForRole,
  isDestinationAllowed,
  resolveSafeDestination,
} from "../src/core/security/roleAccessGuard";
import { t } from "../src/core/l10n/appStrings";
import {
  LAUNCH_ACCOUNTS,
  authenticateByActivationCode,
  authenticateLaunchAccount,
} from "../src/data/accounts";
import { AppDestination, AppLanguage, UserRole } from "../src/types/kashkool";

test("RoleAccessGuard: strict route isolation across all 4 roles", () => {
  // Student cannot access staff/parent routes
  for (const forbidden of ["desk", "analytics", "teacher", "parent"] as AppDestination[]) {
    assert.equal(isDestinationAllowed(UserRole.STUDENT, forbidden), false);
    assert.equal(resolveSafeDestination(UserRole.STUDENT, forbidden), "home");
  }

  // Parent cannot access staff routes or student's private AI assistant
  for (const forbidden of ["desk", "analytics", "teacher", "assistant"] as AppDestination[]) {
    assert.equal(isDestinationAllowed(UserRole.PARENT, forbidden), false);
    assert.equal(resolveSafeDestination(UserRole.PARENT, forbidden), "home");
  }

  // Secretary cannot access parent or student study assistant/courses
  for (const forbidden of ["parent", "assistant", "courses"] as AppDestination[]) {
    assert.equal(isDestinationAllowed(UserRole.SECRETARY, forbidden), false);
  }

  // Teacher cannot access parent portal or student wallet
  for (const forbidden of ["parent", "wallet"] as AppDestination[]) {
    assert.equal(isDestinationAllowed(UserRole.TEACHER, forbidden), false);
  }

  // Capability checks
  assert.equal(canManageFinancialLedger(UserRole.STUDENT), false);
  assert.equal(canManageFinancialLedger(UserRole.PARENT), false);
  assert.equal(canManageFinancialLedger(UserRole.SECRETARY), true);
  assert.equal(canManageFinancialLedger(UserRole.TEACHER), true);

  assert.equal(canAccessStudyAssistant(UserRole.PARENT), false);
  assert.equal(canAccessStudyAssistant(UserRole.STUDENT), true);

  assert.equal(canOperateAttendanceDesk(UserRole.STUDENT), false);
  assert.equal(canOperateAttendanceDesk(UserRole.PARENT), false);
  assert.equal(canOperateAttendanceDesk(UserRole.SECRETARY), true);

  // Every role always has "home"
  for (const role of Object.values(UserRole)) {
    assert.ok(destinationsForRole(role).includes("home"));
  }
});

test("Localization & Semantic Sanity: core keys exist in AR & EN with zero placeholders", () => {
  const criticalKeys = [
    "app_title",
    "welcome",
    "err_invalid_phone",
    "err_invalid_email",
    "no_pending_receipts",
    "empty_students",
    "empty_groups",
    "student_rescue_empty",
    "timeline_empty",
    "parent_dignity_alert",
    "parent_cheer_copied",
    "exam_start_cta",
    "exam_submit_cta",
    "void_entry",
  ];

  for (const key of criticalKeys) {
    const ar = t(AppLanguage.AR, key);
    const en = t(AppLanguage.EN, key);
    assert.ok(ar && ar !== key, `Missing AR translation for ${key}`);
    assert.ok(en && en !== key, `Missing EN translation for ${key}`);
    assert.equal(/\b(TODO|FIXME|undefined|null|NaN)\b/i.test(ar), false);
    assert.equal(/\b(TODO|FIXME|undefined|null|NaN)\b/i.test(en), false);
  }
});

test("Launch Accounts: every role has a verified account and rejects invalid credentials", () => {
  for (const role of Object.values(UserRole)) {
    const acc = LAUNCH_ACCOUNTS.find((a) => a.role === role);
    assert.ok(acc, `Missing launch account for role ${role}`);
    assert.equal(authenticateLaunchAccount(acc.email, acc.password)?.id, acc.id);
    assert.equal(authenticateByActivationCode(acc.activationCode)?.role, role);
    assert.equal(authenticateLaunchAccount(acc.email, "wrong-password"), null);
  }
  assert.equal(authenticateByActivationCode("FAKE999"), null);
});
