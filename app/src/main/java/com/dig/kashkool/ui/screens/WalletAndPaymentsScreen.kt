package com.dig.kashkool.ui.screens

import android.net.Uri
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.PickVisualMediaRequest
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ReceiptLong
import androidx.compose.material.icons.automirrored.filled.Send
import androidx.compose.material.icons.filled.AttachFile
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.ContentCopy
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.RadioButton
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.ui.platform.LocalClipboardManager
import androidx.compose.ui.platform.LocalLayoutDirection
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.AnnotatedString
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.LayoutDirection
import androidx.compose.ui.unit.dp
import coil.compose.AsyncImage
import com.dig.kashkool.core.l10n.AppLanguage
import com.dig.kashkool.core.l10n.AppStrings
import com.dig.kashkool.core.utils.EgyptValidators
import com.dig.kashkool.data.local.LedgerEntryEntity
import com.dig.kashkool.data.local.LedgerKind
import com.dig.kashkool.data.local.PaymentChannelEntity
import com.dig.kashkool.data.local.SubmissionStatus
import com.dig.kashkool.ui.components.EmptyStateCard
import com.dig.kashkool.ui.components.FloatingGlassCard
import com.dig.kashkool.ui.components.NeonButton
import com.dig.kashkool.ui.components.StatusPill
import com.dig.kashkool.ui.theme.AmberDue
import com.dig.kashkool.ui.theme.CrimsonBlocked
import com.dig.kashkool.ui.theme.ElectricBlue
import com.dig.kashkool.ui.theme.EmeraldValid
import com.dig.kashkool.ui.theme.NeonCyan
import com.dig.kashkool.ui.theme.SolarGold
import com.dig.kashkool.ui.theme.SpaceSurface
import com.dig.kashkool.ui.theme.TextPrimary
import com.dig.kashkool.ui.theme.TextSecondary
import com.dig.kashkool.ui.viewmodel.KashkoolUiState

import androidx.compose.material3.CircularProgressIndicator

