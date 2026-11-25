import React, { useState } from "react";
import { AlertTriangle, BookOpen, CheckSquare, Copy, Layers, Share2 } from "lucide-react";
import { useKashkool } from "../context/KashkoolContext";
import { AppLanguage, GroupEntity } from "../types/kashkool";
import { copyToClipboard, shareOrCopyText } from "../core/utils/browserUtils";
import { CosmicButton, CosmicCard, ModalDialog, ShimmerCard, StatusBadge } from "./CosmicUi";

export const LessonRevisionDeckCard: React.FC<{
  lessonTitle: string;
  lessonSummary: string;
}> = ({ lessonTitle, lessonSummary }) => {
  const { revisionDeckState, generateLessonRevisionDeck, tr } = useKashkool();
  const [flippedMap, setFlippedMap] = useState<Record<number, boolean>>({});

  return (
    <CosmicCard tone="gold" className="space-y-3">
      <div className="flex flex-wrap items-center justify-between gap-2">
        <div className="flex items-center gap-2">
          <Layers className="w-4 h-4 text-[#EAB308]" />
          <span className="text-sm font-bold text-[#F1F5F9]">{tr("revision_deck_cta")}</span>
        </div>
        <CosmicButton
          type="button"
          tone="gold"
          variant="subtle"
          className="text-xs px-3 py-1.5"
          loading={revisionDeckState.status === "loading"}
          onClick={() => void generateLessonRevisionDeck(lessonTitle, lessonSummary)}
        >
          {tr("revision_deck_cta")}
        </CosmicButton>
      </div>

      {revisionDeckState.status === "loading" && (
        <div className="space-y-2">
          <p className="text-xs text-[#EAB308]">{tr("revision_deck_loading")}</p>
          <ShimmerCard lines={3} />
        </div>
      )}

      {revisionDeckState.status === "error" && (
        <p className="text-xs text-[#F87171]">
          {tr("revision_deck_error")} ({revisionDeckState.message})
        </p>
      )}

      {revisionDeckState.status === "success" && (
        <div className="space-y-3 pt-1">
          {revisionDeckState.data.memoryHook && (
            <div className="rounded-xl bg-[#EAB308]/12 border border-[#EAB308]/30 p-3 space-y-1">
              <p className="text-[11px] font-bold text-[#EAB308]">{tr("revision_deck_hook")}</p>
              <p className="text-xs text-[#F1F5F9]">{revisionDeckState.data.memoryHook}</p>
            </div>
          )}

          <div className="grid grid-cols-1 sm:grid-cols-2 gap-2.5">
            {revisionDeckState.data.flashcards.map((card, idx) => {
              const flipped = Boolean(flippedMap[idx]);
              return (
                <button
                  key={idx}
                  type="button"
                  onClick={() => setFlippedMap((m) => ({ ...m, [idx]: !flipped }))}
                  className={`text-start rounded-xl border p-3 transition-colors cursor-pointer ${
                    flipped
                      ? "bg-[#34D399]/10 border-[#34D399]/35"
                      : "bg-[#1B263B]/80 border-white/10 hover:border-[#38BDF8]/40"
                  }`}
                >
                  <p className="text-[11px] text-[#94A3B8] mb-1">{tr("revision_deck_tap_flip")}</p>
                  <p className="text-xs font-bold text-[#F1F5F9]">{card.front}</p>
                  {flipped && (
                    <p className="mt-2 pt-2 border-t border-white/10 text-xs text-[#34D399]">{card.back}</p>
                  )}
                </button>
              );
            })}
          </div>

          {revisionDeckState.data.commonTraps.length > 0 && (
            <div className="rounded-xl bg-[#F87171]/10 border border-[#F87171]/25 p-3 space-y-1.5">
              <p className="text-xs font-bold text-[#F87171] flex items-center gap-1.5">
                <AlertTriangle className="w-3.5 h-3.5" />
                {tr("revision_deck_traps")}
              </p>
              <ul className="space-y-1 text-xs text-[#F1F5F9] ps-4 list-disc">
                {revisionDeckState.data.commonTraps.map((trap, i) => (
                  <li key={i}>{trap}</li>
                ))}
              </ul>
            </div>
          )}
        </div>
      )}
    </CosmicCard>
  );
};

