package com.dig.kashkool.ui.screens

import android.content.ClipData
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.EventNote
import androidx.compose.material.icons.filled.AccountBalanceWallet
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.ContentCopy
import androidx.compose.material.icons.filled.Favorite
import androidx.compose.material.icons.filled.Refresh
import androidx.compose.material.icons.filled.School
import androidx.compose.material.icons.filled.Share
import androidx.compose.material.icons.filled.WarningAmber
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.ClipEntry
import androidx.compose.ui.platform.LocalClipboard
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalLayoutDirection
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.unit.LayoutDirection
import androidx.compose.ui.unit.dp
import com.dig.kashkool.core.l10n.AppLanguage
import com.dig.kashkool.core.l10n.AppStrings
import com.dig.kashkool.core.utils.EgyptValidators
import com.dig.kashkool.core.utils.ShareHelper
import com.dig.kashkool.data.local.PerformanceEvaluationEntity
import com.dig.kashkool.ui.components.EmptyStateCard
import com.dig.kashkool.ui.components.EvaluationCardMode
import com.dig.kashkool.ui.components.FloatingGlassCard
import com.dig.kashkool.ui.components.NeonButton
import com.dig.kashkool.ui.components.PerformanceEvaluationCard
import com.dig.kashkool.ui.components.StatusPill
import com.dig.kashkool.ui.theme.AmberDue
import com.dig.kashkool.ui.theme.CrimsonBlocked
import com.dig.kashkool.ui.theme.EmeraldValid
import com.dig.kashkool.ui.theme.NebulaPurple
import com.dig.kashkool.ui.theme.NeonCyan
import com.dig.kashkool.ui.theme.SolarGold
import com.dig.kashkool.ui.theme.TextPrimary
import com.dig.kashkool.ui.theme.TextSecondary
import com.dig.kashkool.ui.viewmodel.KashkoolUiState
import com.dig.kashkool.ui.viewmodel.ParentDigestUiState
import kotlinx.coroutines.launch
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

