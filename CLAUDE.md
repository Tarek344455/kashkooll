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
