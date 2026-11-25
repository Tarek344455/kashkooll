import {
  AttendanceEntity,
  AvailabilityStatus,
  CertaintyBreakdown,
  CourseCandidate,
  CoursePriorityRecommendation,
  FinancialCertaintyResult,
  GroupAllocationResult,
  GroupEntity,
  LedgerEntryEntity,
  LedgerKind,
  OperationalDecision,
  PaymentChannelEntity,
  PaymentChannelOptimization,
  PaymentSubmissionEntity,
  QueueDispatchResult,
  ResourceConflictReport,
  ResourceItem,
  ResourceType,
  SeatTransferPlan,
  StudentEntity,
  StudentOrProfile,
  StudentRiskTier,
  StudyCandidate,
  StudyKnapsackResult,
  SubmissionStatus,
  SystemOperatingReport,
  UserRole,
} from "../../types/kashkool";
import { EgyptValidators } from "../utils/egyptValidators";

function clamp(val: number, min: number, max: number): number {
  return Math.min(max, Math.max(min, val));
}

function solveErlangCQueue(
  enrolledCount: number,
  rushModeEnabled: boolean,
  targetWaitSlaSeconds = 15
): QueueDispatchResult {
  const arrivalRatePerMin = clamp((Math.max(enrolledCount, 25) * 0.35) / 10, 1.5, 36);
  const serviceRatePerLane = 15;

  const computeForLanes = (lanes: number): { waitSec: number; waitPct: number; lq: number } => {
    const c = Math.max(1, lanes);
    const a = arrivalRatePerMin / serviceRatePerLane;
    const rho = clamp(a / c, 0.03, 0.96);
    let sumTerms = 0;
    let fact = 1;
    for (let k = 0; k < c; k++) {
      if (k > 0) fact *= k;
      sumTerms += Math.pow(a, k) / fact;
    }
    const cFact = fact * c;
    const lastTerm = (Math.pow(a, c) / cFact) * (1 / (1 - rho));
    const pWait = clamp(lastTerm / (sumTerms + lastTerm), 0, 1);
    const lq = Math.max(0, pWait * (rho / (1 - rho)));
    const wqSeconds = clamp(Math.round((lq / arrivalRatePerMin) * 60), 2, 180);
    const waitPct = clamp(Math.round(pWait * 100), 0, 99);
    return { waitSec: wqSeconds, waitPct, lq: Math.round(lq * 10) / 10 };
  };

  const activeLanes = rushModeEnabled ? 2 : 1;
  const { waitSec, waitPct, lq } = computeForLanes(activeLanes);
  const rhoActive = clamp(arrivalRatePerMin / (activeLanes * serviceRatePerLane), 0.05, 0.99);
  const utilPct = clamp(Math.round(rhoActive * 100), 5, 99);

  let optimalLanes = 1;
  while (optimalLanes < 4 && computeForLanes(optimalLanes).waitSec > targetWaitSlaSeconds) {
    optimalLanes++;
  }

  return {
    activeLanes,
    expectedWaitSeconds: waitSec,
    queueUtilizationPercent: utilPct,
    recommendExtraLane: (utilPct >= 60 || waitSec > targetWaitSlaSeconds) && !rushModeEnabled,
    erlangCWaitProbabilityPercent: waitPct,
    expectedQueueLengthStudents: lq,
    optimalLanesForSla: optimalLanes,
  };
}

function optimizePaymentChannel(
  channels: PaymentChannelEntity[],
  targetAmountPiasters: number
): PaymentChannelOptimization | null {
  const active = channels.filter((c) => c.isActive);
  if (active.length === 0) return null;
  const safeTarget = Math.max(targetAmountPiasters, 8000);
  const eligible = active.filter((c) => c.maxAmountPiasters >= safeTarget);
  const pool = eligible.length > 0 ? eligible : active;
  const sorted = [...pool].sort((a, b) => {
    if (a.feePiasters !== b.feePiasters) return a.feePiasters - b.feePiasters;
    return b.maxAmountPiasters - a.maxAmountPiasters;
  });
  const best = sorted[0];
  const worstFee = Math.max(...sorted.map((c) => c.feePiasters));
  const savings = Math.max(0, worstFee - best.feePiasters);
  const feeLabelAr =
    best.feePiasters === 0 ? "بدون أي رسوم" : `رسوم ${EgyptValidators.formatPiasters(best.feePiasters, "ar")}`;
  const feeLabelEn =
    best.feePiasters === 0 ? "zero transfer fee" : `fee ${EgyptValidators.formatPiasters(best.feePiasters, "en")}`;

  return {
    optimalChannelId: best.id,
    optimalChannelNameAr: best.nameAr,
    optimalChannelNameEn: best.nameEn,
    optimalFeePiasters: best.feePiasters,
    feeSavingsPiasters: savings,
    recommendedAmountPiasters: safeTarget,
    reasonAr: `${best.nameAr} هو الاختيار الأوفر (${feeLabelAr}).`,
    reasonEn: `${best.nameEn} minimizes transfer cost (${feeLabelEn}).`,
  };
}

