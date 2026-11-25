import React, { useState } from "react";
import { BarChart3, CheckCircle2, Clock, TrendingDown, TrendingUp, Users } from "lucide-react";
import { useKashkool } from "../context/KashkoolContext";
import { AppLanguage, AttendanceChartMode, AttendanceWindow } from "../types/kashkool";
import { AttendanceStackedBarChart, AttendanceTrendAreaChart } from "../components/AttendanceCharts";
import { CosmicCard, EmptyState, StatusBadge } from "../components/CosmicUi";

export const AttendanceDashboardScreen: React.FC = () => {
  const {
    language,
    groups,
    attendanceDashboard,
    attendanceWindow,
    attendanceChartMode,
    attendanceGroupFilter,
    setAttendanceWindow,
    setAttendanceChartMode,
    setAttendanceGroupFilter,
    tr,
  } = useKashkool();

  const isAr = language === AppLanguage.AR;
  const [selectedDayIdx, setSelectedDayIdx] = useState<number | null>(null);

  const selectedPoint =
    selectedDayIdx !== null ? attendanceDashboard.dailyPoints[selectedDayIdx] ?? null : null;

  return (
    <div className="space-y-5">
      {/* Header & Live Pill */}
      <div className="flex flex-wrap items-center justify-between gap-3">
        <div>
          <h2 className="text-xl font-extrabold text-[#F1F5F9]">{tr("att_dash_title")}</h2>
          <p className="text-xs text-[#94A3B8]">{tr("att_dash_subtitle")}</p>
        </div>
        <StatusBadge tone="emerald" label={tr("att_room_live_badge")} />
      </div>

      {/* Filters: Window + Group */}
      <div className="flex flex-wrap items-center justify-between gap-3">
        <div className="flex gap-1.5">
          {[
            { win: AttendanceWindow.DAYS_7, key: "att_window_7d" },
            { win: AttendanceWindow.DAYS_14, key: "att_window_14d" },
            { win: AttendanceWindow.DAYS_30, key: "att_window_30d" },
          ].map((w) => (
            <button
              key={w.win}
              type="button"
              onClick={() => {
                setSelectedDayIdx(null);
                setAttendanceWindow(w.win);
              }}
              className={`rounded-xl border px-3 py-1.5 text-xs font-bold cursor-pointer transition-colors ${
                attendanceWindow === w.win
                  ? "bg-[#38BDF8]/18 border-[#38BDF8]/60 text-[#38BDF8]"
                  : "bg-[#141D2F] border-white/10 text-[#94A3B8]"
              }`}
            >
              {tr(w.key)}
            </button>
          ))}
        </div>

        <div className="flex flex-wrap gap-1.5">
          <button
            type="button"
            onClick={() => setAttendanceGroupFilter(null)}
            className={`rounded-xl border px-3 py-1.5 text-xs font-semibold cursor-pointer ${
              attendanceGroupFilter === null
                ? "bg-[#34D399]/18 border-[#34D399]/55 text-[#34D399]"
                : "bg-[#141D2F] border-white/10 text-[#94A3B8]"
            }`}
          >
            {tr("att_all_groups")}
          </button>
          {groups.map((g) => (
            <button
              key={g.id}
              type="button"
              onClick={() => setAttendanceGroupFilter(g.id)}
              className={`rounded-xl border px-3 py-1.5 text-xs font-semibold cursor-pointer ${
                attendanceGroupFilter === g.id
                  ? "bg-[#34D399]/18 border-[#34D399]/55 text-[#34D399]"
                  : "bg-[#141D2F] border-white/10 text-[#94A3B8]"
              }`}
            >
              {isAr ? g.nameAr : g.nameEn}
            </button>
          ))}
        </div>
      </div>

      {/* 4 KPI Cards */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-3">
        <CosmicCard tone="cyan" className="space-y-1">
          <p className="text-xs text-[#94A3B8]">{tr("att_kpi_today")}</p>
          <p className="text-2xl font-extrabold text-[#38BDF8] tabular-nums">
            {attendanceDashboard.todayCheckIns}
          </p>
          <p className="text-[11px] text-[#94A3B8] tabular-nums">{attendanceDashboard.todayRatePercent}%</p>
        </CosmicCard>

        <CosmicCard tone="emerald" className="space-y-1">
          <p className="text-xs text-[#94A3B8]">{tr("att_kpi_on_time")}</p>
          <p className="text-2xl font-extrabold text-[#34D399] tabular-nums">
            {attendanceDashboard.validRatePercent}%
          </p>
          <p className="text-[11px] text-[#94A3B8] tabular-nums">
            {attendanceDashboard.validCount} {tr("att_legend_valid")}
          </p>
        </CosmicCard>

        <CosmicCard tone="gold" className="space-y-1">
          <p className="text-xs text-[#94A3B8]">{tr("att_kpi_window_total")}</p>
          <p className="text-2xl font-extrabold text-[#EAB308] tabular-nums">
            {attendanceDashboard.totalCheckIns}
          </p>
          <p className="text-[11px] flex items-center gap-1 tabular-nums">
            {attendanceDashboard.trendDeltaPercent >= 0 ? (
              <TrendingUp className="w-3.5 h-3.5 text-[#34D399]" />
            ) : (
              <TrendingDown className="w-3.5 h-3.5 text-[#F87171]" />
            )}
            <span
              className={
                attendanceDashboard.trendDeltaPercent >= 0 ? "text-[#34D399]" : "text-[#F87171]"
              }
            >
              {attendanceDashboard.trendDeltaPercent >= 0 ? "+" : ""}
              {attendanceDashboard.trendDeltaPercent}%
            </span>
            <span className="text-[#94A3B8]">{tr("att_trend_vs_prior")}</span>
          </p>
        </CosmicCard>

        <CosmicCard tone="purple" className="space-y-1">
          <p className="text-xs text-[#94A3B8]">{tr("att_kpi_peak_day")}</p>
          <p className="text-2xl font-extrabold text-[#A78BFA] tabular-nums">
            {attendanceDashboard.peakDayCount}
          </p>
          <p className="text-[11px] text-[#94A3B8] font-mono-tabular">{attendanceDashboard.peakDayLabel}</p>
        </CosmicCard>
      </div>

      {/* Chart Card */}
      <CosmicCard tone="cyan" className="space-y-3">
        <div className="flex flex-wrap items-center justify-between gap-2">
          <div className="flex flex-wrap items-center gap-3 text-xs">
            <span className="flex items-center gap-1.5 text-[#38BDF8]">
              <span className="w-2.5 h-2.5 rounded-full bg-[#38BDF8]" />
              {tr("att_legend_total")}
            </span>
            <span className="flex items-center gap-1.5 text-[#34D399]">
              <span className="w-2.5 h-2.5 rounded-full bg-[#34D399]" />
              {tr("att_legend_valid")}
            </span>
            <span className="flex items-center gap-1.5 text-[#FBBF24]">
              <span className="w-2.5 h-2.5 rounded-full bg-[#FBBF24]" />
              {tr("att_legend_due")}
            </span>
            <span className="flex items-center gap-1.5 text-[#F87171]">
              <span className="w-2.5 h-2.5 rounded-full bg-[#F87171]" />
              {tr("att_legend_blocked")}
            </span>
          </div>

          <div className="flex gap-1.5">
            <button
              type="button"
              onClick={() => setAttendanceChartMode(AttendanceChartMode.AREA_TREND)}
              className={`rounded-lg border px-2.5 py-1 text-xs font-semibold cursor-pointer ${
                attendanceChartMode === AttendanceChartMode.AREA_TREND
                  ? "bg-[#38BDF8]/18 border-[#38BDF8]/55 text-[#38BDF8]"
                  : "bg-[#0A0F1C] border-white/10 text-[#94A3B8]"
              }`}
            >
              {tr("att_chart_area")}
            </button>
            <button
              type="button"
              onClick={() => setAttendanceChartMode(AttendanceChartMode.STACKED_BARS)}
              className={`rounded-lg border px-2.5 py-1 text-xs font-semibold cursor-pointer ${
                attendanceChartMode === AttendanceChartMode.STACKED_BARS
                  ? "bg-[#38BDF8]/18 border-[#38BDF8]/55 text-[#38BDF8]"
                  : "bg-[#0A0F1C] border-white/10 text-[#94A3B8]"
              }`}
            >
              {tr("att_chart_bars")}
            </button>
          </div>
        </div>

        {attendanceDashboard.totalCheckIns === 0 ? (
          <EmptyState icon={<BarChart3 className="w-8 h-8" />} message={tr("att_empty_trend")} />
        ) : attendanceChartMode === AttendanceChartMode.AREA_TREND ? (
          <AttendanceTrendAreaChart
            points={attendanceDashboard.dailyPoints}
            selectedIndex={selectedDayIdx}
            onSelectIndex={setSelectedDayIdx}
          />
        ) : (
          <AttendanceStackedBarChart
            points={attendanceDashboard.dailyPoints}
            selectedIndex={selectedDayIdx}
            onSelectIndex={setSelectedDayIdx}
          />
        )}

        {selectedPoint ? (
          <div className="rounded-xl bg-[#0A0F1C]/75 border border-[#38BDF8]/30 px-3.5 py-2.5 flex flex-wrap items-center justify-between gap-2 text-xs">
            <span className="font-bold text-[#F1F5F9] font-mono-tabular">{selectedPoint.fullDateLabel}</span>
            <div className="flex flex-wrap gap-3 tabular-nums">
              <span className="text-[#38BDF8]">
                {tr("att_legend_total")}: {selectedPoint.totalCount} ({selectedPoint.attendanceRatePercent}%)
              </span>
              <span className="text-[#34D399]">
                {tr("att_legend_valid")}: {selectedPoint.validCount}
              </span>
              <span className="text-[#FBBF24]">
                {tr("att_legend_due")}: {selectedPoint.dueCount}
              </span>
              <span className="text-[#F87171]">
                {tr("att_legend_blocked")}: {selectedPoint.blockedCount}
              </span>
            </div>
          </div>
        ) : (
          <p className="text-[11px] text-[#94A3B8]">{tr("att_tap_day_hint")}</p>
        )}
      </CosmicCard>

      {/* Group Breakdown + Recent Feed */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
        <CosmicCard tone="slate" className="space-y-3">
          <div className="flex items-center gap-2">
            <Users className="w-4 h-4 text-[#38BDF8]" />
            <h3 className="text-sm font-bold text-[#F1F5F9]">{tr("att_group_breakdown")}</h3>
          </div>
          <div className="space-y-2.5">
            {attendanceDashboard.groupSummaries.map((gs) => (
              <div key={gs.groupId} className="space-y-1">
                <div className="flex items-center justify-between text-xs">
                  <span className="font-semibold text-[#F1F5F9]">{isAr ? gs.nameAr : gs.nameEn}</span>
                  <span className="text-[#34D399] font-bold tabular-nums">
                    {gs.checkInsInWindow} ({gs.ratePercent}%)
                  </span>
                </div>
                <div className="h-2 rounded-full bg-[#0A0F1C] overflow-hidden">
                  <div
                    className="h-full rounded-full bg-gradient-to-r from-[#38BDF8] to-[#34D399]"
                    style={{ width: `${Math.min(100, gs.ratePercent)}%` }}
                  />
                </div>
              </div>
            ))}
          </div>
        </CosmicCard>

        <CosmicCard tone="slate" className="space-y-3">
          <div className="flex items-center gap-2">
            <Clock className="w-4 h-4 text-[#34D399]" />
            <h3 className="text-sm font-bold text-[#F1F5F9]">{tr("att_recent_live")}</h3>
          </div>
          {attendanceDashboard.recentRecords.length === 0 ? (
            <p className="text-xs text-[#94A3B8]">{tr("timeline_empty")}</p>
          ) : (
            <div className="space-y-2 max-h-72 overflow-y-auto pe-1">
              {attendanceDashboard.recentRecords.map((rec) => {
                const tone =
                  rec.feedbackStatus === "valid"
                    ? "emerald"
                    : rec.feedbackStatus === "due"
                      ? "amber"
                      : "crimson";
                return (
                  <div
                    key={rec.id}
                    className="flex items-center justify-between gap-2 rounded-xl bg-[#0A0F1C]/65 border border-white/8 px-3 py-2 text-xs"
                  >
                    <div className="flex items-center gap-2 min-w-0">
                      <CheckCircle2
                        className={`w-4 h-4 shrink-0 ${
                          tone === "emerald"
                            ? "text-[#34D399]"
                            : tone === "amber"
                              ? "text-[#FBBF24]"
                              : "text-[#F87171]"
                        }`}
                      />
                      <span className="font-semibold text-[#F1F5F9] truncate">
                        {isAr ? rec.studentNameAr : rec.studentNameEn}
                      </span>
                    </div>
                    <StatusBadge
                      tone={tone}
                      label={
                        rec.feedbackStatus === "valid"
                          ? tr("timeline_status_valid")
                          : rec.feedbackStatus === "due"
                            ? tr("timeline_status_due")
                            : tr("timeline_status_blocked")
                      }
                    />
                  </div>
                );
              })}
            </div>
          )}
        </CosmicCard>
      </div>
    </div>
  );
};
