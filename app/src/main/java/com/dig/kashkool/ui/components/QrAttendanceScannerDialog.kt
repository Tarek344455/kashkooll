package com.dig.kashkool.ui.components

import android.Manifest
import android.content.pm.PackageManager
import android.media.AudioManager
import android.media.ToneGenerator
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.PickVisualMediaRequest
import androidx.activity.result.contract.ActivityResultContracts
import androidx.camera.core.CameraSelector
import androidx.camera.core.ImageAnalysis
import androidx.camera.mlkit.vision.MlKitAnalyzer
import androidx.camera.view.CameraController
import androidx.camera.view.LifecycleCameraController
import androidx.camera.view.PreviewView
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.CameraAlt
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.FlashOff
import androidx.compose.material.icons.filled.FlashOn
import androidx.compose.material.icons.filled.PhotoLibrary
import androidx.compose.material.icons.filled.QrCodeScanner
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableLongStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.hapticfeedback.HapticFeedbackType
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalHapticFeedback
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.viewinterop.AndroidView
import androidx.compose.ui.window.Dialog
import androidx.compose.ui.window.DialogProperties
import androidx.core.content.ContextCompat
import androidx.lifecycle.compose.LocalLifecycleOwner
import com.dig.kashkool.core.l10n.AppLanguage
import com.dig.kashkool.core.l10n.AppStrings
import com.dig.kashkool.ui.theme.AmberDue
import com.dig.kashkool.ui.theme.CrimsonBlocked
import com.dig.kashkool.ui.theme.EmeraldValid
import com.dig.kashkool.ui.theme.NeonCyan
import com.dig.kashkool.ui.theme.SpaceSurface
import com.dig.kashkool.ui.theme.TextPrimary
import com.dig.kashkool.ui.theme.TextSecondary
import com.dig.kashkool.ui.viewmodel.ScanFeedback
import com.google.mlkit.vision.barcode.BarcodeScannerOptions
import com.google.mlkit.vision.barcode.BarcodeScanning
import com.google.mlkit.vision.barcode.common.Barcode
import com.google.mlkit.vision.common.InputImage

