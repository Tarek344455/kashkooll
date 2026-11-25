package com.dig.kashkool.core.utils

import com.google.zxing.BarcodeFormat
import com.google.zxing.EncodeHintType
import com.google.zxing.qrcode.QRCodeWriter
import com.google.zxing.qrcode.decoder.ErrorCorrectionLevel

data class QrMatrix(
    val size: Int,
    val modules: BooleanArray,
) {
    fun isDark(x: Int, y: Int): Boolean {
        if (x !in 0 until size || y !in 0 until size) return false
        return modules[y * size + x]
    }
}

object QrMatrixGenerator {
    fun encode(payload: String): QrMatrix {
        val safePayload = payload.ifBlank { "KSH|empty" }
        val hints = mapOf(
            EncodeHintType.ERROR_CORRECTION to ErrorCorrectionLevel.M,
            EncodeHintType.MARGIN to 1,
            EncodeHintType.CHARACTER_SET to "UTF-8",
        )
        val bitMatrix = QRCodeWriter().encode(safePayload, BarcodeFormat.QR_CODE, 0, 0, hints)
        val width = bitMatrix.width
        val height = bitMatrix.height
        val size = maxOf(width, height)
        val modules = BooleanArray(size * size)
        for (y in 0 until height) {
            for (x in 0 until width) {
                modules[y * size + x] = bitMatrix.get(x, y)
            }
        }
        return QrMatrix(size = size, modules = modules)
    }
}
