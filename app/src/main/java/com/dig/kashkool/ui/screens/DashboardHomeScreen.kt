package com.dig.kashkool.ui.screens

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.AccountBalanceWallet
import androidx.compose.material.icons.filled.AutoStories
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.FamilyRestroom
import androidx.compose.material.icons.filled.Insights
import androidx.compose.material.icons.filled.LocalFireDepartment
import androidx.compose.material.icons.filled.Payments
import androidx.compose.material.icons.filled.PointOfSale
import androidx.compose.material.icons.filled.Quiz
import androidx.compose.material.icons.filled.School
import androidx.compose.material.icons.filled.Shield
import androidx.compose.material3.Icon
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.dig.kashkool.core.l10n.AppLanguage
import com.dig.kashkool.core.l10n.AppStrings
import com.dig.kashkool.core.utils.EgyptValidators
import com.dig.kashkool.data.local.LedgerKind
import com.dig.kashkool.data.local.UserRole
import com.dig.kashkool.ui.components.FloatingGlassCard
import com.dig.kashkool.ui.components.NeonButton
import com.dig.kashkool.ui.components.ShimmerSkeletonCard
import com.dig.kashkool.ui.components.StatusPill
import com.dig.kashkool.ui.components.StudentQrPassCard
import com.dig.kashkool.ui.theme.AmberDue
import com.dig.kashkool.ui.theme.ElectricBlue
import com.dig.kashkool.ui.theme.EmeraldValid
import com.dig.kashkool.ui.theme.NebulaPurple
import com.dig.kashkool.ui.theme.NeonCyan
import com.dig.kashkool.ui.theme.SolarGold
import com.dig.kashkool.ui.theme.TextPrimary
import com.dig.kashkool.ui.theme.TextSecondary
import com.dig.kashkool.ui.viewmodel.KashkoolUiState

