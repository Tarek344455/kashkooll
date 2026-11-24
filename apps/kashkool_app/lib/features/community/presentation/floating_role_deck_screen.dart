import 'package:material_ui/material_ui.dart';
import '../../../../core/theme/glass_widgets.dart';

class FloatingRoleDeckScreen extends StatefulWidget {
  const FloatingRoleDeckScreen({super.key});

  @override
  State<FloatingRoleDeckScreen> createState() => _FloatingRoleDeckScreenState();
}

class _FloatingRoleDeckScreenState extends State<FloatingRoleDeckScreen> {
  final PageController _pageController = PageController(viewportFraction: 0.88);
  int _currentSlide = 0;

  final List<Map<String, dynamic>> _decks = [
    {
      'role': 'المعلم / المحاضر',
      'roleEn': 'Teacher Sovereign OS',
      'icon': Icons.psychology,
      'accentColor': const Color(0xFF00F5D4), // Cyan Neon
      'badge': 'درع الملكية الفكرية والسيطرة',
      'headline': 'أنت لست مجرد مدرس، أنت مؤسسة تعليمية مستقلة',
      'points': [
        {'title': 'White-Label مطلق', 'desc': 'التطبيق يحمل اسمك وشعارك وهويتك البصرية أمام طلابك بالكامل.'},
        {'title': 'حاسبة التسوية الآلية (1-Tap)', 'desc': 'تصفية أرباحك من كل السناتر بنهاية اليوم بضغطة زر وحسم النسب تلقائياً.'},
        {'title': 'درع DRM لمكافحة التسريب', 'desc': 'علامات مائية متحركة برقم واسم الطالب تجعل سرقة المحاضرات مستحيلة.'},
        {'title': 'مصنع الأسئلة والتقوية الذكي', 'desc': 'توليد كويزات وتحليل نقاط ضعف الدفعة تلقائياً دون أي مجهود إداري.'},
      ],
    },
    {
      'role': 'السنتر وإدارة القاعات',
      'roleEn': 'Center Hub & Cashier',
      'icon': Icons.corporate_fare,
      'accentColor': const Color(0xFF38BDF8), // Sky Blue
      'badge': 'تأمين الخزينة وتنظيم الحشود',
      'headline': 'السنتر يعمل ذاتياً وأنت في منزلك دون اختلاس أو عجز',
      'points': [
        {'title': 'بوابة الـ 0.3 ثانية', 'desc': 'مسح كود الطالب وطباعة إيصال المقعد الحراري لحظياً بدون إنترنت.'},
        {'title': 'الدفتر المحاسبي غير القابل للتلاعب', 'desc': 'تسجيل كل مليم كاش؛ أي إلغاء لإيصال يتطلب تصريحاً ويسجل بصمة الجهاز.'},
        {'title': 'لوحة إشغال القاعات الحية', 'desc': 'مراقبة سعة القاعات وتدفق الطلاب بالدقيقة بين الحصص.'},
        {'title': 'حجز الملازم المسبق', 'desc': 'إنهاء خسائر طباعة المذكرات عبر تأكيد الحجز المسبق من المحفظة.'},
      ],
    },
    {
      'role': 'السكرتارية ومكتب الدخول',
      'roleEn': 'Rapid Desk Operations',
      'icon': Icons.bolt,
      'accentColor': const Color(0xFFF59E0B), // Amber Neon
      'badge': 'إنهاء زحام السلالم والدرع الواقي',
      'headline': 'استيعاب 300 طالب في 10 دقائق دون خطأ واحد',
      'points': [
        {'title': 'المسح الفوري التلقائي', 'desc': 'توجيه الكاميرا للكارت فقط: أخضر (مسدد)، أصفر (متبقي)، أحمر (محظور).'},
        {'title': 'دعم ثقافة "متبقي عليه"', 'desc': 'تسجيل المبالغ الجزئية بنقرة واحدة وذكر الباقي في إيصال محترم للطالب.'},
        {'title': 'إلغاء الورقيات والدفاتر', 'desc': 'السيستم هو الكاشير والمحاسب؛ لا يوجد عجز بالدرج بنهاية الوردية.'},
        {'title': 'استقرار كامل في وضع الأوفلاين', 'desc': 'يعمل في أضعف البدرومات والشبكات بدون توقف المبيعات.'},
      ],
    },
    {
      'role': 'الطالب وبناء العادة',
      'roleEn': 'Student Dopamine Flow',
      'icon': Icons.rocket_launch,
      'accentColor': const Color(0xFFA855F7), // Purple Nebula
      'badge': 'تحويل المذاكرة لرياضة تنافسية',
      'headline': 'تعلم بأقصى تركيز دون ملل أو تشتت وبأقل مجهود',
      'points': [
        {'title': 'تحدي الـ 5 دقائق الخاطف', 'desc': 'مهام مصغرة غير قابلة للتأجيل تفرز دوبامين فوري وتبني عادة التعلم.'},
        {'title': 'دوري المحافظات والشارات', 'desc': 'منافسات شرفية بين المجموعات وشارات استمرارية (Study Streaks).'},
        {'title': 'فيديوهات موفرة لباقة الموبايل', 'desc': 'ضغط فائق يعمل بسلاسة دون استنزاف باقة الإنترنت.'},
        {'title': 'كشكول الإنقاذ الفوري', 'desc': 'عند الخطأ في أي مسألة، يفتح لك تدريباً مخصصاً لفهم النقطة دون إحراج.'},
      ],
    },
    {
      'role': 'ولي الأمر المطمئن',
      'roleEn': 'High-Trust Parent Shield',
      'icon': Icons.family_restroom,
      'accentColor': const Color(0xFF10B981), // Emerald
      'badge': 'راحة البال والاستثمار الحقيقي',
      'headline': 'اطمئن على مستقبله ومقعده وأنت في عملك',
      'points': [
        {'title': 'إشعار الوصول اللحظي', 'desc': 'رسالة فورية فور جلوس ابنك على مقعد الحصة بالسنتر بالدقيقة.'},
        {'title': 'موجز الجمعة الهادئ', 'desc': 'تقرير أسبوعي مختصر ومريح بالأرقام الحقيقية دون إزعاج وإشعارات فارغة.'},
        {'title': 'محفظة الحصص الإلكترونية', 'desc': 'شحن الحصص والملازم مسبقاً عبر فوري وإنستاباي لضمان وصول المال.'},
        {'title': 'إنذار الغياب المبكر', 'desc': 'تنبيه ذكي بعد 15 دقيقة مع جدول الحصص البديلة فوراً.'},
      ],
    },
    {
      'role': 'غرفة السيطرة السيادية',
      'roleEn': 'God-Mode Sovereign HQ',
      'icon': Icons.shield,
      'accentColor': const Color(0xFFEC4899), // Neon Pink
      'badge': 'تطبيق الأدمن الخاص بك وحدك',
      'headline': 'إمبراطورية المنظومة كاملة تحت أصابعك',
      'points': [
        {'title': 'رادار المحافظات الحي', 'desc': 'خريطة تفاعلية تراقب تدفق آلاف الطلاب والسناتر دقيقة بدقيقة.'},
        {'title': 'صمامات الأمان (Kill-Switches)', 'desc': 'إيقاف أو تفعيل أي ميزة أو تجميد سنتر بالكامل في أقل من ثانيتين.'},
        {'title': 'الدخول الشبحي (Ghost Mode)', 'desc': 'تقمص واجهة أي طرف لحل مشاكله فورياً دون الحاجة لكلمة سر.'},
        {'title': 'رادار كشف التلاعب المالي', 'desc': 'رصد فوري لعمليات إلغاء الإيصالات وحركات الدرج المشبوهة.'},
      ],
    },
  ];

