package com.dig.kashkool.core.analytics

import com.dig.kashkool.data.local.AttendanceEntity
import com.dig.kashkool.data.local.GroupEntity
import com.dig.kashkool.data.local.StudentEntity
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Date
import java.util.Locale

enum class AttendanceWindow(val days: Int, val labelKey: String) {
    DAYS_7(7, "att_window_7d"),
    DAYS_14(14, "att_window_14d"),
    DAYS_30(30, "att_window_30d"),
}

enum class AttendanceChartMode(val labelKey: String) {
    AREA_TREND("att_chart_area"),
    STACKED_BARS("att_chart_bars"),
}

data class DailyAttendancePoint(
    val dayStartMillis: Long,
    val shortLabel: String,
    val fullDateLabel: String,
    val validCount: Int,
    val dueCount: Int,
    val blockedCount: Int,
    val totalCount: Int,
    val attendanceRatePercent: Int,
)

data class GroupAttendanceSummary(
    val groupId: String,
    val nameAr: String,
    val nameEn: String,
    val checkInsInWindow: Int,
    val validCheckIns: Int,
    val enrolled: Int,
    val capacity: Int,
    val ratePercent: Int,
)

data class AttendanceDashboardSnapshot(
    val window: AttendanceWindow,
    val selectedGroupId: String?,
    val dailyPoints: List<DailyAttendancePoint>,
    val totalCheckIns: Int,
    val todayCheckIns: Int,
    val todayRatePercent: Int,
    val validCount: Int,
    val dueCount: Int,
    val blockedCount: Int,
    val validRatePercent: Int,
    val trendDeltaPercent: Int,
    val peakDayLabel: String,
    val peakDayCount: Int,
    val groupSummaries: List<GroupAttendanceSummary>,
    val recentRecords: List<AttendanceEntity>,
)

object AttendanceAnalyticsEngine {

    private const val DAY_MILLIS = 86_400_000L

    fun startOfDayMillis(timestampMillis: Long): Long {
        val cal = Calendar.getInstance()
        cal.timeInMillis = timestampMillis
        cal.set(Calendar.HOUR_OF_DAY, 0)
        cal.set(Calendar.MINUTE, 0)
        cal.set(Calendar.SECOND, 0)
        cal.set(Calendar.MILLISECOND, 0)
        return cal.timeInMillis
    }

