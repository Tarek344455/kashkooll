import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/supabase_bootstrap.dart';
import '../../../../core/theme/glass_widgets.dart';
import '../providers/settlement_provider.dart';

/// End-of-day settlement. All figures are computed from real Supabase rows
/// (wallet ledger + attendance) for the signed-in tenant — no hardcoded data.
/// The "Adopt" button records the settlement as a wallet ledger entry so the
/// immutable ledger keeps the day's net payout.
class FloatingSettlementScreen extends ConsumerStatefulWidget {
  const FloatingSettlementScreen({super.key});

  @override
  ConsumerState<FloatingSettlementScreen> createState() => _FloatingSettlementScreenState();
}

class _FloatingSettlementScreenState extends ConsumerState<FloatingSettlementScreen> {
  bool _adopted = false;

  Future<void> _adoptSettlement() async {
    final settlement = await ref.read(settlementProvider.future);
    final tenant = await ref.watch(settlementTenantIdProvider.future);
    if (tenant == null) return;

    final client = SupabaseBootstrap.client;
    final user = client.auth.currentUser;
    if (user == null) return;

    final netPayoutPiasters = (settlement['teacherNetPayoutPiasters'] as num?)?.toInt() ?? 0;
    if (netPayoutPiasters <= 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا يوجد صافي ربح لتسويته اليوم')),
      );
      return;
    }

