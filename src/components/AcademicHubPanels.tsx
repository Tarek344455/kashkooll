import React, { useRef, useState } from "react";
import {
  AlertTriangle,
  BookCheck,
  Brain,
  CheckCircle2,
  ClipboardList,
  ImagePlus,
  Megaphone,
  MessageSquarePlus,
  Plus,
  Send,
  Sparkles,
} from "lucide-react";
import { useKashkool } from "../context/KashkoolContext";
import { compressImageFile } from "../core/utils/browserUtils";
import { AppLanguage, UserRole } from "../types/kashkool";
import { CosmicButton, CosmicCard, EmptyState, ModalDialog, StatusBadge } from "./CosmicUi";

export const HomeworkPanel: React.FC<{ role: UserRole }> = ({ role }) => {
  const {
    language,
    groups,
    activeStudent,
    homeworkAssignments,
    homeworkSubmissions,
    createHomeworkAssignment,
    submitHomework,
    gradeHomework,
    tr,
  } = useKashkool();

  const isAr = language === AppLanguage.AR;
  const isStaff = role === UserRole.TEACHER || role === UserRole.SECRETARY;
  const studentId = activeStudent?.id ?? "stu-1";

  // Teacher assign homework modal
  const [assignOpen, setAssignOpen] = useState(false);
  const [hwGroupId, setHwGroupId] = useState(groups[0]?.id ?? "");
  const [hwTitle, setHwTitle] = useState("");
  const [hwDesc, setHwDesc] = useState("");
  const [hwDue, setHwDue] = useState("");
  const [hwMax, setHwMax] = useState("20");
  const [hwErr, setHwErr] = useState<string | null>(null);

  // Student submit homework modal
  const [submitTargetId, setSubmitTargetId] = useState<string | null>(null);
  const [subNotes, setSubNotes] = useState("");
  const [subPhotoUrl, setSubPhotoUrl] = useState<string | null>(null);
  const [compressing, setCompressing] = useState(false);
  const fileRef = useRef<HTMLInputElement | null>(null);

  // Teacher grading modal
  const [gradeTargetId, setGradeTargetId] = useState<string | null>(null);
  const [gradeScore, setGradeScore] = useState("18");
  const [gradeFeedback, setGradeFeedback] = useState("");

  const handleAttachPhoto = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const f = e.target.files?.[0];
    if (!f) return;
    setCompressing(true);
    try {
      const res = await compressImageFile(f);
      setSubPhotoUrl(res.dataUrl);
    } finally {
      setCompressing(false);
    }
  };

  return (
    <div className="space-y-4">
      <div className="flex flex-wrap items-center justify-between gap-2">
        <div className="flex items-center gap-2">
          <ClipboardList className="w-5 h-5 text-[#38BDF8]" />
          <h3 className="text-base font-extrabold text-[#F1F5F9]">{tr("homework_tab")}</h3>
        </div>
        {isStaff && (
          <CosmicButton
            type="button"
            tone="cyan"
            className="text-xs py-1.5 px-3"
            icon={<Plus className="w-3.5 h-3.5" />}
            onClick={() => {
              setHwErr(null);
              setAssignOpen(true);
            }}
          >
            {tr("hw_create_cta")}
          </CosmicButton>
        )}
      </div>

      {homeworkAssignments.length === 0 ? (
        <EmptyState
          icon={<ClipboardList className="w-8 h-8" />}
          message={isAr ? "لا توجد واجبات مطلوبة حالياً." : "No homework assignments posted yet."}
        />
      ) : (
        <div className="space-y-3">
          {homeworkAssignments.map((hw) => {
            const grp = groups.find((g) => g.id === hw.groupId);
            const mySub = homeworkSubmissions.find(
              (s) => s.assignmentId === hw.id && s.studentId === studentId
            );
            const allSubsForHw = homeworkSubmissions.filter((s) => s.assignmentId === hw.id);

            return (
              <CosmicCard key={hw.id} tone={mySub?.status === "graded" ? "emerald" : "cyan"} className="space-y-3">
                <div className="flex flex-wrap items-start justify-between gap-2">
                  <div>
                    <p className="text-xs text-[#38BDF8] font-semibold">
                      {grp ? (isAr ? grp.nameAr : grp.nameEn) : hw.groupId} · {hw.dueDateLabel}
                    </p>
                    <h4 className="text-sm font-extrabold text-[#F1F5F9]">
                      {isAr ? hw.titleAr : hw.titleEn}
                    </h4>
                  </div>
                  <StatusBadge
                    tone="gold"
                    label={`${hw.maxScore} ${isAr ? "درجة" : "pts"}`}
                  />
                </div>

                <p className="text-xs text-[#94A3B8] leading-relaxed">
                  {isAr ? hw.descriptionAr : hw.descriptionEn}
                </p>

                {role === UserRole.STUDENT && (
                  <div className="flex flex-wrap items-center justify-between gap-2 pt-1 border-t border-white/10">
                    {mySub ? (
                      <div className="text-xs space-y-1">
                        <div className="flex items-center gap-2">
                          <StatusBadge
                            tone={mySub.status === "graded" ? "emerald" : "amber"}
                            label={
                              mySub.status === "graded"
                                ? `${tr("hw_graded_badge")}: ${mySub.score}/${hw.maxScore}`
                                : tr("hw_submitted_badge")
                            }
                          />
                        </div>
                        {mySub.feedback && <p className="text-[#34D399]">{mySub.feedback}</p>}
                      </div>
                    ) : (
                      <span className="text-xs text-[#94A3B8]">
                        {isAr ? "لم يتم التسليم بعد" : "Not submitted yet"}
                      </span>
                    )}
                    <CosmicButton
                      type="button"
                      tone="cyan"
                      variant={mySub ? "outline" : "solid"}
                      className="text-xs py-1.5 px-3"
                      onClick={() => {
                        setSubmitTargetId(hw.id);
                        setSubNotes(mySub?.notes ?? "");
                        setSubPhotoUrl(mySub?.attachmentDataUrl ?? null);
                      }}
                    >
                      {tr("hw_submit_cta")}
                    </CosmicButton>
                  </div>
                )}

                {isStaff && (
                  <div className="space-y-2 pt-2 border-t border-white/10">
                    <p className="text-xs font-bold text-[#94A3B8] tabular-nums">
                      {isAr
                        ? `التسليمات المستلمة (${allSubsForHw.length}):`
                        : `Student Submissions (${allSubsForHw.length}):`}
                    </p>
                    {allSubsForHw.map((sub) => (
                      <div
                        key={sub.id}
                        className="rounded-xl bg-[#0A0F1C]/70 border border-white/10 p-2.5 flex flex-wrap items-center justify-between gap-2 text-xs"
                      >
                        <div className="min-w-0 space-y-0.5">
                          <p className="font-bold text-[#F1F5F9]">
                            {isAr ? sub.studentNameAr : sub.studentNameEn}
                          </p>
                          <p className="text-[#94A3B8] truncate">{sub.notes}</p>
                        </div>
                        <div className="flex items-center gap-2">
                          <StatusBadge
                            tone={sub.status === "graded" ? "emerald" : "amber"}
                            label={
                              sub.status === "graded"
                                ? `${sub.score}/${hw.maxScore}`
                                : tr("hw_submitted_badge")
                            }
                          />
                          <CosmicButton
                            type="button"
                            tone="emerald"
                            variant="outline"
                            className="text-xs py-1 px-2.5"
                            onClick={() => {
                              setGradeTargetId(sub.id);
                              setGradeScore(String(sub.score ?? hw.maxScore));
                              setGradeFeedback(sub.feedback ?? "");
                            }}
                          >
                            {tr("hw_grade_cta")}
                          </CosmicButton>
                        </div>
                      </div>
                    ))}
                  </div>
                )}
              </CosmicCard>
            );
          })}
        </div>
      )}

      {/* Teacher Assign Homework Modal */}
      <ModalDialog open={assignOpen} title={tr("hw_create_cta")} onClose={() => setAssignOpen(false)}>
        <div className="space-y-3">
          {hwErr && (
            <div className="rounded-xl bg-[#F87171]/15 border border-[#F87171]/40 px-3 py-2 text-xs text-[#F87171]">
              {hwErr}
            </div>
          )}
          <select
            value={hwGroupId}
            onChange={(e) => setHwGroupId(e.target.value)}
            className="w-full rounded-xl bg-[#0A0F1C] border border-white/15 px-3 py-2 text-sm text-[#F1F5F9]"
          >
            {groups.map((g) => (
              <option key={g.id} value={g.id}>
                {isAr ? g.nameAr : g.nameEn}
              </option>
            ))}
          </select>
          <input
            type="text"
            value={hwTitle}
            onChange={(e) => setHwTitle(e.target.value)}
            placeholder={isAr ? "عنوان الواجب" : "Homework Title"}
            className="w-full rounded-xl bg-[#0A0F1C] border border-white/15 px-3 py-2 text-sm text-[#F1F5F9]"
          />
          <textarea
            value={hwDesc}
            onChange={(e) => setHwDesc(e.target.value)}
            rows={3}
            placeholder={isAr ? "تفاصيل المسائل المطلوبة..." : "Problem numbers & instructions..."}
            className="w-full rounded-xl bg-[#0A0F1C] border border-white/15 px-3 py-2 text-sm text-[#F1F5F9]"
          />
          <div className="grid grid-cols-2 gap-2">
            <input
              type="text"
              value={hwDue}
              onChange={(e) => setHwDue(e.target.value)}
              placeholder={isAr ? "الموعد النهائي" : "Due Date"}
              className="rounded-xl bg-[#0A0F1C] border border-white/15 px-3 py-2 text-xs text-[#F1F5F9]"
            />
            <input
              type="number"
              dir="ltr"
              value={hwMax}
              onChange={(e) => setHwMax(e.target.value)}
              placeholder="20"
              className="rounded-xl bg-[#0A0F1C] border border-white/15 px-3 py-2 text-xs font-mono-tabular text-[#F1F5F9]"
            />
          </div>
          <CosmicButton
            type="button"
            tone="cyan"
            className="w-full"
            onClick={() => {
              if (!hwTitle.trim() || !hwDesc.trim()) {
                setHwErr(tr("validation_required"));
                return;
              }
              createHomeworkAssignment(hwGroupId, hwTitle, hwDesc, hwDue, Number(hwMax) || 20);
              setHwTitle("");
              setHwDesc("");
              setHwDue("");
              setAssignOpen(false);
            }}
          >
            {tr("submit")}
          </CosmicButton>
        </div>
      </ModalDialog>

      {/* Student Submit Homework Modal */}
      <ModalDialog
        open={Boolean(submitTargetId)}
        title={tr("hw_submit_cta")}
        onClose={() => setSubmitTargetId(null)}
      >
        <div className="space-y-3">
          <textarea
            value={subNotes}
            onChange={(e) => setSubNotes(e.target.value)}
            rows={3}
            placeholder={isAr ? "ملخص حلك أو ملاحظات للمعلم..." : "Solution summary or notes..."}
            className="w-full rounded-xl bg-[#0A0F1C] border border-white/15 px-3 py-2 text-sm text-[#F1F5F9]"
          />
          <input
            ref={fileRef}
            type="file"
            accept="image/*"
            className="hidden"
            onChange={(e) => void handleAttachPhoto(e)}
          />
          <div className="flex items-center gap-2">
            <CosmicButton
              type="button"
              tone="cyan"
              variant="outline"
              loading={compressing}
              icon={<ImagePlus className="w-4 h-4" />}
              onClick={() => fileRef.current?.click()}
            >
              {tr("assistant_attach_photo")}
            </CosmicButton>
            {subPhotoUrl && <StatusBadge tone="emerald" label={tr("compressed_badge")} />}
          </div>
          <CosmicButton
            type="button"
            tone="emerald"
            className="w-full"
            disabled={!subNotes.trim() && !subPhotoUrl}
            onClick={() => {
              if (submitTargetId) {
                submitHomework(submitTargetId, subNotes, subPhotoUrl);
              }
              setSubmitTargetId(null);
            }}
          >
            {tr("submit")}
          </CosmicButton>
        </div>
      </ModalDialog>

      {/* Teacher Grade Submission Modal */}
      <ModalDialog
        open={Boolean(gradeTargetId)}
        title={tr("hw_grade_cta")}
        onClose={() => setGradeTargetId(null)}
      >
        <div className="space-y-3">
          <input
            type="number"
            dir="ltr"
            value={gradeScore}
            onChange={(e) => setGradeScore(e.target.value)}
            className="w-full rounded-xl bg-[#0A0F1C] border border-white/15 px-3 py-2 text-sm font-mono-tabular text-[#F1F5F9]"
          />
          <input
            type="text"
            value={gradeFeedback}
            onChange={(e) => setGradeFeedback(e.target.value)}
            placeholder={isAr ? "ملاحظة تشجيعية أو تصحيح..." : "Teacher feedback..."}
            className="w-full rounded-xl bg-[#0A0F1C] border border-white/15 px-3 py-2 text-sm text-[#F1F5F9]"
          />
          <CosmicButton
            type="button"
            tone="emerald"
            className="w-full"
            onClick={() => {
              if (gradeTargetId) {
                gradeHomework(gradeTargetId, Number(gradeScore) || 0, gradeFeedback);
              }
              setGradeTargetId(null);
            }}
          >
            {tr("submit")}
          </CosmicButton>
        </div>
      </ModalDialog>
    </div>
  );
};

