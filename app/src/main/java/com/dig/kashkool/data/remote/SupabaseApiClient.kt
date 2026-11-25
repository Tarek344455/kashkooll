package com.dig.kashkool.data.remote

import com.dig.kashkool.BuildConfig
import com.dig.kashkool.data.local.AttendanceEntity
import com.dig.kashkool.data.local.GroupEntity
import com.dig.kashkool.data.local.LedgerEntryEntity
import com.dig.kashkool.data.local.LedgerKind
import com.dig.kashkool.data.local.PaymentChannelEntity
import com.dig.kashkool.data.local.PaymentSubmissionEntity
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.booleanOrNull
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.jsonArray
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive
import kotlinx.serialization.json.longOrNull
import kotlinx.serialization.json.put
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.RequestBody.Companion.toRequestBody
import java.net.URLEncoder
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import java.util.TimeZone
import java.util.concurrent.TimeUnit

@Serializable
data class RemoteSession(
    val accessToken: String,
    val userId: String,
    val identifier: String,
)

data class RemoteProfile(
    val id: String,
    val tenantId: String?,
    val role: String,
    val phone: String?,
    val displayName: String,
)

class SupabaseApiClient {
    private val client = OkHttpClient.Builder()
        .connectTimeout(15, TimeUnit.SECONDS)
        .readTimeout(30, TimeUnit.SECONDS)
        .build()

    private val json = Json { ignoreUnknownKeys = true }
    private val jsonMediaType = "application/json; charset=utf-8".toMediaType()
    private val jpegMediaType = "image/jpeg".toMediaType()

    val supabaseUrl: String
        get() = BuildConfig.SUPABASE_URL.trim().trimEnd('/')

    val supabaseAnonKey: String
        get() = BuildConfig.SUPABASE_ANON_KEY.trim()

    val isSupabaseConfigured: Boolean
        get() = supabaseUrl.startsWith("https://") ||
            supabaseUrl.startsWith("http://localhost") ||
            supabaseUrl.startsWith("http://127.0.0.1")

    val hasValidSupabaseKeys: Boolean
        get() = isSupabaseConfigured &&
            supabaseAnonKey.isNotBlank() &&
            !supabaseAnonKey.startsWith("your_")

    private fun Request.Builder.withSupabaseAuth(accessToken: String? = null): Request.Builder {
        addHeader("apikey", supabaseAnonKey)
        if (!accessToken.isNullOrBlank()) {
            addHeader("Authorization", "Bearer $accessToken")
        }
        return this
    }

    private fun encode(raw: String): String = URLEncoder.encode(raw, "UTF-8")

    private fun isoTimestamp(millis: Long): String {
        val sdf = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'", Locale.US)
        sdf.timeZone = TimeZone.getTimeZone("UTC")
        return sdf.format(Date(millis))
    }

    suspend fun requestOtp(phoneOrEmail: String, isEmail: Boolean): Result<Unit> =
        withContext(Dispatchers.IO) {
            if (!hasValidSupabaseKeys) {
                return@withContext Result.failure(IllegalStateException("Supabase is not configured."))
            }
            runCatching {
                val payload = if (isEmail) {
                    buildJsonObject { put("email", phoneOrEmail) }
                } else {
                    buildJsonObject { put("phone", phoneOrEmail) }
                }
                val req = Request.Builder()
                    .url("$supabaseUrl/auth/v1/otp")
                    .withSupabaseAuth()
                    .addHeader("Content-Type", "application/json")
                    .post(payload.toString().toRequestBody(jsonMediaType))
                    .build()
                client.newCall(req).execute().use { resp ->
                    if (!resp.isSuccessful) {
                        error("OTP request failed (${resp.code})")
                    }
                }
            }
        }