    try {
      await client.rpc('record_wallet_transaction', params: {
        'p_id': 'settle-${DateTime.now().millisecondsSinceEpoch}',
        'p_tenant_id': tenant,
        'p_student_id': '',
        'p_amount_piasters': -netPayoutPiasters,
        'p_kind': 'settlement',
        'p_channel': 'cash',
        'p_reference_id': 'daily-settle-${DateTime.now().toUtc().toIso8601String()}',
        'p_idempotency_key':
            'settle:$tenant:${DateTime.utc(DateTime.now().year, DateTime.now().month, DateTime.now().day)}',
        'p_note': 'التسوية اليومية — صافي ربح المدرس المحول',
      });

      if (!mounted) return;
      setState(() => _adopted = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم اعتماد التسوية اليومية وتوثيقها في دفتر الحسابات المشفر'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر اعتماد التسوية، حاول مرة أخرى')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final settlement = ref.watch(settlementProvider);

    return settlement.when(
      data: (s) {
        final grossPiasters = (s['grossRevenuePiasters'] as num?)?.toInt() ?? 0;
        final totalAttendance = (s['totalAttendance'] as int?) ?? 0;
        final centerSplitRatePct = (s['centerSplitRatePct'] as int?) ?? 20;
        final assistantWagesPiasters = (s['assistantWagesPiasters'] as num?)?.toInt() ?? 0;
        final bookReservationPiasters = (s['bookReservationPiasters'] as num?)?.toInt() ?? 0;
        final centerCutPiasters = (s['centerCutPiasters'] as num?)?.toInt() ?? 0;
        final teacherNetPayoutPiasters = (s['teacherNetPayoutPiasters'] as num?)?.toInt() ?? 0;
        final centers = (s['centers'] as List?) ?? const [];

        return Scaffold(
          backgroundColor: const Color(0xFF0F172A),
          appBar: AppBar(
            title: const Text('تسوية نهاية اليوم (1-Tap)'),
            backgroundColor: const Color(0xFF1E293B),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Floating Net Payout Orb
                FloatingGlassCard(
                  glowColor: const Color(0xFF00F5D4),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const Text(
                        'صافي أرباح المعلم المستحقة لليوم',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '${(teacherNetPayoutPiasters / 100).toInt()} ج.م',
                        style: const TextStyle(
                          color: Color(0xFF00F5D4),
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'إجمالي حضور اليوم: $totalAttendance طالب',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
                      ),
                      const SizedBox(height: 18),

                      // Status Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: _adopted
                              ? const Color(0xFF10B981).withValues(alpha: 0.18)
                              : const Color(0xFFF59E0B).withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _adopted ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _adopted ? Icons.verified : Icons.pending,
                              color: _adopted ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _adopted
                                  ? 'تمت التسوية وتوزيع الأرباح رسمياً'
                                  : 'بانتظار الاعتماد (الساعة 11:00 م)',
                              style: TextStyle(
                                color: _adopted ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Detailed Financial Formula Breakdown
                const Text(
                  'تفاصيل معادلة التسوية المركبة (The Formula)',
                  style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),

                FloatingGlassCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildFormulaRow(
                        'إجمالي إيراد الحصص الكلي (Gross):',
                        '+${(grossPiasters / 100).toInt()} ج.م',
                        Colors.white,
                      ),
                      const Divider(color: Colors.white12, height: 18),
                      _buildFormulaRow(
                        'نسبة السنتر والقاعات ($centerSplitRatePct%):',
                        '-${(centerCutPiasters / 100).toInt()} ج.م',
                        const Color(0xFFEF4444),
                      ),
                      const Divider(color: Colors.white12, height: 18),
                      _buildFormulaRow(
                        'يوميات المساعدين والسكرتارية:',
                        '-${(assistantWagesPiasters / 100).toInt()} ج.م',
                        const Color(0xFFEF4444),
                      ),
                      const Divider(color: Colors.white12, height: 18),
                      _buildFormulaRow(
                        'مستحقات طباعة وحجز الملازم:',
                        '-${(bookReservationPiasters / 100).toInt()} ج.م',
                        const Color(0xFFF59E0B),
                      ),
                      const Divider(color: Colors.white24, height: 22),
                      _buildFormulaRow(
                        'الصافي المحول للمدرس (Net):',
                        '${(teacherNetPayoutPiasters / 100).toInt()} ج.م',
                        const Color(0xFF00F5D4),
                        isBold: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Per-Center Breakdown
                const Text(
                  'توزيع الإيراد بحسب المجموعات',
                  style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),

                if (centers.isEmpty)
                  const Center(
                    child: Text(
                      'لا توجد مجموعات لديها بيانات هذا اليوم',
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                  )
                else
                  ...centers.map((c) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: FloatingGlassCard(
                        borderRadius: 14,
                        glowColor: const Color(0xFF38BDF8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  c['centerName'] as String? ?? 'مجموعة',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${c['students']} طالب',
                                  style: const TextStyle(color: Colors.white60, fontSize: 11),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${(c['netEgp'] as num?)?.toInt()} ج.م صافي',
                                  style: const TextStyle(
                                    color: Color(0xFF00F5D4),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'من أصل ${(c['grossEgp'] as num?)?.toInt()} ج.م',
                                  style: const TextStyle(color: Colors.white38, fontSize: 10),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                const SizedBox(height: 24),

                // 1-Tap Trigger Button
                NeonButton(
                  glowColor: _adopted ? const Color(0xFF10B981) : const Color(0xFF00F5D4),
                  onPressed: _adopted ? () {} : () { _adoptSettlement(); },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _adopted ? Icons.check_circle : Icons.electric_bolt,
                        color: const Color(0xFF0F172A),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _adopted
                            ? 'تم توثيق التسوية وإرسال الحسابات'
                            : 'اعتماد وتصفية التسوية اليومية بضغطة واحدة',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const Scaffold(
        backgroundColor: Color(0xFF0F172A),
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        appBar: AppBar(
          title: const Text('تسوية نهاية اليوم'),
          backgroundColor: const Color(0xFF1E293B),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.white38, size: 64),
              const SizedBox(height: 16),
              const Text('تعذر تحميل بيانات التسوية', style: TextStyle(color: Colors.white70, fontSize: 18)),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => ref.refresh(settlementProvider),
                icon: const Icon(Icons.refresh),
                label: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormulaRow(String label, String value, Color valueColor, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white70,
            fontSize: isBold ? 14 : 12,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: isBold ? 16 : 13,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}