export const MistakeBankPanel: React.FC<{
  onAskAssistant?: (prompt: string, subject?: string) => void;
}> = ({ onAskAssistant }) => {
  const {
    language,
    activeStudent,
    mistakeBank,
    toggleMistakeMastered,
    explainMistakeWithAi,
    showSnackbar,
    tr,
  } = useKashkool();

  const isAr = language === AppLanguage.AR;
  const studentId = activeStudent?.id ?? "stu-1";
  const [filter, setFilter] = useState<"all" | "pending" | "mastered">("all");
  const [explainingId, setExplainingId] = useState<string | null>(null);

  const items = mistakeBank
    .filter((m) => m.studentId === studentId)
    .filter((m) => {
      if (filter === "pending") return !m.mastered;
      if (filter === "mastered") return m.mastered;
      return true;
    });

  const handleExplain = async (id: string) => {
    setExplainingId(id);
    try {
      await explainMistakeWithAi(id);
    } catch (err) {
      showSnackbar(err instanceof Error ? err.message : "Could not explain mistake");
    } finally {
      setExplainingId(null);
    }
  };

  return (
    <div className="space-y-4">
      <div className="flex flex-wrap items-center justify-between gap-2">
        <div className="flex items-center gap-2">
          <Brain className="w-5 h-5 text-[#FBBF24]" />
          <h3 className="text-base font-extrabold text-[#F1F5F9]">{tr("mistake_bank_tab")}</h3>
        </div>
        <div className="flex gap-1.5">
          {(["all", "pending", "mastered"] as const).map((f) => (
            <button
              key={f}
              type="button"
              onClick={() => setFilter(f)}
              className={`rounded-lg border px-2.5 py-1 text-xs font-semibold cursor-pointer ${
                filter === f
                  ? "bg-[#FBBF24]/18 border-[#FBBF24]/50 text-[#FBBF24]"
                  : "bg-[#141D2F] border-white/10 text-[#94A3B8]"
              }`}
            >
              {f === "all"
                ? isAr
                  ? "الكل"
                  : "All"
                : f === "pending"
                  ? isAr
                    ? "تحتاج مراجعة"
                    : "Pending"
                  : isAr
                    ? "تم إتقانها"
                    : "Mastered"}
            </button>
          ))}
        </div>
      </div>

      {items.length === 0 ? (
        <EmptyState icon={<BookCheck className="w-8 h-8" />} message={tr("mistake_empty")} />
      ) : (
        <div className="space-y-3">
          {items.map((m) => (
            <CosmicCard key={m.id} tone={m.mastered ? "emerald" : "amber"} className="space-y-2.5">
              <div className="flex flex-wrap items-center justify-between gap-2">
                <div className="flex items-center gap-2">
                  <StatusBadge tone="gold" label={isAr ? m.topicTagAr : m.topicTagEn} />
                  <StatusBadge tone="slate" label={m.sourceType.toUpperCase()} />
                </div>
                <StatusBadge
                  tone={m.mastered ? "emerald" : "crimson"}
                  label={m.mastered ? tr("mistake_mastered_cta") : isAr ? "مراجعة" : "Review"}
                />
              </div>

              <h4 className="text-sm font-bold text-[#F1F5F9]">
                {isAr ? m.questionPromptAr : m.questionPromptEn}
              </h4>

              <div className="grid grid-cols-1 sm:grid-cols-2 gap-2 text-xs">
                <div className="rounded-lg bg-[#F87171]/12 border border-[#F87171]/30 px-2.5 py-1.5">
                  <span className="text-[#94A3B8]">{isAr ? "اختيارك:" : "Wrong:"} </span>
                  <span className="font-bold text-[#F87171]">{m.wrongAnswer}</span>
                </div>
                <div className="rounded-lg bg-[#34D399]/12 border border-[#34D399]/30 px-2.5 py-1.5">
                  <span className="text-[#94A3B8]">{isAr ? "الإجابة الصحيحة:" : "Correct:"} </span>
                  <span className="font-bold text-[#34D399]">{m.correctAnswer}</span>
                </div>
              </div>

              <p className="text-xs text-[#94A3B8]">{isAr ? m.remedialAr : m.remedialEn}</p>

              {m.aiBreakdown && (
                <div className="rounded-xl bg-[#0A0F1C]/80 border border-[#38BDF8]/30 p-3 space-y-1.5 text-xs">
                  <p className="font-bold text-[#38BDF8]">{m.aiBreakdown.whyMistakeHappens}</p>
                  <ul className="list-disc list-inside space-y-0.5 text-[#F1F5F9]">
                    {m.aiBreakdown.stepByStepFix.map((s, idx) => (
                      <li key={idx}>{s}</li>
                    ))}
                  </ul>
                  {m.aiBreakdown.goldenRule && (
                    <p className="font-bold text-[#34D399] pt-1">{m.aiBreakdown.goldenRule}</p>
                  )}
                </div>
              )}

              <div className="flex flex-wrap gap-2 pt-1">
                <CosmicButton
                  type="button"
                  tone="cyan"
                  variant="outline"
                  loading={explainingId === m.id}
                  className="text-xs py-1.5 px-3"
                  icon={<Sparkles className="w-3.5 h-3.5" />}
                  onClick={() => void handleExplain(m.id)}
                >
                  {tr("mistake_explain_cta")}
                </CosmicButton>

                <CosmicButton
                  type="button"
                  tone={m.mastered ? "slate" : "emerald"}
                  variant="subtle"
                  className="text-xs py-1.5 px-3"
                  icon={<CheckCircle2 className="w-3.5 h-3.5" />}
                  onClick={() => toggleMistakeMastered(m.id)}
                >
                  {tr("mistake_mastered_cta")}
                </CosmicButton>

                {onAskAssistant && (
                  <CosmicButton
                    type="button"
                    tone="purple"
                    variant="subtle"
                    className="text-xs py-1.5 px-3"
                    onClick={() =>
                      onAskAssistant(
                        isAr
                          ? `راجع معي هذا الخطأ في "${m.topicTagAr}": "${m.questionPromptAr}"`
                          : `Help me master this mistake in "${m.topicTagEn}": "${m.questionPromptEn}"`,
                        isAr ? m.topicTagAr : m.topicTagEn
                      )
                    }
                  >
                    {tr("nav_assistant")}
                  </CosmicButton>
                )}
              </div>
            </CosmicCard>
          ))}
        </div>
      )}
    </div>
  );
};

