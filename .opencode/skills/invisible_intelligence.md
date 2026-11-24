# 🛡️ SKILL: Invisible Intelligence
**ID:** `kashkool-invisible-intelligence-v1`
**Activation:** AUTOMATIC — Triggers on ANY AI/ML feature, smart recommendation, automated report, or intelligent assistant in `kashkool_app`, `kashkool_admin`, `packages/kashkool_core/`, `backend/functions/`
**Enforcement Level:** MANDATORY — Part I Pillar 4 of Supreme Constitution

---

## 🎯 PURPOSE
Enforce **Invisible Intelligence** (Part I, Pillar 4): Zero AI buzzwords in UI. Use Arabic terms: `المساعد الدراسي` (Study Assistant), `التقارير التلقائية` (Auto Reports), `بنك الأسئلة الذكي` (Smart Question Bank).

---

## 🔄 AUTO-ACTIVATION TRIGGERS
- Adding any AI/ML powered feature
- Creating recommendation engines
- Building automated reporting
- Implementing smart question selection
- Writing user-facing copy for intelligent features

---

## 📋 FORBIDDEN vs REQUIRED TERMINOLOGY

### ❌ FORBIDDEN (Auto-Reject)
| English | Arabic | Why |
|---------|--------|-----|
| "AI" / "Artificial Intelligence" | "ذكاء اصطناعي" | Buzzword, scares parents |
| "ML" / "Machine Learning" | "تعلم آلي" | Technical jargon |
| "LLM" / "Large Language Model" | "نموذج لغوي كبير" | Meaningless to users |
| "GPT" / "Generative AI" | "توليدي" | Brand-specific, confusing |
| "Smart" / "Intelligent" (as label) | "ذكي" (كعنوان) | Vague, overused |
| "Magic" / "Auto-magic" | "سحري" | Unprofessional |
| "Bot" / "Chatbot" | "بوت" | Impersonal |
| "Algorithm" | "خوارزمية" | Technical |
| "Neural" / "Deep Learning" | "عصبي" / "تعلم عميق" | Too technical |

### ✅ REQUIRED ARABIC TERMS
| Feature | Arabic Term | English Equivalent |
|---------|-------------|-------------------|
| Study Assistant | **المساعد الدراسي** | Personal tutor |
| Auto Reports | **التقارير التلقائية** | Progress reports |
| Smart Question Bank | **بنك الأسئلة الذكي** | Adaptive practice |
| Learning Path | **مسار التعلم** | Curriculum guide |
| Weak Area Detection | **كشف نقاط الضعف** | Gap analysis |
| Personalized Schedule | **جدول مخصص** | Study planner |
| Progress Prediction | **توقع التقدم** | Forecasting |
| Content Recommendation | **اقتراح المحتوى** | Next steps |

---

## 📋 IMPLEMENTATION PATTERNS

### 1. Study Assistant (Not "AI Tutor")
```dart
// UI Label: "المساعد الدراسي"
// Internal: AI-powered but never labeled as such
class StudyAssistantWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.school_outlined), // Not robot/AI icon
        title: Text(context.l10n.studyAssistantTitle), // "المساعد الدراسي"
        subtitle: Text(context.l10n.studyAssistantSubtitle), // "يساعدك على التركيز على ما تحتاجه"
        trailing: FilledButton(
          onPressed: () => _openAssistant(ref),
          child: Text(context.l10n.studyAssistantStart), // "ابدأ الآن"
        ),
      ),
    );
  }
}
```

### 2. Auto Reports (Not "AI-Generated Reports")
```dart
// UI Label: "التقارير التلقائية"
// Generated weekly, sent to parents
class AutoReportsScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        Text(context.l10n.autoReportsTitle, style: Theme.of(context).headlineMedium), // "التقارير التلقائية"
        Text(context.l10n.autoReportsDescription), // "تقارير أسبوعية عن تقدم ابنك تُرسل تلقائياً"
        _ReportList(),
      ],
    );
  }
}
```

### 3. Smart Question Bank (Not "AI Question Generator")
```dart
// UI Label: "بنك الأسئلة الذكي"
// Adaptive practice based on weak areas
class SmartQuestionBankWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(context.l10n.smartQuestionBankTitle), // "بنك الأسئلة الذكي"
        Text(context.l10n.smartQuestionBankSubtitle), // "أسئلة مخصصة لنقاط قوتك وضعفك"
        _AdaptivePracticeButton(),
      ],
    );
  }
}
```

### 4. No AI Icons/Imagery
```dart
// ❌ FORBIDDEN
Icon(Icons.psychology)           // Brain/AI icon
Icon(Icons.smart_toy)            // Robot
Image.asset('assets/ai_sparkle.png') // Sparkle/magic

// ✅ REQUIRED: Educational icons
Icon(Icons.school_outlined)      // School
Icon(Icons.menu_book_outlined)   // Book
Icon(Icons.trending_up_outlined) // Progress
Icon(Icons.lightbulb_outline)    // Idea/insight
Icon(Icons.auto_awesome_mosaic)  // Auto (subtle)
```

---

## 🔍 VERIFICATION CHECKLIST
```bash
# 1. No forbidden terms in UI strings
grep -r -i "ai\|artificial intelligence\|machine learning\|llm\|gpt\|bot\|algorithm\|neural\|magic" apps/*/l10n/ && echo "VIOLATION" || echo "OK"

# 2. Required Arabic terms present
grep -r "المساعد الدراسي\|التقارير التلقائية\|بنك الأسئلة الذكي\|مسار التعلم\|كشف نقاط الضعف" apps/*/l10n/app_ar.arb

# 3. No AI icons in UI
grep -r "Icons.psychology\|Icons.smart_toy\|ai_sparkle" apps/ --include="*.dart" && echo "VIOLATION" || echo "OK"

# 4. Educational icons used
grep -r "Icons.school\|Icons.menu_book\|Icons.trending_up\|Icons.lightbulb" apps/ --include="*.dart"
```

---

## 🛑 VIOLATION RESPONSE
- Any forbidden term in user-facing strings = **rejected**
- AI/robot/sparkle icons = **rejected**
- "Smart/Intelligent" as feature label = **rejected**
- Missing required Arabic terms = **rejected**
- Output includes: exact forbidden term found, required replacement

---

## 💡 INTEGRATION WITH SAVIOR CORE
- **OR & Context Pruning**: Filters intelligent features by user context, shows only relevant assistance
- **Pulse-Triggered Routing**: Complex personalization escalates to cloud for optimal recommendations
- **360° Awareness**: Monitors assistance usage, report open rates, practice completion in real-time
- **Homeostasis**: Auto-adjusts assistance frequency, report timing, question difficulty