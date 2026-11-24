package com.dig.kashkool.data.repository

import android.content.Context
import android.net.Uri
import android.os.Build
import android.provider.Settings
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.stringPreferencesKey
import androidx.datastore.preferences.preferencesDataStore
import com.dig.kashkool.core.l10n.AppLanguage
import com.dig.kashkool.core.utils.EgyptValidators
import com.dig.kashkool.data.local.AppDatabase
import com.dig.kashkool.data.local.AttendanceEntity
import com.dig.kashkool.data.local.AvailabilityStatus
import com.dig.kashkool.data.local.GroupEntity
import com.dig.kashkool.data.local.KashkoolSeeds
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
import com.dig.kashkool.data.remote.RemoteSession
import com.dig.kashkool.data.remote.SupabaseApiClient
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.map
import java.io.File
import java.util.UUID

private val Context.kashkoolPrefs by preferencesDataStore(name = "kashkool_prefs")

data class SyncReport(
    val syncedItems: Int,
    val failedItems: Int,
    val isOffline: Boolean,
)

class KashkoolRepository(
    private val context: Context,
    private val db: AppDatabase = AppDatabase.getInstance(context),
    val remote: SupabaseApiClient = SupabaseApiClient(),
) {
    private val dao = db.kashkoolDao()

    private object Keys {
        val LANGUAGE = stringPreferencesKey("language")
        val ROLE = stringPreferencesKey("active_role")
        val USER_LABEL = stringPreferencesKey("user_label")
        val SIGNED_IN = stringPreferencesKey("signed_in")
        val ACCESS_TOKEN = stringPreferencesKey("access_token")
        val USER_ID = stringPreferencesKey("user_id")
        val TENANT_ID = stringPreferencesKey("tenant_id")
        val DATA_SAVER = stringPreferencesKey("data_saver")
        val STREAK_SHIELD = stringPreferencesKey("streak_shield")
        val CENTER_PLAN_ID = stringPreferencesKey("center_plan_id")
        val RESCUE_IDS = stringPreferencesKey("rescue_ids")
        val SETTLEMENT_SPLIT_PCT = stringPreferencesKey("settlement_split_pct")
        val ASSISTANT_WAGES_PIASTERS = stringPreferencesKey("assistant_wages_piasters")
        val COMPLETED_COURSES = stringPreferencesKey("completed_courses")
    }

    val languageFlow: Flow<AppLanguage> = context.kashkoolPrefs.data.map { prefs ->
        if (prefs[Keys.LANGUAGE] == AppLanguage.EN.code) AppLanguage.EN else AppLanguage.AR
    }
    val roleFlow: Flow<UserRole> = context.kashkoolPrefs.data.map { prefs ->
        UserRole.entries.firstOrNull { it.key == prefs[Keys.ROLE] } ?: UserRole.STUDENT
    }
    val signedInFlow: Flow<Boolean> = context.kashkoolPrefs.data.map { it[Keys.SIGNED_IN] == "true" }
    val userLabelFlow: Flow<String> = context.kashkoolPrefs.data.map { it[Keys.USER_LABEL] ?: "+201012345678" }
    val dataSaverFlow: Flow<Boolean> = context.kashkoolPrefs.data.map { it[Keys.DATA_SAVER] != "false" }
    val streakShieldFlow: Flow<Boolean> = context.kashkoolPrefs.data.map { it[Keys.STREAK_SHIELD] == "true" }
    val centerPlanIdFlow: Flow<String> = context.kashkoolPrefs.data.map { it[Keys.CENTER_PLAN_ID] ?: "plan-pro" }
    val rescueIdsFlow: Flow<Set<String>> = context.kashkoolPrefs.data.map { prefs ->
        (prefs[Keys.RESCUE_IDS] ?: "q2").split(",").map { it.trim() }.filter { it.isNotEmpty() }.toSet()
    }
    val settlementSplitPercentFlow: Flow<Int> = context.kashkoolPrefs.data.map { prefs ->
        prefs[Keys.SETTLEMENT_SPLIT_PCT]?.toIntOrNull()?.coerceIn(5, 50) ?: 20
    }
    val assistantWagesPiastersFlow: Flow<Long> = context.kashkoolPrefs.data.map { prefs ->
        prefs[Keys.ASSISTANT_WAGES_PIASTERS]?.toLongOrNull()?.coerceIn(0L, 100_000L) ?: 15000L
    }
    val completedCourseIdsFlow: Flow<Set<String>> = context.kashkoolPrefs.data.map { prefs ->
        (prefs[Keys.COMPLETED_COURSES] ?: "").split(",").map { it.trim() }.filter { it.isNotEmpty() }.toSet()
    }

    val groupsFlow: Flow<List<GroupEntity>> = dao.observeGroups()
    val studentsFlow: Flow<List<StudentEntity>> = dao.observeStudents()
    val attendanceFlow: Flow<List<AttendanceEntity>> = dao.observeAttendance()
    val ledgerFlow: Flow<List<LedgerEntryEntity>> = dao.observeLedgerEntries()
    val activeChannelsFlow: Flow<List<PaymentChannelEntity>> = dao.observeActiveChannels()
    val allChannelsFlow: Flow<List<PaymentChannelEntity>> = dao.observeAllChannels()
    val submissionsFlow: Flow<List<PaymentSubmissionEntity>> = dao.observeSubmissions()
    val resourcesFlow: Flow<List<Resource>> = dao.observeResources()
    val evaluationsFlow: Flow<List<PerformanceEvaluationEntity>> = dao.observeEvaluations()

    val pendingSyncCountFlow: Flow<Int> = combine(
        groupsFlow,
        attendanceFlow,
        ledgerFlow,
        submissionsFlow,
        resourcesFlow,
    ) { groups, attendance, ledger, submissions, resources ->
        groups.count { it.syncStatus == "pending" } +
            attendance.count { it.syncStatus == "pending" } +
            ledger.count { it.syncStatus == "pending" } +
            submissions.count { it.syncStatus == "pending" } +
            resources.count { it.syncStatus == "pending" }
    }

    suspend fun setLanguage(language: AppLanguage) {
        context.kashkoolPrefs.edit { it[Keys.LANGUAGE] = language.code }
    }

    suspend fun setDataSaver(enabled: Boolean) {
        context.kashkoolPrefs.edit { it[Keys.DATA_SAVER] = enabled.toString() }
    }

    suspend fun toggleStreakShield(currentlyActive: Boolean) {
        context.kashkoolPrefs.edit { it[Keys.STREAK_SHIELD] = (!currentlyActive).toString() }
    }

    suspend fun saveSettlementSettings(splitPercent: Int, assistantWagesPiasters: Long) {
        context.kashkoolPrefs.edit {
            it[Keys.SETTLEMENT_SPLIT_PCT] = splitPercent.coerceIn(5, 50).toString()
            it[Keys.ASSISTANT_WAGES_PIASTERS] = assistantWagesPiasters.coerceIn(0L, 100_000L).toString()
        }
    }

    suspend fun markCourseCompleted(courseId: String) {
        var addedNew = false
        context.kashkoolPrefs.edit { prefs ->
            val current = (prefs[Keys.COMPLETED_COURSES] ?: "")
                .split(",").map { it.trim() }.filter { it.isNotEmpty() }.toMutableSet()
            addedNew = current.add(courseId)
            prefs[Keys.COMPLETED_COURSES] = current.joinToString(",")
        }
        if (addedNew) {
            dao.getStudentById("stu-1")?.let { student ->
                dao.upsertStudent(student.copy(masteryPercent = (student.masteryPercent + 3).coerceAtMost(100)))
            }
        }
    }

    suspend fun addRescueQuestionId(questionId: String) {
        context.kashkoolPrefs.edit { prefs ->
            val current = (prefs[Keys.RESCUE_IDS] ?: "q2")
                .split(",").map { it.trim() }.filter { it.isNotEmpty() }.toMutableSet()
            current.add(questionId)
            prefs[Keys.RESCUE_IDS] = current.joinToString(",")
        }
    }

    suspend fun completeRescueQuestionId(questionId: String) {
        context.kashkoolPrefs.edit { prefs ->
            val current = (prefs[Keys.RESCUE_IDS] ?: "q2")
                .split(",").map { it.trim() }.filter { it.isNotEmpty() }.toMutableSet()
            current.remove(questionId)
            prefs[Keys.RESCUE_IDS] = current.joinToString(",")
        }
    }

    suspend fun submitCenterSubscription(
        planId: String,
        planName: String,
        amountPiasters: Long,
        channel: PaymentChannelEntity,
        senderRef: String,
        lang: AppLanguage,
    ) {
        dao.upsertSubmission(
            PaymentSubmissionEntity(
                id = "plan-sub-$planId-${UUID.randomUUID()}",
                studentId = "center-owner",
                studentNameAr = "اشتراك سنتر النخبة · $planName",
                studentNameEn = "Center Subscription · $planName",
                channelId = channel.id,
                channelName = if (lang == AppLanguage.AR) channel.nameAr else channel.nameEn,
                amountPiasters = amountPiasters,
                senderReference = senderRef,
                receiptUri = null,
                status = SubmissionStatus.PENDING.key,
                createdAtMillis = System.currentTimeMillis(),
                syncStatus = "pending",
            )
        )
    }

    suspend fun signInWorkspace(role: UserRole, identifier: String) {
        context.kashkoolPrefs.edit {
            it[Keys.ROLE] = role.key
            it[Keys.USER_LABEL] = identifier
            it[Keys.SIGNED_IN] = "true"
        }
    }

    suspend fun completeRemoteSession(session: RemoteSession) {
        val profile = remote.fetchProfile(session.accessToken, session.userId).getOrNull()
        val resolvedRole = when (profile?.role) {
            "teacher" -> UserRole.TEACHER
            "centerAdmin", "assistant", "supervisor" -> UserRole.SECRETARY
            "parent" -> UserRole.PARENT
            else -> UserRole.STUDENT
        }
        val tenantId = profile?.tenantId ?: "demo-centre"
        val display = profile?.displayName?.takeIf { it.isNotBlank() } ?: session.identifier
        context.kashkoolPrefs.edit {
            it[Keys.ACCESS_TOKEN] = session.accessToken
            it[Keys.USER_ID] = session.userId
            it[Keys.TENANT_ID] = tenantId
            it[Keys.ROLE] = resolvedRole.key
            it[Keys.USER_LABEL] = display
            it[Keys.SIGNED_IN] = "true"
        }
        val androidId = Settings.Secure.getString(context.contentResolver, Settings.Secure.ANDROID_ID).orEmpty()
        val fingerprint = EgyptValidators.sha256Hex("${Build.MANUFACTURER}:${Build.MODEL}:$androidId")
        remote.bindDevice(session.accessToken, tenantId, fingerprint)
    }

    suspend fun setActiveRole(role: UserRole) {
        context.kashkoolPrefs.edit { it[Keys.ROLE] = role.key }
    }

    suspend fun signOut() {
        context.kashkoolPrefs.edit {
            it[Keys.SIGNED_IN] = "false"
            it.remove(Keys.ACCESS_TOKEN)
            it.remove(Keys.USER_ID)
        }
    }

    suspend fun ensureSeeded() {
        val now = System.currentTimeMillis()
        dao.insertGroupsIfAbsent(KashkoolSeeds.groups)
        dao.insertStudentsIfAbsent(KashkoolSeeds.students)
        dao.insertChannelsIfAbsent(KashkoolSeeds.channels)
        dao.insertLedgerEntriesIfAbsent(KashkoolSeeds.initialLedgerEntries(now))
        dao.insertResourcesIfAbsent(KashkoolSeeds.initialResources(now))
    }

    suspend fun saveEvaluation(evaluation: PerformanceEvaluationEntity) {
        dao.upsertEvaluation(evaluation)
    }

    suspend fun addResource(name: String, type: ResourceType, costPiasters: Long) {
        dao.upsertResource(
            Resource(
                name = name.trim(),
                type = type,
                availabilityStatus = AvailabilityStatus.AVAILABLE,
                costPiasters = costPiasters.coerceAtLeast(0L),
                syncStatus = "pending",
                updatedAtMillis = System.currentTimeMillis(),
            )
        )
    }

    suspend fun cycleResourceStatus(resource: Resource) {
        val next = when (resource.availabilityStatus) {
            AvailabilityStatus.AVAILABLE -> AvailabilityStatus.IN_USE
            AvailabilityStatus.IN_USE -> AvailabilityStatus.RESERVED
            AvailabilityStatus.RESERVED -> AvailabilityStatus.UNAVAILABLE
            AvailabilityStatus.UNAVAILABLE -> AvailabilityStatus.AVAILABLE
        }
        dao.updateResourceAvailability(resource.id, next)
    }

    suspend fun executeOrSeatRebalance(fromGroupId: String, toGroupId: String, seatsToMove: Int): Int {
        if (seatsToMove <= 0 || fromGroupId == toGroupId) return 0
        val fromGroup = dao.getGroupById(fromGroupId) ?: return 0
        val toGroup = dao.getGroupById(toGroupId) ?: return 0
        val actualShift = minOf(
            seatsToMove,
            fromGroup.enrolled,
            (toGroup.capacity - toGroup.enrolled).coerceAtLeast(0),
        )
        if (actualShift <= 0) return 0

        dao.upsertGroup(fromGroup.copy(enrolled = fromGroup.enrolled - actualShift, syncStatus = "pending"))
        dao.upsertGroup(toGroup.copy(enrolled = toGroup.enrolled + actualShift, syncStatus = "pending"))

        val studentsToShift = dao.getStudentsByGroup(fromGroupId).take(actualShift)
        if (studentsToShift.isNotEmpty()) {
            dao.upsertStudents(studentsToShift.map { it.copy(groupId = toGroupId) })
        }
        return actualShift
    }

    suspend fun addWalkInStudent(
        nameAr: String,
        phone: String,
        groupId: String,
        initialTopUpPiasters: Long,
    ): StudentEntity {
        val cleanPhone = EgyptValidators.normalizeEgyptianPhone(phone).ifBlank { phone.trim() }
        val student = StudentEntity(
            id = "stu-${UUID.randomUUID()}",
            nameAr = nameAr.trim(),
            nameEn = nameAr.trim(),
            phone = cleanPhone,
            groupId = groupId,
            walletBalancePiasters = 0L,
            dueBalancePiasters = 0L,
            streakDays = 1,
            masteryPercent = 75,
            qrActivationCode = EgyptValidators.generateActivationCode(8),
        )
        dao.upsertStudent(student)
        dao.getGroupById(groupId)?.let { grp ->
            dao.upsertGroup(grp.copy(enrolled = (grp.enrolled + 1).coerceAtMost(grp.capacity), syncStatus = "pending"))
        }
        if (initialTopUpPiasters > 0L) {
            appendFinancialEntry(
                student = student,
                kind = LedgerKind.CASH_TOPUP,
                amountPiasters = initialTopUpPiasters,
                note = "تسجيل فوري وشحن مبدئي على الباب",
                role = UserRole.SECRETARY,
            )
        }
        return student
    }

    suspend fun toggleStudentBlocked(student: StudentEntity) {
        dao.upsertStudent(student.copy(isBlocked = !student.isBlocked))
    }

    suspend fun addPaymentChannel(name: String, channelType: String, accountRef: String, feePiasters: Long) {
        dao.upsertChannel(
            PaymentChannelEntity(
                id = "ch-${System.currentTimeMillis()}",
                nameAr = name.trim(),
                nameEn = name.trim(),
                channelType = channelType,
                accountRef = accountRef.trim(),
                maxAmountPiasters = 500000L,
                feePiasters = feePiasters.coerceAtLeast(0L),
                isActive = true,
            )
        )
    }

    suspend fun toggleChannelActive(channelId: String, isActive: Boolean) {
        dao.setChannelActive(channelId, isActive)
    }

    suspend fun generateStudentActivationCode(student: StudentEntity): String {
        val code = EgyptValidators.generateActivationCode(8)
        dao.updateStudentQrCode(student.id, code)
        val prefs = context.kashkoolPrefs.data.first()
        val token = prefs[Keys.ACCESS_TOKEN].orEmpty()
        val tenantId = prefs[Keys.TENANT_ID] ?: "demo-centre"
        if (token.isNotBlank() && remote.hasValidSupabaseKeys) {
            remote.assignQrActivationCode(token, tenantId, student.phone, code)
        }
        return code
    }

    suspend fun activateLocallyWithQr(rawCode: String): StudentEntity? {
        val normalized = EgyptValidators.normalizeQrCode(rawCode)
        val matched = dao.getStudentByQrCode(normalized)
        val label = matched?.let { "${it.nameAr} · QR:$normalized" } ?: "QR:$normalized"
        signInWorkspace(UserRole.STUDENT, label)
        return matched
    }

    suspend fun recordQuickCheckIn(student: StudentEntity, sessionId: String): String {
        val status = when {
            student.isBlocked -> "blocked"
            student.dueBalancePiasters > 0L -> "due"
            else -> "valid"
        }
        dao.insertAttendance(
            AttendanceEntity(
                id = "att-${UUID.randomUUID()}",
                studentId = student.id,
                studentNameAr = student.nameAr,
                studentNameEn = student.nameEn,
                groupId = student.groupId,
                sessionId = sessionId,
                feedbackStatus = status,
                timestampMillis = System.currentTimeMillis(),
                syncStatus = "pending",
            )
        )
        if (!student.isBlocked) {
            dao.upsertStudent(student.copy(streakDays = student.streakDays + 1))
        }
        return status
    }

    suspend fun appendFinancialEntry(
        student: StudentEntity,
        kind: LedgerKind,
        amountPiasters: Long,
        note: String,
        role: UserRole,
    ) {
        val now = System.currentTimeMillis()
        var newWallet = student.walletBalancePiasters
        var newDue = student.dueBalancePiasters

        when (kind) {
            LedgerKind.CASH_TOPUP -> newWallet += amountPiasters
            LedgerKind.PARTIAL_INSTALLMENT -> {
                val paidTowardsDue = minOf(newDue, amountPiasters)
                newDue = (newDue - paidTowardsDue).coerceAtLeast(0L)
                newWallet += (amountPiasters - paidTowardsDue)
            }
            LedgerKind.BOOK_RESERVATION -> {
                if (newWallet >= amountPiasters) newWallet -= amountPiasters
                else {
                    newDue += (amountPiasters - newWallet)
                    newWallet = 0L
                }
            }
            LedgerKind.DISCOUNT -> newDue = (newDue - amountPiasters).coerceAtLeast(0L)
            LedgerKind.SESSION_CHARGE, LedgerKind.SETTLEMENT, LedgerKind.VOID_ENTRY -> Unit
        }

        dao.upsertStudent(student.copy(walletBalancePiasters = newWallet, dueBalancePiasters = newDue))
        dao.appendLedgerEntry(
            LedgerEntryEntity(
                id = "led-${UUID.randomUUID()}",
                studentId = student.id,
                studentNameAr = student.nameAr,
                studentNameEn = student.nameEn,
                kind = kind.key,
                amountPiasters = amountPiasters,
                remainingDuePiasters = newDue,
                note = note,
                createdByRole = role.key,
                createdAtMillis = now,
                syncStatus = "pending",
            )
        )
    }

    suspend fun voidLedgerEntry(entryId: String, reason: String, role: UserRole) {
        val original = dao.getLedgerEntryById(entryId) ?: return
        if (original.kind == LedgerKind.VOID_ENTRY.key) return
        val student = dao.getStudentById(original.studentId)
        if (student != null && original.kind == LedgerKind.CASH_TOPUP.key) {
            val updatedWallet = (student.walletBalancePiasters - original.amountPiasters).coerceAtLeast(0L)
            dao.upsertStudent(student.copy(walletBalancePiasters = updatedWallet))
        }
        dao.appendLedgerEntry(
            LedgerEntryEntity(
                id = "void-${UUID.randomUUID()}",
                studentId = original.studentId,
                studentNameAr = original.studentNameAr,
                studentNameEn = original.studentNameEn,
                kind = LedgerKind.VOID_ENTRY.key,
                amountPiasters = -original.amountPiasters,
                note = reason,
                voidedEntryId = original.id,
                createdByRole = role.key,
                createdAtMillis = System.currentTimeMillis(),
                syncStatus = "pending",
            )
        )
    }

    suspend fun recordDailySettlement(netPayoutPiasters: Long, note: String) {
        dao.appendLedgerEntry(
            LedgerEntryEntity(
                id = "settle-${UUID.randomUUID()}",
                studentId = "center-settlement",
                studentNameAr = "تسوية نهاية اليوم",
                studentNameEn = "End-of-Day Settlement",
                kind = LedgerKind.SETTLEMENT.key,
                amountPiasters = netPayoutPiasters,
                note = note,
                createdByRole = UserRole.TEACHER.key,
                createdAtMillis = System.currentTimeMillis(),
                syncStatus = "pending",
            )
        )
    }

    suspend fun addGroup(name: String, schedule: String, capacity: Int, pricePiasters: Long) {
        dao.upsertGroup(
            GroupEntity(
                id = "grp-${System.currentTimeMillis()}",
                nameAr = name,
                nameEn = name,
                subjectAr = "الثانوية العامة",
                subjectEn = "High School",
                scheduleAr = schedule,
                scheduleEn = schedule,
                enrolled = 0,
                capacity = capacity.coerceAtLeast(1),
                pricePerSessionPiasters = pricePiasters.coerceAtLeast(100L),
                syncStatus = "pending",
            )
        )
    }

    suspend fun submitPaymentReceipt(
        channel: PaymentChannelEntity,
        amountPiasters: Long,
        senderRef: String,
        receiptUri: String?,
        lang: AppLanguage,
    ) {
        dao.upsertSubmission(
            PaymentSubmissionEntity(
                id = "sub-${UUID.randomUUID()}",
                studentId = "stu-1",
                studentNameAr = "أحمد محمد علي",
                studentNameEn = "Ahmed Mohamed Ali",
                channelId = channel.id,
                channelName = if (lang == AppLanguage.AR) channel.nameAr else channel.nameEn,
                amountPiasters = amountPiasters,
                senderReference = senderRef,
                receiptUri = receiptUri,
                status = SubmissionStatus.PENDING.key,
                createdAtMillis = System.currentTimeMillis(),
                syncStatus = "pending",
            )
        )
    }

    suspend fun approveSubmission(submission: PaymentSubmissionEntity) {
        if (submission.status != SubmissionStatus.PENDING.key) return
        dao.updateSubmissionStatus(submission.id, SubmissionStatus.APPROVED.key, null)
        val prefs = context.kashkoolPrefs.data.first()
        val token = prefs[Keys.ACCESS_TOKEN].orEmpty()
        if (token.isNotBlank() && remote.hasValidSupabaseKeys) {
            remote.approveSubmissionRemote(token, submission.id)
                .onSuccess { dao.markSubmissionSynced(submission.id) }
        }
        if (submission.studentId == "center-owner") {
            val resolvedPlan = when {
                submission.id.contains("plan-enterprise") || submission.amountPiasters >= 150000L -> "plan-enterprise"
                submission.id.contains("plan-pro") || submission.amountPiasters >= 75000L -> "plan-pro"
                else -> "plan-starter"
            }
            context.kashkoolPrefs.edit { it[Keys.CENTER_PLAN_ID] = resolvedPlan }
            dao.appendLedgerEntry(
                LedgerEntryEntity(
                    id = "led-plan-${UUID.randomUUID()}",
                    studentId = "center-owner",
                    studentNameAr = submission.studentNameAr,
                    studentNameEn = submission.studentNameEn,
                    kind = LedgerKind.SETTLEMENT.key,
                    amountPiasters = submission.amountPiasters,
                    note = "${submission.channelName} · ${submission.senderReference}",
                    createdByRole = UserRole.TEACHER.key,
                    createdAtMillis = System.currentTimeMillis(),
                    syncStatus = "pending",
                )
            )
            return
        }
        val student = dao.getStudentById(submission.studentId) ?: return
        appendFinancialEntry(
            student = student,
            kind = LedgerKind.CASH_TOPUP,
            amountPiasters = submission.amountPiasters,
            note = "${submission.channelName} · ${submission.senderReference}",
            role = UserRole.SECRETARY,
        )
    }

    suspend fun rejectSubmission(submission: PaymentSubmissionEntity, reason: String) {
        if (submission.status != SubmissionStatus.PENDING.key) return
        dao.updateSubmissionStatus(submission.id, SubmissionStatus.REJECTED.key, reason)
        val prefs = context.kashkoolPrefs.data.first()
        val token = prefs[Keys.ACCESS_TOKEN].orEmpty()
        if (token.isNotBlank() && remote.hasValidSupabaseKeys) {
            remote.rejectSubmissionRemote(token, submission.id, reason)
                .onSuccess { dao.markSubmissionSynced(submission.id) }
        }
    }

    suspend fun syncPendingOperations(): SyncReport {
        val prefs = context.kashkoolPrefs.data.first()
        val token = prefs[Keys.ACCESS_TOKEN].orEmpty()
        val userId = prefs[Keys.USER_ID].orEmpty()
        val tenantId = prefs[Keys.TENANT_ID] ?: "demo-centre"

        if (!remote.hasValidSupabaseKeys || token.isBlank()) {
            return SyncReport(syncedItems = 0, failedItems = 0, isOffline = true)
        }

        var synced = 0
        var failed = 0

        dao.getPendingGroups().forEach { grp ->
            remote.createGroupRemote(token, tenantId, grp).fold(
                onSuccess = { dao.markGroupSynced(grp.id); synced++ },
                onFailure = { failed++ },
            )
        }
        dao.getPendingAttendance().forEach { att ->
            remote.recordAttendanceRemote(token, tenantId, att).fold(
                onSuccess = { dao.markAttendanceSynced(att.id); synced++ },
                onFailure = { failed++ },
            )
        }
        dao.getPendingLedgerEntries().forEach { entry ->
            remote.recordWalletEntryRemote(token, tenantId, entry).fold(
                onSuccess = { dao.markLedgerEntrySynced(entry.id); synced++ },
                onFailure = { failed++ },
            )
        }
        dao.getPendingSubmissions().forEach { sub ->
            var storagePath = sub.receiptUri.orEmpty()
            val localFile = storagePath.takeIf { it.startsWith("file://") }
                ?.let { Uri.parse(it).path }
                ?.let(::File)
            if (localFile != null && localFile.exists() && userId.isNotBlank()) {
                val uploaded = remote.uploadReceiptBytes(
                    accessToken = token,
                    tenantId = tenantId,
                    userId = userId,
                    submissionId = sub.id,
                    jpegBytes = localFile.readBytes(),
                )
                if (uploaded.isSuccess) storagePath = uploaded.getOrThrow()
            }
            remote.submitPaymentRemote(token, tenantId, sub, storagePath).fold(
                onSuccess = { dao.markSubmissionSynced(sub.id, storagePath.takeIf { it.isNotBlank() }); synced++ },
                onFailure = { failed++ },
            )
        }
        remote.fetchActiveChannels(token, tenantId).onSuccess { channels ->
            if (channels.isNotEmpty()) dao.upsertChannels(channels)
        }
        return SyncReport(syncedItems = synced, failedItems = failed, isOffline = false)
    }
}
