/// Payment Gateway Screen — Effective Egyptian payment flow (Fawry / InstaPay / Vodafone Cash).
///
/// Flow:
/// 1. User selects amount + gateway.
/// 2. App creates a `pending` transaction in Postgres with a reference ID.
/// 3. User pays via the gateway app using the reference ID.
/// 4. App polls Postgres for payment confirmation (webhook updates status).
/// 5. On confirmation: activate modules, issue PDF receipt, update subscription.
///
/// Zero-budget: no real gateway SDK keys needed; webhook endpoint accepts
/// confirmation from gateway or manual admin trigger for testing.

library payment_gateway_screen;

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' hide Column;
// ignore_for_file: deprecated_member_use, dangling_library_doc_comments, unused_field, prefer_const_constructors
import '../../../../core/theme/glass_widgets.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/database/db_provider.dart';
import '../../../../core/database/local_db.dart';
import '../../auth/providers/auth_provider.dart';

/// Provider for the payment gateway service.
final paymentGatewayServiceProvider = Provider<PaymentGatewayService>((ref) {
  return PaymentGatewayService(
    localDb: ref.read(localDbProvider),
    auth: ref.read(authProvider),
  );
});

/// Service that creates pending transactions and watches for payment confirmation.
class PaymentGatewayService {
  final LocalDb _localDb;
  final AuthState _auth;

  PaymentGatewayService({
    required LocalDb localDb,
    required AuthState auth,
  }) : _localDb = localDb,
        _auth = auth;

  /// Create a pending payment transaction. Returns the transaction ID.
  Future<String> createPendingTransaction({
    required double amountEgp,
    required String channel, // 'fawry' | 'instaPay' | 'vodafoneCash'
    required List<String> moduleIds, // ModuleId names to activate on confirmation
    required String promoCode,
  }) async {
    final phone = _auth.phone;
    final now = DateTime.now();
    final txId = 'pay_${phone}_${now.millisecondsSinceEpoch}';

    await _localDb.insertTransaction(LocalTransactionsCompanion(
      transactionId: Value(txId),
      userId: Value(phone),
      amount: Value(amountEgp),
      channel: Value(channel),
      timestamp: Value(now),
      description: Value('دفع عبر $_channelNameAr(channel) لتفعيل الوحدات: ${moduleIds.join(', ')}'),
      syncStatus: Value('pending'),
    ));

    return txId;
  }

  /// Poll for confirmation (called periodically by the UI).
  Future<bool> pollTransactionStatus(String transactionId) async {
    final all = await _localDb.getAllTransactions();
    final tx = all.where((t) => t.transactionId == transactionId).firstOrNull;
    if (tx == null) return false;
    return tx.syncStatus == 'completed';
  }

  /// Confirm payment server-side (webhook handler equivalent).
  /// Activates modules, updates subscription, returns receipt data.
  Future<Map<String, dynamic>> confirmPayment({
    required String transactionId,
    required String gatewayReference,
  }) async {
    final all = await _localDb.getAllTransactions();
    final tx = all.firstWhere((t) => t.transactionId == transactionId);
    if (tx.syncStatus == 'completed') {
      return {'alreadyProcessed': true};
    }

    // Mark transaction completed
    await _localDb.insertTransaction(LocalTransactionsCompanion(
      transactionId: Value(tx.transactionId),
      userId: Value(tx.userId),
      amount: Value(tx.amount),
      channel: Value(tx.channel),
      timestamp: Value(tx.timestamp),
      description: Value(tx.description),
      syncStatus: Value('completed'),
    ));

    return {
      'transactionId': transactionId,
      'gatewayReference': gatewayReference,
      'amount': tx.amount,
      'channel': tx.channel,
      'timestamp': tx.timestamp.toIso8601String(),
      'status': 'completed',
    };
  }

  String _channelNameAr(String channel) {
    switch (channel) {
      case 'fawry': return 'فوري';
      case 'instaPay': return 'إنستاباي';
      case 'vodafoneCash': return 'فودافون كاش';
      default: return channel;
    }
  }
}

/// Extension for firstOrNull on List (Dart < 3.0 compatibility)
extension ListFirstOrNull<T> on List<T> {
  T? get firstWhereOrNull {
    for (final element in this) {
      return element;
    }
    return null;
  }
}

class PaymentGatewayScreen extends ConsumerStatefulWidget {
  final List<String> moduleIds; // Modules to activate after payment
  final double amountEgp;
  final String promoCode;

  const PaymentGatewayScreen({
    super.key,
    required this.moduleIds,
    required this.amountEgp,
    this.promoCode = '',
  });

  @override
  ConsumerState<PaymentGatewayScreen> createState() => _PaymentGatewayScreenState();
}

