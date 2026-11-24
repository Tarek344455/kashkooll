# 🛡️ SKILL: Kashkool Supreme Constitution Enforcer (MANDATORY)
**ID:** `kashkool-constitution-v1`
**Activation:** AUTOMATIC — Must trigger BEFORE any code writing, editing, or generation in the Kashkool project (`kashkool_app`, `kashkool_admin`, `backend/`, `packages/kashkool_core/`).
**Enforcement Level:** MANDATORY — Zero tolerance for violations.

---

## 🎯 PURPOSE
This skill enforces **THE KASHKOOL SUPREME CONSTITUTION** as a pre-flight gate on every code change. No code is written, modified, or committed until the constitution is acknowledged and applied.

---

## 🔄 AUTO-ACTIVATION TRIGGER
This skill MUST activate automatically when:
- A user requests any feature, screen, API, or database change in the Kashkool project.
- Before writing any Dart, TypeScript, JSON, YAML, or Markdown file inside `E:\opencode\projects\kashkool\`.
- Before any `git commit` or `git push` for Kashkool.

---

## 📜 CONSTITUTION SUMMARY (READ & APPLY FIRST)

### PART I — Business & Product Mindset (Egyptian EdTech Founder Thinking)
1. **Flexible Money Flows:** Support Full Payment, Partial/Installment, Book Reservation Fees, Teacher Discounts, Cash-to-Wallet Top-ups.
2. **3-Second Queue Rule:** Secretary actions complete in **1 tap/scan (<1 sec)** with Green/Amber/Red color feedback.
3. **Rural & Mobile Data Optimization:** Aggressive compression, SQLite caching, PDF delta-loading, adaptive low-bitrate video.
4. **Immutable Financial Ledger:** No hard-deletes or silent edits. Corrections via Void/Refund Entry in `/tenants/{tenantId}/audit_logs`.
5. **Instant Multi-Center Settlement:** 1-tap end-of-day reconciliation formula.
6. **Addictive Retention:** Leaderboards, streak badges, exam mastery rings, remedial practice, weekly parent digest.
7. **Invisible Intelligence:** Zero AI buzzwords in UI. Use `المساعد الدراسي`, `التقارير التلقائية`, `بنك الأسئلة الذكي`.

### PART II — Zero-Defect Engineering Gates (ALL 5 REQUIRED)
**Gate 1: Full Vertical Slice Wiring** — No `// TODO`, `onPressed: () {}`, fake loaders, or dummy lists. Wire UI → Riverpod AsyncNotifier → Repository (Drift + Supabase Postgres) → RLS policies / Edge Function.

**Gate 2: 4-State UI Resilience** — Every screen must handle: Loading (Space Glass shimmer), Empty (localized CTA), Error (human-friendly message + Retry button), Populated (responsive 360px–1920px+).

**Gate 3: Cross-App Real-Time Sync** — Secretary QR scan → Student/Teacher/Parent update instantly. Kill-Switch or Tenant Freeze → enforced `<2 seconds` via live config stream.

**Gate 4: Cross-Platform & Security** — No `dart:io` in shared files. Enforce `FLAG_SECURE` + `DynamicWatermarkOverlay` on paid content. Every Postgres query must match `supabase/migrations/20261123000003_rls.sql` and `supabase/migrations/20261123000001_schema.sql`.

**Gate 5: Automated Verification Loop** — Run `dart run build_runner build`, `flutter analyze --fatal-infos` (0 issues), verify `app_strings.dart` key parity (ar/en), update `PROJECT_STATE.json` and `AGENTS.md`.

---

## ⚡ PRE-CODE CHECKLIST (MUST COMPLETE BEFORE ANY CODING)
- [ ] Read `AGENTS.md` and `CLAUDE.md` fully.
- [ ] Identify which PART I commercial pillar applies.
- [ ] Map the feature across all 4 architectural layers (Gate 1).
- [ ] Plan all 4 UI states (Gate 2).
- [ ] Plan cross-app sync propagation (Gate 3).
- [ ] Verify RLS policies and indexes exist for every query (Gate 4).
- [ ] Schedule verification commands (Gate 5).

---

## 🚫 PROHIBITED PATTERNS (AUTO-REJECT)
- `// TODO` placeholders in production code.
- `onPressed: () {}` empty callbacks.
- `Future.delayed` fake loaders.
- Hardcoded dummy/mock lists in feature screens.
- Raw stack traces or Supabase error codes shown to users.
- `dart:io` imports in shared UI/business logic.
- Missing `supabase/migrations/20261123000003_rls.sql` or `supabase/migrations/20261123000001_schema.sql` entries for new queries.
- AI/LLM/Boot/sparkle/robot icons or labels in UI strings.

---

## ✅ POST-CODE VERIFICATION (MANDATORY)
After writing any module:
1. `dart run build_runner build --delete-conflicting-outputs`
2. `flutter analyze --fatal-infos` (MUST return 0 issues)
3. Verify `app_strings.dart` 100% key parity between `ar` and `en`
4. Update `PROJECT_STATE.json` and `AGENTS.md` with module status

---

## 🛑 VIOLATION RESPONSE
Any code violating this constitution is considered **broken** and must be **rejected and rewritten immediately**. No exceptions.

---

## 🩺 PART III — Autonomous Self-Healing, Debugging & System Consolidation (Fix Like a Surgeon)

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
