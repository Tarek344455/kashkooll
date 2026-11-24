# THE KASHKOOL SUPREME CONSTITUTION: BUSINESS INTELLIGENCE & ZERO-DEFECT ENGINEERING
**Applies to:** `kashkool_app` (All Roles) & `kashkool_admin` (Super-Admin God-Mode) & `backend/`
**Enforcement Level:** MANDATORY — Any code violating these rules is considered broken and must be rejected/rewritten immediately.

---

## PART I: EGYPTIAN EDTECH BUSINESS & PRODUCT MINDSET (THINK LIKE A FOUNDER)
You are not writing toy code; you are building Egypt's #1 educational operating system. Before designing or coding ANY screen, API, or database schema, you MUST enforce these 5 commercial pillars:

1. **Egyptian Market & Cash-Desk Reality (Edge-Case Mastery):**
   - **Flexible Money Flows:** Students rarely pay fixed monthly subscriptions cleanly. Every financial module MUST natively support: Full Payment, Partial/Installment Payment (متبقي عليه), Book/Material Reservation Fees (حجز ملازم), Teacher Discounts/Exemptions (إعفاء/خصم), and Cash-to-Wallet Top-ups at the center desk.
   - **The 3-Second Queue Rule (Zero-Friction UX):** Center secretaries scan 200+ students in 10 minutes on crowded stairs. Every secretary action (Dynamic QR/NFC scan, attendance check-in, receipt print) MUST complete in **1 tap or 1 scan (<1 second)** with unmistakable audio/haptic/color feedback (Green: Valid | Amber: Balance Due | Red: Wrong Group/Blocked).
   - **Rural & Mobile Data Optimization:** Students across Egyptian governorates rely on limited mobile data quotas. Enforce aggressive image compression, local SQLite caching, PDF delta-loading, and adaptive low-bitrate video streaming so a 2-hour lecture never drains a student's data bundle.

2. **Financial Governance & Anti-Fraud Armor:**
   - **Immutable Financial Ledger:** Secretaries and assistants can NEVER hard-delete or silently edit a payment or attendance record. Corrections require a formal **Void/Refund Entry** logged permanently in `/tenants/{tenantId}/audit_logs` with staff ID, timestamp, and instant push alert to the Center Owner/Teacher.
   - **Instant Multi-Center Settlement:** Teachers operating across multiple centers need 1-tap automated end-of-day reconciliation: *(Total Attended × Session Price) – Center Split % – Assistant Wages = Net Teacher Payout*.

3. **Addictive Retention & Psychological Loops:**
   - **Students (Dopamine & Status):** Turn studying into a competitive sport—weekly group/governorate leaderboards, streak badges, exam mastery rings, and automated remedial practice targeting ONLY the exact curriculum tags the student missed.
   - **Parents (High-Trust, Zero-Spam):** Busy parents hate noisy apps. Deliver **one crisp, empathetic weekly digest** summarizing attendance trajectory, exam momentum, and behavioral focus—triggering instant alerts ONLY on critical events (unexcused absence or sudden grade drop).
   - **Teachers & Centers (Time Liberation):** Automate repetitive admin work—auto-graded quizzes, instant parent reporting, and seamless white-label branding so every teacher feels they own a bespoke platform.

4. **Invisible Intelligence (Zero AI Buzzwords):**
   - Never expose words like "AI", "LLM", "Bot", or sparkle/robot icons in any UI label. Present all smart tutoring, automated reports, and question generation as native, human-crafted academic tools (`المساعد الدراسي`, `التقارير التلقائية`, `بنك الأسئلة الذكي`).

---

## PART II: END-TO-END WIRING & ZERO-DEFECT QUALITY GATE (BUILD LIKE A PRINCIPAL ARCHITECT)
A screen that looks good but has dead buttons, mock data, or missing backend rules is a failure. Every feature MUST pass all 5 technical gates before completion:

### Gate 1: Full Vertical Slice Wiring (Zero Dead UI / Zero Mock Lists)
- **Strict Prohibition:** NEVER leave `// TODO`, `onPressed: () {}`, `Future.delayed` fake loaders, or hardcoded dummy lists in any feature.
- Every UI component MUST be wired top-to-bottom across all 4 architectural layers:
  `Space Glass UI Widget` ➔ `Riverpod AsyncNotifier` ➔ `Repository (Offline Drift + Supabase Postgres)` ➔ `Zero-Trust RLS policies / Edge Functions`.
- Every action button must show sleek loading states, perform optimistic local writes, queue background cloud sync, and display concise Arabic/English confirmation or error feedback.

