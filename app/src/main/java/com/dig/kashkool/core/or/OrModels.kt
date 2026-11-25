package com.dig.kashkool.core.or

data class CourseCandidate(
    val id: String,
    val titleAr: String,
    val titleEn: String,
    val dataEstimateMb: Int,
)

data class StudyCandidate(
    val id: String,
    val titleAr: String,
    val titleEn: String,
    val minutesRequired: Int,
    val masteryGainPercent: Int,
)

data class StudyKnapsackResult(
    val timeBudgetMinutes: Int,
    val selectedItems: List<StudyCandidate>,
    val totalMinutesUsed: Int,
    val guaranteedGainPercent: Int,
)

data class SeatTransferPlan(
    val fromGroupId: String,
    val fromGroupAr: String,
    val fromGroupEn: String,
    val toGroupId: String,
    val toGroupAr: String,
    val toGroupEn: String,
    val seatsToMove: Int,
)

data class GroupAllocationResult(
    val totalEnrolled: Int,
    val totalCapacity: Int,
    val utilizationPercent: Int,
    val bottleneckGroupId: String?,
    val bottleneckGroupAr: String?,
    val bottleneckGroupEn: String?,
    val bottleneckFillPercent: Int,
    val slackGroupId: String?,
    val slackGroupAr: String?,
    val slackGroupEn: String?,
    val recommendedSeatShift: Int,
    val transferPlans: List<SeatTransferPlan> = emptyList(),
    val optimalWalkInGroupId: String? = null,
    val optimalWalkInGroupAr: String? = null,
    val optimalWalkInGroupEn: String? = null,
    val balanceScorePercent: Int = 100,
)

data class FinancialCertaintyResult(
    val attendedCount: Int,
    val splitPercentUsed: Int,
    val grossPiasters: Long,
    val centerSplitPiasters: Long,
    val assistantWagesPiasters: Long,
    val netPayoutPiasters: Long,
    val breakEvenAttendance: Int,
    val marginOfSafetyPercent: Int,
    val pendingDuesPiasters: Long,
    val ledgerBalanced: Boolean,
    val voidChainCount: Int,
    val resourceOverheadPiasters: Long = 0L,
    val netAfterResourcesPiasters: Long = netPayoutPiasters,
    val collectionEfficiencyPercent: Int = 100,
    val voidRatioPercent: Int = 0,
    val anomalyDetected: Boolean = false,
    val projectedWeeklyGrossPiasters: Long = grossPiasters * 2L,
)

data class QueueDispatchResult(
    val activeLanes: Int,
    val expectedWaitSeconds: Int,
    val queueUtilizationPercent: Int,
    val recommendExtraLane: Boolean,
    val erlangCWaitProbabilityPercent: Int = 0,
    val expectedQueueLengthStudents: Double = 0.0,
    val optimalLanesForSla: Int = activeLanes,
)

data class ResourceConflictReport(
    val totalResources: Int,
    val availableCount: Int,
    val inUseCount: Int,
    val unavailableCount: Int,
    val hasHallOrScheduleConflict: Boolean,
    val summaryAr: String,
    val summaryEn: String,
    val utilizedResourceCostPiasters: Long = 0L,
    val conflictGroupCount: Int = 0,
)

data class PaymentChannelOptimization(
    val optimalChannelId: String?,
    val optimalChannelNameAr: String?,
    val optimalChannelNameEn: String?,
    val optimalFeePiasters: Long,
    val feeSavingsPiasters: Long,
    val recommendedAmountPiasters: Long,
    val reasonAr: String,
    val reasonEn: String,
)

data class CoursePriorityRecommendation(
    val courseId: String,
    val rank: Int,
    val priorityScore: Int,
    val efficiencyPerMb: Double,
    val isTopPick: Boolean,
    val selectedInDataBudget: Boolean,
    val reasonAr: String,
    val reasonEn: String,
)

enum class StudentRiskTier(val key: String) {
    CRITICAL("critical"),
    WATCH("watch"),
    HEALTHY("healthy"),
}

data class StudentOrProfile(
    val studentId: String,
    val riskScore: Int,
    val riskTier: StudentRiskTier,
    val coveredSessions: Int,
    val recommendedInstallmentPiasters: Long,
    val actionKind: String, // "unblock_review", "discreet_installment", "academic_rescue", "steady"
    val actionSummaryAr: String,
    val actionSummaryEn: String,
)

data class CertaintyBreakdown(
    val auditScore: Int,
    val marginScore: Int,
    val capacityScore: Int,
    val queueSlaScore: Int,
    val resourceScore: Int,
)

data class OperationalDecision(
    val titleAr: String,
    val titleEn: String,
    val detailAr: String,
    val detailEn: String,
    val verifiedFormula: String,
    val priorityHigh: Boolean = false,
)

data class SystemOperatingReport(
    val certaintyScorePercent: Int,
    val groupAllocation: GroupAllocationResult,
    val financialCertainty: FinancialCertaintyResult,
    val studyKnapsack: StudyKnapsackResult,
    val queueDispatch: QueueDispatchResult,
    val resourceConflict: ResourceConflictReport,
    val decisions: List<OperationalDecision>,
    val channelOptimization: PaymentChannelOptimization? = null,
    val courseRecommendations: List<CoursePriorityRecommendation> = emptyList(),
    val studentProfiles: Map<String, StudentOrProfile> = emptyMap(),
    val priorityStudentIds: List<String> = emptyList(),
    val certaintyBreakdown: CertaintyBreakdown = CertaintyBreakdown(35, 25, 15, 10, 15),
)
