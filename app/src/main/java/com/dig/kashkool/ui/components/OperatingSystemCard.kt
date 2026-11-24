package com.dig.kashkool.ui.components

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Analytics
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.ErrorOutline
import androidx.compose.material.icons.filled.Verified
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalLayoutDirection
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.LayoutDirection
import androidx.compose.ui.unit.dp
import com.dig.kashkool.core.l10n.AppLanguage
import com.dig.kashkool.core.l10n.AppStrings
import com.dig.kashkool.core.or.SystemOperatingReport
import com.dig.kashkool.ui.theme.AmberDue
import com.dig.kashkool.ui.theme.CrimsonBlocked
import com.dig.kashkool.ui.theme.EmeraldValid
import com.dig.kashkool.ui.theme.NebulaPurple
import com.dig.kashkool.ui.theme.NeonCyan
import com.dig.kashkool.ui.theme.SolarGold
import com.dig.kashkool.ui.theme.TextPrimary
import com.dig.kashkool.ui.theme.TextSecondary
import com.dig.kashkool.ui.viewmodel.AiBriefingState

@Composable
fun OperatingSystemCard(
    report: SystemOperatingReport,
    briefingState: AiBriefingState,
    lang: AppLanguage,
    onRequestBriefing: () -> Unit,
    modifier: Modifier = Modifier,
) {
    FloatingGlassCard(
        glowColor = NebulaPurple,
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
                        imageVector = Icons.Default.Verified,
                        contentDescription = AppStrings.t("os_engine_title", lang),
                        tint = EmeraldValid,
                        modifier = Modifier.size(22.dp),
                    )
                    Text(
                        text = AppStrings.t("os_engine_title", lang),
                        style = MaterialTheme.typography.titleMedium.copy(fontWeight = FontWeight.Bold),
                        color = TextPrimary,
                    )
                }
                StatusPill(
                    label = "${AppStrings.t("os_certainty_index", lang)}: ${report.certaintyScorePercent}%",
                    color = EmeraldValid,
                )
            }

            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(8.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                StatusPill(
                    label = AppStrings.t("os_or_verified_badge", lang),
                    color = NeonCyan,
                )
                StatusPill(
                    label = AppStrings.t(
                        if (report.resourceConflict.hasHallOrScheduleConflict) "hall_conflict_alert" else "hall_clear_badge",
                        lang,
                    ),
                    color = if (report.resourceConflict.hasHallOrScheduleConflict) AmberDue else EmeraldValid,
                )
            }

            report.decisions.forEach { decision ->
                FloatingGlassCard(
                    glowColor = if (decision.priorityHigh) SolarGold else NeonCyan.copy(alpha = 0.45f),
                    modifier = Modifier.fillMaxWidth(),
                ) {
                    Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.SpaceBetween,
                            verticalAlignment = Alignment.CenterVertically,
                        ) {
                            Text(
                                text = if (lang == AppLanguage.AR) decision.titleAr else decision.titleEn,
                                style = MaterialTheme.typography.titleSmall,
                                color = if (decision.priorityHigh) SolarGold else NeonCyan,
                                modifier = Modifier.weight(1f),
                            )
                            CompositionLocalProvider(LocalLayoutDirection provides LayoutDirection.Ltr) {
                                Text(
                                    text = decision.verifiedFormula,
                                    style = MaterialTheme.typography.labelSmall.copy(fontFamily = FontFamily.Monospace),
                                    color = EmeraldValid,
                                )
                            }
                        }
                        Text(
                            text = if (lang == AppLanguage.AR) decision.detailAr else decision.detailEn,
                            style = MaterialTheme.typography.bodySmall,
                            color = TextPrimary,
                        )
                    }
                }
            }

            when (briefingState) {
                AiBriefingState.Idle -> {
                    NeonButton(
                        text = AppStrings.t("os_ask_ai_briefing", lang),
                        icon = Icons.Default.Analytics,
                        accentColor = NebulaPurple,
                        onClick = onRequestBriefing,
                        modifier = Modifier
                            .fillMaxWidth()
                            .testTag("os_request_briefing_button"),
                    )
                }
                AiBriefingState.Loading -> {
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(vertical = 8.dp),
                        horizontalArrangement = Arrangement.Center,
                        verticalAlignment = Alignment.CenterVertically,
                    ) {
                        CircularProgressIndicator(
                            modifier = Modifier.size(22.dp),
                            color = NeonCyan,
                            strokeWidth = 2.dp,
                        )
                    }
                }
                is AiBriefingState.Success -> {
                    val b = briefingState.briefing
                    FloatingGlassCard(
                        glowColor = EmeraldValid,
                        modifier = Modifier.fillMaxWidth(),
                    ) {
                        Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
                            Text(
                                text = AppStrings.t("os_ai_briefing_title", lang),
                                style = MaterialTheme.typography.labelMedium,
                                color = EmeraldValid,
                            )
                            Text(
                                text = b.headline,
                                style = MaterialTheme.typography.titleSmall,
                                color = TextPrimary,
                            )
                            Text(
                                text = b.confidenceStatement,
                                style = MaterialTheme.typography.bodySmall,
                                color = TextSecondary,
                            )
                            Text(
                                text = b.topDecision,
                                style = MaterialTheme.typography.bodyMedium.copy(fontWeight = FontWeight.SemiBold),
                                color = SolarGold,
                            )
                            b.nextActionSteps.forEach { step ->
                                Row(
                                    verticalAlignment = Alignment.Top,
                                    horizontalArrangement = Arrangement.spacedBy(6.dp),
                                ) {
                                    Icon(
                                        imageVector = Icons.Default.CheckCircle,
                                        contentDescription = null,
                                        tint = NeonCyan,
                                        modifier = Modifier.size(16.dp),
                                    )
                                    Text(
                                        text = step,
                                        style = MaterialTheme.typography.bodySmall,
                                        color = TextPrimary,
                                    )
                                }
                            }
                            Text(
                                text = b.trustGuarantee,
                                style = MaterialTheme.typography.labelSmall,
                                color = EmeraldValid,
                            )
                            OutlinedButton(
                                onClick = onRequestBriefing,
                                modifier = Modifier.fillMaxWidth(),
                            ) {
                                Text(AppStrings.t("os_ai_retry", lang), color = NeonCyan)
                            }
                        }
                    }
                }
                is AiBriefingState.Error -> {
                    FloatingGlassCard(
                        glowColor = AmberDue,
                        modifier = Modifier.fillMaxWidth(),
                    ) {
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
                                    text = AppStrings.t("os_ai_error_prefix", lang),
                                    style = MaterialTheme.typography.bodySmall,
                                    color = TextPrimary,
                                )
                            }
                            Text(
                                text = briefingState.message,
                                style = MaterialTheme.typography.labelSmall,
                                color = AmberDue,
                            )
                            OutlinedButton(
                                onClick = onRequestBriefing,
                                modifier = Modifier.fillMaxWidth(),
                            ) {
                                Text(AppStrings.t("os_ai_retry", lang), color = NeonCyan)
                            }
                        }
                    }
                }
            }
        }
    }
}