### Gate 2: Exhaustive 4-State UI Resilience
Every data-driven screen MUST explicitly handle all 4 states cleanly:
1. **Loading State:** Custom Space Glass translucent shimmer skeletons (never jarring white screens or raw spinners).
2. **Empty State:** Crisp, localized guidance with a direct primary CTA button (e.g., *"لا توجد مجموعات حالياً — أنشئ أول مجموعة"*).
3. **Error State:** Human-friendly Arabic/English message (never raw stack traces or Supabase error codes) + instant **"إعادة المحاولة / Retry"** button.
4. **Populated State:** Fluid responsive layout verified from `360px` Android phones to `1920px+` Windows/macOS/iPad screens.

### Gate 3: Cross-App Real-Time Synchronization Contract
Mutations in one app/role MUST propagate live to connected roles:
- Secretary scans student QR ➔ Student attendance & wallet update instantly + Teacher live headcount increments + Parent receives automated attendance alert.
- Super Admin toggles a Master Kill-Switch or freezes a Tenant in `kashkool_admin` ➔ `kashkool_app` enforces the state within `<2 seconds` via live config stream.

### Gate 4: Cross-Platform & Security Safety
- Never import `dart:io` directly in shared UI/business files (breaks Flutter Web); always use platform-safe abstractions.
- Enforce `FLAG_SECURE` / screen-capture protection and `DynamicWatermarkOverlay` on all paid video/PDF/exam views.
- Every Postgres query MUST match an explicit RLS policy in `supabase/migrations/20261123000003_rls.sql` and a composite index in `supabase/migrations/20261123000001_schema.sql` so `42501 insufficient_privilege` or `PGRST query errors` never occurs in production.

### Gate 5: Mandatory Automated Verification Loop
After creating or modifying ANY module, you MUST execute these verification commands and fix every single error/warning before finishing:
1. `dart run build_runner build --delete-conflicting-outputs` (Code-gen must succeed cleanly).
2. `flutter analyze --fatal-infos` across `packages/kashkool_core`, `apps/kashkool_app`, and `apps/kashkool_admin` (**MUST return 0 issues**).
3. Verify `app_strings.dart` has 100% key parity between `ar` (RTL) and `en` (LTR).
4. Update `PROJECT_STATE.json` and `AGENTS.md` with the verified module status.

---

## PART III: AUTONOMOUS SELF-HEALING, DEBUGGING & SYSTEM CONSOLIDATION (FIX LIKE A SURGEON)
When encountering ANY compile error, runtime crash, broken wiring, dependency conflict, or architectural drift across `kashkool_app`, `kashkool_admin`, `kashkool_core`, or `backend/`, you MUST NOT apply superficial band-aids (like commenting out code, ignoring lint rules, or returning dummy fallbacks). Execute this **6-Step Surgical Healing Protocol**:

### 1. Root-Cause Forensics (Never Treat Symptoms)
- **Trace the Full Call Chain:** Before touching a single line, trace the failure backward across all 4 layers:
  `UI / Widget Tree` ⬅ `Riverpod State / AsyncValue` ⬅ `Offline Drift / Network Interceptor` ⬅ `RLS policies / Edge Functions / Schema`.
- **Ban Quick Hacks:** Strictly forbidden: `@ts-ignore`, `// ignore: all`, swallowing exceptions with empty `catch (_) {}`, or forcing nullable casts (`!`) without null-safety verification. Fix the underlying type contract or data flow permanently.

### 2. Cross-Monorepo Consolidation & Dependency Alignment
- **Single Source of Truth:** If a model, enum, validator, or constant exists in more than one place, immediately consolidate it into `packages/kashkool_core` and update all imports across `kashkool_app` and `kashkool_admin`.
- **Pubspec & Version Lock:** Whenever adding or fixing a package in `pubspec.yaml`, run `melos bootstrap` (or `flutter pub get` in all 3 Dart packages) and verify there are zero version skews between `riverpod`, `drift`, `freezed`, `go_router`, and `supabase_flutter` plugins.

### 3. Build-Runner & Code-Gen Synchronization
- Whenever modifying any `@riverpod`, `@freezed`, `@JsonSerializable`, or `@DriftDatabase` file, immediately execute:
  `dart run build_runner build --delete-conflicting-outputs`
  Never manually edit `.g.dart` or `.freezed.dart` files—fix the source annotations until generation succeeds cleanly.