  @override
  Widget build(BuildContext context) {
    final activeDeck = _decks[_currentSlide];
    final Color activeColor = activeDeck['accentColor'] as Color;

    return CosmicScaffold(
      appBar: GlassAppBar(
        title: 'منظومة كشكول الفضائية • شرح الأطراف',
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: activeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: activeColor.withValues(alpha: 0.4)),
                ),
                child: Text(
                  '${_currentSlide + 1} / ${_decks.length}',
                  style: TextStyle(color: activeColor, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 12),

          // Role Navigation Bar Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: List.generate(_decks.length, (idx) {
                final isSelected = _currentSlide == idx;
                final deckColor = _decks[idx]['accentColor'] as Color;
                return Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () {
                      _pageController.animateToPage(
                        idx,
                        duration: const Duration(milliseconds: 350),
                        curve: Curves.easeOutCubic,
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected ? deckColor.withValues(alpha: 0.25) : Colors.white.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? deckColor : Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _decks[idx]['icon'] as IconData,
                            size: 14,
                            color: isSelected ? deckColor : Colors.white60,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _decks[idx]['role'] as String,
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.white60,
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),

          const SizedBox(height: 16),

          // Floating Slides Viewport
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: _decks.length,
              onPageChanged: (idx) {
                setState(() {
                  _currentSlide = idx;
                });
              },
              itemBuilder: (context, index) {
                final deck = _decks[index];
                final Color themeColor = deck['accentColor'] as Color;
                final points = deck['points'] as List<Map<String, String>>;

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                  child: FloatingGlassCard(
                    glowColor: themeColor,
                    padding: const EdgeInsets.all(22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Card Header
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: themeColor.withValues(alpha: 0.18),
                                border: Border.all(color: themeColor, width: 1.5),
                                boxShadow: [
                                  BoxShadow(
                                    color: themeColor.withValues(alpha: 0.35),
                                    blurRadius: 20,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                              child: Icon(deck['icon'] as IconData, color: themeColor, size: 28),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: themeColor.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      deck['badge'] as String,
                                      style: TextStyle(color: themeColor, fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    deck['role'] as String,
                                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    deck['roleEn'] as String,
                                    style: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 14),

                        // Headline Pitch
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                          ),
                          child: Text(
                            deck['headline'] as String,
                            style: TextStyle(
                              color: themeColor,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              height: 1.4,
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // 4 Key Pillars / Inventions
                        Expanded(
                          child: ListView.separated(
                            itemCount: points.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (context, pIdx) {
                              final pt = points[pIdx];
                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    margin: const EdgeInsets.only(top: 4),
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: themeColor,
                                      boxShadow: [
                                        BoxShadow(color: themeColor, blurRadius: 6),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          pt['title']!,
                                          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          pt['desc']!,
                                          style: TextStyle(color: Colors.white.withValues(alpha: 0.65), fontSize: 11, height: 1.35),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Bottom Slide Indicators
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_decks.length, (i) {
                final isCurrent = _currentSlide == i;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: isCurrent ? 24 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: isCurrent ? activeColor : Colors.white24,
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
