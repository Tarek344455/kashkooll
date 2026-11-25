import React, { useState } from "react";
import {
  AlertTriangle,
  ArrowRight,
  BarChart3,
  Briefcase,
  CheckCircle2,
  Crown,
  Layers,
  Plus,
  Receipt,
  Settings,
  Users,
  XCircle,
} from "lucide-react";
import { useKashkool } from "../context/KashkoolContext";
import { EgyptValidators } from "../core/utils/egyptValidators";
import {
  AppDestination,
  AppLanguage,
  AvailabilityStatus,
  CenterPlanTier,
  PaymentSubmissionEntity,
  ResourceType,
  SubmissionStatus,
} from "../types/kashkool";
import { CosmicButton, CosmicCard, EmptyState, ModalDialog, StatusBadge } from "../components/CosmicUi";
import { AttendanceTrendAreaChart } from "../components/AttendanceCharts";
import { PerformanceEvaluationCard } from "../components/PerformanceEvaluationCard";
import { TeacherLessonPlanCard } from "../components/AiToolkitCards";

export const TeacherOpsScreen: React.FC<{ onNavigate: (dest: AppDestination) => void }> = ({
  onNavigate,
}) => {
  const {
    language,
    groups,
    allChannels,
    submissions,
    resources,
    centerPlans,
    activeCenterPlanId,
    settlementSplitPercent,
    assistantWagesPiasters,
    operatingReport,
    attendanceDashboard,
    executeOrSeatRebalance,
    updateSettlementControls,
    executeDailySettlement,
    createGroup,
    addResource,
    cycleResourceStatus,
    approveSubmission,
    rejectSubmission,
    addPaymentChannel,
    toggleChannelActive,
    submitCenterPlanUpgrade,
    tr,
  } = useKashkool();

  const isAr = language === AppLanguage.AR;
  const [subTab, setSubTab] = useState<"overview" | "finances" | "receipts">("overview");
  const [chartDayIdx, setChartDayIdx] = useState<number | null>(null);

  // Modals
  const [settleOpen, setSettleOpen] = useState(false);
  const [addGroupOpen, setAddGroupOpen] = useState(false);
  const [gName, setGName] = useState("");
  const [gSchedule, setGSchedule] = useState("");
  const [gCapacity, setGCapacity] = useState("40");
  const [gPrice, setGPrice] = useState("85");

  const [addResOpen, setAddResOpen] = useState(false);
  const [rName, setRName] = useState("");
  const [rType, setRType] = useState<ResourceType>(ResourceType.TOOL);
  const [rCost, setRCost] = useState("150");

  const [rejectTarget, setRejectTarget] = useState<PaymentSubmissionEntity | null>(null);
  const [rejectReason, setRejectReason] = useState("");

  const [addChannelOpen, setAddChannelOpen] = useState(false);
  const [chName, setChName] = useState("");
  const [chType, setChType] = useState("vodafone_cash");
  const [chRef, setChRef] = useState("");
  const [chFee, setChFee] = useState("0");

  const [planOpen, setPlanOpen] = useState(false);
  const [selectedPlan, setSelectedPlan] = useState<CenterPlanTier | null>(null);
  const [planSenderRef, setPlanSenderRef] = useState("");

  const fin = operatingReport.financialCertainty;
  const alloc = operatingReport.groupAllocation;
  const resReport = operatingReport.resourceConflict;
  const pendingSubs = submissions.filter((s) => s.status === SubmissionStatus.PENDING);
  const activePlan = centerPlans.find((p) => p.id === activeCenterPlanId) ?? centerPlans[1] ?? centerPlans[0];

  const availabilityLabel = (status: AvailabilityStatus) => {
    switch (status) {
      case AvailabilityStatus.AVAILABLE:
        return tr("res_available");
      case AvailabilityStatus.IN_USE:
        return tr("res_in_use");
      case AvailabilityStatus.RESERVED:
        return tr("res_reserved");
      case AvailabilityStatus.UNAVAILABLE:
        return tr("res_unavailable");
    }
  };

  return (
    <div className="space-y-4">
      {/* Sub-Tabs */}
      <div className="grid grid-cols-3 gap-2">
        {(
          [
            { id: "overview", key: "teacher_tab_overview" },
            { id: "finances", key: "teacher_tab_finances" },
            { id: "receipts", key: "teacher_tab_receipts" },
          ] as const
        ).map((tab) => (
          <button
            key={tab.id}
            type="button"
            onClick={() => setSubTab(tab.id)}
            className={`rounded-xl border px-3 py-2.5 text-xs sm:text-sm font-bold transition-colors cursor-pointer ${
              subTab === tab.id
                ? "bg-[#EAB308]/18 border-[#EAB308]/60 text-[#EAB308]"
                : "bg-[#141D2F] border-white/10 text-[#94A3B8] hover:text-[#F1F5F9]"
            }`}
          >
            {tr(tab.key)}
            {tab.id === "receipts" && pendingSubs.length > 0 && (
              <span className="ms-1.5 inline-flex items-center justify-center rounded-full bg-[#FBBF24] text-[#0A0F1C] px-1.5 text-[10px] font-extrabold tabular-nums">
                {pendingSubs.length}
              </span>
            )}
          </button>
        ))}
      </div>

      {/* TAB 1: OVERVIEW */}
      {subTab === "overview" && (
        <div className="space-y-4">
          <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
            <CosmicCard tone="emerald" className="space-y-1">
              <p className="text-xs text-[#94A3B8]">{tr("teacher_impact_title")}</p>
              <p className="text-2xl font-extrabold text-[#34D399] tabular-nums">
                {fin.attendedCount} {tr("attendance")}
              </p>
              <p className="text-xs text-[#94A3B8] tabular-nums">
                {tr("or_projected_weekly")}:{" "}
                {EgyptValidators.formatPiasters(fin.projectedWeeklyGrossPiasters, language)}
              </p>
            </CosmicCard>

            <CosmicCard tone="amber" className="space-y-1">
              <p className="text-xs text-[#94A3B8]">{tr("teacher_dues_title")}</p>
              <p className="text-2xl font-extrabold text-[#FBBF24] tabular-nums">
                {EgyptValidators.formatPiasters(fin.pendingDuesPiasters, language)}
              </p>
              <p className="text-xs text-[#94A3B8] tabular-nums">
                {tr("or_collection_eff")}: {fin.collectionEfficiencyPercent}%
              </p>
            </CosmicCard>

            <CosmicCard tone="gold" className="space-y-1">
              <p className="text-xs text-[#94A3B8]">{tr("net_payout")}</p>
              <p className="text-2xl font-extrabold text-[#EAB308] tabular-nums">
                {EgyptValidators.formatPiasters(fin.netPayoutPiasters, language)}
              </p>
              <p className="text-xs text-[#94A3B8] tabular-nums">
                {tr("os_certainty_index")}: {operatingReport.certaintyScorePercent}%
              </p>
            </CosmicCard>
          </div>

          {/* Mini Attendance Chart Card */}
          <CosmicCard tone="cyan" className="space-y-3">
            <div className="flex flex-wrap items-center justify-between gap-2">
              <div className="flex items-center gap-2">
                <BarChart3 className="w-4 h-4 text-[#38BDF8]" />
                <h3 className="text-sm font-bold text-[#F1F5F9]">{tr("att_dash_title")}</h3>
              </div>
              <CosmicButton
                type="button"
                tone="cyan"
                variant="subtle"
                className="text-xs py-1.5 px-3"
                icon={<ArrowRight className="w-3.5 h-3.5" />}
                onClick={() => onNavigate("analytics")}
              >
                {tr("att_open_full_dash")}
              </CosmicButton>
            </div>
            <AttendanceTrendAreaChart
              points={attendanceDashboard.dailyPoints}
              selectedIndex={chartDayIdx}
              onSelectIndex={setChartDayIdx}
            />
          </CosmicCard>

          <PerformanceEvaluationCard mode="TEACHER_CONSOLE" />
          <TeacherLessonPlanCard groups={groups} />
        </div>
      )}

      {/* TAB 2: GROUPS & ACCOUNTS */}
      {subTab === "finances" && (
        <div className="space-y-4">
          {/* OR Seat Rebalance Banner */}
          {(alloc.transferPlans.length > 0 || alloc.recommendedSeatShift > 0) && (
            <CosmicCard tone="amber" className="space-y-2.5">
              <div className="flex flex-wrap items-center justify-between gap-2">
                <div>
                  <p className="text-sm font-bold text-[#FBBF24]">{tr("or_pillar_capacity")}</p>
                  <p className="text-xs text-[#F1F5F9]">
                    {alloc.bottleneckGroupAr && alloc.slackGroupAr
                      ? isAr
                        ? `نقل ${alloc.recommendedSeatShift} طلاب من "${alloc.bottleneckGroupAr}" إلى "${alloc.slackGroupAr}"`
                        : `Shift ${alloc.recommendedSeatShift} seats from "${alloc.bottleneckGroupEn}" to "${alloc.slackGroupEn}"`
                      : ""}
                  </p>
                </div>
                <CosmicButton
                  type="button"
                  tone="amber"
                  onClick={executeOrSeatRebalance}
                  className="text-xs"
                >
                  {tr("or_rebalance_cta")}
                </CosmicButton>
              </div>
            </CosmicCard>
          )}

          {/* Net Teacher Payout + Settlement Controls */}
          <CosmicCard tone="gold" className="space-y-4">
            <div className="flex flex-wrap items-center justify-between gap-2">
              <div>
                <h3 className="text-base font-extrabold text-[#F1F5F9]">{tr("net_payout")}</h3>
                <p className="text-xs text-[#94A3B8]">{tr("settlement_formula")}</p>
              </div>
              <p className="text-2xl font-extrabold text-[#EAB308] tabular-nums">
                {EgyptValidators.formatPiasters(fin.netPayoutPiasters, language)}
              </p>
            </div>

            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
              <div className="space-y-1.5">
                <div className="flex justify-between text-xs">
                  <span className="text-[#94A3B8]">{tr("split_percent_label")}</span>
                  <span className="font-bold text-[#38BDF8] tabular-nums">{settlementSplitPercent}%</span>
                </div>
                <input
                  type="range"
                  min={5}
                  max={45}
                  value={settlementSplitPercent}
                  onChange={(e) =>
                    updateSettlementControls(
                      Number(e.target.value),
                      Math.round(assistantWagesPiasters / 100)
                    )
                  }
                  className="w-full accent-[#38BDF8] cursor-pointer"
                />
              </div>

              <div className="space-y-1.5">
                <div className="flex justify-between text-xs">
                  <span className="text-[#94A3B8]">{tr("assistant_wages_label")}</span>
                  <span className="font-bold text-[#38BDF8] tabular-nums">
                    {EgyptValidators.formatPiasters(assistantWagesPiasters, language)}
                  </span>
                </div>
                <input
                  type="range"
                  min={0}
                  max={500}
                  step={25}
                  value={Math.round(assistantWagesPiasters / 100)}
                  onChange={(e) =>
                    updateSettlementControls(settlementSplitPercent, Number(e.target.value))
                  }
                  className="w-full accent-[#38BDF8] cursor-pointer"
                />
              </div>
            </div>

            <div className="grid grid-cols-2 sm:grid-cols-4 gap-2 text-xs">
              <div className="rounded-xl bg-[#0A0F1C]/70 p-2.5">
                <p className="text-[#94A3B8]">{tr("treasury_today")}</p>
                <p className="font-bold text-[#34D399] tabular-nums">
                  {EgyptValidators.formatPiasters(fin.grossPiasters, language)}
                </p>
              </div>
              <div className="rounded-xl bg-[#0A0F1C]/70 p-2.5">
                <p className="text-[#94A3B8]">{tr("or_breakeven_title")}</p>
                <p className="font-bold text-[#F1F5F9] tabular-nums">
                  {fin.breakEvenAttendance} ({fin.marginOfSafetyPercent}%)
                </p>
              </div>
              <div className="rounded-xl bg-[#0A0F1C]/70 p-2.5">
                <p className="text-[#94A3B8]">{tr("or_collection_eff")}</p>
                <p className="font-bold text-[#38BDF8] tabular-nums">{fin.collectionEfficiencyPercent}%</p>
              </div>
              <div className="rounded-xl bg-[#0A0F1C]/70 p-2.5">
                <p className="text-[#94A3B8]">{tr("drawer_void_total")}</p>
                <p className={`font-bold tabular-nums ${fin.anomalyDetected ? "text-[#F87171]" : "text-[#94A3B8]"}`}>
                  {fin.voidRatioPercent}%
                </p>
              </div>
            </div>

            {fin.anomalyDetected && (
              <div className="flex items-center gap-2 rounded-xl bg-[#F87171]/12 border border-[#F87171]/35 px-3 py-2 text-xs text-[#F87171]">
                <AlertTriangle className="w-4 h-4 shrink-0" />
                <span>{tr("or_void_anomaly")}</span>
              </div>
            )}

            <CosmicButton type="button" tone="gold" className="w-full" onClick={() => setSettleOpen(true)}>
              {tr("run_settlement")}
            </CosmicButton>
          </CosmicCard>

          {/* Groups & Halls */}
          <CosmicCard tone="cyan" className="space-y-3">
            <div className="flex items-center justify-between gap-2">
              <div className="flex items-center gap-2">
                <Users className="w-4 h-4 text-[#38BDF8]" />
                <h3 className="text-sm font-bold text-[#F1F5F9]">{tr("groups_title")}</h3>
              </div>
              <CosmicButton
                type="button"
                tone="cyan"
                variant="subtle"
                className="text-xs py-1.5 px-3"
                icon={<Plus className="w-3.5 h-3.5" />}
                onClick={() => setAddGroupOpen(true)}
              >
                {tr("add_group")}
              </CosmicButton>
            </div>

            {groups.length === 0 ? (
              <EmptyState icon={<Users className="w-8 h-8" />} message={tr("empty_groups")} />
            ) : (
              <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
                {groups.map((g) => {
                  const pct = g.capacity > 0 ? Math.round((g.enrolled / g.capacity) * 100) : 0;
                  return (
                    <div
                      key={g.id}
                      className="rounded-xl bg-[#0A0F1C]/65 border border-white/10 p-3 space-y-2"
                    >
                      <div className="flex items-start justify-between gap-2">
                        <div>
                          <p className="text-sm font-bold text-[#F1F5F9]">
                            {isAr ? g.nameAr : g.nameEn}
                          </p>
                          <p className="text-xs text-[#94A3B8]">{isAr ? g.scheduleAr : g.scheduleEn}</p>
                        </div>
                        <StatusBadge
                          tone={pct >= 90 ? "amber" : "emerald"}
                          label={`${g.enrolled}/${g.capacity}`}
                        />
                      </div>
                      <div className="flex items-center justify-between text-xs text-[#94A3B8]">
                        <span>{isAr ? g.subjectAr : g.subjectEn}</span>
                        <span className="font-bold text-[#34D399] tabular-nums">
                          {EgyptValidators.formatPiasters(g.pricePerSessionPiasters, language)}
                        </span>
                      </div>
                    </div>
                  );
                })}
              </div>
            )}
          </CosmicCard>

          {/* Resources */}
          <CosmicCard tone={resReport.hasHallOrScheduleConflict ? "amber" : "slate"} className="space-y-3">
            <div className="flex flex-wrap items-center justify-between gap-2">
              <div className="flex items-center gap-2">
                <Layers className="w-4 h-4 text-[#A78BFA]" />
                <h3 className="text-sm font-bold text-[#F1F5F9]">{tr("resources_title")}</h3>
              </div>
              <div className="flex items-center gap-2">
                <StatusBadge
                  tone={resReport.hasHallOrScheduleConflict ? "amber" : "emerald"}
                  label={
                    resReport.hasHallOrScheduleConflict
                      ? tr("hall_conflict_alert")
                      : tr("hall_clear_badge")
                  }
                />
                <CosmicButton
                  type="button"
                  tone="purple"
                  variant="subtle"
                  className="text-xs py-1.5 px-3"
                  icon={<Plus className="w-3.5 h-3.5" />}
                  onClick={() => setAddResOpen(true)}
                >
                  {tr("add_resource")}
                </CosmicButton>
              </div>
            </div>

            <p className="text-xs text-[#94A3B8]">
              {isAr ? resReport.summaryAr : resReport.summaryEn}
            </p>

            <div className="space-y-2">
              {resources.map((res) => (
                <div
                  key={res.id}
                  className="flex flex-wrap items-center justify-between gap-2 rounded-xl bg-[#0A0F1C]/65 border border-white/10 px-3 py-2.5 text-xs"
                >
                  <div>
                    <p className="font-bold text-[#F1F5F9]">{res.name}</p>
                    <p className="text-[#94A3B8] tabular-nums">
                      {EgyptValidators.formatPiasters(res.costPiasters, language)}
                    </p>
                  </div>
                  <button
                    type="button"
                    onClick={() => cycleResourceStatus(res)}
                    className="rounded-lg border border-white/15 bg-white/5 px-2.5 py-1 text-xs font-semibold text-[#38BDF8] hover:bg-white/10 cursor-pointer"
                  >
                    {availabilityLabel(res.availabilityStatus)}
                  </button>
                </div>
              ))}
            </div>
          </CosmicCard>
        </div>
      )}

      {/* TAB 3: RECEIPTS, CHANNELS & PLANS */}
      {subTab === "receipts" && (
        <div className="space-y-4">
          {/* Pending Receipts Review Queue */}
          <CosmicCard tone="amber" className="space-y-3">
            <div className="flex items-center gap-2">
              <Receipt className="w-4 h-4 text-[#FBBF24]" />
              <h3 className="text-sm font-bold text-[#F1F5F9]">{tr("review_queue")}</h3>
            </div>

            {pendingSubs.length === 0 ? (
              <p className="text-xs text-[#94A3B8]">{tr("no_pending_receipts")}</p>
            ) : (
              <div className="space-y-3">
                {pendingSubs.map((sub) => (
                  <div
                    key={sub.id}
                    className="rounded-xl bg-[#0A0F1C]/75 border border-white/10 p-3.5 space-y-2.5"
                  >
                    <div className="flex flex-wrap items-center justify-between gap-2">
                      <div>
                        <p className="text-sm font-bold text-[#F1F5F9]">
                          {isAr ? sub.studentNameAr : sub.studentNameEn}
                        </p>
                        <p className="text-xs text-[#94A3B8]">
                          {sub.channelName} · <span className="font-mono-tabular">{sub.senderReference}</span>
                        </p>
                      </div>
                      <span className="text-base font-extrabold text-[#34D399] tabular-nums">
                        {EgyptValidators.formatPiasters(sub.amountPiasters, language)}
                      </span>
                    </div>

                    {sub.receiptUri && (
                      <img
                        src={sub.receiptUri}
                        alt={sub.senderReference}
                        className="max-h-40 rounded-lg border border-white/15 object-contain bg-black/40"
                      />
                    )}

                    <div className="flex flex-wrap gap-2">
                      <CosmicButton
                        type="button"
                        tone="emerald"
                        className="text-xs py-1.5 px-3"
                        icon={<CheckCircle2 className="w-3.5 h-3.5" />}
                        onClick={() => approveSubmission(sub)}
                      >
                        {tr("approve")}
                      </CosmicButton>
                      <CosmicButton
                        type="button"
                        tone="crimson"
                        variant="outline"
                        className="text-xs py-1.5 px-3"
                        icon={<XCircle className="w-3.5 h-3.5" />}
                        onClick={() => {
                          setRejectTarget(sub);
                          setRejectReason("");
                        }}
                      >
                        {tr("reject")}
                      </CosmicButton>
                    </div>
                  </div>
                ))}
              </div>
            )}
          </CosmicCard>

          {/* Payment Channels */}
          <CosmicCard tone="cyan" className="space-y-3">
            <div className="flex items-center justify-between gap-2">
              <div className="flex items-center gap-2">
                <Settings className="w-4 h-4 text-[#38BDF8]" />
                <h3 className="text-sm font-bold text-[#F1F5F9]">{tr("channels_manage_title")}</h3>
              </div>
              <CosmicButton
                type="button"
                tone="cyan"
                variant="subtle"
                className="text-xs py-1.5 px-3"
                icon={<Plus className="w-3.5 h-3.5" />}
                onClick={() => setAddChannelOpen(true)}
              >
                {tr("add_channel")}
              </CosmicButton>
            </div>

            <div className="space-y-2">
              {allChannels.map((ch) => (
                <div
                  key={ch.id}
                  className="flex items-center justify-between gap-3 rounded-xl bg-[#0A0F1C]/65 border border-white/10 p-3 text-xs"
                >
                  <div className="min-w-0">
                    <p className="font-bold text-[#F1F5F9]">{isAr ? ch.nameAr : ch.nameEn}</p>
                    <p className="text-[#94A3B8] font-mono-tabular truncate" dir="ltr">
                      {ch.accountRef} ·{" "}
                      {ch.feePiasters === 0
                        ? tr("zero_fee")
                        : EgyptValidators.formatPiasters(ch.feePiasters, language)}
                    </p>
                  </div>
                  <button
                    type="button"
                    onClick={() => toggleChannelActive(ch)}
                    className={`rounded-lg border px-3 py-1.5 font-bold cursor-pointer ${
                      ch.isActive
                        ? "bg-[#34D399]/18 border-[#34D399]/50 text-[#34D399]"
                        : "bg-white/5 border-white/15 text-[#94A3B8]"
                    }`}
                  >
                    {ch.isActive ? (isAr ? "مفعّل" : "Active") : isAr ? "متوقف" : "Paused"}
                  </button>
                </div>
              ))}
            </div>
          </CosmicCard>

          {/* Center Subscription Plan */}
          <CosmicCard tone="purple" className="space-y-3">
            <div className="flex flex-wrap items-center justify-between gap-2">
              <div className="flex items-center gap-2">
                <Crown className="w-5 h-5 text-[#EAB308]" />
                <div>
                  <h3 className="text-sm font-bold text-[#F1F5F9]">{tr("center_plan_title")}</h3>
                  {activePlan && (
                    <p className="text-xs text-[#94A3B8]">
                      {isAr ? activePlan.nameAr : activePlan.nameEn} ·{" "}
                      {isAr ? activePlan.highlightAr : activePlan.highlightEn}
                    </p>
                  )}
                </div>
              </div>
              <CosmicButton
                type="button"
                tone="purple"
                variant="outline"
                className="text-xs"
                onClick={() => {
                  setSelectedPlan(activePlan ?? centerPlans[0]);
                  setPlanSenderRef("");
                  setPlanOpen(true);
                }}
              >
                {tr("upgrade_plan_cta")}
              </CosmicButton>
            </div>
          </CosmicCard>
        </div>
      )}

      {/* Settlement Confirmation Modal */}
      <ModalDialog
        open={settleOpen}
        title={tr("settlement_confirm_title")}
        onClose={() => setSettleOpen(false)}
      >
        <div className="space-y-4">
          <p className="text-sm text-[#94A3B8]">{tr("settlement_confirm_body")}</p>
          <div className="rounded-xl bg-[#0A0F1C] p-3 flex justify-between items-center">
            <span className="text-xs text-[#94A3B8]">{tr("net_payout")}</span>
            <span className="text-lg font-extrabold text-[#EAB308] tabular-nums">
              {EgyptValidators.formatPiasters(fin.netPayoutPiasters, language)}
            </span>
          </div>
          <CosmicButton
            type="button"
            tone="gold"
            className="w-full"
            icon={<Briefcase className="w-4 h-4" />}
            onClick={() => {
              executeDailySettlement(fin.netPayoutPiasters, fin.attendedCount);
              setSettleOpen(false);
            }}
          >
            {tr("submit")}
          </CosmicButton>
        </div>
      </ModalDialog>

      {/* Add Group Modal */}
      <ModalDialog open={addGroupOpen} title={tr("add_group")} onClose={() => setAddGroupOpen(false)}>
        <div className="space-y-3">
          <div>
            <label className="block text-xs text-[#94A3B8] mb-1">{tr("group_name")}</label>
            <input
              type="text"
              value={gName}
              onChange={(e) => setGName(e.target.value)}
              className="w-full rounded-xl bg-[#0A0F1C] border border-white/15 px-3 py-2 text-sm text-[#F1F5F9]"
            />
          </div>
          <div>
            <label className="block text-xs text-[#94A3B8] mb-1">{tr("group_schedule")}</label>
            <input
              type="text"
              value={gSchedule}
              onChange={(e) => setGSchedule(e.target.value)}
              className="w-full rounded-xl bg-[#0A0F1C] border border-white/15 px-3 py-2 text-sm text-[#F1F5F9]"
            />
          </div>
          <div className="grid grid-cols-2 gap-2">
            <div>
              <label className="block text-xs text-[#94A3B8] mb-1">{tr("group_capacity")}</label>
              <input
                type="number"
                value={gCapacity}
                onChange={(e) => setGCapacity(e.target.value)}
                dir="ltr"
                className="w-full rounded-xl bg-[#0A0F1C] border border-white/15 px-3 py-2 text-sm font-mono-tabular text-[#F1F5F9]"
              />
            </div>
            <div>
              <label className="block text-xs text-[#94A3B8] mb-1">{tr("group_price")}</label>
              <input
                type="number"
                value={gPrice}
                onChange={(e) => setGPrice(e.target.value)}
                dir="ltr"
                className="w-full rounded-xl bg-[#0A0F1C] border border-white/15 px-3 py-2 text-sm font-mono-tabular text-[#F1F5F9]"
              />
            </div>
          </div>
          <CosmicButton
            type="button"
            tone="cyan"
            className="w-full"
            onClick={() => {
              createGroup(gName, gSchedule, gCapacity, gPrice);
              setGName("");
              setGSchedule("");
              setAddGroupOpen(false);
            }}
          >
            {tr("submit")}
          </CosmicButton>
        </div>
      </ModalDialog>

      {/* Add Resource Modal */}
      <ModalDialog open={addResOpen} title={tr("add_resource")} onClose={() => setAddResOpen(false)}>
        <div className="space-y-3">
          <div>
            <label className="block text-xs text-[#94A3B8] mb-1">{tr("resource_name")}</label>
            <input
              type="text"
              value={rName}
              onChange={(e) => setRName(e.target.value)}
              className="w-full rounded-xl bg-[#0A0F1C] border border-white/15 px-3 py-2 text-sm text-[#F1F5F9]"
            />
          </div>
          <div className="grid grid-cols-3 gap-2">
            {[
              { t: ResourceType.HUMAN, key: "resource_human" },
              { t: ResourceType.TOOL, key: "resource_tool" },
              { t: ResourceType.FINANCIAL, key: "resource_financial" },
            ].map((opt) => (
              <button
                key={opt.t}
                type="button"
                onClick={() => setRType(opt.t)}
                className={`rounded-xl border px-2 py-2 text-xs font-bold cursor-pointer ${
                  rType === opt.t
                    ? "bg-[#A78BFA]/20 border-[#A78BFA]/60 text-[#A78BFA]"
                    : "bg-[#0A0F1C] border-white/10 text-[#94A3B8]"
                }`}
              >
                {tr(opt.key)}
              </button>
            ))}
          </div>
          <div>
            <label className="block text-xs text-[#94A3B8] mb-1">{tr("resource_cost")}</label>
            <input
              type="number"
              value={rCost}
              onChange={(e) => setRCost(e.target.value)}
              dir="ltr"
              className="w-full rounded-xl bg-[#0A0F1C] border border-white/15 px-3 py-2 text-sm font-mono-tabular text-[#F1F5F9]"
            />
          </div>
          <CosmicButton
            type="button"
            tone="purple"
            className="w-full"
            onClick={() => {
              addResource(rName, rType, rCost);
              setRName("");
              setAddResOpen(false);
            }}
          >
            {tr("submit")}
          </CosmicButton>
        </div>
      </ModalDialog>

      {/* Reject Reason Modal */}
      <ModalDialog
        open={Boolean(rejectTarget)}
        title={tr("reject_reason")}
        onClose={() => setRejectTarget(null)}
      >
        {rejectTarget && (
          <div className="space-y-3">
            <input
              type="text"
              value={rejectReason}
              onChange={(e) => setRejectReason(e.target.value)}
              placeholder={tr("reject_reason")}
              className="w-full rounded-xl bg-[#0A0F1C] border border-white/15 px-3 py-2 text-sm text-[#F1F5F9]"
            />
            <CosmicButton
              type="button"
              tone="crimson"
              className="w-full"
              onClick={() => {
                rejectSubmission(rejectTarget, rejectReason);
                setRejectTarget(null);
              }}
            >
              {tr("reject")}
            </CosmicButton>
          </div>
        )}
      </ModalDialog>

      {/* Add Payment Channel Modal */}
      <ModalDialog open={addChannelOpen} title={tr("add_channel")} onClose={() => setAddChannelOpen(false)}>
        <div className="space-y-3">
          <div>
            <label className="block text-xs text-[#94A3B8] mb-1">{tr("channel_name")}</label>
            <input
              type="text"
              value={chName}
              onChange={(e) => setChName(e.target.value)}
              className="w-full rounded-xl bg-[#0A0F1C] border border-white/15 px-3 py-2 text-sm text-[#F1F5F9]"
            />
          </div>
          <div>
            <label className="block text-xs text-[#94A3B8] mb-1">Type</label>
            <select
              value={chType}
              onChange={(e) => setChType(e.target.value)}
              className="w-full rounded-xl bg-[#0A0F1C] border border-white/15 px-3 py-2 text-sm text-[#F1F5F9]"
            >
              <option value="vodafone_cash">Vodafone Cash</option>
              <option value="instapay">InstaPay</option>
              <option value="fawry">Fawry</option>
            </select>
          </div>
          <div>
            <label className="block text-xs text-[#94A3B8] mb-1">{tr("channel_account_ref")}</label>
            <input
              type="text"
              value={chRef}
              onChange={(e) => setChRef(e.target.value)}
              dir="ltr"
              className="w-full rounded-xl bg-[#0A0F1C] border border-white/15 px-3 py-2 text-sm font-mono-tabular text-[#F1F5F9]"
            />
          </div>
          <div>
            <label className="block text-xs text-[#94A3B8] mb-1">{tr("channel_fee_egp")}</label>
            <input
              type="number"
              value={chFee}
              onChange={(e) => setChFee(e.target.value)}
              dir="ltr"
              className="w-full rounded-xl bg-[#0A0F1C] border border-white/15 px-3 py-2 text-sm font-mono-tabular text-[#F1F5F9]"
            />
          </div>
          <CosmicButton
            type="button"
            tone="cyan"
            className="w-full"
            onClick={() => {
              addPaymentChannel(chName, chType, chRef, chFee);
              setChName("");
              setChRef("");
              setAddChannelOpen(false);
            }}
          >
            {tr("submit")}
          </CosmicButton>
        </div>
      </ModalDialog>

      {/* Center Plan Upgrade Modal */}
      <ModalDialog open={planOpen} title={tr("plan_submit_title")} onClose={() => setPlanOpen(false)}>
        <div className="space-y-3">
          <div className="space-y-2">
            {centerPlans.map((pl) => {
              const active = selectedPlan?.id === pl.id;
              return (
                <button
                  key={pl.id}
                  type="button"
                  onClick={() => setSelectedPlan(pl)}
                  className={`w-full text-start rounded-xl border p-3 cursor-pointer ${
                    active
                      ? "bg-[#A78BFA]/18 border-[#A78BFA]/60"
                      : "bg-[#0A0F1C] border-white/10"
                  }`}
                >
                  <div className="flex justify-between items-center">
                    <span className="text-sm font-bold text-[#F1F5F9]">
                      {isAr ? pl.nameAr : pl.nameEn}
                    </span>
                    <span className="text-sm font-extrabold text-[#EAB308] tabular-nums">
                      {EgyptValidators.formatPiasters(pl.monthlyPiasters, language)}
                    </span>
                  </div>
                  <p className="text-xs text-[#94A3B8] mt-1">
                    {isAr ? pl.highlightAr : pl.highlightEn}
                  </p>
                </button>
              );
            })}
          </div>
          <div>
            <label className="block text-xs text-[#94A3B8] mb-1">{tr("sender_ref")}</label>
            <input
              type="text"
              value={planSenderRef}
              onChange={(e) => setPlanSenderRef(e.target.value)}
              dir="ltr"
              placeholder="TRX-994012"
              className="w-full rounded-xl bg-[#0A0F1C] border border-white/15 px-3 py-2 text-sm font-mono-tabular text-[#F1F5F9]"
            />
          </div>
          <CosmicButton
            type="button"
            tone="purple"
            className="w-full"
            disabled={!selectedPlan || !planSenderRef.trim() || allChannels.length === 0}
            onClick={() => {
              if (!selectedPlan || !allChannels[0]) return;
              submitCenterPlanUpgrade(selectedPlan, allChannels[0], planSenderRef);
              setPlanOpen(false);
            }}
          >
            {tr("submit")}
          </CosmicButton>
        </div>
      </ModalDialog>
    </div>
  );
};
