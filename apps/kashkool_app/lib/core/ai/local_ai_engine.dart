/// Local AI Engine — offline-first AI for settlement and pricing decisions.
/// Runs entirely on-device with no network dependency. Falls back to heuristic
/// rules when no model is available.
///
/// NOTE: SettlementDecision and PricingRecommendation are now defined in
/// kashkool_core (pricing_model.dart). This file keeps LocalAiEngine for
/// backward compatibility but delegates to the unified IntelligenceFabric.

library local_ai_engine;
// ignore_for_file: unnecessary_brace_in_string_interps, prefer_const_constructors

import 'package:kashkool_core/kashkool_core.dart';

/// Local AI engine for offline settlement and pricing decisions.
/// @deprecated Use IntelligenceFabric instead for unified intelligence.
class LocalAiEngine {
  const LocalAiEngine();

  /// Decide whether to run daily settlement based on local heuristics.
  /// Factors: pending transactions, revenue threshold, time since last settlement.
  SettlementDecision decideSettlement({
    required double todayRevenue,
    required int pendingTransactions,
    required DateTime? lastSettlement,
    required bool isSettlementDay,
  }) {
    final reasons = <String>[];
    var shouldSettle = false;
    var confidence = 0.0;

    // Heuristic 1: Revenue threshold
    if (todayRevenue > 0) {
      reasons.add('إيرادات اليوم: ${todayRevenue.toStringAsFixed(0)} ج.م');
      shouldSettle = true;
      confidence += 0.3;
    }

    // Heuristic 2: Pending transactions exist
    if (pendingTransactions > 0) {
      reasons.add('معاملات معلقة: $pendingTransactions');
      shouldSettle = true;
      confidence += 0.3;
    }

    // Heuristic 3: Time since last settlement (> 24h)
    if (lastSettlement == null ||
        DateTime.now().difference(lastSettlement).inHours > 24) {
      reasons.add('مر أكثر من 24 ساعة على آخر تسوية');
      confidence += 0.2;
    }

    // Heuristic 4: It's settlement day (11 PM cycle)
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

  /// Recommend modules based on usage patterns (offline heuristic).
  PricingRecommendation recommendModules({
    required int studentCount,
    required int sessionCountPerWeek,
    required bool needsQR,
    required bool needsSettlement,
    required bool needsWallet,
  }) {
    final recommended = <String>[];
    var monthlyCost = 0.0;

    // Core is always free
    recommended.add('teacherCore');

    if (needsQR) {
      recommended.add('qr_checkin'); // part of teacherCore
    }

    if (needsSettlement) {
      recommended.add('teacherSettlementAuto');
      monthlyCost += 50;
    }

    if (needsWallet) {
      recommended.add('teacherWalletPayout');
      monthlyCost += 30;
    }

    // AI insights for larger student bases
    if (studentCount > 30) {
      recommended.add('teacherStudentInsights');
      monthlyCost += 30;
    }

    // Multi-center for multiple locations
    if (sessionCountPerWeek > 20) {
      recommended.add('teacherMultiCenter');
      monthlyCost += 20;
    }

    const bundledCost = 250.0; // hypothetical bundled price
    final savings = bundledCost - monthlyCost;

    return PricingRecommendation(
      recommendedModules: recommended,
      estimatedMonthlyCost: monthlyCost,
      savingsVsBundled: savings > 0 ? savings : 0.0,
      reasoning:
          'بناءً على ${studentCount} طالب و ${sessionCountPerWeek} حصة أسبوعياً، الوحدات الموصى بها تغطي احتياجاتك دون تكاليف غير ضرورية.',
    );
  }
}

/// Singleton instance for convenient access.
final LocalAiEngine localAiEngine = LocalAiEngine();
