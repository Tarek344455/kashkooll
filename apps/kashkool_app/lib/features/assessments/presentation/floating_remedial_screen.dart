import 'package:material_ui/material_ui.dart';
import '../../../../core/theme/glass_widgets.dart';

class FloatingRemedialScreen extends StatefulWidget {
  final String quizTitle;
  final String weakConcept;
  final String accuracyPercent;

  const FloatingRemedialScreen({
    super.key,
    this.quizTitle = 'كويز التفاضل والتكامل — الدوال الأسية واللوغاريتمية',
    this.weakConcept = 'قاعدة السلسلة وتكامل مشتقة القوس المركب',
    this.accuracyPercent = '45%',
  });

  @override
  State<FloatingRemedialScreen> createState() => _FloatingRemedialScreenState();
}

class _FloatingRemedialScreenState extends State<FloatingRemedialScreen> {
  int _activeExercise = 0;
  int? _selectedAnswer;
  bool _answered = false;

  final List<Map<String, dynamic>> _remedialExercises = [
    {
      'question': 'أوجد ناتج تكامل الدالة:\n∫ (2x) · (x² + 5)³ dx',
      'hint': 'لاحظ أن مشتقة القوس (x² + 5) هي (2x) الموجودة بالخارج مباشرة؛ لذا نزيد الأس 1 ونقسم على الأس الجديد.',
      'options': [
        '½ (x² + 5)⁴ + C',
        '¼ (x² + 5)⁴ + C',
        '(x² + 5)⁴ + C',
        '4(x² + 5)² + C',
      ],
      'correct': 1,
    },
    {
      'question': 'إذا كانت د(س) = هـ^(3س) ، فإن مشتقتها د\'(س) تساوي:',
      'hint': 'مشتقة الدالة الأسية الطبيعية تساوي نفس الدالة مضروبة في مشتقة الأس.',
      'options': [
        'هـ^(3س) + C',
        '3س · هـ^(3س-1)',
        '3 · هـ^(3س)',
        '⅓ هـ^(3س)',
      ],
      'correct': 2,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final currentEx = _remedialExercises[_activeExercise];

    return CosmicScaffold(
      appBar: const GlassAppBar(
        title: 'كشكول الإنقاذ الأكاديمي التلقائي',
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Diagnostic Floating Card
            FloatingGlassCard(
              glowColor: const Color(0xFFA855F7), // Nebula Purple
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFA855F7).withValues(alpha: 0.2),
                      border: Border.all(color: const Color(0xFFA855F7)),
                    ),
                    child: const Icon(Icons.auto_awesome, color: Color(0xFFA855F7), size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'تم إنشاء تدريب علاجي مخصص تلقائياً',
                          style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'المفهوم المستهدف: ${widget.weakConcept}',
                          style: const TextStyle(color: Color(0xFF00F5D4), fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Exercise Question Box
            FloatingGlassCard(
              glowColor: const Color(0xFF00F5D4),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00F5D4).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'التمرين ${_activeExercise + 1} من ${_remedialExercises.length}',
                          style: const TextStyle(color: Color(0xFF00F5D4), fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const Text(
                        'تثبيت فكرة الامتحان',
                        style: TextStyle(color: Colors.white38, fontSize: 11),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    currentEx['question'] as String,
                    style: const TextStyle(color: Colors.white, fontSize: 16, height: 1.5, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Multiple Choice Floating Tiles
            ...List.generate((currentEx['options'] as List).length, (idx) {
              final isSelected = _selectedAnswer == idx;
              final isCorrect = currentEx['correct'] == idx;
              Color tileGlow = Colors.white12;
              if (_answered) {
                if (isCorrect) tileGlow = const Color(0xFF10B981);
                if (isSelected && !isCorrect) tileGlow = const Color(0xFFEF4444);
              } else if (isSelected) {
                tileGlow = const Color(0xFF00F5D4);
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: FloatingGlassCard(
                  borderRadius: 14,
                  glowColor: tileGlow,
                  onTap: _answered
                      ? null
                      : () {
                          setState(() {
                            _selectedAnswer = idx;
                          });
                        },
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected ? tileGlow.withValues(alpha: 0.25) : Colors.transparent,
                          border: Border.all(color: tileGlow, width: 1.5),
                        ),
                        child: Center(
                          child: Text(
                            String.fromCharCode(65 + idx),
                            style: TextStyle(color: isSelected ? Colors.white : Colors.white60, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          (currentEx['options'] as List)[idx] as String,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.white70,
                            fontSize: 14,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                      if (_answered && isCorrect)
                        const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 20),
                      if (_answered && isSelected && !isCorrect)
                        const Icon(Icons.cancel, color: Color(0xFFEF4444), size: 20),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 12),

            // Hint Explanation Box (appears when answered or upon request)
            if (_answered)
              FloatingGlassCard(
                glowColor: const Color(0xFF38BDF8),
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.lightbulb, color: Color(0xFF38BDF8), size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('سر فكرة الحل:', style: TextStyle(color: Color(0xFF38BDF8), fontWeight: FontWeight.bold, fontSize: 13)),
                          const SizedBox(height: 4),
                          Text(currentEx['hint'] as String, style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.4)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 20),

            // Action Button
            NeonButton(
              glowColor: const Color(0xFF00F5D4),
              onPressed: () {
                if (!_answered) {
                  if (_selectedAnswer != null) {
                    setState(() {
                      _answered = true;
                    });
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('يرجى اختيار إجابة أولاً')),
                    );
                  }
                } else {
                  if (_activeExercise < _remedialExercises.length - 1) {
                    setState(() {
                      _activeExercise++;
                      _selectedAnswer = null;
                      _answered = false;
                    });
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('🎉 أحسنت! تم إتقان المفهوم وإضافته لنقاط القوة في ملفك الأكاديمي'),
                        backgroundColor: Color(0xFF10B981),
                      ),
                    );
                    Navigator.pop(context);
                  }
                }
              },
              child: Text(
                !_answered ? 'تأكيد الإجابة وفحص الفهم' : (_activeExercise < _remedialExercises.length - 1 ? 'التمرين التالي' : 'إنهاء تدريب الإنقاذ بنجاح'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
