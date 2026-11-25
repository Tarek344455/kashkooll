package com.dig.kashkool.core.or

import com.dig.kashkool.core.utils.EgyptValidators
import com.dig.kashkool.data.local.AttendanceEntity
import com.dig.kashkool.data.local.GroupEntity
import com.dig.kashkool.data.local.PaymentChannelEntity
import com.dig.kashkool.data.local.StudentEntity
import kotlin.math.ceil
import kotlin.math.pow
import kotlin.math.roundToInt

internal object OrSubSolvers {

    /**
     * Exact Erlang-C (M/M/c) queueing probability, queue length, and SLA lane optimizer.
     */
    fun solveErlangCQueue(
        enrolledCount: Int,
        rushModeEnabled: Boolean,
        targetWaitSlaSeconds: Int = 15,
    ): QueueDispatchResult {
        val arrivalRatePerMin = ((enrolledCount.coerceAtLeast(25) * 0.35) / 10.0).coerceIn(1.5, 36.0)
        val serviceRatePerLane = 15.0 // 4s average QR tap-in per lane

        fun computeForLanes(lanes: Int): Triple<Int, Int, Double> {
            val c = lanes.coerceAtLeast(1)
            val a = arrivalRatePerMin / serviceRatePerLane
            val rho = (a / c).coerceIn(0.03, 0.96)
            var sumTerms = 0.0
            var fact = 1.0
            for (k in 0 until c) {
                if (k > 0) fact *= k.toDouble()
                sumTerms += a.pow(k.toDouble()) / fact
            }
            val cFact = fact * c.toDouble()
            val lastTerm = (a.pow(c.toDouble()) / cFact) * (1.0 / (1.0 - rho))
            val pWait = (lastTerm / (sumTerms + lastTerm)).coerceIn(0.0, 1.0)
            val lq = (pWait * (rho / (1.0 - rho))).coerceAtLeast(0.0)
            val wqSeconds = ((lq / arrivalRatePerMin) * 60.0).roundToInt().coerceIn(2, 180)
            val waitPct = (pWait * 100.0).roundToInt().coerceIn(0, 99)
            return Triple(wqSeconds, waitPct, (lq * 10.0).roundToInt() / 10.0)
        }

        val activeLanes = if (rushModeEnabled) 2 else 1
        val (waitSec, waitProbPct, expectedLq) = computeForLanes(activeLanes)
        val rhoActive = (arrivalRatePerMin / (activeLanes * serviceRatePerLane)).coerceIn(0.05, 0.99)
        val utilPct = (rhoActive * 100.0).roundToInt().coerceIn(5, 99)

        var optimalLanes = 1
        while (optimalLanes < 4 && computeForLanes(optimalLanes).first > targetWaitSlaSeconds) {
            optimalLanes++
        }

        return QueueDispatchResult(
            activeLanes = activeLanes,
            expectedWaitSeconds = waitSec,
            queueUtilizationPercent = utilPct,
            recommendExtraLane = (utilPct >= 60 || waitSec > targetWaitSlaSeconds) && !rushModeEnabled,
            erlangCWaitProbabilityPercent = waitProbPct,
            expectedQueueLengthStudents = expectedLq,
            optimalLanesForSla = optimalLanes,
        )
    }

    /**
     * Fee-Minimizing Payment Channel Assignment Solver:
     * Picks the lowest-fee active channel capable of carrying [targetAmountPiasters].
     */
    fun optimizePaymentChannel(
        channels: List<PaymentChannelEntity>,
        targetAmountPiasters: Long,
    ): PaymentChannelOptimization? {
        val active = channels.filter { it.isActive }
        if (active.isEmpty()) return null
        val safeTarget = targetAmountPiasters.coerceAtLeast(8000L)
        val eligible = active.filter { it.maxAmountPiasters >= safeTarget }.ifEmpty { active }
        val sorted = eligible.sortedWith(compareBy<PaymentChannelEntity> { it.feePiasters }.thenByDescending { it.maxAmountPiasters })
        val best = sorted.first()
        val worstFee = sorted.maxOf { it.feePiasters }
        val savings = (worstFee - best.feePiasters).coerceAtLeast(0L)
        val feeLabelAr = if (best.feePiasters == 0L) "بدون أي رسوم" else "رسوم ${EgyptValidators.formatPiasters(best.feePiasters, "ar")}"
        val feeLabelEn = if (best.feePiasters == 0L) "zero transfer fee" else "fee ${EgyptValidators.formatPiasters(best.feePiasters, "en")}"

        return PaymentChannelOptimization(
            optimalChannelId = best.id,
            optimalChannelNameAr = best.nameAr,
            optimalChannelNameEn = best.nameEn,
            optimalFeePiasters = best.feePiasters,
            feeSavingsPiasters = savings,
            recommendedAmountPiasters = safeTarget,
            reasonAr = "${best.nameAr} هو الاختيار الأوفر ($feeLabelAr).",
            reasonEn = "${best.nameEn} minimizes transfer cost ($feeLabelEn).",
        )
    }