    suspend fun verifyOtp(
        identifier: String,
        token: String,
        isEmail: Boolean,
    ): Result<RemoteSession> = withContext(Dispatchers.IO) {
        if (!hasValidSupabaseKeys) {
            return@withContext Result.failure(IllegalStateException("Supabase is not configured."))
        }
        runCatching {
            val payload = buildJsonObject {
                if (isEmail) {
                    put("email", identifier)
                    put("type", "email")
                } else {
                    put("phone", identifier)
                    put("type", "sms")
                }
                put("token", token)
            }
            val req = Request.Builder()
                .url("$supabaseUrl/auth/v1/verify")
                .withSupabaseAuth()
                .addHeader("Content-Type", "application/json")
                .post(payload.toString().toRequestBody(jsonMediaType))
                .build()
            client.newCall(req).execute().use { resp ->
                val body = resp.body?.string().orEmpty()
                if (!resp.isSuccessful) error("Verification failed (${resp.code})")
                val obj = json.parseToJsonElement(body).jsonObject
                val accessToken = obj["access_token"]?.jsonPrimitive?.content.orEmpty()
                val userObj = obj["user"]?.jsonObject
                val userId = userObj?.get("id")?.jsonPrimitive?.content.orEmpty()
                if (accessToken.isBlank()) error("Missing access token")
                RemoteSession(accessToken = accessToken, userId = userId, identifier = identifier)
            }
        }
    }

    suspend fun fetchProfile(accessToken: String, userId: String): Result<RemoteProfile?> =
        withContext(Dispatchers.IO) {
            if (!hasValidSupabaseKeys || accessToken.isBlank() || userId.isBlank()) {
                return@withContext Result.success(null)
            }
            runCatching {
                val url =
                    "$supabaseUrl/rest/v1/profiles?id=eq.${encode(userId)}&select=id,tenant_id,role,phone,display_name"
                val req = Request.Builder()
                    .url(url)
                    .withSupabaseAuth(accessToken)
                    .get()
                    .build()
                client.newCall(req).execute().use { resp ->
                    val body = resp.body?.string().orEmpty()
                    if (!resp.isSuccessful) error("Profile fetch failed (${resp.code})")
                    val arr = json.parseToJsonElement(body).jsonArray
                    val row = arr.firstOrNull()?.jsonObject ?: return@use null
                    RemoteProfile(
                        id = row["id"]?.jsonPrimitive?.content.orEmpty(),
                        tenantId = row["tenant_id"]?.jsonPrimitive?.content?.takeIf { it != "null" },
                        role = row["role"]?.jsonPrimitive?.content ?: "student",
                        phone = row["phone"]?.jsonPrimitive?.content?.takeIf { it != "null" },
                        displayName = row["display_name"]?.jsonPrimitive?.content.orEmpty(),
                    )
                }
            }
        }

    suspend fun bindDevice(
        accessToken: String,
        tenantId: String,
        fingerprint: String,
    ): Result<String> = withContext(Dispatchers.IO) {
        if (!hasValidSupabaseKeys || accessToken.isBlank()) {
            return@withContext Result.success("offline")
        }
        runCatching {
            val payload = buildJsonObject {
                put("p_tenant_id", tenantId)
                put("p_fingerprint", fingerprint)
            }
            val req = Request.Builder()
                .url("$supabaseUrl/rest/v1/rpc/bind_device")
                .withSupabaseAuth(accessToken)
                .addHeader("Content-Type", "application/json")
                .post(payload.toString().toRequestBody(jsonMediaType))
                .build()
            client.newCall(req).execute().use { resp ->
                val body = resp.body?.string().orEmpty()
                if (!resp.isSuccessful) error("Device binding failed (${resp.code})")
                val obj = json.parseToJsonElement(body).jsonObject
                obj["status"]?.jsonPrimitive?.content ?: "ok"
            }
        }
    }

