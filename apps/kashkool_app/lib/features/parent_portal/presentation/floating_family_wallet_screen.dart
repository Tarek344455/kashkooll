import 'dart:ui';
import 'package:material_ui/material_ui.dart';
import '../../../../core/theme/glass_widgets.dart';

class FloatingFamilyWalletScreen extends StatefulWidget {
  const FloatingFamilyWalletScreen({super.key});

  @override
  State<FloatingFamilyWalletScreen> createState() => _FloatingFamilyWalletScreenState();
}

class _FloatingFamilyWalletScreenState extends State<FloatingFamilyWalletScreen> {
  double _availableBalance = 640.0; // EGP
  int _coveredSessionsCount = 8;

  final List<Map<String, dynamic>> _ledgerHistory = [
    {
      'title': 'شحن رصيد عبر إنستاباي (InstaPay)',
      'subtitle': 'مرجع التحويل: IP-99214482',
      'date': 'اليوم • 02:15 م',
      'amount': 500.0,
      'isCredit': true,
      'status': 'مكتمل ومؤكد',
    },
    {
      'title': 'سداد حصة تفاضل وتكامل (سنتر النخبة)',
      'subtitle': 'مسح كود المقعد A-14 تلقائياً',
      'date': 'السبت 18 نوفمبر • 04:02 م',
      'amount': 80.0,
      'isCredit': false,
      'status': 'خصم تلقائي',
    },
    {
      'title': 'حجز واستلام ملزمة ليلة الامتحان',
      'subtitle': 'كود الملزمة: BOK-302',
      'date': 'الخميس 16 نوفمبر • 05:30 م',
      'amount': 60.0,
      'isCredit': false,
      'status': 'تسوية فورية',
    },
    {
      'title': 'شحن رصيد عبر فودافون كاش',
      'subtitle': 'رقم المحفظة: 010****492',
      'date': '10 نوفمبر • 11:20 ص',
      'amount': 400.0,
      'isCredit': true,
      'status': 'مكتمل ومؤكد',
    },
  ];

  void _showTopUpSheet() {
    final amountController = TextEditingController(text: '300');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            top: 24,
            left: 20,
            right: 20,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A).withValues(alpha: 0.9),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: const Color(0xFF00F5D4).withValues(alpha: 0.2)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'شحن محفظة الحصص العائلية الفوري',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              const Text(
                'اختر وسيلة الدفع المفضلة لديك في مصر',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white60, fontSize: 12),
              ),
              const SizedBox(height: 18),

              // Payment Methods Badges
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildPaymentMethodPill('إنستاباي', Icons.flash_on, const Color(0xFFEC4899)),
                  _buildPaymentMethodPill('فودافون كاش', Icons.phone_android, const Color(0xFFEF4444)),
                  _buildPaymentMethodPill('فوري كشك', Icons.storefront, const Color(0xFFF59E0B)),
                ],
              ),
              const SizedBox(height: 16),

              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  labelText: 'المبلغ المراد شحنه (ج.م)',
                  labelStyle: const TextStyle(color: Colors.white60),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF00F5D4)),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              NeonButton(
                glowColor: const Color(0xFF00F5D4),
                onPressed: () {
                  final added = double.tryParse(amountController.text.trim()) ?? 0.0;
                  if (added > 0) {
                    setState(() {
                      _availableBalance += added;
                      _coveredSessionsCount = (_availableBalance / 80).toInt();
                      _ledgerHistory.insert(0, {
                        'title': 'شحن رصيد فوري (إنستاباي)',
                        'subtitle': 'مرجع العملية: IP-${DateTime.now().millisecondsSinceEpoch % 100000}',
                        'date': 'الآن • ${TimeOfDay.now().hour}:${TimeOfDay.now().minute} م',
                        'amount': added,
                        'isCredit': true,
                        'status': 'مكتمل ومؤكد',
                      });
                    });
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('🎉 تم شحن المحفظة بنجاح بمبلغ $added ج.م ورصيدك الحالي كافٍ للحصص'),
                        backgroundColor: const Color(0xFF10B981),
                      ),
                    );
                  }
                },
                child: const Text('إتمام الشحن الفوري الآمن'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentMethodPill(String name, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(name, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CosmicScaffold(
      appBar: const GlassAppBar(
        title: 'محفظة الحصص العائلية الذكية',
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Floating Glowing Balance Card
            FloatingGlassCard(
              glowColor: const Color(0xFF00F5D4),
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'الرصيد المتاح لحصص الأبناء',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.lock, color: Color(0xFF10B981), size: 12),
                            SizedBox(width: 4),
                            Text('دفتر حسابات مشفر', style: TextStyle(color: Color(0xFF10B981), fontSize: 11)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    '${_availableBalance.toInt()} ج.م',
                    style: const TextStyle(
                      color: Color(0xFF00F5D4),
                      fontSize: 38,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'يغطي تقريباً $_coveredSessionsCount حصص قادمة شاملة الملازم',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12),
                  ),
                  const SizedBox(height: 20),

                  // Top Up Neon Action Button
                  NeonButton(
                    glowColor: const Color(0xFF00F5D4),
                    onPressed: _showTopUpSheet,
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_card, color: Color(0xFF0F172A), size: 18),
                        SizedBox(width: 8),
                        Text('شحن رصيد الحصص (إنستاباي / كاش / فوري)'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Anti-Fraud Guarantee Info Box
            FloatingGlassCard(
              glowColor: const Color(0xFF38BDF8),
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  const Icon(Icons.verified_user, color: Color(0xFF38BDF8), size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'ضمان وصول الأموال بدون وسيط كاش',
                          style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'يتم الخصم الآلي عند مقعد الحصة فقط بعد مسح كود الطالب بالسنتر.',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Live Ledger Transactions
            const Text(
              'سجل الحركات النقدية غير القابل للتعديل',
              style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            ...List.generate(_ledgerHistory.length, (i) {
              final tx = _ledgerHistory[i];
              final isCredit = tx['isCredit'] as bool;
              final Color txColor = isCredit ? const Color(0xFF10B981) : const Color(0xFFF59E0B);

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: FloatingGlassCard(
                  borderRadius: 14,
                  glowColor: txColor,
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: txColor.withValues(alpha: 0.15),
                        ),
                        child: Icon(
                          isCredit ? Icons.arrow_downward : Icons.arrow_upward,
                          color: txColor,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tx['title'] as String,
                              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${tx['subtitle']} • ${tx['date']}',
                              style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${isCredit ? "+" : "-"}${(tx['amount'] as double).toInt()} ج.م',
                            style: TextStyle(
                              color: txColor,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            tx['status'] as String,
                            style: TextStyle(color: txColor.withValues(alpha: 0.7), fontSize: 10),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
