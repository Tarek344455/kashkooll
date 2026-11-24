import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/supabase_bootstrap.dart';
import '../../../../core/theme/glass_widgets.dart';

/// Tenant id of the signed-in profile.
final _queueTenantIdProvider = FutureProvider<String?>((ref) async {
  final client = SupabaseBootstrap.client;
  final user = client.auth.currentUser;
  if (user == null) return null;
  final data = await client
      .from('profiles')
      .select('tenant_id')
      .eq('id', user.id)
      .single();
  return data['tenant_id'] as String?;
});

/// Recent attendance scans for the tenant's sessions (newest first).
final queueFeedProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final tenant = await ref.watch(_queueTenantIdProvider.future);
  if (tenant == null) return const [];
  final client = SupabaseBootstrap.client;
  final data = await client
      .from('attendance')
      .select('*, students(name)')
      .eq('tenant_id', tenant)
      .order('scanned_at', ascending: false)
      .limit(50);
  return List<Map<String, dynamic>>.from(data);
});

/// Today's scan count and cash collected (from wallet topups) for the tenant.
final queueStatsProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final tenant = await ref.read(_queueTenantIdProvider.future);
  if (tenant == null) return {'scans': 0, 'cash': 0};
  final client = SupabaseBootstrap.client;
  final today = DateTime.now().toUtc();
  final start = DateTime.utc(today.year, today.month, today.day).toIso8601String();
  final end = DateTime.utc(today.year, today.month, today.day + 1).toIso8601String();

  final attendance = await client
      .from('attendance')
      .select('id')
      .eq('tenant_id', tenant)
      .gte('scanned_at', start)
      .lt('scanned_at', end);

  final wallet = await client
      .from('wallet_transactions')
      .select('amount_piasters')
      .eq('tenant_id', tenant)
      .eq('kind', 'topup')
      .eq('status', 'completed')
      .gte('created_at', start)
      .lt('created_at', end);

  final scans = (attendance as List).length;
  final cashPiasters = (wallet as List)
      .map((r) => (r['amount_piasters'] as num?)?.toInt() ?? 0)
      .fold<int>(0, (a, b) => a + b);

  return {'scans': scans, 'cash': cashPiasters / 100.0};
});

/// Auto Queue Desk — real attendance feed from Supabase, RLS-protected.
class AutoQueueDeskScreen extends ConsumerStatefulWidget {
  const AutoQueueDeskScreen({super.key});

  @override
  ConsumerState<AutoQueueDeskScreen> createState() => _AutoQueueDeskScreenState();
}

class _AutoQueueDeskScreenState extends ConsumerState<AutoQueueDeskScreen> {
  String _activeFeedbackStatus = 'READY'; // READY, VALID, PARTIAL, BLOCKED
  Timer? _resetTimer;

  @override
  void dispose() {
    _resetTimer?.cancel();
    super.dispose();
  }

