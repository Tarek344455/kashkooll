# 🛡️ SKILL: Chain of Thought Reasoning (Dart-Native)
**ID:** `kashkool-reasoning-cot-v1`
**Activation:** AUTOMATIC — Triggers on complex debugging, root-cause analysis, architectural decisions, or when `reasoning: true` in task context
**Enforcement Level:** MANDATORY — Part III Forensics of Supreme Constitution

---

## 🎯 PURPOSE
Provide structured, verifiable reasoning for complex problems. Based on extracted skill from Savior vault, converted to Dart-native with Zod-like validation. Used for: Root-Cause Forensics, Debugging, Code Review, Architectural Decisions.

---

## 🔄 AUTO-ACTIVATION TRIGGERS
- `healing_protocol_6step` Step 1 (Root-Cause Forensics)
- Complex multi-layer bugs
- Architecture decision records
- Security audit analysis
- Performance bottleneck investigation

---

## 📋 REASONING STRUCTURE (Dart Implementation)

### Core Types
```dart
// kashkool_core/lib/utils/reasoning.dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:kashkool_core/utils/validation.dart'; // Zod-like

part 'reasoning.freezed.dart';
part 'reasoning.g.dart';

@freezed
class ThoughtStep with _$ThoughtStep {
  const factory ThoughtStep({
    required int step,
    required String statement,
    required String justification,
    required double confidence, // 0.0 - 1.0
    required List<String> evidence, // File paths, logs, test results
    Map<String, dynamic>? metadata,
  }) = _ThoughtStep;
  
  // Validation
  bool get isValid => 
    step > 0 && 
    statement.isNotEmpty && 
    justification.isNotEmpty && 
    confidence >= 0.0 && confidence <= 1.0 &&
    evidence.isNotEmpty;
}

@freezed
class ChainOfThought with _$ChainOfThought {
  const factory ChainOfThought({
    required String problem,
    required List<ThoughtStep> steps,
    required String conclusion,
    required bool verified,
    required DateTime createdAt,
    String? sessionId,
    Map<String, dynamic>? context,
  }) = _ChainOfThought;
  
  // Backward verification: each step builds on previous
  bool verify() {
    if (steps.isEmpty) return false;
    if (!verified) return false;
    
    for (int i = 1; i < steps.length; i++) {
      final current = steps[i];
      final previous = steps[i - 1];
      
      // Current justification must reference previous statement
      if (!current.justification.contains(previous.statement)) {
        return false;
      }
      
      // Confidence should generally increase or stay stable
      if (current.confidence < previous.confidence - 0.1) {
        return false; // Significant confidence drop without explanation
      }
    }
    
    // Conclusion must be supported by final step
    if (!steps.last.statement.contains(conclusion.split(' ').first)) {
      return false;
    }
    
    return true;
  }
  
  // Forward verification: conclusion logically follows
  bool verifyForward() {
    // Check logical flow from problem → steps → conclusion
    final keyTerms = problem.split(' ').where((w) => w.length > 3).toSet();
    final conclusionTerms = conclusion.split(' ').where((w) => w.length > 3).toSet();
    
    // At least some problem terms should appear in conclusion
    return keyTerms.intersection(conclusionTerms).isNotEmpty;
  }
}
```

### Reasoning Engine
```dart
// kashkool_core/lib/services/reasoning_engine.dart
class ReasoningEngine {
  final List<ChainOfThought> _history = [];
  
  // Start a new reasoning chain
  ChainOfThought startChain({
    required String problem,
    Map<String, dynamic>? context,
  }) {
    return ChainOfThought(
      problem: problem,
      steps: [],
      conclusion: '',
      verified: false,
      createdAt: DateTime.now(),
      sessionId: _generateSessionId(),
      context: context,
    );
  }
  
  // Add a thought step
  ChainOfThought addStep(ChainOfThought chain, ThoughtStep step) {
    if (!step.isValid) throw ArgumentError('Invalid thought step');
    
    final newSteps = [...chain.steps, step];
    return chain.copyWith(steps: newSteps);
  }
  
  // Finalize with conclusion
  ChainOfThought conclude(ChainOfThought chain, String conclusion) {
    final concluded = chain.copyWith(
      conclusion: conclusion,
      verified: true,
    );
    
    if (!concluded.verify()) {
      throw StateError('Chain verification failed: backward check');
    }
    if (!concluded.verifyForward()) {
      throw StateError('Chain verification failed: forward check');
    }
    
    _history.add(concluded);
    return concluded;
  }
  
  // Get reasoning history for audit
  List<ChainOfThought> getHistory({String? sessionId}) {
    if (sessionId == null) return _history;
    return _history.where((c) => c.sessionId == sessionId).toList();
  }
}
```

