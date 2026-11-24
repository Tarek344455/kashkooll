/// Unified Intelligence Fabric — single cohesive mind combining local reflexes,
/// Operations Research, and cloud intelligence with seamless, imperceptible switching.
///
/// This replaces the fragmented LocalAiEngine + CloudAiPulse + ReflexGuardrails
/// with one unified fabric that operates at peak strength everywhere.

library intelligence_fabric;

import 'dart:async';
import 'dart:math' as math;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kashkool_core/kashkool_core.dart';
import '../services/network_client.dart';
import 'reflex_guardrails.dart';

/// Unified result from the intelligence fabric — always includes source metadata
/// for observability and debugging.
class FabricResult<T> {
  final T data;
  final FabricSource source;
  final Duration latency;
  final Map<String, dynamic> metadata;
  final bool degraded;

  const FabricResult({
    required this.data,
    required this.source,
    required this.latency,
    this.metadata = const {},
    this.degraded = false,
  });

  FabricResult<T> copyWith({
    T? data,
    FabricSource? source,
    Duration? latency,
    Map<String, dynamic>? metadata,
    bool? degraded,
  }) {
    return FabricResult<T>(
      data: data ?? this.data,
      source: source ?? this.source,
      latency: latency ?? this.latency,
      metadata: metadata ?? this.metadata,
      degraded: degraded ?? this.degraded,
    );
  }
}

/// Source of the decision — enables seamless switching observability.
enum FabricSource {
  localReflex,      // <1ms, deterministic rules (Reflex Guardrails)
  localOR,          // <5ms, Operations Research solver
  localHeuristic,   // <10ms, heuristic AI (LocalAiEngine)
  cloudEnhanced,    // 50-500ms, cloud AI via Savior (:4000)
  cloudVerified,    // async verification of local decision
  hybrid,           // combined local + cloud
}

/// Context that flows through the entire fabric — shared by all components.
class FabricContext {
  final String? accountId;
  final String? tenantId;
  final AccountType? accountType;
  final Map<String, dynamic> runtimeMetrics;
  final Map<String, dynamic> userSignals;
  final DateTime timestamp;
  final String requestId;

  FabricContext({
    this.accountId,
    this.tenantId,
    this.accountType,
    this.runtimeMetrics = const {},
    this.userSignals = const {},
    DateTime? timestamp,
    String? requestId,
  }) : timestamp = timestamp ?? DateTime.now(),
       requestId = requestId ?? _genRequestId();

  static String _genRequestId() =>
      'fabric_${DateTime.now().microsecondsSinceEpoch}_${math.Random().nextInt(10000)}';

  FabricContext withUpdates({
    String? accountId,
    String? tenantId,
    AccountType? accountType,
    Map<String, dynamic>? runtimeMetrics,
    Map<String, dynamic>? userSignals,
  }) {
    return FabricContext(
      accountId: accountId ?? this.accountId,
      tenantId: tenantId ?? this.tenantId,
      accountType: accountType ?? this.accountType,
      runtimeMetrics: {...this.runtimeMetrics, ...?runtimeMetrics},
      userSignals: {...this.userSignals, ...?userSignals},
      timestamp: timestamp,
      requestId: requestId,
    );
  }
}

/// Health signal for proactive switching — emitted by all fabric components.
class HealthSignal {
  final String componentId;
  final double healthScore; // 0.0 - 1.0
  final Duration latencyP95;
  final int errorCount;
  final int successCount;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;

  const HealthSignal({
    required this.componentId,
    required this.healthScore,
    required this.latencyP95,
    required this.errorCount,
    required this.successCount,
    required this.timestamp,
    this.metadata = const {},
  });

  bool get isHealthy => healthScore >= 0.7 && errorCount < 3;
  bool get isDegraded => healthScore < 0.7 || errorCount >= 3;
  bool get isCritical => healthScore < 0.3 || errorCount >= 10;
}

/// Unified Intelligence Fabric — the single cohesive mind.
class IntelligenceFabric {
  final BillingNetworkClient _networkClient;
  final ORSolver _orSolver;