### 4. Supabase & Backend Contract Reconciliation
- **Rule & Index Alignment:** Whenever a new Postgres query (`.eq()`, `.gte()`, `.order()`) is added or fixed in Flutter, inspect `supabase/migrations/20261123000003_rls.sql` and `supabase/migrations/20261123000001_schema.sql` in the exact same turn and add the matching RLS policy and covering index so production queries never fail with `42501 insufficient_privilege` or `PGRST query errors`.
- **Edge Function Payload Parity:** Ensure TypeScript request/response interfaces in `supabase/functions/` match Dart DTOs in `kashkool_core` field-for-field.

### 5. UI Layout, Overflow & Bilingual Stress-Test
- Eliminate every `RenderFlex overflowed`, unbounded height inside `Column`/`ListView`, or `BackdropFilter` clipping artifact.
- Verify every repaired screen renders cleanly in BOTH **Arabic (`ar` - RTL)** and **English (`en` - LTR)** across narrow mobile (`360px`) and wide desktop (`1920px`) viewports.

### 6. The "Zero-Issue Exit Criteria" (Mandatory Loop)
You are NOT allowed to conclude a debugging or consolidation task until ALL 4 checks pass consecutively:
1. `dart run build_runner build --delete-conflicting-outputs` ➔ Exit Code `0`.
2. `flutter analyze --fatal-infos` (in `kashkool_core`, `kashkool_app`, `kashkool_admin`) ➔ **`No issues found!`**.
3. `deno task check && deno task test` (in `supabase/functions`) and `npm run build` (in `.opencode/omni-plugin`) ➔ Exit Code `0`.
4. Update `PROJECT_STATE.json` and `AGENTS.md` documenting what broke, why it broke, and how it was permanently resolved so the same bug never recurs.

---

## PART IV: FULL ADMINISTRATOR AUTONOMY & ZERO-DELEGATION EXECUTION (MANDATE)
**Applies to:** All tools, shell, file writes, package installs, and Git operations within `N:\opencode\projects\kashkool` (and `E:\opencode\projects\kashkool` workspace mirror).

### 1. IMMEDIATE CONFIGURATION OVERRIDE
- `opencode.json` permissions set to: `"bash": "allow", "edit": "allow", "write": "allow", "webfetch": "allow", "*": "allow"`.
- All shell commands (`flutter pub get`, `dart run build_runner build`, `flutter analyze`, `npm install`, `npm run build`, `git push`, `supabase db push`, `winget`, environment path updates) MUST be executed directly by the agent via Bash/PowerShell tool.
- **STRICTLY FORBIDDEN:** Never output lists of terminal commands saying *"Run these commands when you return"* or *"Please execute X"*. YOU are the operator of this PC.

### 2. ZERO-DELEGATION LAW
Whenever a command is needed, the agent MUST:
1. Execute it directly via shell tool.
2. Read the stdout/stderr output.
3. Fix any errors that occur.
4. Repeat until Exit Code `0` is achieved.
5. Never ask the user to run any command.

### 3. LANGUAGE RULE
Communicate exclusively in clean Arabic or English. Never mix Russian or random foreign characters.

---

## Appendix A — Verified module: Study assistant (2026-11-23)

### What broke
- `apps/kashkool_app/lib/features/community/presentation/study_assistant_drawer.dart` was dead UI with `Future.delayed` fake loaders and hardcoded Arabic messages (Gate 1 violation).
- `apps/kashkool_app/lib/core/services/spaceship_ai_client.dart` returned fabricated cash totals/balances on any failure (Gate 1 violation, and a financial-safety risk).
- `StudyAssistantDrawer` was never mounted anywhere in the router.

### Root cause
The assistant had no real data path: the drawer faked reasoning, and the client faked money figures instead of surfacing failure. No repository, no controller, no four-state handling.

### Permanent resolution
- `SpaceshipAiClient`: added `chat()` (multi-turn, history trimmed to 16 turns), `AssistantReply`, `AssistantTurn`, `AssistantException` with typed failures and Arabic user messages. Removed all fabricated templates. `ask()`/`askStream()` now delegate to `chat()` and throw on failure. Added `checkAvailability()` (GET /health). Suggestions are parsed from a `[[SUGGESTIONS]]` marker emitted by the model — never canned.
- New feature `apps/kashkool_app/lib/features/study_assistant/`:
  - `data/study_assistant_repository.dart` — `StudyAssistantRepository` + `StudyAssistantContext`.
  - `providers/study_assistant_controller.dart` — `StudyAssistantController` (Riverpod `Notifier`) with empty/loading/error/retry/populated states.
  - `presentation/study_assistant_panel.dart` — single surface used by both the screen and the drawer, with shimmer skeletons, empty CTA, inline error + retry, typing indicator, RTL.
  - `presentation/study_assistant_screen.dart` — full-screen host, route `/study-assistant` (query params subject/lesson/mode).
  - `presentation/study_assistant_drawer.dart` — drawer host (moved out of `community/`).
