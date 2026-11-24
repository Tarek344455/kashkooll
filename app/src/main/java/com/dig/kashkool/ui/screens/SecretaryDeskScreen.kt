package com.dig.kashkool.ui.screens

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.AccountBalance
import androidx.compose.material.icons.filled.Block
import androidx.compose.material.icons.filled.Bolt
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.NotificationsActive
import androidx.compose.material.icons.filled.Payments
import androidx.compose.material.icons.filled.PersonAdd
import androidx.compose.material.icons.filled.Print
import androidx.compose.material.icons.filled.QrCode2
import androidx.compose.material.icons.filled.QrCodeScanner
import androidx.compose.material.icons.filled.Search
import androidx.compose.material.icons.filled.Share
import androidx.compose.material.icons.filled.VerifiedUser
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.FilterChip
import androidx.compose.material3.FilterChipDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.hapticfeedback.HapticFeedbackType
import androidx.compose.ui.platform.LocalClipboardManager
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalHapticFeedback
import androidx.compose.ui.platform.LocalLayoutDirection
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.AnnotatedString
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.unit.LayoutDirection
import androidx.compose.ui.unit.dp
import com.dig.kashkool.core.l10n.AppLanguage
import com.dig.kashkool.core.l10n.AppStrings
import com.dig.kashkool.core.utils.EgyptValidators
import com.dig.kashkool.core.utils.QrVerifyStatus
import com.dig.kashkool.core.utils.ShareHelper
import com.dig.kashkool.data.local.LedgerKind
import com.dig.kashkool.data.local.StudentEntity
import com.dig.kashkool.ui.components.DynamicQrCanvas
import com.dig.kashkool.ui.components.EmptyStateCard
import com.dig.kashkool.ui.components.FloatingGlassCard
import com.dig.kashkool.ui.components.NeonButton
import com.dig.kashkool.ui.components.StatusPill
import com.dig.kashkool.ui.theme.AmberDue
import com.dig.kashkool.ui.theme.CosmicBlack
import com.dig.kashkool.ui.theme.CrimsonBlocked
import com.dig.kashkool.ui.theme.EmeraldValid
import com.dig.kashkool.ui.theme.NebulaPurple
import com.dig.kashkool.ui.theme.NeonCyan
import com.dig.kashkool.ui.theme.SolarGold
import com.dig.kashkool.ui.theme.SpaceSurface
import com.dig.kashkool.ui.theme.TextPrimary
import com.dig.kashkool.ui.theme.TextSecondary
import com.dig.kashkool.ui.viewmodel.KashkoolUiState

