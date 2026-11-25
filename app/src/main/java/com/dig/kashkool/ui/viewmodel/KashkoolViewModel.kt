package com.dig.kashkool.ui.viewmodel

import android.app.Application
import android.net.Uri
import android.util.Log
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import com.dig.kashkool.core.analytics.AttendanceAnalyticsEngine
import com.dig.kashkool.core.analytics.AttendanceChartMode
import com.dig.kashkool.core.analytics.AttendanceWindow
import com.dig.kashkool.core.firebase.AiAcademicToolkit
import com.dig.kashkool.core.firebase.AiOperationsAdvisor
import com.dig.kashkool.core.l10n.AppLanguage
import com.dig.kashkool.core.l10n.AppStrings
import com.dig.kashkool.core.or.CourseCandidate
import com.dig.kashkool.core.or.OperationsResearchEngine
import com.dig.kashkool.core.or.StudyCandidate
import com.dig.kashkool.core.utils.CompressedReceiptResult
import com.dig.kashkool.core.utils.DynamicQrEngine
import com.dig.kashkool.core.utils.EgyptValidators
import com.dig.kashkool.core.utils.ImageCompressor
import com.dig.kashkool.core.utils.QrVerifyStatus
import com.dig.kashkool.data.local.AttendanceEntity
import com.dig.kashkool.data.local.GroupEntity
import com.dig.kashkool.data.local.LedgerEntryEntity
import com.dig.kashkool.data.local.LedgerKind
import com.dig.kashkool.data.local.PaymentChannelEntity
import com.dig.kashkool.data.local.PaymentSubmissionEntity
import com.dig.kashkool.data.local.PerformanceEvaluationEntity
import com.dig.kashkool.data.local.Resource
import com.dig.kashkool.data.local.ResourceType
import com.dig.kashkool.data.local.StudentEntity
import com.dig.kashkool.data.local.SubmissionStatus
import com.dig.kashkool.data.local.UserRole
import com.dig.kashkool.data.repository.KashkoolRepository
import com.dig.kashkool.data.repository.QrCheckInOutcome
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.TimeoutCancellationException
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import kotlin.math.abs

private const val TAG = "KashkoolViewModel"

class KashkoolViewModel(application: Application) : AndroidViewModel(application) {

    private val repo = KashkoolRepository(application)
    private val aiAdvisor = AiOperationsAdvisor()
    private val aiToolkit = AiAcademicToolkit()
    private val qrEngine = DynamicQrEngine(
        sessionId = "sess-nokhba-today",
        sessionSecret = "kashkool-local-session-hmac-secret-2026",
    )

    val courses: List<CourseUnit> = KashkoolCatalog.courses
    val quizQuestions: List<QuizQuestion> = KashkoolCatalog.quizQuestions

    private val transientState = MutableStateFlow(
        TransientState(
            loading = true,
            qrToken = qrEngine.tokenAt(),
            qrSecondsRemaining = qrEngine.secondsRemaining(),
            assistantMessages = listOf(KashkoolMessageBuilders.initialAssistantMessage()),
        )
    )

    private data class TransientState(
        val loading: Boolean = false,
        val auth: AuthUiState = AuthUiState(),
        val qrToken: String = "",
        val qrSecondsRemaining: Int = 30,
        val qrEpochSeconds: Long = System.currentTimeMillis() / 1000L,
        val scannerScanCount: Int = 0,
        val lastScanFeedback: ScanFeedback? = null,
        val qrVerificationBanner: QrVerificationBanner? = null,
        val snackbarMessage: String? = null,
        val assistantMessages: List<AssistantMessage> = emptyList(),
        val assistantBusy: Boolean = false,
        val assistantError: String? = null,
        val activeLectureId: String? = null,
        val activeLectureTitle: String? = null,
        val adaptiveQuizQuestions: List<QuizQuestion>? = null,
        val adaptiveQuizTopic: String? = null,
        val adaptiveQuizBusy: Boolean = false,
        val adaptiveQuizError: String? = null,
        val syncBusy: Boolean = false,
        val generatedQrCode: String? = null,
        val generatedQrStudentName: String? = null,
        val compressedReceipt: CompressedReceiptResult? = null,
        val receiptCompressing: Boolean = false,
        val reassurancePulseAtMillis: Long = System.currentTimeMillis(),
        val rushModeEnabled: Boolean = false,
        val aiBriefingState: AiBriefingState = AiBriefingState.Idle,
        val evaluationState: EvaluationUiState = EvaluationUiState.Idle,
        val receiptScanState: ReceiptScanUiState = ReceiptScanUiState.Idle,
        val revisionDeckState: RevisionDeckUiState = RevisionDeckUiState.Idle,
        val parentDigestState: ParentDigestUiState = ParentDigestUiState.Idle,
        val secretaryNoticeState: SecretaryNoticeUiState = SecretaryNoticeUiState.Idle,
        val teacherPlanState: TeacherPlanUiState = TeacherPlanUiState.Idle,
        val studyBudgetMinutes: Int = 15,
        val attendanceWindow: AttendanceWindow = AttendanceWindow.DAYS_14,
        val attendanceChartMode: AttendanceChartMode = AttendanceChartMode.AREA_TREND,
        val attendanceGroupFilter: String? = null,
    )

    private data class DbBundle(
        val groups: List<GroupEntity>,
        val students: List<StudentEntity>,
        val attendance: List<AttendanceEntity>,
        val ledger: List<LedgerEntryEntity>,
        val channels: List<PaymentChannelEntity>,
        val allChannels: List<PaymentChannelEntity>,
        val submissions: List<PaymentSubmissionEntity>,
        val resources: List<Resource>,
        val evaluations: List<PerformanceEvaluationEntity>,
    )

    private data class PrefBundle(
        val language: AppLanguage,
        val signedIn: Boolean,
        val role: UserRole,
        val userLabel: String,
        val dataSaver: Boolean,
        val pendingSyncCount: Int,
    )

    private data class ExtraPrefBundle(
        val streakShieldActive: Boolean,
        val centerPlanId: String,
        val rescueIds: Set<String>,
        val splitPercent: Int,
        val assistantWagesPiasters: Long,
        val completedCourseIds: Set<String>,
    )