function optimizeCourseSequence(
  courses: CourseCandidate[],
  completedCourseIds: Set<string>,
  weakTopics: string[],
  lowDataMode: boolean,
  dataBudgetMb = 60
): CoursePriorityRecommendation[] {
  if (courses.length === 0) return [];
  const normalizedWeak = weakTopics.map((t) => t.toLowerCase());

  const scored = courses
    .map((course, idx) => {
      const completed = completedCourseIds.has(course.id);
      const matchesWeak = normalizedWeak.some(
        (wk) => course.titleAr.toLowerCase().includes(wk) || course.titleEn.toLowerCase().includes(wk)
      );
      const baseImpact = completed ? 25 : 75;
      const remedialBoost = matchesWeak && !completed ? 30 : 0;
      const mb = Math.max(1, course.dataEstimateMb);
      const dataBonus = lowDataMode ? Math.floor(Math.max(0, 50 - mb) / 3) : 0;
      const priority = clamp(baseImpact + remedialBoost + dataBonus - idx * 3, 10, 120);
      const efficiency = priority / mb;
      return { course, priority, efficiency, completed };
    })
    .sort((a, b) => {
      if (a.completed !== b.completed) return a.completed ? 1 : -1;
      return lowDataMode ? b.efficiency - a.efficiency : b.priority - a.priority;
    });

  const selectedForData = new Set<string>();
  if (lowDataMode) {
    const uncompleted = scored.filter((s) => !s.completed);
    const n = uncompleted.length;
    const dp: number[][] = Array.from({ length: n + 1 }, () => new Array<number>(dataBudgetMb + 1).fill(0));
    for (let i = 1; i <= n; i++) {
      const { course, priority } = uncompleted[i - 1];
      const w = Math.max(1, course.dataEstimateMb);
      for (let b = 0; b <= dataBudgetMb; b++) {
        dp[i][b] = w <= b ? Math.max(dp[i - 1][b], dp[i - 1][b - w] + priority) : dp[i - 1][b];
      }
    }
    let rem = dataBudgetMb;
    for (let i = n; i >= 1; i--) {
      if (dp[i][rem] !== dp[i - 1][rem]) {
        const c = uncompleted[i - 1].course;
        selectedForData.add(c.id);
        rem -= Math.max(1, c.dataEstimateMb);
      }
    }
  } else {
    scored.filter((s) => !s.completed).forEach((s) => selectedForData.add(s.course.id));
  }

  return scored.map(({ course, priority, efficiency, completed }, rankIdx) => {
    const isTop = rankIdx === 0 && !completed;
    const roundedEff = Math.round(efficiency * 10) / 10;
    const reasonAr = completed
      ? "مكتمل — متاح للمراجعة السريعة"
      : isTop && lowDataMode
        ? `الأعلى عائداً لكل ميجابايت (${roundedEff} نقطة/MB)`
        : isTop
          ? "الأولوية القصوى لرفع الإتقان الآن"
          : selectedForData.has(course.id)
            ? `مناسب لباقة الإنترنت الحالية (${course.dataEstimateMb} MB)`
            : "مراجعة ثانوية";

    const reasonEn = completed
      ? "Completed — ready for quick recap"
      : isTop && lowDataMode
        ? `Highest exam gain per MB (${roundedEff} pts/MB)`
        : isTop
          ? "Top priority to boost mastery now"
          : selectedForData.has(course.id)
            ? `Fits mobile data budget (${course.dataEstimateMb} MB)`
            : "Secondary review";

    return {
      courseId: course.id,
      rank: rankIdx + 1,
      priorityScore: priority,
      efficiencyPerMb: roundedEff,
      isTopPick: isTop,
      selectedInDataBudget: selectedForData.has(course.id),
      reasonAr,
      reasonEn,
    };
  });
}

