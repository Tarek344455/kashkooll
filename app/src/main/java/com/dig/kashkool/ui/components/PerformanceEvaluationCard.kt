package com.dig.kashkool.ui.components

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.size
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.TrendingUp
import androidx.compose.material.icons.filled.Assessment
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.ErrorOutline
import androidx.compose.material.icons.filled.Flag
import androidx.compose.material.icons.filled.Person
import androidx.compose.material.icons.filled.School
import androidx.compose.material.icons.filled.Share
import androidx.compose.material.icons.filled.Verified
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.FilterChip
import androidx.compose.material3.FilterChipDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.dig.kashkool.core.l10n.AppLanguage
import com.dig.kashkool.core.l10n.AppStrings
import com.dig.kashkool.core.utils.ShareHelper
import com.dig.kashkool.data.local.EvaluationTargetType
import com.dig.kashkool.data.local.PerformanceEvaluationEntity
import com.dig.kashkool.data.local.StudentEntity
import com.dig.kashkool.ui.theme.AmberDue
import com.dig.kashkool.ui.theme.CosmicBlack
import com.dig.kashkool.ui.theme.CrimsonBlocked
import com.dig.kashkool.ui.theme.ElectricBlue
import com.dig.kashkool.ui.theme.EmeraldValid
import com.dig.kashkool.ui.theme.NebulaPurple
import com.dig.kashkool.ui.theme.NeonCyan
import com.dig.kashkool.ui.theme.SolarGold
import com.dig.kashkool.ui.theme.TextPrimary
import com.dig.kashkool.ui.theme.TextSecondary
import com.dig.kashkool.ui.viewmodel.EvaluationUiState

enum class EvaluationCardMode {
    TEACHER_CONSOLE,
    STUDENT_SELF,
    PARENT_CHILD,
}

