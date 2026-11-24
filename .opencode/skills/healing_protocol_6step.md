# 🛡️ SKILL: 6-Step Surgical Healing Protocol
**ID:** `kashkool-healing-protocol-6step-v1`
**Activation:** AUTOMATIC — Triggers on ANY compile error, runtime crash, broken wiring, dependency conflict, or architectural drift across `kashkool_app`, `kashkool_admin`, `kashkool_core`, `backend/`
**Enforcement Level:** MANDATORY — Zero tolerance for band-aids

---

## 🎯 PURPOSE
Execute the **6-Step Surgical Healing Protocol** from Part III of the Supreme Constitution. Never apply superficial fixes. Fix the root cause permanently.

---

## 🔄 AUTO-ACTIVATION TRIGGERS
- `flutter analyze` reports errors
- `dart run build_runner` fails
- Runtime exceptions (caught by error tracking)
- `npm run build` fails in backend
- Architectural drift detected (duplicate models, version skew)

---

## 📋 THE 6 STEPS (MANDATORY SEQUENCE)

### STEP 1: Root-Cause Forensics (Never Treat Symptoms)
```bash
# Trace the FULL call chain across all 4 layers:
# UI/Widget Tree ← Riverpod State/AsyncValue ← Offline Drift/Network Interceptor ← RLS policies/Edge Function/Schema

# Tools:
flutter analyze --fatal-infos --verbose
dart run build_runner build --delete-conflicting-outputs --verbose
grep -r "error\|Exception\|Failed" . --include="*.dart" --include="*.ts"

# FORBIDDEN (auto-reject):
# - @ts-ignore, // ignore: all
# - catch (_) {} empty catches
# - forcing nullable casts (!) without verification
# - commenting out broken code
```

### STEP 2: Cross-Monorepo Consolidation & Dependency Alignment
```bash
# Single Source of Truth: Consolidate duplicates into kashkool_core
# Find duplicates:
dart run scripts/find_duplicate_models.dart

# Pubspec alignment:
cd packages/kashkool_core && flutter pub deps
cd apps/kashkool_app && flutter pub deps
cd apps/kashkool_admin && flutter pub deps

# Version lock check:
melos bootstrap  # or flutter pub get in all 3
# Verify zero skew: riverpod, drift, freezed, go_router, supabase_flutter
```

### STEP 3: Build-Runner & Code-Gen Synchronization
```bash
# Whenever modifying @riverpod, @freezed, @JsonSerializable, @DriftDatabase:
dart run build_runner build --delete-conflicting-outputs

# NEVER manually edit .g.dart or .freezed.dart
# Fix SOURCE ANNOTATIONS until generation succeeds cleanly
```

### STEP 4: Supabase & Backend Contract Reconciliation
```bash
# Rule & Index Alignment:
# For every new .eq()/.order() in Flutter:
# 1. Check supabase/migrations/20261123000003_rls.sql
# 2. Check supabase/migrations/20261123000001_schema.sql
# 3. Add matching rule + composite index

# Edge Function Payload Parity:
# supabase/functions/** interfaces MUST match kashkool_core DTOs field-for-field
dart run scripts/verify_dto_parity.dart
```

### STEP 5: UI Layout, Overflow & Bilingual Stress-Test
```bash
# Eliminate:
# - RenderFlex overflowed
# - Unbounded height in Column/ListView
# - BackdropFilter clipping artifacts

# Verify BOTH locales × viewports:
# Arabic (RTL) + English (LTR) × 360px + 1920px
flutter test --platform=chrome --dart-define=LOCALE=ar
flutter test --platform=chrome --dart-define=LOCALE=en
# Responsive tests at 360px, 800px, 1200px, 1920px
```

### STEP 6: Zero-Issue Exit Criteria (MANDATORY LOOP)
```bash
# ALL 4 MUST PASS CONSECUTIVELY:
# 1. dart run build_runner build --delete-conflicting-outputs → Exit Code 0
# 2. flutter analyze --fatal-infos (core, app, admin) → "No issues found!"
# 3. npm run build (supabase/functions) → Exit Code 0
# 4. Update PROJECT_STATE.json + AGENTS.md with:
#    - What broke
#    - Why it broke (root cause)
#    - How permanently resolved
#    - Prevention for recurrence

# LOOP UNTIL ALL 4 GREEN
```

---

## 🤖 AUTOMATED HEALING SCRIPT
```dart
// scripts/healing_protocol.dart
import 'dart:io';
import 'package:args/args.dart';

class HealingStep {
  final String name;
  final String workingDir;
  final String command;
  final bool required;
  
  HealingStep(this.name, this.workingDir, this.command, {this.required = true});
}

void main(List<String> args) async {
  final steps = [
    HealingStep('Root-Cause Forensics', '.', 'dart run scripts/root_cause_forensics.dart'),
    HealingStep('Consolidation Check', '.', 'dart run scripts/find_duplicates.dart'),
    HealingStep('Build Runner (core)', 'packages/kashkool_core', 'dart run build_runner build --delete-conflicting-outputs'),
    HealingStep('Build Runner (app)', 'apps/kashkool_app', 'dart run build_runner build --delete-conflicting-outputs'),
    HealingStep('Build Runner (admin)', 'apps/kashkool_admin', 'dart run build_runner build --delete-conflicting-outputs'),
    HealingStep('Analyze (core)', 'packages/kashkool_core', 'flutter analyze --fatal-infos'),
    HealingStep('Analyze (app)', 'apps/kashkool_app', 'flutter analyze --fatal-infos'),
    HealingStep('Analyze (admin)', 'apps/kashkool_admin', 'flutter analyze --fatal-infos'),
    HealingStep('Supabase Parity', '.', 'dart run scripts/supabase/validate_sql.py'),
    HealingStep('DTO Parity', '.', 'dart run scripts/verify_dto_parity.dart'),
    HealingStep('Backend Build', 'supabase/functions', 'npm run build'),
    HealingStep('UI Stress Test', '.', 'dart run scripts/ui_stress_test.dart'),
    HealingStep('Update State', '.', 'dart run scripts/update_project_state.dart'),
    HealingStep('Update AGENTS', '.', 'dart run scripts/update_agents_md.dart'),
  ];
  
  for (final step in steps) {
    print('🔄 ${step.name}...');
    final result = await Process.run('sh', ['-c', step.command], 
      workingDirectory: step.workingDir, runInShell: true);
    if (result.exitCode != 0) {
      print('❌ ${step.name} FAILED');
      print(result.stdout);
      print(result.stderr);
      if (step.required) exit(1);
    } else {
      print('✅ ${step.name} passed');
    }
  }
  
  print('🎉 HEALING COMPLETE — Zero-Issue Exit Criteria MET');
}
```

---

## 🛑 VIOLATION RESPONSE
- Skipping any step = **rejected**
- Band-aid fix detected = **rejected** (reverts to Step 1)
- Exit criteria not met = **continues looping**
- Output includes: step-by-step trace, root cause, permanent fix applied

---

## 💡 INTEGRATION WITH SAVIOR CORE
- **OR & Context Pruning**: Filters healing paths by error type, affected layers, historical patterns
- **Pulse-Triggered Routing**: Complex root-cause analysis escalates to cloud for multi-layer tracing
- **360° Awareness**: Monitors system health across all packages, predicts drift before failure
- **Homeostasis**: Auto-triggers healing on any anomaly, maintains zero-issue equilibrium