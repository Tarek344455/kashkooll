package com.dig.kashkool.data.local

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import kotlinx.coroutines.flow.Flow

@Dao
interface KashkoolDao {

    @Query("SELECT * FROM groups ORDER BY nameEn ASC")
    fun observeGroups(): Flow<List<GroupEntity>>

    @Query("SELECT * FROM groups WHERE syncStatus = 'pending'")
    suspend fun getPendingGroups(): List<GroupEntity>

    @Query("UPDATE groups SET syncStatus = 'synced' WHERE id = :id")
    suspend fun markGroupSynced(id: String)

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun upsertGroup(group: GroupEntity)

    @Insert(onConflict = OnConflictStrategy.IGNORE)
    suspend fun insertGroupsIfAbsent(groups: List<GroupEntity>)

    @Query("SELECT * FROM students ORDER BY nameAr ASC")
    fun observeStudents(): Flow<List<StudentEntity>>

    @Query("SELECT * FROM students WHERE id = :id LIMIT 1")
    suspend fun getStudentById(id: String): StudentEntity?

    @Query("SELECT * FROM students WHERE UPPER(REPLACE(IFNULL(qrActivationCode, ''), '-', '')) = :normalizedCode LIMIT 1")
    suspend fun getStudentByQrCode(normalizedCode: String): StudentEntity?

    @Query("UPDATE students SET qrActivationCode = :code WHERE id = :studentId")
    suspend fun updateStudentQrCode(studentId: String, code: String)

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun upsertStudent(student: StudentEntity)

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun upsertStudents(students: List<StudentEntity>)

    @Insert(onConflict = OnConflictStrategy.IGNORE)
    suspend fun insertStudentsIfAbsent(students: List<StudentEntity>)

    @Query("SELECT * FROM attendance ORDER BY timestampMillis DESC")
    fun observeAttendance(): Flow<List<AttendanceEntity>>

    @Query("SELECT * FROM attendance WHERE timestampMillis >= :sinceMillis ORDER BY timestampMillis ASC")
    fun observeAttendanceSince(sinceMillis: Long): Flow<List<AttendanceEntity>>

    @Query("SELECT COUNT(*) FROM attendance")
    suspend fun getAttendanceCount(): Int

    @Query("SELECT * FROM attendance WHERE syncStatus = 'pending' ORDER BY timestampMillis ASC")
    suspend fun getPendingAttendance(): List<AttendanceEntity>

    @Query("UPDATE attendance SET syncStatus = 'synced' WHERE id = :id")
    suspend fun markAttendanceSynced(id: String)

    @Query(
        "SELECT * FROM attendance WHERE studentId = :studentId AND sessionId = :sessionId AND timestampMillis >= :startOfDayMillis ORDER BY timestampMillis DESC LIMIT 1"
    )
    suspend fun getAttendanceForStudentInSessionSince(
        studentId: String,
        sessionId: String,
        startOfDayMillis: Long,
    ): AttendanceEntity?

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertAttendance(record: AttendanceEntity)

    @Insert(onConflict = OnConflictStrategy.IGNORE)
    suspend fun insertAttendanceIfAbsent(records: List<AttendanceEntity>)

    @Query("SELECT * FROM ledger_entries ORDER BY createdAtMillis DESC")
    fun observeLedgerEntries(): Flow<List<LedgerEntryEntity>>

    @Query("SELECT * FROM ledger_entries WHERE syncStatus = 'pending' ORDER BY createdAtMillis ASC")
    suspend fun getPendingLedgerEntries(): List<LedgerEntryEntity>

    @Query("UPDATE ledger_entries SET syncStatus = 'synced' WHERE id = :id")
    suspend fun markLedgerEntrySynced(id: String)

    @Query("SELECT * FROM ledger_entries WHERE id = :id LIMIT 1")
    suspend fun getLedgerEntryById(id: String): LedgerEntryEntity?

    @Insert(onConflict = OnConflictStrategy.ABORT)
    suspend fun appendLedgerEntry(entry: LedgerEntryEntity)

    @Insert(onConflict = OnConflictStrategy.IGNORE)
    suspend fun insertLedgerEntriesIfAbsent(entries: List<LedgerEntryEntity>)

    @Query("SELECT * FROM payment_channels WHERE isActive = 1 ORDER BY feePiasters ASC, nameEn ASC")
    fun observeActiveChannels(): Flow<List<PaymentChannelEntity>>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun upsertChannels(channels: List<PaymentChannelEntity>)

    @Insert(onConflict = OnConflictStrategy.IGNORE)
    suspend fun insertChannelsIfAbsent(channels: List<PaymentChannelEntity>)

    @Query("SELECT * FROM payment_submissions ORDER BY createdAtMillis DESC")
    fun observeSubmissions(): Flow<List<PaymentSubmissionEntity>>

    @Query("SELECT * FROM payment_submissions WHERE syncStatus = 'pending' ORDER BY createdAtMillis ASC")
    suspend fun getPendingSubmissions(): List<PaymentSubmissionEntity>

    @Query("UPDATE payment_submissions SET syncStatus = 'synced', receiptUri = COALESCE(:remoteUrl, receiptUri) WHERE id = :id")
    suspend fun markSubmissionSynced(id: String, remoteUrl: String? = null)

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun upsertSubmission(submission: PaymentSubmissionEntity)

    @Query(
        "UPDATE payment_submissions SET status = :status, rejectionReason = :reason, syncStatus = 'pending' WHERE id = :id"
    )
    suspend fun updateSubmissionStatus(id: String, status: String, reason: String?)

    @Query("SELECT * FROM groups WHERE id = :id LIMIT 1")
    suspend fun getGroupById(id: String): GroupEntity?

    @Query("SELECT * FROM students WHERE groupId = :groupId ORDER BY nameAr ASC")
    suspend fun getStudentsByGroup(groupId: String): List<StudentEntity>

    @Query("SELECT * FROM payment_channels ORDER BY isActive DESC, feePiasters ASC, nameEn ASC")
    fun observeAllChannels(): Flow<List<PaymentChannelEntity>>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun upsertChannel(channel: PaymentChannelEntity)

    @Query("UPDATE payment_channels SET isActive = :active WHERE id = :id")
    suspend fun setChannelActive(id: String, active: Boolean)

    @Query("SELECT * FROM resources ORDER BY updated_at_millis DESC")
    fun observeResources(): Flow<List<Resource>>

    @Insert(onConflict = OnConflictStrategy.IGNORE)
    suspend fun insertResourcesIfAbsent(resources: List<Resource>)

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun upsertResource(resource: Resource)

    @Query(
        "UPDATE resources SET availability_status = :status, sync_status = 'pending', updated_at_millis = :updatedAt WHERE id = :id"
    )
    suspend fun updateResourceAvailability(
        id: String,
        status: AvailabilityStatus,
        updatedAt: Long = System.currentTimeMillis(),
    )

    @Query("SELECT * FROM performance_evaluations ORDER BY evaluated_at_millis DESC")
    fun observeEvaluations(): Flow<List<PerformanceEvaluationEntity>>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun upsertEvaluation(evaluation: PerformanceEvaluationEntity)
}
