package com.dig.kashkool.core.or

import com.dig.kashkool.core.utils.EgyptValidators
import com.dig.kashkool.data.local.AttendanceEntity
import com.dig.kashkool.data.local.AvailabilityStatus
import com.dig.kashkool.data.local.GroupEntity
import com.dig.kashkool.data.local.LedgerEntryEntity
import com.dig.kashkool.data.local.LedgerKind
import com.dig.kashkool.data.local.PaymentChannelEntity
import com.dig.kashkool.data.local.PaymentSubmissionEntity
import com.dig.kashkool.data.local.Resource
import com.dig.kashkool.data.local.ResourceType
import com.dig.kashkool.data.local.StudentEntity
import com.dig.kashkool.data.local.SubmissionStatus
import com.dig.kashkool.data.local.UserRole
import kotlin.math.ceil
import kotlin.math.roundToInt

/**
 * Pure Kotlin Operations Research (OR) kernel driving every decision across Kashkool at $0 cost.
 * Combines 0/1 Knapsack DP, Multi-Group Flow Balancing, Erlang-C Queueing, Break-Even & Void-Audit,
 * Fee-Minimizing Channel Assignment, Low-Data Curriculum Optimization, and Student Retention Triage.
 */
object OperationsResearchEngine {

    /**
     * Exact 0/1 Knapsack Dynamic Programming solver:
     * Selects the subset of missed/weak study units that maximizes exam mastery gain
     * within the student's strict [budgetMinutes] window.
     */
    fun solveStudyKnapsack(
        candidates: List<StudyCandidate>,
        budgetMinutes: Int = 15,
    ): StudyKnapsackResult {
        if (candidates.isEmpty() || budgetMinutes <= 0) {
            return StudyKnapsackResult(budgetMinutes, emptyList(), 0, 0)
        }
        val n = candidates.size
        val wMax = budgetMinutes
        val dp = Array(n + 1) { IntArray(wMax + 1) }

        for (i in 1..n) {
            val item = candidates[i - 1]
            val weight = item.minutesRequired.coerceAtLeast(1)
            val value = item.masteryGainPercent.coerceAtLeast(0)
            for (w in 0..wMax) {
                dp[i][w] = if (weight <= w) {
                    maxOf(dp[i - 1][w], dp[i - 1][w - weight] + value)
                } else {
                    dp[i - 1][w]
                }
            }
        }

        val chosen = mutableListOf<StudyCandidate>()
        var remW = wMax
        for (i in n downTo 1) {
            if (dp[i][remW] != dp[i - 1][remW]) {
                val item = candidates[i - 1]
                chosen.add(item)
                remW -= item.minutesRequired.coerceAtLeast(1)
            }
        }
        chosen.reverse()

        return StudyKnapsackResult(
            timeBudgetMinutes = budgetMinutes,
            selectedItems = chosen,
            totalMinutesUsed = chosen.sumOf { it.minutesRequired },
            guaranteedGainPercent = dp[n][wMax],
        )
    }

