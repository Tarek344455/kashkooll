import React, { useState } from "react";
import { Award, CheckCircle2, RefreshCw, Share2, ShieldCheck, Target, TrendingUp } from "lucide-react";
import { useKashkool } from "../context/KashkoolContext";
import { AppLanguage } from "../types/kashkool";
import { shareOrCopyText } from "../core/utils/browserUtils";
import { CosmicButton, CosmicCard, ShimmerCard, StatusBadge } from "./CosmicUi";

export type EvaluationMode = "TEACHER_CONSOLE" | "STUDENT_SELF" | "PARENT_CHILD";

export const PerformanceEvaluationCard: React.FC<{ mode: EvaluationMode }> = ({ mode }) => {
  const {
    language,
    students,
    evaluationState,
    evaluateTeacherPerformance,
    evaluateStudentPerformance,
    buildEvaluationShareText,
    showSnackbar,
    tr,
  } = useKashkool();

  const [selectedStudentId, setSelectedStudentId] = useState<string>(students[0]?.id ?? "stu-1");

  const primaryCtaLabel =
    mode === "TEACHER_CONSOLE"
      ? tr("eval_teacher_btn")
      : mode === "STUDENT_SELF"
        ? tr("eval_my_progress_btn")
        : tr("eval_child_btn");

  const triggerPrimary = () => {
    if (mode === "TEACHER_CONSOLE") {
      void evaluateTeacherPerformance();
    } else {
      void evaluateStudentPerformance(students[0]?.id ?? null);
    }
  };

  return (
    <CosmicCard tone="purple" className="space-y-3.5">
      <div className="flex flex-wrap items-center justify-between gap-2">
        <div className="flex items-center gap-2">
          <Award className="w-5 h-5 text-[#A78BFA]" />
          <h3 className="text-sm font-bold text-[#F1F5F9]">{tr("eval_section_title")}</h3>
        </div>
        <StatusBadge tone="emerald" label={tr("eval_saved_badge")} />
      </div>

      {mode === "TEACHER_CONSOLE" && students.length > 0 && (
        <div className="space-y-2">
          <label className="block text-xs text-[#94A3B8]">{tr("eval_select_student")}</label>
          <div className="flex flex-wrap gap-1.5">
            {students.map((st) => {
              const label = language === AppLanguage.AR ? st.nameAr : st.nameEn;
              const active = st.id === selectedStudentId;
              return (
                <button
                  key={st.id}
                  type="button"
                  onClick={() => setSelectedStudentId(st.id)}
                  className={`rounded-lg border px-2.5 py-1.5 text-xs font-medium transition-colors cursor-pointer ${
                    active
                      ? "bg-[#A78BFA]/20 border-[#A78BFA]/60 text-[#F1F5F9]"
                      : "bg-[#1B263B]/70 border-white/10 text-[#94A3B8] hover:text-[#F1F5F9]"
                  }`}
                >
                  {label}
                </button>
              );
            })}
          </div>
        </div>
      )}

      <div className="flex flex-wrap gap-2">
        <CosmicButton
          type="button"
          tone="purple"
          onClick={triggerPrimary}
          loading={evaluationState.status === "loading"}
          icon={<TrendingUp className="w-4 h-4" />}
        >
          {primaryCtaLabel}
        </CosmicButton>
        {mode === "TEACHER_CONSOLE" && students.length > 0 && (
          <CosmicButton
            type="button"
            tone="cyan"
            variant="outline"
            onClick={() => void evaluateStudentPerformance(selectedStudentId)}
            loading={evaluationState.status === "loading"}
          >
            {tr("eval_student_btn")}
          </CosmicButton>
        )}
      </div>

      {evaluationState.status === "idle" && (
        <p className="text-xs text-[#94A3B8]">{tr("eval_empty_hint")}</p>
      )}

      {evaluationState.status === "loading" && (
        <div className="space-y-2">
          <p className="text-xs text-[#A78BFA]">{tr("eval_loading")}</p>
          <ShimmerCard lines={4} />
        </div>
      )}

      {evaluationState.status === "error" && (
        <div className="rounded-xl bg-[#F87171]/10 border border-[#F87171]/30 p-3 space-y-2">
          <p className="text-xs font-semibold text-[#F87171]">
            {tr("eval_error_prefix")} {evaluationState.message}
          </p>
          <CosmicButton
            type="button"
            tone="crimson"
            variant="outline"
            className="text-xs py-1.5 px-3"
            icon={<RefreshCw className="w-3.5 h-3.5" />}
            onClick={triggerPrimary}
          >
            {tr("eval_retry")}
          </CosmicButton>
        </div>
      )}

      {evaluationState.status === "success" && (
        <div className="space-y-3 pt-1">
          <div className="flex flex-wrap items-center justify-between gap-2 rounded-xl bg-[#0A0F1C]/60 border border-white/10 p-3">
            <div>
              <p className="text-sm font-bold text-[#F1F5F9]">{evaluationState.data.targetName}</p>
              <p className="text-xs text-[#34D399] font-semibold">{evaluationState.data.trustBadge}</p>
            </div>
            <div className="text-end">
              <span className="text-2xl font-extrabold text-[#A78BFA] font-mono-tabular">
                {evaluationState.data.overallScore}
              </span>
              <span className="text-xs text-[#94A3B8]">/100</span>
            </div>
          </div>

          <p className="text-xs leading-relaxed text-[#F1F5F9]">{evaluationState.data.analyticalSummary}</p>

          <div className="rounded-xl bg-[#38BDF8]/10 border border-[#38BDF8]/25 p-3 space-y-1">
            <p className="text-[11px] font-bold text-[#38BDF8]">{tr("eval_instant_feedback_title")}</p>
            <p className="text-xs text-[#F1F5F9]">{evaluationState.data.instantFeedback}</p>
          </div>

          {evaluationState.data.strengths.length > 0 && (
            <div className="space-y-1">
              <p className="text-xs font-bold text-[#34D399] flex items-center gap-1.5">
                <CheckCircle2 className="w-3.5 h-3.5" />
                {tr("eval_strengths_title")}
              </p>
              <ul className="space-y-1 text-xs text-[#94A3B8] ps-4 list-disc">
                {evaluationState.data.strengths.map((s, i) => (
                  <li key={i}>{s}</li>
                ))}
              </ul>
            </div>
          )}

          {evaluationState.data.improvementAreas.length > 0 && (
            <div className="space-y-1">
              <p className="text-xs font-bold text-[#FBBF24] flex items-center gap-1.5">
                <Target className="w-3.5 h-3.5" />
                {tr("eval_improvements_title")}
              </p>
              <ul className="space-y-1 text-xs text-[#94A3B8] ps-4 list-disc">
                {evaluationState.data.improvementAreas.map((s, i) => (
                  <li key={i}>{s}</li>
                ))}
              </ul>
            </div>
          )}

          {evaluationState.data.nextActionPlan.length > 0 && (
            <div className="space-y-1">
              <p className="text-xs font-bold text-[#38BDF8]">{tr("eval_next_plan_title")}</p>
              <ul className="space-y-1 text-xs text-[#F1F5F9] ps-4 list-decimal">
                {evaluationState.data.nextActionPlan.map((s, i) => (
                  <li key={i}>{s}</li>
                ))}
              </ul>
            </div>
          )}

          {evaluationState.data.trustVerificationNote && (
            <div className="flex items-start gap-2 rounded-xl bg-white/5 px-3 py-2 text-[11px] text-[#94A3B8]">
              <ShieldCheck className="w-4 h-4 text-[#34D399] shrink-0 mt-0.5" />
              <div>
                <span className="font-semibold text-[#F1F5F9]">{tr("eval_trust_note_title")}: </span>
                <span>{evaluationState.data.trustVerificationNote}</span>
              </div>
            </div>
          )}

          <CosmicButton
            type="button"
            variant="outline"
            tone="emerald"
            className="w-full text-xs"
            icon={<Share2 className="w-3.5 h-3.5" />}
            onClick={async () => {
              const text = buildEvaluationShareText(evaluationState.data);
              const res = await shareOrCopyText(evaluationState.data.targetName, text);
              showSnackbar(
                res === "copied"
                  ? language === AppLanguage.AR
                    ? "تم نسخ التقييم للمشاركة"
                    : "Evaluation copied for sharing"
                  : language === AppLanguage.AR
                    ? "تمت مشاركة التقييم"
                    : "Evaluation shared"
              );
            }}
          >
            {tr("eval_share_cta")}
          </CosmicButton>
        </div>
      )}
    </CosmicCard>
  );
};
