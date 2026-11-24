package com.dig.kashkool.data.local

import androidx.room.Entity
import androidx.room.PrimaryKey

enum class UserRole(val key: String) {
    STUDENT("student"),
    SECRETARY("secretary"),
    TEACHER("teacher"),
    PARENT("parent"),
}

enum class LedgerKind(val key: String) {
    CASH_TOPUP("cash_topup"),
    PARTIAL_INSTALLMENT("partial_installment"),
    BOOK_RESERVATION("book_reservation"),
    DISCOUNT("discount"),
    SESSION_CHARGE("session_charge"),
    SETTLEMENT("settlement"),
    VOID_ENTRY("void_entry"),
}

enum class SubmissionStatus(val key: String) {
    PENDING("pending"),
    APPROVED("approved"),
    REJECTED("rejected"),
}

@Entity(tableName = "groups")
data class GroupEntity(
    @PrimaryKey val id: String,
    val nameAr: String,
    val nameEn: String,
    val subjectAr: String,
    val subjectEn: String,
    val scheduleAr: String,
    val scheduleEn: String,
    val enrolled: Int,
    val capacity: Int,
    val pricePerSessionPiasters: Long,
    val centerSplitPercent: Int = 20,
    val syncStatus: String = "synced",
)

@Entity(tableName = "students")
data class StudentEntity(
    @PrimaryKey val id: String,
    val nameAr: String,
    val nameEn: String,
    val phone: String,
    val groupId: String,
    val walletBalancePiasters: Long,
    val dueBalancePiasters: Long,
    val streakDays: Int,
    val masteryPercent: Int,
    val isBlocked: Boolean = false,
    val qrActivationCode: String? = null,
)

@Entity(tableName = "attendance")
data class AttendanceEntity(
    @PrimaryKey val id: String,
    val studentId: String,
    val studentNameAr: String,
    val studentNameEn: String,
    val groupId: String,
    val sessionId: String,
    val feedbackStatus: String, // "valid", "due", "blocked"
    val timestampMillis: Long,
    val syncStatus: String = "pending",
)

@Entity(tableName = "ledger_entries")
data class LedgerEntryEntity(
    @PrimaryKey val id: String,
    val studentId: String,
    val studentNameAr: String,
    val studentNameEn: String,
    val kind: String,
    val amountPiasters: Long,
    val remainingDuePiasters: Long = 0L,
    val note: String = "",
    val voidedEntryId: String? = null,
    val createdByRole: String = "secretary",
    val createdAtMillis: Long,
    val syncStatus: String = "pending",
)

@Entity(tableName = "payment_channels")
data class PaymentChannelEntity(
    @PrimaryKey val id: String,
    val nameAr: String,
    val nameEn: String,
    val channelType: String, // "insta_pay", "vodafone_cash", "etisalat_cash", "orange_cash", "we_pay", "fawry", "cash_desk"
    val accountRef: String,
    val maxAmountPiasters: Long,
    val feePiasters: Long,
    val isActive: Boolean = true,
)

@Entity(tableName = "payment_submissions")
data class PaymentSubmissionEntity(
    @PrimaryKey val id: String,
    val studentId: String,
    val studentNameAr: String,
    val studentNameEn: String,
    val channelId: String,
    val channelName: String,
    val amountPiasters: Long,
    val senderReference: String,
    val receiptUri: String? = null,
    val status: String = SubmissionStatus.PENDING.key,
    val rejectionReason: String? = null,
    val createdAtMillis: Long,
    val syncStatus: String = "pending",
)
