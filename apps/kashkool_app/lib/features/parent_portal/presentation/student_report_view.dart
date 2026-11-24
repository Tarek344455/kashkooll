import 'package:material_ui/material_ui.dart';
import '../../../../core/theme/glass_widgets.dart';

class StudentReportView extends StatelessWidget {
  final String studentName;
  final String studentGrade;

  const StudentReportView({
    super.key,
    this.studentName = 'أحمد محمد علي',
    this.studentGrade = 'الصف الثالث الثانوي — علمي رياضة',
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text('تقرير أداء الطالب التلقائي'),
        backgroundColor: const Color(0xFF1E293B),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Student Identity Summary
            FloatingGlassCard(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: Colors.cyanAccent.withValues(alpha: 0.2),
                      child: const Icon(Icons.person, color: Colors.cyanAccent, size: 30),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(studentName, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(studentGrade, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.greenAccent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('منتظم ومتميز', style: TextStyle(color: Colors.greenAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Performance Numbers
            Row(
              children: [
                Expanded(
                  child: FloatingGlassCard(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('متوسط درجات الاختبارات', style: TextStyle(color: Colors.white60, fontSize: 11)),
                          const SizedBox(height: 6),
                          const Text('92%', style: TextStyle(color: Colors.cyanAccent, fontSize: 24, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 2),
                          Text('أعلى من 85% من الدفعة', style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 10)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FloatingGlassCard(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('نسبة الحضور الفعلي', style: TextStyle(color: Colors.white60, fontSize: 11)),
                          const SizedBox(height: 6),
                          const Text('96%', style: TextStyle(color: Colors.greenAccent, fontSize: 24, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 2),
                          Text('غياب حصة واحدة بعذر', style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 10)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Recent Exam Logs
            const Text('سجل درجات الكويزات الأخيرة', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),

            _buildQuizScoreTile('كويز التفاضل والتكامل (التكامل المتقدم)', '19 / 20', 'ممتاز • الأول على المجموعة', Colors.greenAccent),
            const SizedBox(height: 8),
            _buildQuizScoreTile('كويز تطبيقات الرياضيات والفيزياء', '18 / 20', 'جيد جداً مرتفع', Colors.cyanAccent),
            const SizedBox(height: 8),
            _buildQuizScoreTile('كويز الهندسة الفراغية السريع', '17 / 20', 'جيد جداً', Colors.amberAccent),

            const SizedBox(height: 20),

            // Behavioral & Remedial Feedback
            const FloatingGlassCard(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.lightbulb_outline, color: Colors.cyanAccent, size: 18),
                        SizedBox(width: 8),
                        Text('توجيهات التقوية الذكية للطالب', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    SizedBox(height: 10),
                    Text(
                      '• مستوى استيعاب ممتاز في مفاهيم التفاضل والتكامل.\n'
                      '• يُنصح بمراجعة أسئلة مستويات التفكير العليا في وحدة الهندسة الفراغية (تم تخصيص تدريب تكميلي تلقائي له في التطبيق).',
                      style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.5),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuizScoreTile(String title, String score, String evaluation, Color evalColor) {
    return FloatingGlassCard(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(evaluation, style: TextStyle(color: evalColor, fontSize: 11)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(score, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
            ),
          ],
        ),
      ),
    );
  }
}