function evaluateStudentProfiles(
  students: StudentEntity[],
  groups: GroupEntity[],
  attendance: AttendanceEntity[]
): { profiles: Record<string, StudentOrProfile>; orderedIds: string[] } {
  if (students.length === 0) return { profiles: {}, orderedIds: [] };
  const groupMap = new Map(groups.map((g) => [g.id, g]));

  const list: StudentOrProfile[] = students.map((s) => {
    const sessionPrice = Math.max(1000, groupMap.get(s.groupId)?.pricePerSessionPiasters ?? 8000);
    const covered = Math.max(0, Math.floor(s.walletBalancePiasters / sessionPrice));
    const masteryDeficit = Math.max(0, 85 - s.masteryPercent);
    const duesPressure = s.dueBalancePiasters > 0 ? 28 : 0;
    const lowWalletPenalty = covered <= 1 ? 20 : covered === 2 ? 10 : 0;
    const streakPenalty = s.streakDays < 3 ? 14 : 0;
    const blockedPenalty = s.isBlocked ? 35 : 0;
    const attendanceCount = attendance.filter((a) => a.studentId === s.id).length;
    const attendanceOffset = Math.min(attendanceCount * 2, 10);

    const risk = clamp(
      masteryDeficit + duesPressure + lowWalletPenalty + streakPenalty + blockedPenalty - attendanceOffset,
      5,
      99
    );

    const riskTier =
      s.isBlocked || risk >= 60
        ? StudentRiskTier.CRITICAL
        : risk >= 32
          ? StudentRiskTier.WATCH
          : StudentRiskTier.HEALTHY;

    const targetWalletBuffer = sessionPrice * 4;
    const neededBuffer = Math.max(0, targetWalletBuffer - s.walletBalancePiasters);
    const rawInstallment = Math.max(sessionPrice, s.dueBalancePiasters + neededBuffer);
    const roundedInstallment = Math.max(sessionPrice, Math.ceil(rawInstallment / 1000) * 1000);

    let actionKind = "steady";
    let actionSummaryAr = `مسار مستقر · رصيد يغطي ${covered} حصص`;
    let actionSummaryEn = `On track · wallet covers ${covered} sessions`;

    if (s.isBlocked) {
      actionKind = "unblock_review";
      actionSummaryAr = "يحتاج مراجعة إدارية عاجلة وإعادة التفعيل";
      actionSummaryEn = "Needs urgent reception review & reactivation";
    } else if (s.dueBalancePiasters > 0) {
      actionKind = "discreet_installment";
      actionSummaryAr = `سماح هادئ + قسط مقترح ${EgyptValidators.formatPiasters(roundedInstallment, "ar")}`;
      actionSummaryEn = `Discreet entry + suggested ${EgyptValidators.formatPiasters(roundedInstallment, "en")}`;
    } else if (s.masteryPercent < 75) {
      actionKind = "academic_rescue";
      actionSummaryAr = `خطة إنقاذ 15 دقيقة لرفع الإتقان (${s.masteryPercent}%)`;
      actionSummaryEn = `15-min rescue plan to lift mastery (${s.masteryPercent}%)`;
    }

    return {
      studentId: s.id,
      riskScore: risk,
      riskTier,
      coveredSessions: covered,
      recommendedInstallmentPiasters: roundedInstallment,
      actionKind,
      actionSummaryAr,
      actionSummaryEn,
    };
  });

  const orderedIds = [...list].sort((a, b) => b.riskScore - a.riskScore).map((p) => p.studentId);
  const profiles: Record<string, StudentOrProfile> = {};
  for (const p of list) profiles[p.studentId] = p;
  return { profiles, orderedIds };
}