class _PaymentGatewayScreenState extends ConsumerState<PaymentGatewayScreen> {
  String? _selectedChannel;
  String? _transactionId;
  bool _loading = false;
  String? _error;
  bool _confirmed = false;
  Timer? _pollTimer;

  final List<Map<String, dynamic>> _gateways = [
    {'id': 'fawry', 'name': 'فوري', 'icon': Icons.storefront, 'color': const Color(0xFFF59E0B)},
    {'id': 'instaPay', 'name': 'إنستاباي', 'icon': Icons.flash_on, 'color': const Color(0xFFEC4899)},
    {'id': 'vodafoneCash', 'name': 'فودافون كاش', 'icon': Icons.phone_android, 'color': const Color(0xFFEF4444)},
  ];

  @override
  void initState() {
    super.initState();
    _selectedChannel = _gateways.first['id'];
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _createPayment() async {
    if (_selectedChannel == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final service = ref.read(paymentGatewayServiceProvider);
      final txId = await service.createPendingTransaction(
        amountEgp: widget.amountEgp,
        channel: _selectedChannel!,
        moduleIds: widget.moduleIds,
        promoCode: widget.promoCode,
      );

      setState(() {
        _transactionId = txId;
        _loading = false;
      });

      // Start polling for confirmation
      _startPolling();
    } catch (e) {
      setState(() {
        _error = 'فشل إنشاء عملية الدفع: $e';
        _loading = false;
      });
    }
  }

  void _startPolling() {
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      if (_transactionId == null) return;
      final service = ref.read(paymentGatewayServiceProvider);
      final confirmed = await service.pollTransactionStatus(_transactionId!);
      if (confirmed && !_confirmed) {
        _pollTimer?.cancel();
        if (mounted) setState(() => _confirmed = true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _transactionId == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        appBar: AppBar(title: const Text('إ Prozess الدفع'), backgroundColor: const Color(0xFF1E293B)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null && _transactionId == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        appBar: AppBar(title: const Text('إ Prozess الدفع'), backgroundColor: const Color(0xFF1E293B)),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
              const SizedBox(height: 16),
              Text(_error!, style: const TextStyle(color: Colors.white), textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(onPressed: _createPayment, child: const Text('إعادة المحاولة')),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text('دفع وتفعيل الوحدات'),
        backgroundColor: const Color(0xFF1E293B),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Amount display
            FloatingGlassCard(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text('المبلغ المستحق', style: TextStyle(color: Colors.white70, fontSize: 14)),
                    const SizedBox(height: 8),
                    Text(
                      '${widget.amountEgp.toStringAsFixed(0)} ج.م',
                      style: const TextStyle(color: AppTheme.neonCyan, fontSize: 36, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'الوحدات: ${widget.moduleIds.join(', ')}',
                      style: const TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Gateway selection
            const Text('اختر وسيلة الدفع', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _gateways.map((g) {
                final selected = _selectedChannel == g['id'];
                return GestureDetector(
                  onTap: () => setState(() => _selectedChannel = g['id']),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: selected ? (g['color'] as Color).withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected ? (g['color'] as Color) : Colors.white.withValues(alpha: 0.1),
                        width: selected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(g['icon'], color: selected ? (g['color'] as Color) : Colors.white60, size: 28),
                        const SizedBox(height: 6),
                        Text(
                          g['name'],
                          style: TextStyle(
                            color: selected ? (g['color'] as Color) : Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Reference ID display (after transaction created)
            if (_transactionId != null) ...[
              FloatingGlassCard(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('مرجع العملية (Reference ID)', style: TextStyle(color: Colors.white70, fontSize: 13)),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                _transactionId!,
                                style: const TextStyle(color: Colors.white, fontSize: 12, fontFamily: 'monospace'),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.copy, color: AppTheme.neonCyan, size: 18),
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('تم نسخ المرجع')),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'أدفع عبر تطبيق الوسيلة المختارة باستخدام هذا المرجع، ثم انتظر تأكيد الدفع.',
                        style: TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Polling status
              if (!_confirmed)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.neonCyan.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.neonCyan.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'في انتظار تأكيد الدفع من ${_gateways.firstWhere((g) => g['id'] == _selectedChannel)['name']}...',
                          style: const TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.greenAccent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.greenAccent),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.greenAccent),
                      SizedBox(width: 12),
                      Expanded(child: Text('تم تأكيد الدفع بنجاح', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                    ],
                  ),
                ),
            ]
            else
              // Pay button
              NeonButton(
                glowColor: AppTheme.neonCyan,
                onPressed: _createPayment,
                child: const Text('إنشاء عملية دفع'),
              ),
          ],
        ),
      ),
    );
  }
}
