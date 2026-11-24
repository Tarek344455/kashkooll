# 🛡️ SKILL: Gate 1 — Full Vertical Slice Wiring Enforcer
**ID:** `kashkool-gate1-vertical-slice-v1`
**Activation:** AUTOMATIC — Triggers on any UI/widget creation, Riverpod provider, repository, or Postgres query in `kashkool_app`, `kashkool_admin`, `packages/kashkool_core/`
**Enforcement Level:** MANDATORY — Zero tolerance for incomplete wiring

---

## 🎯 PURPOSE
Enforce **Gate 1 of the Supreme Constitution**: Every feature must be a complete vertical slice — UI → Riverpod AsyncNotifier → Repository (Drift + Supabase Postgres) → RLS policies / Edge Function. No `// TODO`, empty callbacks, fake loaders, or dummy lists.

---

## 🔄 AUTO-ACTIVATION TRIGGERS
- Creating/editing any `.dart` file in `lib/features/**`, `lib/providers/**`, `lib/repositories/**`
- Adding new Riverpod providers (`@riverpod`, `AsyncNotifier`, `Notifier`)
- Writing Postgres queries (`.eq()`, `.gte()`, `.order()`, `.limit()`)
- Creating new Edge Functions in `supabase/functions/`

---

## 📋 ENFORCEMENT RULES

### 1. UI Layer (Widget)
- ✅ **Required:** Real `Consumer`/`ConsumerWidget` with `ref.watch(provider)`
- ✅ **Required:** Proper `AsyncValue` handling: `data`, `loading`, `error`, `empty`
- ❌ **Forbidden:** `onPressed: () {}`, `Future.delayed` fake loaders, hardcoded `List.generate(5, ...)`

### 2. State Layer (Riverpod)
- ✅ **Required:** `AsyncNotifier`/`Notifier` with real `build()` and mutation methods
- ✅ **Required:** Proper error handling with `AsyncValue.error()`
- ✅ **Required:** Optimistic updates where applicable
- ❌ **Forbidden:** `StateProvider` for complex async logic, `FutureProvider` without proper error handling

### 3. Repository Layer (Drift + Supabase Postgres)
- ✅ **Required:** Repository interface in `kashkool_core` with Drift (offline) + Supabase Postgres (online) implementations
- ✅ **Required:** All queries use typed DTOs from `kashkool_core`
- ✅ **Required:** Offline-first: Drift cache → Supabase sync
- ❌ **Forbidden:** Direct Supabase Postgres calls in UI, raw `Map<String, dynamic>` in business logic

### 4. Backend Layer (RLS policies + Edge Functions)
- ✅ **Required:** Every Postgres query has matching rule in `supabase/migrations/20261123000003_rls.sql`
- ✅ **Required:** Composite indexes in `supabase/migrations/20261123000001_schema.sql` for `.eq().order()`
- ✅ **Required:** Edge Function payloads match Dart DTOs field-for-field
- ❌ **Forbidden:** Deploying without rule/index verification

---

## 🔍 VERIFICATION CHECKLIST (Run Before Commit)
```bash
# 1. Build runner sync
dart run build_runner build --delete-conflicting-outputs

# 2. Static analysis (MUST be zero issues)
flutter analyze --fatal-infos

# 3. Verify RLS policies exist for all queries
grep -r "\.where\|\.orderBy" lib/ --include="*.dart" | while read line; do
  # Check corresponding rule exists
done

# 4. Verify indexes
cat supabase/migrations/20261123000001_schema.sql | jq '.indexes[] | select(.fields | length > 1)'
```

---

## 🛑 VIOLATION RESPONSE
Any incomplete vertical slice is **rejected immediately**. The skill outputs:
1. Which layer is incomplete
2. Exact file:line references
3. Required fix pattern with code example
4. Blocks commit until resolved

---

## 💡 INTEGRATION WITH SAVIOR CORE
- Uses **OR & Context Pruning** to filter candidate fix paths against active constraints
- Triggers **Pulse-Triggered Hybrid Routing** for complex multi-layer fixes (escalates to cloud only when needed)
- Feeds **360° Awareness** with real-time wiring state across all 4 layers