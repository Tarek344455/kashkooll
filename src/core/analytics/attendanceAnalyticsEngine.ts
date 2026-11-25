import {
  AttendanceDashboardSnapshot,
  AttendanceEntity,
  AttendanceWindow,
  DailyAttendancePoint,
  GroupAttendanceSummary,
  GroupEntity,
  StudentEntity,
} from "../../types/kashkool";

const DAY_MILLIS = 86_400_000;

export function startOfDayMillis(timestampMillis: number): number {
  const d = new Date(timestampMillis);
  d.setHours(0, 0, 0, 0);
  return d.getTime();
}

function formatShortDate(millis: number): string {
  const d = new Date(millis);
  const dd = String(d.getDate()).padStart(2, "0");
  const mm = String(d.getMonth() + 1).padStart(2, "0");
  return `${dd}/${mm}`;
}

function formatFullDate(millis: number): string {
  return new Date(millis).toLocaleDateString("en-US", {
    weekday: "short",
    day: "2-digit",
    month: "short",
  });
}

export const AttendanceAnalyticsEngine = {
  compute(params: {
    attendance: AttendanceEntity[];
    groups: GroupEntity[];
    students: StudentEntity[];
    window: AttendanceWindow;
    selectedGroupId: string | null;
    nowMillis?: number;
  }): AttendanceDashboardSnapshot {
    const {
      attendance,
      groups,
      students,
      window,
      selectedGroupId,
      nowMillis = Date.now(),
    } = params;

    const todayStart = startOfDayMillis(nowMillis);
    const dayCount = window;
    const windowStart = todayStart - (dayCount - 1) * DAY_MILLIS;
    const previousWindowStart = windowStart - dayCount * DAY_MILLIS;

    const filteredAttendance = !selectedGroupId
      ? attendance
      : attendance.filter((a) => a.groupId === selectedGroupId);

    const activeStudents = students.filter((s) => !s.isBlocked).length;
    const targetDenominator = Math.max(
      1,
      !selectedGroupId
        ? Math.max(
            activeStudents,
            Math.min(
              Math.max(activeStudents, 1),
              groups.reduce((s, g) => s + g.enrolled, 0)
            )
          )
        : (() => {
            const grpStu = students.filter((s) => s.groupId === selectedGroupId && !s.isBlocked).length;
            const enrolled = groups.find((g) => g.id === selectedGroupId)?.enrolled ?? 0;
            return Math.max(grpStu, Math.min(Math.max(grpStu, 1), enrolled));
          })()
    );

    const recordsByDay = new Map<number, AttendanceEntity[]>();
    for (const rec of filteredAttendance) {
      if (rec.timestampMillis >= windowStart) {
        const day = startOfDayMillis(rec.timestampMillis);
        const list = recordsByDay.get(day) ?? [];
        list.push(rec);
        recordsByDay.set(day, list);
      }
    }

    const dailyPoints: DailyAttendancePoint[] = [];
    for (let offset = 0; offset < dayCount; offset++) {
      const dayMillis = windowStart + offset * DAY_MILLIS;
      const dayRecords = recordsByDay.get(dayMillis) ?? [];
      const validCount = dayRecords.filter((r) => r.feedbackStatus === "valid").length;
      const dueCount = dayRecords.filter((r) => r.feedbackStatus === "due").length;
      const blockedCount = dayRecords.filter((r) => r.feedbackStatus === "blocked").length;
      const totalCount = dayRecords.length;
      const distinct = new Set(
        dayRecords.filter((r) => r.feedbackStatus !== "blocked").map((r) => r.studentId)
      ).size;
      const rate = Math.min(100, Math.max(0, Math.floor((distinct * 100) / targetDenominator)));

      dailyPoints.push({
        dayStartMillis: dayMillis,
        shortLabel: formatShortDate(dayMillis),
        fullDateLabel: formatFullDate(dayMillis),
        validCount,
        dueCount,
        blockedCount,
        totalCount,
        attendanceRatePercent: rate,
      });
    }

    const currentWindowRecords = filteredAttendance.filter((r) => r.timestampMillis >= windowStart);
    const previousWindowCount = filteredAttendance.filter(
      (r) => r.timestampMillis >= previousWindowStart && r.timestampMillis < windowStart
    ).length;

    const totalCheckIns = currentWindowRecords.length;
    const validCount = currentWindowRecords.filter((r) => r.feedbackStatus === "valid").length;
    const dueCount = currentWindowRecords.filter((r) => r.feedbackStatus === "due").length;
    const blockedCount = currentWindowRecords.filter((r) => r.feedbackStatus === "blocked").length;
    const validRatePercent =
      totalCheckIns > 0 ? Math.min(100, Math.max(0, Math.floor((validCount * 100) / totalCheckIns))) : 0;

    const todayRecords = currentWindowRecords.filter((r) => r.timestampMillis >= todayStart);
    const todayCheckIns = todayRecords.length;
    const todayDistinct = new Set(
      todayRecords.filter((r) => r.feedbackStatus !== "blocked").map((r) => r.studentId)
    ).size;
    const todayRatePercent = Math.min(100, Math.max(0, Math.floor((todayDistinct * 100) / targetDenominator)));

    const trendDeltaPercent =
      previousWindowCount === 0 && totalCheckIns > 0
        ? 100
        : previousWindowCount === 0
          ? 0
          : Math.floor(((totalCheckIns - previousWindowCount) * 100) / previousWindowCount);

    let peakPoint: DailyAttendancePoint | null = null;
    for (const pt of dailyPoints) {
      if (!peakPoint || pt.totalCount > peakPoint.totalCount) peakPoint = pt;
    }
    const peakDayLabel = peakPoint && peakPoint.totalCount > 0 ? peakPoint.shortLabel : "--";
    const peakDayCount = peakPoint?.totalCount ?? 0;

    const allCurrentRecords = attendance.filter((r) => r.timestampMillis >= windowStart);
    const groupSummaries: GroupAttendanceSummary[] = groups.map((grp) => {
      const grpRecords = allCurrentRecords.filter((r) => r.groupId === grp.id);
      const grpValid = grpRecords.filter((r) => r.feedbackStatus === "valid").length;
      const expectedCap = Math.max(1, Math.max(1, grp.enrolled) * dayCount);
      const fillRate = Math.min(100, Math.max(0, Math.floor((grpRecords.length * 100) / expectedCap)));
      const validShare =
        grpRecords.length === 0 ? 0 : Math.min(100, Math.max(0, Math.floor((grpValid * 100) / grpRecords.length)));

      return {
        groupId: grp.id,
        nameAr: grp.nameAr,
        nameEn: grp.nameEn,
        checkInsInWindow: grpRecords.length,
        validCheckIns: grpValid,
        enrolled: grp.enrolled,
        capacity: grp.capacity,
        ratePercent: grpRecords.length === 0 ? 0 : Math.max(fillRate, validShare),
      };
    });

    const recentRecords = [...filteredAttendance]
      .sort((a, b) => b.timestampMillis - a.timestampMillis)
      .slice(0, 8);

    return {
      window,
      selectedGroupId,
      dailyPoints,
      totalCheckIns,
      todayCheckIns,
      todayRatePercent,
      validCount,
      dueCount,
      blockedCount,
      validRatePercent,
      trendDeltaPercent,
      peakDayLabel,
      peakDayCount,
      groupSummaries,
      recentRecords,
    };
  },
};
