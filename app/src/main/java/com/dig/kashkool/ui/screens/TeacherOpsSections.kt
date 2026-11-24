package com.dig.kashkool.ui.screens

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.FilterChip
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Switch
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalLayoutDirection
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.LayoutDirection
import androidx.compose.ui.unit.dp
import com.dig.kashkool.core.l10n.AppLanguage
import com.dig.kashkool.core.l10n.AppStrings
import com.dig.kashkool.core.utils.EgyptValidators
import com.dig.kashkool.data.local.AvailabilityStatus
import com.dig.kashkool.data.local.PaymentChannelEntity
import com.dig.kashkool.data.local.Resource
import com.dig.kashkool.data.local.ResourceType
import com.dig.kashkool.ui.components.FloatingGlassCard
import com.dig.kashkool.ui.components.NeonButton
import com.dig.kashkool.ui.components.StatusPill
import com.dig.kashkool.ui.theme.AmberDue
import com.dig.kashkool.ui.theme.CrimsonBlocked
import com.dig.kashkool.ui.theme.ElectricBlue
import com.dig.kashkool.ui.theme.EmeraldValid
import com.dig.kashkool.ui.theme.NebulaPurple
import com.dig.kashkool.ui.theme.NeonCyan
import com.dig.kashkool.ui.theme.SolarGold
import com.dig.kashkool.ui.theme.SpaceSurface
import com.dig.kashkool.ui.theme.TextPrimary
import com.dig.kashkool.ui.theme.TextSecondary
import com.dig.kashkool.ui.viewmodel.CenterPlanTier
import com.dig.kashkool.ui.viewmodel.KashkoolUiState

@Composable
fun ResourceItemCard(
    resource: Resource,
    lang: AppLanguage,
    onCycleStatus: (Resource) -> Unit,
) {
    val (statusKey, statusColor) = when (resource.availabilityStatus) {
        AvailabilityStatus.AVAILABLE -> "res_available" to EmeraldValid
        AvailabilityStatus.IN_USE -> "res_in_use" to NeonCyan
        AvailabilityStatus.RESERVED -> "res_reserved" to AmberDue
        AvailabilityStatus.UNAVAILABLE -> "res_unavailable" to CrimsonBlocked
    }
    val typeKey = when (resource.type) {
        ResourceType.HUMAN -> "resource_human"
        ResourceType.TOOL -> "resource_tool"
        ResourceType.FINANCIAL -> "resource_financial"
    }

    FloatingGlassCard(
        glowColor = statusColor,
        modifier = Modifier
            .fillMaxWidth()
            .testTag("resource_card_${resource.id}"),
    ) {
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Column(modifier = Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(4.dp)) {
                Text(text = resource.name, style = MaterialTheme.typography.titleMedium, color = TextPrimary)
                Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    StatusPill(label = AppStrings.t(typeKey, lang), color = ElectricBlue)
                    if (resource.costPiasters > 0L) {
                        Text(
                            text = EgyptValidators.formatPiasters(resource.costPiasters, lang.code),
                            style = MaterialTheme.typography.labelMedium,
                            color = SolarGold,
                        )
                    }
                }
            }
            OutlinedButton(
                onClick = { onCycleStatus(resource) },
                modifier = Modifier.testTag("resource_status_btn_${resource.id}"),
            ) {
                Text(text = AppStrings.t(statusKey, lang), color = statusColor)
            }
        }
    }
}

@Composable
fun ChannelToggleCard(
    channel: PaymentChannelEntity,
    lang: AppLanguage,
    onToggleActive: (PaymentChannelEntity) -> Unit,
) {
    FloatingGlassCard(
        glowColor = if (channel.isActive) EmeraldValid else TextSecondary,
        modifier = Modifier.fillMaxWidth(),
    ) {
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Column(modifier = Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(2.dp)) {
                Text(
                    text = if (lang == AppLanguage.AR) channel.nameAr else channel.nameEn,
                    style = MaterialTheme.typography.titleSmall,
                    color = TextPrimary,
                )
                CompositionLocalProvider(LocalLayoutDirection provides LayoutDirection.Ltr) {
                    Text(text = channel.accountRef, style = MaterialTheme.typography.bodySmall, color = NeonCyan)
                }
            }
            Switch(
                checked = channel.isActive,
                onCheckedChange = { onToggleActive(channel) },
                modifier = Modifier.testTag("channel_switch_${channel.id}"),
            )
        }
    }
}

