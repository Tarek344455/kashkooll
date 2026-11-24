# 🛡️ SKILL: Gate 5 — Automated Verification Loop Enforcer
**ID:** `kashkool-gate5-verification-loop-v1`
**Activation:** AUTOMATIC — Triggers on any code change, pre-commit, pre-push, CI/CD in `kashkool_app`, `kashkool_admin`, `packages/kashkool_core/`, `backend/functions/`
**Enforcement Level:** MANDATORY — All 4 checks must pass consecutively

---

## 🎯 PURPOSE
Enforce **Gate 5 of the Supreme Constitution**: Run `build_runner`, `flutter analyze --fatal-infos` (0 issues), verify `app_strings.dart` parity, update `PROJECT_STATE.json` and `AGENTS.md`.

---

## 🔄 AUTO-ACTIVATION TRIGGERS
- Any `git commit` (pre-commit hook)
- Any `git push` (pre-push hook)
- CI/CD pipeline (GitHub Actions)
- Manual invocation via `dart run scripts/verify_all.dart`

---

## 📋 FOUR MANDATORY CHECKS (All Must Pass)

### 1. Build Runner & Code Generation
```bash
# Run in ALL 3 Dart packages
cd packages/kashkool_core && dart run build_runner build --delete-conflicting-outputs
cd apps/kashkool_app && dart run build_runner build --delete-conflicting-outputs
cd apps/kashkool_admin && dart run build_runner build --delete-conflicting-outputs

# Exit code MUST be 0
# No manual .g.dart/.freezed.dart edits allowed
```

### 2. Static Analysis — Zero Issues
```bash
# Run in ALL 3 Dart packages
cd packages/kashkool_core && flutter analyze --fatal-infos
cd apps/kashkool_app && flutter analyze --fatal-infos
cd apps/kashkool_admin && flutter analyze --fatal-infos

# Output MUST be: "No issues found!"
# --fatal-infos treats infos as errors
```

### 3. String Parity (AR/EN 100%)
```bash
# Verify app_strings.dart keys match between ar.arb and en.arb
dart run scripts/verify_string_parity.dart

# Output: 
# ✅ 100% parity (XXX keys matched)
# ❌ Missing keys: [list]
```

### 4. Backend Build & State Update
```bash
# Backend TypeScript build
cd backend/functions && npm run build
# Exit code MUST be 0

# Update PROJECT_STATE.json
dart run scripts/update_project_state.dart

# Update AGENTS.md with module status
dart run scripts/update_agents_md.dart
```

---

## 🤖 AUTOMATION SCRIPTS

### verify_all.dart (Master Verification)
```dart
// scripts/verify_all.dart
import 'dart:io';
import 'package:args/args.dart';

void main(List<String> args) async {
  final parser = ArgParser()..addFlag('ci', abbr: 'c', defaultsTo: false);
  final results = parser.parse(args);
  final isCI = results['ci'] as bool;
  
  final checks = [
    ('Build Runner (core)', 'packages/kashkool_core', 'dart run build_runner build --delete-conflicting-outputs'),
    ('Build Runner (app)', 'apps/kashkool_app', 'dart run build_runner build --delete-conflicting-outputs'),
    ('Build Runner (admin)', 'apps/kashkool_admin', 'dart run build_runner build --delete-conflicting-outputs'),
    ('Analyze (core)', 'packages/kashkool_core', 'flutter analyze --fatal-infos'),
    ('Analyze (app)', 'apps/kashkool_app', 'flutter analyze --fatal-infos'),
    ('Analyze (admin)', 'apps/kashkool_admin', 'flutter analyze --fatal-infos'),
    ('String Parity', '.', 'dart run scripts/verify_string_parity.dart'),
    ('Backend Build', 'backend/functions', 'npm run build'),
    ('Update State', '.', 'dart run scripts/update_project_state.dart'),
    ('Update AGENTS', '.', 'dart run scripts/update_agents_md.dart'),
  ];
  
  for (final (name, dir, cmd) in checks) {
    print('🔄 $name...');
    final result = await Process.run('sh', ['-c', cmd], workingDirectory: dir, runInShell: true);
    if (result.exitCode != 0) {
      print('❌ $name FAILED');
      print(result.stdout);
      print(result.stderr);
      exit(1);
    }
    print('✅ $name passed');
  }
  
  print('🎉 ALL CHECKS PASSED');
}
```

### verify_string_parity.dart
```dart
// scripts/verify_string_parity.dart
import 'dart:io';
import 'dart:convert';

void main() {
  final arFile = File('apps/kashkool_app/l10n/app_ar.arb');
  final enFile = File('apps/kashkool_app/l10n/app_en.arb');
  
  final arJson = jsonDecode(arFile.readAsStringSync()) as Map<String, dynamic>;
  final enJson = jsonDecode(enFile.readAsStringSync()) as Map<String, dynamic>;
  
  final arKeys = arJson.keys.where((k) => !k.startsWith('@')).toSet();
  final enKeys = enJson.keys.where((k) => !k.startsWith('@')).toSet();
  
  final missingInAr = enKeys.difference(arKeys);
  final missingInEn = arKeys.difference(enKeys);
  
  if (missingInAr.isEmpty && missingInEn.isEmpty) {
    print('✅ 100% parity (${arKeys.length} keys matched)');
    exit(0);
  } else {
    print('❌ Missing in AR: $missingInAr');
    print('❌ Missing in EN: $missingInEn');
    exit(1);
  }
}
```

---

## 🔗 GIT HOOKS (Husky / pre-commit)
```json
// .husky/pre-commit
#!/bin/sh
dart run scripts/verify_all.dart
```

```json
// .husky/pre-push
#!/bin/sh
dart run scripts/verify_all.dart --ci
```

---

## 🛑 VIOLATION RESPONSE
Any check fails = **commit/push blocked**. Output includes:
1. Which check failed
2. Exact command and output
3. Required fix
4. Auto-fix suggestions where possible

---

## 💡 INTEGRATION WITH SAVIOR CORE
- **OR & Context Pruning**: Filters verification scope by changed files (incremental verification)
- **Pulse-Triggered Routing**: Complex analysis failures escalate to cloud for root-cause diagnosis
- **360° Awareness**: Tracks verification health across all packages in real-time
- **Homeostasis**: Auto-runs verification on file save, maintains zero-issue state continuously