@Composable
fun QrAttendanceScannerDialog(
    lang: AppLanguage,
    lastScanFeedback: ScanFeedback?,
    scannedCount: Int,
    onPayloadScanned: (String) -> Unit,
    onDismiss: () -> Unit,
) {
    val context = LocalContext.current
    val lifecycleOwner = LocalLifecycleOwner.current
    val haptics = LocalHapticFeedback.current

    var hasCameraPermission by remember {
        mutableStateOf(
            ContextCompat.checkSelfPermission(context, Manifest.permission.CAMERA) ==
                PackageManager.PERMISSION_GRANTED
        )
    }
    var torchEnabled by remember { mutableStateOf(false) }
    var lastDecodedValue by remember { mutableStateOf<String?>(null) }
    var lastDecodedAtMillis by remember { mutableLongStateOf(0L) }

    val barcodeScanner = remember {
        val options = BarcodeScannerOptions.Builder()
            .setBarcodeFormats(Barcode.FORMAT_QR_CODE)
            .build()
        BarcodeScanning.getClient(options)
    }

    val toneGenerator = remember {
        runCatching { ToneGenerator(AudioManager.STREAM_NOTIFICATION, 85) }.getOrNull()
    }

    val permissionLauncher = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.RequestPermission(),
    ) { granted ->
        hasCameraPermission = granted
    }

    val photoPickerLauncher = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.PickVisualMedia(),
    ) { uri ->
        if (uri != null) {
            runCatching { InputImage.fromFilePath(context, uri) }.onSuccess { image ->
                barcodeScanner.process(image).addOnSuccessListener { barcodes ->
                    val raw = barcodes.firstNotNullOfOrNull { it.rawValue?.trim() }
                    if (!raw.isNullOrBlank()) {
                        onPayloadScanned(raw)
                    }
                }
            }
        }
    }

    LaunchedEffect(Unit) {
        if (!hasCameraPermission) {
            permissionLauncher.launch(Manifest.permission.CAMERA)
        }
    }

    LaunchedEffect(lastScanFeedback?.timestampMillis) {
        val fb = lastScanFeedback ?: return@LaunchedEffect
        haptics.performHapticFeedback(HapticFeedbackType.LongPress)
        runCatching {
            val tone = when (fb.status) {
                "valid", "due" -> ToneGenerator.TONE_PROP_ACK
                "already" -> ToneGenerator.TONE_PROP_BEEP2
                else -> ToneGenerator.TONE_PROP_NACK
            }
            toneGenerator?.startTone(tone, 140)
        }
    }

    val cameraController = remember(hasCameraPermission) {
        if (!hasCameraPermission) null
        else LifecycleCameraController(context).apply {
            setEnabledUseCases(CameraController.IMAGE_ANALYSIS)
            cameraSelector = CameraSelector.DEFAULT_BACK_CAMERA
        }
    }

    DisposableEffect(cameraController, lifecycleOwner, barcodeScanner) {
        if (cameraController != null) {
            val executor = ContextCompat.getMainExecutor(context)
            cameraController.setImageAnalysisAnalyzer(
                executor,
                MlKitAnalyzer(
                    listOf(barcodeScanner),
                    ImageAnalysis.COORDINATE_SYSTEM_VIEW_REFERENCED,
                    executor,
                ) { result ->
                    val barcodes = result?.getValue(barcodeScanner).orEmpty()
                    val raw = barcodes.firstNotNullOfOrNull { it.rawValue?.trim() }
                    if (!raw.isNullOrBlank()) {
                        val now = System.currentTimeMillis()
                        val withinCooldown = raw == lastDecodedValue && (now - lastDecodedAtMillis) < 3500L
                        if (!withinCooldown) {
                            lastDecodedValue = raw
                            lastDecodedAtMillis = now
                            onPayloadScanned(raw)
                        }
                    }
                },
            )
            cameraController.bindToLifecycle(lifecycleOwner)
        }
        onDispose {
            cameraController?.unbind()
        }
    }

    DisposableEffect(Unit) {
        onDispose {
            runCatching { barcodeScanner.close() }
            runCatching { toneGenerator?.release() }
        }
    }

    Dialog(
        onDismissRequest = onDismiss,
        properties = DialogProperties(usePlatformDefaultWidth = false),
    ) {
        Surface(
            color = SpaceSurface,
            shape = RoundedCornerShape(24.dp),
            modifier = Modifier
                .fillMaxWidth(0.94f)
                .border(1.dp, NeonCyan.copy(alpha = 0.35f), RoundedCornerShape(24.dp))
                .testTag("qr_attendance_scanner_dialog"),
        ) {
            Column(
                modifier = Modifier.padding(16.dp),
                verticalArrangement = Arrangement.spacedBy(12.dp),
            ) {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    Row(
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(8.dp),
                        modifier = Modifier.weight(1f),
                    ) {
                        Icon(
                            imageVector = Icons.Default.QrCodeScanner,
                            contentDescription = AppStrings.t("qr_scanner_title", lang),
                            tint = NeonCyan,
                        )
                        Column {
                            Text(
                                text = AppStrings.t("qr_scanner_title", lang),
                                style = MaterialTheme.typography.titleMedium,
                                color = TextPrimary,
                            )
                            Text(
                                text = "${AppStrings.t("qr_scanned_count", lang)}: $scannedCount",
                                style = MaterialTheme.typography.labelMedium,
                                color = EmeraldValid,
                            )
                        }
                    }
                    if (cameraController != null) {
                        IconButton(
                            onClick = {
                                torchEnabled = !torchEnabled
                                cameraController.enableTorch(torchEnabled)
                            },
                            modifier = Modifier.testTag("scanner_torch_button"),
                        ) {
                            Icon(
                                imageVector = if (torchEnabled) Icons.Default.FlashOn else Icons.Default.FlashOff,
                                contentDescription = AppStrings.t("qr_torch_toggle", lang),
                                tint = if (torchEnabled) AmberDue else TextSecondary,
                            )
                        }
                    }
                    IconButton(
                        onClick = onDismiss,
                        modifier = Modifier.testTag("scanner_close_button"),
                    ) {
                        Icon(
                            imageVector = Icons.Default.Close,
                            contentDescription = AppStrings.t("close", lang),
                            tint = TextSecondary,
                        )
                    }
                }

                Text(
                    text = AppStrings.t("qr_scanner_subtitle", lang),
                    style = MaterialTheme.typography.bodySmall,
                    color = TextSecondary,
                )

                if (hasCameraPermission && cameraController != null) {
                    Box(
                        modifier = Modifier
                            .fillMaxWidth()
                            .height(290.dp)
                            .clip(RoundedCornerShape(18.dp))
                            .border(2.dp, NeonCyan.copy(alpha = 0.65f), RoundedCornerShape(18.dp)),
                        contentAlignment = Alignment.Center,
                    ) {
                        AndroidView(
                            factory = { ctx ->
                                PreviewView(ctx).apply {
                                    controller = cameraController
                                    scaleType = PreviewView.ScaleType.FILL_CENTER
                                }
                            },
                            modifier = Modifier.fillMaxSize(),
                        )
                        Box(
                            modifier = Modifier
                                .size(190.dp)
                                .border(2.dp, EmeraldValid.copy(alpha = 0.8f), RoundedCornerShape(16.dp)),
                        )
                    }
                } else {
                    FloatingGlassCard(
                        glowColor = AmberDue,
                        modifier = Modifier.fillMaxWidth(),
                    ) {
                        Column(
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(vertical = 8.dp),
                            horizontalAlignment = Alignment.CenterHorizontally,
                            verticalArrangement = Arrangement.spacedBy(10.dp),
                        ) {
                            Icon(
                                imageVector = Icons.Default.CameraAlt,
                                contentDescription = null,
                                tint = AmberDue,
                                modifier = Modifier.size(40.dp),
                            )
                            Text(
                                text = AppStrings.t("qr_camera_perm_needed", lang),
                                style = MaterialTheme.typography.bodyMedium,
                                color = TextPrimary,
                                textAlign = TextAlign.Center,
                            )
                            NeonButton(
                                text = AppStrings.t("qr_grant_camera_cta", lang),
                                icon = Icons.Default.CameraAlt,
                                accentColor = NeonCyan,
                                onClick = { permissionLauncher.launch(Manifest.permission.CAMERA) },
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .testTag("scanner_grant_camera_button"),
                            )
                        }
                    }
                }

                lastScanFeedback?.let { fb ->
                    val (accent, badgeKey) = when (fb.status) {
                        "valid" -> EmeraldValid to "scan_valid"
                        "due" -> AmberDue to "scan_due"
                        "already" -> NeonCyan to "qr_already_checked_in"
                        else -> CrimsonBlocked to "scan_blocked"
                    }
                    FloatingGlassCard(
                        glowColor = accent,
                        modifier = Modifier
                            .fillMaxWidth()
                            .testTag("scanner_feedback_card"),
                    ) {
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.SpaceBetween,
                            verticalAlignment = Alignment.CenterVertically,
                        ) {
                            Column(modifier = Modifier.weight(1f)) {
                                Text(
                                    text = fb.studentName,
                                    style = MaterialTheme.typography.titleMedium,
                                    color = TextPrimary,
                                )
                                if (fb.detail.isNotBlank()) {
                                    Text(
                                        text = fb.detail,
                                        style = MaterialTheme.typography.bodySmall,
                                        color = accent,
                                    )
                                }
                            }
                            StatusPill(
                                label = AppStrings.t(badgeKey, lang),
                                color = accent,
                            )
                        }
                    }
                }

                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    OutlinedButton(
                        onClick = {
                            photoPickerLauncher.launch(
                                PickVisualMediaRequest(ActivityResultContracts.PickVisualMedia.ImageOnly)
                            )
                        },
                        modifier = Modifier.testTag("scanner_pick_photo_button"),
                    ) {
                        Icon(
                            imageVector = Icons.Default.PhotoLibrary,
                            contentDescription = null,
                            tint = NeonCyan,
                            modifier = Modifier
                                .size(18.dp)
                                .padding(end = 6.dp),
                        )
                        Text(AppStrings.t("qr_scan_from_photo_cta", lang), color = NeonCyan)
                    }
                    TextButton(onClick = onDismiss) {
                        Text(AppStrings.t("close", lang), color = TextSecondary)
                    }
                }
            }
        }
    }
}
