import React, { useState } from "react";
import { CheckCircle2, Copy, Maximize2, QrCode, RefreshCw } from "lucide-react";
import { useKashkool } from "../context/KashkoolContext";
import { AppLanguage } from "../types/kashkool";
import { copyToClipboard } from "../core/utils/browserUtils";
import { CosmicButton, CosmicCard, DynamicQrCode, ModalDialog, StatusBadge } from "./CosmicUi";

export const StudentQrPassCard: React.FC = () => {
  const {
    language,
    activeStudent,
    activeStudentQrToken,
    activeStudentCardCode,
    activeStudentCardPayload,
    activeStudentCheckedInToday,
    qrSecondsRemaining,
    notifyQrCopied,
    tr,
  } = useKashkool();

  const [useStaticCard, setUseStaticCard] = useState(false);
  const [showFullscreen, setShowFullscreen] = useState(false);

  const studentName = activeStudent
    ? language === AppLanguage.AR
      ? activeStudent.nameAr
      : activeStudent.nameEn
    : "";
  const activePayload =
    useStaticCard && activeStudentCardPayload ? activeStudentCardPayload : activeStudentQrToken;
  const codeText = useStaticCard && activeStudentCardCode ? activeStudentCardCode : activeStudentQrToken;

  return (
    <>
      <CosmicCard tone={activeStudentCheckedInToday ? "emerald" : "cyan"} className="space-y-3">
        <div className="flex flex-wrap items-center justify-between gap-2">
          <div className="flex items-center gap-2 min-w-0">
            <QrCode className="w-5 h-5 text-[#38BDF8] shrink-0" />
            <div className="min-w-0">
              <p className="text-sm font-bold text-[#F1F5F9] truncate">{tr("student_qr_pass_title")}</p>
              {studentName && <p className="text-xs text-[#94A3B8] truncate">{studentName}</p>}
            </div>
          </div>
          <StatusBadge
            tone={activeStudentCheckedInToday ? "emerald" : "cyan"}
            label={
              activeStudentCheckedInToday
                ? tr("student_qr_checked_in_today")
                : tr("student_qr_ready_scan")
            }
          />
        </div>

        <div className="flex gap-2">
          <button
            type="button"
            onClick={() => setUseStaticCard(false)}
            className={`flex-1 rounded-xl border px-3 py-2 text-xs font-semibold transition-colors cursor-pointer ${
              !useStaticCard
                ? "bg-[#38BDF8]/18 border-[#38BDF8]/50 text-[#38BDF8]"
                : "bg-white/5 border-white/10 text-[#94A3B8]"
            }`}
          >
            {tr("student_qr_live_mode")}
          </button>
          <button
            type="button"
            onClick={() => setUseStaticCard(true)}
            disabled={!activeStudentCardPayload}
            className={`flex-1 rounded-xl border px-3 py-2 text-xs font-semibold transition-colors cursor-pointer disabled:opacity-40 ${
              useStaticCard
                ? "bg-[#A78BFA]/18 border-[#A78BFA]/50 text-[#A78BFA]"
                : "bg-white/5 border-white/10 text-[#94A3B8]"
            }`}
          >
            {tr("student_qr_card_mode")}
          </button>
        </div>

        <div className="flex flex-col sm:flex-row items-center gap-4 pt-1">
          <div className="shrink-0">
            <DynamicQrCode payload={activePayload} size={140} />
          </div>
          <div className="flex-1 w-full space-y-2.5 text-start">
            {!useStaticCard ? (
              <div className="flex items-center gap-2 text-xs font-semibold text-[#38BDF8]">
                <RefreshCw className="w-3.5 h-3.5 animate-spin" style={{ animationDuration: "6s" }} />
                <span className="tabular-nums">
                  {tr("rotates_in")} {qrSecondsRemaining}s
                </span>
              </div>
            ) : (
              <div className="flex items-center gap-1.5 text-xs font-semibold text-[#A78BFA]">
                <CheckCircle2 className="w-3.5 h-3.5" />
                <span className="font-mono-tabular">{activeStudentCardCode}</span>
              </div>
            )}

            <p className="text-[11px] font-mono-tabular text-[#94A3B8] break-all bg-[#0A0F1C]/60 rounded-lg px-2.5 py-1.5 border border-white/8" dir="ltr">
              {codeText}
            </p>

            <div className="flex flex-wrap gap-2">
              <CosmicButton
                type="button"
                variant="outline"
                tone="cyan"
                className="text-xs px-3 py-1.5"
                icon={<Copy className="w-3.5 h-3.5" />}
                onClick={async () => {
                  await copyToClipboard(activePayload);
                  notifyQrCopied();
                }}
              >
                {tr("student_qr_copy_code")}
              </CosmicButton>
              <CosmicButton
                type="button"
                variant="subtle"
                tone="cyan"
                className="text-xs px-3 py-1.5"
                icon={<Maximize2 className="w-3.5 h-3.5" />}
                onClick={() => setShowFullscreen(true)}
              >
                {tr("student_qr_fullscreen_cta")}
              </CosmicButton>
            </div>
          </div>
        </div>
      </CosmicCard>

      <ModalDialog
        open={showFullscreen}
        title={tr("student_qr_pass_title")}
        onClose={() => setShowFullscreen(false)}
      >
        <div className="flex flex-col items-center gap-4 text-center py-2">
          {studentName && <p className="text-base font-bold text-[#F1F5F9]">{studentName}</p>}
          <DynamicQrCode payload={activePayload} size={230} />
          <p className="text-xs font-mono-tabular text-[#38BDF8] break-all" dir="ltr">
            {activePayload}
          </p>
          {!useStaticCard && (
            <p className="text-xs text-[#94A3B8] tabular-nums">
              {tr("rotates_in")} {qrSecondsRemaining}s
            </p>
          )}
        </div>
      </ModalDialog>
    </>
  );
};