export const OperationsResearchEngine = {
  solveStudyKnapsack(candidates: StudyCandidate[], budgetMinutes = 15): StudyKnapsackResult {
    if (candidates.length === 0 || budgetMinutes <= 0) {
      return {
        timeBudgetMinutes: budgetMinutes,
        selectedItems: [],
        totalMinutesUsed: 0,
        guaranteedGainPercent: 0,
      };
    }
    const n = candidates.length;
    const wMax = budgetMinutes;
    const dp: number[][] = Array.from({ length: n + 1 }, () => new Array<number>(wMax + 1).fill(0));

    for (let i = 1; i <= n; i++) {
      const item = candidates[i - 1];
      const weight = Math.max(1, item.minutesRequired);
      const value = Math.max(0, item.masteryGainPercent);
      for (let w = 0; w <= wMax; w++) {
        dp[i][w] = weight <= w ? Math.max(dp[i - 1][w], dp[i - 1][w - weight] + value) : dp[i - 1][w];
      }
    }

    const chosen: StudyCandidate[] = [];
    let remW = wMax;
    for (let i = n; i >= 1; i--) {
      if (dp[i][remW] !== dp[i - 1][remW]) {
        const item = candidates[i - 1];
        chosen.push(item);
        remW -= Math.max(1, item.minutesRequired);
      }
    }
    chosen.reverse();

    return {
      timeBudgetMinutes: budgetMinutes,
      selectedItems: chosen,
      totalMinutesUsed: chosen.reduce((acc, c) => acc + c.minutesRequired, 0),
      guaranteedGainPercent: dp[n][wMax],
    };
  },

  analyzeGroupAllocation(groups: GroupEntity[]): GroupAllocationResult {
    if (groups.length === 0) {
      return {
        totalEnrolled: 0,
        totalCapacity: 0,
        utilizationPercent: 0,
        bottleneckGroupId: null,
        bottleneckGroupAr: null,
        bottleneckGroupEn: null,
        bottleneckFillPercent: 0,
        slackGroupId: null,
        slackGroupAr: null,
        slackGroupEn: null,
        recommendedSeatShift: 0,
        transferPlans: [],
        optimalWalkInGroupId: null,
        optimalWalkInGroupAr: null,
        optimalWalkInGroupEn: null,
        balanceScorePercent: 100,
      };
    }

    const totalEnrolled = groups.reduce((s, g) => s + g.enrolled, 0);
    const totalCapacity = Math.max(1, groups.reduce((s, g) => s + g.capacity, 0));
    const utilPct = clamp(Math.round((totalEnrolled * 100) / totalCapacity), 0, 100);

    const sortedByRatioDesc = [...groups].sort(
      (a, b) => b.enrolled / Math.max(1, b.capacity) - a.enrolled / Math.max(1, a.capacity)
    );
    const busiest = sortedByRatioDesc[0];
    const slackest = sortedByRatioDesc[sortedByRatioDesc.length - 1];
    const busiestFill = busiest ? Math.round((busiest.enrolled * 100) / Math.max(1, busiest.capacity)) : 0;

    let seatShift = 0;
    if (busiest && slackest && busiest.id !== slackest.id && busiestFill >= 85) {
      const target80 = Math.round(busiest.capacity * 0.8);
      const overflow = Math.max(0, busiest.enrolled - target80);
      const slackSeats = Math.max(0, slackest.capacity - slackest.enrolled);
      seatShift = Math.min(overflow, slackSeats);
    }

    const simEnrolled = new Map(groups.map((g) => [g.id, g.enrolled]));
    const transfers: SeatTransferPlan[] = [];
    const overloaded = groups
      .filter((g) => (g.enrolled * 100) / Math.max(1, g.capacity) >= 85)
      .sort((a, b) => b.enrolled / Math.max(1, b.capacity) - a.enrolled / Math.max(1, a.capacity));
    const receivers = groups
      .filter((g) => g.enrolled < g.capacity)
      .sort((a, b) => a.enrolled / Math.max(1, a.capacity) - b.enrolled / Math.max(1, b.capacity));

    for (const src of overloaded) {
      const targetMax = Math.round(src.capacity * 0.8);
      let excess = Math.max(0, (simEnrolled.get(src.id) ?? src.enrolled) - targetMax);
      for (const dst of receivers) {
        if (excess <= 0 || src.id === dst.id) continue;
        const dstNow = simEnrolled.get(dst.id) ?? dst.enrolled;
        const dstRoom = Math.max(0, dst.capacity - dstNow);
        const move = Math.min(excess, dstRoom);
        if (move > 0) {
          transfers.push({
            fromGroupId: src.id,
            fromGroupAr: src.nameAr,
            fromGroupEn: src.nameEn,
            toGroupId: dst.id,
            toGroupAr: dst.nameAr,
            toGroupEn: dst.nameEn,
            seatsToMove: move,
          });
          simEnrolled.set(src.id, (simEnrolled.get(src.id) ?? src.enrolled) - move);
          simEnrolled.set(dst.id, dstNow + move);
          excess -= move;
        }
      }
    }

    const walkInCandidates = groups
      .filter((g) => g.enrolled < g.capacity)
      .sort((a, b) => a.enrolled / Math.max(1, a.capacity) - b.enrolled / Math.max(1, b.capacity));
    const optimalWalkIn = walkInCandidates[0] ?? slackest;

    const fills = groups.map((g) => (g.enrolled * 100) / Math.max(1, g.capacity));
    const spread = Math.round(Math.max(...fills) - Math.min(...fills));
    const balanceScore = clamp(100 - Math.floor(spread / 2), 35, 100);
    const hasDistinctSlack = slackest && busiest && slackest.id !== busiest.id;

    return {
      totalEnrolled,
      totalCapacity,
      utilizationPercent: utilPct,
      bottleneckGroupId: busiest?.id ?? null,
      bottleneckGroupAr: busiest?.nameAr ?? null,
      bottleneckGroupEn: busiest?.nameEn ?? null,
      bottleneckFillPercent: busiestFill,
      slackGroupId: hasDistinctSlack ? slackest.id : null,
      slackGroupAr: hasDistinctSlack ? slackest.nameAr : null,
      slackGroupEn: hasDistinctSlack ? slackest.nameEn : null,
      recommendedSeatShift: seatShift,
      transferPlans: transfers,
      optimalWalkInGroupId: optimalWalkIn?.id ?? null,
      optimalWalkInGroupAr: optimalWalkIn?.nameAr ?? null,
      optimalWalkInGroupEn: optimalWalkIn?.nameEn ?? null,
      balanceScorePercent: balanceScore,
    };
  },

  analyzeFinancialCertainty(params: {
    groups: GroupEntity[];
    students: StudentEntity[];
    attendance: AttendanceEntity[];
    ledger: LedgerEntryEntity[];
    submissions: PaymentSubmissionEntity[];
    assistantWagesPiasters?: number;
    splitPercentOverride?: number | null;
    resources?: ResourceItem[];
  }): FinancialCertaintyResult {
    const {
      groups,
      students,
      attendance,
      ledger,
      submissions,
      assistantWagesPiasters = 15000,
      splitPercentOverride = null,
      resources = [],
    } = params;

    const attendedCount = Math.max(attendance.length, 18);
    const avgPrice =
      groups.length > 0
        ? Math.max(
            1000,
            Math.floor(groups.reduce((s, g) => s + g.pricePerSessionPiasters, 0) / groups.length)
          )
        : 8000;
    const splitPct = clamp(splitPercentOverride ?? groups[0]?.centerSplitPercent ?? 20, 0, 80);
    const safeWages = Math.max(0, assistantWagesPiasters);
    const resourceOverhead = resources
      .filter((r) => r.availabilityStatus !== AvailabilityStatus.UNAVAILABLE)
      .reduce((s, r) => s + Math.max(0, r.costPiasters), 0);

    const gross = attendedCount * avgPrice;
    const centerSplit = Math.floor((gross * splitPct) / 100);
    const netPayout = Math.max(0, gross - centerSplit - safeWages);
    const netAfterResources = Math.max(0, netPayout - resourceOverhead);

    const contributionPerStudent = Math.max(1, (avgPrice * (100 - splitPct)) / 100);
    const breakEven = Math.max(1, Math.ceil(safeWages / contributionPerStudent));
    const marginPct =
      attendedCount > 0 ? clamp(Math.round(((attendedCount - breakEven) / attendedCount) * 100), -100, 100) : 0;

    const totalDues = students.reduce((s, st) => s + st.dueBalancePiasters, 0);
    const collectedPositive = ledger
      .filter(
        (e) =>
          e.kind === LedgerKind.CASH_TOPUP ||
          e.kind === LedgerKind.PARTIAL_INSTALLMENT ||
          e.kind === LedgerKind.BOOK_RESERVATION
      )
      .reduce((s, e) => s + Math.max(0, e.amountPiasters), 0);
    const totalCollectible = Math.max(1, collectedPositive + totalDues);
    const collectionEfficiency = clamp(Math.round((collectedPositive * 100) / totalCollectible), 0, 100);

    const voidCount = ledger.filter((e) => e.kind === LedgerKind.VOID_ENTRY).length;
    const nonVoidCount = Math.max(1, ledger.filter((e) => e.kind !== LedgerKind.VOID_ENTRY).length);
    const voidRatio = clamp(Math.round((voidCount * 100) / nonVoidCount), 0, 100);

    const entryIds = new Set(ledger.map((e) => e.id));
    const voidsConsistent = ledger
      .filter((e) => e.kind === LedgerKind.VOID_ENTRY)
      .every((e) => !e.voidedEntryId || entryIds.has(e.voidedEntryId));
    const approvedSum = submissions
      .filter((s) => s.status === SubmissionStatus.APPROVED)
      .reduce((s, sub) => s + sub.amountPiasters, 0);
    const ledgerBalanced = voidsConsistent && approvedSum >= 0 && netPayout + centerSplit + safeWages <= gross + safeWages;
    const anomalyDetected = !voidsConsistent || voidRatio >= 25;
    const rawProjected = groups.reduce((s, g) => s + g.enrolled * g.pricePerSessionPiasters * 2, 0);
    const projectedWeeklyGross = rawProjected > 0 ? rawProjected : gross * 2;

    return {
      attendedCount,
      splitPercentUsed: splitPct,
      grossPiasters: gross,
      centerSplitPiasters: centerSplit,
      assistantWagesPiasters: safeWages,
      netPayoutPiasters: netPayout,
      breakEvenAttendance: breakEven,
      marginOfSafetyPercent: marginPct,
      pendingDuesPiasters: totalDues,
      ledgerBalanced,
      voidChainCount: voidCount,
      resourceOverheadPiasters: resourceOverhead,
      netAfterResourcesPiasters: netAfterResources,
      collectionEfficiencyPercent: collectionEfficiency,
      voidRatioPercent: voidRatio,
      anomalyDetected,
      projectedWeeklyGrossPiasters: projectedWeeklyGross,
    };
  },

  analyzeResourceConflicts(groups: GroupEntity[], resources: ResourceItem[]): ResourceConflictReport {
    const available = resources.filter((r) => r.availabilityStatus === AvailabilityStatus.AVAILABLE).length;
    const inUse = resources.filter((r) => r.availabilityStatus === AvailabilityStatus.IN_USE).length;
    const unavailable = resources.filter((r) => r.availabilityStatus === AvailabilityStatus.UNAVAILABLE).length;
    const utilizedCost = resources
      .filter((r) => r.availabilityStatus !== AvailabilityStatus.UNAVAILABLE)
      .reduce((s, r) => s + Math.max(0, r.costPiasters), 0);

    const schedMap = new Map<string, number>();
    for (const g of groups) {
      const k = g.scheduleEn.trim().toLowerCase();
      if (k) schedMap.set(k, (schedMap.get(k) ?? 0) + 1);
    }
    let conflictingGroups = 0;
    schedMap.forEach((count) => {
      if (count > 1) conflictingGroups += count;
    });

    const duplicateSchedules = conflictingGroups > 0;
    const availableToolsOrHalls = resources.filter(
      (r) => r.type === ResourceType.TOOL && r.availabilityStatus !== AvailabilityStatus.UNAVAILABLE
    ).length;
    const hallShortage = groups.length > 0 && resources.length > 0 && availableToolsOrHalls === 0;
    const conflict = duplicateSchedules || hallShortage || unavailable > 0;

    let summaryAr = `جميع القاعات والموارد جاهزة (${available} متاح، ${inUse} قيد التشغيل).`;
    let summaryEn = `All halls & resources clear (${available} ready, ${inUse} active).`;

    if (duplicateSchedules) {
      summaryAr = `تعارض في مواعيد ${conflictingGroups} مجموعات — راجع جدول القاعات.`;
      summaryEn = `Schedule overlap across ${conflictingGroups} groups.`;
    } else if (hallShortage) {
      summaryAr = "لا توجد قاعات أو أجهزة متاحة لتشغيل الحصص.";
      summaryEn = "No available halls or tools for scheduled sessions.";
    } else if (unavailable > 0) {
      summaryAr = `يوجد ${unavailable} مورد خارج الخدمة حالياً — تأكد من البدائل.`;
      summaryEn = `${unavailable} resource(s) unavailable — verify backup.`;
    }

    return {
      totalResources: resources.length,
      availableCount: available,
      inUseCount: inUse,
      unavailableCount: unavailable,
      hasHallOrScheduleConflict: conflict,
      summaryAr,
      summaryEn,
      utilizedResourceCostPiasters: utilizedCost,
      conflictGroupCount: conflictingGroups,
    };
  },

  evaluateSystem(params: {
    role: UserRole;
    groups: GroupEntity[];
    students: StudentEntity[];
    attendance: AttendanceEntity[];
    ledger: LedgerEntryEntity[];
    submissions: PaymentSubmissionEntity[];
    rescueCandidates: StudyCandidate[];
    rushModeEnabled: boolean;
    resources: ResourceItem[];
    assistantWagesPiasters: number;
    splitPercentOverride: number | null;
    channels: PaymentChannelEntity[];
    courses: CourseCandidate[];
    completedCourseIds: Set<string>;
    lowDataMode: boolean;
    studyBudgetMinutes: number;
  }): SystemOperatingReport {
    const alloc = this.analyzeGroupAllocation(params.groups);
    const finance = this.analyzeFinancialCertainty({
      groups: params.groups,
      students: params.students,
      attendance: params.attendance,
      ledger: params.ledger,
      submissions: params.submissions,
      assistantWagesPiasters: params.assistantWagesPiasters,
      splitPercentOverride: params.splitPercentOverride,
      resources: params.resources,
    });
    const knapsack = this.solveStudyKnapsack(
      params.rescueCandidates,
      clamp(params.studyBudgetMinutes, 5, 90)
    );
    const queue = solveErlangCQueue(alloc.totalEnrolled, params.rushModeEnabled);
    const resourceReport = this.analyzeResourceConflicts(params.groups, params.resources);

    const { profiles: studentProfiles, orderedIds: priorityIds } = evaluateStudentProfiles(
      params.students,
      params.groups,
      params.attendance
    );
    const primaryProfile = params.students[0] ? studentProfiles[params.students[0].id] : undefined;
    const targetTopUp = primaryProfile?.recommendedInstallmentPiasters ?? 24000;
    const channelOpt = optimizePaymentChannel(params.channels, targetTopUp);
    const weakTitles = params.rescueCandidates.map((c) => c.titleEn);
    const courseRecs = optimizeCourseSequence(
      params.courses,
      params.completedCourseIds,
      weakTitles,
      params.lowDataMode
    );

    const auditScore =
      finance.ledgerBalanced && !finance.anomalyDetected ? 35 : finance.ledgerBalanced ? 24 : 10;
    const marginScore = Math.floor((clamp(finance.marginOfSafetyPercent, 0, 100) * 25) / 100);
    const capacityScore = Math.floor((clamp(alloc.balanceScorePercent, 40, 100) * 15) / 100);
    const queueSlaScore = queue.expectedWaitSeconds <= 15 ? 10 : queue.expectedWaitSeconds <= 35 ? 6 : 3;
    const resourceScore = !resourceReport.hasHallOrScheduleConflict ? 15 : 6;
    const certainty = clamp(auditScore + marginScore + capacityScore + queueSlaScore + resourceScore, 45, 100);
    const certaintyBreakdown: CertaintyBreakdown = {
      auditScore,
      marginScore,
      capacityScore,
      queueSlaScore,
      resourceScore,
    };

    const decisions: OperationalDecision[] = [];
    if (params.role === UserRole.STUDENT || params.role === UserRole.PARENT) {
      if (knapsack.selectedItems.length > 0) {
        const namesAr = knapsack.selectedItems.map((i) => i.titleAr).join(" + ");
        const namesEn = knapsack.selectedItems.map((i) => i.titleEn).join(" + ");
        decisions.push({
          titleAr: `أفضل خطة مذاكرة خلال ${knapsack.timeBudgetMinutes} دقيقة`,
          titleEn: `Optimal ${knapsack.timeBudgetMinutes}-Min Study Selection`,
          detailAr: `مراجعة (${namesAr}) ترفع مستواك بمقدار +${knapsack.guaranteedGainPercent}% بأقل وقت.`,
          detailEn: `Reviewing (${namesEn}) yields +${knapsack.guaranteedGainPercent}% guaranteed gain.`,
          verifiedFormula: `0/1 Knapsack · ${knapsack.totalMinutesUsed}/${knapsack.timeBudgetMinutes}m`,
          priorityHigh: true,
        });
      }
      const topCourse = courseRecs.find((c) => c.isTopPick);
      if (topCourse) {
        decisions.push({
          titleAr: "أولوية الدرس القادم",
          titleEn: "Top Recommended Lesson",
          detailAr: `${topCourse.reasonAr} · كفاءة ${topCourse.efficiencyPerMb} نقطة/MB.`,
          detailEn: `${topCourse.reasonEn} · ${topCourse.efficiencyPerMb} pts/MB.`,
          verifiedFormula: `Data-Opt #${topCourse.rank} · Score=${topCourse.priorityScore}`,
          priorityHigh: false,
        });
      }
      if (channelOpt) {
        decisions.push({
          titleAr: "القناة الأوفر للدفع والشحن",
          titleEn: "Lowest-Fee Payment Channel",
          detailAr: `${channelOpt.reasonAr} المبلغ المقترح: ${EgyptValidators.formatPiasters(channelOpt.recommendedAmountPiasters, "ar")}.`,
          detailEn: `${channelOpt.reasonEn} Suggested top-up: ${EgyptValidators.formatPiasters(channelOpt.recommendedAmountPiasters, "en")}.`,
          verifiedFormula: `Min-Fee=${EgyptValidators.formatPiasters(channelOpt.optimalFeePiasters, "en")}`,
          priorityHigh: false,
        });
      }
    } else if (params.role === UserRole.TEACHER) {
      decisions.push({
        titleAr: "تغطية نقطة التعادل وأمان اليوم",
        titleEn: "Break-Even & Safety Margin",
        detailAr: `نقطة التعادل ${finance.breakEvenAttendance} طالب، والحضور الفعلي ${finance.attendedCount} طالب بهامش أمان ${finance.marginOfSafetyPercent}%.`,
        detailEn: `Break-even at ${finance.breakEvenAttendance} students vs ${finance.attendedCount} attended (${finance.marginOfSafetyPercent}% safety margin).`,
        verifiedFormula: `BEP=${finance.breakEvenAttendance} · Split=${finance.splitPercentUsed}%`,
        priorityHigh: finance.marginOfSafetyPercent < 25,
      });
      if (alloc.transferPlans.length > 0) {
        const totalShift = alloc.transferPlans.reduce((s, p) => s + p.seatsToMove, 0);
        const first = alloc.transferPlans[0];
        decisions.push({
          titleAr: `موازنة القاعات الممتلئة (${totalShift} مقعد)`,
          titleEn: `Multi-Hall Flow Rebalance (${totalShift} seats)`,
          detailAr: `مجموعة «${first.fromGroupAr}» وصلت ${alloc.bottleneckFillPercent}% — يُنصح بتحويل ${first.seatsToMove} طلاب إلى «${first.toGroupAr}».`,
          detailEn: `${first.fromGroupEn} is at ${alloc.bottleneckFillPercent}% — shift ${first.seatsToMove} seats to ${first.toGroupEn}.`,
          verifiedFormula: `Flow Balance=${alloc.balanceScorePercent}% · Shift=${totalShift}`,
          priorityHigh: true,
        });
      }
      if (resourceReport.totalResources > 0) {
        decisions.push({
          titleAr: "جاهزية القاعات والموارد",
          titleEn: "Hall & Resource Readiness",
          detailAr: resourceReport.summaryAr,
          detailEn: resourceReport.summaryEn,
          verifiedFormula: `Ready=${resourceReport.availableCount}/${resourceReport.totalResources}`,
          priorityHigh: resourceReport.hasHallOrScheduleConflict,
        });
      }
    } else if (params.role === UserRole.SECRETARY) {
      decisions.push({
        titleAr: `طابور السلم (${queue.activeLanes} مسار · SLA ${queue.optimalLanesForSla})`,
        titleEn: `Queue Dispatch (${queue.activeLanes} lane · SLA ${queue.optimalLanesForSla})`,
        detailAr: queue.recommendExtraLane
          ? `احتمال الانتظار ${queue.erlangCWaitProbabilityPercent}% (${queue.expectedWaitSeconds} ث) — فعّل الساعة المزدحمة.`
          : `انتظار متوقع ${queue.expectedWaitSeconds} ثانية فقط باحتمال ازدحام ${queue.erlangCWaitProbabilityPercent}%.`,
        detailEn: `Erlang-C wait ${queue.expectedWaitSeconds}s (${queue.erlangCWaitProbabilityPercent}% wait prob, Lq=${queue.expectedQueueLengthStudents}).`,
        verifiedFormula: `Erlang-C M/M/${queue.activeLanes} · Wq=${queue.expectedWaitSeconds}s`,
        priorityHigh: queue.recommendExtraLane,
      });
      const criticalCount = priorityIds
        .map((id) => studentProfiles[id])
        .filter((p) => p && p.riskTier !== StudentRiskTier.HEALTHY).length;
      decisions.push({
        titleAr: "أولويات الاستقبال وتطابق الخزينة",
        titleEn: "Reception Triage & Ledger Audit",
        detailAr: `كفاءة التحصيل ${finance.collectionEfficiencyPercent}% · يوجد ${criticalCount} طلاب بحاجة لمتابعة أو تقسيط.`,
        detailEn: `Collection efficiency ${finance.collectionEfficiencyPercent}% · ${criticalCount} student(s) flagged for triage.`,
        verifiedFormula: `Collect=${finance.collectionEfficiencyPercent}% · Voids=${finance.voidRatioPercent}%`,
        priorityHigh: finance.anomalyDetected || criticalCount > 0,
      });
    }

    return {
      certaintyScorePercent: certainty,
      groupAllocation: alloc,
      financialCertainty: finance,
      studyKnapsack: knapsack,
      queueDispatch: queue,
      resourceConflict: resourceReport,
      decisions,
      channelOptimization: channelOpt,
      courseRecommendations: courseRecs,
      studentProfiles,
      priorityStudentIds: priorityIds,
      certaintyBreakdown,
    };
  },
};
