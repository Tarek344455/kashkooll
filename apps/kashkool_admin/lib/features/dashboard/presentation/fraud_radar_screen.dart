import 'dart:math';
import 'dart:ui';
import 'package:material_ui/material_ui.dart';

/// رادار الاحتيال المالي — Fraud Detection Radar Screen
/// شاشة كونية عائمة تعرض الحركات المالية المشبوهة عبر كل السناتر

class FraudRadarScreen extends StatefulWidget {
  const FraudRadarScreen({super.key});

  @override
  State<FraudRadarScreen> createState() => _FraudRadarScreenState();
}

class _FraudRadarScreenState extends State<FraudRadarScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _radarCtrl;
  late Animation<double> _sweepAnim;

  String _filterLevel = 'الكل';
  final List<String> _riskLevels = ['الكل', '🔴 عالي', '🟡 متوسط', '🟢 طبيعي'];

  final List<Map<String, dynamic>> _alerts = [
    {
      'id': 'FRD-001',
      'type': 'استرداد مشبوه',
      'center': 'سنتر النجوم — القاهرة',
      'amount': 'EGP 4,500',
      'student': 'عمر محمود',
      'time': 'منذ 12 د',
      'risk': 'عالي',
      'detail': '3 استردادات متتالية خلال 48 ساعة لنفس الطالب',
    },
    {
      'id': 'FRD-002',
      'type': 'دفع خارج الوقت',
      'center': 'سنتر الفتح — الإسكندرية',
      'amount': 'EGP 1,200',
      'student': 'ليلى أحمد',
      'time': 'منذ 1 س',
      'risk': 'متوسط',
      'detail': 'معاملة ماليه الساعة 2:17 صباحاً',
    },
    {
      'id': 'FRD-003',
      'type': 'خصم مكرر',
      'center': 'سنتر المستقبل — الجيزة',
      'amount': 'EGP 850',
      'student': 'كريم سليم',
      'time': 'منذ 3 س',
      'risk': 'عالي',
      'detail': 'تم خصم نفس المبلغ مرتين في جلسة واحدة',
    },
    {
      'id': 'FRD-004',
      'type': 'خصم زائد',
      'center': 'سنتر الأمل — أسيوط',
      'amount': 'EGP 320',
      'student': 'نور حسن',
      'time': 'منذ 6 س',
      'risk': 'متوسط',
      'detail': 'مبلغ أكبر من سعر الحصة المسجل',
    },
    {
      'id': 'FRD-005',
      'type': 'دفع إنستاباي',
      'center': 'سنتر النور — المنصورة',
      'amount': 'EGP 2,100',
      'student': 'آية مصطفى',
      'time': 'منذ 1 ي',
      'risk': 'طبيعي',
      'detail': 'معاملة عادية — تأكيد مكتمل',
    },
  ];

  @override
  void initState() {
    super.initState();
    _radarCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
    _sweepAnim = Tween<double>(begin: 0, end: 2 * pi).animate(
      CurvedAnimation(parent: _radarCtrl, curve: Curves.linear),
    );
  }

  @override
  void dispose() {
    _radarCtrl.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filtered {
    if (_filterLevel == 'الكل') return _alerts;
    final riskMap = {'🔴 عالي': 'عالي', '🟡 متوسط': 'متوسط', '🟢 طبيعي': 'طبيعي'};
    final key = riskMap[_filterLevel] ?? '';
    return _alerts.where((a) => a['risk'] == key).toList();
  }

  @override
  Widget build(BuildContext context) {
    final highCount = _alerts.where((a) => a['risk'] == 'عالي').length;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF1A0505), Color(0xFF0D0D1A), Color(0xFF000005)],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // ── AppBar ───────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: _buildAppBar(highCount),
                ),
                const SizedBox(height: 14),
                // ── Radar Visualization ───────────────────────────────────
                _buildRadarWidget(),
                const SizedBox(height: 14),
                // ── Stats Row ─────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildStatsRow(),
                ),
                const SizedBox(height: 10),
                // ── Filter chips ──────────────────────────────────────────
                SizedBox(
                  height: 36,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _riskLevels.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, i) => _filterChip(_riskLevels[i]),
                  ),
                ),
                const SizedBox(height: 10),
                // ── Alerts List ───────────────────────────────────────────
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: _filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => _FraudAlertCard(alert: _filtered[i]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(int highCount) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFDC143C).withValues(alpha: 0.4)),
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: Colors.white70, size: 20),
              ),
              const SizedBox(width: 12),
              const Icon(Icons.radar_rounded, color: Color(0xFFDC143C), size: 24),
              const SizedBox(width: 10),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '📡 رادار الاحتيال المالي',
                    style: TextStyle(
                        color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text('تحريات مالية آنية عبر كل السناتر',
                      style: TextStyle(color: Colors.white54, fontSize: 11)),
                ],
              ),
              const Spacer(),
              if (highCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDC143C).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFDC143C).withValues(alpha: 0.6)),
                  ),
                  child: Text(
                    '⚠️ $highCount عالي',
                    style: const TextStyle(color: Color(0xFFDC143C), fontSize: 11),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRadarWidget() {
    return SizedBox(
      height: 160,
      child: AnimatedBuilder(
        animation: _sweepAnim,
        builder: (_, __) => CustomPaint(
          painter: _RadarPainter(sweepAngle: _sweepAnim.value),
          child: const SizedBox(width: double.infinity),
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    final highCount = _alerts.where((a) => a['risk'] == 'عالي').length;
    final midCount = _alerts.where((a) => a['risk'] == 'متوسط').length;
    final okCount = _alerts.where((a) => a['risk'] == 'طبيعي').length;

    return Row(
      children: [
        _statChip('$highCount تنبيه عالي', const Color(0xFFDC143C)),
        const SizedBox(width: 8),
        _statChip('$midCount متوسط', const Color(0xFFFFD700)),
        const SizedBox(width: 8),
        _statChip('$okCount طبيعي', const Color(0xFF00F5D4)),
      ],
    );
  }

  Widget _statChip(String label, Color color) {
    return Expanded(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withValues(alpha: 0.4)),
            ),
            child: Center(
              child: Text(
                label,
                style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _filterChip(String level) {
    final selected = _filterLevel == level;
    return GestureDetector(
      onTap: () => setState(() => _filterLevel = level),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFFDC143C).withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? const Color(0xFFDC143C)
                : Colors.white.withValues(alpha: 0.2),
          ),
        ),
        child: Text(
          level,
          style: TextStyle(
            color: selected ? const Color(0xFFDC143C) : Colors.white60,
            fontSize: 12,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

// ─── Radar Painter ────────────────────────────────────────────────────────────
class _RadarPainter extends CustomPainter {
  _RadarPainter({required this.sweepAngle});
  final double sweepAngle;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.height / 2;

    // دوائر الرادار
    for (int i = 1; i <= 4; i++) {
      final r = maxRadius * i / 4;
      canvas.drawCircle(
        center,
        r,
        Paint()
          ..color = const Color(0xFFDC143C).withValues(alpha: 0.15)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0,
      );
    }

    // خطوط محاور الرادار
    for (int i = 0; i < 8; i++) {
      final angle = i * pi / 4;
      canvas.drawLine(
        center,
        Offset(center.dx + maxRadius * cos(angle), center.dy + maxRadius * sin(angle)),
        Paint()
          ..color = const Color(0xFFDC143C).withValues(alpha: 0.1)
          ..strokeWidth = 0.8,
      );
    }

    // شعاع الرادار الدوار
    final radarPaint = Paint()
      ..shader = SweepGradient(
        startAngle: sweepAngle - 1.0,
        endAngle: sweepAngle,
        colors: [
          Colors.transparent,
          const Color(0xFFDC143C).withValues(alpha: 0.5),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: maxRadius))
      ..style = PaintingStyle.fill;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: maxRadius),
      sweepAngle - 1.0,
      1.0,
      true,
      radarPaint,
    );

    // نقاط الاحتيال
    final dotPaint = Paint()..color = const Color(0xFFDC143C);
    final dots = [
      Offset(center.dx + maxRadius * 0.4 * cos(sweepAngle * 1.3),
          center.dy + maxRadius * 0.4 * sin(sweepAngle * 1.3)),
      Offset(center.dx + maxRadius * 0.7 * cos(sweepAngle * 0.7),
          center.dy + maxRadius * 0.7 * sin(sweepAngle * 0.7)),
    ];
    for (final dot in dots) {
      canvas.drawCircle(dot, 4, dotPaint);
    }
  }

  @override
  bool shouldRepaint(_RadarPainter old) => old.sweepAngle != sweepAngle;
}

// ─── Fraud Alert Card ─────────────────────────────────────────────────────────
class _FraudAlertCard extends StatefulWidget {
  const _FraudAlertCard({required this.alert});
  final Map<String, dynamic> alert;

  @override
  State<_FraudAlertCard> createState() => _FraudAlertCardState();
}

class _FraudAlertCardState extends State<_FraudAlertCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final risk = widget.alert['risk'] as String;
    final neonColor = risk == 'عالي'
        ? const Color(0xFFDC143C)
        : risk == 'متوسط'
            ? const Color(0xFFFFD700)
            : const Color(0xFF00F5D4);

    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: neonColor.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: neonColor.withValues(alpha: 0.4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: neonColor.withValues(alpha: 0.15),
                        border: Border.all(color: neonColor.withValues(alpha: 0.4)),
                      ),
                      child: Icon(Icons.warning_rounded, color: neonColor, size: 18),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.alert['type'] as String,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '${widget.alert['center']} — ${widget.alert['student']}',
                            style: const TextStyle(color: Colors.white54, fontSize: 11),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          widget.alert['amount'] as String,
                          style: TextStyle(
                              color: neonColor, fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          widget.alert['time'] as String,
                          style: const TextStyle(color: Colors.white38, fontSize: 10),
                        ),
                      ],
                    ),
                  ],
                ),
                if (_expanded) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, color: Colors.white54, size: 14),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            widget.alert['detail'] as String,
                            style: const TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text(
                        'ID: ',
                        style: TextStyle(color: Colors.white38, fontSize: 10),
                      ),
                      Text(
                        widget.alert['id'] as String,
                        style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 10,
                            fontFamily: 'monospace'),
                      ),
                      const Spacer(),
                      _actionBtn('تجميد', const Color(0xFFDC143C)),
                      const SizedBox(width: 8),
                      _actionBtn('تجاهل', Colors.white38),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _actionBtn(String label, Color color) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Text(label, style: TextStyle(color: color, fontSize: 11)),
      ),
    );
  }
}
