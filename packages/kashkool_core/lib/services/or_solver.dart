/// Sub-Problem Specialization: OR Constraint Solver & Financial Optimizer.
///
/// Right engine for the right problem (DUAL-LAYER directive Part A item 2):
///   1. ScheduleSolver — combinatorial scheduling / hard constraints
///      (class/group timetables, room/hall capacities, teacher availability,
///       conflict-free student slots). Constraint-satisfaction / discrete
///       scheduling logic with conflict diagnostics.
///   2. FinancialOptimizer — allocation, batching & financial settlement
///      optimization (installment plans, multi-center revenue splits,
///      resource reservation distribution). Deterministic linear/integer
///      optimization and exact ledger arithmetic in piasters (int).
///
/// All money uses piasters (int minor units) — no floating-point drift.

library or_solver;

import '../models/session_model.dart';
import '../models/pricing_model.dart';
import '../utils/egypt_validators.dart';

// ============================================================================
// SCHEDULE SOLVER — Combinatorial / Hard Constraints
// ============================================================================

/// A solved timetable slot.
class SolvedSlot {
  final String sessionId;
  final String roomId;
  final String teacherId;
  final DateTime startTime;
  final DateTime endTime;
  final List<String> studentIds;

  const SolvedSlot({
    required this.sessionId,
    required this.roomId,
    required this.teacherId,
    required this.startTime,
    required this.endTime,
    required this.studentIds,
  });
}

/// Result of schedule solving.
class ScheduleSolveResult {
  final bool feasible;
  final List<SolvedSlot> slots;
  final List<SessionConflict> conflicts; // unsolvable conflicts with diagnostics
  final int iterations;
  final double solveTimeMs;

  const ScheduleSolveResult({
    required this.feasible,
    required this.slots,
    required this.conflicts,
    required this.iterations,
    required this.solveTimeMs,
  });

  /// Human-readable diagnosis when infeasible.
  String get diagnostic {
    if (feasible) return 'الجدولة قابلة للتنفيذ — ${slots.length} جلسة مجدولة';
    return 'الجدولة غير قابلة للتنفيذ — ${conflicts.length} تعارض:\n'
        '${conflicts.map((c) => c.message).join('\n')}';
  }
}

/// Constraint-satisfaction scheduler for sessions.
class ScheduleSolver {
  const ScheduleSolver();

