package com.dig.kashkool.core.utils

import java.nio.charset.StandardCharsets
import java.security.MessageDigest
import java.util.Locale
import javax.crypto.Mac
import javax.crypto.spec.SecretKeySpec

object EgyptValidators {

    private val phoneRegex = Regex("^(?:\\+|00)?(?:20)?0?1[0125][0-9]{8}$")

    fun isValidEgyptianPhone(phone: String): Boolean {
        val clean = phone.replace(Regex("[\\s\\-()]+"), "")
        return phoneRegex.matches(clean)
    }

    fun normalizeEgyptianPhone(phone: String): String {
        val clean = phone.replace(Regex("[\\s\\-()]+"), "")
        if (!isValidEgyptianPhone(clean)) return ""
        var digits = clean.replace(Regex("^(\\+|00)"), "")
        if (digits.startsWith("20")) digits = digits.substring(2)
        if (digits.startsWith("0")) digits = digits.substring(1)
        return "+20$digits"
    }

    fun formatPiasters(piasters: Long, lang: String = "ar"): String {
        val egp = piasters / 100.0
        val formatted = if (piasters % 100L == 0L) {
            (piasters / 100L).toString()
        } else {
            String.format(Locale.US, "%.2f", egp)
        }
        return if (lang == "ar") "$formatted ج.م" else "$formatted EGP"
    }

    fun egpStringToPiasters(raw: String): Long? {
        val value = raw.trim().toDoubleOrNull() ?: return null
        if (!value.isFinite() || value <= 0.0) return null
        return Math.round(value * 100.0)
    }

    fun sha256Hex(raw: String): String {
        val digest = MessageDigest.getInstance("SHA-256")
            .digest(raw.toByteArray(StandardCharsets.UTF_8))
        return digest.joinToString("") { "%02x".format(it) }
    }

    private const val QR_ALPHABET = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"

    fun generateActivationCode(length: Int = 8): String {
        val rng = java.security.SecureRandom()
        return buildString(length) {
            repeat(length) {
                append(QR_ALPHABET[rng.nextInt(QR_ALPHABET.length)])
            }
        }
    }

    fun normalizeQrCode(raw: String): String =
        raw.trim().uppercase(Locale.US).replace(Regex("[\\s-]+"), "")

    fun isValidQrActivationCode(raw: String): Boolean {
        val clean = normalizeQrCode(raw)
        return clean.length in 6..24 && clean.all { it.isLetterOrDigit() }
    }

    fun dataSavingsPercent(originalBytes: Long, compressedBytes: Long): Int {
        if (originalBytes <= 0L || compressedBytes >= originalBytes) return 0
        return (((originalBytes - compressedBytes) * 100L) / originalBytes).toInt().coerceIn(0, 99)
    }
}

enum class QrVerifyStatus { VALID, EXPIRED, INVALID }

data class QrVerifyResult(
    val status: QrVerifyStatus,
    val sessionId: String? = null,
)

class DynamicQrEngine(
    private val sessionId: String,
    private val sessionSecret: String,
    private val windowSeconds: Long = 30L,
) {
    private fun signatureForBucket(targetSessionId: String, bucket: Long): String {
        val payload = "$targetSessionId:$bucket"
        val mac = Mac.getInstance("HmacSHA256")
        mac.init(SecretKeySpec(sessionSecret.toByteArray(StandardCharsets.UTF_8), "HmacSHA256"))
        return mac.doFinal(payload.toByteArray(StandardCharsets.UTF_8))
            .take(8)
            .joinToString("") { "%02x".format(it) }
    }

    fun tokenAt(epochSeconds: Long = System.currentTimeMillis() / 1000L): String {
        val bucket = epochSeconds / windowSeconds
        val sig = signatureForBucket(sessionId, bucket)
        return "KSH|$sessionId|$bucket|$sig"
    }

    fun secondsRemaining(epochSeconds: Long = System.currentTimeMillis() / 1000L): Int {
        val rem = windowSeconds - (epochSeconds % windowSeconds)
        return rem.toInt()
    }

    fun verifyToken(
        rawToken: String,
        epochSeconds: Long = System.currentTimeMillis() / 1000L,
    ): QrVerifyResult {
        val parts = rawToken.trim().split("|")
        if (parts.size != 4 || parts[0] != "KSH") {
            return QrVerifyResult(QrVerifyStatus.INVALID)
        }
        val tokenSession = parts[1]
        val tokenBucket = parts[2].toLongOrNull() ?: return QrVerifyResult(QrVerifyStatus.INVALID)
        val tokenSig = parts[3]
        if (tokenSession != sessionId) {
            return QrVerifyResult(QrVerifyStatus.INVALID, tokenSession)
        }
        val expectedSig = signatureForBucket(tokenSession, tokenBucket)
        if (!expectedSig.equals(tokenSig, ignoreCase = true)) {
            return QrVerifyResult(QrVerifyStatus.INVALID, tokenSession)
        }
        val currentBucket = epochSeconds / windowSeconds
        return if (tokenBucket == currentBucket || tokenBucket == currentBucket - 1L) {
            QrVerifyResult(QrVerifyStatus.VALID, tokenSession)
        } else {
            QrVerifyResult(QrVerifyStatus.EXPIRED, tokenSession)
        }
    }
}