export const CommunicationHubPanel: React.FC<{ role: UserRole }> = ({ role }) => {
  const {
    language,
    groups,
    activeStudent,
    announcements,
    supportTickets,
    createAnnouncement,
    markAnnouncementRead,
    createSupportTicket,
    replySupportTicket,
    tr,
  } = useKashkool();

  const isAr = language === AppLanguage.AR;
  const isStaff = role === UserRole.TEACHER || role === UserRole.SECRETARY;
  const readerId = activeStudent?.id ?? role;

  const [annOpen, setAnnOpen] = useState(false);
  const [annGroup, setAnnGroup] = useState<string>("");
  const [annTitle, setAnnTitle] = useState("");
  const [annBody, setAnnBody] = useState("");
  const [annErr, setAnnErr] = useState<string | null>(null);

  const [ticketOpen, setTicketOpen] = useState(false);
  const [tktSubject, setTktSubject] = useState("");
  const [tktMessage, setTktMessage] = useState("");
  const [tktErr, setTktErr] = useState<string | null>(null);

  const [replyTargetId, setReplyTargetId] = useState<string | null>(null);
  const [replyText, setReplyText] = useState("");

  return (
    <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
      {/* Targeted Announcements */}
      <CosmicCard tone="cyan" className="space-y-3">
        <div className="flex items-center justify-between gap-2">
          <div className="flex items-center gap-2">
            <Megaphone className="w-4 h-4 text-[#38BDF8]" />
            <h3 className="text-sm font-bold text-[#F1F5F9]">{tr("announcements_title")}</h3>
          </div>
          {isStaff && (
            <CosmicButton
              type="button"
              tone="cyan"
              variant="subtle"
              className="text-xs py-1 px-2.5"
              icon={<Plus className="w-3.5 h-3.5" />}
              onClick={() => {
                setAnnErr(null);
                setAnnOpen(true);
              }}
            >
              {tr("announcement_post_cta")}
            </CosmicButton>
          )}
        </div>

        <div className="space-y-2">
          {announcements.map((a) => {
            const isRead = a.readByIds.includes(readerId);
            return (
              <div
                key={a.id}
                className="rounded-xl bg-[#0A0F1C]/70 border border-white/10 p-3 space-y-1.5 text-xs"
              >
                <div className="flex items-center justify-between gap-2">
                  <span className="font-bold text-[#F1F5F9]">{isAr ? a.titleAr : a.titleEn}</span>
                  <StatusBadge
                    tone={isRead ? "emerald" : "amber"}
                    label={
                      isRead
                        ? `${tr("announcement_read_badge")} (${a.readByIds.length})`
                        : `${a.readByIds.length}`
                    }
                  />
                </div>
                <p className="text-[#94A3B8] leading-relaxed">{isAr ? a.bodyAr : a.bodyEn}</p>
                {!isRead && (
                  <button
                    type="button"
                    onClick={() => markAnnouncementRead(a.id)}
                    className="text-[#38BDF8] font-bold hover:underline cursor-pointer"
                  >
                    {tr("announcement_mark_read")}
                  </button>
                )}
              </div>
            );
          })}
        </div>
      </CosmicCard>

      {/* Support & Inquiry Tickets */}
      <CosmicCard tone="purple" className="space-y-3">
        <div className="flex items-center justify-between gap-2">
          <div className="flex items-center gap-2">
            <MessageSquarePlus className="w-4 h-4 text-[#A78BFA]" />
            <h3 className="text-sm font-bold text-[#F1F5F9]">{tr("tickets_title")}</h3>
          </div>
          <CosmicButton
            type="button"
            tone="purple"
            variant="subtle"
            className="text-xs py-1 px-2.5"
            icon={<Plus className="w-3.5 h-3.5" />}
            onClick={() => {
              setTktErr(null);
              setTicketOpen(true);
            }}
          >
            {tr("ticket_send_cta")}
          </CosmicButton>
        </div>

        <div className="space-y-2">
          {supportTickets.map((tk) => (
            <div
              key={tk.id}
              className="rounded-xl bg-[#0A0F1C]/70 border border-white/10 p-3 space-y-1.5 text-xs"
            >
              <div className="flex items-center justify-between gap-2">
                <span className="font-bold text-[#F1F5F9]">{tk.subject}</span>
                <StatusBadge
                  tone={tk.status === "answered" ? "emerald" : "amber"}
                  label={tk.status === "answered" ? (isAr ? "تم الرد" : "Answered") : isAr ? "مفتوحة" : "Open"}
                />
              </div>
              <p className="text-[#94A3B8]">{tk.message}</p>
              {tk.replyText && (
                <div className="rounded-lg bg-[#34D399]/10 border border-[#34D399]/30 p-2 text-[#34D399]">
                  {tk.replyText}
                </div>
              )}
              {isStaff && (
                <button
                  type="button"
                  onClick={() => {
                    setReplyTargetId(tk.id);
                    setReplyText(tk.replyText ?? "");
                  }}
                  className="text-[#A78BFA] font-bold hover:underline cursor-pointer"
                >
                  {tr("ticket_reply_cta")}
                </button>
              )}
            </div>
          ))}
        </div>
      </CosmicCard>

      {/* Post Announcement Modal */}
      <ModalDialog open={annOpen} title={tr("announcement_post_cta")} onClose={() => setAnnOpen(false)}>
        <div className="space-y-3">
          {annErr && (
            <div className="flex items-center gap-2 rounded-xl bg-[#F87171]/15 border border-[#F87171]/40 px-3 py-2 text-xs text-[#F87171]">
              <AlertTriangle className="w-4 h-4" />
              <span>{annErr}</span>
            </div>
          )}
          <select
            value={annGroup}
            onChange={(e) => setAnnGroup(e.target.value)}
            className="w-full rounded-xl bg-[#0A0F1C] border border-white/15 px-3 py-2 text-sm text-[#F1F5F9]"
          >
            <option value="">{tr("att_all_groups")}</option>
            {groups.map((g) => (
              <option key={g.id} value={g.id}>
                {isAr ? g.nameAr : g.nameEn}
              </option>
            ))}
          </select>
          <input
            type="text"
            value={annTitle}
            onChange={(e) => setAnnTitle(e.target.value)}
            placeholder={isAr ? "عنوان الإعلان" : "Announcement Title"}
            className="w-full rounded-xl bg-[#0A0F1C] border border-white/15 px-3 py-2 text-sm text-[#F1F5F9]"
          />
          <textarea
            value={annBody}
            onChange={(e) => setAnnBody(e.target.value)}
            rows={3}
            placeholder={isAr ? "نص التنبيه أو التعليمات..." : "Announcement details..."}
            className="w-full rounded-xl bg-[#0A0F1C] border border-white/15 px-3 py-2 text-sm text-[#F1F5F9]"
          />
          <CosmicButton
            type="button"
            tone="cyan"
            className="w-full"
            onClick={() => {
              if (!annTitle.trim() || !annBody.trim()) {
                setAnnErr(tr("validation_required"));
                return;
              }
              createAnnouncement(annGroup || null, annTitle, annBody, true);
              setAnnTitle("");
              setAnnBody("");
              setAnnOpen(false);
            }}
          >
            {tr("submit")}
          </CosmicButton>
        </div>
      </ModalDialog>

      {/* Open Support Ticket Modal */}
      <ModalDialog open={ticketOpen} title={tr("ticket_send_cta")} onClose={() => setTicketOpen(false)}>
        <div className="space-y-3">
          {tktErr && (
            <div className="rounded-xl bg-[#F87171]/15 border border-[#F87171]/40 px-3 py-2 text-xs text-[#F87171]">
              {tktErr}
            </div>
          )}
          <input
            type="text"
            value={tktSubject}
            onChange={(e) => setTktSubject(e.target.value)}
            placeholder={isAr ? "موضوع الاستفسار" : "Subject"}
            className="w-full rounded-xl bg-[#0A0F1C] border border-white/15 px-3 py-2 text-sm text-[#F1F5F9]"
          />
          <textarea
            value={tktMessage}
            onChange={(e) => setTktMessage(e.target.value)}
            rows={3}
            placeholder={isAr ? "اكتب استفسارك أو طلبك هنا..." : "Write your message..."}
            className="w-full rounded-xl bg-[#0A0F1C] border border-white/15 px-3 py-2 text-sm text-[#F1F5F9]"
          />
          <CosmicButton
            type="button"
            tone="purple"
            icon={<Send className="w-4 h-4" />}
            className="w-full"
            onClick={() => {
              if (!tktSubject.trim() || !tktMessage.trim()) {
                setTktErr(tr("validation_required"));
                return;
              }
              createSupportTicket(tktSubject, tktMessage);
              setTktSubject("");
              setTktMessage("");
              setTicketOpen(false);
            }}
          >
            {tr("submit")}
          </CosmicButton>
        </div>
      </ModalDialog>

      {/* Staff Reply Ticket Modal */}
      <ModalDialog
        open={Boolean(replyTargetId)}
        title={tr("ticket_reply_cta")}
        onClose={() => setReplyTargetId(null)}
      >
        <div className="space-y-3">
          <textarea
            value={replyText}
            onChange={(e) => setReplyText(e.target.value)}
            rows={3}
            placeholder={isAr ? "اكتب رد إدارة السنتر أو المعلم..." : "Write official reply..."}
            className="w-full rounded-xl bg-[#0A0F1C] border border-white/15 px-3 py-2 text-sm text-[#F1F5F9]"
          />
          <CosmicButton
            type="button"
            tone="emerald"
            className="w-full"
            disabled={!replyText.trim()}
            onClick={() => {
              if (replyTargetId) replySupportTicket(replyTargetId, replyText);
              setReplyTargetId(null);
            }}
          >
            {tr("submit")}
          </CosmicButton>
        </div>
      </ModalDialog>
    </div>
  );
};