  /// Solve sessions into conflict-free slots.
  ///
  /// [sessions] — sessions to schedule (must have startTime; roomId/teacherId
  /// resolved via [roomIdBySessionId] / [teacherIdBySessionId]).
  /// [availableRooms] — pool of room IDs.
  /// [maxIterations] — safety cap for the search loop.
  ScheduleSolveResult solve({
    required List<SessionModel> sessions,
    required List<String> availableRooms,
    required Map<String, String> roomIdBySessionId,
    required Map<String, String> teacherIdBySessionId,
    int maxIterations = 10000,
  }) {
    final stopwatch = Stopwatch()..start();
    final slots = <SolvedSlot>[];
    final conflicts = <SessionConflict>[];
    var iterations = 0;

    // Sort sessions by start time for deterministic greedy assignment.
    final ordered = List<SessionModel>.from(sessions)
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    // Track occupancy per room and per teacher: (id, start, end) -> busy.
    final roomBusy = <String, List<_TimeWindow>>{};
    final teacherBusy = <String, List<_TimeWindow>>{};

    for (final session in ordered) {
      iterations++;
      if (iterations > maxIterations) {
        conflicts.add(SessionConflict(
          type: ConflictType.invalidDuration,
          message: 'تم بلوغ الحد الأقصى للتكرارات ($maxIterations) دون إنهاء الجدولة',
          sourceField: 'iterations',
          conflictingEntity: session.sessionId,
        ));
        break;
      }

      final newStart = session.startTime;
      final newEnd = session.startTime.add(const Duration(hours: 2));
      final room = roomIdBySessionId[session.sessionId] ?? '';
      final teacher = teacherIdBySessionId[session.sessionId] ?? '';

      // Check room conflict
      final roomConflicts = _windowConflicts(roomBusy[room] ?? [], newStart, newEnd);
      // Check teacher conflict
      final teacherConflicts = _windowConflicts(teacherBusy[teacher] ?? [], newStart, newEnd);

      if (roomConflicts.isNotEmpty || teacherConflicts.isNotEmpty) {
        // Try to find an alternative room if room conflict
        String? alternativeRoom;
        if (roomConflicts.isNotEmpty && availableRooms.isNotEmpty) {
          for (final candidate in availableRooms) {
            if (candidate == room) continue;
            final candidateBusy = roomBusy[candidate] ?? [];
            if (_windowConflicts(candidateBusy, newStart, newEnd).isEmpty) {
              alternativeRoom = candidate;
              break;
            }
          }
        }

        if (alternativeRoom != null) {
          // Re-assign to alternative room
          slots.add(SolvedSlot(
            sessionId: session.sessionId,
            roomId: alternativeRoom,
            teacherId: teacher,
            startTime: newStart,
            endTime: newEnd,
            studentIds: session.studentIds,
          ));
          (roomBusy[alternativeRoom] ??= []).add(_TimeWindow(newStart, newEnd));
          (teacherBusy[teacher] ??= []).add(_TimeWindow(newStart, newEnd));
        } else {
          // Unsolvable — record conflict with exact diagnostics
          final msgs = <String>[];
          if (roomConflicts.isNotEmpty) {
            msgs.add('القاعة $room تشغِّل جلسة أخرى في نفس الوقت');
          }
          if (teacherConflicts.isNotEmpty) {
            msgs.add('المعلم $teacher يُدرس جلسة أخرى في نفس الوقت');
          }
          conflicts.add(SessionConflict(
            type: teacherConflicts.isNotEmpty
                ? ConflictType.teacherOverlap
                : ConflictType.roomOverlap,
            message: 'جلسة ${session.sessionId} غير قابلة للجدولة: ${msgs.join(' و ')} '
                '(${_fmt(newStart)}-${_fmt(newEnd)})',
            sourceField: 'schedule',
            conflictingEntity: session.sessionId,
          ));
        }
      } else {
        // No conflict — assign
        slots.add(SolvedSlot(
          sessionId: session.sessionId,
          roomId: room,
          teacherId: teacher,
          startTime: newStart,
          endTime: newEnd,
          studentIds: session.studentIds,
        ));
        (roomBusy[room] ??= []).add(_TimeWindow(newStart, newEnd));
        (teacherBusy[teacher] ??= []).add(_TimeWindow(newStart, newEnd));
      }
    }

    stopwatch.stop();
    return ScheduleSolveResult(
      feasible: conflicts.isEmpty,
      slots: slots,
      conflicts: conflicts,
      iterations: iterations,
      solveTimeMs: stopwatch.elapsedMilliseconds.toDouble(),
    );
  }

