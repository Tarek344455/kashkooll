import 'package:material_ui/material_ui.dart';
import '../../../../core/theme/glass_widgets.dart';

class QuestionEditorScreen extends StatefulWidget {
  const QuestionEditorScreen({super.key});

  @override
  State<QuestionEditorScreen> createState() => _QuestionEditorScreenState();
}

class _QuestionEditorScreenState extends State<QuestionEditorScreen> {
  final _questionController = TextEditingController();
  final List<TextEditingController> _options = [
    TextEditingController(text: '3x^2 + 5x + C'),
    TextEditingController(text: 'x^3 + (5/2)x^2 + C'),
    TextEditingController(text: '6x + C'),
    TextEditingController(text: 'x^3 + 5x + C'),
  ];
  int _correctIndex = 1;
  String _difficulty = 'متوسط';
  final _explanationController = TextEditingController(text: 'باستخدام قاعدة تكامل كثيرات الحدود: تكامل 3x^2 هو x^3، وتكامل 5x هو (5/2)x^2 بالإضافة لثابت التكامل C.');

  @override
  void initState() {
    super.initState();
    _questionController.text = 'أوجد ناتج التكامل التالي:\n∫ (3x² + 5x) dx';
  }

  @override
  void dispose() {
    _questionController.dispose();
    _explanationController.dispose();
    for (var opt in _options) {
      opt.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text('محرر بنك الأسئلة والاختبارات'),
        backgroundColor: const Color(0xFF1E293B),
        actions: [
          IconButton(
            icon: const Icon(Icons.check, color: Colors.cyanAccent),
            tooltip: 'حفظ السؤال في بنك الأسئلة',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('تم حفظ السؤال وتصنيفه في بنك الأسئلة الذكي')),
              );
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Subject & Difficulty Selector
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _difficulty,
                        dropdownColor: const Color(0xFF1E293B),
                        style: const TextStyle(color: Colors.white),
                        items: ['سهل', 'متوسط', 'متقدم (مستويات عليا)']
                            .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _difficulty = val);
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.cyanAccent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('رياضيات 3ث', style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Question Text Input
            FloatingGlassCard(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('نص السؤال (يدعم الرموز والمعادلات الرياضية)', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _questionController,
                      maxLines: 4,
                      style: const TextStyle(color: Colors.white, fontSize: 15),
                      decoration: const InputDecoration(
                        hintText: 'اكتب نص السؤال هنا...',
                        hintStyle: TextStyle(color: Colors.white30),
                        border: InputBorder.none,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Multiple Choices
            const Text('الخيارات (اختر الإجابة الصحيحة)', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),

            RadioGroup<int>(
              groupValue: _correctIndex,
              onChanged: (val) => setState(() => _correctIndex = val ?? 0),
              child: Column(
                children: List.generate(4, (index) {
                  final isCorrect = _correctIndex == index;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: FloatingGlassCard(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        child: Row(
                          children: [
                            Radio<int>(
                              value: index,
                              activeColor: Colors.greenAccent,
                            ),
                            Expanded(
                              child: TextField(
                                controller: _options[index],
                                style: TextStyle(
                                  color: isCorrect ? Colors.greenAccent : Colors.white,
                                  fontWeight: isCorrect ? FontWeight.bold : FontWeight.normal,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'الخيار رقم ${index + 1}',
                                  hintStyle: const TextStyle(color: Colors.white24),
                                  border: InputBorder.none,
                                ),
                              ),
                            ),
                            if (isCorrect)
                              const Icon(Icons.check_circle, color: Colors.greenAccent, size: 20),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 12),

            // Explanation / Remedial Notes
            FloatingGlassCard(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('تفسير الإجابة وشرح خطوات الحل (للتقوية التلقائية)', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _explanationController,
                      maxLines: 3,
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                      decoration: const InputDecoration(
                        hintText: 'اكتب تفسير الحل ليظهر للطالب في حال الخطأ...',
                        hintStyle: TextStyle(color: Colors.white30),
                        border: InputBorder.none,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Save Button
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.cyanAccent,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم حفظ السؤال وتصنيفه في بنك الأسئلة الذكي')),
                );
                Navigator.pop(context);
              },
              child: const Text('حفظ ونشر في بنك الأسئلة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
