package com.dig.kashkool.ui.screens

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Balance
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.Groups
import androidx.compose.material.icons.filled.Insights
import androidx.compose.material.icons.filled.Payments
import androidx.compose.material.icons.filled.WorkspacePremium
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.FilterChip
import androidx.compose.material3.FilterChipDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Slider
import androidx.compose.material3.SliderDefaults
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.unit.dp
import com.dig.kashkool.core.l10n.AppLanguage
import com.dig.kashkool.core.l10n.AppStrings
import com.dig.kashkool.core.utils.EgyptValidators
import com.dig.kashkool.data.local.GroupEntity
import com.dig.kashkool.data.local.PaymentChannelEntity
import com.dig.kashkool.data.local.PaymentSubmissionEntity
import com.dig.kashkool.data.local.PerformanceEvaluationEntity
import com.dig.kashkool.data.local.Resource
import com.dig.kashkool.data.local.ResourceType
import com.dig.kashkool.data.local.SubmissionStatus
import com.dig.kashkool.ui.components.AttendanceTrendAreaChart
import com.dig.kashkool.ui.components.EmptyStateCard
import com.dig.kashkool.ui.components.EvaluationCardMode
import com.dig.kashkool.ui.components.FloatingGlassCard
import com.dig.kashkool.ui.components.NeonButton
import com.dig.kashkool.ui.components.PerformanceEvaluationCard
import com.dig.kashkool.ui.components.StatusPill
import com.dig.kashkool.ui.components.TeacherLessonPlanCard
import com.dig.kashkool.ui.theme.AmberDue
import com.dig.kashkool.ui.theme.CosmicBlack
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
import kotlin.math.roundToInt