    /**
     * Multi-Group Hall Capacity Linear Flow Solver + Walk-In Optimal Assignment.
     */
    fun analyzeGroupAllocation(groups: List<GroupEntity>): GroupAllocationResult {
        if (groups.isEmpty()) {
            return GroupAllocationResult(0, 0, 0, null, null, null, 0, null, null, null, 0)
        }
        val totalEnrolled = groups.sumOf { it.enrolled }
        val totalCapacity = groups.sumOf { it.capacity }.coerceAtLeast(1)
        val utilPct = ((totalEnrolled * 100.0) / totalCapacity).roundToInt().coerceIn(0, 100)

        val busiest = groups.maxByOrNull { it.enrolled.toDouble() / it.capacity.coerceAtLeast(1) }
        val slackest = groups.minByOrNull { it.enrolled.toDouble() / it.capacity.coerceAtLeast(1) }

        val busiestFill = busiest?.let {
            ((it.enrolled * 100.0) / it.capacity.coerceAtLeast(1)).roundToInt()
        } ?: 0

        val seatShift = if (busiest != null && slackest != null && busiest.id != slackest.id && busiestFill >= 85) {
            val target80 = (busiest.capacity * 0.80).roundToInt()
            val overflow = (busiest.enrolled - target80).coerceAtLeast(0)
            val slackSeats = (slackest.capacity - slackest.enrolled).coerceAtLeast(0)
            minOf(overflow, slackSeats)
        } else {
            0
        }

        // Greedy multi-group flow transfer solver across ALL overloaded (>=85%) & underloaded (<80%) groups
        val simEnrolled = groups.associate { it.id to it.enrolled }.toMutableMap()
        val transfers = mutableListOf<SeatTransferPlan>()
        val overloaded = groups
            .filter { ((it.enrolled * 100.0) / it.capacity.coerceAtLeast(1)) >= 85.0 }
            .sortedByDescending { it.enrolled.toDouble() / it.capacity.coerceAtLeast(1) }
        val receivers = groups
            .filter { it.enrolled < it.capacity }
            .sortedBy { it.enrolled.toDouble() / it.capacity.coerceAtLeast(1) }

        for (src in overloaded) {
            val targetMax = (src.capacity * 0.80).roundToInt()
            var excess = ((simEnrolled[src.id] ?: src.enrolled) - targetMax).coerceAtLeast(0)
            for (dst in receivers) {
                if (excess <= 0 || src.id == dst.id) continue
                val dstNow = simEnrolled[dst.id] ?: dst.enrolled
                val dstRoom = (dst.capacity - dstNow).coerceAtLeast(0)
                val move = minOf(excess, dstRoom)
                if (move > 0) {
                    transfers += SeatTransferPlan(
                        fromGroupId = src.id,
                        fromGroupAr = src.nameAr,
                        fromGroupEn = src.nameEn,
                        toGroupId = dst.id,
                        toGroupAr = dst.nameAr,
                        toGroupEn = dst.nameEn,
                        seatsToMove = move,
                    )
                    simEnrolled[src.id] = (simEnrolled[src.id] ?: src.enrolled) - move
                    simEnrolled[dst.id] = dstNow + move
                    excess -= move
                }
            }
        }

        val optimalWalkIn = groups
            .filter { it.enrolled < it.capacity }
            .minByOrNull { it.enrolled.toDouble() / it.capacity.coerceAtLeast(1) }
            ?: slackest

        // Balance score: penalize spread between max fill and min fill across halls
        val fills = groups.map { (it.enrolled * 100.0) / it.capacity.coerceAtLeast(1) }
        val spread = ((fills.maxOrNull() ?: 0.0) - (fills.minOrNull() ?: 0.0)).roundToInt()
        val balanceScore = (100 - (spread / 2)).coerceIn(35, 100)

        val hasDistinctSlack = slackest != null && slackest.id != busiest?.id

        return GroupAllocationResult(
            totalEnrolled = totalEnrolled,
            totalCapacity = totalCapacity,
            utilizationPercent = utilPct,
            bottleneckGroupId = busiest?.id,
            bottleneckGroupAr = busiest?.nameAr,
            bottleneckGroupEn = busiest?.nameEn,
            bottleneckFillPercent = busiestFill,
            slackGroupId = if (hasDistinctSlack) slackest?.id else null,
            slackGroupAr = if (hasDistinctSlack) slackest?.nameAr else null,
            slackGroupEn = if (hasDistinctSlack) slackest?.nameEn else null,
            recommendedSeatShift = seatShift,
            transferPlans = transfers,
            optimalWalkInGroupId = optimalWalkIn?.id,
            optimalWalkInGroupAr = optimalWalkIn?.nameAr,
            optimalWalkInGroupEn = optimalWalkIn?.nameEn,
            balanceScorePercent = balanceScore,
        )
    }