@OptIn(ExperimentalLayoutApi::class)
@Composable
fun AddResourceDialog(
    lang: AppLanguage,
    onDismiss: () -> Unit,
    onSave: (String, ResourceType, String) -> Unit,
) {
    var name by remember { mutableStateOf("") }
    var selectedType by remember { mutableStateOf(ResourceType.TOOL) }
    var costEgp by remember { mutableStateOf("0") }

    AlertDialog(
        onDismissRequest = onDismiss,
        containerColor = SpaceSurface,
        title = { Text(AppStrings.t("add_resource", lang), color = TextPrimary) },
        text = {
            Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                OutlinedTextField(
                    value = name,
                    onValueChange = { name = it },
                    label = { Text(AppStrings.t("resource_name", lang)) },
                    singleLine = true,
                    modifier = Modifier.fillMaxWidth().testTag("resource_name_input"),
                )
                FlowRow(horizontalArrangement = Arrangement.spacedBy(6.dp), verticalArrangement = Arrangement.spacedBy(6.dp)) {
                    listOf(
                        ResourceType.TOOL to "resource_tool",
                        ResourceType.HUMAN to "resource_human",
                        ResourceType.FINANCIAL to "resource_financial",
                    ).forEach { (type, key) ->
                        FilterChip(
                            selected = selectedType == type,
                            onClick = { selectedType = type },
                            label = { Text(AppStrings.t(key, lang)) },
                        )
                    }
                }
                OutlinedTextField(
                    value = costEgp,
                    onValueChange = { costEgp = it },
                    label = { Text(AppStrings.t("resource_cost", lang)) },
                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Decimal),
                    singleLine = true,
                    modifier = Modifier.fillMaxWidth(),
                )
            }
        },
        confirmButton = {
            NeonButton(
                text = AppStrings.t("submit", lang),
                enabled = name.isNotBlank(),
                onClick = { onSave(name, selectedType, costEgp) },
            )
        },
        dismissButton = {
            TextButton(onClick = onDismiss) { Text(AppStrings.t("close", lang), color = TextSecondary) }
        },
    )
}

@OptIn(ExperimentalLayoutApi::class)
@Composable
fun AddChannelDialog(
    lang: AppLanguage,
    onDismiss: () -> Unit,
    onSave: (String, String, String, String) -> Unit,
) {
    var name by remember { mutableStateOf("") }
    var channelType by remember { mutableStateOf("insta_pay") }
    var accountRef by remember { mutableStateOf("") }
    var feeEgp by remember { mutableStateOf("0") }

    AlertDialog(
        onDismissRequest = onDismiss,
        containerColor = SpaceSurface,
        title = { Text(AppStrings.t("add_channel", lang), color = TextPrimary) },
        text = {
            Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                OutlinedTextField(
                    value = name,
                    onValueChange = { name = it },
                    label = { Text(AppStrings.t("channel_name", lang)) },
                    singleLine = true,
                    modifier = Modifier.fillMaxWidth(),
                )
                FlowRow(horizontalArrangement = Arrangement.spacedBy(6.dp), verticalArrangement = Arrangement.spacedBy(6.dp)) {
                    listOf(
                        "insta_pay" to "InstaPay",
                        "vodafone_cash" to "Vodafone Cash",
                        "fawry" to "Fawry",
                        "cash_desk" to "Cash",
                    ).forEach { (typeKey, label) ->
                        FilterChip(selected = channelType == typeKey, onClick = { channelType = typeKey }, label = { Text(label) })
                    }
                }
                OutlinedTextField(
                    value = accountRef,
                    onValueChange = { accountRef = it },
                    label = { Text(AppStrings.t("channel_account_ref", lang)) },
                    singleLine = true,
                    modifier = Modifier.fillMaxWidth(),
                )
                OutlinedTextField(
                    value = feeEgp,
                    onValueChange = { feeEgp = it },
                    label = { Text(AppStrings.t("channel_fee_egp", lang)) },
                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Decimal),
                    singleLine = true,
                    modifier = Modifier.fillMaxWidth(),
                )
            }
        },
        confirmButton = {
            NeonButton(
                text = AppStrings.t("submit", lang),
                enabled = name.isNotBlank() && accountRef.isNotBlank(),
                onClick = { onSave(name, channelType, accountRef, feeEgp) },
            )
        },
        dismissButton = {
            TextButton(onClick = onDismiss) { Text(AppStrings.t("close", lang), color = TextSecondary) }
        },
    )
}

