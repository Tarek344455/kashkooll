package com.dig.kashkool.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ShowChart
import androidx.compose.material.icons.automirrored.filled.TrendingUp
import androidx.compose.material.icons.filled.BarChart
import androidx.compose.material.icons.filled.Groups
import androidx.compose.material.icons.filled.Insights
import androidx.compose.material3.FilterChip
import androidx.compose.material3.FilterChipDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.MaterialTheme
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
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.dig.kashkool.core.analytics.AttendanceChartMode
import com.dig.kashkool.core.analytics.AttendanceWindow
import com.dig.kashkool.core.l10n.AppLanguage
import com.dig.kashkool.core.l10n.AppStrings
import com.dig.kashkool.ui.components.AttendanceStackedBarChart
import com.dig.kashkool.ui.components.AttendanceTrendAreaChart
import com.dig.kashkool.ui.components.EmptyStateCard
import com.dig.kashkool.ui.components.FloatingGlassCard
import com.dig.kashkool.ui.components.ShimmerSkeletonCard
import com.dig.kashkool.ui.components.StatusPill
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
import com.dig.kashkool.ui.viewmodel.KashkoolUiState
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

@OptIn(ExperimentalLayoutApi::class)
@Composable
fun AttendanceDashboardScreen(
    state: KashkoolUiState,
    onSelectWindow: (AttendanceWindow) -> Unit,
    onSelectChartMode: (AttendanceChartMode) -> Unit,
    onSelectGroupFilter: (String?) -> Unit,
) {
    val lang = state.language
    val snapshot = state.attendanceDashboard

    if (state.loading || snapshot == null) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            ShimmerSkeletonCard()
            ShimmerSkeletonCard()
            ShimmerSkeletonCard()
        }
        return
    }

    var selectedDayIndex by remember(snapshot.dailyPoints.size, snapshot.selectedGroupId) {
        val lastNonZero = snapshot.dailyPoints.indexOfLast { it.totalCount > 0 }
        mutableStateOf(if (lastNonZero >= 0) lastNonZero else snapshot.dailyPoints.lastIndex.takeIf { it >= 0 })
    }
    val selectedDay = selectedDayIndex?.let { snapshot.dailyPoints.getOrNull(it) }
    val timeFormatter = remember { SimpleDateFormat("dd MMM · HH:mm", Locale.US) }

    LazyColumn(
        modifier = Modifier
            .fillMaxSize()
            .testTag("attendance_dashboard_screen"),
        contentPadding = PaddingValues(horizontal = 20.dp, vertical = 18.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp),
    ) {
        // Header + Live Status
        item {
            FloatingGlassCard(modifier = Modifier.fillMaxWidth()) {
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
                                imageVector = Icons.Default.Insights,
                                contentDescription = AppStrings.t("att_dash_title", lang),
                                tint = NeonCyan,
                            )
                            Text(
                                text = AppStrings.t("att_dash_title", lang),
                                style = MaterialTheme.typography.titleLarge,
                                color = TextPrimary,
                            )
                        }
                        StatusPill(
                            label = AppStrings.t("att_room_live_badge", lang),
                            color = EmeraldValid,
                        )
                    }
                    Text(
                        text = AppStrings.t("att_dash_subtitle", lang),
                        style = MaterialTheme.typography.bodySmall,
                        color = TextSecondary,
                    )
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.spacedBy(8.dp),
                    ) {
                        AttendanceWindow.entries.forEach { window ->
                            val selected = state.attendanceWindow == window
                            FilterChip(
                                selected = selected,
                                onClick = { onSelectWindow(window) },
                                modifier = Modifier
                                    .weight(1f)
                                    .testTag("att_window_${window.name}"),
                                label = { Text(AppStrings.t(window.labelKey, lang)) },
                                colors = FilterChipDefaults.filterChipColors(
                                    selectedContainerColor = NeonCyan,
                                    selectedLabelColor = CosmicBlack,
                                ),
                            )
                        }
                    }
                    LazyRow(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                        item {
                            FilterChip(
                                selected = state.attendanceGroupFilter == null,
                                onClick = { onSelectGroupFilter(null) },
                                modifier = Modifier.testTag("att_group_filter_all"),
                                label = { Text(AppStrings.t("att_all_groups", lang)) },
                                colors = FilterChipDefaults.filterChipColors(
                                    selectedContainerColor = EmeraldValid,
                                    selectedLabelColor = CosmicBlack,
                                ),
                            )
                        }
                        items(state.groups, key = { it.id }) { grp ->
                            val label = if (lang == AppLanguage.AR) grp.nameAr else grp.nameEn
                            FilterChip(
                                selected = state.attendanceGroupFilter == grp.id,
                                onClick = { onSelectGroupFilter(grp.id) },
                                modifier = Modifier.testTag("att_group_filter_${grp.id}"),
                                label = { Text(label.take(26)) },
                                colors = FilterChipDefaults.filterChipColors(
                                    selectedContainerColor = ElectricBlue,
                                    selectedLabelColor = CosmicBlack,
                                ),
                            )
                        }
                    }
                }
            }
        }

        // KPI Grid (2x2)
        item {
            FlowRow(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(10.dp),
                verticalArrangement = Arrangement.spacedBy(10.dp),
                maxItemsInEachRow = 2,
            ) {
                AttendanceKpiCard(
                    title = AppStrings.t("att_kpi_today", lang),
                    value = "${snapshot.todayCheckIns}",
                    subtitle = "${snapshot.todayRatePercent}%",
                    accent = NeonCyan,
                    modifier = Modifier.weight(1f),
                )
                AttendanceKpiCard(
                    title = AppStrings.t("att_kpi_on_time", lang),
                    value = "${snapshot.validRatePercent}%",
                    subtitle = "${snapshot.validCount} / ${snapshot.totalCheckIns}",
                    accent = EmeraldValid,
                    modifier = Modifier.weight(1f),
                )
                val deltaPrefix = if (snapshot.trendDeltaPercent >= 0) "+" else ""
                AttendanceKpiCard(
                    title = AppStrings.t("att_kpi_window_total", lang),
                    value = "${snapshot.totalCheckIns}",
                    subtitle = "$deltaPrefix${snapshot.trendDeltaPercent}% ${AppStrings.t("att_trend_vs_prior", lang)}",
                    accent = SolarGold,
                    modifier = Modifier.weight(1f),
                )
                AttendanceKpiCard(
                    title = AppStrings.t("att_kpi_peak_day", lang),
                    value = snapshot.peakDayLabel,
                    subtitle = "${snapshot.peakDayCount} ${AppStrings.t("attendance", lang)}",
                    accent = NebulaPurple,
                    modifier = Modifier.weight(1f),
                )
            }
        }

        // Daily Attendance Trends Chart Card
        item {
            FloatingGlassCard(glowColor = ElectricBlue, modifier = Modifier.fillMaxWidth()) {
                Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.spacedBy(8.dp),
                    ) {
                        FilterChip(
                            selected = state.attendanceChartMode == AttendanceChartMode.AREA_TREND,
                            onClick = { onSelectChartMode(AttendanceChartMode.AREA_TREND) },
                            modifier = Modifier
                                .weight(1f)
                                .testTag("att_chart_mode_area"),
                            leadingIcon = { Icon(Icons.AutoMirrored.Filled.ShowChart, contentDescription = null, modifier = Modifier.size(16.dp)) },
                            label = { Text(AppStrings.t("att_chart_area", lang)) },
                            colors = FilterChipDefaults.filterChipColors(
                                selectedContainerColor = NeonCyan,
                                selectedLabelColor = CosmicBlack,
                            ),
                        )
                        FilterChip(
                            selected = state.attendanceChartMode == AttendanceChartMode.STACKED_BARS,
                            onClick = { onSelectChartMode(AttendanceChartMode.STACKED_BARS) },
                            modifier = Modifier
                                .weight(1f)
                                .testTag("att_chart_mode_bars"),
                            leadingIcon = { Icon(Icons.Default.BarChart, contentDescription = null, modifier = Modifier.size(16.dp)) },
                            label = { Text(AppStrings.t("att_chart_bars", lang)) },
                            colors = FilterChipDefaults.filterChipColors(
                                selectedContainerColor = EmeraldValid,
                                selectedLabelColor = CosmicBlack,
                            ),
                        )
                    }

                    FlowRow(
                        horizontalArrangement = Arrangement.spacedBy(12.dp),
                        verticalArrangement = Arrangement.spacedBy(4.dp),
                    ) {
                        ChartLegendDot(AppStrings.t("att_legend_total", lang), NeonCyan)
                        ChartLegendDot("${AppStrings.t("att_legend_valid", lang)} (${snapshot.validCount})", EmeraldValid)
                        ChartLegendDot("${AppStrings.t("att_legend_due", lang)} (${snapshot.dueCount})", AmberDue)
                        ChartLegendDot("${AppStrings.t("att_legend_blocked", lang)} (${snapshot.blockedCount})", CrimsonBlocked)
                    }

                    if (snapshot.totalCheckIns == 0) {
                        EmptyStateCard(
                            icon = Icons.AutoMirrored.Filled.TrendingUp,
                            message = AppStrings.t("att_empty_trend", lang),
                        )
                    } else {
                        if (state.attendanceChartMode == AttendanceChartMode.AREA_TREND) {
                            AttendanceTrendAreaChart(
                                points = snapshot.dailyPoints,
                                selectedIndex = selectedDayIndex,
                                onSelectIndex = { selectedDayIndex = it },
                            )
                        } else {
                            AttendanceStackedBarChart(
                                points = snapshot.dailyPoints,
                                selectedIndex = selectedDayIndex,
                                onSelectIndex = { selectedDayIndex = it },
                            )
                        }
                    }

                    selectedDay?.let { pt ->
                        FloatingGlassCard(
                            glowColor = NeonCyan.copy(alpha = 0.55f),
                            modifier = Modifier
                                .fillMaxWidth()
                                .testTag("att_selected_day_tooltip"),
                        ) {
                            Row(
                                modifier = Modifier.fillMaxWidth(),
                                horizontalArrangement = Arrangement.SpaceBetween,
                                verticalAlignment = Alignment.CenterVertically,
                            ) {
                                Column(verticalArrangement = Arrangement.spacedBy(2.dp)) {
                                    Text(
                                        text = pt.fullDateLabel,
                                        style = MaterialTheme.typography.titleSmall,
                                        color = TextPrimary,
                                    )
                                    Text(
                                        text = "${AppStrings.t("att_legend_valid", lang)}: ${pt.validCount} · ${AppStrings.t("att_legend_due", lang)}: ${pt.dueCount} · ${AppStrings.t("att_legend_blocked", lang)}: ${pt.blockedCount}",
                                        style = MaterialTheme.typography.bodySmall,
                                        color = TextSecondary,
                                    )
                                }
                                StatusPill(
                                    label = "${pt.totalCount} (${pt.attendanceRatePercent}%)",
                                    color = NeonCyan,
                                )
                            }
                        }
                    } ?: Text(
                        text = AppStrings.t("att_tap_day_hint", lang),
                        style = MaterialTheme.typography.bodySmall,
                        color = TextSecondary,
                    )
                }
            }
        }

        // Group Breakdown
        item {
            FloatingGlassCard(glowColor = SolarGold, modifier = Modifier.fillMaxWidth()) {
                Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                    Row(
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(8.dp),
                    ) {
                        Icon(
                            imageVector = Icons.Default.Groups,
                            contentDescription = AppStrings.t("att_group_breakdown", lang),
                            tint = SolarGold,
                        )
                        Text(
                            text = AppStrings.t("att_group_breakdown", lang),
                            style = MaterialTheme.typography.titleMedium,
                            color = TextPrimary,
                        )
                    }
                    if (snapshot.groupSummaries.isEmpty()) {
                        Text(
                            text = AppStrings.t("empty_groups", lang),
                            style = MaterialTheme.typography.bodySmall,
                            color = TextSecondary,
                        )
                    } else {
                        snapshot.groupSummaries.forEach { grp ->
                            val grpName = if (lang == AppLanguage.AR) grp.nameAr else grp.nameEn
                            Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
                                Row(
                                    modifier = Modifier.fillMaxWidth(),
                                    horizontalArrangement = Arrangement.SpaceBetween,
                                ) {
                                    Text(
                                        text = grpName,
                                        style = MaterialTheme.typography.bodyMedium,
                                        color = TextPrimary,
                                        modifier = Modifier.weight(1f),
                                    )
                                    Text(
                                        text = "${grp.checkInsInWindow} · ${grp.validCheckIns} ${AppStrings.t("att_legend_valid", lang)}",
                                        style = MaterialTheme.typography.labelMedium,
                                        color = NeonCyan,
                                    )
                                }
                                LinearProgressIndicator(
                                    progress = { (grp.ratePercent / 100f).coerceIn(0f, 1f) },
                                    modifier = Modifier
                                        .fillMaxWidth()
                                        .height(6.dp)
                                        .clip(MaterialTheme.shapes.small),
                                    color = if (grp.ratePercent >= 70) EmeraldValid else SolarGold,
                                    trackColor = Color.White.copy(alpha = 0.1f),
                                )
                            }
                        }
                    }
                }
            }
        }

        // Live Recent Room Feed
        item {
            Text(
                text = AppStrings.t("att_recent_live", lang),
                style = MaterialTheme.typography.titleMedium,
                color = TextPrimary,
            )
        }
        if (snapshot.recentRecords.isEmpty()) {
            item {
                EmptyStateCard(
                    icon = Icons.Default.Insights,
                    message = AppStrings.t("timeline_empty", lang),
                )
            }
        } else {
            items(snapshot.recentRecords, key = { it.id }) { record ->
                val studentName = if (lang == AppLanguage.AR) record.studentNameAr else record.studentNameEn
                val (badgeColor, badgeKey) = when (record.feedbackStatus) {
                    "valid" -> EmeraldValid to "scan_valid"
                    "due" -> AmberDue to "scan_due"
                    else -> CrimsonBlocked to "scan_blocked"
                }
                FloatingGlassCard(glowColor = badgeColor, modifier = Modifier.fillMaxWidth()) {
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically,
                    ) {
                        Column(modifier = Modifier.weight(1f)) {
                            Text(text = studentName, style = MaterialTheme.typography.titleSmall, color = TextPrimary)
                            Text(
                                text = timeFormatter.format(Date(record.timestampMillis)),
                                style = MaterialTheme.typography.bodySmall,
                                color = TextSecondary,
                            )
                        }
                        StatusPill(label = AppStrings.t(badgeKey, lang), color = badgeColor)
                    }
                }
            }
        }
    }
}

@Composable
private fun AttendanceKpiCard(
    title: String,
    value: String,
    subtitle: String,
    accent: Color,
    modifier: Modifier = Modifier,
) {
    FloatingGlassCard(glowColor = accent, modifier = modifier) {
        Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
            Text(text = title, style = MaterialTheme.typography.bodySmall, color = TextSecondary)
            Text(
                text = value,
                style = MaterialTheme.typography.headlineSmall.copy(fontWeight = FontWeight.Bold),
                color = accent,
            )
            Text(text = subtitle, style = MaterialTheme.typography.labelSmall, color = TextPrimary)
        }
    }
}

@Composable
private fun ChartLegendDot(label: String, color: Color) {
    Row(
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(6.dp),
    ) {
        Box(
            modifier = Modifier
                .size(8.dp)
                .clip(CircleShape)
                .background(color),
        )
        Text(text = label, style = MaterialTheme.typography.labelSmall, color = TextSecondary)
    }
}