    private val dbFlow = combine(
        repo.groupsFlow,
        repo.studentsFlow,
        repo.attendanceFlow,
        repo.ledgerFlow,
        repo.activeChannelsFlow,
        repo.allChannelsFlow,
        repo.submissionsFlow,
        repo.resourcesFlow,
        repo.evaluationsFlow,
    ) { values ->
        @Suppress("UNCHECKED_CAST")
        DbBundle(
            groups = values[0] as List<GroupEntity>,
            students = values[1] as List<StudentEntity>,
            attendance = values[2] as List<AttendanceEntity>,
            ledger = values[3] as List<LedgerEntryEntity>,
            channels = values[4] as List<PaymentChannelEntity>,
            allChannels = values[5] as List<PaymentChannelEntity>,
            submissions = values[6] as List<PaymentSubmissionEntity>,
            resources = values[7] as List<Resource>,
            evaluations = values[8] as List<PerformanceEvaluationEntity>,
        )
    }

    private val prefFlow = combine<Any, PrefBundle>(
        repo.languageFlow,
        repo.signedInFlow,
        repo.roleFlow,
        repo.userLabelFlow,
        repo.dataSaverFlow,
        repo.pendingSyncCountFlow,
    ) { values ->
        PrefBundle(
            language = values[0] as AppLanguage,
            signedIn = values[1] as Boolean,
            role = values[2] as UserRole,
            userLabel = values[3] as String,
            dataSaver = values[4] as Boolean,
            pendingSyncCount = values[5] as Int,
        )
    }

    private val extraFlow = combine(
        repo.streakShieldFlow,
        repo.centerPlanIdFlow,
        repo.rescueIdsFlow,
        repo.settlementSplitPercentFlow,
        repo.assistantWagesPiastersFlow,
        repo.completedCourseIdsFlow,
    ) { values ->
        @Suppress("UNCHECKED_CAST")
        ExtraPrefBundle(
            streakShieldActive = values[0] as Boolean,
            centerPlanId = values[1] as String,
            rescueIds = values[2] as Set<String>,
            splitPercent = values[3] as Int,
            assistantWagesPiasters = values[4] as Long,
            completedCourseIds = values[5] as Set<String>,
        )
    }

    val uiState: StateFlow<KashkoolUiState> = combine(
        prefFlow,
        dbFlow,
        extraFlow,
        transientState,
    ) { prefs, db, extra, tr ->
        val rescueItems = extra.rescueIds.mapIndexedNotNull { idx, qId ->
            val q = (tr.adaptiveQuizQuestions.orEmpty() + quizQuestions).firstOrNull { it.id == qId }
                ?: return@mapIndexedNotNull null
            RescueItem(
                id = q.id,
                topicAr = q.topicTagAr,
                topicEn = q.topicTagEn,
                hintAr = q.remedialAr,
                hintEn = q.remedialEn,
                boostPercent = 4 + (idx * 2),
            )
        }

        val candidates = rescueItems.mapIndexed { idx, item ->
            StudyCandidate(
                id = item.id,
                titleAr = item.topicAr,
                titleEn = item.topicEn,
                minutesRequired = 5 + (idx * 2),
                masteryGainPercent = item.boostPercent,
            )
        }

        val approvedSubmissionTotal = db.submissions
            .filter { it.status == SubmissionStatus.APPROVED.key }
            .sumOf { it.amountPiasters }
        val cashTotal = db.ledger
            .filter {
                it.kind == LedgerKind.CASH_TOPUP.key ||
                    it.kind == LedgerKind.PARTIAL_INSTALLMENT.key ||
                    it.kind == LedgerKind.BOOK_RESERVATION.key
            }
            .sumOf { it.amountPiasters }
            .minus(approvedSubmissionTotal)
            .coerceAtLeast(0L)
        val voidTotal = db.ledger
            .filter { it.kind == LedgerKind.VOID_ENTRY.key }
            .sumOf { abs(it.amountPiasters) }
        val reconciliation = ShiftReconciliation(
            cashCollectedPiasters = cashTotal,
            electronicTransfersPiasters = approvedSubmissionTotal,
            voidedTotalPiasters = voidTotal,
            netDrawerCashPiasters = (cashTotal - voidTotal).coerceAtLeast(0L),
        )

        val courseCandidates = courses.map {
            CourseCandidate(
                id = it.id,
                titleAr = it.titleAr,
                titleEn = it.titleEn,
                dataEstimateMb = it.dataEstimateMb,
            )
        }
        val report = OperationsResearchEngine.evaluateSystem(
            role = prefs.role,
            groups = db.groups,
            students = db.students,
            attendance = db.attendance,
            ledger = db.ledger,
            submissions = db.submissions,
            rescueCandidates = candidates,
            rushModeEnabled = tr.rushModeEnabled,
            resources = db.resources,
            assistantWagesPiasters = extra.assistantWagesPiasters,
            splitPercentOverride = extra.splitPercent,
            channels = db.channels,
            courses = courseCandidates,
            completedCourseIds = extra.completedCourseIds,
            lowDataMode = prefs.dataSaver,
            studyBudgetMinutes = tr.studyBudgetMinutes,
        )

        val qrCodeFromLabel = Regex("QR:([A-Za-z0-9]+)").find(prefs.userLabel)?.groupValues?.getOrNull(1)
        val activeStudent = qrCodeFromLabel?.let { code ->
            db.students.firstOrNull { it.qrActivationCode.equals(code, ignoreCase = true) }
        } ?: db.students.firstOrNull { it.id == "stu-1" } ?: db.students.firstOrNull()

        val activeStudentQrToken = activeStudent?.let {
            qrEngine.studentTokenAt(it.id, tr.qrEpochSeconds)
        }.orEmpty()
        val activeStudentCardCode = activeStudent?.qrActivationCode.orEmpty()
        val activeStudentCardPayload = if (activeStudent != null && activeStudentCardCode.isNotBlank()) {
            qrEngine.cardPayloadFor(activeStudent.id, activeStudentCardCode)
        } else {
            ""
        }
        val startOfDayMillis = java.util.Calendar.getInstance().apply {
            set(java.util.Calendar.HOUR_OF_DAY, 0)
            set(java.util.Calendar.MINUTE, 0)
            set(java.util.Calendar.SECOND, 0)
            set(java.util.Calendar.MILLISECOND, 0)
        }.timeInMillis
        val activeStudentCheckedInToday = activeStudent != null && db.attendance.any {
            it.studentId == activeStudent.id &&
                it.sessionId == "sess-nokhba-today" &&
                it.timestampMillis >= startOfDayMillis &&
                it.feedbackStatus != "blocked"
        }

        val attendanceDashboard = AttendanceAnalyticsEngine.compute(
            attendance = db.attendance,
            groups = db.groups,
            students = db.students,
            window = tr.attendanceWindow,
            selectedGroupId = tr.attendanceGroupFilter,
        )

        KashkoolUiState(
            loading = tr.loading,
            language = prefs.language,
            signedIn = prefs.signedIn,
            activeRole = prefs.role,
            userLabel = prefs.userLabel,
            backendConfigured = repo.remote.hasValidSupabaseKeys,
            auth = tr.auth,
            groups = db.groups,
            students = db.students,
            attendance = db.attendance,
            ledger = db.ledger,
            channels = db.channels,
            allChannels = db.allChannels,
            submissions = db.submissions,
            resources = db.resources,
            qrToken = tr.qrToken,
            qrSecondsRemaining = tr.qrSecondsRemaining,
            activeStudentQrToken = activeStudentQrToken,
            activeStudentCardCode = activeStudentCardCode,
            activeStudentCardPayload = activeStudentCardPayload,
            activeStudentCheckedInToday = activeStudentCheckedInToday,
            scannerScanCount = tr.scannerScanCount,
            lastScanFeedback = tr.lastScanFeedback,
            qrVerificationBanner = tr.qrVerificationBanner,
            snackbarMessage = tr.snackbarMessage,
            assistantMessages = tr.assistantMessages,
            assistantBusy = tr.assistantBusy,
            assistantError = tr.assistantError,
            activeLectureId = tr.activeLectureId,
            activeLectureTitle = tr.activeLectureTitle,
            completedCourseIds = extra.completedCourseIds,
            adaptiveQuizQuestions = tr.adaptiveQuizQuestions,
            adaptiveQuizTopic = tr.adaptiveQuizTopic,
            adaptiveQuizBusy = tr.adaptiveQuizBusy,
            adaptiveQuizError = tr.adaptiveQuizError,
            pendingSyncCount = prefs.pendingSyncCount,
            syncBusy = tr.syncBusy,
            lowDataMode = prefs.dataSaver,
            generatedQrCode = tr.generatedQrCode,
            generatedQrStudentName = tr.generatedQrStudentName,
            compressedReceipt = tr.compressedReceipt,
            receiptCompressing = tr.receiptCompressing,
            streakShieldActive = extra.streakShieldActive,
            rescueItems = rescueItems,
            reassurancePulseAtMillis = tr.reassurancePulseAtMillis,
            rushModeEnabled = tr.rushModeEnabled,
            activeCenterPlanId = extra.centerPlanId,
            settlementSplitPercent = extra.splitPercent,
            assistantWagesPiasters = extra.assistantWagesPiasters,
            shiftReconciliation = reconciliation,
            operatingReport = report,
            aiBriefingState = tr.aiBriefingState,
            evaluations = db.evaluations,
            evaluationState = tr.evaluationState,
            receiptScanState = tr.receiptScanState,
            revisionDeckState = tr.revisionDeckState,
            parentDigestState = tr.parentDigestState,
            secretaryNoticeState = tr.secretaryNoticeState,
            teacherPlanState = tr.teacherPlanState,
            studyBudgetMinutes = tr.studyBudgetMinutes,
            attendanceWindow = tr.attendanceWindow,
            attendanceChartMode = tr.attendanceChartMode,
            attendanceGroupFilter = tr.attendanceGroupFilter,
            attendanceDashboard = attendanceDashboard,
        )
    }.stateIn(
        scope = viewModelScope,
        started = SharingStarted.WhileSubscribed(5000),
        initialValue = KashkoolUiState(backendConfigured = repo.remote.hasValidSupabaseKeys),
    )

