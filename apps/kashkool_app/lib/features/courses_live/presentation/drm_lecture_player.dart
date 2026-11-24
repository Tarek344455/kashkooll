import 'dart:async';
import 'package:material_ui/material_ui.dart';

import '../../study_assistant/presentation/study_assistant_screen.dart';

/// مشغل المحاضرات المشفر والمحمي بتقنيات DRM والعلامات المائية العشوائية المتحركة
class DrmLecturePlayer extends StatefulWidget {
  final String lectureTitle;
  final String studentName;
  final String studentPhone;

  const DrmLecturePlayer({
    super.key,
    this.lectureTitle = 'المحاضرة 1: التكامل بالتجزيء والكسور الجزئية',
    this.studentName = 'أحمد محمد علي',
    this.studentPhone = '01012345678',
  });

  @override
  State<DrmLecturePlayer> createState() => _DrmLecturePlayerState();
}

class _DrmLecturePlayerState extends State<DrmLecturePlayer> {
  // Drifting Watermark position coordinates
  Offset _watermarkPosition = const Offset(40, 80);
  Timer? _watermarkTimer;
  bool _isPlaying = true;
  double _currentProgress = 0.35; // 35% of video watched

  @override
  void initState() {
    super.initState();
    _startWatermarkDrifting();
  }

  void _startWatermarkDrifting() {
    // يحرك العلامة المائية عشوائياً كل 4 ثوانٍ لمنع تسجيل الشاشة أو إخفائها بأي قناع
    _watermarkTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!mounted) return;
      final size = MediaQuery.of(context).size;
      final maxX = (size.width - 220).clamp(10.0, double.infinity);
      final maxY = (size.height - 180).clamp(50.0, double.infinity);

      final nextX = (10 + (DateTime.now().millisecondsSinceEpoch % (maxX.toInt() + 1))).toDouble();
      final nextY = (60 + ((DateTime.now().millisecondsSinceEpoch ~/ 7) % (maxY.toInt() + 1))).toDouble();

      setState(() {
        _watermarkPosition = Offset(nextX, nextY);
      });
    });
  }

  @override
  void dispose() {
    _watermarkTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Mock Encrypted Video Container / Surface
            Column(
              children: [
                // Top Custom Video Bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  color: Colors.black87,
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.lectureTitle,
                          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        tooltip: 'المساعد الدراسي',
                        icon: const Icon(Icons.auto_stories, color: Colors.cyanAccent),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => StudyAssistantScreen(
                                lesson: widget.lectureTitle,
                              ),
                            ),
                          );
                        },
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.greenAccent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.lock, color: Colors.greenAccent, size: 12),
                            SizedBox(width: 4),
                            Text('بث مشفر DRM', style: TextStyle(color: Colors.greenAccent, fontSize: 11)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Video Display Area
                Expanded(
                  child: Center(
                    child: Container(
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        gradient: RadialGradient(
                          center: Alignment.center,
                          radius: 0.8,
                          colors: [
                            Color(0xFF1E293B),
                            Colors.black,
                          ],
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _isPlaying ? Icons.play_circle_fill : Icons.pause_circle_filled,
                            size: 72,
                            color: Colors.cyanAccent.withValues(alpha: 0.8),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'المحتوى محمي بنظام كشكول لمكافحة القرصنة',
                            style: TextStyle(color: Colors.white70, fontSize: 13),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'ممنوع تصوير أو تسجيل الشاشة — سيتم تتبع الحساب فوراً',
                            style: TextStyle(color: Colors.white30, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Video Controls Bottom Bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  color: const Color(0xFF0F172A),
                  child: Column(
                    children: [
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 4,
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                          activeTrackColor: Colors.cyanAccent,
                          inactiveTrackColor: Colors.white24,
                          thumbColor: Colors.cyanAccent,
                        ),
                        child: Slider(
                          value: _currentProgress,
                          onChanged: (val) {
                            setState(() {
                              _currentProgress = val;
                            });
                          },
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              IconButton(
                                icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow, color: Colors.white),
                                onPressed: () {
                                  setState(() {
                                    _isPlaying = !_isPlaying;
                                  });
                                },
                              ),
                              const SizedBox(width: 8),
                              const Text('38:15 / 1:45:00', style: TextStyle(color: Colors.white70, fontSize: 12)),
                            ],
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.speed, color: Colors.white70, size: 20),
                                tooltip: 'السرعة 1.25x',
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('السرعة: 1.25x')),
                                  );
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.fullscreen, color: Colors.white, size: 22),
                                tooltip: 'وضع ملء الشاشة',
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('وضع ملء الشاشة سيُفعّل في الإصدار القادم من التطبيق'),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Animated Drifting Dynamic Watermark (Anti-Piracy Overlay)
            AnimatedPositioned(
              duration: const Duration(seconds: 3),
              curve: Curves.easeInOut,
              top: _watermarkPosition.dy,
              left: _watermarkPosition.dx,
              child: IgnorePointer(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'كشكول • ${widget.studentName}',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.22),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'الهاتف: ${widget.studentPhone}',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.18),
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
