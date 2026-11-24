import 'package:material_ui/material_ui.dart';
import '../../../../core/theme/glass_widgets.dart';
import 'drm_lecture_player.dart';

class CourseTreeScreen extends StatelessWidget {
  const CourseTreeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text('شجرة المناهج والمحاضرات'),
        backgroundColor: const Color(0xFF1E293B),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Grade 3 Secondary
          FloatingGlassCard(
            child: ExpansionTile(
              initiallyExpanded: true,
              leading: const Icon(Icons.school, color: Colors.cyanAccent),
              title: const Text('الصف الثالث الثانوي — الرياضيات والفيزياء', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              subtitle: const Text('المحاضرات والمراجعات الشاملة', style: TextStyle(color: Colors.white60, fontSize: 12)),
              children: [
                // Unit 1
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: ExpansionTile(
                    initiallyExpanded: true,
                    leading: const Icon(Icons.folder_open, color: Colors.amberAccent),
                    title: const Text('الوحدة الأولى: التفاضل والتكامل المتقدم', style: TextStyle(color: Colors.white, fontSize: 14)),
                    children: [
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                        leading: const Icon(Icons.play_circle_filled, color: Colors.cyanAccent),
                        title: const Text('الدرس الأول: التكامل بالتجزيء والكسور الجزئية', style: TextStyle(color: Colors.white, fontSize: 13)),
                        subtitle: const Text('المدة: 1:45:00 • مشفر DRM', style: TextStyle(color: Colors.white60, fontSize: 11)),
                        trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white38, size: 14),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const DrmLecturePlayer(
                                lectureTitle: 'الدرس الأول: التكامل بالتجزيء والكسور الجزئية',
                              ),
                            ),
                          );
                        },
                      ),
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                        leading: const Icon(Icons.play_circle_filled, color: Colors.cyanAccent),
                        title: const Text('الدرس الثاني: حجوم الأجسام الدورانية', style: TextStyle(color: Colors.white, fontSize: 13)),
                        subtitle: const Text('المدة: 1:30:00 • مشفر DRM', style: TextStyle(color: Colors.white60, fontSize: 11)),
                        trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white38, size: 14),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const DrmLecturePlayer(
                                lectureTitle: 'الدرس الثاني: حجوم الأجسام الدورانية',
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                // Unit 2
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: ExpansionTile(
                    leading: const Icon(Icons.folder, color: Colors.white60),
                    title: const Text('الوحدة الثانية: الهندسة الفراغية والمعادلات المتجهة', style: TextStyle(color: Colors.white, fontSize: 14)),
                    children: [
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                        leading: const Icon(Icons.play_circle_filled, color: Colors.cyanAccent),
                        title: const Text('الدرس الأول: معادلة الخط المستقيم والمستوى في الفراغ', style: TextStyle(color: Colors.white, fontSize: 13)),
                        subtitle: const Text('المدة: 1:15:00 • مشفر DRM', style: TextStyle(color: Colors.white60, fontSize: 11)),
                        trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white38, size: 14),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const DrmLecturePlayer(
                                lectureTitle: 'معادلة الخط المستقيم والمستوى في الفراغ',
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Grade 2 Secondary
          FloatingGlassCard(
            child: ExpansionTile(
              leading: const Icon(Icons.school_outlined, color: Colors.purpleAccent),
              title: const Text('الصف الثاني الثانوي — تطبيقات الرياضيات', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              subtitle: const Text('منهج الاستاتيكا والهندسة والتحليل', style: TextStyle(color: Colors.white60, fontSize: 12)),
              children: [
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  leading: const Icon(Icons.play_circle_filled, color: Colors.cyanAccent),
                  title: const Text('الدرس الأول: محصلة قوتين متلاقيتين في نقطة', style: TextStyle(color: Colors.white, fontSize: 13)),
                  subtitle: const Text('المدة: 50:00 • مشفر DRM', style: TextStyle(color: Colors.white60, fontSize: 11)),
                  trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white38, size: 14),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const DrmLecturePlayer(
                          lectureTitle: 'محصلة قوتين متلاقيتين في نقطة',
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