    suspend fun assignQrActivationCode(
        accessToken: String,
        tenantId: String,
        phone: String,
        code: String,
    ): Result<Unit> = withContext(Dispatchers.IO) {
        if (!hasValidSupabaseKeys || accessToken.isBlank()) {
            return@withContext Result.failure(IllegalStateException("Supabase session unavailable"))
        }
        runCatching {
            val url =
                "$supabaseUrl/rest/v1/profiles?phone=eq.${encode(phone)}&tenant_id=eq.${encode(tenantId)}"
            val payload = buildJsonObject {
                put("qr_activation_code", code)
                put("qr_activated_at", null as String?)
            }
            val req = Request.Builder()
                .url(url)
                .withSupabaseAuth(accessToken)
                .addHeader("Content-Type", "application/json")
                .patch(payload.toString().toRequestBody(jsonMediaType))
                .build()
            client.newCall(req).execute().use { resp ->
                if (!resp.isSuccessful) error("QR code assignment failed (${resp.code})")
            }
        }
    }

    suspend fun fetchActiveChannels(
        accessToken: String,
        tenantId: String,
    ): Result<List<PaymentChannelEntity>> = withContext(Dispatchers.IO) {
        if (!hasValidSupabaseKeys || accessToken.isBlank()) {
            return@withContext Result.success(emptyList())
        }
        runCatching {
            val url = "$supabaseUrl/rest/v1/payment_channels" +
                "?tenant_id=eq.${encode(tenantId)}&active=eq.true" +
                "&select=id,name,channel_type,account_ref,fee_piasters,max_amount_piasters,active"
            val req = Request.Builder()
                .url(url)
                .withSupabaseAuth(accessToken)
                .get()
                .build()
            client.newCall(req).execute().use { resp ->
                val body = resp.body?.string().orEmpty()
                if (!resp.isSuccessful) error("Channels fetch failed (${resp.code})")
                json.parseToJsonElement(body).jsonArray.map { el ->
                    val obj = el.jsonObject
                    val name = obj["name"]?.jsonPrimitive?.content.orEmpty()
                    PaymentChannelEntity(
                        id = obj["id"]?.jsonPrimitive?.content.orEmpty(),
                        nameAr = name,
                        nameEn = name,
                        channelType = obj["channel_type"]?.jsonPrimitive?.content ?: "cash_desk",
                        accountRef = obj["account_ref"]?.jsonPrimitive?.content.orEmpty(),
                        maxAmountPiasters = obj["max_amount_piasters"]?.jsonPrimitive?.longOrNull ?: 500000L,
                        feePiasters = obj["fee_piasters"]?.jsonPrimitive?.longOrNull ?: 0L,
                        isActive = obj["active"]?.jsonPrimitive?.booleanOrNull ?: true,
                    )
                }
            }
        }
    }

    suspend fun createGroupRemote(
        accessToken: String,
        tenantId: String,
        group: GroupEntity,
    ): Result<Unit> = withContext(Dispatchers.IO) {
        if (!hasValidSupabaseKeys || accessToken.isBlank()) {
            return@withContext Result.failure(IllegalStateException("Offline"))
        }
        runCatching {
            val payload = buildJsonObject {
                put("id", group.id)
                put("tenant_id", tenantId)
                put("name", group.nameAr)
                put("subject", group.subjectAr)
                put(
                    "schedule",
                    buildJsonObject {
                        put("label", group.scheduleAr)
                        put("capacity", group.capacity)
                        put("price_piasters", group.pricePerSessionPiasters)
                    },
                )
            }
            val req = Request.Builder()
                .url("$supabaseUrl/rest/v1/groups")
                .withSupabaseAuth(accessToken)
                .addHeader("Content-Type", "application/json")
                .addHeader("Prefer", "resolution=merge-duplicates")
                .post(payload.toString().toRequestBody(jsonMediaType))
                .build()
            client.newCall(req).execute().use { resp ->
                if (!resp.isSuccessful) error("Group sync failed (${resp.code})")
            }
        }
    }

