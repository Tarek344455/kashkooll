package com.dig.kashkool.ui.components

import android.content.ClipData
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Badge
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.ContentCopy
import androidx.compose.material.icons.filled.Fullscreen
import androidx.compose.material.icons.filled.QrCode2
import androidx.compose.material.icons.filled.Timer
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.FilterChip
import androidx.compose.material3.FilterChipDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.ClipEntry
import androidx.compose.ui.platform.LocalClipboard
import androidx.compose.ui.platform.LocalLayoutDirection
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.LayoutDirection
import androidx.compose.ui.unit.dp
import com.dig.kashkool.core.l10n.AppLanguage
import com.dig.kashkool.core.l10n.AppStrings
import com.dig.kashkool.ui.theme.AmberDue
import com.dig.kashkool.ui.theme.CosmicBlack
import com.dig.kashkool.ui.theme.EmeraldValid
import com.dig.kashkool.ui.theme.NeonCyan
import com.dig.kashkool.ui.theme.SpaceSurface
import com.dig.kashkool.ui.theme.TextPrimary
import com.dig.kashkool.ui.theme.TextSecondary
import kotlinx.coroutines.launch

@Composable
fun StudentQrPassCard(
    studentName: String,
    liveToken: String,
    secondsRemaining: Int,
    cardCode: String,
    cardPayload: String,
    checkedInToday: Boolean,
    lang: AppLanguage,
    onCodeCopied: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val clipboard = LocalClipboard.current
    val scope = rememberCoroutineScope()
    var useCardMode by rememberSaveable { mutableStateOf(false) }
    var showFullScreen by remember { mutableStateOf(false) }

    val hasCardPayload = cardPayload.isNotBlank() && cardCode.isNotBlank()
    val effectiveCardMode = useCardMode && hasCardPayload
    val activePayload = if (effectiveCardMode) cardPayload else liveToken
    val activeAccent = if (checkedInToday) EmeraldValid else NeonCyan

    FloatingGlassCard(
        glowColor = activeAccent,
        modifier = modifier
            .fillMaxWidth()
            .testTag("student_qr_pass_card"),
    ) {
        Column(
            modifier = Modifier.fillMaxWidth(),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(10.dp),
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
                        imageVector = Icons.Default.QrCode2,
                        contentDescription = AppStrings.t("student_qr_pass_title", lang),
                        tint = activeAccent,
                    )
                    Column {
                        Text(
                            text = AppStrings.t("student_qr_pass_title", lang),
                            style = MaterialTheme.typography.titleMedium,
                            color = TextPrimary,
                        )
                        if (studentName.isNotBlank()) {
                            Text(
                                text = studentName,
                                style = MaterialTheme.typography.bodySmall,
                                color = TextSecondary,
                            )
                        }
                    }
                }
                StatusPill(
                    label = AppStrings.t(
                        if (checkedInToday) "student_qr_checked_in_today" else "student_qr_ready_scan",
                        lang,
                    ),
                    color = if (checkedInToday) EmeraldValid else AmberDue,
                )
            }

            if (hasCardPayload) {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(8.dp),
                ) {
                    FilterChip(
                        selected = !effectiveCardMode,
                        onClick = { useCardMode = false },
                        modifier = Modifier
                            .weight(1f)
                            .testTag("student_qr_mode_live"),
                        leadingIcon = {
                            Icon(Icons.Default.Timer, contentDescription = null, modifier = Modifier.size(16.dp))
                        },
                        label = { Text(AppStrings.t("student_qr_live_mode", lang)) },
                        colors = FilterChipDefaults.filterChipColors(
                            selectedContainerColor = NeonCyan,
                            selectedLabelColor = CosmicBlack,
                        ),
                    )
                    FilterChip(
                        selected = effectiveCardMode,
                        onClick = { useCardMode = true },
                        modifier = Modifier
                            .weight(1f)
                            .testTag("student_qr_mode_card"),
                        leadingIcon = {
                            Icon(Icons.Default.Badge, contentDescription = null, modifier = Modifier.size(16.dp))
                        },
                        label = { Text(AppStrings.t("student_qr_card_mode", lang)) },
                        colors = FilterChipDefaults.filterChipColors(
                            selectedContainerColor = EmeraldValid,
                            selectedLabelColor = CosmicBlack,
                        ),
                    )
                }
            }

            if (activePayload.isNotBlank()) {
                DynamicQrCanvas(
                    token = activePayload,
                    sizeDp = 176.dp,
                )
            }

            if (effectiveCardMode) {
                CompositionLocalProvider(LocalLayoutDirection provides LayoutDirection.Ltr) {
                    Text(
                        text = cardCode,
                        style = MaterialTheme.typography.titleLarge.copy(
                            fontFamily = FontFamily.Monospace,
                            fontWeight = FontWeight.Bold,
                        ),
                        color = EmeraldValid,
                    )
                }
            } else {
                Text(
                    text = "${AppStrings.t("rotates_in", lang)} ${secondsRemaining}s",
                    style = MaterialTheme.typography.labelLarge,
                    color = NeonCyan,
                )
            }

            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(8.dp),
            ) {
                OutlinedButton(
                    onClick = {
                        val toCopy = if (effectiveCardMode) cardCode else activePayload
                        if (toCopy.isNotBlank()) {
                            scope.launch {
                                clipboard.setClipEntry(ClipEntry(ClipData.newPlainText("kashkool_qr", toCopy)))
                                onCodeCopied()
                            }
                        }
                    },
                    modifier = Modifier
                        .weight(1f)
                        .testTag("student_qr_copy_btn"),
                ) {
                    Icon(
                        imageVector = Icons.Default.ContentCopy,
                        contentDescription = null,
                        tint = NeonCyan,
                        modifier = Modifier
                            .size(18.dp)
                            .padding(end = 4.dp),
                    )
                    Text(AppStrings.t("student_qr_copy_code", lang), color = NeonCyan)
                }
                NeonButton(
                    text = AppStrings.t("student_qr_fullscreen_cta", lang),
                    icon = Icons.Default.Fullscreen,
                    accentColor = activeAccent,
                    onClick = { showFullScreen = true },
                    modifier = Modifier
                        .weight(1f)
                        .testTag("student_qr_fullscreen_btn"),
                )
            }
        }
    }

    if (showFullScreen && activePayload.isNotBlank()) {
        AlertDialog(
            onDismissRequest = { showFullScreen = false },
            containerColor = SpaceSurface,
            title = {
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(8.dp),
                ) {
                    Icon(
                        imageVector = if (checkedInToday) Icons.Default.CheckCircle else Icons.Default.QrCode2,
                        contentDescription = null,
                        tint = activeAccent,
                    )
                    Text(
                        text = studentName.ifBlank { AppStrings.t("student_qr_pass_title", lang) },
                        color = TextPrimary,
                    )
                }
            },
            text = {
                Column(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalAlignment = Alignment.CenterHorizontally,
                    verticalArrangement = Arrangement.spacedBy(12.dp),
                ) {
                    DynamicQrCanvas(
                        token = activePayload,
                        sizeDp = 240.dp,
                    )
                    if (effectiveCardMode) {
                        CompositionLocalProvider(LocalLayoutDirection provides LayoutDirection.Ltr) {
                            Text(
                                text = cardCode,
                                style = MaterialTheme.typography.headlineSmall.copy(
                                    fontFamily = FontFamily.Monospace,
                                    fontWeight = FontWeight.Bold,
                                ),
                                color = EmeraldValid,
                            )
                        }
                    } else {
                        Text(
                            text = "${AppStrings.t("rotates_in", lang)} ${secondsRemaining}s",
                            style = MaterialTheme.typography.titleMedium,
                            color = NeonCyan,
                        )
                    }
                    StatusPill(
                        label = AppStrings.t(
                            if (checkedInToday) "student_qr_checked_in_today" else "student_qr_ready_scan",
                            lang,
                        ),
                        color = if (checkedInToday) EmeraldValid else AmberDue,
                    )
                }
            },
            confirmButton = {
                TextButton(onClick = { showFullScreen = false }) {
                    Text(AppStrings.t("close", lang), color = NeonCyan)
                }
            },
        )
    }
}
