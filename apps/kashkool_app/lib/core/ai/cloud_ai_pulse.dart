/// Cloud AI Pulse — pulse-triggered cloud AI via Kashkool Savior server (:4000)
/// with safe local fallback when offline or when the cloud is unavailable.
///
/// NOTE: This file is DEPRECATED. Use IntelligenceFabric instead for unified intelligence.
/// Kept only for backward compatibility during migration.

library cloud_ai_pulse;

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:kashkool_core/kashkool_core.dart';
import '../config/api_config.dart';
import 'reflex_guardrails.dart';

/// Result from cloud AI with fallback indicator.
/// @deprecated Use FabricResult from IntelligenceFabric instead.
class CloudAiResult<T> {
  final T data;
  final bool fromCloud;
  final bool fallbackUsed;
  final String? error;

  CloudAiResult({
    required this.data,
    required this.fromCloud,
    required this.fallbackUsed,
    this.error,
  });
}

/// Pulse-triggered cloud AI client. Sends periodic pulses to the Kashkool
/// Savior server at :4000 and falls back to local heuristic when offline.
/// @deprecated Use IntelligenceFabric instead for unified intelligence.
class CloudAiPulse {
  static String get _serverUrl => ApiConfig.baseUrl;
  static const Duration _pulseInterval = Duration(minutes: 5);
  static const Duration _timeout = Duration(seconds: 10);

  final ReflexGuardrails _guardrails = defaultGuardrails;

  DateTime? _lastPulse;
  bool _cloudAvailable = false;

  /// Send a pulse to the cloud AI and get a settlement decision.
  /// Falls back to local heuristic if cloud is unavailable.
  Future<CloudAiResult<SettlementDecision>> pulseSettlementDecision({
    required double todayRevenue,
    required int pendingTransactions,
    required DateTime? lastSettlement,
    required bool isSettlementDay,
  }) async {
    // Local heuristic decision (fast, offline)
    final localDecision = _localHeuristicSettlement(
      todayRevenue: todayRevenue,
      pendingTransactions: pendingTransactions,
      lastSettlement: lastSettlement,
      isSettlementDay: isSettlementDay,
    );

    // Try cloud pulse
    try {
      final now = DateTime.now();
      if (_lastPulse == null ||
          now.difference(_lastPulse!) >= _pulseInterval) {
        await _pingCloud();
        _lastPulse = now;
      }

      if (_cloudAvailable) {
        final cloudDecision = await _queryCloudSettlement(
          todayRevenue: todayRevenue,
          pendingTransactions: pendingTransactions,
          lastSettlement: lastSettlement,
          isSettlementDay: isSettlementDay,
        );
        return CloudAiResult<SettlementDecision>(
          data: cloudDecision,
          fromCloud: true,
          fallbackUsed: false,
        );
      }
    } catch (e) {
      _cloudAvailable = false;
    }

    // Fallback to local heuristic
    return CloudAiResult<SettlementDecision>(
      data: localDecision,
      fromCloud: false,
      fallbackUsed: true,
    );
  }

  /// Get AI-powered pricing recommendation with cloud + local fallback.
  Future<CloudAiResult<PricingRecommendation>> pulsePricingRecommendation({
    required int studentCount,
    required int sessionCountPerWeek,
    required bool needsQR,
    required bool needsSettlement,
    required bool needsWallet,
  }) async {
    final localRec = _localHeuristicPricing(
      studentCount: studentCount,
      sessionCountPerWeek: sessionCountPerWeek,
      needsQR: needsQR,
      needsSettlement: needsSettlement,
      needsWallet: needsWallet,
    );

    try {
      final now = DateTime.now();
      if (_lastPulse == null ||
          now.difference(_lastPulse!) >= _pulseInterval) {
        await _pingCloud();
        _lastPulse = now;
      }

      if (_cloudAvailable) {
        final cloudRec = await _queryCloudPricing(
          studentCount: studentCount,
          sessionCountPerWeek: sessionCountPerWeek,
          needsQR: needsQR,
          needsSettlement: needsSettlement,
          needsWallet: needsWallet,
        );
        return CloudAiResult<PricingRecommendation>(
          data: cloudRec,
          fromCloud: true,
          fallbackUsed: false,
        );
      }
    } catch (e) {
      _cloudAvailable = false;
    }

    return CloudAiResult<PricingRecommendation>(
      data: localRec,
      fromCloud: false,
      fallbackUsed: true,
    );
  }

  /// Run reflex guardrails on a transaction (always local, fast).
  GuardrailResult checkTransactionGuardrails(Map<String, dynamic> ctx) {
    return _guardrails.evaluate(ctx);
  }

  /// Ping the Kashkool Savior server health endpoint.
  Future<void> _pingCloud() async {
    try {
      final response = await http.get(
        Uri.parse('$_serverUrl/health'),
      ).timeout(_timeout);
      _cloudAvailable = response.statusCode == 200;
    } catch (_) {
      _cloudAvailable = false;
    }
  }

