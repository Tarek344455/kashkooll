package com.dig.kashkool.ui.screens

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.FilterChip
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import com.dig.kashkool.core.l10n.AppLanguage
import com.dig.kashkool.core.l10n.AppStrings
import com.dig.kashkool.core.or.StudentOrProfile
import com.dig.kashkool.data.local.GroupEntity
import com.dig.kashkool.data.local.LedgerKind
import com.dig.kashkool.data.local.StudentEntity
import com.dig.kashkool.ui.components.NeonButton
import com.dig.kashkool.ui.theme.EmeraldValid
import com.dig.kashkool.ui.theme.NeonCyan
import com.dig.kashkool.ui.theme.SpaceSurface
import com.dig.kashkool.ui.theme.TextPrimary
import com.dig.kashkool.ui.theme.TextSecondary

@OptIn(ExperimentalLayoutApi::class)
@Composable
fun WalkInStudentDialog(
    groups: List<GroupEntity>,
    lang: AppLanguage,
    optimalGroupId: String? = null,
    onDismiss: () -> Unit,
    onConfirm: (name: String, phone: String, groupId: String, initialTopUpEgp: String) -> Unit,
) {
    var name by remember { mutableStateOf("") }
    var phone by remember { mutableStateOf("") }
    var selectedGroupId by remember(groups, optimalGroupId) {
        mutableStateOf(
            optimalGroupId?.takeIf { id -> groups.any { it.id == id } }
                ?: groups.firstOrNull()?.id.orEmpty()
        )
    }
    var topUpEgp by remember { mutableStateOf("80") }

    AlertDialog(
        onDismissRequest = onDismiss,
        containerColor = SpaceSurface,
        title = { Text(AppStrings.t("walkin_dialog_title", lang), color = TextPrimary) },
        text = {
            Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                OutlinedTextField(
                    value = name,
                    onValueChange = { name = it },
                    label = { Text(AppStrings.t("walkin_name", lang)) },
                    singleLine = true,
                    modifier = Modifier
                        .fillMaxWidth()
                        .testTag("walkin_name_input"),
                )
                OutlinedTextField(
                    value = phone,
                    onValueChange = { phone = it },
                    label = { Text(AppStrings.t("phone_label", lang)) },
                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Phone),
                    singleLine = true,
                    modifier = Modifier
                        .fillMaxWidth()
                        .testTag("walkin_phone_input"),
                )
                if (groups.isNotEmpty()) {
                    FlowRow(horizontalArrangement = Arrangement.spacedBy(6.dp), verticalArrangement = Arrangement.spacedBy(6.dp)) {
                        groups.forEach { grp ->
                            val baseName = if (lang == AppLanguage.AR) grp.nameAr else grp.nameEn
                            val labelText = if (grp.id == optimalGroupId) {
                                "$baseName · ${AppStrings.t("or_best_fit_group", lang)}"
                            } else {
                                baseName
                            }
                            FilterChip(
                                selected = selectedGroupId == grp.id,
                                onClick = { selectedGroupId = grp.id },
                                label = {
                                    Text(
                                        text = labelText,
                                        style = MaterialTheme.typography.labelSmall,
                                    )
                                },
                            )
                        }
                    }
                }
                OutlinedTextField(
                    value = topUpEgp,
                    onValueChange = { topUpEgp = it },
                    label = { Text(AppStrings.t("walkin_topup", lang)) },
                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Decimal),
                    singleLine = true,
                    modifier = Modifier.fillMaxWidth(),
                )
            }
        },
        confirmButton = {
            NeonButton(
                text = AppStrings.t("submit", lang),
                accentColor = EmeraldValid,
                enabled = name.isNotBlank() && selectedGroupId.isNotBlank(),
                onClick = { onConfirm(name, phone, selectedGroupId, topUpEgp) },
                modifier = Modifier.testTag("walkin_submit_button"),
            )
        },
        dismissButton = {
            TextButton(onClick = onDismiss) {
                Text(AppStrings.t("close", lang), color = TextSecondary)
            }
        },
    )
}

@OptIn(ExperimentalLayoutApi::class)
@Composable
fun CashEntryDialog(
    student: StudentEntity,
    lang: AppLanguage,
    orProfile: StudentOrProfile? = null,
    onDismiss: () -> Unit,
    onConfirm: (LedgerKind, String, String) -> Unit,
) {
    var selectedKind by remember(student.id) {
        mutableStateOf(
            if (student.dueBalancePiasters > 0L) LedgerKind.PARTIAL_INSTALLMENT
            else LedgerKind.CASH_TOPUP
        )
    }
    var amountText by remember(student.id, orProfile) {
        val suggested = orProfile?.recommendedInstallmentPiasters?.div(100L)?.takeIf { it > 0L }?.toString()
        mutableStateOf(suggested ?: "100")
    }
    var noteText by remember { mutableStateOf("") }

    AlertDialog(
        onDismissRequest = onDismiss,
        containerColor = SpaceSurface,
        title = { Text(text = if (lang == AppLanguage.AR) student.nameAr else student.nameEn, color = TextPrimary) },
        text = {
            Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                orProfile?.let { profile ->
                    Text(
                        text = if (lang == AppLanguage.AR) profile.actionSummaryAr else profile.actionSummaryEn,
                        style = MaterialTheme.typography.bodySmall,
                        color = NeonCyan,
                    )
                }
                FlowRow(horizontalArrangement = Arrangement.spacedBy(6.dp), verticalArrangement = Arrangement.spacedBy(6.dp)) {
                    listOf(
                        LedgerKind.CASH_TOPUP to "cash_topup",
                        LedgerKind.PARTIAL_INSTALLMENT to "partial_installment",
                        LedgerKind.BOOK_RESERVATION to "book_reservation",
                        LedgerKind.DISCOUNT to "teacher_discount",
                    ).forEach { (kind, key) ->
                        FilterChip(selected = selectedKind == kind, onClick = { selectedKind = kind }, label = { Text(AppStrings.t(key, lang)) })
                    }
                }
                OutlinedTextField(
                    value = amountText,
                    onValueChange = { amountText = it },
                    label = { Text(AppStrings.t("amount_egp", lang)) },
                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Decimal),
                    singleLine = true,
                    modifier = Modifier.fillMaxWidth(),
                )
                OutlinedTextField(
                    value = noteText,
                    onValueChange = { noteText = it },
                    label = { Text(AppStrings.t("note_label", lang)) },
                    singleLine = true,
                    modifier = Modifier.fillMaxWidth(),
                )
                Spacer(modifier = Modifier.height(2.dp))
            }
        },
        confirmButton = { NeonButton(text = AppStrings.t("submit", lang), onClick = { onConfirm(selectedKind, amountText, noteText) }) },
        dismissButton = { TextButton(onClick = onDismiss) { Text(AppStrings.t("close", lang), color = TextSecondary) } },
    )
}