    init {
        viewModelScope.launch {
            repo.ensureSeeded()
            transientState.update { it.copy(loading = false) }
        }
        viewModelScope.launch {
            while (true) {
                val nowSec = System.currentTimeMillis() / 1000L
                transientState.update {
                    it.copy(
                        qrToken = qrEngine.tokenAt(nowSec),
                        qrSecondsRemaining = qrEngine.secondsRemaining(nowSec),
                        qrEpochSeconds = nowSec,
                    )
                }
                delay(1000L)
            }
        }
    }

    fun toggleLanguage() = viewModelScope.launch {
        val next = if (uiState.value.language == AppLanguage.AR) AppLanguage.EN else AppLanguage.AR
        repo.setLanguage(next)
    }

    fun setAuthMode(mode: AuthMode) {
        transientState.update { it.copy(auth = AuthUiState(mode = mode)) }
    }

    fun requestOtp(input: String) {
        val mode = uiState.value.auth.mode
        val lang = uiState.value.language
        val trimmed = input.trim()
        if (mode == AuthMode.PHONE) {
            val normalized = EgyptValidators.normalizeEgyptianPhone(trimmed)
            if (normalized.isEmpty()) {
                transientState.update { it.copy(auth = it.auth.copy(errorMessage = AppStrings.t("err_invalid_phone", lang))) }
                return
            }
            sendRemoteOtp(normalized, isEmail = false)
        } else if (mode == AuthMode.EMAIL) {
            if (!trimmed.contains("@") || !trimmed.contains(".")) {
                transientState.update { it.copy(auth = it.auth.copy(errorMessage = AppStrings.t("err_invalid_email", lang))) }
                return
            }
            sendRemoteOtp(trimmed.lowercase(), isEmail = true)
        }
    }

    private fun sendRemoteOtp(identifier: String, isEmail: Boolean) = viewModelScope.launch {
        transientState.update { it.copy(auth = it.auth.copy(busy = true, errorMessage = null)) }
        repo.remote.requestOtp(identifier, isEmail).fold(
            onSuccess = { transientState.update { it.copy(auth = it.auth.copy(busy = false, awaitingOtp = true, identifier = identifier)) } },
            onFailure = { err -> transientState.update { it.copy(auth = it.auth.copy(busy = false, errorMessage = err.message)) } },
        )
    }

    fun verifyOtp(code: String) {
        val auth = uiState.value.auth
        val lang = uiState.value.language
        if (code.trim().length != 6) {
            transientState.update { it.copy(auth = it.auth.copy(errorMessage = AppStrings.t("err_invalid_code", lang))) }
            return
        }
        viewModelScope.launch {
            transientState.update { it.copy(auth = it.auth.copy(busy = true, errorMessage = null)) }
            repo.remote.verifyOtp(auth.identifier, code.trim(), auth.mode == AuthMode.EMAIL).fold(
                onSuccess = { session -> repo.completeRemoteSession(session); transientState.update { it.copy(auth = AuthUiState()) } },
                onFailure = { err -> transientState.update { it.copy(auth = it.auth.copy(busy = false, errorMessage = err.message)) } },
            )
        }
    }

