# EXECUTION_ROADMAP.md — KASHKOOL AGENT HANDOFF ROADMAP

This document outlines the 8 sequential Mini-Steps required to construct the complete Kashkool EdTech ecosystem. Subsequent agents (**OpenCode** or **Claude**) must execute these steps sequentially without skipping or modifying defined contracts.

---

## MINI-STEP 1: Authentication, Onboarding & Dynamic Tenant Resolver UI
- **Goal:** Implement Space Glass login screens, OTP verification, dynamic white-label tenant resolution (subdomain/code), and hardware device binding handshake.
- **Deliverables:**
  - `apps/kashkool_app/lib/features/auth/presentation/login_screen.dart`
  - `apps/kashkool_app/lib/features/auth/presentation/tenant_selector_screen.dart`
  - `apps/kashkool_app/lib/features/auth/providers/auth_provider.dart`
- **Acceptance Criteria:** Successful device lock validation; failure redirects to hardware binding reset request flow.

---

## MINI-STEP 2: Center Secretary Offline Desk
- **Goal:** Build high-throughput offline check-in station for secretaries with Dynamic QR (5s rotation), NFC scanning, thermal receipt layout generation, and cash-to-wallet top-up desk.
- **Deliverables:**
  - `apps/kashkool_app/lib/features/center_ops/presentation/secretary_desk_screen.dart`
  - `apps/kashkool_app/lib/features/center_ops/services/thermal_printer_service.dart`
  - `apps/kashkool_app/lib/features/center_ops/services/dynamic_qr_engine.dart`
- **Acceptance Criteria:** Scans and issues thermal receipt layout in <1 second offline; queues record into `SyncQueueTable` with `CRITICAL` priority.

---

## MINI-STEP 3: Teacher & Center Dashboard
- **Goal:** Provide white-label customization UI, revenue/attendance analytics graphs, student group management, and class schedule builder.
- **Deliverables:**
  - `apps/kashkool_app/lib/features/center_ops/presentation/teacher_dashboard_screen.dart`
  - `apps/kashkool_app/lib/features/center_ops/presentation/group_management_screen.dart`

---

## MINI-STEP 4: Courses, Encrypted Lectures & Live Classroom UI
- **Goal:** Interactive curriculum tree (Grade -> Subject -> Unit -> Lesson), DRM video player with dynamic drifting watermark overlay, and WebRTC live classroom with polls and hand-raising.
- **Deliverables:**
  - `apps/kashkool_app/lib/features/courses_live/presentation/course_tree_screen.dart`
  - `apps/kashkool_app/lib/features/courses_live/presentation/drm_lecture_player.dart`
  - `apps/kashkool_app/lib/features/courses_live/presentation/live_classroom_screen.dart`

---

## MINI-STEP 5: Question Bank & Auto-Graded Quiz Engine
- **Goal:** LaTeX math rendering engine, timed quiz interface, instant local auto-grading, and automated remedial practice generator.
- **Deliverables:**
  - `apps/kashkool_app/lib/features/assessments/presentation/quiz_runner_screen.dart`
  - `apps/kashkool_app/lib/features/assessments/presentation/question_editor_screen.dart`

---

## MINI-STEP 6: Moderated Academic Community & Study Assistant Drawer
- **Goal:** Lesson-scoped discussion rooms with teacher moderation tools + Socratic `StudyAssistant` sliding glass drawer backed by `smart_router.ts`.
- **Deliverables:**
  - `apps/kashkool_app/lib/features/community/presentation/discussion_room_screen.dart`
  - `apps/kashkool_app/lib/features/community/presentation/study_assistant_drawer.dart`

---

## MINI-STEP 7: Parent Portal & Automated Reports View
- **Goal:** Parent dashboard showing real-time attendance timeline, exam analytics charts, wallet balance top-up button, and weekly behavior reports.
- **Deliverables:**
  - `apps/kashkool_app/lib/features/parent_portal/presentation/parent_dashboard_screen.dart`
  - `apps/kashkool_app/lib/features/parent_portal/presentation/student_report_view.dart`

---

## MINI-STEP 8: Kashkool God-Mode Android Admin App UI
- **Goal:** Dedicated Super-Admin Control Center featuring live governorate active-user map, tenant provisioning/freezing controls, ghost impersonation generator, and global feature kill-switches.
- **Deliverables:**
  - `apps/kashkool_admin/lib/features/dashboard/presentation/god_mode_dashboard.dart`
  - `apps/kashkool_admin/lib/features/tenants/presentation/tenant_manager_screen.dart`