    suspend fun recordAttendanceRemote(
        accessToken: String,
        tenantId: String,
        record: AttendanceEntity,
    ): Result<Unit> = withContext(Dispatchers.IO) {
        if (!hasValidSupabaseKeys || accessToken.isBlank()) {
            return@withContext Result.failure(IllegalStateException("Offline"))
        }
        runCatching {
            val payload = buildJsonObject {
                put("p_id", record.id)
                put("p_tenant_id", tenantId)
                put("p_student_id", record.studentId)
                put("p_session_id", record.sessionId)
                put("p_idempotency_key", record.id)
                put("p_scanned_at", isoTimestamp(record.timestampMillis))
            }
            val req = Request.Builder()
                .url("$supabaseUrl/rest/v1/rpc/record_attendance")
                .withSupabaseAuth(accessToken)
                .addHeader("Content-Type", "application/json")
                .post(payload.toString().toRequestBody(jsonMediaType))
                .build()
            client.newCall(req).execute().use { resp ->
                if (!resp.isSuccessful) error("Attendance RPC failed (${resp.code})")
            }
        }
    }

    suspend fun recordWalletEntryRemote(
        accessToken: String,
        tenantId: String,
        entry: LedgerEntryEntity,
    ): Result<Unit> = withContext(Dispatchers.IO) {
        if (!hasValidSupabaseKeys || accessToken.isBlank()) {
            return@withContext Result.failure(IllegalStateException("Offline"))
        }
        runCatching {
            if (entry.kind == LedgerKind.VOID_ENTRY.key && !entry.voidedEntryId.isNullOrBlank()) {
                val payload = buildJsonObject {
                    put("p_tenant_id", tenantId)
                    put("p_transaction_id", entry.voidedEntryId)
                    put("p_reason", entry.note)
                }
                val req = Request.Builder()
                    .url("$supabaseUrl/rest/v1/rpc/void_wallet_transaction")
                    .withSupabaseAuth(accessToken)
                    .addHeader("Content-Type", "application/json")
                    .post(payload.toString().toRequestBody(jsonMediaType))
                    .build()
                client.newCall(req).execute().use { resp ->
                    if (!resp.isSuccessful) error("Void RPC failed (${resp.code})")
                }
                return@runCatching
            }

            val mappedKind = when (entry.kind) {
                LedgerKind.CASH_TOPUP.key -> "topup"
                LedgerKind.PARTIAL_INSTALLMENT.key -> "payment"
                LedgerKind.BOOK_RESERVATION.key -> "reservation"
                LedgerKind.DISCOUNT.key -> "refund"
                LedgerKind.SETTLEMENT.key -> "settlement"
                else -> "charge"
            }
            val payload = buildJsonObject {
                put("p_id", entry.id)
                put("p_tenant_id", tenantId)
                put("p_student_id", entry.studentId)
                put("p_amount_piasters", entry.amountPiasters)
                put("p_kind", mappedKind)
                put("p_channel", "cash_desk")
                put("p_idempotency_key", entry.id)
                put("p_note", entry.note)
            }
            val req = Request.Builder()
                .url("$supabaseUrl/rest/v1/rpc/record_wallet_transaction")
                .withSupabaseAuth(accessToken)
                .addHeader("Content-Type", "application/json")
                .post(payload.toString().toRequestBody(jsonMediaType))
                .build()
            client.newCall(req).execute().use { resp ->
                if (!resp.isSuccessful) error("Wallet RPC failed (${resp.code})")
            }
        }
    }