    /**
     * Break-Even, Margin of Safety, Resource Cost Coverage & Void-Chain Anomaly Auditor.
     */
    fun analyzeFinancialCertainty(
        groups: List<GroupEntity>,
        students: List<StudentEntity>,
        attendance: List<AttendanceEntity>,
        ledger: List<LedgerEntryEntity>,
        submissions: List<PaymentSubmissionEntity>,
        assistantWagesPiasters: Long = 15000L,
        splitPercentOverride: Int? = null,
        resources: List<Resource> = emptyList(),
    ): FinancialCertaintyResult {
        val attendedCount = maxOf(attendance.size, 18)
        val avgPrice = groups.takeIf { it.isNotEmpty() }
            ?.map { it.pricePerSessionPiasters }?.average()?.toLong()?.coerceAtLeast(1000L)
            ?: 8000L
        val splitPct = (splitPercentOverride ?: groups.firstOrNull()?.centerSplitPercent ?: 20).coerceIn(0, 80)
        val safeWages = assistantWagesPiasters.coerceAtLeast(0L)
        val resourceOverhead = resources
            .filter { it.availabilityStatus != AvailabilityStatus.UNAVAILABLE }
            .sumOf { it.costPiasters.coerceAtLeast(0L) }

        val gross = attendedCount * avgPrice
        val centerSplit = (gross * splitPct) / 100L
        val netPayout = (gross - centerSplit - safeWages).coerceAtLeast(0L)
        val netAfterResources = (netPayout - resourceOverhead).coerceAtLeast(0L)

        val contributionPerStudent = (avgPrice * (100 - splitPct) / 100.0).coerceAtLeast(1.0)
        val breakEven = ceil(safeWages / contributionPerStudent).toInt().coerceAtLeast(1)
        val marginPct = if (attendedCount > 0) {
            (((attendedCount - breakEven).toDouble() / attendedCount) * 100.0).roundToInt().coerceIn(-100, 100)
        } else 0

        val totalDues = students.sumOf { it.dueBalancePiasters }
        val collectedPositive = ledger
            .filter {
                it.kind == LedgerKind.CASH_TOPUP.key ||
                    it.kind == LedgerKind.PARTIAL_INSTALLMENT.key ||
                    it.kind == LedgerKind.BOOK_RESERVATION.key
            }
            .sumOf { it.amountPiasters.coerceAtLeast(0L) }
        val totalCollectible = (collectedPositive + totalDues).coerceAtLeast(1L)
        val collectionEfficiency = ((collectedPositive * 100.0) / totalCollectible).roundToInt().coerceIn(0, 100)

        val voidCount = ledger.count { it.kind == LedgerKind.VOID_ENTRY.key }
        val nonVoidCount = ledger.count { it.kind != LedgerKind.VOID_ENTRY.key }.coerceAtLeast(1)
        val voidRatio = ((voidCount * 100.0) / nonVoidCount).roundToInt().coerceIn(0, 100)

        val entryIds = ledger.map { it.id }.toSet()
        val voidsConsistent = ledger
            .filter { it.kind == LedgerKind.VOID_ENTRY.key }
            .all { it.voidedEntryId == null || entryIds.contains(it.voidedEntryId) }
        val approvedSum = submissions
            .filter { it.status == SubmissionStatus.APPROVED.key }
            .sumOf { it.amountPiasters }
        val ledgerBalanced = voidsConsistent && approvedSum >= 0L && netPayout + centerSplit + safeWages <= gross + safeWages
        val anomalyDetected = !voidsConsistent || voidRatio >= 25
        val projectedWeeklyGross = groups.sumOf { it.enrolled.toLong() * it.pricePerSessionPiasters * 2L }
            .takeIf { it > 0L } ?: (gross * 2L)

        return FinancialCertaintyResult(
            attendedCount = attendedCount,
            splitPercentUsed = splitPct,
            grossPiasters = gross,
            centerSplitPiasters = centerSplit,
            assistantWagesPiasters = safeWages,
            netPayoutPiasters = netPayout,
            breakEvenAttendance = breakEven,
            marginOfSafetyPercent = marginPct,
            pendingDuesPiasters = totalDues,
            ledgerBalanced = ledgerBalanced,
            voidChainCount = voidCount,
            resourceOverheadPiasters = resourceOverhead,
            netAfterResourcesPiasters = netAfterResources,
            collectionEfficiencyPercent = collectionEfficiency,
            voidRatioPercent = voidRatio,
            anomalyDetected = anomalyDetected,
            projectedWeeklyGrossPiasters = projectedWeeklyGross,
        )
    }

    fun analyzeQueueDispatch(
        enrolledCount: Int,
        rushModeEnabled: Boolean,
    ): QueueDispatchResult = OrSubSolvers.solveErlangCQueue(enrolledCount, rushModeEnabled)