    /**
     * Bi-Criteria Curriculum & Mobile-Data Knapsack Optimizer:
     * Ranks lessons by exam impact per MB and selects the optimal pack within [dataBudgetMb].
     */
    fun optimizeCourseSequence(
        courses: List<CourseCandidate>,
        completedCourseIds: Set<String>,
        weakTopics: List<String>,
        lowDataMode: Boolean,
        dataBudgetMb: Int = 60,
    ): List<CoursePriorityRecommendation> {
        if (courses.isEmpty()) return emptyList()
        val normalizedWeak = weakTopics.map { it.lowercase() }

        val scored = courses.mapIndexed { idx, course ->
            val completed = completedCourseIds.contains(course.id)
            val matchesWeak = normalizedWeak.any { wk ->
                course.titleAr.lowercase().contains(wk) || course.titleEn.lowercase().contains(wk)
            }
            val baseImpact = if (completed) 25 else 75
            val remedialBoost = if (matchesWeak && !completed) 30 else 0
            val mb = course.dataEstimateMb.coerceAtLeast(1)
            val dataBonus = if (lowDataMode) ((50 - mb).coerceAtLeast(0) / 3) else 0
            val priority = (baseImpact + remedialBoost + dataBonus - (idx * 3)).coerceIn(10, 120)
            val efficiency = (priority.toDouble() / mb)
            Triple(course, priority, efficiency)
        }.sortedWith(
            compareByDescending<Triple<CourseCandidate, Int, Double>> { !completedCourseIds.contains(it.first.id) }
                .thenByDescending { if (lowDataMode) it.third else it.second.toDouble() }
        )

        // Exact 0/1 Knapsack for mobile data budget when lowDataMode is enabled
        val selectedForData = mutableSetOf<String>()
        if (lowDataMode) {
            val uncompleted = scored.filter { !completedCourseIds.contains(it.first.id) }
            val n = uncompleted.size
            val dp = Array(n + 1) { IntArray(dataBudgetMb + 1) }
            for (i in 1..n) {
                val (course, priority, _) = uncompleted[i - 1]
                val w = course.dataEstimateMb.coerceAtLeast(1)
                for (b in 0..dataBudgetMb) {
                    dp[i][b] = if (w <= b) maxOf(dp[i - 1][b], dp[i - 1][b - w] + priority) else dp[i - 1][b]
                }
            }
            var rem = dataBudgetMb
            for (i in n downTo 1) {
                if (dp[i][rem] != dp[i - 1][rem]) {
                    val c = uncompleted[i - 1].first
                    selectedForData.add(c.id)
                    rem -= c.dataEstimateMb.coerceAtLeast(1)
                }
            }
        } else {
            scored.filter { !completedCourseIds.contains(it.first.id) }.forEach { selectedForData.add(it.first.id) }
        }

        return scored.mapIndexed { rankIdx, (course, priority, efficiency) ->
            val completed = completedCourseIds.contains(course.id)
            val isTop = rankIdx == 0 && !completed
            val roundedEff = (efficiency * 10.0).roundToInt() / 10.0
            val reasonAr = when {
                completed -> "مكتمل — متاح للمراجعة السريعة"
                isTop && lowDataMode -> "الأعلى عائداً لكل ميجابايت ($roundedEff نقطة/MB)"
                isTop -> "الأولوية القصوى لرفع الإتقان الآن"
                selectedForData.contains(course.id) -> "مناسب لباقة الإنترنت الحالية (${course.dataEstimateMb} MB)"
                else -> "مراجعة ثانوية"
            }
            val reasonEn = when {
                completed -> "Completed — ready for quick recap"
                isTop && lowDataMode -> "Highest exam gain per MB ($roundedEff pts/MB)"
                isTop -> "Top priority to boost mastery now"
                selectedForData.contains(course.id) -> "Fits mobile data budget (${course.dataEstimateMb} MB)"
                else -> "Secondary review"
            }
            CoursePriorityRecommendation(
                courseId = course.id,
                rank = rankIdx + 1,
                priorityScore = priority,
                efficiencyPerMb = roundedEff,
                isTopPick = isTop,
                selectedInDataBudget = selectedForData.contains(course.id),
                reasonAr = reasonAr,
                reasonEn = reasonEn,
            )
        }
    }