    /**
     * Uploads compressed JPEG bytes (<= 150 KB) into the private `receipts` bucket.
     * Path `<tenantId>/<userId>/<submissionId>.jpg` satisfies `20261123000010_storage_receipts.sql` RLS.
     */
    suspend fun uploadReceiptBytes(
        accessToken: String,
        tenantId: String,
        userId: String,
        submissionId: String,
        jpegBytes: ByteArray,
    ): Result<String> = withContext(Dispatchers.IO) {
        if (!hasValidSupabaseKeys || accessToken.isBlank() || userId.isBlank()) {
            return@withContext Result.failure(IllegalStateException("Offline"))
        }
        runCatching {
            val objectPath = "$tenantId/$userId/$submissionId.jpg"
            val req = Request.Builder()
                .url("$supabaseUrl/storage/v1/object/receipts/$objectPath")
                .withSupabaseAuth(accessToken)
                .addHeader("Content-Type", "image/jpeg")
                .addHeader("x-upsert", "true")
                .post(jpegBytes.toRequestBody(jpegMediaType))
                .build()
            client.newCall(req).execute().use { resp ->
                if (!resp.isSuccessful) error("Receipt upload failed (${resp.code})")
                objectPath
            }
        }
    }

    suspend fun submitPaymentRemote(
        accessToken: String,
        tenantId: String,
        submission: PaymentSubmissionEntity,
        storagePath: String,
    ): Result<Unit> = withContext(Dispatchers.IO) {
        if (!hasValidSupabaseKeys || accessToken.isBlank()) {
            return@withContext Result.failure(IllegalStateException("Offline"))
        }
        runCatching {
            val payload = buildJsonObject {
                put("id", submission.id)
                put("tenant_id", tenantId)
                put("student_id", submission.studentId)
                put("channel_id", submission.channelId)
                put("amount_piasters", submission.amountPiasters)
                put("sender_reference", submission.senderReference)
                put("receipt_url", storagePath)
                put("status", submission.status)
            }
            val req = Request.Builder()
                .url("$supabaseUrl/rest/v1/payment_submissions")
                .withSupabaseAuth(accessToken)
                .addHeader("Content-Type", "application/json")
                .addHeader("Prefer", "resolution=merge-duplicates")
                .post(payload.toString().toRequestBody(jsonMediaType))
                .build()
            client.newCall(req).execute().use { resp ->
                if (!resp.isSuccessful) error("Payment submission failed (${resp.code})")
            }
        }
    }

    suspend fun approveSubmissionRemote(
        accessToken: String,
        submissionId: String,
        note: String = "",
    ): Result<Unit> = withContext(Dispatchers.IO) {
        if (!hasValidSupabaseKeys || accessToken.isBlank()) {
            return@withContext Result.failure(IllegalStateException("Offline"))
        }
        runCatching {
            val payload = buildJsonObject {
                put("p_submission_id", submissionId)
                put("p_note", note)
            }
            val req = Request.Builder()
                .url("$supabaseUrl/rest/v1/rpc/approve_payment_submission")
                .withSupabaseAuth(accessToken)
                .addHeader("Content-Type", "application/json")
                .post(payload.toString().toRequestBody(jsonMediaType))
                .build()
            client.newCall(req).execute().use { resp ->
                if (!resp.isSuccessful) error("Approve RPC failed (${resp.code})")
            }
        }
    }

    suspend fun rejectSubmissionRemote(
        accessToken: String,
        submissionId: String,
        reason: String,
    ): Result<Unit> = withContext(Dispatchers.IO) {
        if (!hasValidSupabaseKeys || accessToken.isBlank()) {
            return@withContext Result.failure(IllegalStateException("Offline"))
        }
        runCatching {
            val payload = buildJsonObject {
                put("p_submission_id", submissionId)
                put("p_reason", reason)
            }
            val req = Request.Builder()
                .url("$supabaseUrl/rest/v1/rpc/reject_payment_submission")
                .withSupabaseAuth(accessToken)
                .addHeader("Content-Type", "application/json")
                .post(payload.toString().toRequestBody(jsonMediaType))
                .build()
            client.newCall(req).execute().use { resp ->
                if (!resp.isSuccessful) error("Reject RPC failed (${resp.code})")
            }
        }
    }
}