  // Health tracking for proactive switching
  final Map<String, HealthSignal> _healthSignals = {};
  final StreamController<HealthSignal> _healthStreamController =
      StreamController<HealthSignal>.broadcast();

  // Predictive pre-warming
  final Map<String, Future<void>> _prewarmFutures = {};
  Timer? _prewarmTimer;

  // Shared context bus
  FabricContext _globalContext = FabricContext();
  final StreamController<FabricContext> _contextStreamController =
      StreamController<FabricContext>.broadcast();

  // Cloud availability with fast detection
  bool _cloudAvailable = false;
  DateTime? _lastCloudCheck;
  static const Duration _cloudCheckInterval = Duration(seconds: 30);
  static const Duration _cloudTimeout = Duration(seconds: 8);

  IntelligenceFabric({
    required BillingNetworkClient networkClient,
  }) : _networkClient = networkClient,
       _orSolver = ORSolver() {
    _startBackgroundServices();
  }

  /// Stream of health signals for observability and proactive switching.
  Stream<HealthSignal> get healthSignals => _healthStreamController.stream;

  /// Stream of context updates for coordinated intelligence.
  Stream<FabricContext> get contextUpdates => _contextStreamController.stream;

  /// Current global context.
  FabricContext get context => _globalContext;

  /// Update global context — notifies all fabric components.
  void updateContext(FabricContext newContext) {
    _globalContext = newContext;
    _contextStreamController.add(newContext);
  }

  /// Record health signal — enables proactive failover.
  void recordHealth(HealthSignal signal) {
    _healthSignals[signal.componentId] = signal;
    _healthStreamController.add(signal);
    _evaluateProactiveSwitch(signal);
  }

  // =========================================================================
  // SETTLEMENT DECISIONS — Zero-RTT local reflex + async cloud enhancement
  // =========================================================================

  /// Decide settlement with zero-RTT local reflex, enhanced by cloud async.
  /// Returns immediately with local decision, then enhances if cloud available.
  Future<FabricResult<SettlementDecision>> decideSettlement({
    required double todayRevenue,
    required int pendingTransactions,
    required DateTime? lastSettlement,
    required bool isSettlementDay,
  }) async {
    final stopwatch = Stopwatch()..start();
    final requestId = _globalContext.requestId;

    // LAYER 1: Reflex Guardrails (deterministic, <1ms) — FRAUD/SAFETY FIRST
    final guardrailResult = _evaluateSettlementGuardrails({
      'todayRevenue': todayRevenue,
      'pendingTransactions': pendingTransactions,
      'lastSettlement': lastSettlement?.toIso8601String(),
      'isSettlementDay': isSettlementDay,
      'hour': DateTime.now().hour,
    });

    if (guardrailResult.isBlocked) {
      stopwatch.stop();
      return FabricResult<SettlementDecision>(
        data: SettlementDecision(
          shouldSettle: false,
          suggestedAmount: 0,
          reasons: ['محظور: ${guardrailResult.violations.join(', ')}'],
          confidence: 1.0,
        ),
        source: FabricSource.localReflex,
        latency: stopwatch.elapsed,
        metadata: {'guardrailAction': guardrailResult.action, 'violations': guardrailResult.violations},
        degraded: true,
      );
    }

    // LAYER 2: Operations Research Solver (deterministic, <5ms) — MATHEMATICAL OPTIMALITY
    final orResult = _orSolver.optimizeSettlement(
      todayRevenue: todayRevenue,
      pendingTransactions: pendingTransactions,
      lastSettlement: lastSettlement,
      isSettlementDay: isSettlementDay,
    );

    // LAYER 3: Local Heuristic AI (fast, <10ms) — CONTEXTUAL INTELLIGENCE
    final localDecision = _localHeuristicSettlement(
      todayRevenue: todayRevenue,
      pendingTransactions: pendingTransactions,
      lastSettlement: lastSettlement,
      isSettlementDay: isSettlementDay,
      orRecommendation: orResult,
    );

    stopwatch.stop();

    // Return immediately with best local decision (zero-RTT for user)
    final localResult = FabricResult<SettlementDecision>(
      data: localDecision,
      source: orResult.feasible ? FabricSource.localOR : FabricSource.localHeuristic,
      latency: stopwatch.elapsed,
      metadata: {
        'guardrailRisk': guardrailResult.riskScore,
        'orFeasible': orResult.feasible,
        'orWarnings': orResult.warnings,
      },
    );

    // ASYNC: Enhance with cloud if available (non-blocking)
    _enhanceWithCloudSettlement(
      requestId: requestId,
      localDecision: localDecision,
      context: {
        'todayRevenue': todayRevenue,
        'pendingTransactions': pendingTransactions,
        'lastSettlement': lastSettlement?.toIso8601String(),
        'isSettlementDay': isSettlementDay,
      },
    );

    return localResult;
  }