    /**
     * Multi-Factor Student Retention Risk & Exact Installment Calculator.
     */
    fun evaluateStudentProfiles(
        students: List<StudentEntity>,
        groups: List<GroupEntity>,
        attendance: List<AttendanceEntity>,
    ): Pair<Map<String, StudentOrProfile>, List<String>> {
        if (students.isEmpty()) return emptyMap<String, StudentOrProfile>() to emptyList()
        val groupMap = groups.associateBy { it.id }

        val profiles = students.map { s ->
            val sessionPrice = (groupMap[s.groupId]?.pricePerSessionPiasters ?: 8000L).coerceAtLeast(1000L)
            val covered = (s.walletBalancePiasters / sessionPrice).toInt().coerceAtLeast(0)
            val masteryDeficit = (85 - s.masteryPercent).coerceAtLeast(0)
            val duesPressure = if (s.dueBalancePiasters > 0L) 28 else 0
            val lowWalletPenalty = if (covered <= 1) 20 else if (covered == 2) 10 else 0
            val streakPenalty = if (s.streakDays < 3) 14 else 0
            val blockedPenalty = if (s.isBlocked) 35 else 0
            val attendanceCount = attendance.count { it.studentId == s.id }
            val attendanceOffset = minOf(attendanceCount * 2, 10)

            val risk = (masteryDeficit + duesPressure + lowWalletPenalty + streakPenalty + blockedPenalty - attendanceOffset)
                .coerceIn(5, 99)

            val tier = when {
                s.isBlocked || risk >= 60 -> StudentRiskTier.CRITICAL
                risk >= 32 -> StudentRiskTier.WATCH
                else -> StudentRiskTier.HEALTHY
            }

            // Optimal installment = pending dues + target 4-session safety buffer rounded up to nearest 10 EGP (1000 piasters)
            val targetWalletBuffer = sessionPrice * 4L
            val neededBuffer = (targetWalletBuffer - s.walletBalancePiasters).coerceAtLeast(0L)
            val rawInstallment = (s.dueBalancePiasters + neededBuffer).coerceAtLeast(sessionPrice)
            val roundedInstallment = (ceil(rawInstallment / 1000.0).toLong() * 1000L).coerceAtLeast(sessionPrice)

            val (kind, actionAr, actionEn) = when {
                s.isBlocked -> Triple(
                    "unblock_review",
                    "يحتاج مراجعة إدارية عاجلة وإعادة التفعيل",
                    "Needs urgent reception review & reactivation",
                )
                s.dueBalancePiasters > 0L -> Triple(
                    "discreet_installment",
                    "سماح هادئ + قسط مقترح ${EgyptValidators.formatPiasters(roundedInstallment, "ar")}",
                    "Discreet entry + suggested ${EgyptValidators.formatPiasters(roundedInstallment, "en")}",
                )
                s.masteryPercent < 75 -> Triple(
                    "academic_rescue",
                    "خطة إنقاذ 15 دقيقة لرفع الإتقان (${s.masteryPercent}%)",
                    "15-min rescue plan to lift mastery (${s.masteryPercent}%)",
                )
                else -> Triple(
                    "steady",
                    "مسار مستقر · رصيد يغطي $covered حصص",
                    "On track · wallet covers $covered sessions",
                )
            }

            StudentOrProfile(
                studentId = s.id,
                riskScore = risk,
                riskTier = tier,
                coveredSessions = covered,
                recommendedInstallmentPiasters = roundedInstallment,
                actionKind = kind,
                actionSummaryAr = actionAr,
                actionSummaryEn = actionEn,
            )
        }

        val orderedIds = profiles.sortedByDescending { it.riskScore }.map { it.studentId }
        return profiles.associateBy { it.studentId } to orderedIds
    }
}