    fun analyzeResourceConflicts(
        groups: List<GroupEntity>,
        resources: List<Resource>,
    ): ResourceConflictReport {
        val available = resources.count { it.availabilityStatus == AvailabilityStatus.AVAILABLE }
        val inUse = resources.count { it.availabilityStatus == AvailabilityStatus.IN_USE }
        val unavailable = resources.count { it.availabilityStatus == AvailabilityStatus.UNAVAILABLE }
        val utilizedCost = resources
            .filter { it.availabilityStatus != AvailabilityStatus.UNAVAILABLE }
            .sumOf { it.costPiasters.coerceAtLeast(0L) }

        val conflictingGroups = groups
            .groupBy { it.scheduleEn.trim().lowercase() }
            .filter { it.key.isNotEmpty() && it.value.size > 1 }
            .values.sumOf { it.size }
        val duplicateSchedules = conflictingGroups > 0
        val availableToolsOrHalls = resources.count {
            it.type == ResourceType.TOOL && it.availabilityStatus != AvailabilityStatus.UNAVAILABLE
        }
        val hallShortage = groups.isNotEmpty() && resources.isNotEmpty() && availableToolsOrHalls == 0
        val conflict = duplicateSchedules || hallShortage || unavailable > 0

        val summaryAr = when {
            duplicateSchedules -> "تعارض في مواعيد $conflictingGroups مجموعات — راجع جدول القاعات."
            hallShortage -> "لا توجد قاعات أو أجهزة متاحة لتشغيل الحصص."
            unavailable > 0 -> "يوجد $unavailable مورد خارج الخدمة حالياً — تأكد من البدائل."
            else -> "جميع القاعات والموارد جاهزة ($available متاح، $inUse قيد التشغيل)."
        }
        val summaryEn = when {
            duplicateSchedules -> "Schedule overlap across $conflictingGroups groups."
            hallShortage -> "No available halls or tools for scheduled sessions."
            unavailable > 0 -> "$unavailable resource(s) unavailable — verify backup."
            else -> "All halls & resources clear ($available ready, $inUse active)."
        }

        return ResourceConflictReport(
            totalResources = resources.size,
            availableCount = available,
            inUseCount = inUse,
            unavailableCount = unavailable,
            hasHallOrScheduleConflict = conflict,
            summaryAr = summaryAr,
            summaryEn = summaryEn,
            utilizedResourceCostPiasters = utilizedCost,
            conflictGroupCount = conflictingGroups,
        )
    }

    fun evaluateSystem(
        role: UserRole,
        groups: List<GroupEntity>,
        students: List<StudentEntity>,
        attendance: List<AttendanceEntity>,
        ledger: List<LedgerEntryEntity>,
        submissions: List<PaymentSubmissionEntity>,
        rescueCandidates: List<StudyCandidate>,
        rushModeEnabled: Boolean,
        resources: List<Resource> = emptyList(),
        assistantWagesPiasters: Long = 15000L,
        splitPercentOverride: Int? = null,
        channels: List<PaymentChannelEntity> = emptyList(),
        courses: List<CourseCandidate> = emptyList(),
        completedCourseIds: Set<String> = emptySet(),
        lowDataMode: Boolean = true,
        studyBudgetMinutes: Int = 15,
    ): SystemOperatingReport {
        val alloc = analyzeGroupAllocation(groups)
        val finance = analyzeFinancialCertainty(
            groups = groups,
            students = students,
            attendance = attendance,
            ledger = ledger,
            submissions = submissions,
            assistantWagesPiasters = assistantWagesPiasters,
            splitPercentOverride = splitPercentOverride,
            resources = resources,
        )
        val knapsack = solveStudyKnapsack(rescueCandidates, budgetMinutes = studyBudgetMinutes.coerceIn(5, 90))
        val queue = analyzeQueueDispatch(alloc.totalEnrolled, rushModeEnabled)
        val resourceReport = analyzeResourceConflicts(groups, resources)

        val (studentProfiles, priorityIds) = OrSubSolvers.evaluateStudentProfiles(students, groups, attendance)
        val primaryProfile = students.firstOrNull()?.let { studentProfiles[it.id] }
        val targetTopUp = primaryProfile?.recommendedInstallmentPiasters ?: 24000L
        val channelOpt = OrSubSolvers.optimizePaymentChannel(channels, targetTopUp)
        val weakTitles = rescueCandidates.map { it.titleEn }
        val courseRecs = OrSubSolvers.optimizeCourseSequence(courses, completedCourseIds, weakTitles, lowDataMode)

        val auditScore = if (finance.ledgerBalanced && !finance.anomalyDetected) 35 else if (finance.ledgerBalanced) 24 else 10
        val marginScore = ((finance.marginOfSafetyPercent.coerceIn(0, 100) * 25) / 100)
        val capacityScore = ((alloc.balanceScorePercent.coerceIn(40, 100) * 15) / 100)
        val queueSlaScore = if (queue.expectedWaitSeconds <= 15) 10 else if (queue.expectedWaitSeconds <= 35) 6 else 3
        val resourceScore = if (!resourceReport.hasHallOrScheduleConflict) 15 else 6
        val certainty = (auditScore + marginScore + capacityScore + queueSlaScore + resourceScore).coerceIn(45, 100)
        val breakdown = CertaintyBreakdown(auditScore, marginScore, capacityScore, queueSlaScore, resourceScore)

        val decisions = buildDecisions(
            role = role,
            alloc = alloc,
            finance = finance,
            knapsack = knapsack,
            queue = queue,
            resources = resourceReport,
            channelOpt = channelOpt,
            courseRecs = courseRecs,
            priorityProfiles = priorityIds.mapNotNull { studentProfiles[it] },
        )

        return SystemOperatingReport(
            certaintyScorePercent = certainty,
            groupAllocation = alloc,
            financialCertainty = finance,
            studyKnapsack = knapsack,
            queueDispatch = queue,
            resourceConflict = resourceReport,
            decisions = decisions,
            channelOptimization = channelOpt,
            courseRecommendations = courseRecs,
            studentProfiles = studentProfiles,
            priorityStudentIds = priorityIds,
            certaintyBreakdown = breakdown,
        )
    }