  /// Warm-start relaxation: when a session is unsolvable, try alternative
  /// time slots or rooms before declaring infeasible. Returns the relaxed
  /// solution and the constraint that forced the fallback.
  ScheduleSolveResult relaxConstraints({
    required List<SessionModel> sessions,
    required List<String> availableRooms,
    required Map<String, String> roomIdBySessionId,
    required Map<String, String> teacherIdBySessionId,
    required SessionConflict conflict,
  }) {
    final conflictingSession = sessions.firstWhere(
      (s) => s.sessionId == conflict.conflictingEntity,
      orElse: () => sessions.first,
    );

    final newStart = conflictingSession.startTime;
    final newEnd = conflictingSession.startTime.add(const Duration(hours: 2));
    final room = roomIdBySessionId[conflictingSession.sessionId] ?? '';
    final teacher = teacherIdBySessionId[conflictingSession.sessionId] ?? '';

    final slots = <SolvedSlot>[];
    final relaxations = <String>[];

    // Try shifting time ±1 hour
    for (final offset in [-1, 1]) {
      final shiftedStart = newStart.add(Duration(hours: offset));
      final shiftedEnd = shiftedStart.add(const Duration(hours: 2));
      final roomConflicts = _windowConflicts(
        roomBusyFromSessions(sessions, room, roomIdBySessionId) ?? [],
        shiftedStart,
        shiftedEnd,
      );
      final teacherConflicts = _windowConflicts(
        teacherBusyFromSessions(sessions, teacher, teacherIdBySessionId) ?? [],
        shiftedStart,
        shiftedEnd,
      );
      if (roomConflicts.isEmpty && teacherConflicts.isEmpty) {
        relaxations.add('نُقلت الجلسة ${conflictingSession.sessionId} من ${_fmt(newStart)} إلى ${_fmt(shiftedStart)}');
        slots.add(SolvedSlot(
          sessionId: conflictingSession.sessionId,
          roomId: room,
          teacherId: teacher,
          startTime: shiftedStart,
          endTime: shiftedEnd,
          studentIds: conflictingSession.studentIds,
        ));
        return ScheduleSolveResult(
          feasible: true,
          slots: slots,
          conflicts: [],
          iterations: 1,
          solveTimeMs: 0,
        );
      }
    }

    // Try alternative room at same time
    for (final candidate in availableRooms) {
      if (candidate == room) continue;
      final candidateBusy = roomBusyFromSessions(sessions, candidate, roomIdBySessionId) ?? [];
      if (_windowConflicts(candidateBusy, newStart, newEnd).isEmpty) {
        relaxations.add('نُقلت الجلسة ${conflictingSession.sessionId} من القاعة $room إلى القاعة $candidate');
        slots.add(SolvedSlot(
          sessionId: conflictingSession.sessionId,
          roomId: candidate,
          teacherId: teacher,
          startTime: newStart,
          endTime: newEnd,
          studentIds: conflictingSession.studentIds,
        ));
        return ScheduleSolveResult(
          feasible: true,
          slots: slots,
          conflicts: [],
          iterations: 1,
          solveTimeMs: 0,
        );
      }
    }

    // Cannot relax — return the original conflict
    return ScheduleSolveResult(
      feasible: false,
      slots: [],
      conflicts: [conflict],
      iterations: 1,
      solveTimeMs: 0,
    );
  }

  List<_TimeWindow>? roomBusyFromSessions(List<SessionModel> allSessions, String roomId, Map<String, String> roomMap) {
    final windows = <_TimeWindow>[];
    for (final s in allSessions) {
      if (roomMap[s.sessionId] == roomId) {
        windows.add(_TimeWindow(s.startTime, s.startTime.add(const Duration(hours: 2))));
      }
    }
    return windows.isEmpty ? null : windows;
  }

  List<_TimeWindow>? teacherBusyFromSessions(List<SessionModel> allSessions, String teacherId, Map<String, String> teacherMap) {
    final windows = <_TimeWindow>[];
    for (final s in allSessions) {
      if (teacherMap[s.sessionId] == teacherId) {
        windows.add(_TimeWindow(s.startTime, s.startTime.add(const Duration(hours: 2))));
      }
    }
    return windows.isEmpty ? null : windows;
  }

  List<_TimeWindow> _windowConflicts(
    List<_TimeWindow> windows,
    DateTime start,
    DateTime end,
  ) {
    return windows.where((w) => start.isBefore(w.end) && end.isAfter(w.start)).toList();
  }