export const TeacherLessonPlanCard: React.FC<{ groups: GroupEntity[] }> = ({ groups }) => {
  const { language, teacherPlanState, generateTeacherLessonPlan, showSnackbar, tr } = useKashkool();
  const [selectedGroupId, setSelectedGroupId] = useState<string>(groups[0]?.id ?? "");

  const selectedGroup = groups.find((g) => g.id === selectedGroupId) ?? groups[0];

  return (
    <CosmicCard tone="blue" className="space-y-3">
      <div className="flex flex-wrap items-center justify-between gap-2">
        <div className="flex items-center gap-2">
          <BookOpen className="w-5 h-5 text-[#60A5FA]" />
          <h3 className="text-sm font-bold text-[#F1F5F9]">{tr("teacher_plan_title")}</h3>
        </div>
      </div>

      {groups.length > 0 && (
        <div className="flex flex-wrap gap-1.5">
          {groups.map((g) => {
            const label = language === AppLanguage.AR ? g.nameAr : g.nameEn;
            const active = g.id === selectedGroup?.id;
            return (
              <button
                key={g.id}
                type="button"
                onClick={() => setSelectedGroupId(g.id)}
                className={`rounded-lg border px-2.5 py-1.5 text-xs font-medium cursor-pointer transition-colors ${
                  active
                    ? "bg-[#60A5FA]/20 border-[#60A5FA]/60 text-[#F1F5F9]"
                    : "bg-[#1B263B]/70 border-white/10 text-[#94A3B8]"
                }`}
              >
                {label}
              </button>
            );
          })}
        </div>
      )}

      {selectedGroup && (
        <CosmicButton
          type="button"
          tone="blue"
          loading={teacherPlanState.status === "loading"}
          onClick={() => void generateTeacherLessonPlan(selectedGroup)}
        >
          {tr("teacher_plan_cta")}
        </CosmicButton>
      )}

      {teacherPlanState.status === "loading" && (
        <div className="space-y-2">
          <p className="text-xs text-[#60A5FA]">{tr("teacher_plan_loading")}</p>
          <ShimmerCard lines={4} />
        </div>
      )}

      {teacherPlanState.status === "error" && (
        <p className="text-xs text-[#F87171]">
          {tr("teacher_plan_error")} ({teacherPlanState.message})
        </p>
      )}

      {teacherPlanState.status === "success" && (
        <div className="space-y-3 pt-1">
          <p className="text-sm font-bold text-[#F1F5F9]">{teacherPlanState.data.topicTitle}</p>

          <div className="space-y-1">
            <p className="text-xs font-bold text-[#38BDF8]">{tr("teacher_plan_pacing")}</p>
            <ul className="space-y-1 text-xs text-[#F1F5F9] ps-4 list-decimal">
              {teacherPlanState.data.pacingSteps.map((s, i) => (
                <li key={i}>{s}</li>
              ))}
            </ul>
          </div>

          <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
            <div className="rounded-xl bg-[#0A0F1C]/60 border border-white/10 p-3 space-y-1">
              <p className="text-xs font-bold text-[#34D399]">{tr("teacher_plan_basic_hw")}</p>
              <ul className="space-y-1 text-xs text-[#94A3B8] ps-4 list-disc">
                {teacherPlanState.data.basicHomework.map((s, i) => (
                  <li key={i}>{s}</li>
                ))}
              </ul>
            </div>
            <div className="rounded-xl bg-[#0A0F1C]/60 border border-white/10 p-3 space-y-1">
              <p className="text-xs font-bold text-[#EAB308]">{tr("teacher_plan_challenge_hw")}</p>
              <ul className="space-y-1 text-xs text-[#94A3B8] ps-4 list-disc">
                {teacherPlanState.data.challengeHomework.map((s, i) => (
                  <li key={i}>{s}</li>
                ))}
              </ul>
            </div>
          </div>

          {teacherPlanState.data.assistantChecklist.length > 0 && (
            <div className="space-y-1">
              <p className="text-xs font-bold text-[#A78BFA] flex items-center gap-1.5">
                <CheckSquare className="w-3.5 h-3.5" />
                {tr("teacher_plan_assistants")}
              </p>
              <ul className="space-y-1 text-xs text-[#94A3B8] ps-4 list-disc">
                {teacherPlanState.data.assistantChecklist.map((s, i) => (
                  <li key={i}>{s}</li>
                ))}
              </ul>
            </div>
          )}

          <CosmicButton
            type="button"
            variant="outline"
            tone="cyan"
            className="w-full text-xs"
            icon={<Share2 className="w-3.5 h-3.5" />}
            onClick={async () => {
              const plan = teacherPlanState.data;
              const txt = [
                plan.topicTitle,
                "",
                `${tr("teacher_plan_pacing")}:`,
                ...plan.pacingSteps.map((s) => `• ${s}`),
                "",
                `${tr("teacher_plan_basic_hw")}:`,
                ...plan.basicHomework.map((s) => `- ${s}`),
                "",
                `${tr("teacher_plan_challenge_hw")}:`,
                ...plan.challengeHomework.map((s) => `★ ${s}`),
              ].join("\n");
              await shareOrCopyText(plan.topicTitle, txt);
              showSnackbar(language === AppLanguage.AR ? "تم تجهيز الخطة للمشاركة" : "Plan ready to share");
            }}
          >
            {tr("teacher_plan_share")}
          </CosmicButton>
        </div>
      )}
    </CosmicCard>
  );
};