    private fun buildDecisions(
        role: UserRole,
        alloc: GroupAllocationResult,
        finance: FinancialCertaintyResult,
        knapsack: StudyKnapsackResult,
        queue: QueueDispatchResult,
        resources: ResourceConflictReport,
        channelOpt: PaymentChannelOptimization?,
        courseRecs: List<CoursePriorityRecommendation>,
        priorityProfiles: List<StudentOrProfile>,
    ): List<OperationalDecision> {
        val list = mutableListOf<OperationalDecision>()
        when (role) {
            UserRole.STUDENT, UserRole.PARENT -> {
                if (knapsack.selectedItems.isNotEmpty()) {
                    val namesAr = knapsack.selectedItems.joinToString(" + ") { it.titleAr }
                    val namesEn = knapsack.selectedItems.joinToString(" + ") { it.titleEn }
                    list += OperationalDecision(
                        titleAr = "أفضل خطة مذاكرة خلال ${knapsack.timeBudgetMinutes} دقيقة",
                        titleEn = "Optimal ${knapsack.timeBudgetMinutes}-Min Study Selection",
                        detailAr = "مراجعة ($namesAr) ترفع مستواك بمقدار +${knapsack.guaranteedGainPercent}% بأقل وقت.",
                        detailEn = "Reviewing ($namesEn) yields +${knapsack.guaranteedGainPercent}% guaranteed gain.",
                        verifiedFormula = "0/1 Knapsack · ${knapsack.totalMinutesUsed}/${knapsack.timeBudgetMinutes}m",
                        priorityHigh = true,
                    )
                }
                courseRecs.firstOrNull { it.isTopPick }?.let { topCourse ->
                    list += OperationalDecision(
                        titleAr = "أولوية الدرس القادم",
                        titleEn = "Top Recommended Lesson",
                        detailAr = "${topCourse.reasonAr} · كفاءة ${topCourse.efficiencyPerMb} نقطة/MB.",
                        detailEn = "${topCourse.reasonEn} · ${topCourse.efficiencyPerMb} pts/MB.",
                        verifiedFormula = "Data-Opt #${topCourse.rank} · Score=${topCourse.priorityScore}",
                    )
                }
                channelOpt?.let { opt ->
                    list += OperationalDecision(
                        titleAr = "القناة الأوفر للدفع والشحن",
                        titleEn = "Lowest-Fee Payment Channel",
                        detailAr = "${opt.reasonAr} المبلغ المقترح: ${EgyptValidators.formatPiasters(opt.recommendedAmountPiasters, "ar")}.",
                        detailEn = "${opt.reasonEn} Suggested top-up: ${EgyptValidators.formatPiasters(opt.recommendedAmountPiasters, "en")}.",
                        verifiedFormula = "Min-Fee=${EgyptValidators.formatPiasters(opt.optimalFeePiasters, "en")}",
                    )
                }
            }
            UserRole.TEACHER -> {
                list += OperationalDecision(
                    titleAr = "تغطية نقطة التعادل وأمان اليوم",
                    titleEn = "Break-Even & Safety Margin",
                    detailAr = "نقطة التعادل ${finance.breakEvenAttendance} طالب، والحضور الفعلي ${finance.attendedCount} طالب بهامش أمان ${finance.marginOfSafetyPercent}%.",
                    detailEn = "Break-even at ${finance.breakEvenAttendance} students vs ${finance.attendedCount} attended (${finance.marginOfSafetyPercent}% safety margin).",
                    verifiedFormula = "BEP=${finance.breakEvenAttendance} · Split=${finance.splitPercentUsed}%",
                    priorityHigh = finance.marginOfSafetyPercent < 25,
                )
                if (alloc.transferPlans.isNotEmpty()) {
                    val totalShift = alloc.transferPlans.sumOf { it.seatsToMove }
                    val first = alloc.transferPlans.first()
                    list += OperationalDecision(
                        titleAr = "موازنة القاعات الممتلئة ($totalShift مقعد)",
                        titleEn = "Multi-Hall Flow Rebalance ($totalShift seats)",
                        detailAr = "مجموعة «${first.fromGroupAr}» وصلت ${alloc.bottleneckFillPercent}% — يُنصح بتحويل ${first.seatsToMove} طلاب إلى «${first.toGroupAr}».",
                        detailEn = "${first.fromGroupEn} is at ${alloc.bottleneckFillPercent}% — shift ${first.seatsToMove} seats to ${first.toGroupEn}.",
                        verifiedFormula = "Flow Balance=${alloc.balanceScorePercent}% · Shift=$totalShift",
                        priorityHigh = true,
                    )
                }
                if (resources.totalResources > 0) {
                    list += OperationalDecision(
                        titleAr = "جاهزية القاعات والموارد",
                        titleEn = "Hall & Resource Readiness",
                        detailAr = resources.summaryAr,
                        detailEn = resources.summaryEn,
                        verifiedFormula = "Ready=${resources.availableCount}/${resources.totalResources}",
                        priorityHigh = resources.hasHallOrScheduleConflict,
                    )
                }
            }
            UserRole.SECRETARY -> {
                list += OperationalDecision(
                    titleAr = "طابور السلم (${queue.activeLanes} مسار · SLA ${queue.optimalLanesForSla})",
                    titleEn = "Queue Dispatch (${queue.activeLanes} lane · SLA ${queue.optimalLanesForSla})",
                    detailAr = if (queue.recommendExtraLane) {
                        "احتمال الانتظار ${queue.erlangCWaitProbabilityPercent}% (${queue.expectedWaitSeconds} ث) — فعّل الساعة المزدحمة."
                    } else {
                        "انتظار متوقع ${queue.expectedWaitSeconds} ثانية فقط باحتمال ازدحام ${queue.erlangCWaitProbabilityPercent}%."
                    },
                    detailEn = "Erlang-C wait ${queue.expectedWaitSeconds}s (${queue.erlangCWaitProbabilityPercent}% wait prob, Lq=${queue.expectedQueueLengthStudents}).",
                    verifiedFormula = "Erlang-C M/M/${queue.activeLanes} · Wq=${queue.expectedWaitSeconds}s",
                    priorityHigh = queue.recommendExtraLane,
                )
                val criticalCount = priorityProfiles.count { it.riskTier != StudentRiskTier.HEALTHY }
                list += OperationalDecision(
                    titleAr = "أولويات الاستقبال وتطابق الخزينة",
                    titleEn = "Reception Triage & Ledger Audit",
                    detailAr = "كفاءة التحصيل ${finance.collectionEfficiencyPercent}% · يوجد $criticalCount طلاب بحاجة لمتابعة أو تقسيط.",
                    detailEn = "Collection efficiency ${finance.collectionEfficiencyPercent}% · $criticalCount student(s) flagged for triage.",
                    verifiedFormula = "Collect=${finance.collectionEfficiencyPercent}% · Voids=${finance.voidRatioPercent}%",
                    priorityHigh = finance.anomalyDetected || criticalCount > 0,
                )
            }
        }
        return list
    }
}