    fun activateWithQr(code: String) {
        val lang = uiState.value.language
        if (!EgyptValidators.isValidQrActivationCode(code)) {
            transientState.update { it.copy(auth = it.auth.copy(errorMessage = AppStrings.t("err_invalid_qr", lang))) }
            return
        }
        viewModelScope.launch { repo.activateLocallyWithQr(code); transientState.update { it.copy(auth = AuthUiState()) } }
    }

    fun syncNow() = viewModelScope.launch {
        val lang = uiState.value.language
        transientState.update { it.copy(syncBusy = true) }
        val report = repo.syncPendingOperations()
        val msg = if (report.isOffline) AppStrings.t("sync_offline_saved", lang) else "${AppStrings.t("sync_done", lang)} (${report.syncedItems})"
        transientState.update { it.copy(syncBusy = false, snackbarMessage = msg) }
    }

    fun toggleLowDataMode() = viewModelScope.launch { repo.setDataSaver(!uiState.value.lowDataMode) }
    fun toggleStreakShield() = viewModelScope.launch { repo.toggleStreakShield(uiState.value.streakShieldActive) }
    fun completeRescueItem(questionId: String) = viewModelScope.launch { repo.completeRescueQuestionId(questionId) }

    fun recordQuizOutcome(questionId: String, correct: Boolean) = viewModelScope.launch {
        if (correct) repo.completeRescueQuestionId(questionId) else repo.addRescueQuestionId(questionId)
    }

    fun triggerParentReassurance() {
        val lang = uiState.value.language
        transientState.update {
            it.copy(reassurancePulseAtMillis = System.currentTimeMillis(), snackbarMessage = AppStrings.t("parent_reassure_title", lang))
        }
    }

    fun buildEncouragementMessage(lang: AppLanguage): String =
        KashkoolMessageBuilders.buildEncouragementMessage(uiState.value.students.firstOrNull(), lang)

    fun buildParentReportShareText(lang: AppLanguage): String =
        KashkoolMessageBuilders.buildParentReportShareText(uiState.value.students.firstOrNull(), uiState.value.attendance, lang)

    fun notifyMessageCopied() {
        transientState.update { it.copy(snackbarMessage = AppStrings.t("parent_cheer_copied", uiState.value.language)) }
    }

    fun toggleRushMode() { transientState.update { it.copy(rushModeEnabled = !it.rushModeEnabled) } }

    fun discreetAllowWithParentNotice(student: StudentEntity) = viewModelScope.launch {
        repo.recordQuickCheckIn(student, "sess-nokhba-today")
        val lang = uiState.value.language
        val name = if (lang == AppLanguage.AR) student.nameAr else student.nameEn
        transientState.update {
            it.copy(lastScanFeedback = ScanFeedback(name, "due"), snackbarMessage = AppStrings.t("discreet_due_done", lang))
        }
    }

    fun notifyQrCopied() {
        transientState.update { it.copy(snackbarMessage = AppStrings.t("student_qr_copied", uiState.value.language)) }
    }

    fun setAttendanceWindow(window: AttendanceWindow) {
        transientState.update { it.copy(attendanceWindow = window) }
    }

    fun setAttendanceChartMode(mode: AttendanceChartMode) {
        transientState.update { it.copy(attendanceChartMode = mode) }
    }

    fun setAttendanceGroupFilter(groupId: String?) {
        transientState.update { it.copy(attendanceGroupFilter = groupId) }
    }

    fun verifyGateQrToken(rawToken: String) {
        val trimmed = rawToken.trim()
        if (trimmed.startsWith("KSHS|") || trimmed.startsWith("KSHC|") || EgyptValidators.isValidQrActivationCode(trimmed)) {
            scanQrForAttendance(trimmed)
            return
        }
        val result = qrEngine.verifyToken(trimmed)
        transientState.update {
            it.copy(qrVerificationBanner = QrVerificationBanner(result.status, trimmed.take(28)))
        }
    }