export const SecretaryNoticeModal: React.FC = () => {
  const { language, secretaryNoticeState, dismissSecretaryNotice, showSnackbar, tr } = useKashkool();
  const isOpen = secretaryNoticeState.status !== "idle";

  return (
    <ModalDialog
      open={isOpen}
      title={tr("draft_notice_title")}
      onClose={dismissSecretaryNotice}
    >
      {secretaryNoticeState.status === "loading" && (
        <div className="space-y-2 py-2">
          <p className="text-xs text-[#38BDF8]">{tr("draft_notice_loading")}</p>
          <ShimmerCard lines={3} />
        </div>
      )}

      {secretaryNoticeState.status === "error" && (
        <div className="space-y-3 py-2">
          <p className="text-sm font-bold text-[#F1F5F9]">{secretaryNoticeState.studentName}</p>
          <p className="text-xs text-[#F87171]">
            {tr("draft_notice_error")} ({secretaryNoticeState.message})
          </p>
        </div>
      )}

      {secretaryNoticeState.status === "success" && (
        <div className="space-y-3">
          <div className="flex items-center justify-between gap-2">
            <span className="text-sm font-bold text-[#F1F5F9]">{secretaryNoticeState.studentName}</span>
            {secretaryNoticeState.draft.toneTag && (
              <StatusBadge tone="emerald" label={secretaryNoticeState.draft.toneTag} />
            )}
          </div>
          <div className="rounded-xl bg-[#0A0F1C]/80 border border-white/10 p-3.5 text-sm leading-relaxed text-[#F1F5F9] whitespace-pre-wrap">
            {secretaryNoticeState.draft.messageText}
          </div>
          <div className="flex flex-wrap gap-2">
            <CosmicButton
              type="button"
              tone="cyan"
              variant="outline"
              className="flex-1 text-xs"
              icon={<Copy className="w-3.5 h-3.5" />}
              onClick={async () => {
                await copyToClipboard(secretaryNoticeState.draft.messageText);
                showSnackbar(language === AppLanguage.AR ? "تم نسخ الرسالة" : "Notice copied");
              }}
            >
              {tr("copy_text")}
            </CosmicButton>
            <CosmicButton
              type="button"
              tone="emerald"
              className="flex-1 text-xs"
              icon={<Share2 className="w-3.5 h-3.5" />}
              onClick={async () => {
                await shareOrCopyText(
                  secretaryNoticeState.studentName,
                  secretaryNoticeState.draft.messageText
                );
                dismissSecretaryNotice();
              }}
            >
              {tr("share_whatsapp")}
            </CosmicButton>
          </div>
        </div>
      )}
    </ModalDialog>
  );
};