@Composable
fun WalletAndPaymentsScreen(
    state: KashkoolUiState,
    onSubmitReceipt: (PaymentChannelEntity, String, String, String?) -> Unit,
    onVoidLedgerEntry: (String, String) -> Unit,
    onCompressReceipt: (Uri) -> Unit = {},
    onClearCompressedReceipt: () -> Unit = {},
) {
    val lang = state.language
    val clipboard = LocalClipboardManager.current

    var selectedChannelId by rememberSaveable { mutableStateOf(state.channels.firstOrNull()?.id.orEmpty()) }
    var amountText by rememberSaveable { mutableStateOf("") }
    var senderRef by rememberSaveable { mutableStateOf("") }
    var voidTarget by remember { mutableStateOf<LedgerEntryEntity?>(null) }

    // Zero-permission Android Photo Picker per Play Policy + <=150KB compression for Supabase Free Tier
    val photoPicker = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.PickVisualMedia()
    ) { uri ->
        if (uri != null) onCompressReceipt(uri)
    }

    val selectedChannel = state.channels.firstOrNull { it.id == selectedChannelId }
        ?: state.channels.firstOrNull()

    LazyColumn(
        modifier = Modifier.fillMaxSize(),
        contentPadding = PaddingValues(16.dp),
        verticalArrangement = Arrangement.spacedBy(14.dp),
    ) {
        item {
            FloatingGlassCard(
                glowColor = NeonCyan,
                modifier = Modifier.fillMaxWidth(),
            ) {
                Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                    Text(
                        text = AppStrings.t("select_channel", lang),
                        style = MaterialTheme.typography.titleMedium,
                        color = TextPrimary,
                    )
                    state.channels.forEach { ch ->
                        val isSelected = selectedChannel?.id == ch.id
                        FloatingGlassCard(
                            glowColor = if (isSelected) NeonCyan else ElectricBlue.copy(alpha = 0.3f),
                            contentPadding = PaddingValues(horizontal = 10.dp, vertical = 8.dp),
                            onClick = { selectedChannelId = ch.id },
                            modifier = Modifier.fillMaxWidth(),
                        ) {
                            Row(
                                modifier = Modifier.fillMaxWidth(),
                                verticalAlignment = Alignment.CenterVertically,
                            ) {
                                RadioButton(
                                    selected = isSelected,
                                    onClick = { selectedChannelId = ch.id },
                                )
                                Column(modifier = Modifier.weight(1f)) {
                                    Row(
                                        verticalAlignment = Alignment.CenterVertically,
                                        horizontalArrangement = Arrangement.spacedBy(6.dp),
                                    ) {
                                        Text(
                                            text = if (lang == AppLanguage.AR) ch.nameAr else ch.nameEn,
                                            style = MaterialTheme.typography.bodyLarge,
                                            color = TextPrimary,
                                        )
                                        if (ch.feePiasters == 0L) {
                                            StatusPill(
                                                label = AppStrings.t("zero_fee", lang),
                                                color = EmeraldValid,
                                            )
                                        }
                                    }
                                    CompositionLocalProvider(LocalLayoutDirection provides LayoutDirection.Ltr) {
                                        Text(
                                            text = ch.accountRef,
                                            style = MaterialTheme.typography.bodySmall,
                                            color = NeonCyan,
                                        )
                                    }
                                }
                                IconButton(
                                    onClick = { clipboard.setText(AnnotatedString(ch.accountRef)) }
                                ) {
                                    Icon(
                                        imageVector = Icons.Default.ContentCopy,
                                        contentDescription = AppStrings.t("copy_receipt", lang),
                                        tint = TextSecondary,
                                    )
                                }
                            }
                        }
                    }

                    OutlinedTextField(
                        value = amountText,
                        onValueChange = { amountText = it },
                        label = { Text(AppStrings.t("amount_egp", lang)) },
                        keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Decimal),
                        singleLine = true,
                        modifier = Modifier
                            .fillMaxWidth()
                            .testTag("checkout_amount_input"),
                    )

                    OutlinedTextField(
                        value = senderRef,
                        onValueChange = { senderRef = it },
                        label = { Text(AppStrings.t("sender_ref", lang)) },
                        singleLine = true,
                        modifier = Modifier
                            .fillMaxWidth()
                            .testTag("checkout_sender_ref_input"),
                    )

                    val compressed = state.compressedReceipt
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.spacedBy(10.dp),
                        verticalAlignment = Alignment.CenterVertically,
                    ) {
                        OutlinedButton(
                            onClick = {
                                photoPicker.launch(
                                    PickVisualMediaRequest(ActivityResultContracts.PickVisualMedia.ImageOnly)
                                )
                            },
                            enabled = !state.receiptCompressing,
                            modifier = Modifier
                                .weight(1f)
                                .testTag("checkout_attach_receipt_button"),
                        ) {
                            if (state.receiptCompressing) {
                                CircularProgressIndicator(
                                    modifier = Modifier.size(16.dp),
                                    strokeWidth = 2.dp,
                                    color = NeonCyan,
                                )
                            } else {
                                Icon(
                                    imageVector = if (compressed == null) Icons.Default.AttachFile else Icons.Default.CheckCircle,
                                    contentDescription = null,
                                    tint = if (compressed == null) NeonCyan else EmeraldValid,
                                    modifier = Modifier.padding(end = 6.dp),
                                )
                            }
                            Text(
                                text = AppStrings.t(
                                    when {
                                        state.receiptCompressing -> "compressing_receipt"
                                        compressed == null -> "attach_receipt"
                                        else -> "receipt_attached"
                                    },
                                    lang,
                                ),
                                color = TextPrimary,
                            )
                        }
                        if (compressed != null) {
                            AsyncImage(
                                model = compressed.localUri,
                                contentDescription = AppStrings.t("receipt_attached", lang),
                                modifier = Modifier.size(48.dp),
                            )
                        }
                    }

                    if (compressed != null) {
                        val kb = (compressed.compressedBytes / 1024L).coerceAtLeast(1L)
                        StatusPill(
                            label = "${AppStrings.t("compressed_badge", lang)} · $kb KB (-${compressed.savingsPercent}%)",
                            color = EmeraldValid,
                        )
                    }

                    NeonButton(
                        text = AppStrings.t("submit_receipt", lang),
                        icon = Icons.AutoMirrored.Filled.Send,
                        enabled = selectedChannel != null && amountText.isNotBlank() && senderRef.isNotBlank() && !state.receiptCompressing,
                        onClick = {
                            if (selectedChannel != null) {
                                onSubmitReceipt(
                                    selectedChannel,
                                    amountText,
                                    senderRef,
                                    compressed?.localUri,
                                )
                                amountText = ""
                                senderRef = ""
                                onClearCompressedReceipt()
                            }
                        },
                        modifier = Modifier
                            .fillMaxWidth()
                            .testTag("checkout_submit_button"),
                    )
                }
            }
        }

        if (state.submissions.isNotEmpty()) {
            item {
                Text(
                    text = AppStrings.t("submissions_history", lang),
                    style = MaterialTheme.typography.titleLarge,
                    color = TextPrimary,
                )
            }
            items(state.submissions, key = { it.id }) { sub ->
                val pillColor = when (sub.status) {
                    SubmissionStatus.APPROVED.key -> EmeraldValid
                    SubmissionStatus.REJECTED.key -> CrimsonBlocked
                    else -> AmberDue
                }
                val statusKey = when (sub.status) {
                    SubmissionStatus.APPROVED.key -> "status_approved"
                    SubmissionStatus.REJECTED.key -> "status_rejected"
                    else -> "status_pending"
                }
                FloatingGlassCard(glowColor = pillColor, modifier = Modifier.fillMaxWidth()) {
                    Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.SpaceBetween,
                            verticalAlignment = Alignment.CenterVertically,
                        ) {
                            Text(
                                text = "${sub.channelName} · ${sub.senderReference}",
                                style = MaterialTheme.typography.titleMedium,
                                color = TextPrimary,
                            )
                            StatusPill(label = AppStrings.t(statusKey, lang), color = pillColor)
                        }
                        Text(
                            text = EgyptValidators.formatPiasters(sub.amountPiasters, lang.code),
                            style = MaterialTheme.typography.bodyMedium,
                            color = NeonCyan,
                        )
                        if (!sub.rejectionReason.isNullOrBlank()) {
                            Text(
                                text = sub.rejectionReason,
                                style = MaterialTheme.typography.bodySmall,
                                color = CrimsonBlocked,
                            )
                        }
                    }
                }
            }
        }

        item {
            Text(
                text = AppStrings.t("immutable_ledger", lang),
                style = MaterialTheme.typography.titleLarge,
                color = TextPrimary,
            )
        }

        if (state.ledger.isEmpty()) {
            item {
                EmptyStateCard(
                    icon = Icons.AutoMirrored.Filled.ReceiptLong,
                    message = AppStrings.t("no_pending_receipts", lang),
                )
            }
        } else {
            val voidedIds = state.ledger.mapNotNull { it.voidedEntryId }.toSet()
            items(state.ledger, key = { it.id }) { entry ->
                val isVoid = entry.kind == LedgerKind.VOID_ENTRY.key
                val alreadyVoided = voidedIds.contains(entry.id)
                val color = when {
                    isVoid -> CrimsonBlocked
                    entry.kind == LedgerKind.SETTLEMENT.key -> SolarGold
                    else -> EmeraldValid
                }
                FloatingGlassCard(glowColor = color, modifier = Modifier.fillMaxWidth()) {
                    Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.SpaceBetween,
                            verticalAlignment = Alignment.CenterVertically,
                        ) {
                            Text(
                                text = if (lang == AppLanguage.AR) entry.studentNameAr else entry.studentNameEn,
                                style = MaterialTheme.typography.titleMedium,
                                color = TextPrimary,
                            )
                            Text(
                                text = EgyptValidators.formatPiasters(entry.amountPiasters, lang.code),
                                style = MaterialTheme.typography.titleMedium,
                                color = color,
                            )
                        }
                        Text(
                            text = "${AppStrings.ledgerKindLabel(entry.kind, lang)} · ${entry.note}",
                            style = MaterialTheme.typography.bodySmall,
                            color = TextSecondary,
                        )
                        if (!isVoid && !alreadyVoided) {
                            OutlinedButton(
                                onClick = { voidTarget = entry },
                                modifier = Modifier.testTag("void_entry_${entry.id}"),
                            ) {
                                Text(AppStrings.t("void_entry", lang), color = CrimsonBlocked)
                            }
                        } else if (alreadyVoided) {
                            StatusPill(label = AppStrings.t("status_voided", lang), color = CrimsonBlocked)
                        }
                    }
                }
            }
        }
    }

    voidTarget?.let { target ->
        var reason by remember { mutableStateOf("") }
        AlertDialog(
            onDismissRequest = { voidTarget = null },
            containerColor = SpaceSurface,
            title = { Text(AppStrings.t("void_entry", lang), color = TextPrimary) },
            text = {
                OutlinedTextField(
                    value = reason,
                    onValueChange = { reason = it },
                    label = { Text(AppStrings.t("void_reason", lang)) },
                    modifier = Modifier.fillMaxWidth(),
                )
            },
            confirmButton = {
                NeonButton(
                    text = AppStrings.t("submit", lang),
                    accentColor = CrimsonBlocked,
                    enabled = reason.isNotBlank(),
                    onClick = {
                        onVoidLedgerEntry(target.id, reason)
                        voidTarget = null
                    },
                )
            },
            dismissButton = {
                TextButton(onClick = { voidTarget = null }) {
                    Text(AppStrings.t("close", lang), color = TextSecondary)
                }
            },
        )
    }
}