    fun scanQrForAttendance(rawPayload: String) = viewModelScope.launch {
        val lang = uiState.value.language
        val result = repo.processAutomatedQrScan(rawPayload, qrEngine)
        val studentName = result.student?.let {
            if (lang == AppLanguage.AR) it.nameAr else it.nameEn
        }
        when (result.outcome) {
            QrCheckInOutcome.CHECKED_IN_VALID -> {
                val name = studentName ?: ""
                transientState.update {
                    it.copy(
                        scannerScanCount = it.scannerScanCount + 1,
                        lastScanFeedback = ScanFeedback(
                            studentName = name,
                            status = "valid",
                            detail = AppStrings.t("scan_valid", lang),
                        ),
                        qrVerificationBanner = QrVerificationBanner(QrVerifyStatus.VALID, result.tokenPreview),
                        snackbarMessage = if (lang == AppLanguage.AR) "تم تسجيل حضور $name" else "Checked in $name",
                    )
                }
            }
            QrCheckInOutcome.CHECKED_IN_DUE -> {
                val name = studentName ?: ""
                val dueFormatted = result.student?.let {
                    EgyptValidators.formatPiasters(it.dueBalancePiasters, lang.code)
                }.orEmpty()
                transientState.update {
                    it.copy(
                        scannerScanCount = it.scannerScanCount + 1,
                        lastScanFeedback = ScanFeedback(
                            studentName = name,
                            status = "due",
                            detail = "${AppStrings.t("due_balance", lang)}: $dueFormatted",
                        ),
                        qrVerificationBanner = QrVerificationBanner(QrVerifyStatus.VALID, result.tokenPreview),
                        snackbarMessage = if (lang == AppLanguage.AR) "تم حضور $name · متبقي $dueFormatted" else "$name checked in · Due $dueFormatted",
                    )
                }
            }
            QrCheckInOutcome.ALREADY_CHECKED_IN -> {
                val name = studentName ?: ""
                transientState.update {
                    it.copy(
                        lastScanFeedback = ScanFeedback(
                            studentName = name,
                            status = "already",
                            detail = AppStrings.t("qr_already_checked_in", lang),
                            alreadyCheckedIn = true,
                        ),
                        qrVerificationBanner = QrVerificationBanner(QrVerifyStatus.VALID, result.tokenPreview),
                        snackbarMessage = "$name · ${AppStrings.t("qr_already_checked_in", lang)}",
                    )
                }
            }
            QrCheckInOutcome.BLOCKED -> {
                val name = studentName ?: ""
                transientState.update {
                    it.copy(
                        lastScanFeedback = ScanFeedback(
                            studentName = name,
                            status = "blocked",
                            detail = AppStrings.t("scan_blocked", lang),
                        ),
                        qrVerificationBanner = QrVerificationBanner(QrVerifyStatus.INVALID, result.tokenPreview),
                        snackbarMessage = "$name · ${AppStrings.t("scan_blocked", lang)}",
                    )
                }
            }
            QrCheckInOutcome.SESSION_GATE_VALID -> {
                transientState.update {
                    it.copy(
                        qrVerificationBanner = QrVerificationBanner(QrVerifyStatus.VALID, result.tokenPreview),
                        snackbarMessage = AppStrings.t("qr_result_valid", lang),
                    )
                }
            }
            QrCheckInOutcome.EXPIRED_TOKEN -> {
                transientState.update {
                    it.copy(
                        lastScanFeedback = ScanFeedback(
                            studentName = AppStrings.t("qr_result_expired", lang),
                            status = "due",
                            detail = result.tokenPreview,
                        ),
                        qrVerificationBanner = QrVerificationBanner(QrVerifyStatus.EXPIRED, result.tokenPreview),
                        snackbarMessage = AppStrings.t("qr_result_expired", lang),
                    )
                }
            }
            QrCheckInOutcome.STUDENT_NOT_FOUND -> {
                transientState.update {
                    it.copy(
                        lastScanFeedback = ScanFeedback(
                            studentName = AppStrings.t("qr_student_not_found", lang),
                            status = "blocked",
                            detail = result.tokenPreview,
                        ),
                        qrVerificationBanner = QrVerificationBanner(QrVerifyStatus.INVALID, result.tokenPreview),
                        snackbarMessage = AppStrings.t("qr_student_not_found", lang),
                    )
                }
            }
            QrCheckInOutcome.INVALID_TOKEN -> {
                transientState.update {
                    it.copy(
                        lastScanFeedback = ScanFeedback(
                            studentName = AppStrings.t("qr_result_invalid", lang),
                            status = "blocked",
                            detail = result.tokenPreview,
                        ),
                        qrVerificationBanner = QrVerificationBanner(QrVerifyStatus.INVALID, result.tokenPreview),
                        snackbarMessage = AppStrings.t("qr_result_invalid", lang),
                    )
                }
            }
        }
    }

    fun addWalkInStudent(name: String, phone: String, groupId: String, initialTopUpEgp: String) {
        if (name.isBlank() || groupId.isBlank()) return
        val topUp = EgyptValidators.egpStringToPiasters(initialTopUpEgp) ?: 0L
        val lang = uiState.value.language
        viewModelScope.launch {
            repo.addWalkInStudent(name, phone, groupId, topUp)
            transientState.update { it.copy(snackbarMessage = AppStrings.t("walkin_added", lang)) }
        }
    }

    fun toggleStudentBlocked(student: StudentEntity) = viewModelScope.launch {
        repo.toggleStudentBlocked(student)
    }

    fun addResource(name: String, type: ResourceType, costEgp: String) {
        if (name.isBlank()) return
        val costPiasters = EgyptValidators.egpStringToPiasters(costEgp) ?: 0L
        viewModelScope.launch { repo.addResource(name, type, costPiasters) }
    }

    fun cycleResourceStatus(resource: Resource) = viewModelScope.launch {
        repo.cycleResourceStatus(resource)
    }

    fun updateStudyBudgetMinutes(minutes: Int) {
        transientState.update { it.copy(studyBudgetMinutes = minutes.coerceIn(10, 60)) }
    }

    fun executeOrSeatRebalance() = viewModelScope.launch {
        val alloc = uiState.value.operatingReport?.groupAllocation ?: return@launch
        var totalShifted = 0
        if (alloc.transferPlans.isNotEmpty()) {
            alloc.transferPlans.forEach { plan ->
                totalShifted += repo.executeOrSeatRebalance(plan.fromGroupId, plan.toGroupId, plan.seatsToMove)
            }
        } else {
            val fromId = alloc.bottleneckGroupId ?: return@launch
            val toId = alloc.slackGroupId ?: return@launch
            totalShifted = repo.executeOrSeatRebalance(fromId, toId, alloc.recommendedSeatShift)
        }
        if (totalShifted > 0) {
            transientState.update {
                it.copy(snackbarMessage = AppStrings.t("rebalance_done", uiState.value.language))
            }
        }
    }

    fun updateSettlementControls(splitPercent: Int, assistantWagesEgp: Int) = viewModelScope.launch {
        repo.saveSettlementSettings(splitPercent, assistantWagesEgp.toLong() * 100L)
    }

    fun addPaymentChannel(name: String, type: String, accountRef: String, feeEgp: String) {
        if (name.isBlank() || accountRef.isBlank()) return
        val feePiasters = EgyptValidators.egpStringToPiasters(feeEgp) ?: 0L
        viewModelScope.launch { repo.addPaymentChannel(name, type, accountRef, feePiasters) }
    }

    fun toggleChannelActive(channel: PaymentChannelEntity) = viewModelScope.launch {
        repo.toggleChannelActive(channel.id, !channel.isActive)
    }

    fun submitCenterPlanUpgrade(plan: CenterPlanTier, channel: PaymentChannelEntity, senderRef: String) = viewModelScope.launch {
        val lang = uiState.value.language
        val planName = if (lang == AppLanguage.AR) plan.nameAr else plan.nameEn
        repo.submitCenterSubscription(plan.id, planName, plan.monthlyPiasters, channel, senderRef.trim(), lang)
        transientState.update { it.copy(snackbarMessage = AppStrings.t("plan_submitted", lang)) }
    }

    fun generateQrForStudent(student: StudentEntity) = viewModelScope.launch {
        val code = repo.generateStudentActivationCode(student)
        val studentName = if (uiState.value.language == AppLanguage.AR) student.nameAr else student.nameEn
        transientState.update { it.copy(generatedQrCode = code, generatedQrStudentName = studentName) }
    }

