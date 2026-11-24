import 'package:material_ui/material_ui.dart';
import '../../../../core/theme/glass_widgets.dart';

class QuizRunnerScreen extends StatefulWidget {
  const QuizRunnerScreen({super.key});

  @override
  State<QuizRunnerScreen> createState() => _QuizRunnerScreenState();
}

class _QuizRunnerScreenState extends State<QuizRunnerScreen> {
  String? selectedOption;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Exam: Auto-Graded Quiz')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Question Card
            FloatingGlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'السؤال الأول: حل المعادلة',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  // LaTeX Placeholder
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      '\$2x + 5 = 15\$',
                      style: TextStyle(color: Colors.white24, fontSize: 20),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // MCQ Options
                  ...List.generate(
                    4,
                    (index) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: FloatingGlassCard(
                        child: ListTile(
                          title: Text(
                            'Option ${index + 1}: 4x = 10',
                            style: const TextStyle(color: Colors.white),
                          ),
                          leading: RadioGroup<String>(
                            groupValue: selectedOption,
                            onChanged: (String? value) {
                              setState(() => selectedOption = value);
                            },
                            child: Radio<String>(value: 'option_$index'),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  // Submit Button
                  NeonButton(
                    onPressed: () {
                      // Auto-Grade Logic Mock
                      final bool isCorrect =
                          selectedOption == 'option_0'; // Correct answer
                      if (isCorrect) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('✅ الإجابة صحيحة!')),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content:
                                  Text('❌ الإجابة غير صحيحة، حاول مرة أخرى')),
                        );
                      }
                    },
                    child: const Text('تقديم الإجابة'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
