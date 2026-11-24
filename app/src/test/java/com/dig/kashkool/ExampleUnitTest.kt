package com.dig.kashkool

import com.dig.kashkool.core.l10n.AppLanguage
import com.dig.kashkool.core.l10n.AppStrings
import com.dig.kashkool.core.utils.DynamicQrEngine
import com.dig.kashkool.core.utils.EgyptValidators
import com.dig.kashkool.core.utils.QrVerifyStatus
import com.dig.kashkool.core.or.OperationsResearchEngine
import com.dig.kashkool.core.or.StudyCandidate
import com.dig.kashkool.data.local.AvailabilityStatus
import com.dig.kashkool.data.local.EvaluationTargetType
import com.dig.kashkool.data.local.GroupEntity
import com.dig.kashkool.data.local.LedgerKind
import com.dig.kashkool.data.local.PerformanceEvaluationConverters
import com.dig.kashkool.data.local.PerformanceEvaluationEntity
import com.dig.kashkool.data.local.Resource
import com.dig.kashkool.data.local.ResourceConverters
import com.dig.kashkool.data.local.ResourceType
import com.dig.kashkool.data.local.UserRole
import com.dig.kashkool.ui.viewmodel.KashkoolMessageBuilders
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class ExampleUnitTest {
    @Test
    fun egyptianPhoneNormalization() {
        assertTrue(EgyptValidators.isValidEgyptianPhone("01012345678"))
        assertTrue(EgyptValidators.isValidEgyptianPhone("+201122334455"))
        assertFalse(EgyptValidators.isValidEgyptianPhone("0212345678"))
        assertEquals("+201012345678", EgyptValidators.normalizeEgyptianPhone("01012345678"))
    }

    @Test
    fun piastersFormatting() {
        assertEquals("240 ج.م", EgyptValidators.formatPiasters(24000L, "ar"))
        assertEquals("125.50 EGP", EgyptValidators.formatPiasters(12550L, "en"))
        assertEquals(8000L, EgyptValidators.egpStringToPiasters("80"))
    }

    @Test
    fun dynamicQrRotatesAndVerifiesHmacTokens() {
        val engine = DynamicQrEngine("sess-1", "secret-key")
        val tokenAt60 = engine.tokenAt(60L)
        assertEquals(tokenAt60, engine.tokenAt(89L))
        assertFalse(tokenAt60 == engine.tokenAt(90L))

        assertEquals(QrVerifyStatus.VALID, engine.verifyToken(tokenAt60, epochSeconds = 85L).status)
        assertEquals(QrVerifyStatus.VALID, engine.verifyToken(tokenAt60, epochSeconds = 100L).status)
        assertEquals(QrVerifyStatus.EXPIRED, engine.verifyToken(tokenAt60, epochSeconds = 180L).status)
        assertEquals(QrVerifyStatus.INVALID, engine.verifyToken("KSH|sess-1|2|deadbeef", epochSeconds = 85L).status)
        assertEquals(QrVerifyStatus.INVALID, engine.verifyToken("random-junk", epochSeconds = 85L).status)
    }

    @Test
    fun zeroCostQrActivationValidation() {
        val generated = EgyptValidators.generateActivationCode(8)
        assertEquals(8, generated.length)
        assertTrue(EgyptValidators.isValidQrActivationCode(generated))
        assertEquals("KSH2026A", EgyptValidators.normalizeQrCode(" ksh-2026-a "))
        assertFalse(EgyptValidators.isValidQrActivationCode("ab"))
    }

    @Test
    fun receiptDataSavingsCalculation() {
        assertEquals(75, EgyptValidators.dataSavingsPercent(400_000L, 100_000L))
        assertEquals(0, EgyptValidators.dataSavingsPercent(0L, 100L))
        assertEquals(0, EgyptValidators.dataSavingsPercent(100L, 150L))
    }

    @Test
    fun resourceEntityAndConverters() {
        val converters = ResourceConverters()
        assertEquals("financial", converters.fromResourceType(ResourceType.FINANCIAL))
        assertEquals(ResourceType.HUMAN, converters.toResourceType("human"))
        assertEquals("in_use", converters.fromAvailabilityStatus(AvailabilityStatus.IN_USE))
        assertEquals(AvailabilityStatus.AVAILABLE, converters.toAvailabilityStatus("available"))

        val resource = Resource(
            id = "res-1",
            name = "Teaching Assistant",
            type = ResourceType.HUMAN,
            availabilityStatus = AvailabilityStatus.AVAILABLE,
        )
        assertEquals("pending", resource.syncStatus)
        assertEquals(0L, resource.costPiasters)
    }

    @Test
    fun localizationKeyParityAndNaturalLabels() {
        assertTrue(AppStrings.allKeysMatch())
        assertEquals("الحضور", AppStrings.t("attendance", AppLanguage.AR))
        assertEquals("Attendance", AppStrings.t("attendance", AppLanguage.EN))
        assertEquals("شحن رصيد", AppStrings.ledgerKindLabel(LedgerKind.CASH_TOPUP.key, AppLanguage.AR))
        assertEquals("Wallet Top-Up", AppStrings.ledgerKindLabel(LedgerKind.CASH_TOPUP.key, AppLanguage.EN))
        assertFalse(AppStrings.t("backend_offline", AppLanguage.AR).contains("SUPABASE", ignoreCase = true))
        assertFalse(AppStrings.t("zero_cost_badge", AppLanguage.AR).contains("صفرية"))
    }

    @Test
    fun operationsResearchSolversAreDeterministicAndAccurate() {
        val candidates = listOf(
            StudyCandidate("a", "درس أ", "Topic A", minutesRequired = 10, masteryGainPercent = 8),
            StudyCandidate("b", "درس ب", "Topic B", minutesRequired = 6, masteryGainPercent = 6),
            StudyCandidate("c", "درس ج", "Topic C", minutesRequired = 9, masteryGainPercent = 9),
        )
        val knapsack = OperationsResearchEngine.solveStudyKnapsack(candidates, budgetMinutes = 15)
        assertEquals(15, knapsack.guaranteedGainPercent)
        assertEquals(15, knapsack.totalMinutesUsed)

        val groups = listOf(
            GroupEntity("g1", "أ", "A", "رياضة", "Math", "السبت", "Sat", enrolled = 48, capacity = 50, pricePerSessionPiasters = 8000L),
            GroupEntity("g2", "ب", "B", "رياضة", "Math", "الأحد", "Sun", enrolled = 20, capacity = 40, pricePerSessionPiasters = 8000L),
        )
        val alloc = OperationsResearchEngine.analyzeGroupAllocation(groups)
        assertEquals("g1", alloc.bottleneckGroupId)
        assertEquals("g2", alloc.slackGroupId)
        assertEquals(96, alloc.bottleneckFillPercent)
        assertEquals(8, alloc.recommendedSeatShift)

        val queue1Lane = OperationsResearchEngine.analyzeQueueDispatch(enrolledCount = 120, rushModeEnabled = false)
        val queue2Lanes = OperationsResearchEngine.analyzeQueueDispatch(enrolledCount = 120, rushModeEnabled = true)
        assertTrue(queue2Lanes.expectedWaitSeconds <= queue1Lane.expectedWaitSeconds)

        val readyResources = listOf(
            Resource("r1", "Hall A", ResourceType.TOOL, AvailabilityStatus.AVAILABLE),
            Resource("r2", "TA", ResourceType.HUMAN, AvailabilityStatus.IN_USE),
        )
        val clearReport = OperationsResearchEngine.analyzeResourceConflicts(groups, readyResources)
        assertFalse(clearReport.hasHallOrScheduleConflict)

        val brokenResources = listOf(
            Resource("r1", "Hall A", ResourceType.TOOL, AvailabilityStatus.UNAVAILABLE),
        )
        val conflictReport = OperationsResearchEngine.analyzeResourceConflicts(groups, brokenResources)
        assertTrue(conflictReport.hasHallOrScheduleConflict)

        val report = OperationsResearchEngine.evaluateSystem(
            role = UserRole.TEACHER,
            groups = groups,
            students = emptyList(),
            attendance = emptyList(),
            ledger = emptyList(),
            submissions = emptyList(),
            rescueCandidates = candidates,
            rushModeEnabled = false,
            resources = readyResources,
            assistantWagesPiasters = 20000L,
            splitPercentOverride = 25,
        )
        assertEquals(25, report.financialCertainty.splitPercentUsed)
        assertEquals(20000L, report.financialCertainty.assistantWagesPiasters)
        assertTrue(report.certaintyScorePercent in 50..100)
        assertTrue(report.financialCertainty.ledgerBalanced)
    }

    @Test
    fun performanceEvaluationConvertersAndShareFormatting() {
        val converters = PerformanceEvaluationConverters()
        assertEquals("teacher", converters.fromTargetType(EvaluationTargetType.TEACHER))
        assertEquals(EvaluationTargetType.STUDENT, converters.toTargetType("student"))

        val items = listOf("انتظام الحضور", "إتقان التفاضل")
        val encoded = converters.fromStringList(items)
        assertEquals(items, converters.toStringList(encoded))

        val eval = PerformanceEvaluationEntity(
            targetId = "stu-1",
            targetName = "أحمد محمد",
            targetType = EvaluationTargetType.STUDENT,
            languageCode = "ar",
            overallScore = 91,
            trustBadge = "موثق بالسجلات الفعلية",
            analyticalSummary = "مستوى تصاعدي منتظم خلال هذا الأسبوع.",
            instantFeedback = "مجهود ممتاز يا بطل!",
            strengths = items,
            improvementAreas = listOf("مراجعة التكامل المحدد"),
            nextActionPlan = listOf("حل 3 مسائل يومياً"),
            trustVerificationNote = "مبني على 18 حصة حضور واختبارات موثقة.",
        )
        val sharedAr = KashkoolMessageBuilders.buildEvaluationShareText(eval, AppLanguage.AR)
        assertTrue(sharedAr.contains("91/100"))
        assertTrue(sharedAr.contains("أحمد محمد"))
        assertTrue(sharedAr.contains("✓ انتظام الحضور"))
    }
}