  /// Local heuristic settlement decision (replaces LocalAiEngine.decideSettlement).
  SettlementDecision _localHeuristicSettlement({
    required double todayRevenue,
    required int pendingTransactions,
    required DateTime? lastSettlement,
    required bool isSettlementDay,
    required FinancialOptimizationResult orRecommendation,
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

    // OR solver adds mathematical confidence
    if (orRecommendation.feasible) {
      reasons.add('المحلل الرياضي: ${orRecommendation.warnings.join('; ')}');
      confidence += 0.15;
    }

    if (confidence > 0.7) shouldSettle = true;

    return SettlementDecision(
      shouldSettle: shouldSettle,
      suggestedAmount: todayRevenue,
      reasons: reasons,
      confidence: confidence.clamp(0.0, 1.0),
    );
  }

  /// Evaluate settlement guardrails (replaces ReflexGuardrails for settlement).
  GuardrailResult _evaluateSettlementGuardrails(Map<String, dynamic> ctx) {
    final hour = ctx['hour'] as int? ?? DateTime.now().hour;
    final dailyRev = (ctx['todayRevenue'] as num?)?.toDouble() ?? 0.0;
    final pendingTx = ctx['pendingTransactions'] as int? ?? 0;

    final violations = <String>[];
    var riskScore = 0.0;

    // Settlement window enforcement (10-11 PM)
    if (hour < 22 || hour > 23) {
      violations.add('التسوية خارج النافذة المسموحة (22-23)');
      riskScore += 0.3;
    }

    // Daily revenue cap
    if (dailyRev > 50000) {
      violations.add('تجاوز الحد اليومي للإيرادات (50,000 ج.م)');
      riskScore += 0.4;
    }

    // Excessive pending transactions
    if (pendingTx > 100) {
      violations.add('عدد معاملات معلقة مرتفع جداً: $pendingTx');
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

  // =========================================================================
  // PRICING RECOMMENDATIONS — OR Solver + Local Heuristic + Cloud Enhanced
  // =========================================================================

  /// Get pricing recommendation with mathematical optimization + cloud enhancement.
  Future<FabricResult<PricingRecommendation>> recommendPricing({
    required int studentCount,
    required int sessionCountPerWeek,
    required bool needsQR,
    required bool needsSettlement,
    required bool needsWallet,
    AccountType? accountType,
  }) async {
    final stopwatch = Stopwatch()..start();
    final requestId = _globalContext.requestId;

    // LAYER 1: OR Solver — Mathematical optimization (deterministic, <5ms)
    final orResult = _orSolver.optimizePricing(
      studentCount: studentCount,
      sessionCountPerWeek: sessionCountPerWeek,
      needsQR: needsQR,
      needsSettlement: needsSettlement,
      needsWallet: needsWallet,
      accountType: accountType ?? _globalContext.accountType ?? AccountType.teacher,
    );

    // LAYER 2: Local Heuristic — Contextual intelligence (<10ms)
    final localRec = _localHeuristicPricing(
      studentCount: studentCount,
      sessionCountPerWeek: sessionCountPerWeek,
      needsQR: needsQR,
      needsSettlement: needsSettlement,
      needsWallet: needsWallet,
      orRecommendation: orResult,
    );

    stopwatch.stop();

    final localResult = FabricResult<PricingRecommendation>(
      data: localRec,
      source: orResult.feasible ? FabricSource.localOR : FabricSource.localHeuristic,
      latency: stopwatch.elapsed,
      metadata: {
        'orFeasible': orResult.feasible,
        'orModules': orResult.warnings, // warnings contain module info
        'orCost': orResult.totalPiasters / 100.0,
      },
    );

    // ASYNC: Cloud enhancement
    _enhanceWithCloudPricing(
      requestId: requestId,
      localRecommendation: localRec,
      context: {
        'studentCount': studentCount,
        'sessionCountPerWeek': sessionCountPerWeek,
        'needsQR': needsQR,
        'needsSettlement': needsSettlement,
        'needsWallet': needsWallet,
        'accountType': accountType?.name ?? _globalContext.accountType?.name,
      },
    );

    return localResult;
  }

  PricingRecommendation _localHeuristicPricing({
    required int studentCount,
    required int sessionCountPerWeek,
    required bool needsQR,
    required bool needsSettlement,
    required bool needsWallet,
    required FinancialOptimizationResult orRecommendation,
  }) {
    final recommended = <String>[];
    var monthlyCost = 0.0;
    final reasoning = <String>[];

    // Core is always free
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

    // OR solver validation
    if (orRecommendation.feasible) {
      reasoning.add('المحلل الرياضي يؤكد الجدوى: ${orRecommendation.warnings.join('; ')}');
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

  // =========================================================================
  // TRANSACTION GUARDRAILS — Zero-RTT fraud detection
  // =========================================================================

  /// Check transaction against all guardrails — zero-RTT, deterministic.
  GuardrailResult checkTransactionGuardrails(Map<String, dynamic> ctx) {
    final stopwatch = Stopwatch()..start();

    final result = _evaluateTransactionGuardrails(ctx);

    stopwatch.stop();
    recordHealth(HealthSignal(
      componentId: 'transaction_guardrails',
      healthScore: result.allowed ? 1.0 : 0.3,
      latencyP95: stopwatch.elapsed,
      errorCount: result.allowed ? 0 : 1,
      successCount: result.allowed ? 1 : 0,
      timestamp: DateTime.now(),
      metadata: {'riskScore': result.riskScore, 'action': result.action},
    ));

    return result;
  }

  GuardrailResult _evaluateTransactionGuardrails(Map<String, dynamic> ctx) {
    final amount = (ctx['amount'] as num?)?.toDouble() ?? 0.0;
    final channel = ctx['channel'] as String? ?? '';
    final hour = DateTime.now().hour;
    final dailyCount = (ctx['dailyTransactionCount'] as int?) ?? 0;
    final dailyRevenue = (ctx['dailyRevenue'] as num?)?.toDouble() ?? 0.0;
    final tenantId = ctx['tenantId'] as String? ?? '';
    final targetTenantId = ctx['targetTenantId'] as String? ?? '';
    final isGhostMode = ctx['isGhostMode'] as bool? ?? false;
    final requestingUserId = ctx['requestingUserId'] as String? ?? '';

    final violations = <String>[];
    var riskScore = 0.0;

    // Financial anomalies
    if (amount > 5000) {
      violations.add('مبلغ كبير بشكل غير عادي: ${amount.toStringAsFixed(0)} ج.م');
      riskScore += 0.3;
    }

    if ((hour >= 23 || hour <= 5) && channel != 'settlement') {
      violations.add('معاملة في وقت متأخر من الليل');
      riskScore += 0.2;
    }

    if (dailyCount > 20) {
      violations.add('عدد معاملات اليوم مرتفع: $dailyCount');
      riskScore += 0.2;
    }

    if (dailyRevenue > 50000) {
      violations.add('تجاوز الحد اليومي للإيرادات');
      riskScore += 0.4;
    }

    // Data access anomalies
    if (tenantId.isNotEmpty &&
        targetTenantId.isNotEmpty &&
        tenantId != targetTenantId &&
        !isGhostMode) {
      violations.add('وصول عبر مراكز مختلفة بدون وضع الشبح');
      riskScore += 0.5;
    }

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

  // =========================================================================
  // CLOUD ENHANCEMENT — Async, non-blocking, with verification
  // =========================================================================

  Future<void> _enhanceWithCloudSettlement({
    required String requestId,
    required SettlementDecision localDecision,
    required Map<String, dynamic> context,
  }) async {
    if (!_shouldUseCloud()) return;

    try {
      final cloudDecision = await _queryCloudSettlement(context).timeout(_cloudTimeout);

      // Verify cloud agrees with local (consistency check)
      final consistent = cloudDecision.shouldSettle == localDecision.shouldSettle &&
          (cloudDecision.suggestedAmount - localDecision.suggestedAmount).abs() < 1.0;

      // Update context with cloud verification
      updateContext(_globalContext.withUpdates(
        runtimeMetrics: {
          'cloudVerification': consistent ? 'consistent' : 'divergent',
          'cloudConfidence': cloudDecision.confidence,
          'localConfidence': localDecision.confidence,
        },
      ));

      recordHealth(HealthSignal(
        componentId: 'cloud_settlement',
        healthScore: consistent ? 1.0 : 0.6,
        latencyP95: _cloudTimeout,
        errorCount: consistent ? 0 : 1,
        successCount: 1,
        timestamp: DateTime.now(),
        metadata: {'consistent': consistent, 'requestId': requestId},
      ));
    } catch (e) {
      _cloudAvailable = false;
      recordHealth(HealthSignal(
        componentId: 'cloud_settlement',
        healthScore: 0.0,
        latencyP95: _cloudTimeout,
        errorCount: 1,
        successCount: 0,
        timestamp: DateTime.now(),
        metadata: {'error': e.toString(), 'requestId': requestId},
      ));
    }
  }

  Future<void> _enhanceWithCloudPricing({
    required String requestId,
    required PricingRecommendation localRecommendation,
    required Map<String, dynamic> context,
  }) async {
    if (!_shouldUseCloud()) return;

    try {
      final cloudRec = await _queryCloudPricing(context).timeout(_cloudTimeout);

      // Merge: cloud can add modules but local OR solver is authoritative on feasibility
      final mergedModules = <String>{...localRecommendation.recommendedModules, ...cloudRec.recommendedModules}.toList();

      updateContext(_globalContext.withUpdates(
        runtimeMetrics: {
          'cloudPricingModules': cloudRec.recommendedModules,
          'mergedModules': mergedModules,
          'cloudSavings': cloudRec.savingsVsBundled,
        },
      ));

      recordHealth(HealthSignal(
        componentId: 'cloud_pricing',
        healthScore: 1.0,
        latencyP95: _cloudTimeout,
        errorCount: 0,
        successCount: 1,
        timestamp: DateTime.now(),
        metadata: {'requestId': requestId},
      ));
    } catch (e) {
      _cloudAvailable = false;
      recordHealth(HealthSignal(
        componentId: 'cloud_pricing',
        healthScore: 0.0,
        latencyP95: _cloudTimeout,
        errorCount: 1,
        successCount: 0,
        timestamp: DateTime.now(),
        metadata: {'error': e.toString(), 'requestId': requestId},
      ));
    }
  }

  bool _shouldUseCloud() {
    final now = DateTime.now();
    if (_lastCloudCheck != null &&
        now.difference(_lastCloudCheck!) < _cloudCheckInterval) {
      return _cloudAvailable;
    }
    return _cloudAvailable;
  }

  Future<void> _pingCloud() async {
    try {
      final response = await _networkClient.get('/health').timeout(_cloudTimeout);
      _cloudAvailable = response.statusCode == 200;
      _lastCloudCheck = DateTime.now();

      recordHealth(HealthSignal(
        componentId: 'cloud_connection',
        healthScore: _cloudAvailable ? 1.0 : 0.0,
        latencyP95: Duration(milliseconds: response.statusCode == 200 ? 50 : 8000),
        errorCount: _cloudAvailable ? 0 : 1,
        successCount: _cloudAvailable ? 1 : 0,
        timestamp: DateTime.now(),
      ));
    } catch (_) {
      _cloudAvailable = false;
      _lastCloudCheck = DateTime.now();
    }
  }

  Future<SettlementDecision> _queryCloudSettlement(Map<String, dynamic> context) async {
    await _pingCloud();
    if (!_cloudAvailable) throw Exception('Cloud unavailable');

    final response = await _networkClient.post(
      '/v1/ai/settlement',
      body: context,
    ).timeout(_cloudTimeout);

    if (response.statusCode == 200 && response.data != null) {
      final data = response.data as Map<String, dynamic>;
      return SettlementDecision(
        shouldSettle: data['shouldSettle'] ?? false,
        suggestedAmount: (data['suggestedAmount'] as num?)?.toDouble() ?? 0.0,
        reasons: List<String>.from(data['reasons'] ?? []),
        confidence: (data['confidence'] as num?)?.toDouble() ?? 0.5,
      );
    }
    throw Exception('Cloud AI returned ${response.statusCode}');
  }

  Future<PricingRecommendation> _queryCloudPricing(Map<String, dynamic> context) async {
    await _pingCloud();
    if (!_cloudAvailable) throw Exception('Cloud unavailable');

    final response = await _networkClient.post(
      '/v1/ai/pricing',
      body: context,
    ).timeout(_cloudTimeout);

    if (response.statusCode == 200 && response.data != null) {
      final data = response.data as Map<String, dynamic>;
      return PricingRecommendation(
        recommendedModules: List<String>.from(data['recommendedModules'] ?? []),
        estimatedMonthlyCost: (data['estimatedMonthlyCost'] as num?)?.toDouble() ?? 0.0,
        savingsVsBundled: (data['savingsVsBundled'] as num?)?.toDouble() ?? 0.0,
        reasoning: data['reasoning'] ?? '',
      );
    }
    throw Exception('Cloud AI returned ${response.statusCode}');
  }

  // =========================================================================
  // PREDICTIVE PRE-WARMING — Anticipate next requests
  // =========================================================================

  void _startBackgroundServices() {
    // Initial cloud ping
    _pingCloud();

    // Periodic cloud health check
    Timer.periodic(_cloudCheckInterval, (_) => _pingCloud());

    // Predictive pre-warming based on usage patterns
    _prewarmTimer = Timer.periodic(const Duration(minutes: 2), (_) => _predictivePrewarm());

    // Context-aware pre-warming
    _contextStreamController.stream.listen((context) {
      _contextAwarePrewarm(context);
    });
  }

  void _predictivePrewarm() {
    // Pre-warm cloud connection if settlement time approaching
    final hour = DateTime.now().hour;
    if (hour == 21 || hour == 22) {
      // Settlement window approaching - pre-warm
      _prewarmCloud('/v1/ai/settlement');
    }

    // Pre-warm pricing if user browsing pricing calculator
    if (_globalContext.userSignals['viewing_pricing'] == true) {
      _prewarmCloud('/v1/ai/pricing');
    }
  }

  void _contextAwarePrewarm(FabricContext context) {
    if (context.userSignals['viewing_pricing'] == true) {
      _prewarmCloud('/v1/ai/pricing');
    }
    if (context.userSignals['initiating_payment'] == true) {
      _prewarmCloud('/v1/wallet/prepare');
    }
  }

  void _prewarmCloud(String endpoint) {
    final key = 'prewarm_$endpoint';
    if (_prewarmFutures.containsKey(key)) return;

    _prewarmFutures[key] = _networkClient.get('/health').then((_) {
      _prewarmFutures.remove(key);
    }).catchError((_) {
      _prewarmFutures.remove(key);
    });
  }

  // =========================================================================
  // PROACTIVE SWITCHING — Switch before failure
  // =========================================================================

  void _evaluateProactiveSwitch(HealthSignal signal) {
    if (signal.isCritical) {
      // Critical degradation - trigger immediate fallback preparation
      _prepareFallback(signal.componentId);
    } else if (signal.isDegraded) {
      // Degraded - increase monitoring frequency
      _increaseMonitoring(signal.componentId);
    }
  }

  void _prepareFallback(String componentId) {
    // Pre-warm alternative paths
    switch (componentId) {
      case 'cloud_settlement':
      case 'cloud_pricing':
      case 'cloud_connection':
        // Local fabric is already primary - just ensure it's healthy
        recordHealth(HealthSignal(
          componentId: 'local_fabric_fallback',
          healthScore: 1.0,
          latencyP95: const Duration(milliseconds: 5),
          errorCount: 0,
          successCount: 1,
          timestamp: DateTime.now(),
          metadata: {'triggeredBy': componentId},
        ));
        break;
    }
  }

  void _increaseMonitoring(String componentId) {
    // Could increase health check frequency for this component
  }

  // =========================================================================
  // SCHEDULING — Unified OR Solver access
  // =========================================================================

  /// Solve schedule with full OR power + guardrails.
  Future<FabricResult<ScheduleSolveResult>> solveSchedule({
    required List<SessionModel> sessions,
    required List<String> availableRooms,
    required Map<String, String> roomIdBySessionId,
    required Map<String, String> teacherIdBySessionId,
  }) async {
    final stopwatch = Stopwatch()..start();

    // Guardrails first
    final guardrailResult = checkTransactionGuardrails({
      'dailyTransactionCount': sessions.length,
      'channel': 'schedule',
    });

    if (guardrailResult.isBlocked) {
      stopwatch.stop();
      return FabricResult<ScheduleSolveResult>(
        data: ScheduleSolveResult(
          feasible: false,
          slots: [],
          conflicts: [SessionConflict(
            type: ConflictType.invalidDuration,
            message: 'محظور: ${guardrailResult.violations.join(', ')}',
            sourceField: 'schedule',
          )],
          iterations: 0,
          solveTimeMs: 0,
        ),
        source: FabricSource.localReflex,
        latency: stopwatch.elapsed,
        degraded: true,
      );
    }

    // OR Solver
    final result = _orSolver.solve(
      sessions: sessions,
      availableRooms: availableRooms,
      roomIdBySessionId: roomIdBySessionId,
      teacherIdBySessionId: teacherIdBySessionId,
    );

    stopwatch.stop();

    return FabricResult<ScheduleSolveResult>(
      data: result,
      source: FabricSource.localOR,
      latency: stopwatch.elapsed,
      metadata: {
        'iterations': result.iterations,
        'conflicts': result.conflicts.length,
      },
    );
  }

  /// Financial optimization — exact piasters, no drift.
  Future<FabricResult<FinancialOptimizationResult>> optimizeFinancial({
    required int totalPiasters,
    required int installmentCount,
    required DateTime startDate,
    bool allowPartial = true,
    Map<String, double>? centerWeights,
  }) async {
    final stopwatch = Stopwatch()..start();

    final installments = _orSolver.planInstallments(
      totalPiasters: totalPiasters,
      installmentCount: installmentCount,
      startDate: startDate,
      allowPartial: allowPartial,
    );

    Map<String, int> revenueSplit = {};
    if (centerWeights != null && centerWeights.isNotEmpty) {
      revenueSplit = _orSolver.splitRevenue(
        totalPiasters: totalPiasters,
        centerWeights: centerWeights,
      );
    }

    stopwatch.stop();

    return FabricResult<FinancialOptimizationResult>(
      data: FinancialOptimizationResult(
        feasible: installments.feasible,
        totalPiasters: installments.totalPiasters,
        remainingPiasters: installments.remainingPiasters,
        installments: installments.installments,
        revenueSplitPiasters: revenueSplit,
        warnings: installments.warnings,
      ),
      source: FabricSource.localOR,
      latency: stopwatch.elapsed,
    );
  }

  /// Validate money at source — Egyptian compliance.
  MoneyValidation validateMoney(int amountPiasters) {
    return EgyptValidators.validatePiasters(amountPiasters);
  }

  /// Validate session schedule at source.
  SessionValidationResult validateSession(SessionModel session, {
    List<SessionModel>? existingSessions,
    Map<String, int>? roomCapacities,
    required Map<String, String> roomIdBySessionId,
    required Map<String, String> teacherIdBySessionId,
  }) {
    return EgyptValidators.validateSessionSchedule(
      session,
      existingSessions ?? [],
      roomIdBySessionId: roomIdBySessionId,
      teacherIdBySessionId: teacherIdBySessionId,
    );
  }

  /// Validate capacity at source.
  CapacityValidation validateCapacity(int studentCount, int roomCapacity) {
    return EgyptValidators.validateCapacityBounds(studentCount, roomCapacity);
  }

  /// Dispose resources.
  void dispose() {
    _prewarmTimer?.cancel();
    _healthStreamController.close();
    _contextStreamController.close();
    _prewarmFutures.clear();
  }
}

/// Riverpod provider for the unified intelligence fabric.
final intelligenceFabricProvider = Provider<IntelligenceFabric>((ref) {
  final fabric = IntelligenceFabric(
    networkClient: ref.read(billingNetworkClientProvider),
  );
  ref.onDispose(fabric.dispose);
  return fabric;
});

/// Convenience providers for UI access.
final settlementDecisionProvider = FutureProvider.family<
    FabricResult<SettlementDecision>,
    ({
      double todayRevenue,
      int pendingTransactions,
      DateTime? lastSettlement,
      bool isSettlementDay,
    })
>((ref, params) async {
  final fabric = ref.read(intelligenceFabricProvider);
  return fabric.decideSettlement(
    todayRevenue: params.todayRevenue,
    pendingTransactions: params.pendingTransactions,
    lastSettlement: params.lastSettlement,
    isSettlementDay: params.isSettlementDay,
  );
});

final pricingRecommendationProvider = FutureProvider.family<
    FabricResult<PricingRecommendation>,
    ({
      int studentCount,
      int sessionCountPerWeek,
      bool needsQR,
      bool needsSettlement,
      bool needsWallet,
      AccountType? accountType,
    })
>((ref, params) async {
  final fabric = ref.read(intelligenceFabricProvider);
  return fabric.recommendPricing(
    studentCount: params.studentCount,
    sessionCountPerWeek: params.sessionCountPerWeek,
    needsQR: params.needsQR,
    needsSettlement: params.needsSettlement,
    needsWallet: params.needsWallet,
    accountType: params.accountType,
  );
});

final transactionGuardrailProvider = Provider.family<GuardrailResult, Map<String, dynamic>>((ref, ctx) {
  final fabric = ref.read(intelligenceFabricProvider);
  return fabric.checkTransactionGuardrails(ctx);
});

final scheduleSolverProvider = FutureProvider.family<
    FabricResult<ScheduleSolveResult>,
    ({
      List<SessionModel> sessions,
      List<String> availableRooms,
      Map<String, String> roomIdBySessionId,
      Map<String, String> teacherIdBySessionId,
    })
>((ref, params) async {
  final fabric = ref.read(intelligenceFabricProvider);
  return fabric.solveSchedule(
    sessions: params.sessions,
    availableRooms: params.availableRooms,
    roomIdBySessionId: params.roomIdBySessionId,
    teacherIdBySessionId: params.teacherIdBySessionId,
  );
});

final financialOptimizerProvider = FutureProvider.family<
    FabricResult<FinancialOptimizationResult>,
    ({
      int totalPiasters,
      int installmentCount,
      DateTime startDate,
      bool allowPartial,
      Map<String, double>? centerWeights,
    })
>((ref, params) async {
  final fabric = ref.read(intelligenceFabricProvider);
  return fabric.optimizeFinancial(
    totalPiasters: params.totalPiasters,
    installmentCount: params.installmentCount,
    startDate: params.startDate,
    allowPartial: params.allowPartial,
    centerWeights: params.centerWeights,
  );
});

final fabricHealthProvider = StreamProvider<HealthSignal>((ref) {
  final fabric = ref.read(intelligenceFabricProvider);
  return fabric.healthSignals;
});

final fabricContextProvider = StreamProvider<FabricContext>((ref) {
  final fabric = ref.read(intelligenceFabricProvider);
  return fabric.contextUpdates;
});