@Composable
fun TeacherOpsScreen(
    state: KashkoolUiState,
    onCreateGroup: (String, String, String, String) -> Unit,
    onExecuteSettlement: (Long, Int) -> Unit,
    onApproveSubmission: (PaymentSubmissionEntity) -> Unit,
    onRejectSubmission: (PaymentSubmissionEntity, String) -> Unit,
    onUpgradeCenterPlan: (CenterPlanTier, PaymentChannelEntity, String) -> Unit = { _, _, _ -> },
    onExecuteOrRebalance: () -> Unit = {},
    onUpdateSettlementControls: (Int, Int) -> Unit = { _, _ -> },
    onAddResource: (String, ResourceType, String) -> Unit = { _, _, _ -> },
    onCycleResourceStatus: (Resource) -> Unit = {},
    onAddChannel: (String, String, String, String) -> Unit = { _, _, _, _ -> },
    onToggleChannelActive: (PaymentChannelEntity) -> Unit = {},
    onEvaluateTeacher: () -> Unit = {},
    onEvaluateStudent: (String?) -> Unit = {},
    buildEvaluationShareText: (PerformanceEvaluationEntity) -> String = { "" },
    onGenerateLessonPlan: (GroupEntity) -> Unit = {},
    onOpenAttendanceDashboard: () -> Unit = {},
) {
    val lang = state.language
    var selectedSection by rememberSaveable { mutableIntStateOf(0) }
    var showAddGroup by remember { mutableStateOf(false) }
    var showAddResource by remember { mutableStateOf(false) }
    var showAddChannel by remember { mutableStateOf(false) }
    var showSettlementConfirm by remember { mutableStateOf(false) }
    var showPlanDialog by remember { mutableStateOf(false) }
    var rejectTarget by remember { mutableStateOf<PaymentSubmissionEntity?>(null) }

    val totalCapacity = state.groups.sumOf { it.capacity }.coerceAtLeast(1)
    val totalEnrolled = state.groups.sumOf { it.enrolled }
    val alloc = state.operatingReport?.groupAllocation
    val finance = state.operatingReport?.financialCertainty
    val resConflict = state.operatingReport?.resourceConflict
    val attendedCount = finance?.attendedCount ?: maxOf(state.attendance.size, 18)
    val netPayoutPiasters = finance?.netPayoutPiasters ?: 0L
    val pendingDuesTotal = state.students.sumOf { it.dueBalancePiasters }
    val pendingDuesCount = state.students.count { it.dueBalancePiasters > 0L }
    val avgMastery = state.students.takeIf { it.isNotEmpty() }?.map { it.masteryPercent }?.average()?.toInt() ?: 85
    val activePlan = state.centerPlans.firstOrNull { it.id == state.activeCenterPlanId } ?: state.centerPlans.first()
    val pendingSubmissions = state.submissions.filter { it.status == SubmissionStatus.PENDING.key }
    val wagesEgp = (state.assistantWagesPiasters / 100L).toInt()

    LazyColumn(
        modifier = Modifier.fillMaxSize(),
        contentPadding = PaddingValues(horizontal = 20.dp, vertical = 18.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp),
    ) {
        item {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(8.dp),
            ) {
                listOf(
                    0 to "teacher_tab_overview",
                    1 to "teacher_tab_finances",
                    2 to "teacher_tab_receipts",
                ).forEach { (idx, key) ->
                    FilterChip(
                        selected = selectedSection == idx,
                        onClick = { selectedSection = idx },
                        modifier = Modifier
                            .weight(1f)
                            .testTag("teacher_section_$idx"),
                        label = {
                            Text(
                                text = AppStrings.t(key, lang),
                                maxLines = 1,
                                style = MaterialTheme.typography.labelMedium,
                            )
                        },
                        colors = FilterChipDefaults.filterChipColors(
                            selectedContainerColor = NeonCyan,
                            selectedLabelColor = CosmicBlack,
                        ),
                    )
                }
            }
        }

        if (selectedSection == 0) {
            item {
                FloatingGlassCard(glowColor = EmeraldValid, modifier = Modifier.fillMaxWidth()) {
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically,
                    ) {
                        Column(modifier = Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(4.dp)) {
                            Text(
                                text = AppStrings.t("teacher_impact_title", lang),
                                style = MaterialTheme.typography.titleMedium,
                                color = EmeraldValid,
                            )
                            Text(
                                text = if (lang == AppLanguage.AR) "$attendedCount طالب حضروا اليوم · متوسط إتقان المجموعة $avgMastery%"
                                else "$attendedCount attended today · $avgMastery% group mastery",
                                style = MaterialTheme.typography.bodySmall,
                                color = TextPrimary,
                            )
                        }
                        StatusPill(
                            label = "$pendingDuesCount (${EgyptValidators.formatPiasters(pendingDuesTotal, lang.code)})",
                            color = if (pendingDuesTotal > 0L) AmberDue else EmeraldValid,
                        )
                    }
                }
            }

            state.attendanceDashboard?.let { dash ->
                item {
                    FloatingGlassCard(modifier = Modifier.fillMaxWidth()) {
                        Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
                            Row(
                                modifier = Modifier.fillMaxWidth(),
                                horizontalArrangement = Arrangement.SpaceBetween,
                                verticalAlignment = Alignment.CenterVertically,
                            ) {
                                Text(
                                    text = AppStrings.t("att_dash_title", lang),
                                    style = MaterialTheme.typography.titleMedium,
                                    color = NeonCyan,
                                    modifier = Modifier.weight(1f),
                                )
                                StatusPill(
                                    label = "${dash.validRatePercent}% ${AppStrings.t("att_legend_valid", lang)}",
                                    color = EmeraldValid,
                                )
                            }
                            if (dash.dailyPoints.isNotEmpty()) {
                                AttendanceTrendAreaChart(
                                    points = dash.dailyPoints.takeLast(7),
                                    selectedIndex = null,
                                    onSelectIndex = { onOpenAttendanceDashboard() },
                                )
                            }
                            NeonButton(
                                text = AppStrings.t("att_open_full_dash", lang),
                                icon = Icons.Default.Insights,
                                accentColor = NeonCyan,
                                onClick = onOpenAttendanceDashboard,
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .testTag("teacher_open_attendance_dash_btn"),
                            )
                        }
                    }
                }
            }

            item {
                PerformanceEvaluationCard(
                    evaluationState = state.evaluationState,
                    savedEvaluations = state.evaluations,
                    lang = lang,
                    mode = EvaluationCardMode.TEACHER_CONSOLE,
                    students = state.students,
                    onEvaluateTeacher = onEvaluateTeacher,
                    onEvaluateStudent = onEvaluateStudent,
                    buildShareText = buildEvaluationShareText,
                )
            }

            item {
                TeacherLessonPlanCard(
                    groups = state.groups,
                    planState = state.teacherPlanState,
                    lang = lang,
                    onGeneratePlan = onGenerateLessonPlan,
                )
            }
        } else if (selectedSection == 1) {
            if (alloc != null && alloc.recommendedSeatShift > 0 && alloc.bottleneckGroupAr != null && alloc.slackGroupAr != null) {
                item {
                    FloatingGlassCard(glowColor = SolarGold, modifier = Modifier.fillMaxWidth()) {
                        Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                            Text(
                                text = if (lang == AppLanguage.AR) {
                                    "ضغط مرتفع (${alloc.bottleneckFillPercent}%) في «${alloc.bottleneckGroupAr}» — انقل ${alloc.recommendedSeatShift} طلاب إلى «${alloc.slackGroupAr}»"
                                } else {
                                    "Overload (${alloc.bottleneckFillPercent}%) in ${alloc.bottleneckGroupEn} — shift ${alloc.recommendedSeatShift} seats to ${alloc.slackGroupEn}"
                                },
                                style = MaterialTheme.typography.bodyMedium,
                                color = SolarGold,
                            )
                            NeonButton(
                                text = AppStrings.t("or_rebalance_cta", lang),
                                icon = Icons.Default.Balance,
                                accentColor = SolarGold,
                                onClick = onExecuteOrRebalance,
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .testTag("or_rebalance_button"),
                            )
                        }
                    }
                }
            }

            item {
                FloatingGlassCard(glowColor = SolarGold, modifier = Modifier.fillMaxWidth()) {
                    Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                        Text(text = AppStrings.t("net_payout", lang), style = MaterialTheme.typography.titleMedium, color = SolarGold)
                        Text(text = EgyptValidators.formatPiasters(netPayoutPiasters, lang.code), style = MaterialTheme.typography.displaySmall, color = TextPrimary)
                        Text(text = AppStrings.t("settlement_formula", lang), style = MaterialTheme.typography.bodySmall, color = TextSecondary)

                        Text(
                            text = "${AppStrings.t("split_percent_label", lang)}: ${state.settlementSplitPercent}%",
                            style = MaterialTheme.typography.labelMedium,
                            color = NeonCyan,
                        )
                        Slider(
                            value = state.settlementSplitPercent.toFloat(),
                            onValueChange = { onUpdateSettlementControls(it.roundToInt(), wagesEgp) },
                            valueRange = 5f..45f,
                            colors = SliderDefaults.colors(thumbColor = NeonCyan, activeTrackColor = NeonCyan),
                            modifier = Modifier.testTag("settlement_split_slider"),
                        )

                        Text(
                            text = "${AppStrings.t("assistant_wages_label", lang)}: ${EgyptValidators.formatPiasters(state.assistantWagesPiasters, lang.code)}",
                            style = MaterialTheme.typography.labelMedium,
                            color = SolarGold,
                        )
                        Slider(
                            value = wagesEgp.toFloat(),
                            onValueChange = { onUpdateSettlementControls(state.settlementSplitPercent, (it / 10f).roundToInt() * 10) },
                            valueRange = 0f..500f,
                            colors = SliderDefaults.colors(thumbColor = SolarGold, activeTrackColor = SolarGold),
                            modifier = Modifier.testTag("settlement_wages_slider"),
                        )

                        Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                            Text(text = "${AppStrings.t("attendance", lang)}: $attendedCount / $totalEnrolled", style = MaterialTheme.typography.labelMedium, color = NeonCyan)
                            Text(
                                text = "${(totalEnrolled * 100 / totalCapacity)}%",
                                style = MaterialTheme.typography.labelMedium,
                                color = EmeraldValid,
                            )
                        }
                        if (finance != null) {
                            Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                                Text(
                                    text = "${AppStrings.t("or_collection_eff", lang)}: ${finance.collectionEfficiencyPercent}%",
                                    style = MaterialTheme.typography.labelMedium,
                                    color = if (finance.collectionEfficiencyPercent >= 75) EmeraldValid else AmberDue,
                                )
                                Text(
                                    text = "${AppStrings.t("or_projected_weekly", lang)}: ${EgyptValidators.formatPiasters(finance.projectedWeeklyGrossPiasters, lang.code)}",
                                    style = MaterialTheme.typography.labelMedium,
                                    color = SolarGold,
                                )
                            }
                            if (finance.anomalyDetected) {
                                StatusPill(
                                    label = AppStrings.t("or_void_anomaly", lang),
                                    color = CrimsonBlocked,
                                )
                            }
                        }
                        NeonButton(
                            text = AppStrings.t("run_settlement", lang),
                            icon = Icons.Default.Payments,
                            accentColor = SolarGold,
                            onClick = { showSettlementConfirm = true },
                            modifier = Modifier
                                .fillMaxWidth()
                                .testTag("run_settlement_button"),
                        )
                    }
                }
            }

            item {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    Text(text = AppStrings.t("groups_title", lang), style = MaterialTheme.typography.titleLarge, color = TextPrimary)
                    IconButton(onClick = { showAddGroup = true }, modifier = Modifier.testTag("add_group_button")) {
                        Icon(Icons.Default.Add, contentDescription = AppStrings.t("add_group", lang), tint = NeonCyan)
                    }
                }
            }
            if (state.groups.isEmpty()) {
                item {
                    EmptyStateCard(
                        icon = Icons.Default.Groups,
                        message = AppStrings.t("empty_groups", lang),
                        actionLabel = AppStrings.t("add_group", lang),
                        onAction = { showAddGroup = true },
                    )
                }
            } else {
                items(state.groups, key = { it.id }) { grp ->
                    val fill = (grp.enrolled.toFloat() / grp.capacity.coerceAtLeast(1)).coerceIn(0f, 1f)
                    FloatingGlassCard(glowColor = ElectricBlue, modifier = Modifier.fillMaxWidth()) {
                        Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                            Row(
                                modifier = Modifier.fillMaxWidth(),
                                horizontalArrangement = Arrangement.SpaceBetween,
                                verticalAlignment = Alignment.CenterVertically,
                            ) {
                                Text(
                                    text = if (lang == AppLanguage.AR) grp.nameAr else grp.nameEn,
                                    style = MaterialTheme.typography.titleMedium,
                                    color = TextPrimary,
                                    modifier = Modifier.weight(1f),
                                )
                                StatusPill(label = EgyptValidators.formatPiasters(grp.pricePerSessionPiasters, lang.code), color = NeonCyan)
                            }
                            Text(text = if (lang == AppLanguage.AR) grp.scheduleAr else grp.scheduleEn, style = MaterialTheme.typography.bodySmall, color = TextSecondary)
                            LinearProgressIndicator(
                                progress = { fill },
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .height(6.dp)
                                    .clip(MaterialTheme.shapes.small),
                                color = if (fill > 0.9f) SolarGold else NeonCyan,
                                trackColor = Color.White.copy(alpha = 0.08f),
                            )
                            Text(text = "${AppStrings.t("enrolled", lang)}: ${grp.enrolled} / ${grp.capacity}", style = MaterialTheme.typography.labelMedium, color = TextSecondary)
                        }
                    }
                }
            }

            item {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    Column(modifier = Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(4.dp)) {
                        Text(text = AppStrings.t("resources_title", lang), style = MaterialTheme.typography.titleLarge, color = TextPrimary)
                        if (resConflict != null) {
                            StatusPill(
                                label = AppStrings.t(if (resConflict.hasHallOrScheduleConflict) "hall_conflict_alert" else "hall_clear_badge", lang),
                                color = if (resConflict.hasHallOrScheduleConflict) AmberDue else EmeraldValid,
                            )
                        }
                    }
                    IconButton(onClick = { showAddResource = true }, modifier = Modifier.testTag("add_resource_button")) {
                        Icon(Icons.Default.Add, contentDescription = AppStrings.t("add_resource", lang), tint = NeonCyan)
                    }
                }
            }
            items(state.resources, key = { it.id }) { resource ->
                ResourceItemCard(resource = resource, lang = lang, onCycleStatus = onCycleResourceStatus)
            }
        } else {
            item {
                Text(text = AppStrings.t("review_queue", lang), style = MaterialTheme.typography.titleLarge, color = TextPrimary)
            }
            if (pendingSubmissions.isEmpty()) {
                item { EmptyStateCard(icon = Icons.Default.Check, message = AppStrings.t("no_pending_receipts", lang)) }
            } else {
                items(pendingSubmissions, key = { it.id }) { sub ->
                    FloatingGlassCard(modifier = Modifier.fillMaxWidth()) {
                        Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                            Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                                Text(
                                    text = "${sub.channelName} · ${sub.senderReference}",
                                    style = MaterialTheme.typography.titleMedium,
                                    color = TextPrimary,
                                    modifier = Modifier.weight(1f),
                                )
                                Text(
                                    text = EgyptValidators.formatPiasters(sub.amountPiasters, lang.code),
                                    style = MaterialTheme.typography.titleMedium,
                                    color = EmeraldValid,
                                )
                            }
                            Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                                NeonButton(
                                    text = AppStrings.t("approve", lang),
                                    icon = Icons.Default.Check,
                                    accentColor = EmeraldValid,
                                    onClick = { onApproveSubmission(sub) },
                                    modifier = Modifier
                                        .weight(1f)
                                        .testTag("approve_sub_${sub.id}"),
                                )
                                OutlinedButton(
                                    onClick = { rejectTarget = sub },
                                    modifier = Modifier
                                        .weight(1f)
                                        .testTag("reject_sub_${sub.id}"),
                                ) {
                                    Icon(Icons.Default.Close, contentDescription = null, tint = CrimsonBlocked)
                                    Text(AppStrings.t("reject", lang), color = CrimsonBlocked)
                                }
                            }
                        }
                    }
                }
            }

            item {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    Text(text = AppStrings.t("channels_manage_title", lang), style = MaterialTheme.typography.titleLarge, color = TextPrimary)
                    IconButton(onClick = { showAddChannel = true }, modifier = Modifier.testTag("add_channel_button")) {
                        Icon(Icons.Default.Add, contentDescription = AppStrings.t("add_channel", lang), tint = EmeraldValid)
                    }
                }
            }
            items(state.allChannels, key = { it.id }) { ch ->
                ChannelToggleCard(channel = ch, lang = lang, onToggleActive = onToggleChannelActive)
            }

            item {
                val planFill = (totalEnrolled.toFloat() / activePlan.maxStudents.coerceAtLeast(1)).coerceIn(0f, 1f)
                FloatingGlassCard(glowColor = NebulaPurple, modifier = Modifier.fillMaxWidth()) {
                    Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.SpaceBetween,
                            verticalAlignment = Alignment.CenterVertically,
                        ) {
                            Text(
                                text = AppStrings.t("center_plan_title", lang),
                                style = MaterialTheme.typography.titleMedium,
                                color = TextPrimary,
                                modifier = Modifier.weight(1f),
                            )
                            StatusPill(
                                label = if (lang == AppLanguage.AR) activePlan.nameAr else activePlan.nameEn,
                                color = NebulaPurple,
                            )
                        }
                        Text(
                            text = if (lang == AppLanguage.AR) activePlan.highlightAr else activePlan.highlightEn,
                            style = MaterialTheme.typography.bodySmall,
                            color = TextSecondary,
                        )
                        LinearProgressIndicator(
                            progress = { planFill },
                            modifier = Modifier
                                .fillMaxWidth()
                                .height(6.dp)
                                .clip(MaterialTheme.shapes.small),
                            color = NebulaPurple,
                            trackColor = Color.White.copy(alpha = 0.08f),
                        )
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.SpaceBetween,
                            verticalAlignment = Alignment.CenterVertically,
                        ) {
                            Text(text = "$totalEnrolled / ${activePlan.maxStudents}", style = MaterialTheme.typography.labelMedium, color = NeonCyan)
                            OutlinedButton(onClick = { showPlanDialog = true }, modifier = Modifier.testTag("manage_center_plan_button")) {
                                Icon(Icons.Default.WorkspacePremium, contentDescription = null, tint = SolarGold)
                                Text(AppStrings.t("upgrade_plan_cta", lang), color = SolarGold)
                            }
                        }
                    }
                }
            }
        }
    }

    if (showPlanDialog && state.channels.isNotEmpty()) {
        CenterPlanUpgradeDialog(state = state, lang = lang, onDismiss = { showPlanDialog = false }) { plan, ch, ref ->
            onUpgradeCenterPlan(plan, ch, ref); showPlanDialog = false
        }
    }
    if (showAddResource) {
        AddResourceDialog(lang = lang, onDismiss = { showAddResource = false }) { name, type, cost ->
            onAddResource(name, type, cost); showAddResource = false
        }
    }
    if (showAddChannel) {
        AddChannelDialog(lang = lang, onDismiss = { showAddChannel = false }) { name, type, ref, fee ->
            onAddChannel(name, type, ref, fee); showAddChannel = false
        }
    }
    if (showSettlementConfirm) {
        AlertDialog(
            onDismissRequest = { showSettlementConfirm = false },
            containerColor = SpaceSurface,
            title = { Text(AppStrings.t("settlement_confirm_title", lang), color = TextPrimary) },
            text = { Text(AppStrings.t("settlement_confirm_body", lang), color = TextSecondary) },
            confirmButton = {
                NeonButton(text = AppStrings.t("submit", lang), accentColor = SolarGold, onClick = { onExecuteSettlement(netPayoutPiasters, attendedCount); showSettlementConfirm = false })
            },
            dismissButton = { TextButton(onClick = { showSettlementConfirm = false }) { Text(AppStrings.t("close", lang), color = TextSecondary) } },
        )
    }
    if (showAddGroup) {
        AddGroupDialog(lang = lang, onDismiss = { showAddGroup = false }) { name, schedule, cap, price ->
            onCreateGroup(name, schedule, cap, price); showAddGroup = false
        }
    }
    rejectTarget?.let { target ->
        var reason by remember { mutableStateOf("") }
        AlertDialog(
            onDismissRequest = { rejectTarget = null },
            containerColor = SpaceSurface,
            title = { Text(AppStrings.t("reject", lang), color = TextPrimary) },
            text = { OutlinedTextField(value = reason, onValueChange = { reason = it }, label = { Text(AppStrings.t("reject_reason", lang)) }, modifier = Modifier.fillMaxWidth()) },
            confirmButton = {
                NeonButton(text = AppStrings.t("reject", lang), accentColor = CrimsonBlocked, enabled = reason.isNotBlank(), onClick = { onRejectSubmission(target, reason); rejectTarget = null })
            },
            dismissButton = { TextButton(onClick = { rejectTarget = null }) { Text(AppStrings.t("close", lang), color = TextSecondary) } },
        )
    }
}
