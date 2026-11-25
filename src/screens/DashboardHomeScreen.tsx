import React from "react";
import {
  Activity,
  BarChart3,
  BookOpen,
  Briefcase,
  CheckCircle2,
  Flame,
  HelpCircle,
  RefreshCw,
  ScanLine,
  Shield,
  ShieldCheck,
  TrendingUp,
  Users,
  Wallet,
} from "lucide-react";
import { useKashkool } from "../context/KashkoolContext";
import { EgyptValidators } from "../core/utils/egyptValidators";
import { AppDestination, AppLanguage, UserRole } from "../types/kashkool";
import { CosmicButton, CosmicCard, ShimmerCard, StatusBadge } from "../components/CosmicUi";
import { StudentQrPassCard } from "../components/StudentQrPassCard";

export const DashboardHomeScreen: React.FC<{
  onNavigate: (dest: AppDestination, opts?: { openQuizTab?: boolean; prompt?: string }) => void;
}> = ({ onNavigate }) => {
  const {
    language,
    activeRole,
    activeStudent,
    attendance,
    operatingReport,
    rescueItems,
    studyBudgetMinutes,
    streakShieldActive,
    aiBriefingState,
    updateStudyBudgetMinutes,
    completeRescueItem,
    toggleStreakShield,
    requestOperationalBriefing,
    tr,
  } = useKashkool();

  const isAr = language === AppLanguage.AR;
  const isStaff = activeRole === UserRole.SECRETARY || activeRole === UserRole.TEACHER;

  const student = activeStudent;
  const walletEgp = student ? EgyptValidators.formatPiasters(student.walletBalancePiasters, language) : "0";
  const todayCount = attendance.filter((a) => a.feedbackStatus !== "blocked").length;
  const treasuryEgp = EgyptValidators.formatPiasters(
    operatingReport.financialCertainty.grossPiasters,
    language
  );

  const quickActions: Array<{
    titleKey: string;
    dest: AppDestination;
    icon: React.ReactNode;
    tone: "cyan" | "emerald" | "gold" | "purple";
    openQuizTab?: boolean;
  }> = (() => {
    switch (activeRole) {
      case UserRole.STUDENT:
        return [
          { titleKey: "open_courses", dest: "courses", icon: <BookOpen className="w-5 h-5" />, tone: "cyan" },
          { titleKey: "open_quiz", dest: "courses", icon: <Activity className="w-5 h-5" />, tone: "gold", openQuizTab: true },
          { titleKey: "open_assistant", dest: "assistant", icon: <HelpCircle className="w-5 h-5" />, tone: "emerald" },
          { titleKey: "open_checkout", dest: "wallet", icon: <Wallet className="w-5 h-5" />, tone: "purple" },
        ];
      case UserRole.SECRETARY:
        return [
          { titleKey: "open_desk", dest: "desk", icon: <ScanLine className="w-5 h-5" />, tone: "emerald" },
          { titleKey: "open_attendance_dashboard", dest: "analytics", icon: <BarChart3 className="w-5 h-5" />, tone: "cyan" },
          { titleKey: "open_settlement", dest: "teacher", icon: <Briefcase className="w-5 h-5" />, tone: "gold" },
          { titleKey: "open_checkout", dest: "wallet", icon: <Wallet className="w-5 h-5" />, tone: "purple" },
        ];
      case UserRole.TEACHER:
        return [
          { titleKey: "open_settlement", dest: "teacher", icon: <Briefcase className="w-5 h-5" />, tone: "gold" },
          { titleKey: "open_attendance_dashboard", dest: "analytics", icon: <BarChart3 className="w-5 h-5" />, tone: "cyan" },
          { titleKey: "open_courses", dest: "courses", icon: <BookOpen className="w-5 h-5" />, tone: "emerald" },
          { titleKey: "open_desk", dest: "desk", icon: <ScanLine className="w-5 h-5" />, tone: "purple" },
        ];
      case UserRole.PARENT:
        return [
          { titleKey: "open_parent", dest: "parent", icon: <Shield className="w-5 h-5" />, tone: "purple" },
          { titleKey: "open_checkout", dest: "wallet", icon: <Wallet className="w-5 h-5" />, tone: "emerald" },
          { titleKey: "open_courses", dest: "courses", icon: <BookOpen className="w-5 h-5" />, tone: "cyan" },
          { titleKey: "open_assistant", dest: "assistant", icon: <HelpCircle className="w-5 h-5" />, tone: "gold" },
        ];
    }
  })();

  return (
    <div className="space-y-5">
      {/* Role Hero Card */}
      <CosmicCard tone="cyan" className="bg-gradient-to-br from-[#141D2F] via-[#141D2F] to-[#1B2A44]">
        <div className="flex flex-wrap items-center justify-between gap-3">
          <div className="space-y-1">
            <p className="text-xs font-semibold text-[#38BDF8]">{tr("zero_cost_badge")}</p>
            <h1 className="text-xl sm:text-2xl font-extrabold text-[#F1F5F9]">
              {activeRole === UserRole.STUDENT || activeRole === UserRole.PARENT
                ? isAr
                  ? student?.nameAr ?? tr("welcome")
                  : student?.nameEn ?? tr("welcome")
                : tr("welcome")}
            </h1>
            <p className="text-xs text-[#94A3B8]">{tr("subtitle_cosmic")}</p>
          </div>

          <StatusBadge
            tone="emerald"
            label={`${tr("os_certainty_index")}: ${operatingReport.certaintyScorePercent}%`}
          />
        </div>
      </CosmicCard>

      {/* Role-Specific Primary KPIs */}
      {!isStaff && student ? (
        <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
          <CosmicCard tone="emerald" className="space-y-1">
            <p className="text-xs text-[#94A3B8]">{tr("wallet_balance")}</p>
            <p className="text-xl font-extrabold text-[#34D399] tabular-nums">{walletEgp}</p>
            {student.dueBalancePiasters > 0 && (
              <p className="text-xs text-[#FBBF24] tabular-nums">
                {tr("due_balance")}: {EgyptValidators.formatPiasters(student.dueBalancePiasters, language)}
              </p>
            )}
          </CosmicCard>

          <CosmicCard tone="gold" className="space-y-1">
            <p className="text-xs text-[#94A3B8]">{tr("streak_days")}</p>
            <div className="flex items-center gap-2">
              <Flame className="w-5 h-5 text-[#EAB308]" />
              <p className="text-xl font-extrabold text-[#EAB308] tabular-nums">
                {student.streakDays} {isAr ? "يوم" : "Days"}
              </p>
            </div>
          </CosmicCard>

          <CosmicCard tone="cyan" className="space-y-2">
            <div className="flex items-center justify-between text-xs">
              <span className="text-[#94A3B8]">{tr("student_mastery")}</span>
              <span className="font-bold text-[#38BDF8] tabular-nums">{student.masteryPercent}%</span>
            </div>
            <div className="h-2.5 rounded-full bg-[#0A0F1C] overflow-hidden">
              <div
                className="h-full rounded-full bg-gradient-to-r from-[#38BDF8] to-[#34D399] transition-all"
                style={{ width: `${Math.min(100, student.masteryPercent)}%` }}
              />
            </div>
          </CosmicCard>
        </div>
      ) : (
        <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
          <CosmicCard tone="emerald" className="space-y-1">
            <div className="flex items-center justify-between">
              <p className="text-xs text-[#94A3B8]">{tr("attendance")}</p>
              <Users className="w-4 h-4 text-[#34D399]" />
            </div>
            <p className="text-2xl font-extrabold text-[#34D399] tabular-nums">{todayCount}</p>
          </CosmicCard>

          <CosmicCard tone="gold" className="space-y-1">
            <div className="flex items-center justify-between">
              <p className="text-xs text-[#94A3B8]">{tr("treasury_today")}</p>
              <TrendingUp className="w-4 h-4 text-[#EAB308]" />
            </div>
            <p className="text-2xl font-extrabold text-[#EAB308] tabular-nums">{treasuryEgp}</p>
          </CosmicCard>

          <CosmicCard tone="cyan" className="space-y-1">
            <div className="flex items-center justify-between">
              <p className="text-xs text-[#94A3B8]">{tr("os_certainty_index")}</p>
              <ShieldCheck className="w-4 h-4 text-[#38BDF8]" />
            </div>
            <p className="text-2xl font-extrabold text-[#38BDF8] tabular-nums">
              {operatingReport.certaintyScorePercent}%
            </p>
          </CosmicCard>
        </div>
      )}

      {/* Student QR Pass for Student / Parent */}
      {!isStaff && <StudentQrPassCard />}

      {/* Staff Certainty & Operational Briefing Card */}
      {isStaff && (
        <CosmicCard tone="blue" className="space-y-3">
          <div className="flex flex-wrap items-center justify-between gap-2">
            <div>
              <h3 className="text-sm font-bold text-[#F1F5F9]">{tr("os_engine_title")}</h3>
              <p className="text-xs text-[#94A3B8]">{tr("os_or_verified_badge")}</p>
            </div>
            <CosmicButton
              type="button"
              tone="cyan"
              variant="subtle"
              loading={aiBriefingState.status === "loading"}
              onClick={() => void requestOperationalBriefing()}
              className="text-xs"
            >
              {tr("os_ask_ai_briefing")}
            </CosmicButton>
          </div>

          <div className="grid grid-cols-2 sm:grid-cols-5 gap-2 text-center">
            {[
              { key: "or_pillar_audit", val: operatingReport.certaintyBreakdown.auditScore },
              { key: "or_pillar_margin", val: operatingReport.certaintyBreakdown.marginScore },
              { key: "or_pillar_capacity", val: operatingReport.certaintyBreakdown.capacityScore },
              { key: "or_pillar_queue", val: operatingReport.certaintyBreakdown.queueSlaScore },
              { key: "or_pillar_resources", val: operatingReport.certaintyBreakdown.resourceScore },
            ].map((pillar) => (
              <div key={pillar.key} className="rounded-xl bg-[#0A0F1C]/65 border border-white/10 p-2">
                <p className="text-[11px] text-[#94A3B8] truncate">{tr(pillar.key)}</p>
                <p className="text-sm font-bold text-[#38BDF8] tabular-nums">{pillar.val}%</p>
              </div>
            ))}
          </div>

          {operatingReport.decisions.slice(0, 2).map((dec, i) => (
            <div
              key={i}
              className={`rounded-xl border p-3 space-y-1 ${
                dec.priorityHigh
                  ? "bg-[#FBBF24]/10 border-[#FBBF24]/30"
                  : "bg-[#0A0F1C]/60 border-white/10"
              }`}
            >
              <p className="text-xs font-bold text-[#F1F5F9]">{isAr ? dec.titleAr : dec.titleEn}</p>
              <p className="text-xs text-[#94A3B8]">{isAr ? dec.detailAr : dec.detailEn}</p>
              <p className="text-[11px] font-mono-tabular text-[#38BDF8]" dir="ltr">
                {dec.verifiedFormula}
              </p>
            </div>
          ))}

          {aiBriefingState.status === "loading" && <ShimmerCard lines={3} />}

          {aiBriefingState.status === "error" && (
            <div className="rounded-xl bg-[#F87171]/10 border border-[#F87171]/30 p-3 space-y-2">
              <p className="text-xs text-[#F87171]">
                {tr("os_ai_error_prefix")} {aiBriefingState.message}
              </p>
              <CosmicButton
                type="button"
                tone="crimson"
                variant="outline"
                className="text-xs py-1.5 px-3"
                icon={<RefreshCw className="w-3.5 h-3.5" />}
                onClick={() => void requestOperationalBriefing()}
              >
                {tr("os_ai_retry")}
              </CosmicButton>
            </div>
          )}

          {aiBriefingState.status === "success" && (
            <div className="rounded-xl bg-[#38BDF8]/10 border border-[#38BDF8]/30 p-3.5 space-y-2">
              <div className="flex items-center justify-between gap-2">
                <p className="text-xs font-bold text-[#38BDF8]">{tr("os_ai_briefing_title")}</p>
                <StatusBadge tone="emerald" label={aiBriefingState.data.confidenceStatement} />
              </div>
              <p className="text-sm font-bold text-[#F1F5F9]">{aiBriefingState.data.headline}</p>
              <p className="text-xs text-[#F1F5F9]">{aiBriefingState.data.topDecision}</p>
              <ul className="space-y-1 text-xs text-[#94A3B8] ps-4 list-disc">
                {aiBriefingState.data.nextActionSteps.map((s, idx) => (
                  <li key={idx}>{s}</li>
                ))}
              </ul>
              <p className="text-[11px] text-[#34D399]">{aiBriefingState.data.trustGuarantee}</p>
            </div>
          )}
        </CosmicCard>
      )}

      {/* Student 15-Min Rescue Plan + Streak Shield */}
      {activeRole === UserRole.STUDENT && (
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
          <CosmicCard tone="amber" className="space-y-3">
            <div className="flex flex-wrap items-center justify-between gap-2">
              <h3 className="text-sm font-bold text-[#F1F5F9]">{tr("student_rescue_title")}</h3>
              <span className="text-xs font-semibold text-[#FBBF24] tabular-nums">
                {tr("or_study_budget_label")}: {studyBudgetMinutes}m
              </span>
            </div>

            <div className="flex flex-wrap gap-1.5">
              {[10, 15, 25, 40, 60].map((m) => (
                <button
                  key={m}
                  type="button"
                  onClick={() => updateStudyBudgetMinutes(m)}
                  className={`rounded-lg border px-2.5 py-1 text-xs font-bold tabular-nums cursor-pointer ${
                    studyBudgetMinutes === m
                      ? "bg-[#FBBF24]/20 border-[#FBBF24]/60 text-[#FBBF24]"
                      : "bg-[#0A0F1C]/60 border-white/10 text-[#94A3B8]"
                  }`}
                >
                  {m}m
                </button>
              ))}
            </div>

            {rescueItems.length === 0 ? (
              <div className="flex items-center gap-2 rounded-xl bg-[#34D399]/10 border border-[#34D399]/30 p-3 text-xs text-[#34D399]">
                <CheckCircle2 className="w-4 h-4 shrink-0" />
                <span>{tr("student_rescue_empty")}</span>
              </div>
            ) : (
              <div className="space-y-2">
                {rescueItems.map((item) => (
                  <div
                    key={item.id}
                    className="rounded-xl bg-[#0A0F1C]/65 border border-white/10 p-3 space-y-2"
                  >
                    <div className="flex items-center justify-between gap-2">
                      <p className="text-xs font-bold text-[#F1F5F9]">
                        {isAr ? item.topicAr : item.topicEn}
                      </p>
                      <StatusBadge tone="emerald" label={`+${item.boostPercent}%`} />
                    </div>
                    <p className="text-xs text-[#94A3B8]">{isAr ? item.hintAr : item.hintEn}</p>
                    <div className="flex flex-wrap gap-2">
                      <CosmicButton
                        type="button"
                        tone="cyan"
                        variant="subtle"
                        className="text-xs py-1.5 px-3"
                        onClick={() =>
                          onNavigate("assistant", {
                            prompt: isAr
                              ? `ساعدني أراجع نقطة: ${item.topicAr} (${item.hintAr})`
                              : `Help me review: ${item.topicEn} (${item.hintEn})`,
                          })
                        }
                      >
                        {tr("student_rescue_cta")}
                      </CosmicButton>
                      <CosmicButton
                        type="button"
                        tone="emerald"
                        variant="outline"
                        className="text-xs py-1.5 px-3"
                        onClick={() => completeRescueItem(item.id)}
                      >
                        {tr("student_rescue_done")}
                      </CosmicButton>
                    </div>
                  </div>
                ))}
              </div>
            )}
          </CosmicCard>

          <CosmicCard tone={streakShieldActive ? "emerald" : "slate"} className="flex flex-col justify-between gap-3">
            <div className="space-y-2">
              <div className="flex items-center justify-between gap-2">
                <div className="flex items-center gap-2">
                  <Shield className={`w-5 h-5 ${streakShieldActive ? "text-[#34D399]" : "text-[#94A3B8]"}`} />
                  <h3 className="text-sm font-bold text-[#F1F5F9]">{tr("streak_shield_title")}</h3>
                </div>
                <StatusBadge
                  tone={streakShieldActive ? "emerald" : "slate"}
                  label={streakShieldActive ? tr("streak_shield_active") : tr("streak_shield_ready")}
                />
              </div>
              <p className="text-xs text-[#94A3B8] leading-relaxed">{tr("streak_shield_desc")}</p>
            </div>
            <CosmicButton
              type="button"
              tone={streakShieldActive ? "slate" : "emerald"}
              variant={streakShieldActive ? "outline" : "solid"}
              onClick={toggleStreakShield}
              className="w-full"
            >
              {streakShieldActive ? tr("streak_shield_active") : tr("streak_shield_ready")}
            </CosmicButton>
          </CosmicCard>
        </div>
      )}

      {/* Quick Access 2x2 Grid */}
      <div className="space-y-2.5">
        <h3 className="text-sm font-bold text-[#F1F5F9]">{tr("quick_actions")}</h3>
        <div className="grid grid-cols-2 lg:grid-cols-4 gap-3">
          {quickActions.map((qa) => (
            <CosmicCard
              key={qa.titleKey}
              tone={qa.tone}
              onClick={() => onNavigate(qa.dest, qa.openQuizTab ? { openQuizTab: true } : undefined)}
              className="flex flex-col items-start gap-2.5 p-4 hover:bg-[#1B263B]/80 transition-colors"
            >
              <div className="p-2 rounded-xl bg-white/8 text-[#F1F5F9]">{qa.icon}</div>
              <span className="text-sm font-bold text-[#F1F5F9]">{tr(qa.titleKey)}</span>
            </CosmicCard>
          ))}
        </div>
      </div>
    </div>
  );
};
