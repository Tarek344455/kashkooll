package com.dig.kashkool.ui.viewmodel

import android.app.Application
import android.net.Uri
import android.util.Log
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import com.dig.kashkool.core.firebase.AiOperationsAdvisor
import com.dig.kashkool.core.l10n.AppLanguage
import com.dig.kashkool.core.l10n.AppStrings
import com.dig.kashkool.core.or.OperationsResearchEngine
import com.dig.kashkool.core.or.StudyCandidate
import com.dig.kashkool.core.utils.CompressedReceiptResult
import com.dig.kashkool.core.utils.DynamicQrEngine
import com.dig.kashkool.core.utils.EgyptValidators
import com.dig.kashkool.core.utils.ImageCompressor
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

    fun verifyGateQrToken(rawToken: String) {
        val result = qrEngine.verifyToken(rawToken)
        transientState.update {
            it.copy(qrVerificationBanner = QrVerificationBanner(result.status, rawToken.trim().take(28)))
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

    fun executeOrSeatRebalance() = viewModelScope.launch {
        val alloc = uiState.value.operatingReport?.groupAllocation ?: return@launch
        val fromId = alloc.bottleneckGroupId ?: return@launch
        val toId = alloc.slackGroupId ?: return@launch
        val shifted = repo.executeOrSeatRebalance(fromId, toId, alloc.recommendedSeatShift)
        if (shifted > 0) {
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
        transientState.update { it.copy(receiptCompressing = true) }
        ImageCompressor.compressReceiptUri(getApplication(), uri).fold(
            onSuccess = { compressed -> transientState.update { it.copy(receiptCompressing = false, compressedReceipt = compressed) } },
            onFailure = { transientState.update { it.copy(receiptCompressing = false, snackbarMessage = AppStrings.t("compression_failed", lang)) } },
        )
    }

    fun clearCompressedReceipt() { transientState.update { it.copy(compressedReceipt = null) } }

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
        transientState.update { it.copy(activeLectureId = unit.id, activeLectureTitle = title) }
    }

    fun closeLecture() {
        transientState.update { it.copy(activeLectureId = null, activeLectureTitle = null) }
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

    fun askStudyAssistant(prompt: String, subject: String = "الرياضيات والفيزياء") {
        val clean = prompt.trim()
        if (clean.isEmpty()) return
        val currentState = uiState.value
        val report = currentState.operatingReport ?: return
        val lang = currentState.language

        transientState.update {
            it.copy(
                assistantMessages = it.assistantMessages + AssistantMessage(fromUser = true, text = clean),
                assistantBusy = true,
                assistantError = null,
            )
        }

        viewModelScope.launch {
            try {
                var addedStreamBubble = false
                aiAdvisor.streamStudyGuidance(clean, currentState.activeRole, subject, report, lang).collect { accumulated ->
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
                    listOf("أعطني مسألة تدريب", "لخص القانون الأساسي")
                } else {
                    listOf("Give me a practice problem", "Summarize the key formula")
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

    fun clearSnackbar() { transientState.update { it.copy(snackbarMessage = null) } }

    fun buildThermalReceipt(lang: AppLanguage): String =
        KashkoolMessageBuilders.buildThermalReceipt(uiState.value.shiftReconciliation, uiState.value.attendance, lang)
}