@OptIn(ExperimentalLayoutApi::class)
@Composable
fun CenterPlanUpgradeDialog(
    state: KashkoolUiState,
    lang: AppLanguage,
    onDismiss: () -> Unit,
    onSubmit: (CenterPlanTier, PaymentChannelEntity, String) -> Unit,
) {
    var selectedPlan by remember {
        mutableStateOf(state.centerPlans.firstOrNull { it.id == state.activeCenterPlanId } ?: state.centerPlans.first())
    }
    var selectedChannel by remember { mutableStateOf(state.channels.first()) }
    var refCode by remember { mutableStateOf("") }

    AlertDialog(
        onDismissRequest = onDismiss,
        containerColor = SpaceSurface,
        title = { Text(AppStrings.t("plan_submit_title", lang), color = TextPrimary) },
        text = {
            Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                FlowRow(horizontalArrangement = Arrangement.spacedBy(6.dp), verticalArrangement = Arrangement.spacedBy(6.dp)) {
                    state.centerPlans.forEach { plan ->
                        val title = if (lang == AppLanguage.AR) plan.nameAr else plan.nameEn
                        val price = EgyptValidators.formatPiasters(plan.monthlyPiasters, lang.code)
                        FilterChip(selected = selectedPlan.id == plan.id, onClick = { selectedPlan = plan }, label = { Text("$title · $price") })
                    }
                }
                FlowRow(horizontalArrangement = Arrangement.spacedBy(6.dp), verticalArrangement = Arrangement.spacedBy(6.dp)) {
                    state.channels.take(3).forEach { ch ->
                        FilterChip(selected = selectedChannel.id == ch.id, onClick = { selectedChannel = ch }, label = { Text(if (lang == AppLanguage.AR) ch.nameAr else ch.nameEn) })
                    }
                }
                OutlinedTextField(
                    value = refCode,
                    onValueChange = { refCode = it },
                    label = { Text(AppStrings.t("sender_ref", lang)) },
                    singleLine = true,
                    modifier = Modifier.fillMaxWidth(),
                )
            }
        },
        confirmButton = {
            NeonButton(
                text = AppStrings.t("submit", lang),
                accentColor = NebulaPurple,
                enabled = refCode.isNotBlank(),
                onClick = { onSubmit(selectedPlan, selectedChannel, refCode) },
            )
        },
        dismissButton = {
            TextButton(onClick = onDismiss) { Text(AppStrings.t("close", lang), color = TextSecondary) }
        },
    )
}

@Composable
fun AddGroupDialog(
    lang: AppLanguage,
    onDismiss: () -> Unit,
    onSave: (String, String, String, String) -> Unit,
) {
    var name by remember { mutableStateOf("") }
    var schedule by remember { mutableStateOf("") }
    var capacity by remember { mutableStateOf("45") }
    var price by remember { mutableStateOf("80") }

    AlertDialog(
        onDismissRequest = onDismiss,
        containerColor = SpaceSurface,
        title = { Text(AppStrings.t("add_group", lang), color = TextPrimary) },
        text = {
            Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                OutlinedTextField(value = name, onValueChange = { name = it }, label = { Text(AppStrings.t("group_name", lang)) }, modifier = Modifier.fillMaxWidth())
                OutlinedTextField(value = schedule, onValueChange = { schedule = it }, label = { Text(AppStrings.t("group_schedule", lang)) }, modifier = Modifier.fillMaxWidth())
                OutlinedTextField(value = capacity, onValueChange = { capacity = it }, label = { Text(AppStrings.t("group_capacity", lang)) }, keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number), modifier = Modifier.fillMaxWidth())
                OutlinedTextField(value = price, onValueChange = { price = it }, label = { Text(AppStrings.t("group_price", lang)) }, keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Decimal), modifier = Modifier.fillMaxWidth())
            }
        },
        confirmButton = {
            NeonButton(text = AppStrings.t("submit", lang), enabled = name.isNotBlank(), onClick = { onSave(name, schedule, capacity, price) })
        },
        dismissButton = {
            TextButton(onClick = onDismiss) { Text(AppStrings.t("close", lang), color = TextSecondary) }
        },
    )
}
