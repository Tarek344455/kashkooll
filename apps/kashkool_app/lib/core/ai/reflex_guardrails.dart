/// Reflex Guardrails — fast local rules for fraud detection, rate limiting,
/// and homeostasis. Runs synchronously on-device with zero network dependency.

library reflex_guardrails;
// ignore_for_file: prefer_const_constructors

/// Result of a guardrail check.
class GuardrailResult {
  final bool allowed;
  final List<String> violations;
  final double riskScore;
  final String action; // 'allow', 'warn', 'block'

  GuardrailResult({
    required this.allowed,
    required this.violations,
    required this.riskScore,
    required this.action,
  });

  bool get isBlocked => action == 'block';
  bool get isWarning => action == 'warn';
}

/// Homeostasis rule: keeps system in stable state by detecting anomalies.
class HomeostasisRule {
  final String name;
  final bool Function(Map<String, dynamic>) check;
  final String violationMessage;
  final double riskWeight;

  HomeostasisRule({
    required this.name,
    required this.check,
    required this.violationMessage,
    this.riskWeight = 0.3,
  });
}

/// Reflex guardrails engine — evaluates transactions and actions against
/// local fraud and anomaly rules.
class ReflexGuardrails {
  final List<HomeostasisRule> _rules = [];

  ReflexGuardrails withRules(List<HomeostasisRule> rules) {
    _rules.addAll(rules);
    return this;
  }

  /// Evaluate an action against all guardrail rules.
  GuardrailResult evaluate(Map<String, dynamic> context) {
    final violations = <String>[];
    var riskScore = 0.0;

    for (final rule in _rules) {
      if (!rule.check(context)) {
        violations.add(rule.violationMessage);
        riskScore += rule.riskWeight;
      }
    }

    riskScore = riskScore.clamp(0.0, 1.0);

    String action;
    bool allowed;
    if (riskScore >= 0.7) {
      action = 'block';
      allowed = false;
    } else if (riskScore >= 0.4) {
      action = 'warn';
      allowed = true;
    } else {
      action = 'allow';
      allowed = true;
    }

    return GuardrailResult(
      allowed: allowed,
      violations: violations,
      riskScore: riskScore,
      action: action,
    );
  }
}

/// Default guardrails for financial transactions.
class FinancialGuardrails {
  const FinancialGuardrails();

  /// Check for suspicious transaction patterns.
  static GuardrailResult checkTransaction(Map<String, dynamic> ctx) {
    final amount = (ctx['amount'] as num?)?.toDouble() ?? 0.0;
    final channel = ctx['channel'] as String? ?? '';
    final hour = DateTime.now().hour;
    final dailyCount = (ctx['dailyTransactionCount'] as int?) ?? 0;

    final violations = <String>[];
    var riskScore = 0.0;

    // Unusually large amount (> 5000 EGP)
    if (amount > 5000) {
      violations.add('مبلغ كبير بشكل غير عادي: ${amount.toStringAsFixed(0)} ج.م');
      riskScore += 0.3;
    }

    // Late night transactions (11 PM - 5 AM) other than settlement
    if ((hour >= 23 || hour <= 5) && channel != 'settlement') {
      violations.add('معاملة في وقت متأخر من الليل');
      riskScore += 0.2;
    }

    // High frequency (> 20 transactions/day)
    if (dailyCount > 20) {
      violations.add('عدد معاملات اليوم مرتفع: $dailyCount');
      riskScore += 0.2;
    }

    riskScore = riskScore.clamp(0.0, 1.0);

    String action;
    bool allowed;
    if (riskScore >= 0.7) {
      action = 'block';
      allowed = false;
    } else if (riskScore >= 0.4) {
      action = 'warn';
      allowed = true;
    } else {
      action = 'allow';
      allowed = true;
    }

    return GuardrailResult(
      allowed: allowed,
      violations: violations,
      riskScore: riskScore,
      action: action,
    );
  }

  /// Check for data access anomalies (possible ghost impersonation abuse).
  static GuardrailResult checkDataAccess(Map<String, dynamic> ctx) {
    final tenantId = ctx['tenantId'] as String? ?? '';
    final requestingUserId = ctx['requestingUserId'] as String? ?? '';
    final targetTenantId = ctx['targetTenantId'] as String? ?? '';
    final isGhostMode = ctx['isGhostMode'] as bool? ?? false;

    final violations = <String>[];
    var riskScore = 0.0;

    // Cross-tenant access without ghost mode
    if (tenantId.isNotEmpty &&
        targetTenantId.isNotEmpty &&
        tenantId != targetTenantId &&
        !isGhostMode) {
      violations.add('وصول عبر مراكز مختلفة بدون وضع الشبح');
      riskScore += 0.5;
    }

    // Empty user ID
    if (requestingUserId.isEmpty) {
      violations.add('معرف مستخدم غير محدد');
      riskScore += 0.3;
    }

    riskScore = riskScore.clamp(0.0, 1.0);

    String action;
    bool allowed;
    if (riskScore >= 0.7) {
      action = 'block';
      allowed = false;
    } else if (riskScore >= 0.4) {
      action = 'warn';
      allowed = true;
    } else {
      action = 'allow';
      allowed = true;
    }

    return GuardrailResult(
      allowed: allowed,
      violations: violations,
      riskScore: riskScore,
      action: action,
    );
  }
}

/// Default set of reflex guardrails ready to use.
final defaultGuardrails = ReflexGuardrails()
  ..withRules([
    HomeostasisRule(
      name: 'max_daily_revenue',
      check: (ctx) {
        final dailyRev = (ctx['dailyRevenue'] as num?)?.toDouble() ?? 0.0;
        return dailyRev <= 50000; // 50K EGP daily cap
      },
      violationMessage: 'تجاوز الحد اليومي للإيرادات',
      riskWeight: 0.4,
    ),
    HomeostasisRule(
      name: 'settlement_time_window',
      check: (ctx) {
        final hour = DateTime.now().hour;
        return hour >= 22 && hour <= 23; // Settlement window 10-11 PM
      },
      violationMessage: 'التسوية خارج النافذة المسموحة (22-23)',
      riskWeight: 0.2,
    ),
  ]);
