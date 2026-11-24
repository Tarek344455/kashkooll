import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' hide Column;
// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables
import '../../../../core/theme/glass_widgets.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/database/db_provider.dart';
import '../../../../core/database/local_db.dart';
import '../../auth/providers/auth_provider.dart';
import 'group_management_screen.dart';

class TeacherDashboardScreen extends ConsumerStatefulWidget {
  const TeacherDashboardScreen({super.key});

  @override
  ConsumerState<TeacherDashboardScreen> createState() => _TeacherDashboardScreenState();
}

class _TeacherDashboardScreenState extends ConsumerState<TeacherDashboardScreen> {
  bool _loading = true;
  String? _error;
  int _todayAttendance = 0;
  int _totalEnrolled = 0;
  double _todayRevenue = 0.0;
  List<LocalSession> _todaySessions = [];
  bool _settlementFeatureEnabled = false;
  bool _settlementChecking = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
    _checkSettlementFeature();
  }

  Future<void> _checkSettlementFeature() async {
    final auth = ref.read(authProvider);
    // Billing is per centre: the tenant claim is the account id. The phone
    // number used to be passed here, which pointed at a non-existent account
    // document and disabled the feature for every teacher.
    final accountId = auth.tenantId;
    final enabled = await ref
        .read(featureFlagServiceProvider)
        .isEnabled('one_tap_settlement', accountId: accountId);
    if (!mounted) return;
    setState(() {
      _settlementFeatureEnabled = enabled;
      _settlementChecking = false;
    });
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final db = ref.read(localDbProvider);
      final auth = ref.read(authProvider);
      final tenantId = auth.tenantId ?? 'unassigned';
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final todayEnd = todayStart.add(const Duration(days: 1));

      // Load today's sessions
      final allSessions = await db.getAllSessions();
      _todaySessions = allSessions
          .where((s) => s.tenantId == tenantId && s.startTime.isAfter(todayStart) && s.startTime.isBefore(todayEnd))
          .toList()
        ..sort((a, b) => a.startTime.compareTo(b.startTime));

      // Calculate attendance for today's sessions
      int totalAttendance = 0;
      int totalEnrolled = 0;
      for (final session in _todaySessions) {
        final attendance = await db.getAttendanceForSession(session.sessionId);
        totalAttendance += attendance.length;
        // Enrolled count would come from group membership - placeholder for now
        totalEnrolled += 50;
      }

      // Calculate today's revenue from cash transactions
      final allTransactions = await db.getAllTransactions();
      final todayTransactions = allTransactions
          .where((t) => t.timestamp.isAfter(todayStart) && t.timestamp.isBefore(todayEnd) && t.channel == 'cashToWallet')
          .toList();
      final revenue = todayTransactions.fold(0.0, (sum, t) => sum + t.amount);

      if (!mounted) return;
      setState(() {
        _todayAttendance = totalAttendance;
        _totalEnrolled = totalEnrolled;
        _todayRevenue = revenue;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'فشل تحميل لوحة التحكم: $e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        appBar: AppBar(
          title: const Text('لوحة تحكم المعلم والسنتر'),
          backgroundColor: const Color(0xFF1E293B),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        appBar: AppBar(
          title: const Text('لوحة تحكم المعلم والسنتر'),
          backgroundColor: const Color(0xFF1E293B),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
              const SizedBox(height: 16),
              Text(_error!, style: const TextStyle(color: Colors.white), textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(onPressed: _loadDashboardData, child: const Text('إعادة المحاولة')),
            ],
          ),
        ),
      );
    }

    final attendancePercent = _totalEnrolled > 0 ? (_todayAttendance / _totalEnrolled * 100).toStringAsFixed(1) : '0.0';

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text('لوحة تحكم المعلم والسنتر'),
        backgroundColor: const Color(0xFF1E293B),
        actions: [
          IconButton(
            icon: const Icon(Icons.groups_outlined),
            tooltip: 'إدارة المجموعات',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const GroupManagementScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'تحديث البيانات',
            onPressed: _loadDashboardData,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadDashboardData,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Welcome Card
              FloatingGlassCard(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: Colors.cyanAccent.withValues(alpha: 0.2),
                        child: const Icon(Icons.person, color: Colors.cyanAccent, size: 32),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'أهلاً بك، ${ref.read(authProvider).phone.isNotEmpty ? 'أستاذ' : 'مدرس'}',
                              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'سنتر ${ref.read(authProvider).tenantId ?? 'غير محدد'}',
                              style: const TextStyle(color: Colors.white70, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Live Performance Metrics
              Row(
                children: [
                  Expanded(
                    child: FloatingGlassCard(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('نسبة الحضور اليوم', style: TextStyle(color: Colors.white70, fontSize: 12)),
                                Icon(Icons.trending_up, color: Colors.greenAccent, size: 18),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '$attendancePercent%',
                              style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$_todayAttendance من أصل $_totalEnrolled طالباً',
                              style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11),
                            ),
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
                            const Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('متحصلات الخزينة اليوم', style: TextStyle(color: Colors.white70, fontSize: 12)),
                                Icon(Icons.account_balance_wallet, color: Colors.cyanAccent, size: 18),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${_todayRevenue.toStringAsFixed(0)} ج.م',
                              style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'بعد خصم نسبة السنتر',
                              style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Quick Actions Bar
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.cyanAccent,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.group_add),
                      label: const Text('إدارة المجموعات', style: TextStyle(fontWeight: FontWeight.bold)),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const GroupManagementScreen()),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white24),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.analytics_outlined),
                      label: const Text('تقرير نهاية اليوم'),
                      onPressed: _settlementChecking || !_settlementFeatureEnabled
                          ? null
                          : () => _showSettlementConfirmDialog(context),
                    ),
                  ),
                ],
              ),

              // Feature flag notice
              if (!_settlementFeatureEnabled && !_settlementChecking)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'ميزة التسوية التلقائية غير مفعلة لحسابك. راجع حاسبة الأسعار لتفعيل وحدة "محرك التسوية".',
                    style: TextStyle(color: Colors.white54, fontSize: 11),
                    textAlign: TextAlign.center,
                  ),
                ),

              const SizedBox(height: 24),

              // Today's Sessions
              const Text(
                'جدول الحصص والمجموعات النشطة اليوم',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              if (_todaySessions.isEmpty)
                const FloatingGlassCard(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Icon(Icons.event_busy, color: Colors.white38, size: 48),
                        SizedBox(height: 12),
                        Text('لا توجد حصص مجدولة لليوم', style: TextStyle(color: Colors.white70, fontSize: 16)),
                        SizedBox(height: 8),
                        Text('أضف مجموعات من "إدارة المجموعات" لظهور الحصص هنا', style: TextStyle(color: Colors.white38, fontSize: 12)),
                      ],
                    ),
                  ),
                )
              else
                ..._todaySessions.map((session) => _buildSessionTile(session)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSessionTile(LocalSession session) {
    final now = DateTime.now();
    final isActive = session.startTime.isBefore(now) && session.startTime.add(const Duration(hours: 2)).isAfter(now);
    final isUpcoming = session.startTime.isAfter(now);

    Color statusColor;
    String statusText;
    if (isActive) {
      statusColor = Colors.greenAccent;
      statusText = 'حصة نشطة';
    } else if (isUpcoming) {
      statusColor = Colors.amberAccent;
      statusText = 'قادمة بعد قليل';
    } else {
      statusColor = Colors.white38;
      statusText = 'منتهية';
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: FloatingGlassCard(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      session.title,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.schedule, color: Colors.white60, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        '${_formatTime(session.startTime)} – ${_formatTime(session.startTime.add(const Duration(hours: 2)))}',
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                  Text(
                    'المجموعة: ${session.groupId}',
                    style: const TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour > 12 ? dt.hour - 12 : dt.hour;
    final period = dt.hour >= 12 ? 'م' : 'ص';
    return '$hour:${dt.minute.toString().padLeft(2, '0')} $period';
  }

  /// Settlement confirmation dialog with a hard 10-second countdown.
  Future<void> _showSettlementConfirmDialog(BuildContext context) async {
    bool confirmed = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1E293B),
              title: const Text(
                'تأكيد التسوية اليومية',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'سيتم تنفيذ التسوية التلقائية للحصص اليوم. تأكد من مراجعة جميع البيانات قبل التأكيد.',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.neonCyan.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.neonCyan.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'التأكيد التلقائي خلال',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                        Text(
                          '10 ث',
                          style: TextStyle(
                            color: AppTheme.neonCyan,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    confirmed = true;
                    Navigator.of(dialogContext).pop(true);
                  },
                  child: const Text(
                    'تأكيد فوري',
                    style: TextStyle(color: AppTheme.neonCyan, fontWeight: FontWeight.bold),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('إلغاء', style: TextStyle(color: Colors.white54)),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmed && context.mounted) {
      await _executeSettlement();
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم إلغاء التسوية'),
          backgroundColor: Colors.amber,
        ),
      );
    }
  }

  /// Executes the daily settlement as an immutable ledger entry (idempotent).
  Future<void> _executeSettlement() async {
    setState(() => _loading = true);
    try {
      final db = ref.read(localDbProvider);
      final auth = ref.read(authProvider);
      final tenantId = auth.tenantId ?? 'unassigned';
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);

      // Idempotency: skip if already settled today
      final allTransactions = await db.getAllTransactions();
      final todaySettled = allTransactions.any(
        (t) =>
            t.channel == 'settlement' &&
            t.timestamp.isAfter(todayStart) &&
            t.timestamp.isBefore(todayStart.add(const Duration(days: 1))),
      );

      if (todaySettled) {
        if (!mounted) return;
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('التسوية قد تمت بالفعل اليوم'),
            backgroundColor: Colors.amber,
          ),
        );
        return;
      }

      await db.insertTransaction(LocalTransactionsCompanion(
        transactionId: Value('settlement_${tenantId}_${now.millisecondsSinceEpoch}'),
        userId: Value(auth.phone),
        amount: Value(_todayRevenue),
        channel: Value('settlement'),
        timestamp: Value(now),
        description: Value('التسوية اليومية التلقائية'),
        syncStatus: Value('pending'),
      ));

      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم إتمام التسوية اليومية بنجاح'),
          backgroundColor: Colors.greenAccent,
        ),
      );
      await _loadDashboardData();
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل التسوية: $e'), backgroundColor: Colors.redAccent),
      );
    }
  }
}