@OptIn(ExperimentalLayoutApi::class)
@Composable
fun PerformanceEvaluationCard(
    evaluationState: EvaluationUiState,
    savedEvaluations: List<PerformanceEvaluationEntity>,
    lang: AppLanguage,
    mode: EvaluationCardMode,
    students: List<StudentEntity> = emptyList(),
    onEvaluateTeacher: () -> Unit = {},
    onEvaluateStudent: (String?) -> Unit = {},
    buildShareText: (PerformanceEvaluationEntity) -> String = { "" },
    modifier: Modifier = Modifier,
) {
    val context = LocalContext.current
    var selectedStudentId by remember(students.firstOrNull()?.id) {
        mutableStateOf(students.firstOrNull()?.id)
    }

    val latestSaved = remember(savedEvaluations, mode, selectedStudentId) {
        when (mode) {
            EvaluationCardMode.TEACHER_CONSOLE -> {
                savedEvaluations.firstOrNull {
                    it.targetType == EvaluationTargetType.TEACHER ||
                        (selectedStudentId != null && it.targetId == selectedStudentId)
                } ?: savedEvaluations.firstOrNull()
            }
            EvaluationCardMode.STUDENT_SELF, EvaluationCardMode.PARENT_CHILD -> {
                val targetId = students.firstOrNull()?.id
                savedEvaluations.firstOrNull {
                    it.targetType == EvaluationTargetType.STUDENT && (targetId == null || it.targetId == targetId)
                } ?: savedEvaluations.firstOrNull { it.targetType == EvaluationTargetType.STUDENT }
            }
        }
    }

    FloatingGlassCard(
        glowColor = NeonCyan,
        modifier = modifier.fillMaxWidth(),
    ) {
        Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
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
                        imageVector = Icons.Default.Assessment,
                        contentDescription = AppStrings.t("eval_section_title", lang),
                        tint = NeonCyan,
                        modifier = Modifier.size(22.dp),
                    )
                    Text(
                        text = AppStrings.t("eval_section_title", lang),
                        style = MaterialTheme.typography.titleMedium.copy(fontWeight = FontWeight.Bold),
                        color = TextPrimary,
                    )
                }
                StatusPill(
                    label = AppStrings.t("zero_fee", lang),
                    color = EmeraldValid,
                )
            }

            if (mode == EvaluationCardMode.TEACHER_CONSOLE && students.isNotEmpty()) {
                Text(
                    text = AppStrings.t("eval_select_student", lang),
                    style = MaterialTheme.typography.labelMedium,
                    color = TextSecondary,
                )
                FlowRow(
                    horizontalArrangement = Arrangement.spacedBy(6.dp),
                    verticalArrangement = Arrangement.spacedBy(6.dp),
                ) {
                    students.take(6).forEach { stu ->
                        val sName = if (lang == AppLanguage.AR) stu.nameAr else stu.nameEn
                        val selected = selectedStudentId == stu.id
                        FilterChip(
                            selected = selected,
                            onClick = { selectedStudentId = stu.id },
                            modifier = Modifier.testTag("eval_student_chip_${stu.id}"),
                            label = { Text(sName) },
                            colors = FilterChipDefaults.filterChipColors(
                                selectedContainerColor = NeonCyan,
                                selectedLabelColor = CosmicBlack,
                            ),
                        )
                    }
                }
            }

            when (evaluationState) {
                EvaluationUiState.Loading -> {
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.spacedBy(10.dp),
                        verticalAlignment = Alignment.CenterVertically,
                    ) {
                        CircularProgressIndicator(
                            modifier = Modifier.size(22.dp),
                            color = NeonCyan,
                            strokeWidth = 2.dp,
                        )
                        Text(
                            text = AppStrings.t("eval_loading", lang),
                            style = MaterialTheme.typography.bodySmall,
                            color = NeonCyan,
                        )
                    }
                }
                is EvaluationUiState.Error -> {
                    FloatingGlassCard(glowColor = AmberDue, modifier = Modifier.fillMaxWidth()) {
                        Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
                            Row(
                                verticalAlignment = Alignment.CenterVertically,
                                horizontalArrangement = Arrangement.spacedBy(6.dp),
                            ) {
                                Icon(
                                    imageVector = Icons.Default.ErrorOutline,
                                    contentDescription = null,
                                    tint = CrimsonBlocked,
                                    modifier = Modifier.size(18.dp),
                                )
                                Text(
                                    text = AppStrings.t("eval_error_prefix", lang),
                                    style = MaterialTheme.typography.bodySmall,
                                    color = TextPrimary,
                                )
                            }
                            Text(
                                text = evaluationState.message,
                                style = MaterialTheme.typography.labelSmall,
                                color = AmberDue,
                            )
                        }
                    }
                }
                else -> Unit
            }

            val displayedEvaluation = when (evaluationState) {
                is EvaluationUiState.Success -> evaluationState.evaluation
                else -> latestSaved
            }

            AnimatedVisibility(visible = displayedEvaluation != null) {
                displayedEvaluation?.let { eval ->
                    EvaluationReportBody(
                        evaluation = eval,
                        isSavedSnapshot = evaluationState !is EvaluationUiState.Success,
                        lang = lang,
                        onShare = {
                            ShareHelper.shareText(
                                context = context,
                                title = AppStrings.t("eval_section_title", lang),
                                body = buildShareText(eval),
                            )
                        },
                    )
                }
            }

            if (displayedEvaluation == null && evaluationState == EvaluationUiState.Idle) {
                Text(
                    text = AppStrings.t("eval_empty_hint", lang),
                    style = MaterialTheme.typography.bodySmall,
                    color = TextSecondary,
                )
            }

            val busy = evaluationState == EvaluationUiState.Loading
            when (mode) {
                EvaluationCardMode.TEACHER_CONSOLE -> {
                    Column(
                        modifier = Modifier.fillMaxWidth(),
                        verticalArrangement = Arrangement.spacedBy(8.dp),
                    ) {
                        NeonButton(
                            text = AppStrings.t("eval_teacher_btn", lang),
                            icon = Icons.Default.School,
                            accentColor = SolarGold,
                            enabled = !busy,
                            onClick = onEvaluateTeacher,
                            modifier = Modifier
                                .fillMaxWidth()
                                .testTag("eval_teacher_button"),
                        )
                        NeonButton(
                            text = AppStrings.t("eval_student_btn", lang),
                            icon = Icons.Default.Person,
                            accentColor = NeonCyan,
                            enabled = !busy && selectedStudentId != null,
                            onClick = { onEvaluateStudent(selectedStudentId) },
                            modifier = Modifier
                                .fillMaxWidth()
                                .testTag("eval_student_button"),
                        )
                    }
                }
                EvaluationCardMode.STUDENT_SELF -> {
                    NeonButton(
                        text = AppStrings.t(
                            if (evaluationState is EvaluationUiState.Error) "eval_retry" else "eval_my_progress_btn",
                            lang,
                        ),
                        icon = Icons.AutoMirrored.Filled.TrendingUp,
                        accentColor = NebulaPurple,
                        enabled = !busy,
                        onClick = { onEvaluateStudent(students.firstOrNull()?.id) },
                        modifier = Modifier
                            .fillMaxWidth()
                            .testTag("eval_my_progress_button"),
                    )
                }
                EvaluationCardMode.PARENT_CHILD -> {
                    NeonButton(
                        text = AppStrings.t(
                            if (evaluationState is EvaluationUiState.Error) "eval_retry" else "eval_child_btn",
                            lang,
                        ),
                        icon = Icons.Default.Verified,
                        accentColor = EmeraldValid,
                        enabled = !busy,
                        onClick = { onEvaluateStudent(students.firstOrNull()?.id) },
                        modifier = Modifier
                            .fillMaxWidth()
                            .testTag("eval_child_progress_button"),
                    )
                }
            }
        }
    }
}