    fun dismissGeneratedQr() {
        transientState.update { it.copy(generatedQrCode = null, generatedQrStudentName = null) }
    }

    fun compressAndAttachReceipt(uri: Uri) = viewModelScope.launch {
        val lang = uiState.value.language
        transientState.update { it.copy(receiptCompressing = true, receiptScanState = ReceiptScanUiState.Idle) }
        ImageCompressor.compressReceiptUri(getApplication(), uri).fold(
            onSuccess = { compressed -> transientState.update { it.copy(receiptCompressing = false, compressedReceipt = compressed) } },
            onFailure = { transientState.update { it.copy(receiptCompressing = false, snackbarMessage = AppStrings.t("compression_failed", lang)) } },
        )
    }

    fun clearCompressedReceipt() {
        transientState.update { it.copy(compressedReceipt = null, receiptScanState = ReceiptScanUiState.Idle) }
    }

    fun scanAttachedReceipt() {
        val compressed = uiState.value.compressedReceipt ?: return
        val lang = uiState.value.language
        transientState.update { it.copy(receiptScanState = ReceiptScanUiState.Loading) }
        viewModelScope.launch {
            val bitmap = ImageCompressor.decodeFileScaled(compressed.filePath).getOrElse { err ->
                transientState.update {
                    it.copy(receiptScanState = ReceiptScanUiState.Error(err.localizedMessage ?: AppStrings.t("scan_receipt_error", lang)))
                }
                return@launch
            }
            try {
                aiToolkit.scanPaymentReceipt(bitmap, lang).fold(
                    onSuccess = { result ->
                        transientState.update { it.copy(receiptScanState = ReceiptScanUiState.Success(result)) }
                    },
                    onFailure = { err ->
                        transientState.update {
                            it.copy(receiptScanState = ReceiptScanUiState.Error(err.localizedMessage ?: AppStrings.t("scan_receipt_error", lang)))
                        }
                    },
                )
            } finally {
                bitmap.recycle()
            }
        }
    }

    fun enterOfflineWorkspace(role: UserRole) = viewModelScope.launch {
        val label = when (role) {
            UserRole.STUDENT -> "+201012345678 · أحمد محمد"
            UserRole.SECRETARY -> "مكتب السكرتارية · سنتر النخبة"
            UserRole.TEACHER -> "أ. طارق عزت · الرياضيات والفيزياء"
            UserRole.PARENT -> "ولي أمر · أحمد محمد"
        }
        repo.signInWorkspace(role, label)
    }

    fun switchRole(role: UserRole) = viewModelScope.launch {
        repo.setActiveRole(role)
        transientState.update { it.copy(aiBriefingState = AiBriefingState.Idle) }
    }

    fun signOut() = viewModelScope.launch { repo.signOut() }

    fun checkInStudent(student: StudentEntity) = viewModelScope.launch {
        val status = repo.recordQuickCheckIn(student, "sess-nokhba-today")
        val name = if (uiState.value.language == AppLanguage.AR) student.nameAr else student.nameEn
        transientState.update { it.copy(lastScanFeedback = ScanFeedback(studentName = name, status = status)) }
    }

    fun recordCashDeskEntry(student: StudentEntity, kind: LedgerKind, amountEgpText: String, note: String) {
        val piasters = EgyptValidators.egpStringToPiasters(amountEgpText) ?: return
        viewModelScope.launch {
            repo.appendFinancialEntry(
                student = student,
                kind = kind,
                amountPiasters = piasters,
                note = note.ifBlank { AppStrings.ledgerKindLabel(kind.key, uiState.value.language) },
                role = uiState.value.activeRole,
            )
            val msg = if (uiState.value.language == AppLanguage.AR) {
                "تم تسجيل ${EgyptValidators.formatPiasters(piasters, "ar")} بنجاح"
            } else {
                "Recorded ${EgyptValidators.formatPiasters(piasters, "en")} to ledger"
            }
            transientState.update { it.copy(snackbarMessage = msg) }
        }
    }

    fun voidLedgerEntry(entryId: String, reason: String) {
        if (reason.isBlank()) return
        viewModelScope.launch {
            repo.voidLedgerEntry(entryId, reason.trim(), uiState.value.activeRole)
            val lang = uiState.value.language
            transientState.update {
                it.copy(snackbarMessage = if (lang == AppLanguage.AR) "تم تسجيل عكس القيد في الدفتر" else "Void entry appended")
            }
        }
    }

    fun executeDailySettlement(netPayoutPiasters: Long, attendedCount: Int) = viewModelScope.launch {
        repo.recordDailySettlement(netPayoutPiasters, "تسوية يومية تلقائية · $attendedCount حضور")
        transientState.update { it.copy(snackbarMessage = AppStrings.t("settlement_done", uiState.value.language)) }
    }

    fun createGroup(name: String, schedule: String, capacityText: String, priceEgpText: String) {
        if (name.isBlank()) return
        val capacity = capacityText.trim().toIntOrNull() ?: 40
        val pricePiasters = EgyptValidators.egpStringToPiasters(priceEgpText) ?: 8000L
        viewModelScope.launch {
            repo.addGroup(name.trim(), schedule.trim().ifBlank { "السبت والثلاثاء 4 م" }, capacity, pricePiasters)
        }
    }

    fun submitPaymentReceipt(channel: PaymentChannelEntity, amountEgpText: String, senderRef: String, receiptUri: String?) {
        val piasters = EgyptValidators.egpStringToPiasters(amountEgpText) ?: return
        if (senderRef.isBlank()) return
        val lang = uiState.value.language
        viewModelScope.launch {
            repo.submitPaymentReceipt(channel, piasters, senderRef.trim(), receiptUri, lang)
            transientState.update {
                it.copy(snackbarMessage = if (lang == AppLanguage.AR) "تم إرسال الإيصال للمراجعة" else "Receipt submitted")
            }
        }
    }

    fun approveSubmission(submission: PaymentSubmissionEntity) = viewModelScope.launch { repo.approveSubmission(submission) }

    fun rejectSubmission(submission: PaymentSubmissionEntity, reason: String) {
        if (reason.isBlank()) return
        viewModelScope.launch { repo.rejectSubmission(submission, reason.trim()) }
    }

    fun openLecture(unit: CourseUnit, lang: AppLanguage) {
        val title = if (lang == AppLanguage.AR) unit.titleAr else unit.titleEn
        transientState.update {
            it.copy(
                activeLectureId = unit.id,
                activeLectureTitle = title,
                revisionDeckState = RevisionDeckUiState.Idle,
            )
        }
    }