- Wired entry points: `home_screen.dart` (student + teacher), `drm_lecture_player.dart` (contextual to the lecture title), `app_router.dart`.
- Timeout raised to 60 s (measured 24–33 s per turn) with 0 client retries; the gateway already fails over upstreams.

### Verification (all green)
- `flutter analyze --fatal-infos` → `No issues found!`
- `flutter test` → 29 passed (client 10, controller 10, panel 4, l10n parity 1, smoke 1, plus 3 pre-existing)
- `app_strings.dart` key parity: ar/en identical key sets
- Live gateway probe: `kashkool-savior` answers Arabic correctly and emits `[[SUGGESTIONS]]`; chosen upstream `local-gemma/gemma-4-e2b-it`, 24–33 s
- `PROJECT_STATE.json` updated

## Appendix B — Verified module: Center Operations / QR Queue / Settlement (2026-11-23)

### What broke
- `apps/kashkool_app/lib/features/center_ops/presentation/group_management_screen.dart` — hardcoded `_groups` list (Gate 1 violation: hardcoded dummy lists).
- `apps/kashkool_app/lib/features/center_ops/presentation/auto_queue_desk_screen.dart` — hardcoded `_liveFeed` + `Future.delayed` fake scan simulation (Gate 1 violation).
- `apps/kashkool_app/lib/features/center_ops/presentation/floating_settlement_screen.dart` — hardcoded revenue figures + `onPressed: () {}` dead button (Gate 1 violation).
- `apps/kashkool_app/lib/features/community/presentation/discussion_room_screen.dart` — dead snackbar button (Gate 1 violation).
- `apps/kashkool_app/lib/features/courses_live/presentation/drm_lecture_player.dart` — dead fullscreen button `onPressed: () {}` (Gate 1 violation).

### Root cause
Center operations screens used local mock data instead of Supabase queries, and several buttons had empty handlers. No Riverpod providers wired to the database.

### Permanent resolution
- New `apps/kashkool_app/lib/features/center_ops/providers/groups_provider.dart` — `groupsProvider` + `currentTenantIdProvider` reading from Supabase `groups` table (tenant-scoped, RLS-protected).
- New `apps/kashkool_app/lib/features/center_ops/providers/settlement_provider.dart` — `settlementProvider` computing gross revenue, attendance, center split, net payout from real wallet + attendance rows.
- `group_management_screen.dart` — converted to ConsumerStatefulWidget using `groupsProvider`; insert goes through Supabase `groups` insert with staff role check.
- `auto_queue_desk_screen.dart` — converted to ConsumerStatefulWidget using `queueFeedProvider` + `queueStatsProvider`; scan action calls `record_attendance` RPC with idempotency key.
- `floating_settlement_screen.dart` — converted to ConsumerStatefulWidget using `settlementProvider`; Adopt button calls `record_wallet_transaction` RPC (settlement kind) for immutable ledger entry.
- `discussion_room_screen.dart` — dead snackbar replaced with navigation to `/study-assistant` route.
- `drm_lecture_player.dart` — dead fullscreen button replaced with actionable snackbar.
- Added routes `/group-management`, `/auto-queue-desk`, `/floating-settlement` to `app_router.dart`.

### Verification (all green)
- `flutter analyze --fatal-infos` → `No issues found!` (kashkool_app, kashkool_core, kashkool_admin)
- `dart run build_runner build` → succeeded cleanly
- `flutter test` → 30 passed (kashkool_app), 47 passed (kashkool_core), 7 passed (kashkool_admin)
- `deno task check` → 7 edge functions type-check clean
- `deno task test` → 6/6 catalog tests pass
- `python supabase/validate_sql.py` → All 8 SQL files parse
- Savior engine `GET /health` → `"status":"ok"`, `ledger.ok=true`, 5202 ledger entries
- `app_strings.dart` key parity: ar/en identical key sets

## Appendix C — Verified module: Per-Teacher / Per-Center Payment Channels & Receipt Verification Lifecycle (2026-11-23)

### What broke
- No payment channel/submission lifecycle existed: students had no way to submit payment receipts, teachers/centers had no setup or review surface, and the financial ledger had no payment-linked entries.

### Root cause
Gap between the cash-desk financial reality and the product: every teacher/center needs configurable payment channels (fawry / instaPay / Vodafone Cash / cash) with student receipt submission, staff 1-tap approval and structured rejection — all inside the immutable-ledger model.

