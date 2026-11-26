import React, { useState } from "react";
import {
  AlertCircle,
  Bell,
  CheckCircle2,
  Copy,
  Flame,
  HeartHandshake,
  Link2,
  RefreshCw,
  Share2,
  Shield,
  Wallet,
} from "lucide-react";
import { useKashkool } from "../context/KashkoolContext";
import { EgyptValidators } from "../core/utils/egyptValidators";
import { copyToClipboard, formatShortTime, shareOrCopyText } from "../core/utils/browserUtils";
import { AppDestination, AppLanguage, UserRole } from "../types/kashkool";
import { CosmicButton, CosmicCard, ShimmerCard, StatusBadge } from "../components/CosmicUi";
import { PerformanceEvaluationCard } from "../components/PerformanceEvaluationCard";
import { CommunicationHubPanel } from "../components/AcademicHubPanels";

export const ParentPortalScreen: React.FC<{ onNavigate: (dest: AppDestination) => void }> = ({
  onNavigate,
}) => {
  const {
    language,
    linkedParentStudent,
    attendance,
    parentAlerts,
    operatingReport,
    parentDigestState,
    reassurancePulseAtMillis,
    triggerParentReassurance,
    buildEncouragementMessage,
    buildParentReportShareText,
    notifyMessageCopied,
    refreshParentWeeklyDigest,
    linkChildByInviteCode,
    markParentAlertRead,
    showSnackbar,
    tr,
  } = useKashkool();

  const isAr = language === AppLanguage.AR;
  const student = linkedParentStudent;
  const profile = student ? operatingReport.studentProfiles[student.id] : undefined;
  const coveredSessions = profile?.coveredSessions ?? 3;
  const studentAttendance = student
    ? attendance.filter((a) => a.studentId === student.id).slice(0, 8)
    : [];
  const childAlerts = student ? parentAlerts.filter((al) => al.studentId === student.id) : [];

  const [inviteCodeInput, setInviteCodeInput] = useState("");
  const [linkError, setLinkError] = useState<string | null>(null);

  return (
    <div className="space-y-5">
      {/* One-Tap Child Invite Code Linker */}
      <CosmicCard tone="slate" className="space-y-2.5">
        <div className="flex flex-wrap items-center justify-between gap-2">
          <div className="flex items-center gap-2">
            <Link2 className="w-4 h-4 text-[#38BDF8]" />
            <h3 className="text-sm font-bold text-[#F1F5F9]">{tr("parent_link_title")}</h3>
          </div>
          {student?.parentInviteCode && (
            <StatusBadge tone="cyan" label={`${student.parentInviteCode}`} />
          )}
        </div>
        <div className="flex flex-wrap gap-2">
          <input
            type="text"
            dir="ltr"
            value={inviteCodeInput}
            onChange={(e) => setInviteCodeInput(e.target.value)}
            placeholder={tr("parent_link_hint")}
            className="flex-1 min-w-[200px] rounded-xl bg-[#0A0F1C] border border-white/15 px-3 py-2 text-xs font-mono-tabular text-[#F1F5F9]"
          />
          <CosmicButton
            type="button"
            tone="cyan"
            variant="outline"
            className="text-xs py-2 px-3"
            onClick={() => {
              const res = linkChildByInviteCode(inviteCodeInput);
              if (!res.ok) {
                setLinkError(res.error ?? tr("validation_required"));
                return;
              }
              setLinkError(null);
              setInviteCodeInput("");
            }}
          >
            {tr("parent_link_cta")}
          </CosmicButton>
        </div>
        {linkError && <p className="text-xs text-[#F87171]">{linkError}</p>}
      </CosmicCard>
      {/* Student Overview Card */}
      {student && (
        <CosmicCard tone="purple" className="space-y-3">
          <div className="flex flex-wrap items-center justify-between gap-2">
            <div>
              <p className="text-xs text-[#A78BFA] font-semibold">{tr("role_parent")}</p>
              <h2 className="text-xl font-extrabold text-[#F1F5F9]">
                {isAr ? student.nameAr : student.nameEn}
              </h2>
            </div>
            <StatusBadge
              tone="emerald"
              label={`${tr("streak_days")}: ${student.streakDays}`}
            />
          </div>

          <div className="space-y-1.5">
            <div className="flex justify-between text-xs">
              <span className="text-[#94A3B8]">{tr("student_mastery")}</span>
              <span className="font-bold text-[#38BDF8] tabular-nums">{student.masteryPercent}%</span>
            </div>
            <div className="h-2.5 rounded-full bg-[#0A0F1C] overflow-hidden">
              <div
                className="h-full rounded-full bg-gradient-to-r from-[#A78BFA] to-[#34D399]"
                style={{ width: `${Math.min(100, student.masteryPercent)}%` }}
              />
            </div>
          </div>

          <div className="flex flex-wrap gap-2 pt-1">
            <CosmicButton
              type="button"
              tone="emerald"
              icon={<HeartHandshake className="w-4 h-4" />}
              onClick={triggerParentReassurance}
            >
              {tr("parent_reassure_cta")}
            </CosmicButton>

            <CosmicButton
              type="button"
              tone="cyan"
              variant="outline"
              icon={<Share2 className="w-4 h-4" />}
              onClick={async () => {
                const txt = buildParentReportShareText();
                const res = await shareOrCopyText(tr("parent_digest_title"), txt);
                showSnackbar(
                  res === "copied"
                    ? isAr
                      ? "تم نسخ التقرير للمشاركة"
                      : "Report copied for sharing"
                    : isAr
                      ? "تمت مشاركة التقرير"
                      : "Report shared"
                );
              }}
            >
              {tr("share_report")}
            </CosmicButton>

            <CosmicButton
              type="button"
              tone="gold"
              variant="subtle"
              icon={<Copy className="w-4 h-4" />}
              onClick={async () => {
                await copyToClipboard(buildEncouragementMessage());
                notifyMessageCopied();
              }}
            >
              {tr("parent_cheer_cta")}
            </CosmicButton>
          </div>
          <p className="text-[11px] text-[#34D399] tabular-nums">
            <Flame className="w-3 h-3 inline me-1" />
            {tr("parent_reassure_title")} · {new Date(reassurancePulseAtMillis).toLocaleTimeString()}
          </p>
        </CosmicCard>
      )}

      {/* Low Balance Dignity Alert */}
      {coveredSessions <= 2 && (
        <CosmicCard tone="amber" className="flex flex-wrap items-center justify-between gap-3">
          <div className="flex items-start gap-2.5 flex-1 min-w-[200px]">
            <AlertCircle className="w-5 h-5 text-[#FBBF24] shrink-0 mt-0.5" />
            <p className="text-xs sm:text-sm text-[#F1F5F9] leading-relaxed">
              {tr("parent_dignity_alert")}
            </p>
          </div>
          <CosmicButton
            type="button"
            tone="amber"
            onClick={() => onNavigate("wallet")}
            icon={<Wallet className="w-4 h-4" />}
          >
            {tr("topup_now")}
          </CosmicButton>
        </CosmicCard>
      )}

      {/* Calm Weekly Summary Digest */}
      <CosmicCard tone="cyan" className="space-y-3">
        <div className="flex flex-wrap items-center justify-between gap-2">
          <div className="flex items-center gap-2">
            <Shield className="w-4 h-4 text-[#38BDF8]" />
            <h3 className="text-sm font-bold text-[#F1F5F9]">{tr("parent_digest_title")}</h3>
          </div>
          <CosmicButton
            type="button"
            tone="cyan"
            variant="subtle"
            className="text-xs py-1.5 px-3"
            loading={parentDigestState.status === "loading"}
            icon={<RefreshCw className="w-3.5 h-3.5" />}
            onClick={() => void refreshParentWeeklyDigest()}
          >
            {tr("parent_digest_refresh")}
          </CosmicButton>
        </div>

        {parentDigestState.status === "idle" && (
          <p className="text-xs text-[#F1F5F9] leading-relaxed">{tr("parent_digest_body")}</p>
        )}

        {parentDigestState.status === "loading" && (
          <div className="space-y-2">
            <p className="text-xs text-[#38BDF8]">{tr("parent_digest_loading")}</p>
            <ShimmerCard lines={3} />
          </div>
        )}

        {parentDigestState.status === "error" && (
          <p className="text-xs text-[#F87171]">
            {tr("parent_digest_error")} ({parentDigestState.message})
          </p>
        )}

        {parentDigestState.status === "success" && (
          <div className="space-y-2.5">
            <p className="text-sm font-bold text-[#34D399]">{parentDigestState.data.headline}</p>
            <p className="text-xs text-[#F1F5F9] leading-relaxed">
              {parentDigestState.data.weeklyNarrative}
            </p>
            {parentDigestState.data.homeSupportTip && (
              <div className="rounded-xl bg-[#0A0F1C]/65 border border-white/10 p-3 text-xs space-y-1">
                <p className="font-bold text-[#38BDF8]">{tr("parent_home_tip")}</p>
                <p className="text-[#94A3B8]">{parentDigestState.data.homeSupportTip}</p>
              </div>
            )}
          </div>
        )}
      </CosmicCard>

      {/* Analytical Evaluation Card */}
      <PerformanceEvaluationCard mode="PARENT_CHILD" />

      {/* Attendance Timeline & Family Wallet */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
        <CosmicCard tone="slate" className="space-y-3">
          <h3 className="text-sm font-bold text-[#F1F5F9]">{tr("attendance_timeline")}</h3>
          {studentAttendance.length === 0 ? (
            <p className="text-xs text-[#94A3B8]">{tr("timeline_empty")}</p>
          ) : (
            <div className="space-y-2">
              {studentAttendance.map((rec) => {
                const tone =
                  rec.feedbackStatus === "valid"
                    ? "emerald"
                    : rec.feedbackStatus === "due"
                      ? "amber"
                      : "crimson";
                return (
                  <div
                    key={rec.id}
                    className="flex items-center justify-between gap-2 rounded-xl bg-[#0A0F1C]/65 border border-white/10 px-3 py-2 text-xs"
                  >
                    <div className="flex items-center gap-2">
                      <CheckCircle2
                        className={`w-4 h-4 ${
                          tone === "emerald"
                            ? "text-[#34D399]"
                            : tone === "amber"
                              ? "text-[#FBBF24]"
                              : "text-[#F87171]"
                        }`}
                      />
                      <span className="text-[#94A3B8] font-mono-tabular">
                        {new Date(rec.timestampMillis).toLocaleDateString()}
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

        {student && (
          <CosmicCard tone="emerald" className="flex flex-col justify-between gap-4">
            <div className="space-y-1.5">
              <h3 className="text-sm font-bold text-[#F1F5F9]">{tr("family_wallet")}</h3>
              <p className="text-2xl font-extrabold text-[#34D399] tabular-nums">
                {EgyptValidators.formatPiasters(student.walletBalancePiasters, language)}
              </p>
              <p className="text-xs text-[#94A3B8] tabular-nums">
                {isAr
                  ? `الرصيد يكفي تقريباً لـ ${coveredSessions} حصص`
                  : `Covers ~${coveredSessions} upcoming sessions`}
              </p>
            </div>
            <CosmicButton
              type="button"
              tone="emerald"
              className="w-full"
              icon={<Wallet className="w-4 h-4" />}
              onClick={() => onNavigate("wallet")}
            >
              {tr("topup_now")}
            </CosmicButton>
          </CosmicCard>
        )}
      </div>

      {/* Instant Arrival & Exam Alerts Feed */}
      <CosmicCard tone="amber" className="space-y-3">
        <div className="flex items-center justify-between gap-2">
          <div className="flex items-center gap-2">
            <Bell className="w-4 h-4 text-[#FBBF24]" />
            <h3 className="text-sm font-bold text-[#F1F5F9]">{tr("parent_alerts_title")}</h3>
          </div>
          <StatusBadge
            tone="amber"
            label={`${childAlerts.filter((a) => !a.isRead).length}`}
          />
        </div>
        {childAlerts.length === 0 ? (
          <p className="text-xs text-[#94A3B8]">{tr("timeline_empty")}</p>
        ) : (
          <div className="space-y-2">
            {childAlerts.slice(0, 6).map((al) => (
              <div
                key={al.id}
                onClick={() => markParentAlertRead(al.id)}
                className={`rounded-xl border p-3 text-xs space-y-1 cursor-pointer transition-colors ${
                  al.isRead
                    ? "bg-[#0A0F1C]/60 border-white/10"
                    : "bg-[#FBBF24]/10 border-[#FBBF24]/35"
                }`}
              >
                <div className="flex items-center justify-between gap-2">
                  <span className="font-bold text-[#F1F5F9]">
                    {isAr ? al.titleAr : al.titleEn}
                  </span>
                  <span className="text-[11px] text-[#94A3B8] tabular-nums">
                    {formatShortTime(al.createdAtMillis, language)}
                  </span>
                </div>
                <p className="text-[#94A3B8]">{isAr ? al.bodyAr : al.bodyEn}</p>
              </div>
            ))}
          </div>
        )}
      </CosmicCard>

      {/* Center Announcements & Support Tickets */}
      <CommunicationHubPanel role={UserRole.PARENT} />
    </div>
  );
};