### Zod-Like Validation (for evidence)
```dart
// kashkool_core/lib/utils/validation.dart
abstract class Schema<T> {
  T parse(dynamic input);
  bool validate(dynamic input);
  String? getError(dynamic input);
}

class StringSchema extends Schema<String> {
  final int? minLength;
  final int? maxLength;
  final RegExp? pattern;
  
  StringSchema({this.minLength, this.maxLength, this.pattern});
  
  @override
  String parse(dynamic input) {
    if (input is! String) throw ValidationError('Expected string');
    if (minLength != null && input.length < minLength!) {
      throw ValidationError('String too short');
    }
    if (maxLength != null && input.length > maxLength!) {
      throw ValidationError('String too long');
    }
    if (pattern != null && !pattern!.hasMatch(input)) {
      throw ValidationError('Pattern mismatch');
    }
    return input;
  }
  
  @override
  bool validate(dynamic input) {
    try { parse(input); return true; } catch (_) { return false; }
  }
  
  @override
  String? getError(dynamic input) {
    try { parse(input); return null; } catch (e) { return e.toString(); }
  }
}

class NumberSchema extends Schema<num> {
  final num? min;
  final num? max;
  final bool integer;
  
  NumberSchema({this.min, this.max, this.integer = false});
  
  @override
  num parse(dynamic input) {
    if (input is! num) throw ValidationError('Expected number');
    if (integer && input is! int) throw ValidationError('Expected integer');
    if (min != null && input < min!) throw ValidationError('Below minimum');
    if (max != null && input > max!) throw ValidationError('Above maximum');
    return input;
  }
  
  @override
  bool validate(dynamic input) {
    try { parse(input); return true; } catch (_) { return false; }
  }
  
  @override
  String? getError(dynamic input) {
    try { parse(input); return null; } catch (e) { return e.toString(); }
  }
}

// Pre-defined schemas for reasoning
const confidenceSchema = NumberSchema(min: 0.0, max: 1.0);
const stepNumberSchema = NumberSchema(min: 1, integer: true);
const nonEmptyStringSchema = StringSchema(minLength: 1);
```

---

## 🔍 USAGE IN HEALING PROTOCOL (Step 1)

```dart
// scripts/root_cause_forensics.dart
import 'package:kashkool_core/utils/reasoning.dart';

void main() async {
  final engine = ReasoningEngine();
  
  // Problem: "Flutter analyze fails with 'Undefined class Riverpod' in kashkool_app"
  var chain = engine.startChain(
    problem: 'Flutter analyze fails with Undefined class Riverpod in kashkool_app',
    context: {'package': 'kashkool_app', 'error': 'Undefined class Riverpod'},
  );
  
  // Step 1: Check pubspec.yaml
  chain = engine.addStep(chain, ThoughtStep(
    step: 1,
    statement: 'riverpod dependency missing from kashkool_app/pubspec.yaml',
    justification: 'Error "Undefined class Riverpod" typically means package not in dependencies',
    confidence: 0.8,
    evidence: ['apps/kashkool_app/pubspec.yaml'],
  ));
  
  // Step 2: Verify in pubspec
  chain = engine.addStep(chain, ThoughtStep(
    step: 2,
    statement: 'riverpod ^2.5.0 present in kashkool_core but NOT in kashkool_app',
    justification: 'Checked pubspec.yaml files: core has riverpod, app does not',
    confidence: 0.95,
    evidence: ['packages/kashkool_core/pubspec.yaml', 'apps/kashkool_app/pubspec.yaml'],
  ));
  
  // Step 3: Check imports
  chain = engine.addStep(chain, ThoughtStep(
    step: 3,
    statement: 'kashkool_app imports riverpod from kashkool_core re-export',
    justification: 'Found "export package:riverpod/riverpod.dart" in kashkool_core, but app does not depend on core properly',
    confidence: 0.9,
    evidence: ['packages/kashkool_core/lib/kashkool_core.dart', 'apps/kashkool_app/pubspec.yaml'],
  ));
  
  // Step 4: Root cause
  chain = engine.addStep(chain, ThoughtStep(
    step: 4,
    statement: 'kashkool_app missing dependency on kashkool_core in pubspec.yaml',
    justification: 'App uses core exports but does not declare dependency; pub get does not pull transitive deps for Flutter packages',
    confidence: 0.98,
    evidence: ['apps/kashkool_app/pubspec.yaml'],
  ));
  
  // Conclusion
  final concluded = engine.conclude(chain, 
    'Add kashkool_core as dependency in kashkool_app/pubspec.yaml and run flutter pub get'
  );
  
  print('✅ Reasoning verified: ${concluded.verify()}');
  print('📋 Conclusion: ${concluded.conclusion}');
}
```

---

## 🔍 VERIFICATION CHECKLIST
```bash
# 1. Reasoning types in kashkool_core
ls packages/kashkool_core/lib/utils/ | grep reasoning

# 2. Validation schemas
ls packages/kashkool_core/lib/utils/ | grep validation

# 3. Reasoning engine service
ls packages/kashkool_core/lib/services/ | grep reasoning

# 4. Used in healing protocol
grep -r "ChainOfThought\|ReasoningEngine" scripts/
```

---

## 🛑 VIOLATION RESPONSE
- Reasoning without evidence = **rejected**
- Chain fails verification = **rejected** (must restart)
- Confidence without justification = **rejected**
- Conclusion not supported by steps = **rejected**
- Output includes: failed verification step, required fix

---

## 💡 INTEGRATION WITH SAVIOR CORE
- **OR & Context Pruning**: Filters reasoning paths by error type, historical patterns, affected layers
- **Pulse-Triggered Routing**: Complex multi-system reasoning escalates to cloud for broader context
- **360° Awareness**: Tracks reasoning quality, common failure patterns, resolution effectiveness
- **Homeostasis**: Learns from successful chains, suggests steps for similar problems