package com.dig.kashkool.ui.components

import android.content.ClipData
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.size
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.MenuBook
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.ContentCopy
import androidx.compose.material.icons.filled.Share
import androidx.compose.material.icons.filled.Style
import androidx.compose.material.icons.filled.WarningAmber
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.FilterChip
import androidx.compose.material3.FilterChipDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.ClipEntry
import androidx.compose.ui.platform.LocalClipboard
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.dig.kashkool.core.firebase.TeacherLessonPlan
import com.dig.kashkool.core.l10n.AppLanguage
import com.dig.kashkool.core.l10n.AppStrings
import com.dig.kashkool.core.utils.ShareHelper
import com.dig.kashkool.data.local.GroupEntity
import com.dig.kashkool.ui.theme.AmberDue
import com.dig.kashkool.ui.theme.CosmicBlack
import com.dig.kashkool.ui.theme.ElectricBlue
import com.dig.kashkool.ui.theme.EmeraldValid
import com.dig.kashkool.ui.theme.NebulaPurple
import com.dig.kashkool.ui.theme.NeonCyan
import com.dig.kashkool.ui.theme.SolarGold
import com.dig.kashkool.ui.theme.SpaceSurface
import com.dig.kashkool.ui.theme.TextPrimary
import com.dig.kashkool.ui.theme.TextSecondary
import com.dig.kashkool.ui.viewmodel.RevisionDeckUiState
import com.dig.kashkool.ui.viewmodel.SecretaryNoticeUiState
import com.dig.kashkool.ui.viewmodel.TeacherPlanUiState
import kotlinx.coroutines.launch

@Composable
fun LessonRevisionDeckCard(
    deckState: RevisionDeckUiState,
    lang: AppLanguage,
    onGenerateDeck: () -> Unit,
    modifier: Modifier = Modifier,
) {
    FloatingGlassCard(glowColor = ElectricBlue, modifier = modifier.fillMaxWidth()) {
        Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
            when (deckState) {
                RevisionDeckUiState.Idle -> {
                    NeonButton(
                        text = AppStrings.t("revision_deck_cta", lang),
                        icon = Icons.Default.Style,
                        accentColor = ElectricBlue,
                        onClick = onGenerateDeck,
                        modifier = Modifier
                            .fillMaxWidth()
                            .testTag("generate_revision_deck_button"),
                    )
                }
                RevisionDeckUiState.Loading -> {
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.spacedBy(10.dp),
                        verticalAlignment = Alignment.CenterVertically,
                    ) {
                        CircularProgressIndicator(modifier = Modifier.size(20.dp), color = ElectricBlue, strokeWidth = 2.dp)
                        Text(text = AppStrings.t("revision_deck_loading", lang), style = MaterialTheme.typography.bodySmall, color = ElectricBlue)
                    }
                }
                is RevisionDeckUiState.Error -> {
                    Text(
                        text = "${AppStrings.t("revision_deck_error", lang)} (${deckState.message})",
                        style = MaterialTheme.typography.bodySmall,
                        color = AmberDue,
                    )
                    OutlinedButton(onClick = onGenerateDeck, modifier = Modifier.fillMaxWidth()) {
                        Text(AppStrings.t("revision_deck_cta", lang), color = ElectricBlue)
                    }
                }
                is RevisionDeckUiState.Success -> {
                    val deck = deckState.deck
                    Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                        Icon(Icons.Default.Style, contentDescription = null, tint = ElectricBlue)
                        Text(
                            text = deck.lessonTitle.ifBlank { AppStrings.t("revision_deck_cta", lang) },
                            style = MaterialTheme.typography.titleMedium.copy(fontWeight = FontWeight.Bold),
                            color = TextPrimary,
                        )
                    }
                    if (deck.memoryHook.isNotBlank()) {
                        FloatingGlassCard(glowColor = SolarGold, modifier = Modifier.fillMaxWidth()) {
                            Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
                                Text(text = AppStrings.t("revision_deck_hook", lang), style = MaterialTheme.typography.labelMedium, color = SolarGold)
                                Text(text = deck.memoryHook, style = MaterialTheme.typography.bodySmall, color = TextPrimary)
                            }
                        }
                    }
                    Text(text = AppStrings.t("revision_deck_tap_flip", lang), style = MaterialTheme.typography.labelSmall, color = TextSecondary)
                    deck.flashcards.forEachIndexed { idx, card ->
                        var revealed by remember(deck.lessonTitle, idx) { mutableStateOf(false) }
                        FloatingGlassCard(
                            glowColor = if (revealed) EmeraldValid else NeonCyan,
                            onClick = { revealed = !revealed },
                            modifier = Modifier
                                .fillMaxWidth()
                                .testTag("flashcard_item_$idx"),
                        ) {
                            Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
                                Text(text = card.front, style = MaterialTheme.typography.titleSmall, color = NeonCyan)
                                if (revealed) {
                                    Text(text = card.back, style = MaterialTheme.typography.bodySmall, color = TextPrimary)
                                }
                            }
                        }
                    }
                    if (deck.commonTraps.isNotEmpty()) {
                        Text(text = AppStrings.t("revision_deck_traps", lang), style = MaterialTheme.typography.labelMedium, color = AmberDue)
                        deck.commonTraps.forEach { trap ->
                            Row(horizontalArrangement = Arrangement.spacedBy(6.dp), verticalAlignment = Alignment.Top) {
                                Icon(Icons.Default.WarningAmber, contentDescription = null, tint = AmberDue, modifier = Modifier.size(16.dp))
                                Text(text = trap, style = MaterialTheme.typography.bodySmall, color = TextSecondary)
                            }
                        }
                    }
                }
            }
        }
    }
}