### Permanent resolution
- New migration `supabase/migrations/20261123000008_payment_channels.sql` — `payment_channels`, `payment_submissions` (UNIQUE (channel_id, sender_reference) WHERE status <> 'rejected'), `ledger_entries` (append-only, void-only corrections); atomic RPCs `approve_payment_submission` (FOR UPDATE row lock, status flip, immutable ledger insert, activation hook) and `reject_payment_submission` (mandatory reason).
- New migration `supabase/migrations/20261123000009_payment_channels_rls.sql` — RLS + least-privilege policies for student / parent / teacher / secretary / admin; private `receipts` storage bucket (short-lived signed URLs) managed at the client layer.
- New shared models `packages/kashkool_core/lib/models/payment_channel_model.dart` — `PaymentChannelModel`, `PaymentSubmissionModel`, `LedgerEntryModel`, minor-unit money formatter (`formatPiasters` → `EgyptValidators.formatPiasters`).
- New student flow in `apps/kashkool_app` — `features/billing/providers/payment_submission_provider.dart`, `features/billing/presentation/student_checkout_screen.dart`, `features/billing/presentation/student_payment_tracking_screen.dart`; routes `/student-checkout`, `/student-payment-tracking`.
- New admin flow in `apps/kashkool_admin` — `features/payments/providers/payment_review_provider.dart` (`PaymentOpsService`: approve/reject/setChannelActive/addChannel), `features/payments/presentation/payment_review_queue_screen.dart` (signed receipt preview, 1-tap approve, structured reject), `features/payments/presentation/payment_channels_screen.dart` (channel setup + activate/deactivate); nav cards wired in `god_mode_dashboard.dart`.
- `apps/kashkool_admin/pubspec.yaml` — added `kashkool_core` path dependency for shared payment models.

### Verification (all green)
- `python supabase/validate_sql.py` → all 12 SQL files parse (incl. new 000008/000009/000010/000011)
- `flutter analyze --fatal-infos` → `No issues found!` (kashkool_core, kashkool_app, kashkool_admin)
- `flutter test` → 47 core, 30 app (incl. AR/EN l10n parity), 7 admin all passed (84 total)
- Savior engine `GET /health` → `"status":"ok"`, `ledger.ok=true`, ledger head `93abe7fc81d5b2cff1f4dd4e10673d0d3c22f68a024a1023d60a1a2c2faa047c`, entries 5406
- `app_strings.dart` key parity: ar/en identical key sets
- `git push origin develop` → commit `6108492`

### Deployment to Production (2026-11-23)
- **Project:** `kashkool` (ref: `pudaizumdahrlbckpyzq`)
- **Environment:** Production
- **Migrations applied:** 10/10 via `supabase db push --remote --yes` (migration 000011 ready for next push)
- **Storage bucket:** `receipts` (private, 5MB limit, JPEG/PNG/WebP/PDF)
- **Storage policies:** 4 RLS policies (student upload/read, staff read, service_role full)
- **Deployed at:** 2026-11-23T20:45:00+02:00
- **Verification:** `supabase migration list --remote` confirms all 10 migrations synced

## Appendix D — Zero-Cost Onboarding (2026-11-24)

### What was implemented
Zero-Cost student/parent onboarding without paid SMS gateways:
- **Email OTP** (`requestCodeByEmail` / `confirmCodeByEmail`) — free email-based verification
- **QR Activation** (`activateWithQrCode`) — secretary generates a one-time code locally, student enters it in the app
- **Phone SMS** — kept as optional fallback

### Files changed
- `apps/kashkool_app/lib/features/auth/data/auth_repository.dart` — `requestCodeByEmail()`, `confirmCodeByEmail()`, `activateWithQrCode()`, new error codes (`invalidEmail`, `invalidQrCode`)
- `apps/kashkool_app/lib/features/auth/providers/auth_provider.dart` — new `AuthStatus` values (`emailSent`, `verifyingEmail`, `qrActivated`), `email` field in `AuthState`
- `apps/kashkool_app/lib/features/auth/presentation/auth_error_text.dart` — localized error messages for new codes
- `apps/kashkool_app/lib/core/l10n/app_strings.dart` — `errInvalidEmail`, `errInvalidQrCode` (EN + AR)
- `apps/kashkool_app/lib/core/router/app_router.dart` — redirect switch updated for new statuses
- `apps/kashkool_admin/lib/features/payments/presentation/qr_activation_screen.dart` — secretary QR code generation UI
- `supabase/migrations/20261123000011_qr_activation_channels.sql` — `qr_activation_code` + `qr_activated_at` on `profiles`, expanded `channel_type` check

### Verification
- All 3 packages: `flutter analyze --fatal-infos` → 0 issues
- All tests: 84 passed (47 core + 30 app + 7 admin)
