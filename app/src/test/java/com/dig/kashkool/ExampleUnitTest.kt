package com.dig.kashkool

import com.dig.kashkool.core.analytics.AttendanceAnalyticsEngine
import com.dig.kashkool.core.analytics.AttendanceWindow
import com.dig.kashkool.core.l10n.AppLanguage
import com.dig.kashkool.core.l10n.AppStrings
import com.dig.kashkool.core.utils.DynamicQrEngine
import com.dig.kashkool.core.utils.EgyptValidators
import com.dig.kashkool.core.utils.QrMatrixGenerator
import com.dig.kashkool.core.utils.QrPayloadKind
import com.dig.kashkool.core.utils.QrVerifyStatus
import com.dig.kashkool.core.or.CourseCandidate
import com.dig.kashkool.core.or.OperationsResearchEngine
import com.dig.kashkool.core.or.StudentRiskTier
import com.dig.kashkool.core.or.StudyCandidate
import com.dig.kashkool.data.local.AttendanceEntity
import com.dig.kashkool.data.local.AvailabilityStatus
import com.dig.kashkool.data.local.EvaluationTargetType
import com.dig.kashkool.data.local.GroupEntity
import com.dig.kashkool.data.local.KashkoolSeeds
import com.dig.kashkool.data.local.LedgerEntryEntity
import com.dig.kashkool.data.local.LedgerKind
import com.dig.kashkool.data.local.PaymentChannelEntity
import com.dig.kashkool.data.local.PerformanceEvaluationConverters
import com.dig.kashkool.data.local.PerformanceEvaluationEntity
import com.dig.kashkool.data.local.Resource
import com.dig.kashkool.data.local.ResourceConverters
import com.dig.kashkool.data.local.ResourceType
import com.dig.kashkool.data.local.StudentEntity
import com.dig.kashkool.data.local.UserRole
import com.dig.kashkool.core.firebase.AiAcademicToolkit
import com.dig.kashkool.core.firebase.LessonRevisionDeck
import com.dig.kashkool.core.firebase.ParentWeeklyDigest
import com.dig.kashkool.core.firebase.ReceiptScanResult
import com.dig.kashkool.core.firebase.SecretaryNoticeDraft
import com.dig.kashkool.core.firebase.TeacherLessonPlan
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
    fun studentQrGeneratorAndScannedPayloadVerification() {
        val engine = DynamicQrEngine("sess-nokhba-today", "secret-key")
        val studentPass = engine.studentTokenAt("stu-1", epochSeconds = 90L)
        assertTrue(studentPass.startsWith("KSHS|stu-1|sess-nokhba-today|"))

        val validResult = engine.verifyScannedPayload(studentPass, epochSeconds = 105L)
        assertEquals(QrVerifyStatus.VALID, validResult.status)
        assertEquals(QrPayloadKind.STUDENT_DYNAMIC, validResult.kind)
        assertEquals("stu-1", validResult.studentId)

        val graceResult = engine.verifyScannedPayload(studentPass, epochSeconds = 125L)
        assertEquals(QrVerifyStatus.VALID, graceResult.status)

        val expiredResult = engine.verifyScannedPayload(studentPass, epochSeconds = 200L)
        assertEquals(QrVerifyStatus.EXPIRED, expiredResult.status)

        val tampered = studentPass.dropLast(4) + "beef"
        assertEquals(QrVerifyStatus.INVALID, engine.verifyScannedPayload(tampered, epochSeconds = 105L).status)

        val cardPayload = engine.cardPayloadFor("stu-2", "ksh-2026-b")
        assertEquals("KSHC|stu-2|KSH2026B", cardPayload)
        val cardResult = engine.verifyScannedPayload(cardPayload, epochSeconds = 105L)
        assertEquals(QrVerifyStatus.VALID, cardResult.status)
        assertEquals(QrPayloadKind.STUDENT_CARD, cardResult.kind)
        assertEquals("stu-2", cardResult.studentId)
        assertEquals("KSH2026B", cardResult.activationCode)

        val bareCodeResult = engine.verifyScannedPayload("KSH2026A", epochSeconds = 105L)
        assertEquals(QrVerifyStatus.VALID, bareCodeResult.status)
        assertEquals(QrPayloadKind.STUDENT_CARD, bareCodeResult.kind)
        assertEquals("KSH2026A", bareCodeResult.activationCode)

        val gateResult = engine.verifyScannedPayload(engine.tokenAt(90L), epochSeconds = 100L)
        assertEquals(QrVerifyStatus.VALID, gateResult.status)
        assertEquals(QrPayloadKind.SESSION_GATE, gateResult.kind)

        val matrixA = QrMatrixGenerator.encode(studentPass)
        val matrixB = QrMatrixGenerator.encode(cardPayload)
        assertTrue(matrixA.size >= 21)
        assertTrue(matrixA.isDark(1, 1))
        assertFalse(matrixA.modules.contentEquals(matrixB.modules))
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
        // Invisible intelligence check across new UI strings
        listOf(
            "scan_receipt_cta",
            "revision_deck_cta",
            "parent_digest_refresh",
            "draft_notice_cta",
            "teacher_plan_cta",
            "assistant_attach_photo",
            "student_qr_pass_title",
            "open_qr_scanner_cta",
            "qr_scanner_title",
            "att_dash_title",
            "att_open_full_dash",
        ).forEach { key ->
            val ar = AppStrings.t(key, AppLanguage.AR)
            val en = AppStrings.t(key, AppLanguage.EN)
            assertFalse(ar.contains("ذكاء اصطناعي"))
            assertFalse(en.contains("LLM", ignoreCase = true))
            assertFalse(en.contains("Bot", ignoreCase = true))
        }
    }

    @Test
    fun attendanceAnalyticsEngineComputesDailyTrendsAndFilters() {
        val now = 1_760_000_000_000L
        val seedRecords = KashkoolSeeds.initialAttendance(now) + listOf(
            AttendanceEntity(
                id = "att-today-1",
                studentId = "stu-1",
                studentNameAr = "أحمد محمد علي",
                studentNameEn = "Ahmed Mohamed Ali",
                groupId = "grp-math-3sec",
                sessionId = "sess-nokhba-today",
                feedbackStatus = "valid",
                timestampMillis = now - 60_000L,
            ),
            AttendanceEntity(
                id = "att-today-2",
                studentId = "stu-2",
                studentNameAr = "سارة خالد حسن",
                studentNameEn = "Sara Khaled Hassan",
                groupId = "grp-math-3sec",
                sessionId = "sess-nokhba-today",
                feedbackStatus = "due",
                timestampMillis = now - 30_000L,
            ),
        )

        val snap14 = AttendanceAnalyticsEngine.compute(
            attendance = seedRecords,
            groups = KashkoolSeeds.groups,
            students = KashkoolSeeds.students,
            window = AttendanceWindow.DAYS_14,
            selectedGroupId = null,
            nowMillis = now,
        )
        assertEquals(14, snap14.dailyPoints.size)
        assertEquals(2, snap14.todayCheckIns)
        assertEquals(seedRecords.size, snap14.totalCheckIns)
        assertTrue(snap14.validCount > 0)
        assertTrue(snap14.dueCount > 0)
        assertTrue(snap14.blockedCount > 0)
        assertEquals(3, snap14.groupSummaries.size)
        assertEquals("att-today-2", snap14.recentRecords.first().id)

        val snapFiltered = AttendanceAnalyticsEngine.compute(
            attendance = seedRecords,
            groups = KashkoolSeeds.groups,
            students = KashkoolSeeds.students,
            window = AttendanceWindow.DAYS_7,
            selectedGroupId = "grp-phys-3sec",
            nowMillis = now,
        )
        assertEquals(7, snapFiltered.dailyPoints.size)
        assertEquals(0, snapFiltered.todayCheckIns)
        assertTrue(snapFiltered.totalCheckIns < snap14.totalCheckIns)
        assertEquals(0, snapFiltered.dueCount)
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
    fun upgradedOrPlatformEngineDrivesAllWorkflows() {
        val groups = listOf(
            GroupEntity("g1", "أ", "A", "رياضة", "Math", "السبت", "Sat", enrolled = 48, capacity = 50, pricePerSessionPiasters = 8000L),
            GroupEntity("g2", "ب", "B", "رياضة", "Math", "الأحد", "Sun", enrolled = 15, capacity = 40, pricePerSessionPiasters = 8000L),
            GroupEntity("g3", "ج", "C", "رياضة", "Math", "الإثنين", "Mon", enrolled = 36, capacity = 40, pricePerSessionPiasters = 8000L),
        )
        val alloc = OperationsResearchEngine.analyzeGroupAllocation(groups)
        assertTrue(alloc.transferPlans.isNotEmpty())
        assertEquals("g2", alloc.optimalWalkInGroupId)
        assertTrue(alloc.balanceScorePercent in 35..100)

        val q1 = OperationsResearchEngine.analyzeQueueDispatch(enrolledCount = 180, rushModeEnabled = false)
        val q2 = OperationsResearchEngine.analyzeQueueDispatch(enrolledCount = 180, rushModeEnabled = true)
        assertTrue(q1.erlangCWaitProbabilityPercent >= q2.erlangCWaitProbabilityPercent)
        assertTrue(q1.optimalLanesForSla >= 1)
        assertTrue(q2.expectedQueueLengthStudents <= q1.expectedQueueLengthStudents)

        val students = listOf(
            StudentEntity("s_risk", "طارق", "Tarek", "+201000000001", "g1", walletBalancePiasters = 4000L, dueBalancePiasters = 16000L, streakDays = 1, masteryPercent = 62, isBlocked = false),
            StudentEntity("s_ok", "سارة", "Sara", "+201000000002", "g2", walletBalancePiasters = 40000L, dueBalancePiasters = 0L, streakDays = 9, masteryPercent = 94, isBlocked = false),
        )
        val channels = listOf(
            PaymentChannelEntity("ch_fawry", "فوري", "Fawry", "fawry", "12345", feePiasters = 500L, isActive = true, maxAmountPiasters = 100000L),
            PaymentChannelEntity("ch_instapay", "إنستاباي", "InstaPay", "insta_pay", "kashkool@ip", feePiasters = 0L, isActive = true, maxAmountPiasters = 100000L),
            PaymentChannelEntity("ch_off", "معطل", "Off", "cash", "desk", feePiasters = 0L, isActive = false, maxAmountPiasters = 100000L),
        )
        val courses = listOf(
            CourseCandidate("c1", "التفاضل", "Calculus Limits", dataEstimateMb = 18),
            CourseCandidate("c2", "الميكانيكا", "Heavy Dynamics", dataEstimateMb = 55),
            CourseCandidate("c3", "التكامل", "Integrals", dataEstimateMb = 25),
        )
        val ledgerWithVoids = listOf(
            LedgerEntryEntity(
                id = "l1",
                studentId = "s_ok",
                studentNameAr = "سارة",
                studentNameEn = "Sara",
                kind = LedgerKind.CASH_TOPUP.key,
                amountPiasters = 16000L,
                createdAtMillis = 1_700_000_000_000L,
            ),
            LedgerEntryEntity(
                id = "l2",
                studentId = "s_ok",
                studentNameAr = "سارة",
                studentNameEn = "Sara",
                kind = LedgerKind.VOID_ENTRY.key,
                amountPiasters = -8000L,
                voidedEntryId = "l1",
                createdAtMillis = 1_700_000_001_000L,
            ),
        )
        val resources = listOf(
            Resource("r_hall", "Hall 1", ResourceType.TOOL, AvailabilityStatus.AVAILABLE, costPiasters = 10000L),
        )
        val candidates = listOf(
            StudyCandidate("st1", "التفاضل", "Calculus", minutesRequired = 10, masteryGainPercent = 9),
            StudyCandidate("st2", "الجبر", "Algebra", minutesRequired = 15, masteryGainPercent = 14),
        )

        val report10 = OperationsResearchEngine.evaluateSystem(
            role = UserRole.STUDENT,
            groups = groups,
            students = students,
            attendance = listOf(
                AttendanceEntity(
                    id = "a1",
                    studentId = "s_ok",
                    studentNameAr = "سارة",
                    studentNameEn = "Sara",
                    groupId = "g2",
                    sessionId = "sess-1",
                    feedbackStatus = "valid",
                    timestampMillis = 1_700_000_000_000L,
                )
            ),
            ledger = ledgerWithVoids,
            submissions = emptyList(),
            rescueCandidates = candidates,
            rushModeEnabled = false,
            resources = resources,
            assistantWagesPiasters = 10000L,
            channels = channels,
            courses = courses,
            completedCourseIds = emptySet(),
            lowDataMode = true,
            studyBudgetMinutes = 10,
        )
        val report30 = OperationsResearchEngine.evaluateSystem(
            role = UserRole.TEACHER,
            groups = groups,
            students = students,
            attendance = emptyList(),
            ledger = ledgerWithVoids,
            submissions = emptyList(),
            rescueCandidates = candidates,
            rushModeEnabled = true,
            resources = resources,
            assistantWagesPiasters = 10000L,
            channels = channels,
            courses = courses,
            completedCourseIds = emptySet(),
            lowDataMode = true,
            studyBudgetMinutes = 30,
        )

        assertEquals("ch_instapay", report10.channelOptimization?.optimalChannelId)
        assertEquals(500L, report10.channelOptimization?.feeSavingsPiasters)
        assertEquals(3, report10.courseRecommendations.size)
        assertTrue(report10.courseRecommendations.first().isTopPick)
        assertEquals(StudentRiskTier.CRITICAL, report10.studentProfiles["s_risk"]?.riskTier)
        assertEquals(StudentRiskTier.HEALTHY, report10.studentProfiles["s_ok"]?.riskTier)
        assertEquals("s_risk", report10.priorityStudentIds.first())
        assertTrue((report10.studentProfiles["s_risk"]?.recommendedInstallmentPiasters ?: 0L) >= 16000L)
        assertTrue(report10.financialCertainty.anomalyDetected)
        assertEquals(10000L, report10.financialCertainty.resourceOverheadPiasters)
        assertEquals(
            report10.financialCertainty.netPayoutPiasters - 10000L,
            report10.financialCertainty.netAfterResourcesPiasters
        )
        assertTrue(report30.studyKnapsack.guaranteedGainPercent > report10.studyKnapsack.guaranteedGainPercent)
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

    @Test
    fun aiAcademicToolkitStructuredDtosDecodeCleanly() {
        val json = AiAcademicToolkit().jsonParser

        val receipt = json.decodeFromString<ReceiptScanResult>(
            """{"amountEgp":"240","referenceNumber":"IPN99821","detectedChannelType":"insta_pay","clarityStatus":"high","verificationNote":"إيصال واضح."}"""
        )
        assertEquals("240", receipt.amountEgp)
        assertEquals("IPN99821", receipt.referenceNumber)
        assertEquals("insta_pay", receipt.detectedChannelType)

        val deck = json.decodeFromString<LessonRevisionDeck>(
            """{"lessonTitle":"التفاضل","memoryHook":"اختر u بالأولوية","flashcards":[{"front":"∫u dv","back":"u·v - ∫v du"}],"commonTraps":["نسيان ثابت التكامل"]}"""
        )
        assertEquals(1, deck.flashcards.size)
        assertEquals(1, deck.commonTraps.size)

        val digest = json.decodeFromString<ParentWeeklyDigest>(
            """{"headline":"أسبوع ممتاز","weeklyNarrative":"حضر 4 حصص.","cheerMessage":"عاش يا بطل","homeSupportTip":"مراجعة 10 دقائق"}"""
        )
        assertEquals("أسبوع ممتاز", digest.headline)

        val notice = json.decodeFromString<SecretaryNoticeDraft>(
            """{"toneTag":"متابعة لطيفة","messageText":"أهلاً بحضرتك في سنتر النخبة."}"""
        )
        assertEquals("متابعة لطيفة", notice.toneTag)

        val plan = json.decodeFromString<TeacherLessonPlan>(
            """{"topicTitle":"التكامل","pacingSteps":["0-15 مراجعة"],"basicHomework":["مسألة 1"],"challengeHomework":["مسألة متفوقين"],"assistantChecklist":["تجهيز الملازم"]}"""
        )
        assertEquals("التكامل", plan.topicTitle)
        assertEquals(1, plan.challengeHomework.size)
    }
}