@OptIn(ExperimentalLayoutApi::class)
@Composable
fun TeacherLessonPlanCard(
    groups: List<GroupEntity>,
    planState: TeacherPlanUiState,
    lang: AppLanguage,
    onGeneratePlan: (GroupEntity) -> Unit,
    modifier: Modifier = Modifier,
) {
    if (groups.isEmpty()) return
    val context = LocalContext.current
    var selectedGroupId by remember(groups.firstOrNull()?.id) { mutableStateOf(groups.first().id) }
    val selectedGroup = groups.firstOrNull { it.id == selectedGroupId } ?: groups.first()

    FloatingGlassCard(glowColor = NebulaPurple, modifier = modifier.fillMaxWidth()) {
        Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
            Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                Icon(Icons.AutoMirrored.Filled.MenuBook, contentDescription = AppStrings.t("teacher_plan_title", lang), tint = NebulaPurple)
                Text(
                    text = AppStrings.t("teacher_plan_title", lang),
                    style = MaterialTheme.typography.titleMedium.copy(fontWeight = FontWeight.Bold),
                    color = TextPrimary,
                )
            }

            FlowRow(horizontalArrangement = Arrangement.spacedBy(6.dp), verticalArrangement = Arrangement.spacedBy(6.dp)) {
                groups.take(4).forEach { grp ->
                    FilterChip(
                        selected = grp.id == selectedGroup.id,
                        onClick = { selectedGroupId = grp.id },
                        label = { Text(if (lang == AppLanguage.AR) grp.subjectAr else grp.subjectEn) },
                        colors = FilterChipDefaults.filterChipColors(selectedContainerColor = NebulaPurple, selectedLabelColor = CosmicBlack),
                    )
                }
            }

            when (planState) {
                TeacherPlanUiState.Loading -> {
                    Row(horizontalArrangement = Arrangement.spacedBy(10.dp), verticalAlignment = Alignment.CenterVertically) {
                        CircularProgressIndicator(modifier = Modifier.size(20.dp), color = NebulaPurple, strokeWidth = 2.dp)
                        Text(text = AppStrings.t("teacher_plan_loading", lang), style = MaterialTheme.typography.bodySmall, color = NeonCyan)
                    }
                }
                is TeacherPlanUiState.Error -> {
                    Text(text = "${AppStrings.t("teacher_plan_error", lang)} (${planState.message})", style = MaterialTheme.typography.bodySmall, color = AmberDue)
                }
                is TeacherPlanUiState.Success -> {
                    val plan = planState.plan
                    Text(text = plan.topicTitle, style = MaterialTheme.typography.titleSmall.copy(fontWeight = FontWeight.Bold), color = NeonCyan)
                    PlanSection(AppStrings.t("teacher_plan_pacing", lang), plan.pacingSteps, EmeraldValid)
                    PlanSection(AppStrings.t("teacher_plan_basic_hw", lang), plan.basicHomework, ElectricBlue)
                    PlanSection(AppStrings.t("teacher_plan_challenge_hw", lang), plan.challengeHomework, SolarGold)
                    PlanSection(AppStrings.t("teacher_plan_assistants", lang), plan.assistantChecklist, TextSecondary)
                    OutlinedButton(
                        onClick = {
                            ShareHelper.shareText(
                                context = context,
                                title = plan.topicTitle,
                                body = formatTeacherPlanShare(plan, lang),
                            )
                        },
                        modifier = Modifier
                            .fillMaxWidth()
                            .testTag("teacher_plan_share_button"),
                    ) {
                        Icon(Icons.Default.Share, contentDescription = null, tint = NeonCyan, modifier = Modifier.size(16.dp))
                        Text(text = AppStrings.t("teacher_plan_share", lang), color = NeonCyan)
                    }
                }
                TeacherPlanUiState.Idle -> Unit
            }

            NeonButton(
                text = AppStrings.t("teacher_plan_cta", lang),
                icon = Icons.AutoMirrored.Filled.MenuBook,
                accentColor = NebulaPurple,
                enabled = planState != TeacherPlanUiState.Loading,
                onClick = { onGeneratePlan(selectedGroup) },
                modifier = Modifier
                    .fillMaxWidth()
                    .testTag("teacher_plan_generate_button"),
            )
        }
    }
}