  /// Query cloud AI for settlement decision.
  Future<SettlementDecision> _queryCloudSettlement({
    required double todayRevenue,
    required int pendingTransactions,
    required DateTime? lastSettlement,
    required bool isSettlementDay,
  }) async {
    final response = await http.post(
      Uri.parse('$_serverUrl/v1/ai/settlement'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'todayRevenue': todayRevenue,
        'pendingTransactions': pendingTransactions,
        'lastSettlement': lastSettlement?.toIso8601String(),
        'isSettlementDay': isSettlementDay,
      }),
    ).timeout(_timeout);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return SettlementDecision(
        shouldSettle: data['shouldSettle'] ?? false,
        suggestedAmount: (data['suggestedAmount'] as num?)?.toDouble() ?? 0.0,
        reasons: List<String>.from(data['reasons'] ?? []),
        confidence: (data['confidence'] as num?)?.toDouble() ?? 0.5,
      );
    }
    throw Exception('Cloud AI returned ${response.statusCode}');
  }

  /// Query cloud AI for pricing recommendation.
  Future<PricingRecommendation> _queryCloudPricing({
    required int studentCount,
    required int sessionCountPerWeek,
    required bool needsQR,
    required bool needsSettlement,
    required bool needsWallet,
  }) async {
    final response = await http.post(
      Uri.parse('$_serverUrl/v1/ai/pricing'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'studentCount': studentCount,
        'sessionCountPerWeek': sessionCountPerWeek,
        'needsQR': needsQR,
        'needsSettlement': needsSettlement,
        'needsWallet': needsWallet,
      }),
    ).timeout(_timeout);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return PricingRecommendation(
        recommendedModules: List<String>.from(data['recommendedModules'] ?? []),
        estimatedMonthlyCost: (data['estimatedMonthlyCost'] as num?)?.toDouble() ?? 0.0,
        savingsVsBundled: (data['savingsVsBundled'] as num?)?.toDouble() ?? 0.0,
        reasoning: data['reasoning'] ?? '',
      );
    }
    throw Exception('Cloud AI returned ${response.statusCode}');
  }

  // Local heuristic methods (copied from LocalAiEngine for backward compatibility)
  SettlementDecision _localHeuristicSettlement({
    required double todayRevenue,
    required int pendingTransactions,
    required DateTime? lastSettlement,
    required bool isSettlementDay,
  }) {
    final reasons = <String>[];
    var shouldSettle = false;
    var confidence = 0.0;

    if (todayRevenue > 0) {
      reasons.add('إيرادات اليوم: ${todayRevenue.toStringAsFixed(0)} ج.م');
      shouldSettle = true;
      confidence += 0.3;
    }

    if (pendingTransactions > 0) {
      reasons.add('معاملات معلقة: $pendingTransactions');
      shouldSettle = true;
      confidence += 0.3;
    }

    if (lastSettlement == null ||
        DateTime.now().difference(lastSettlement).inHours > 24) {
      reasons.add('مر أكثر من 24 ساعة على آخر تسوية');
      confidence += 0.2;
    }

    if (isSettlementDay) {
      reasons.add('وقت التسوية اليومي (11 م)');
      confidence += 0.2;
    }

    if (confidence > 0.7) shouldSettle = true;

    return SettlementDecision(
      shouldSettle: shouldSettle,
      suggestedAmount: todayRevenue,
      reasons: reasons,
      confidence: confidence.clamp(0.0, 1.0),
    );
  }

  PricingRecommendation _localHeuristicPricing({
    required int studentCount,
    required int sessionCountPerWeek,
    required bool needsQR,
    required bool needsSettlement,
    required bool needsWallet,
  }) {
    final recommended = <String>[];
    var monthlyCost = 0.0;
    final reasoning = <String>[];

    recommended.add('teacherCore');
    reasoning.add('الوحدة الأساسية مجانية دائماً');

    if (needsQR) {
      recommended.add('qr_checkin');
      reasoning.add('فحص الحضور عبر QR');
    }

    if (needsSettlement) {
      recommended.add('teacherSettlementAuto');
      monthlyCost += 50;
      reasoning.add('التسوية التلقائية: 50 ج.م/شهر');
    }

    if (needsWallet) {
      recommended.add('teacherWalletPayout');
      monthlyCost += 30;
      reasoning.add('محفظة الدفع: 30 ج.م/شهر');
    }

    if (studentCount > 30) {
      recommended.add('teacherStudentInsights');
      monthlyCost += 30;
      reasoning.add('تحليلات الطلاب (>30 طالب): 30 ج.م/شهر');
    }

    if (sessionCountPerWeek > 20) {
      recommended.add('teacherMultiCenter');
      monthlyCost += 20;
      reasoning.add('متعدد المراكز (>20 حصة/أسبوع): 20 ج.م/شهر');
    }

    const bundledCost = 250.0;
    final savings = bundledCost - monthlyCost;

    return PricingRecommendation(
      recommendedModules: recommended,
      estimatedMonthlyCost: monthlyCost,
      savingsVsBundled: savings > 0 ? savings : 0.0,
      reasoning: reasoning.join('\n'),
    );
  }
}

/// Singleton instance for convenient access.
/// @deprecated Use IntelligenceFabric via Riverpod instead.
final CloudAiPulse cloudAiPulse = CloudAiPulse();
