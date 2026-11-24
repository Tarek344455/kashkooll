package com.dig.kashkool.core.utils

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.net.Uri
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.io.ByteArrayOutputStream
import java.io.File
import java.util.UUID
import kotlin.math.max
import kotlin.math.roundToInt

data class CompressedReceiptResult(
    val localUri: String,
    val filePath: String,
    val originalBytes: Long,
    val compressedBytes: Long,
    val quality: Int,
) {
    val savingsPercent: Int
        get() = EgyptValidators.dataSavingsPercent(originalBytes, compressedBytes)
}

/**
 * Zero-Cost Receipt Compressor:
 * Downscales receipt photos to <= 1280px and encodes JPEG <= 150 KB so student
 * mobile data bundles and Supabase Free Tier (1 GB) storage stay protected.
 */
object ImageCompressor {
    const val DEFAULT_MAX_BYTES = 150 * 1024
    const val MAX_DIMENSION_PX = 1280

    suspend fun compressReceiptUri(
        context: Context,
        sourceUri: Uri,
        maxBytes: Int = DEFAULT_MAX_BYTES,
    ): Result<CompressedReceiptResult> = withContext(Dispatchers.IO) {
        runCatching {
            val rawBytes = context.contentResolver.openInputStream(sourceUri)?.use { it.readBytes() }
                ?: error("Could not read selected image")
            val originalSize = rawBytes.size.toLong()

            val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
            BitmapFactory.decodeByteArray(rawBytes, 0, rawBytes.size, bounds)
            if (bounds.outWidth <= 0 || bounds.outHeight <= 0) {
                error("Unsupported image format")
            }

            val sampleSize = calculateInSampleSize(bounds.outWidth, bounds.outHeight, MAX_DIMENSION_PX)
            val decodeOpts = BitmapFactory.Options().apply { inSampleSize = sampleSize }
            val sampled = BitmapFactory.decodeByteArray(rawBytes, 0, rawBytes.size, decodeOpts)
                ?: error("Could not decode image")

            val scaled = scaleDownIfNeeded(sampled, MAX_DIMENSION_PX)
            if (scaled !== sampled) sampled.recycle()

            val (compressed, usedQuality) = encodeWithinBudget(scaled, maxBytes)
            scaled.recycle()

            if (compressed.size > maxBytes * 2) {
                error("Image too large even after compression")
            }

            val outDir = File(context.filesDir, "receipts_cache").apply { mkdirs() }
            val outFile = File(outDir, "rcpt_${UUID.randomUUID()}.jpg")
            outFile.writeBytes(compressed)

            CompressedReceiptResult(
                localUri = Uri.fromFile(outFile).toString(),
                filePath = outFile.absolutePath,
                originalBytes = originalSize,
                compressedBytes = compressed.size.toLong(),
                quality = usedQuality,
            )
        }
    }

    internal fun encodeWithinBudget(bitmap: Bitmap, maxBytes: Int): Pair<ByteArray, Int> {
        var quality = 88
        var bestBytes = ByteArray(0)
        var bestQuality = quality
        while (quality >= 36) {
            val stream = ByteArrayOutputStream()
            bitmap.compress(Bitmap.CompressFormat.JPEG, quality, stream)
            val candidate = stream.toByteArray()
            bestBytes = candidate
            bestQuality = quality
            if (candidate.size <= maxBytes) break
            quality -= 10
        }
        return bestBytes to bestQuality
    }

    internal fun calculateInSampleSize(width: Int, height: Int, maxDim: Int): Int {
        var sample = 1
        var w = width
        var h = height
        while (w / 2 >= maxDim || h / 2 >= maxDim) {
            w /= 2
            h /= 2
            sample *= 2
        }
        return sample
    }

    private fun scaleDownIfNeeded(bitmap: Bitmap, maxDim: Int): Bitmap {
        val largest = max(bitmap.width, bitmap.height)
        if (largest <= maxDim) return bitmap
        val ratio = maxDim.toFloat() / largest.toFloat()
        val targetW = (bitmap.width * ratio).roundToInt().coerceAtLeast(1)
        val targetH = (bitmap.height * ratio).roundToInt().coerceAtLeast(1)
        return Bitmap.createScaledBitmap(bitmap, targetW, targetH, true)
    }
}