@Composable
private fun PlanSection(title: String, items: List<String>, accent: androidx.compose.ui.graphics.Color) {
    if (items.isEmpty()) return
    Column(verticalArrangement = Arrangement.spacedBy(3.dp)) {
        Text(text = title, style = MaterialTheme.typography.labelMedium, color = accent)
        items.forEach { line ->
            Row(horizontalArrangement = Arrangement.spacedBy(6.dp), verticalAlignment = Alignment.Top) {
                Icon(Icons.Default.CheckCircle, contentDescription = null, tint = accent, modifier = Modifier.size(14.dp))
                Text(text = line, style = MaterialTheme.typography.bodySmall, color = TextPrimary)
            }
        }
    }
}

private fun formatTeacherPlanShare(plan: TeacherLessonPlan, lang: AppLanguage): String {
    val pacing = plan.pacingSteps.joinToString("\n") { "• $it" }
    val basic = plan.basicHomework.joinToString("\n") { "• $it" }
    val challenge = plan.challengeHomework.joinToString("\n") { "• $it" }
    return if (lang == AppLanguage.AR) {
        "خطة كشكول للحصة: ${plan.topicTitle}\n\nالتقسيم الزمني:\n$pacing\n\nواجب التأسيس:\n$basic\n\nمسائل المتفوقين:\n$challenge"
    } else {
        "Kashkool Lesson Plan: ${plan.topicTitle}\n\nPacing:\n$pacing\n\nCore Homework:\n$basic\n\nChallenge:\n$challenge"
    }
}

@Composable
fun SecretaryNoticeDialog(
    noticeState: SecretaryNoticeUiState,
    lang: AppLanguage,
    onDismiss: () -> Unit,
) {
    if (noticeState is SecretaryNoticeUiState.Idle) return
    val context = LocalContext.current
    val clipboard = LocalClipboard.current
    val scope = rememberCoroutineScope()

    val studentName = when (noticeState) {
        is SecretaryNoticeUiState.Loading -> noticeState.studentName
        is SecretaryNoticeUiState.Success -> noticeState.studentName
        is SecretaryNoticeUiState.Error -> noticeState.studentName
        SecretaryNoticeUiState.Idle -> ""
    }

    AlertDialog(
        onDismissRequest = onDismiss,
        containerColor = SpaceSurface,
        title = { Text("${AppStrings.t("draft_notice_title", lang)} — $studentName", color = TextPrimary) },
        text = {
            when (noticeState) {
                is SecretaryNoticeUiState.Loading -> {
                    Row(horizontalArrangement = Arrangement.spacedBy(10.dp), verticalAlignment = Alignment.CenterVertically) {
                        CircularProgressIndicator(modifier = Modifier.size(22.dp), color = NeonCyan, strokeWidth = 2.dp)
                        Text(text = AppStrings.t("draft_notice_loading", lang), style = MaterialTheme.typography.bodySmall, color = NeonCyan)
                    }
                }
                is SecretaryNoticeUiState.Error -> {
                    Text(text = noticeState.message, style = MaterialTheme.typography.bodySmall, color = AmberDue)
                }
                is SecretaryNoticeUiState.Success -> {
                    Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                        if (noticeState.draft.toneTag.isNotBlank()) {
                            StatusPill(label = noticeState.draft.toneTag, color = EmeraldValid)
                        }
                        Text(text = noticeState.draft.messageText, style = MaterialTheme.typography.bodyMedium, color = TextPrimary)
                    }
                }
                SecretaryNoticeUiState.Idle -> Unit
            }
        },
        confirmButton = {
            if (noticeState is SecretaryNoticeUiState.Success) {
                Row(horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                    TextButton(
                        onClick = {
                            ShareHelper.shareText(
                                context = context,
                                title = AppStrings.t("draft_notice_title", lang),
                                body = noticeState.draft.messageText,
                            )
                        }
                    ) {
                        Icon(Icons.Default.Share, contentDescription = null, tint = EmeraldValid)
                        Text(AppStrings.t("share_whatsapp", lang), color = EmeraldValid)
                    }
                    TextButton(
                        onClick = {
                            scope.launch {
                                clipboard.setClipEntry(
                                    ClipEntry(ClipData.newPlainText("notice", noticeState.draft.messageText))
                                )
                            }
                            onDismiss()
                        }
                    ) {
                        Icon(Icons.Default.ContentCopy, contentDescription = null, tint = NeonCyan)
                        Text(AppStrings.t("copy_text", lang), color = NeonCyan)
                    }
                }
            }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) {
                Text(AppStrings.t("close", lang), color = TextSecondary)
            }
        },
    )
}