  String _fmt(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

class _TimeWindow {
  final DateTime start;
  final DateTime end;
  _TimeWindow(this.start, this.end);
}

// ============================================================================
// FINANCIAL OPTIMIZER — Deterministic Ledger Arithmetic
// ============================================================================

/// An installment plan item.
class InstallmentItem {
  final int duePiasters;
  final DateTime dueDate;
  final bool paid;

  const InstallmentItem({
    required this.duePiasters,
    required this.dueDate,
    this.paid = false,
  });
}

/// Result of financial optimization.
class FinancialOptimizationResult {
  final bool feasible;
  final int totalPiasters;
  final int remainingPiasters;
  final List<InstallmentItem> installments;
  final Map<String, int> revenueSplitPiasters; // centerId -> piasters
  final List<String> warnings;

  const FinancialOptimizationResult({
    required this.feasible,
    required this.totalPiasters,
    required this.remainingPiasters,
    required this.installments,
    required this.revenueSplitPiasters,
    required this.warnings,
  });

  int get paidPiasters =>
      installments.where((i) => i.paid).fold(0, (sum, i) => sum + i.duePiasters);

  int get unpaidPiasters => totalPiasters - paidPiasters;

  String get totalEgp => EgyptValidators.formatPiasters(totalPiasters);
  String get remainingEgp => EgyptValidators.formatPiasters(remainingPiasters);
}

/// Optimizer for financial allocation & settlement.
class FinancialOptimizer {
  const FinancialOptimizer();

  /// Create an installment plan from a total amount.
  FinancialOptimizationResult planInstallments({
    required int totalPiasters,
    required int installmentCount,
    required DateTime startDate,
    required bool allowPartial,
  }) {
    final warnings = <String>[];
    final installments = <InstallmentItem>[];

    final moneyCheck = EgyptValidators.validatePiasters(totalPiasters);
    if (!moneyCheck.isValid) {
      return FinancialOptimizationResult(
        feasible: false,
        totalPiasters: 0,
        remainingPiasters: 0,
        installments: [],
        revenueSplitPiasters: {},
        warnings: [moneyCheck.message!],
      );
    }

    if (installmentCount <= 0) {
      return FinancialOptimizationResult(
        feasible: false,
        totalPiasters: totalPiasters,
        remainingPiasters: totalPiasters,
        installments: [],
        revenueSplitPiasters: {},
        warnings: ['عدد الأقساط يجب أن يكون أكبر من صفر'],
      );
    }

    final base = totalPiasters ~/ installmentCount;
    final remainder = totalPiasters % installmentCount;

    var dueDate = startDate;
    for (var i = 0; i < installmentCount; i++) {
      final amount = base + (i < remainder ? 1 : 0);
      installments.add(InstallmentItem(
        duePiasters: amount,
        dueDate: dueDate,
        paid: false,
      ));
      dueDate = dueDate.add(const Duration(days: 30));
    }

    if (allowPartial && remainder > 0) {
      warnings.add('باقٍ من القسمة: $remainder قرش أُضيف إلى الأقساط الأولى');
    }

    return FinancialOptimizationResult(
      feasible: true,
      totalPiasters: totalPiasters,
      remainingPiasters: totalPiasters,
      installments: installments,
      revenueSplitPiasters: {},
      warnings: warnings,
    );
  }

  /// Split revenue across centers deterministically (exact piasters, no drift).
  Map<String, int> splitRevenue({
    required int totalPiasters,
    required Map<String, double> centerWeights, // centerId -> weight (0-1)
  }) {
    final result = <String, int>{};
    if (totalPiasters <= 0) {
      for (final id in centerWeights.keys) {
        result[id] = 0;
      }
      return result;
    }

    final weightSum = centerWeights.values.fold(0.0, (sum, w) => sum + w);
    if (weightSum <= 0) {
      final equal = totalPiasters ~/ centerWeights.length;
      for (final id in centerWeights.keys) {
        result[id] = equal;
      }
      return result;
    }

    var remaining = totalPiasters;
    final sortedIds = centerWeights.keys.toList()..sort();
    for (var i = 0; i < sortedIds.length; i++) {
      final id = sortedIds[i];
      final weight = centerWeights[id]!;
      final isLast = i == sortedIds.length - 1;
      if (isLast) {
        // Give remainder to last center to avoid drift
        result[id] = remaining;
      } else {
        final share = (totalPiasters * weight / weightSum).round();
        result[id] = share;
        remaining -= share;
      }
    }

    return result;
  }

  /// Validate a ledger transaction for financial hygiene (pre-mutation).
  MoneyValidation validateTransaction(int amountPiasters, String channel) {
    final money = EgyptValidators.validatePiasters(amountPiasters);
    if (!money.isValid) return money;

    // Channel-specific sanity checks
    final validChannels = {'cashToWallet', 'fawry', 'vodafoneCash', 'instaPay', 'settlement'};
    if (!validChannels.contains(channel)) {
      return MoneyValidation.invalid(
        'قناة دفع غير معروفة: $channel',
        sourceField: 'channel',
        sourceValue: channel,
      );
    }

    return MoneyValidation.ok();
  }
}

/// Unified OR Solver — combines ScheduleSolver + FinancialOptimizer
/// with additional optimization methods for the Intelligence Fabric.
class ORSolver {
  final ScheduleSolver _scheduleSolver = ScheduleSolver();
  final FinancialOptimizer _financialOptimizer = FinancialOptimizer();

  /// Optimize settlement decision using mathematical analysis.
  FinancialOptimizationResult optimizeSettlement({
    required double todayRevenue,
    required int pendingTransactions,
    required DateTime? lastSettlement,
    required bool isSettlementDay,
  }) {
    final totalPiasters = (todayRevenue * 100).round();
    final warnings = <String>[];

    // Mathematical feasibility check
    if (totalPiasters <= 0 && pendingTransactions == 0) {
      return FinancialOptimizationResult(
        feasible: false,
        totalPiasters: 0,
        remainingPiasters: 0,
        installments: [],
        revenueSplitPiasters: {},
        warnings: ['لا توجد إيرادات ولا معاملات معلقة للتسوية'],
      );
    }

    // Time since last settlement
    if (lastSettlement != null) {
      final hoursSince = DateTime.now().difference(lastSettlement).inHours;
      if (hoursSince < 12) {
        warnings.add('آخر تسوية كانت منذ $hoursSince ساعة فقط');
      }
    }

    // Settlement day bonus confidence
    if (isSettlementDay) {
      warnings.add('نافذة التسوية الرسمية نشطة (22:00-23:00)');
    }

    // Pending transactions analysis
    if (pendingTransactions > 50) {
      warnings.add('عدد معاملات معلقة مرتفع: $pendingTransactions — يُنصح بالتسوية الفورية');
    }

    return FinancialOptimizationResult(
      feasible: true,
      totalPiasters: totalPiasters,
      remainingPiasters: totalPiasters,
      installments: [],
      revenueSplitPiasters: {},
      warnings: warnings,
    );
  }

  /// Optimize pricing recommendation using mathematical modeling.
  FinancialOptimizationResult optimizePricing({
    required int studentCount,
    required int sessionCountPerWeek,
    required bool needsQR,
    required bool needsSettlement,
    required bool needsWallet,
    required AccountType accountType,
  }) {
    final recommendedModules = <String>[];
    var estimatedMonthlyCostPiasters = 0;
    final warnings = <String>[];

    // Core is always free
    recommendedModules.add('teacherCore');

    // Module pricing in piasters (exact, no drift)
    const modulePrices = {
      'teacherSettlementAuto': 5000,    // 50 EGP
      'teacherWalletPayout': 3000,      // 30 EGP
      'teacherStudentInsights': 3000,   // 30 EGP
      'teacherMultiCenter': 2000,       // 20 EGP
      'teacherContentDrm': 4000,        // 40 EGP
      'teacherWhiteLabelParentApp': 6000, // 60 EGP
    };

    if (needsSettlement) {
      recommendedModules.add('teacherSettlementAuto');
      estimatedMonthlyCostPiasters += modulePrices['teacherSettlementAuto']!;
    }

    if (needsWallet) {
      recommendedModules.add('teacherWalletPayout');
      estimatedMonthlyCostPiasters += modulePrices['teacherWalletPayout']!;
    }

    if (studentCount > 30) {
      recommendedModules.add('teacherStudentInsights');
      estimatedMonthlyCostPiasters += modulePrices['teacherStudentInsights']!;
      warnings.add('قاعدة طلاب كبيرة ($studentCount) — تحليلات الطلاب موصى بها');
    }

    if (sessionCountPerWeek > 20) {
      recommendedModules.add('teacherMultiCenter');
      estimatedMonthlyCostPiasters += modulePrices['teacherMultiCenter']!;
      warnings.add('حجم عمليات كبير ($sessionCountPerWeek حصة/أسبوع) — متعدد المراكز موصى به');
    }

    // Center-specific modules
    if (accountType == AccountType.center) {
      if (needsSettlement) {
        recommendedModules.add('centerSettlementEngine');
        estimatedMonthlyCostPiasters += 8000; // 80 EGP
      }
      if (studentCount > 100) {
        recommendedModules.add('centerStudentEngagement');
        estimatedMonthlyCostPiasters += 5000; // 50 EGP
      }
      if (sessionCountPerWeek > 50) {
        recommendedModules.add('centerMultiBranch');
        estimatedMonthlyCostPiasters += 10000; // 100 EGP
      }
    }

    const bundledCostPiasters = 25000; // 250 EGP hypothetical bundle
    final savingsPiasters = bundledCostPiasters - estimatedMonthlyCostPiasters;
    // savingsPiasters used for validation: if negative, bundle is cheaper
    if (savingsPiasters < 0) {
      warnings.add('الحزمة المجمعة أرخص بـ ${(-savingsPiasters / 100).toStringAsFixed(0)} ج.م');
    }

    return FinancialOptimizationResult(
      feasible: true,
      totalPiasters: estimatedMonthlyCostPiasters,
      remainingPiasters: estimatedMonthlyCostPiasters,
      installments: [],
      revenueSplitPiasters: {},
      warnings: warnings,
    );
  }

  // Delegate to ScheduleSolver
  ScheduleSolveResult solve({
    required List<SessionModel> sessions,
    required List<String> availableRooms,
    required Map<String, String> roomIdBySessionId,
    required Map<String, String> teacherIdBySessionId,
    int maxIterations = 10000,
  }) {
    return _scheduleSolver.solve(
      sessions: sessions,
      availableRooms: availableRooms,
      roomIdBySessionId: roomIdBySessionId,
      teacherIdBySessionId: teacherIdBySessionId,
      maxIterations: maxIterations,
    );
  }

  ScheduleSolveResult relaxConstraints({
    required List<SessionModel> sessions,
    required List<String> availableRooms,
    required Map<String, String> roomIdBySessionId,
    required Map<String, String> teacherIdBySessionId,
    required SessionConflict conflict,
  }) {
    return _scheduleSolver.relaxConstraints(
      sessions: sessions,
      availableRooms: availableRooms,
      roomIdBySessionId: roomIdBySessionId,
      teacherIdBySessionId: teacherIdBySessionId,
      conflict: conflict,
    );
  }

  // Delegate to FinancialOptimizer
  FinancialOptimizationResult planInstallments({
    required int totalPiasters,
    required int installmentCount,
    required DateTime startDate,
    required bool allowPartial,
  }) {
    return _financialOptimizer.planInstallments(
      totalPiasters: totalPiasters,
      installmentCount: installmentCount,
      startDate: startDate,
      allowPartial: allowPartial,
    );
  }

  Map<String, int> splitRevenue({
    required int totalPiasters,
    required Map<String, double> centerWeights,
  }) {
    return _financialOptimizer.splitRevenue(
      totalPiasters: totalPiasters,
      centerWeights: centerWeights,
    );
  }

  MoneyValidation validateTransaction(int amountPiasters, String channel) {
    return _financialOptimizer.validateTransaction(amountPiasters, channel);
  }
}