    fun closeLecture() {
        transientState.update {
            it.copy(
                activeLectureId = null,
                activeLectureTitle = null,
                revisionDeckState = RevisionDeckUiState.Idle,
            )
        }
    }

    fun generateLessonRevisionDeck(lessonTitle: String, lessonSummary: String) {
        val lang = uiState.value.language
        transientState.update { it.copy(revisionDeckState = RevisionDeckUiState.Loading) }
        viewModelScope.launch {
            aiToolkit.generateLessonRevisionDeck(lessonTitle, lessonSummary, lang).fold(
                onSuccess = { deck ->
                    transientState.update { it.copy(revisionDeckState = RevisionDeckUiState.Success(deck)) }
                },
                onFailure = { err ->
                    transientState.update {
                        it.copy(revisionDeckState = RevisionDeckUiState.Error(err.localizedMessage ?: AppStrings.t("revision_deck_error", lang)))
                    }
                },
            )
        }
    }

    fun markActiveLectureCompleted() = viewModelScope.launch {
        val id = uiState.value.activeLectureId ?: return@launch
        repo.markCourseCompleted(id)
        transientState.update {
            it.copy(snackbarMessage = AppStrings.t("lesson_completed_badge", uiState.value.language))
        }
    }

    fun generateAdaptiveQuiz(lessonTitle: String) {
        val lang = uiState.value.language
        transientState.update {
            it.copy(adaptiveQuizBusy = true, adaptiveQuizError = null, adaptiveQuizTopic = lessonTitle)
        }
        viewModelScope.launch {
            aiAdvisor.generateAdaptiveQuiz(lessonTitle, lang).fold(
                onSuccess = { generated ->
                    transientState.update {
                        it.copy(adaptiveQuizBusy = false, adaptiveQuizQuestions = generated, adaptiveQuizError = null)
                    }
                },
                onFailure = { err ->
                    transientState.update {
                        it.copy(
                            adaptiveQuizBusy = false,
                            adaptiveQuizError = err.localizedMessage ?: "Adaptive quiz unavailable",
                        )
                    }
                },
            )
        }
    }

    fun resetAdaptiveQuiz() {
        transientState.update {
            it.copy(adaptiveQuizQuestions = null, adaptiveQuizTopic = null, adaptiveQuizError = null)
        }
    }

    fun askStudyAssistant(
        prompt: String,
        subject: String = "الرياضيات والفيزياء",
        photoUri: Uri? = null,
    ) {
        val currentState = uiState.value
        val lang = currentState.language
        val clean = prompt.trim().ifBlank {
            if (photoUri != null) {
                if (lang == AppLanguage.AR) "اشرح وحل هذه المسألة خطوة بخطوة" else "Solve and explain this problem step by step"
            } else {
                return
            }
        }
        val report = currentState.operatingReport ?: return
        val priorHistory = currentState.assistantMessages

        transientState.update {
            it.copy(
                assistantMessages = it.assistantMessages + AssistantMessage(
                    fromUser = true,
                    text = clean,
                    attachedPhotoUri = photoUri?.toString(),
                ),
                assistantBusy = true,
                assistantError = null,
            )
        }

        viewModelScope.launch {
            val problemBitmap = photoUri?.let { uri ->
                ImageCompressor.decodeScaledBitmap(getApplication(), uri).getOrNull()
            }
            try {
                var addedStreamBubble = false
                aiToolkit.streamMultiTurnStudyOrPhoto(
                    prompt = clean,
                    history = priorHistory,
                    problemBitmap = problemBitmap,
                    role = currentState.activeRole,
                    subject = subject,
                    report = report,
                    lang = lang,
                ).collect { accumulated ->
                    transientState.update { tr ->
                        val updatedList = if (!addedStreamBubble) {
                            addedStreamBubble = true
                            tr.assistantMessages + AssistantMessage(fromUser = false, text = accumulated)
                        } else {
                            tr.assistantMessages.dropLast(1) + AssistantMessage(fromUser = false, text = accumulated)
                        }
                        tr.copy(assistantMessages = updatedList)
                    }
                }
                val followUpChips = if (lang == AppLanguage.AR) {
                    listOf("اشرح الخطوة السابقة ببساطة", "أعطني مسألة تدريب")
                } else {
                    listOf("Explain the last step simply", "Give me a practice problem")
                }
                transientState.update { tr ->
                    val last = tr.assistantMessages.lastOrNull()
                    val finalized = if (last != null && !last.fromUser) {
                        tr.assistantMessages.dropLast(1) + last.copy(suggestions = followUpChips)
                    } else tr.assistantMessages
                    tr.copy(assistantMessages = finalized, assistantBusy = false)
                }
            } catch (e: TimeoutCancellationException) {
                Log.e(TAG, "Study assistant stream timed out", e)
                transientState.update {
                    it.copy(
                        assistantBusy = false,
                        assistantError = if (lang == AppLanguage.AR) "انتهت مهلة الاتصال (60 ثانية). حاول مجدداً." else "Timed out after 60s. Please retry.",
                    )
                }
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                Log.e(TAG, "Study assistant stream failed", e)
                transientState.update {
                    it.copy(assistantBusy = false, assistantError = e.localizedMessage ?: "Assistant unavailable")
                }
            } finally {
                problemBitmap?.recycle()
            }
        }
    }

    fun requestOperationalBriefing() {
        val currentState = uiState.value
        val report = currentState.operatingReport ?: return
        transientState.update { it.copy(aiBriefingState = AiBriefingState.Loading) }
        viewModelScope.launch {
            aiAdvisor.generateOperationalBriefing(report, currentState.activeRole, currentState.language).fold(
                onSuccess = { briefing -> transientState.update { it.copy(aiBriefingState = AiBriefingState.Success(briefing)) } },
                onFailure = { err -> transientState.update { it.copy(aiBriefingState = AiBriefingState.Error(err.localizedMessage ?: "Briefing failed")) } },
            )
        }
    }