  Color _glowColor(String status) {
    switch (status) {
      case 'VALID':
        return const Color(0xFF10B981);
      case 'PARTIAL':
        return const Color(0xFFF59E0B);
      case 'BLOCKED':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF00F5D4);
    }
  }

  String _statusArabic(Map<String, dynamic> item) {
    final status = item['status'] as String?;
    switch (status) {
      case 'present':
        return 'حضر';
      case 'late':
        return 'تأخر';
      case 'absent':
        return 'غائب';
      case 'excused':
        return 'معذور';
      default:
        return 'حالة غير معروفة';
    }
  }

  IconData _statusIcon(Map<String, dynamic> item) {
    final status = item['status'] as String?;
    switch (status) {
      case 'present':
        return Icons.check_circle;
      case 'late':
        return Icons.access_time;
      case 'absent':
        return Icons.cancel;
      case 'excused':
        return Icons.block;
      default:
        return Icons.help_outline;
    }
  }

  Future<void> _recordManualScan() async {
    final tenant = await ref.read(_queueTenantIdProvider.future);
    if (tenant == null) return;

    final client = SupabaseBootstrap.client;
    final user = client.auth.currentUser;
    if (user == null) return;

    // Simple manual scan: pick the first active session and mark attendance.
    // In production this is triggered by a QR/NFC scan.
    final sessions = await client
        .from('sessions')
        .select('id')
        .eq('tenant_id', tenant)
        .eq('is_active', true)
        .limit(1);

    if ((sessions as List).isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('لا توجد حصص نشطة لهذا السنتر')),
        );
      }
      return;
    }

    final sessionId = (sessions.first as Map)['id'] as String;

    // Use the first enrolled student for this session (demo flow).
    final students = await client
        .from('students')
        .select('id')
        .eq('tenant_id', tenant)
        .limit(1);

    if ((students as List).isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('لا يوجد طلاب مسجلين لهذا السنتر')),
        );
      }
      return;
    }

    final studentId = (students.first as Map)['id'] as String;
    final idempotencyKey = 'scan-$tenant-$studentId-$sessionId-${DateTime.now().millisecondsSinceEpoch}';

    try {
      await client.rpc('record_attendance', params: {
        'p_id': 'att-${DateTime.now().millisecondsSinceEpoch}',
        'p_tenant_id': tenant,
        'p_student_id': studentId,
        'p_session_id': sessionId,
        'p_idempotency_key': idempotencyKey,
        'p_scanned_at': DateTime.now().toUtc().toIso8601String(),
      });

      setState(() {
        _activeFeedbackStatus = 'VALID';
      });
      _resetTimer?.cancel();
      _resetTimer = Timer(const Duration(seconds: 2), () {
        if (mounted) setState(() => _activeFeedbackStatus = 'READY');
      });

      ref.invalidate(queueFeedProvider);
      ref.invalidate(queueStatsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تسجيل الحضور بنجاح')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر تسجيل الحضور، حاول مرة أخرى')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final feed = ref.watch(queueFeedProvider);
    final stats = ref.watch(queueStatsProvider);
    final glowColor = _glowColor(_activeFeedbackStatus);

    return CosmicScaffold(
      // ignore: prefer_const_constructors
      appBar: GlassAppBar(
        title: 'بوابة الدخول الذكية السريعة (0.3 ثانية)',
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: feed.when(
                    data: (rows) => FloatingGlassCard(
                      glowColor: const Color(0xFF00F5D4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('حضور الدفعة الحالية', style: TextStyle(color: Colors.white70, fontSize: 12)),
                          const SizedBox(height: 6),
                          Text(
                            '${rows.length} مسح',
                            style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 2),
                          const Text('بيانات مباشرة من السحابة', style: TextStyle(color: Color(0xFF00F5D4), fontSize: 11)),
                        ],
                      ),
                    ),
                    loading: () => const FloatingGlassCard(
                      glowColor: Color(0xFF00F5D4),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (_, __) => const FloatingGlassCard(
                      glowColor: Color(0xFFEF4444),
                      child: Center(child: Text('تعذر تحميل البيانات', style: TextStyle(color: Colors.white70))),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: stats.when(
                    data: (s) => FloatingGlassCard(
                      glowColor: const Color(0xFFF59E0B),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('الكاش المحصل بالخزينة', style: TextStyle(color: Colors.white70, fontSize: 12)),
                          const SizedBox(height: 6),
                          Text(
                            '${(s['cash'] as num?)?.toStringAsFixed(0) ?? '0'} ج.م',
                            style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 2),
                          const Text('مسجل في السجل المشفر', style: TextStyle(color: Color(0xFFF59E0B), fontSize: 11)),
                        ],
                      ),
                    ),
                    loading: () => const FloatingGlassCard(
                      glowColor: Color(0xFFF59E0B),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (_, __) => const FloatingGlassCard(
                      glowColor: Color(0xFFF59E0B),
                      child: Center(child: Text('–', style: TextStyle(color: Colors.white70))),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            FloatingGlassCard(
              glowColor: glowColor,
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: glowColor.withValues(alpha: 0.18),
                      border: Border.all(color: glowColor, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: glowColor.withValues(alpha: 0.4),
                          blurRadius: 25,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Icon(Icons.qr_code_scanner, color: glowColor, size: 38),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'المسح التلقائي الفوري (NFC / Dynamic QR)',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'تسجيل حضور الطالب عبر الكود الديناميكي — يتم القيد في السجل فوراً',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                  const SizedBox(height: 16),
                  NeonButton(
                    glowColor: glowColor,
                    onPressed: _recordManualScan,
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.bolt, color: Color(0xFF0F172A), size: 20),
                        SizedBox(width: 8),
                        Text('تسجيل حضور (0.3s)'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            const Text(
              'سجل الحضور اللحظي',
              style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            Expanded(
              child: feed.when(
                data: (rows) {
                  if (rows.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.groups_outlined, size: 64, color: Colors.white38),
                          SizedBox(height: 16),
                          Text('لا توجد سجلات حضور حتى الآن', style: TextStyle(color: Colors.white70, fontSize: 18)),
                        ],
                      ),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.only(bottom: 10),
                    itemCount: rows.length,
                    itemBuilder: (context, index) {
                      final item = rows[index];
                      final students = item['students'] as Map? ?? {};
                      final name = students['name'] ?? 'طالب';
                      final time = item['scanned_at'] as String?;
                      final timeDisplay = time != null
                          ? DateTime.tryParse(time)?.toLocal().toString().substring(11, 16) ?? ''
                          : '';
                      final statusArabic = _statusArabic(item);
                      final itemColor = _glowColor(item['status'] as String? ?? '');
                      final statusIcon = _statusIcon(item);

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: FloatingGlassCard(
                          borderRadius: 14,
                          glowColor: itemColor,
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: itemColor.withValues(alpha: 0.15),
                                ),
                                child: Icon(statusIcon, color: itemColor, size: 22),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          name,
                                          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                                        ),
                                        Text(
                                          timeDisplay,
                                          style: const TextStyle(color: Colors.white38, fontSize: 11),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      statusArabic,
                                      style: TextStyle(color: itemColor, fontSize: 11, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => const Center(
                  child: Text('تعذر تحميل السجلات', style: TextStyle(color: Colors.white70)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