@Composable
private fun EvaluationReportBody(
    evaluation: PerformanceEvaluationEntity,
    isSavedSnapshot: Boolean,
    lang: AppLanguage,
    onShare: () -> Unit,
) {
    val scoreColor = when {
        evaluation.overallScore >= 85 -> EmeraldValid
        evaluation.overallScore >= 65 -> SolarGold
        else -> AmberDue
    }

    FloatingGlassCard(
        glowColor = scoreColor,
        modifier = Modifier
            .fillMaxWidth()
            .testTag("evaluation_result_card"),
    ) {
        Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Column(modifier = Modifier.weight(1f)) {
                    Text(
                        text = evaluation.targetName,
                        style = MaterialTheme.typography.titleSmall.copy(fontWeight = FontWeight.Bold),
                        color = TextPrimary,
                    )
                    if (evaluation.trustBadge.isNotBlank()) {
                        Text(
                            text = evaluation.trustBadge,
                            style = MaterialTheme.typography.labelSmall,
                            color = EmeraldValid,
                        )
                    }
                }
                Row(
                    horizontalArrangement = Arrangement.spacedBy(6.dp),
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    if (isSavedSnapshot) {
                        StatusPill(
                            label = AppStrings.t("eval_saved_badge", lang),
                            color = ElectricBlue,
                        )
                    }
                    StatusPill(
                        label = "${evaluation.overallScore}/100",
                        color = scoreColor,
                    )
                }
            }

            LinearProgressIndicator(
                progress = { (evaluation.overallScore / 100f).coerceIn(0f, 1f) },
                modifier = Modifier
                    .fillMaxWidth()
                    .height(6.dp)
                    .clip(MaterialTheme.shapes.small),
                color = scoreColor,
                trackColor = Color.White.copy(alpha = 0.1f),
            )

            Text(
                text = evaluation.analyticalSummary,
                style = MaterialTheme.typography.bodySmall,
                color = TextPrimary,
            )

            FloatingGlassCard(
                glowColor = NeonCyan.copy(alpha = 0.6f),
                modifier = Modifier.fillMaxWidth(),
            ) {
                Column(verticalArrangement = Arrangement.spacedBy(3.dp)) {
                    Text(
                        text = AppStrings.t("eval_instant_feedback_title", lang),
                        style = MaterialTheme.typography.labelMedium,
                        color = NeonCyan,
                    )
                    Text(
                        text = evaluation.instantFeedback,
                        style = MaterialTheme.typography.bodySmall,
                        color = TextPrimary,
                    )
                }
            }

            if (evaluation.strengths.isNotEmpty()) {
                Text(
                    text = AppStrings.t("eval_strengths_title", lang),
                    style = MaterialTheme.typography.labelMedium,
                    color = EmeraldValid,
                )
                evaluation.strengths.forEach { item ->
                    Row(
                        verticalAlignment = Alignment.Top,
                        horizontalArrangement = Arrangement.spacedBy(6.dp),
                    ) {
                        Icon(
                            imageVector = Icons.Default.CheckCircle,
                            contentDescription = null,
                            tint = EmeraldValid,
                            modifier = Modifier.size(16.dp),
                        )
                        Text(text = item, style = MaterialTheme.typography.bodySmall, color = TextPrimary)
                    }
                }
            }

            if (evaluation.improvementAreas.isNotEmpty()) {
                Text(
                    text = AppStrings.t("eval_improvements_title", lang),
                    style = MaterialTheme.typography.labelMedium,
                    color = AmberDue,
                )
                evaluation.improvementAreas.forEach { item ->
                    Row(
                        verticalAlignment = Alignment.Top,
                        horizontalArrangement = Arrangement.spacedBy(6.dp),
                    ) {
                        Icon(
                            imageVector = Icons.Default.Flag,
                            contentDescription = null,
                            tint = AmberDue,
                            modifier = Modifier.size(16.dp),
                        )
                        Text(text = item, style = MaterialTheme.typography.bodySmall, color = TextSecondary)
                    }
                }
            }

            if (evaluation.nextActionPlan.isNotEmpty()) {
                Text(
                    text = AppStrings.t("eval_next_plan_title", lang),
                    style = MaterialTheme.typography.labelMedium,
                    color = SolarGold,
                )
                evaluation.nextActionPlan.forEach { step ->
                    Text(
                        text = "• $step",
                        style = MaterialTheme.typography.bodySmall,
                        color = TextPrimary,
                    )
                }
            }

            if (evaluation.trustVerificationNote.isNotBlank()) {
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(6.dp),
                ) {
                    Icon(
                        imageVector = Icons.Default.Verified,
                        contentDescription = AppStrings.t("eval_trust_note_title", lang),
                        tint = EmeraldValid,
                        modifier = Modifier.size(15.dp),
                    )
                    Text(
                        text = evaluation.trustVerificationNote,
                        style = MaterialTheme.typography.labelSmall,
                        color = EmeraldValid,
                    )
                }
            }

            OutlinedButton(
                onClick = onShare,
                modifier = Modifier
                    .fillMaxWidth()
                    .testTag("eval_share_whatsapp_button"),
            ) {
                Icon(
                    imageVector = Icons.Default.Share,
                    contentDescription = AppStrings.t("eval_share_cta", lang),
                    tint = NeonCyan,
                    modifier = Modifier.size(16.dp),
                )
                Text(
                    text = AppStrings.t("eval_share_cta", lang),
                    color = NeonCyan,
                )
            }
        }
    }
}