    fun evaluateTeacherPerformance() {
        val currentState = uiState.value
        val report = currentState.operatingReport ?: return
        val lang = currentState.language
        val teacherLabel = if (lang == AppLanguage.AR) "أ. طارق عزت · سنتر النخبة" else "Mr. Tarek Ezzat · Al-Nokhba Center"
        val avgMastery = currentState.students.takeIf { it.isNotEmpty() }?.map { it.masteryPercent }?.average()?.toInt() ?: 85
        val pendingCount = currentState.submissions.count { it.status == SubmissionStatus.PENDING.key }

        transientState.update { it.copy(evaluationState = EvaluationUiState.Loading) }
        viewModelScope.launch {
            aiAdvisor.evaluateTeacherPerformance(
                teacherLabel = teacherLabel,
                report = report,
                studentCount = currentState.students.size,
                avgStudentMastery = avgMastery,
                pendingReceiptsCount = pendingCount,
                lang = lang,
            ).fold(
                onSuccess = { evaluation ->
                    repo.saveEvaluation(evaluation)
                    transientState.update { it.copy(evaluationState = EvaluationUiState.Success(evaluation)) }
                },
                onFailure = { err ->
                    transientState.update {
                        it.copy(evaluationState = EvaluationUiState.Error(err.localizedMessage ?: "Evaluation failed"))
                    }
                },
            )
        }
    }

    fun evaluateStudentPerformance(studentId: String? = null) {
        val currentState = uiState.value
        val lang = currentState.language
        val targetStudent = currentState.students.firstOrNull { it.id == studentId }
            ?: currentState.students.firstOrNull()
            ?: return
        val groupName = currentState.groups.firstOrNull { it.id == targetStudent.groupId }?.let {
            if (lang == AppLanguage.AR) it.nameAr else it.nameEn
        } ?: if (lang == AppLanguage.AR) "المجموعة الأساسية" else "Main Group"
        val attendedSessionsCount = currentState.attendance.count { it.studentId == targetStudent.id }
        val weakTopics = currentState.rescueItems.map { if (lang == AppLanguage.AR) it.topicAr else it.topicEn }

        transientState.update { it.copy(evaluationState = EvaluationUiState.Loading) }
        viewModelScope.launch {
            aiAdvisor.evaluateStudentPerformance(
                student = targetStudent,
                groupName = groupName,
                attendedSessionsCount = attendedSessionsCount,
                completedLessonsCount = currentState.completedCourseIds.size,
                weakTopicTitles = weakTopics,
                lang = lang,
            ).fold(
                onSuccess = { evaluation ->
                    repo.saveEvaluation(evaluation)
                    transientState.update { it.copy(evaluationState = EvaluationUiState.Success(evaluation)) }
                },
                onFailure = { err ->
                    transientState.update {
                        it.copy(evaluationState = EvaluationUiState.Error(err.localizedMessage ?: "Evaluation failed"))
                    }
                },
            )
        }
    }

    fun buildEvaluationShareText(evaluation: PerformanceEvaluationEntity, lang: AppLanguage): String =
        KashkoolMessageBuilders.buildEvaluationShareText(evaluation, lang)

    fun refreshParentWeeklyDigest() {
        val currentState = uiState.value
        val student = currentState.students.firstOrNull() ?: return
        val lang = currentState.language
        val attendanceCount = currentState.attendance.count { it.studentId == student.id }
        val weakTopics = currentState.rescueItems.map { if (lang == AppLanguage.AR) it.topicAr else it.topicEn }
        val orProfile = currentState.operatingReport?.studentProfiles?.get(student.id)
        transientState.update { it.copy(parentDigestState = ParentDigestUiState.Loading) }
        viewModelScope.launch {
            aiToolkit.composeParentWeeklyDigest(student, attendanceCount, weakTopics, lang, orProfile).fold(
                onSuccess = { digest ->
                    transientState.update { it.copy(parentDigestState = ParentDigestUiState.Success(digest)) }
                },
                onFailure = { err ->
                    transientState.update {
                        it.copy(parentDigestState = ParentDigestUiState.Error(err.localizedMessage ?: AppStrings.t("parent_digest_error", lang)))
                    }
                },
            )
        }
    }

    fun composeSecretaryNotice(student: StudentEntity) {
        val currentState = uiState.value
        val lang = currentState.language
        val studentName = if (lang == AppLanguage.AR) student.nameAr else student.nameEn
        val groupName = currentState.groups.firstOrNull { it.id == student.groupId }?.let {
            if (lang == AppLanguage.AR) it.nameAr else it.nameEn
        } ?: if (lang == AppLanguage.AR) "المجموعة الأساسية" else "Main Group"
        val orProfile = currentState.operatingReport?.studentProfiles?.get(student.id)
        transientState.update { it.copy(secretaryNoticeState = SecretaryNoticeUiState.Loading(studentName)) }
        viewModelScope.launch {
            aiToolkit.composeSecretaryNotice(student, groupName, lang, orProfile).fold(
                onSuccess = { draft ->
                    transientState.update { it.copy(secretaryNoticeState = SecretaryNoticeUiState.Success(studentName, draft)) }
                },
                onFailure = { err ->
                    transientState.update {
                        it.copy(
                            secretaryNoticeState = SecretaryNoticeUiState.Error(
                                studentName = studentName,
                                message = err.localizedMessage ?: AppStrings.t("draft_notice_error", lang),
                            )
                        )
                    }
                },
            )
        }
    }

    fun dismissSecretaryNotice() {
        transientState.update { it.copy(secretaryNoticeState = SecretaryNoticeUiState.Idle) }
    }

    fun generateTeacherLessonPlan(group: GroupEntity) {
        val currentState = uiState.value
        val lang = currentState.language
        val avgMastery = currentState.students.takeIf { it.isNotEmpty() }?.map { it.masteryPercent }?.average()?.toInt() ?: 85
        transientState.update { it.copy(teacherPlanState = TeacherPlanUiState.Loading) }
        viewModelScope.launch {
            aiToolkit.generateTeacherLessonPlan(group, avgMastery, lang, currentState.operatingReport).fold(
                onSuccess = { plan ->
                    transientState.update { it.copy(teacherPlanState = TeacherPlanUiState.Success(plan)) }
                },
                onFailure = { err ->
                    transientState.update {
                        it.copy(teacherPlanState = TeacherPlanUiState.Error(err.localizedMessage ?: AppStrings.t("teacher_plan_error", lang)))
                    }
                },
            )
        }
    }

    fun clearSnackbar() { transientState.update { it.copy(snackbarMessage = null) } }

    fun buildThermalReceipt(lang: AppLanguage): String =
        KashkoolMessageBuilders.buildThermalReceipt(uiState.value.shiftReconciliation, uiState.value.attendance, lang)
}