@OptIn(ExperimentalLayoutApi::class)
@Composable
fun SecretaryDeskScreen(
    state: KashkoolUiState,
    onCheckInStudent: (StudentEntity) -> Unit,
    onRecordCashEntry: (StudentEntity, LedgerKind, String, String) -> Unit,
    buildThermalReceipt: (AppLanguage) -> String,
    onGenerateQrCode: (StudentEntity) -> Unit = {},
    onDismissGeneratedQr: () -> Unit = {},
    onToggleRushMode: () -> Unit = {},
    onDiscreetAllow: (StudentEntity) -> Unit = {},
    onVerifyQrToken: (String) -> Unit = {},
    onAddWalkInStudent: (String, String, String, String) -> Unit = { _, _, _, _ -> },
    onToggleBlockStudent: (StudentEntity) -> Unit = {},
) {
    val lang = state.language
    val haptics = LocalHapticFeedback.current
    val clipboard = LocalClipboardManager.current
    val context = LocalContext.current

    var searchQuery by rememberSaveable { mutableStateOf("") }
    var tokenInput by rememberSaveable { mutableStateOf("") }
    var cashDialogStudent by remember { mutableStateOf<StudentEntity?>(null) }
    var showReceiptDialog by remember { mutableStateOf(false) }
    var showDrawerDialog by remember { mutableStateOf(false) }
    var showWalkInDialog by remember { mutableStateOf(false) }

    val filteredStudents = remember(state.students, searchQuery) {
        val q = searchQuery.trim().lowercase()
        if (q.isEmpty()) state.students
        else state.students.filter {
            it.nameAr.lowercase().contains(q) ||
                it.nameEn.lowercase().contains(q) ||
                it.phone.contains(q)
        }
    }

    LazyColumn(
        modifier = Modifier.fillMaxSize(),
        contentPadding = PaddingValues(16.dp),
        verticalArrangement = Arrangement.spacedBy(14.dp),
    ) {
        item {
            val queue = state.operatingReport?.queueDispatch
            FloatingGlassCard(
                glowColor = if (state.rushModeEnabled) SolarGold else NeonCyan,
                modifier = Modifier.fillMaxWidth(),
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
                        FilterChip(
                            selected = state.rushModeEnabled,
                            onClick = onToggleRushMode,
                            modifier = Modifier.testTag("rush_mode_toggle"),
                            leadingIcon = { Icon(Icons.Default.Bolt, contentDescription = null) },
                            label = { Text(AppStrings.t("rush_mode_toggle", lang)) },
                            colors = FilterChipDefaults.filterChipColors(
                                selectedContainerColor = SolarGold,
                                selectedLabelColor = CosmicBlack,
                            ),
                        )
                        StatusPill(
                            label = "${AppStrings.t("rush_counter_label", lang)}: ${state.attendance.size}",
                            color = EmeraldValid,
                        )
                    }
                    if (!state.rushModeEnabled) {
                        Text(text = AppStrings.t("dynamic_qr_title", lang), style = MaterialTheme.typography.titleMedium, color = TextPrimary)
                        DynamicQrCanvas(token = state.qrToken)
                        Text(text = "${AppStrings.t("rotates_in", lang)} ${state.qrSecondsRemaining}s", style = MaterialTheme.typography.labelLarge, color = NeonCyan)
                    } else if (queue != null) {
                        Text(
                            text = if (lang == AppLanguage.AR) {
                                "متوسط انتظار السلم: ${queue.expectedWaitSeconds} ثانية (${queue.activeLanes} مسار)"
                            } else {
                                "Expected queue wait: ${queue.expectedWaitSeconds}s (${queue.activeLanes} lanes)"
                            },
                            style = MaterialTheme.typography.titleMedium,
                            color = SolarGold,
                        )
                    }
                    Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                        OutlinedButton(
                            onClick = { showDrawerDialog = true },
                            modifier = Modifier.weight(1f).testTag("drawer_reconcile_button"),
                        ) {
                            Icon(Icons.Default.AccountBalance, contentDescription = null, tint = EmeraldValid)
                            Text(AppStrings.t("drawer_reconcile_cta", lang), color = EmeraldValid)
                        }
                        OutlinedButton(
                            onClick = { showWalkInDialog = true },
                            modifier = Modifier.weight(1f).testTag("add_walkin_button"),
                        ) {
                            Icon(Icons.Default.PersonAdd, contentDescription = null, tint = NeonCyan)
                            Text(AppStrings.t("add_walkin_cta", lang), color = NeonCyan)
                        }
                    }
                }
            }
        }

        // Dynamic QR Gate Verifier
        item {
            FloatingGlassCard(glowColor = NebulaPurple, modifier = Modifier.fillMaxWidth()) {
                Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                    Text(text = AppStrings.t("verify_qr_cta", lang), style = MaterialTheme.typography.titleMedium, color = TextPrimary)
                    OutlinedTextField(
                        value = tokenInput,
                        onValueChange = { tokenInput = it },
                        label = { Text(AppStrings.t("verify_qr_hint", lang)) },
                        singleLine = true,
                        modifier = Modifier.fillMaxWidth().testTag("qr_verify_input"),
                    )
                    Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                        NeonButton(
                            text = AppStrings.t("verify_qr_cta", lang),
                            icon = Icons.Default.VerifiedUser,
                            accentColor = NebulaPurple,
                            enabled = tokenInput.isNotBlank(),
                            onClick = {
                                haptics.performHapticFeedback(HapticFeedbackType.LongPress)
                                onVerifyQrToken(tokenInput)
                            },
                            modifier = Modifier.weight(1f).testTag("qr_verify_button"),
                        )
                        OutlinedButton(
                            onClick = {
                                tokenInput = state.qrToken
                                onVerifyQrToken(state.qrToken)
                            },
                            modifier = Modifier.weight(1f).testTag("qr_verify_live_button"),
                        ) {
                            Text(AppStrings.t("verify_qr_use_live", lang), color = NeonCyan)
                        }
                    }
                    state.qrVerificationBanner?.let { banner ->
                        val (color, key) = when (banner.status) {
                            QrVerifyStatus.VALID -> EmeraldValid to "qr_result_valid"
                            QrVerifyStatus.EXPIRED -> AmberDue to "qr_result_expired"
                            QrVerifyStatus.INVALID -> CrimsonBlocked to "qr_result_invalid"
                        }
                        StatusPill(label = AppStrings.t(key, lang), color = color)
                    }
                }
            }
        }

        if (state.lastScanFeedback != null) {
            val fb = state.lastScanFeedback
            val color = when (fb.status) { "valid" -> EmeraldValid; "due" -> AmberDue; else -> CrimsonBlocked }
            val labelKey = when (fb.status) { "valid" -> "scan_valid"; "due" -> "scan_due"; else -> "scan_blocked" }
            item {
                FloatingGlassCard(glowColor = color, modifier = Modifier.fillMaxWidth()) {
                    Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween, verticalAlignment = Alignment.CenterVertically) {
                        Text(text = fb.studentName, style = MaterialTheme.typography.titleMedium, color = TextPrimary)
                        StatusPill(label = AppStrings.t(labelKey, lang), color = color)
                    }
                }
            }
        }

        item {
            Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(10.dp), verticalAlignment = Alignment.CenterVertically) {
                OutlinedTextField(
                    value = searchQuery,
                    onValueChange = { searchQuery = it },
                    label = { Text(AppStrings.t("search_student", lang)) },
                    leadingIcon = { Icon(Icons.Default.Search, contentDescription = null, tint = NeonCyan) },
                    singleLine = true,
                    modifier = Modifier.weight(1f).testTag("desk_search_input"),
                )
                OutlinedButton(
                    onClick = { showReceiptDialog = true },
                    modifier = Modifier.testTag("desk_print_receipt_button"),
                ) {
                    Icon(Icons.Default.Print, contentDescription = AppStrings.t("print_batch_receipt", lang))
                }
            }
        }

        if (filteredStudents.isEmpty()) {
            item { EmptyStateCard(icon = Icons.Default.QrCodeScanner, message = AppStrings.t("empty_students", lang)) }
        } else {
            items(filteredStudents, key = { it.id }) { student ->
                val name = if (lang == AppLanguage.AR) student.nameAr else student.nameEn
                val statusColor = when {
                    student.isBlocked -> CrimsonBlocked
                    student.dueBalancePiasters > 0L -> AmberDue
                    else -> EmeraldValid
                }
                val statusLabel = when {
                    student.isBlocked -> AppStrings.t("scan_blocked", lang)
                    student.dueBalancePiasters > 0L -> "${AppStrings.t("due_balance", lang)}: ${EgyptValidators.formatPiasters(student.dueBalancePiasters, lang.code)}"
                    else -> AppStrings.t("scan_valid", lang)
                }

                FloatingGlassCard(glowColor = statusColor, modifier = Modifier.fillMaxWidth()) {
                    Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                        Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween, verticalAlignment = Alignment.CenterVertically) {
                            Column(modifier = Modifier.weight(1f)) {
                                Text(text = name, style = MaterialTheme.typography.titleMedium, color = TextPrimary)
                                Row(horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                                    CompositionLocalProvider(LocalLayoutDirection provides LayoutDirection.Ltr) {
                                        Text(text = student.phone, style = MaterialTheme.typography.bodySmall, color = TextSecondary)
                                    }
                                    Text(
                                        text = "· ${EgyptValidators.formatPiasters(student.walletBalancePiasters, lang.code)}",
                                        style = MaterialTheme.typography.bodySmall,
                                        color = EmeraldValid,
                                    )
                                }
                            }
                            StatusPill(label = statusLabel, color = statusColor)
                        }

                        FlowRow(horizontalArrangement = Arrangement.spacedBy(8.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                            NeonButton(
                                text = AppStrings.t("tap_to_checkin", lang),
                                icon = Icons.Default.CheckCircle,
                                accentColor = statusColor,
                                onClick = {
                                    haptics.performHapticFeedback(HapticFeedbackType.LongPress)
                                    onCheckInStudent(student)
                                },
                                modifier = Modifier.testTag("checkin_btn_${student.id}"),
                            )
                            if (student.dueBalancePiasters > 0L && !student.isBlocked) {
                                OutlinedButton(
                                    onClick = { haptics.performHapticFeedback(HapticFeedbackType.LongPress); onDiscreetAllow(student) },
                                    modifier = Modifier.testTag("discreet_allow_btn_${student.id}"),
                                ) {
                                    Icon(Icons.Default.NotificationsActive, contentDescription = null, tint = AmberDue, modifier = Modifier.padding(end = 6.dp))
                                    Text(AppStrings.t("discreet_due_allow", lang), color = AmberDue)
                                }
                            }
                            OutlinedButton(
                                onClick = { cashDialogStudent = student },
                                modifier = Modifier.testTag("collect_cash_btn_${student.id}"),
                            ) {
                                Icon(Icons.Default.Payments, contentDescription = null, tint = NeonCyan, modifier = Modifier.padding(end = 6.dp))
                                Text(AppStrings.t("collect_cash", lang), color = TextPrimary)
                            }
                            OutlinedButton(
                                onClick = { onGenerateQrCode(student) },
                                modifier = Modifier.testTag("generate_qr_btn_${student.id}"),
                            ) {
                                Icon(Icons.Default.QrCode2, contentDescription = null, tint = EmeraldValid, modifier = Modifier.padding(end = 6.dp))
                                Text(AppStrings.t("generate_qr", lang), color = TextPrimary)
                            }
                            OutlinedButton(
                                onClick = { onToggleBlockStudent(student) },
                                modifier = Modifier.testTag("block_toggle_btn_${student.id}"),
                            ) {
                                Icon(
                                    imageVector = Icons.Default.Block,
                                    contentDescription = null,
                                    tint = if (student.isBlocked) EmeraldValid else CrimsonBlocked,
                                    modifier = Modifier.padding(end = 4.dp),
                                )
                                Text(
                                    text = AppStrings.t(if (student.isBlocked) "unblock_student" else "block_student", lang),
                                    color = if (student.isBlocked) EmeraldValid else CrimsonBlocked,
                                )
                            }
                        }
                    }
                }
            }
        }
    }

    if (showWalkInDialog) {
        WalkInStudentDialog(
            groups = state.groups,
            lang = lang,
            onDismiss = { showWalkInDialog = false },
            onConfirm = { name, phone, groupId, topUp ->
                onAddWalkInStudent(name, phone, groupId, topUp)
                showWalkInDialog = false
            },
        )
    }

    if (showDrawerDialog) {
        val rec = state.shiftReconciliation
        AlertDialog(
            onDismissRequest = { showDrawerDialog = false },
            containerColor = SpaceSurface,
            title = { Text(AppStrings.t("drawer_reconcile_title", lang), color = TextPrimary) },
            text = {
                Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                    DrawerRow(AppStrings.t("drawer_cash_total", lang), EgyptValidators.formatPiasters(rec.cashCollectedPiasters, lang.code), EmeraldValid)
                    DrawerRow(AppStrings.t("drawer_electronic_total", lang), EgyptValidators.formatPiasters(rec.electronicTransfersPiasters, lang.code), NeonCyan)
                    DrawerRow(AppStrings.t("drawer_void_total", lang), EgyptValidators.formatPiasters(rec.voidedTotalPiasters, lang.code), CrimsonBlocked)
                    DrawerRow(AppStrings.t("drawer_net_total", lang), EgyptValidators.formatPiasters(rec.netDrawerCashPiasters, lang.code), SolarGold)
                }
            },
            confirmButton = {
                TextButton(onClick = { showDrawerDialog = false }) { Text(AppStrings.t("close", lang), color = NeonCyan) }
            },
        )
    }

    cashDialogStudent?.let { target ->
        CashEntryDialog(
            student = target,
            lang = lang,
            onDismiss = { cashDialogStudent = null },
            onConfirm = { kind, amount, note -> onRecordCashEntry(target, kind, amount, note); cashDialogStudent = null },
        )
    }

    if (showReceiptDialog) {
        val receipt = buildThermalReceipt(lang)
        AlertDialog(
            onDismissRequest = { showReceiptDialog = false },
            containerColor = SpaceSurface,
            title = { Text(AppStrings.t("batch_receipt_title", lang), color = TextPrimary) },
            text = {
                CompositionLocalProvider(LocalLayoutDirection provides LayoutDirection.Ltr) {
                    Text(text = receipt, style = MaterialTheme.typography.bodySmall.copy(fontFamily = FontFamily.Monospace), color = TextSecondary)
                }
            },
            confirmButton = {
                Row(horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                    TextButton(onClick = {
                        ShareHelper.shareText(context, AppStrings.t("batch_receipt_title", lang), receipt)
                    }) {
                        Icon(Icons.Default.Share, contentDescription = null, tint = EmeraldValid)
                        Text(AppStrings.t("share_whatsapp", lang), color = EmeraldValid)
                    }
                    TextButton(onClick = { clipboard.setText(AnnotatedString(receipt)); showReceiptDialog = false }) {
                        Text(AppStrings.t("copy_receipt", lang), color = NeonCyan)
                    }
                }
            },
            dismissButton = { TextButton(onClick = { showReceiptDialog = false }) { Text(AppStrings.t("close", lang), color = TextSecondary) } },
        )
    }

    state.generatedQrCode?.let { code ->
        val studentName = state.generatedQrStudentName.orEmpty()
        AlertDialog(
            onDismissRequest = onDismissGeneratedQr,
            containerColor = SpaceSurface,
            title = { Text(AppStrings.t("qr_generated_title", lang), color = TextPrimary) },
            text = {
                Column(modifier = Modifier.fillMaxWidth(), horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(10.dp)) {
                    if (studentName.isNotBlank()) Text(text = studentName, style = MaterialTheme.typography.titleMedium, color = NeonCyan)
                    DynamicQrCanvas(token = code)
                    CompositionLocalProvider(LocalLayoutDirection provides LayoutDirection.Ltr) {
                        Text(text = code, style = MaterialTheme.typography.headlineSmall.copy(fontFamily = FontFamily.Monospace), color = EmeraldValid)
                    }
                    Text(text = AppStrings.t("qr_generated_hint", lang), style = MaterialTheme.typography.bodySmall, color = TextSecondary)
                }
            },
            confirmButton = {
                Row(horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                    TextButton(onClick = {
                        val msg = if (lang == AppLanguage.AR) "بطاقة دخول كشكول لـ $studentName\nالكود: $code" else "Kashkool Student Code for $studentName: $code"
                        ShareHelper.shareText(context, AppStrings.t("qr_generated_title", lang), msg)
                    }) {
                        Text(AppStrings.t("share_whatsapp", lang), color = EmeraldValid)
                    }
                    TextButton(onClick = { clipboard.setText(AnnotatedString(code)); onDismissGeneratedQr() }) {
                        Text(AppStrings.t("copy_receipt", lang), color = NeonCyan)
                    }
                }
            },
            dismissButton = { TextButton(onClick = onDismissGeneratedQr) { Text(AppStrings.t("close", lang), color = TextSecondary) } },
        )
    }
}

@Composable
private fun DrawerRow(label: String, value: String, color: androidx.compose.ui.graphics.Color) {
    Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
        Text(text = label, style = MaterialTheme.typography.bodyMedium, color = TextSecondary)
        Text(text = value, style = MaterialTheme.typography.titleMedium, color = color)
    }
}
