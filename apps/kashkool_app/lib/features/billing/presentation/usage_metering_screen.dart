/// Usage Metering Screen — tracks metered usage (SMS, WhatsApp, AI remedial,
/// Storage, API calls) per account and shows current month consumption vs limits.
///
/// Reads usageCounters from the account subscription and displays per-meter
/// cost breakdown using UsageMetering prices from kashkool_core.

library usage_metering_screen;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kashkool_core/kashkool_core.dart';
// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables, deprecated_member_use, dangling_library_doc_comments, unused_field, unnecessary_to_list_in_spreads
import '../../../../core/theme/glass_widgets.dart';
import '../../../../core/theme/app_theme.dart';

/// Provider for usage metering data.
final usageMeteringProvider = Provider.family<UsageMeteringData, String>((ref, accountId) {
  return UsageMeteringData(accountId: accountId);
});

/// Holds usage counters and calculated costs for an account.
class UsageMeteringData {
  final String accountId;
  final Map<String, int> counters;
  final Map<String, double> costs;

  UsageMeteringData({
    required this.accountId,
    this.counters = const {},
    this.costs = const {},
  });

  double get totalCost => costs.values.fold(0.0, (sum, c) => sum + c);
}

/// Screen showing usage metering per account.
class UsageMeteringScreen extends ConsumerStatefulWidget {
  final String accountId;

  const UsageMeteringScreen({super.key, required this.accountId});

  @override
  ConsumerState<UsageMeteringScreen> createState() => _UsageMeteringScreenState();
}

class _UsageMeteringScreenState extends ConsumerState<UsageMeteringScreen> {
  bool _loading = true;
  String? _error;
  Map<String, int> _counters = {};
  Map<String, double> _costs = {};

  @override
  void initState() {
    super.initState();
    _loadUsage();
  }

  Future<void> _loadUsage() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // Usage counters come from the account subscription (server-synced).
      // For now, show available meter types with their prices.
      final costs = <String, double>{};
      final counters = <String, int>{};
      for (final entry in UsageMetering.prices.entries) {
        counters[entry.key] = 0;
        costs[entry.key] = 0.0;
      }

      setState(() {
        _counters = counters;
        _costs = costs;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'فشل تحميل بيانات الاستخدام: $e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        appBar: AppBar(title: const Text('قياس الاستهلاك'), backgroundColor: const Color(0xFF1E293B)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        appBar: AppBar(title: const Text('قياس الاستهلاك'), backgroundColor: const Color(0xFF1E293B)),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
              const SizedBox(height: 16),
              Text(_error!, style: const TextStyle(color: Colors.white), textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(onPressed: _loadUsage, child: const Text('إعادة المحاولة')),
            ],
          ),
        ),
      );
    }

    if (_counters.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        appBar: AppBar(title: const Text('قياس الاستهلاك'), backgroundColor: const Color(0xFF1E293B)),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.signal_cellular_off, color: Colors.white38, size: 48),
              SizedBox(height: 12),
              Text('لا توجد بيانات استهلاك لهذا الشهر', style: TextStyle(color: Colors.white70)),
              Text('سيتم تتبع الاستهلاك تلقائياً عند استخدام الخدمات', style: TextStyle(color: Colors.white54, fontSize: 12)),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text('قياس الاستهلاك'),
        backgroundColor: const Color(0xFF1E293B),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Total cost card
            FloatingGlassCard(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Text(
                      'إجمالي التكلفة الشهرية',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${_costs.values.fold(0.0, (sum, c) => sum + c).toStringAsFixed(0)} ج.م',
                      style: const TextStyle(color: AppTheme.neonCyan, fontSize: 32, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'الفاتورة الشهرية بناءً على الاستهلاك الفعلي',
                      style: TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Usage breakdown list
            const Text(
              'تفصيل الاستهلاك',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            ..._counters.entries.map((entry) {
              final meterKey = entry.key;
              final quantity = entry.value;
              final cost = _costs[meterKey] ?? 0.0;
              final price = UsageMetering.getPrice(meterKey);
              return _usageRow(
                meterKey: meterKey,
                quantity: quantity,
                cost: cost,
                unitNameAr: price?.unitNameAr ?? meterKey,
                bundlePrice: price?.bundlePriceEgp.toDouble() ?? 0.0,
              );
            }).toList(),

            const SizedBox(height: 24),

            // Reset info
            FloatingGlassCard(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'إعادة التعيين الشهرية',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'يتم إعادة تعيين عدادات الاستهلاك في اليوم الأول من كل شهر. الفواتير تُصدر تلقائياً عبر وظيفة الفوترة الشهرية.',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
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

  Widget _usageRow({
    required String meterKey,
    required int quantity,
    required double cost,
    required String unitNameAr,
    required double bundlePrice,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: FloatingGlassCard(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      unitNameAr,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      meterKey,
                      style: const TextStyle(color: Colors.white54, fontSize: 11),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$quantity وحدة',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${cost.toStringAsFixed(0)} ج.م',
                    style: TextStyle(color: AppTheme.neonCyan, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