    fun compute(
        attendance: List<AttendanceEntity>,
        groups: List<GroupEntity>,
        students: List<StudentEntity>,
        window: AttendanceWindow,
        selectedGroupId: String?,
        nowMillis: Long = System.currentTimeMillis(),
    ): AttendanceDashboardSnapshot {
        val todayStart = startOfDayMillis(nowMillis)
        val dayCount = window.days
        val windowStart = todayStart - (dayCount - 1L) * DAY_MILLIS
        val previousWindowStart = windowStart - dayCount * DAY_MILLIS

        val filteredAttendance = if (selectedGroupId.isNullOrBlank()) {
            attendance
        } else {
            attendance.filter { it.groupId == selectedGroupId }
        }

        val targetDenominator = if (selectedGroupId.isNullOrBlank()) {
            val activeStudents = students.count { !it.isBlocked }
            maxOf(activeStudents, groups.sumOf { it.enrolled }.coerceAtMost(activeStudents.coerceAtLeast(1)))
        } else {
            val groupStudents = students.count { it.groupId == selectedGroupId && !it.isBlocked }
            val enrolled = groups.firstOrNull { it.id == selectedGroupId }?.enrolled ?: 0
            maxOf(groupStudents, enrolled.coerceAtMost(maxOf(groupStudents, 1)))
        }.coerceAtLeast(1)

        val shortFmt = SimpleDateFormat("dd/MM", Locale.US)
        val fullFmt = SimpleDateFormat("EEE, dd MMM", Locale.US)

        val recordsByDay = filteredAttendance
            .filter { it.timestampMillis >= windowStart }
            .groupBy { startOfDayMillis(it.timestampMillis) }

        val dailyPoints = (0 until dayCount).map { offset ->
            val dayMillis = windowStart + offset * DAY_MILLIS
            val dayRecords = recordsByDay[dayMillis].orEmpty()
            val valid = dayRecords.count { it.feedbackStatus == "valid" }
            val due = dayRecords.count { it.feedbackStatus == "due" }
            val blocked = dayRecords.count { it.feedbackStatus == "blocked" }
            val total = dayRecords.size
            val distinctAttended = dayRecords
                .filter { it.feedbackStatus != "blocked" }
                .map { it.studentId }
                .toSet()
                .size
            val rate = ((distinctAttended * 100f) / targetDenominator).toInt().coerceIn(0, 100)
            val date = Date(dayMillis)
            DailyAttendancePoint(
                dayStartMillis = dayMillis,
                shortLabel = shortFmt.format(date),
                fullDateLabel = fullFmt.format(date),
                validCount = valid,
                dueCount = due,
                blockedCount = blocked,
                totalCount = total,
                attendanceRatePercent = rate,
            )
        }

        val currentWindowRecords = filteredAttendance.filter { it.timestampMillis >= windowStart }
        val previousWindowCount = filteredAttendance.count {
            it.timestampMillis in previousWindowStart until windowStart
        }

        val totalCheckIns = currentWindowRecords.size
        val validCount = currentWindowRecords.count { it.feedbackStatus == "valid" }
        val dueCount = currentWindowRecords.count { it.feedbackStatus == "due" }
        val blockedCount = currentWindowRecords.count { it.feedbackStatus == "blocked" }
        val validRatePercent = if (totalCheckIns > 0) {
            ((validCount * 100f) / totalCheckIns).toInt().coerceIn(0, 100)
        } else {
            0
        }

        val todayRecords = currentWindowRecords.filter { it.timestampMillis >= todayStart }
        val todayCheckIns = todayRecords.size
        val todayDistinct = todayRecords
            .filter { it.feedbackStatus != "blocked" }
            .map { it.studentId }
            .toSet()
            .size
        val todayRatePercent = ((todayDistinct * 100f) / targetDenominator).toInt().coerceIn(0, 100)

        val trendDeltaPercent = when {
            previousWindowCount == 0 && totalCheckIns > 0 -> 100
            previousWindowCount == 0 -> 0
            else -> (((totalCheckIns - previousWindowCount) * 100f) / previousWindowCount).toInt()
        }

        val peakPoint = dailyPoints.maxByOrNull { it.totalCount }
        val peakDayLabel = peakPoint?.takeIf { it.totalCount > 0 }?.shortLabel ?: "--"
        val peakDayCount = peakPoint?.totalCount ?: 0

        val allCurrentRecords = attendance.filter { it.timestampMillis >= windowStart }
        val groupSummaries = groups.map { grp ->
            val grpRecords = allCurrentRecords.filter { it.groupId == grp.id }
            val grpValid = grpRecords.count { it.feedbackStatus == "valid" }
            val expectedCap = (grp.enrolled.coerceAtLeast(1) * dayCount).coerceAtLeast(1)
            val fillRate = ((grpRecords.size * 100f) / expectedCap.coerceAtLeast(1)).toInt().coerceIn(0, 100)
            GroupAttendanceSummary(
                groupId = grp.id,
                nameAr = grp.nameAr,
                nameEn = grp.nameEn,
                checkInsInWindow = grpRecords.size,
                validCheckIns = grpValid,
                enrolled = grp.enrolled,
                capacity = grp.capacity,
                ratePercent = if (grpRecords.isEmpty()) 0 else fillRate.coerceAtLeast(
                    ((grpValid * 100f) / grpRecords.size).toInt().coerceIn(0, 100)
                ),
            )
        }

        val recentRecords = filteredAttendance
            .sortedByDescending { it.timestampMillis }
            .take(8)

        return AttendanceDashboardSnapshot(
            window = window,
            selectedGroupId = selectedGroupId,
            dailyPoints = dailyPoints,
            totalCheckIns = totalCheckIns,
            todayCheckIns = todayCheckIns,
            todayRatePercent = todayRatePercent,
            validCount = validCount,
            dueCount = dueCount,
            blockedCount = blockedCount,
            validRatePercent = validRatePercent,
            trendDeltaPercent = trendDeltaPercent,
            peakDayLabel = peakDayLabel,
            peakDayCount = peakDayCount,
            groupSummaries = groupSummaries,
            recentRecords = recentRecords,
        )
    }
}