@OptIn(ExperimentalLayoutApi::class)
@Composable
fun DashboardHomeScreen(
    state: KashkoolUiState,
    onNavigateTab: (String) -> Unit,
    onToggleStreakShield: () -> Unit = {},
    onReviewRescueItem: (String) -> Unit = {},
    onCompleteRescueItem: (String) -> Unit = {},
    onQrCodeCopied: () -> Unit = {},
) {
    val lang = state.language
    val qrCodeFromLabel = Regex("QR:([A-Za-z0-9]+)").find(state.userLabel)?.groupValues?.getOrNull(1)
    val primaryStudent = qrCodeFromLabel?.let { code ->
        state.students.firstOrNull { it.qrActivationCode.equals(code, ignoreCase = true) }
    } ?: state.students.firstOrNull { it.id == "stu-1" } ?: state.students.firstOrNull()
    val totalCollected = state.ledger
        .filter { it.kind == LedgerKind.CASH_TOPUP.key || it.kind == LedgerKind.PARTIAL_INSTALLMENT.key }
        .sumOf { it.amountPiasters }

    if (state.loading) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(20.dp),
            verticalArrangement = Arrangement.spacedBy(14.dp),
        ) {
            ShimmerSkeletonCard()
            ShimmerSkeletonCard()
            ShimmerSkeletonCard()
        }
        return
    }

    LazyColumn(
        modifier = Modifier.fillMaxSize(),
        contentPadding = PaddingValues(horizontal = 20.dp, vertical = 18.dp),
        verticalArrangement = Arrangement.spacedBy(18.dp),
    ) {
        item {
            FloatingGlassCard(
                modifier = Modifier.fillMaxWidth(),
            ) {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    Column(
                        modifier = Modifier.weight(1f),
                        verticalArrangement = Arrangement.spacedBy(4.dp),
                    ) {
                        Text(
                            text = state.userLabel,
                            style = MaterialTheme.typography.titleMedium,
                            color = TextPrimary,
                        )
                        Text(
                            text = AppStrings.t("subtitle_cosmic", lang),
                            style = MaterialTheme.typography.bodySmall,
                            color = TextSecondary,
                        )
                    }
                    StatusPill(
                        label = AppStrings.t("role_${state.activeRole.key}", lang),
                        color = NeonCyan,
                    )
                }
            }
        }

        if (primaryStudent != null && (state.activeRole == UserRole.STUDENT || state.activeRole == UserRole.PARENT)) {
            item {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(14.dp),
                ) {
                    FloatingGlassCard(
                        glowColor = EmeraldValid,
                        modifier = Modifier.weight(1f),
                    ) {
                        Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
                            Text(
                                text = AppStrings.t("wallet_balance", lang),
                                style = MaterialTheme.typography.bodySmall,
                                color = TextSecondary,
                            )
                            Text(
                                text = EgyptValidators.formatPiasters(primaryStudent.walletBalancePiasters, lang.code),
                                style = MaterialTheme.typography.titleLarge,
                                color = EmeraldValid,
                            )
                        }
                    }
                    FloatingGlassCard(
                        glowColor = SolarGold,
                        modifier = Modifier.weight(1f),
                    ) {
                        Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
                            Row(
                                verticalAlignment = Alignment.CenterVertically,
                                horizontalArrangement = Arrangement.spacedBy(4.dp),
                            ) {
                                Icon(
                                    imageVector = Icons.Default.LocalFireDepartment,
                                    contentDescription = null,
                                    tint = SolarGold,
                                    modifier = Modifier.size(16.dp),
                                )
                                Text(
                                    text = AppStrings.t("streak_days", lang),
                                    style = MaterialTheme.typography.bodySmall,
                                    color = TextSecondary,
                                )
                            }
                            Text(
                                text = "${primaryStudent.streakDays}",
                                style = MaterialTheme.typography.titleLarge,
                                color = SolarGold,
                            )
                        }
                    }
                }
            }

            item {
                FloatingGlassCard(
                    modifier = Modifier.fillMaxWidth(),
                ) {
                    Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.SpaceBetween,
                        ) {
                            Text(
                                text = AppStrings.t("student_mastery", lang),
                                style = MaterialTheme.typography.titleMedium,
                                color = TextPrimary,
                            )
                            Text(
                                text = "${primaryStudent.masteryPercent}%",
                                style = MaterialTheme.typography.titleMedium.copy(fontWeight = FontWeight.Bold),
                                color = NeonCyan,
                            )
                        }
                        LinearProgressIndicator(
                            progress = { primaryStudent.masteryPercent / 100f },
                            modifier = Modifier
                                .fillMaxWidth()
                                .height(8.dp)
                                .clip(MaterialTheme.shapes.small),
                            color = NeonCyan,
                            trackColor = Color.White.copy(alpha = 0.08f),
                        )
                    }
                }
            }

            if (state.activeRole == UserRole.STUDENT && state.activeStudentQrToken.isNotBlank()) {
                item {
                    val activeName = if (lang == AppLanguage.AR) primaryStudent.nameAr else primaryStudent.nameEn
                    StudentQrPassCard(
                        studentName = activeName,
                        liveToken = state.activeStudentQrToken,
                        secondsRemaining = state.qrSecondsRemaining,
                        cardCode = state.activeStudentCardCode,
                        cardPayload = state.activeStudentCardPayload,
                        checkedInToday = state.activeStudentCheckedInToday,
                        lang = lang,
                        onCodeCopied = onQrCodeCopied,
                    )
                }
            }
        } else {
            item {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(14.dp),
                ) {
                    FloatingGlassCard(
                        modifier = Modifier.weight(1f),
                    ) {
                        Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
                            Text(
                                text = AppStrings.t("attendance", lang),
                                style = MaterialTheme.typography.bodySmall,
                                color = TextSecondary,
                            )
                            Text(
                                text = "${state.attendance.size}",
                                style = MaterialTheme.typography.headlineSmall,
                                color = NeonCyan,
                            )
                        }
                    }
                    FloatingGlassCard(
                        glowColor = SolarGold,
                        modifier = Modifier.weight(1f),
                    ) {
                        Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
                            Text(
                                text = AppStrings.t("treasury_today", lang),
                                style = MaterialTheme.typography.bodySmall,
                                color = TextSecondary,
                            )
                            Text(
                                text = EgyptValidators.formatPiasters(totalCollected, lang.code),
                                style = MaterialTheme.typography.titleLarge,
                                color = SolarGold,
                            )
                        }
                    }
                }
            }
        }

        if (state.activeRole == UserRole.STUDENT) {
            if (state.rescueItems.isNotEmpty()) {
                item {
                    FloatingGlassCard(
                        glowColor = AmberDue,
                        modifier = Modifier.fillMaxWidth(),
                    ) {
                        Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
                            Text(
                                text = AppStrings.t("student_rescue_title", lang),
                                style = MaterialTheme.typography.titleMedium,
                                color = SolarGold,
                            )
                            state.rescueItems.forEach { item ->
                                val topic = if (lang == AppLanguage.AR) item.topicAr else item.topicEn
                                val hint = if (lang == AppLanguage.AR) item.hintAr else item.hintEn
                                Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
                                    Row(
                                        modifier = Modifier.fillMaxWidth(),
                                        horizontalArrangement = Arrangement.SpaceBetween,
                                        verticalAlignment = Alignment.CenterVertically,
                                    ) {
                                        Text(
                                            text = topic,
                                            style = MaterialTheme.typography.titleSmall,
                                            color = TextPrimary,
                                        )
                                        StatusPill(label = "+${item.boostPercent}%", color = EmeraldValid)
                                    }
                                    Text(
                                        text = hint,
                                        style = MaterialTheme.typography.bodySmall,
                                        color = TextSecondary,
                                    )
                                    Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                                        NeonButton(
                                            text = AppStrings.t("student_rescue_cta", lang),
                                            accentColor = NeonCyan,
                                            onClick = { onReviewRescueItem(topic) },
                                            modifier = Modifier
                                                .weight(1f)
                                                .testTag("rescue_review_${item.id}"),
                                        )
                                        OutlinedButton(
                                            onClick = { onCompleteRescueItem(item.id) },
                                            modifier = Modifier
                                                .weight(1f)
                                                .testTag("rescue_done_${item.id}"),
                                        ) {
                                            Icon(
                                                imageVector = Icons.Default.CheckCircle,
                                                contentDescription = null,
                                                tint = EmeraldValid,
                                                modifier = Modifier.size(16.dp),
                                            )
                                            Text(AppStrings.t("student_rescue_done", lang), color = EmeraldValid)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            item {
                FloatingGlassCard(
                    glowColor = if (state.streakShieldActive) EmeraldValid else NebulaPurple,
                    modifier = Modifier.fillMaxWidth(),
                ) {
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically,
                    ) {
                        Row(
                            modifier = Modifier.weight(1f),
                            verticalAlignment = Alignment.CenterVertically,
                            horizontalArrangement = Arrangement.spacedBy(10.dp),
                        ) {
                            Icon(
                                imageVector = Icons.Default.Shield,
                                contentDescription = AppStrings.t("streak_shield_title", lang),
                                tint = if (state.streakShieldActive) EmeraldValid else SolarGold,
                            )
                            Column(verticalArrangement = Arrangement.spacedBy(2.dp)) {
                                Text(
                                    text = AppStrings.t("streak_shield_title", lang),
                                    style = MaterialTheme.typography.titleSmall,
                                    color = TextPrimary,
                                )
                                Text(
                                    text = AppStrings.t("streak_shield_desc", lang),
                                    style = MaterialTheme.typography.bodySmall,
                                    color = TextSecondary,
                                )
                            }
                        }
                        OutlinedButton(
                            onClick = onToggleStreakShield,
                            modifier = Modifier.testTag("streak_shield_toggle"),
                        ) {
                            Text(
                                text = AppStrings.t(
                                    if (state.streakShieldActive) "streak_shield_active" else "streak_shield_ready",
                                    lang,
                                ),
                                color = if (state.streakShieldActive) EmeraldValid else NeonCyan,
                                style = MaterialTheme.typography.labelMedium,
                            )
                        }
                    }
                }
            }
        }

        item {
            Spacer(modifier = Modifier.height(2.dp))
            Text(
                text = AppStrings.t("quick_actions", lang),
                style = MaterialTheme.typography.titleMedium,
                color = TextPrimary,
            )
        }

        item {
            val actions = buildQuickActions(state.activeRole)
            FlowRow(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(12.dp),
                verticalArrangement = Arrangement.spacedBy(12.dp),
                maxItemsInEachRow = 2,
            ) {
                actions.forEach { action ->
                    QuickActionTile(
                        title = AppStrings.t(action.labelKey, lang),
                        icon = action.icon,
                        accent = action.accent,
                        testTag = "quick_action_${action.tabId}",
                        onClick = { onNavigateTab(action.tabId) },
                        modifier = Modifier.weight(1f),
                    )
                }
            }
        }
    }
}

private data class QuickActionItem(
    val labelKey: String,
    val icon: ImageVector,
    val tabId: String,
    val accent: Color,
)

private fun buildQuickActions(role: UserRole): List<QuickActionItem> {
    return when (role) {
        UserRole.SECRETARY -> listOf(
            QuickActionItem("open_desk", Icons.Default.PointOfSale, "desk", NeonCyan),
            QuickActionItem("open_attendance_dashboard", Icons.Default.Insights, "analytics", ElectricBlue),
            QuickActionItem("open_settlement", Icons.Default.Payments, "teacher", SolarGold),
            QuickActionItem("open_checkout", Icons.Default.AccountBalanceWallet, "wallet", EmeraldValid),
        )
        UserRole.TEACHER -> listOf(
            QuickActionItem("open_attendance_dashboard", Icons.Default.Insights, "analytics", NeonCyan),
            QuickActionItem("open_settlement", Icons.Default.Payments, "teacher", SolarGold),
            QuickActionItem("open_desk", Icons.Default.PointOfSale, "desk", ElectricBlue),
            QuickActionItem("open_assistant", Icons.Default.AutoStories, "assistant", NebulaPurple),
        )
        UserRole.PARENT -> listOf(
            QuickActionItem("open_parent", Icons.Default.FamilyRestroom, "parent", NeonCyan),
            QuickActionItem("open_checkout", Icons.Default.AccountBalanceWallet, "wallet", EmeraldValid),
            QuickActionItem("open_courses", Icons.Default.School, "courses", ElectricBlue),
            QuickActionItem("open_assistant", Icons.Default.AutoStories, "assistant", SolarGold),
        )
        UserRole.STUDENT -> listOf(
            QuickActionItem("open_courses", Icons.Default.School, "courses", NeonCyan),
            QuickActionItem("open_quiz", Icons.Default.Quiz, "courses", SolarGold),
            QuickActionItem("open_assistant", Icons.Default.AutoStories, "assistant", NebulaPurple),
            QuickActionItem("open_checkout", Icons.Default.AccountBalanceWallet, "wallet", EmeraldValid),
        )
    }
}

@Composable
private fun QuickActionTile(
    title: String,
    icon: ImageVector,
    accent: Color,
    testTag: String,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
) {
    FloatingGlassCard(
        glowColor = accent,
        onClick = onClick,
        modifier = modifier.testTag(testTag),
    ) {
        Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
            Icon(
                imageVector = icon,
                contentDescription = title,
                tint = accent,
                modifier = Modifier.size(24.dp),
            )
            Text(
                text = title,
                style = MaterialTheme.typography.titleSmall,
                color = TextPrimary,
            )
        }
    }
}