@Composable
fun ParentPortalScreen(
    state: KashkoolUiState,
    onTopUpClick: () -> Unit,
    onReassureNow: () -> Unit = {},
    buildCheerMessage: (AppLanguage) -> String = { "" },
    buildParentReportText: (AppLanguage) -> String = { "" },
    onCheerCopied: () -> Unit = {},
    onEvaluateChild: (String?) -> Unit = {},
    buildEvaluationShareText: (PerformanceEvaluationEntity) -> String = { "" },
    onRefreshDigest: () -> Unit = {},
) {
    val lang = state.language
    val clipboard = LocalClipboard.current
    val scope = rememberCoroutineScope()
    val context = LocalContext.current
    val student = state.students.firstOrNull()
    val childOr = student?.let { state.operatingReport?.studentProfiles?.get(it.id) }
    val coveredSessions = childOr?.coveredSessions ?: ((student?.walletBalancePiasters ?: 24000L) / 8000L).toInt()
    val timeFormatter = remember { SimpleDateFormat("dd MMM · h:mm a", Locale.US) }

    val studentTimeline = remember(state.attendance, student?.id) {
        if (student == null) state.attendance
        else state.attendance.filter { it.studentId == student.id }.ifEmpty { state.attendance }
    }

    LazyColumn(
        modifier = Modifier.fillMaxSize(),
        contentPadding = PaddingValues(horizontal = 20.dp, vertical = 18.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp),
    ) {
        if (student != null) {
            item {
                FloatingGlassCard(modifier = Modifier.fillMaxWidth()) {
                    Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
                        Row(
                            verticalAlignment = Alignment.CenterVertically,
                            horizontalArrangement = Arrangement.spacedBy(12.dp),
                        ) {
                            Icon(
                                imageVector = Icons.Default.School,
                                contentDescription = null,
                                tint = NeonCyan,
                                modifier = Modifier.size(34.dp),
                            )
                            Column(modifier = Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(2.dp)) {
                                Text(
                                    text = if (lang == AppLanguage.AR) student.nameAr else student.nameEn,
                                    style = MaterialTheme.typography.titleLarge,
                                    color = TextPrimary,
                                )
                                Text(
                                    text = "${AppStrings.t("student_mastery", lang)}: ${student.masteryPercent}% · ${student.streakDays} ${AppStrings.t("streak_days", lang)}",
                                    style = MaterialTheme.typography.bodySmall,
                                    color = TextSecondary,
                                )
                            }
                            StatusPill(
                                label = if (lang == AppLanguage.AR) "$coveredSessions حصص متاحة" else "$coveredSessions sessions",
                                color = EmeraldValid,
                            )
                        }

                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.spacedBy(8.dp),
                        ) {
                            NeonButton(
                                text = AppStrings.t("parent_reassure_cta", lang),
                                icon = Icons.Default.Favorite,
                                accentColor = EmeraldValid,
                                onClick = onReassureNow,
                                modifier = Modifier
                                    .weight(1f)
                                    .testTag("parent_reassure_button"),
                            )
                            OutlinedButton(
                                onClick = {
                                    ShareHelper.shareText(
                                        context = context,
                                        title = AppStrings.t("share_report", lang),
                                        body = buildParentReportText(lang),
                                    )
                                },
                                modifier = Modifier
                                    .weight(1f)
                                    .testTag("parent_share_report_button"),
                            ) {
                                Icon(
                                    imageVector = Icons.Default.Share,
                                    contentDescription = AppStrings.t("share_whatsapp", lang),
                                    tint = NeonCyan,
                                    modifier = Modifier.size(16.dp),
                                )
                                Text(
                                    text = AppStrings.t("share_whatsapp", lang),
                                    color = TextPrimary,
                                    maxLines = 1,
                                )
                            }
                        }

                        OutlinedButton(
                            onClick = {
                                val dynamicCheer = (state.parentDigestState as? ParentDigestUiState.Success)
                                    ?.digest?.cheerMessage?.takeIf { it.isNotBlank() }
                                val cheer = dynamicCheer ?: buildCheerMessage(lang)
                                scope.launch {
                                    clipboard.setClipEntry(
                                        ClipEntry(ClipData.newPlainText("cheer", cheer))
                                    )
                                }
                                onCheerCopied()
                            },
                            modifier = Modifier
                                .fillMaxWidth()
                                .testTag("parent_cheer_button"),
                        ) {
                            Icon(
                                imageVector = Icons.Default.ContentCopy,
                                contentDescription = null,
                                tint = NebulaPurple,
                                modifier = Modifier.size(16.dp),
                            )
                            Text(
                                text = AppStrings.t("parent_cheer_cta", lang),
                                color = TextPrimary,
                            )
                        }
                    }
                }
            }
        }

        if (coveredSessions <= 2) {
            item {
                FloatingGlassCard(glowColor = AmberDue, modifier = Modifier.fillMaxWidth()) {
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.spacedBy(10.dp),
                        verticalAlignment = Alignment.CenterVertically,
                    ) {
                        Icon(
                            imageVector = Icons.Default.WarningAmber,
                            contentDescription = null,
                            tint = AmberDue,
                        )
                        Text(
                            text = AppStrings.t("parent_dignity_alert", lang),
                            style = MaterialTheme.typography.bodySmall,
                            color = TextPrimary,
                            modifier = Modifier.weight(1f),
                        )
                    }
                }
            }
        }

        item {
            FloatingGlassCard(glowColor = SolarGold, modifier = Modifier.fillMaxWidth()) {
                Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically,
                    ) {
                        Text(
                            text = AppStrings.t("parent_digest_title", lang),
                            style = MaterialTheme.typography.titleMedium,
                            color = SolarGold,
                            modifier = Modifier.weight(1f),
                        )
                        OutlinedButton(
                            onClick = onRefreshDigest,
                            enabled = state.parentDigestState !is ParentDigestUiState.Loading,
                            modifier = Modifier.testTag("parent_digest_refresh_button"),
                        ) {
                            Icon(
                                imageVector = Icons.Default.Refresh,
                                contentDescription = null,
                                tint = SolarGold,
                                modifier = Modifier.size(16.dp),
                            )
                            Text(AppStrings.t("parent_digest_refresh", lang), color = SolarGold)
                        }
                    }
                    when (val digestState = state.parentDigestState) {
                        ParentDigestUiState.Idle -> {
                            Text(
                                text = AppStrings.t("parent_digest_body", lang),
                                style = MaterialTheme.typography.bodyMedium,
                                color = TextPrimary,
                            )
                        }
                        ParentDigestUiState.Loading -> {
                            Row(
                                horizontalArrangement = Arrangement.spacedBy(10.dp),
                                verticalAlignment = Alignment.CenterVertically,
                            ) {
                                CircularProgressIndicator(
                                    modifier = Modifier.size(20.dp),
                                    color = SolarGold,
                                    strokeWidth = 2.dp,
                                )
                                Text(
                                    text = AppStrings.t("parent_digest_loading", lang),
                                    style = MaterialTheme.typography.bodySmall,
                                    color = SolarGold,
                                )
                            }
                        }
                        is ParentDigestUiState.Error -> {
                            Text(
                                text = AppStrings.t("parent_digest_error", lang),
                                style = MaterialTheme.typography.bodySmall,
                                color = AmberDue,
                            )
                            Text(
                                text = AppStrings.t("parent_digest_body", lang),
                                style = MaterialTheme.typography.bodyMedium,
                                color = TextPrimary,
                            )
                        }
                        is ParentDigestUiState.Success -> {
                            val d = digestState.digest
                            if (d.headline.isNotBlank()) {
                                Text(
                                    text = d.headline,
                                    style = MaterialTheme.typography.titleSmall,
                                    color = NeonCyan,
                                )
                            }
                            Text(
                                text = d.weeklyNarrative,
                                style = MaterialTheme.typography.bodyMedium,
                                color = TextPrimary,
                            )
                            if (d.homeSupportTip.isNotBlank()) {
                                FloatingGlassCard(glowColor = EmeraldValid, modifier = Modifier.fillMaxWidth()) {
                                    Column(verticalArrangement = Arrangement.spacedBy(2.dp)) {
                                        Text(
                                            text = AppStrings.t("parent_home_tip", lang),
                                            style = MaterialTheme.typography.labelMedium,
                                            color = EmeraldValid,
                                        )
                                        Text(
                                            text = d.homeSupportTip,
                                            style = MaterialTheme.typography.bodySmall,
                                            color = TextPrimary,
                                        )
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        item {
            PerformanceEvaluationCard(
                evaluationState = state.evaluationState,
                savedEvaluations = state.evaluations,
                lang = lang,
                mode = EvaluationCardMode.PARENT_CHILD,
                students = state.students,
                onEvaluateStudent = onEvaluateChild,
                buildShareText = buildEvaluationShareText,
            )
        }

        item {
            Text(
                text = AppStrings.t("attendance_timeline", lang),
                style = MaterialTheme.typography.titleLarge,
                color = TextPrimary,
            )
        }

        if (studentTimeline.isEmpty()) {
            item {
                EmptyStateCard(
                    icon = Icons.AutoMirrored.Filled.EventNote,
                    message = AppStrings.t("timeline_empty", lang),
                )
            }
        } else {
            items(studentTimeline, key = { it.id }) { rec ->
                val statusColor = when (rec.feedbackStatus) {
                    "valid" -> EmeraldValid
                    "due" -> AmberDue
                    else -> CrimsonBlocked
                }
                val statusText = when (rec.feedbackStatus) {
                    "valid" -> AppStrings.t("timeline_status_valid", lang)
                    "due" -> AppStrings.t("timeline_status_due", lang)
                    else -> AppStrings.t("timeline_status_blocked", lang)
                }
                val groupName = state.groups.firstOrNull { it.id == rec.groupId }?.let {
                    if (lang == AppLanguage.AR) it.nameAr else it.nameEn
                } ?: if (lang == AppLanguage.AR) rec.studentNameAr else rec.studentNameEn

                FloatingGlassCard(glowColor = statusColor, modifier = Modifier.fillMaxWidth()) {
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
                                imageVector = Icons.Default.CheckCircle,
                                contentDescription = null,
                                tint = statusColor,
                                modifier = Modifier.size(20.dp),
                            )
                            Column {
                                Text(
                                    text = groupName,
                                    style = MaterialTheme.typography.bodyMedium,
                                    color = TextPrimary,
                                )
                                CompositionLocalProvider(LocalLayoutDirection provides LayoutDirection.Ltr) {
                                    Text(
                                        text = timeFormatter.format(Date(rec.timestampMillis)),
                                        style = MaterialTheme.typography.labelSmall,
                                        color = TextSecondary,
                                    )
                                }
                            }
                        }
                        StatusPill(label = statusText, color = statusColor)
                    }
                }
            }
        }

        item {
            FloatingGlassCard(glowColor = EmeraldValid, modifier = Modifier.fillMaxWidth()) {
                Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween,
                    ) {
                        Text(
                            text = AppStrings.t("family_wallet", lang),
                            style = MaterialTheme.typography.titleMedium,
                            color = TextPrimary,
                        )
                        Text(
                            text = EgyptValidators.formatPiasters(
                                student?.walletBalancePiasters ?: 24000L,
                                lang.code,
                            ),
                            style = MaterialTheme.typography.titleMedium,
                            color = EmeraldValid,
                        )
                    }
                    NeonButton(
                        text = AppStrings.t("topup_now", lang),
                        icon = Icons.Default.AccountBalanceWallet,
                        accentColor = EmeraldValid,
                        onClick = onTopUpClick,
                        modifier = Modifier
                            .fillMaxWidth()
                            .testTag("parent_topup_button"),
                    )
                }
            }
        }
    }
}
