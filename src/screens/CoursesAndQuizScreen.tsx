import React, { useEffect, useState } from "react";
import {
  ArrowLeft,
  CheckCircle2,
  Clock,
  HelpCircle,
  Play,
  RotateCcw,
  ShieldCheck,
  Wifi,
} from "lucide-react";
import { useKashkool } from "../context/KashkoolContext";
import { AppLanguage, CourseUnit } from "../types/kashkool";
import { CosmicButton, CosmicCard, ShimmerCard, StatusBadge } from "../components/CosmicUi";
import { LessonRevisionDeckCard } from "../components/AiToolkitCards";
import { PerformanceEvaluationCard } from "../components/PerformanceEvaluationCard";

export const CoursesAndQuizScreen: React.FC<{
  initialTab?: "courses" | "quiz";
  onAskAssistant: (prompt: string, subject?: string) => void;
}> = ({ initialTab = "courses", onAskAssistant }) => {
  const {
    language,
    courses,
    quizQuestions,
    adaptiveQuizQuestions,
    adaptiveQuizTopic,
    adaptiveQuizBusy,
    adaptiveQuizError,
    completedCourseIds,
    lowDataMode,
    activeLectureId,
    operatingReport,
    userLabel,
    toggleLowDataMode,
    openLecture,
    closeLecture,
    markActiveLectureCompleted,
    generateAdaptiveQuiz,
    resetAdaptiveQuiz,
    recordQuizOutcome,
    tr,
  } = useKashkool();

  const isAr = language === AppLanguage.AR;
  const [tab, setTab] = useState<"courses" | "quiz">(initialTab);
  const [lectureProgress, setLectureProgress] = useState(35);

  // Quiz state
  const activeQuestions = adaptiveQuizQuestions ?? quizQuestions;
  const [qIndex, setQIndex] = useState(0);
  const [selectedOpt, setSelectedOpt] = useState<number | null>(null);
  const [submittedAnswer, setSubmittedAnswer] = useState(false);
  const [score, setScore] = useState(0);
  const [quizFinished, setQuizFinished] = useState(false);

  useEffect(() => {
    setTab(initialTab);
  }, [initialTab]);

  useEffect(() => {
    setQIndex(0);
    setSelectedOpt(null);
    setSubmittedAnswer(false);
    setScore(0);
    setQuizFinished(false);
  }, [adaptiveQuizQuestions]);

  const activeUnit: CourseUnit | undefined = courses.find((c) => c.id === activeLectureId);
  const rankedCourses = [...courses].sort((a, b) => {
    const ra = operatingReport.courseRecommendations.find((r) => r.courseId === a.id)?.rank ?? 99;
    const rb = operatingReport.courseRecommendations.find((r) => r.courseId === b.id)?.rank ?? 99;
    return ra - rb;
  });

  const currentQuestion = activeQuestions[qIndex];

  const handleCheckAnswer = () => {
    if (selectedOpt === null || !currentQuestion) return;
    const correct = selectedOpt === currentQuestion.correctIndex;
    setSubmittedAnswer(true);
    if (correct) setScore((s) => s + 1);
    recordQuizOutcome(currentQuestion.id, correct);
  };

  const handleNextQuestion = () => {
    if (qIndex + 1 >= activeQuestions.length) {
      setQuizFinished(true);
    } else {
      setQIndex((i) => i + 1);
      setSelectedOpt(null);
      setSubmittedAnswer(false);
    }
  };

  const handleRestartQuiz = () => {
    setQIndex(0);
    setSelectedOpt(null);
    setSubmittedAnswer(false);
    setScore(0);
    setQuizFinished(false);
  };

  return (
    <div className="space-y-4">
      {/* Top Tabs + Data Saver Toggle */}
      <div className="flex flex-wrap items-center justify-between gap-2">
        <div className="flex gap-2">
          <button
            type="button"
            onClick={() => setTab("courses")}
            className={`rounded-xl border px-4 py-2 text-xs sm:text-sm font-bold cursor-pointer ${
              tab === "courses"
                ? "bg-[#38BDF8]/18 border-[#38BDF8]/60 text-[#38BDF8]"
                : "bg-[#141D2F] border-white/10 text-[#94A3B8]"
            }`}
          >
            {tr("courses_tab")}
          </button>
          <button
            type="button"
            onClick={() => setTab("quiz")}
            className={`rounded-xl border px-4 py-2 text-xs sm:text-sm font-bold cursor-pointer ${
              tab === "quiz"
                ? "bg-[#EAB308]/18 border-[#EAB308]/60 text-[#EAB308]"
                : "bg-[#141D2F] border-white/10 text-[#94A3B8]"
            }`}
          >
            {tr("quiz_tab")}
          </button>
        </div>

        <CosmicButton
          type="button"
          tone={lowDataMode ? "emerald" : "slate"}
          variant="outline"
          className="text-xs py-1.5 px-3"
          icon={<Wifi className="w-3.5 h-3.5" />}
          onClick={toggleLowDataMode}
        >
          {lowDataMode ? tr("low_data_360p") : tr("standard_720p")}
        </CosmicButton>
      </div>

      {/* LECTURES TAB */}
      {tab === "courses" && !activeUnit && (
        <div className="space-y-4">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
            {rankedCourses.map((unit) => {
              const rec = operatingReport.courseRecommendations.find((r) => r.courseId === unit.id);
              const done = completedCourseIds.has(unit.id);
              return (
                <CosmicCard
                  key={unit.id}
                  tone={done ? "emerald" : rec?.isTopPick ? "gold" : "cyan"}
                  onClick={() => {
                    setLectureProgress(done ? 100 : 35);
                    openLecture(unit);
                  }}
                  className="space-y-2.5"
                >
                  <div className="flex flex-wrap items-center justify-between gap-2">
                    <span className="text-xs font-semibold text-[#38BDF8]">
                      {isAr ? unit.gradeAr : unit.gradeEn}
                    </span>
                    <div className="flex items-center gap-1.5">
                      {rec?.isTopPick && !done && (
                        <StatusBadge tone="gold" label={tr("or_course_top_pick")} />
                      )}
                      {done && <StatusBadge tone="emerald" label={tr("lesson_completed_badge")} />}
                    </div>
                  </div>
                  <h3 className="text-sm font-bold text-[#F1F5F9]">
                    {isAr ? unit.titleAr : unit.titleEn}
                  </h3>
                  <p className="text-xs text-[#94A3B8] line-clamp-2">
                    {isAr ? unit.summaryAr : unit.summaryEn}
                  </p>
                  <div className="flex items-center justify-between text-xs text-[#94A3B8] pt-1">
                    <span className="flex items-center gap-1 tabular-nums">
                      <Clock className="w-3.5 h-3.5" /> {unit.duration}
                    </span>
                    <span className="tabular-nums">~{unit.dataEstimateMb} MB</span>
                  </div>
                </CosmicCard>
              );
            })}
          </div>

          <PerformanceEvaluationCard mode="STUDENT_SELF" />
        </div>
      )}

      {/* LECTURE PLAYER */}
      {tab === "courses" && activeUnit && (
        <div className="space-y-4">
          <CosmicButton
            type="button"
            tone="slate"
            variant="outline"
            className="text-xs py-1.5 px-3"
            icon={<ArrowLeft className="w-3.5 h-3.5" />}
            onClick={closeLecture}
          >
            {tr("courses_tab")}
          </CosmicButton>

          {/* Protected Video Stage */}
          <CosmicCard tone="cyan" className="space-y-3">
            <div className="flex flex-wrap items-center justify-between gap-2">
              <div>
                <p className="text-xs text-[#38BDF8]">
                  {isAr ? activeUnit.gradeAr : activeUnit.gradeEn}
                </p>
                <h2 className="text-base sm:text-lg font-extrabold text-[#F1F5F9]">
                  {isAr ? activeUnit.titleAr : activeUnit.titleEn}
                </h2>
              </div>
              <StatusBadge tone="emerald" label={tr("flag_secure_active")} />
            </div>

            <div className="relative rounded-2xl bg-gradient-to-br from-[#0A0F1C] via-[#101A2F] to-[#172542] border border-[#38BDF8]/30 h-52 sm:h-64 flex flex-col items-center justify-center p-4 overflow-hidden select-none">
              {/* Dynamic Watermark */}
              <div className="pointer-events-none absolute top-3 end-4 text-[11px] font-mono-tabular text-white/25">
                {userLabel} · {lowDataMode ? "360p" : "720p"}
              </div>
              <div className="w-14 h-14 rounded-full bg-[#38BDF8]/20 border border-[#38BDF8]/60 flex items-center justify-center text-[#38BDF8] mb-3">
                <Play className="w-6 h-6 fill-current" />
              </div>
              <p className="text-sm font-bold text-[#F1F5F9] text-center">
                {isAr ? activeUnit.titleAr : activeUnit.titleEn}
              </p>
              <p className="text-xs text-[#94A3B8] mt-1 tabular-nums">
                {tr("drm_protected")} · {activeUnit.duration} · ~{activeUnit.dataEstimateMb} MB
              </p>
            </div>

            {/* Interactive Timeline Progress + Chapters */}
            <div className="space-y-2">
              <div className="flex justify-between text-xs">
                <span className="text-[#94A3B8]">{tr("lesson_progress")}</span>
                <span className="font-bold text-[#38BDF8] tabular-nums">{lectureProgress}%</span>
              </div>
              <input
                type="range"
                min={0}
                max={100}
                value={lectureProgress}
                onChange={(e) => setLectureProgress(Number(e.target.value))}
                className="w-full accent-[#38BDF8] cursor-pointer"
              />
              <div className="flex flex-wrap gap-1.5">
                {[
                  { label: isAr ? "مقدمة الفكرة" : "Intro Concept", pct: 15 },
                  { label: isAr ? "القوانين الأساسية" : "Core Formulas", pct: 45 },
                  { label: isAr ? "مسائل متدرجة" : "Worked Examples", pct: 75 },
                  { label: isAr ? "أفكار الامتحان" : "Exam Tricks", pct: 95 },
                ].map((ch) => (
                  <button
                    key={ch.pct}
                    type="button"
                    onClick={() => setLectureProgress(ch.pct)}
                    className="rounded-lg bg-[#0A0F1C]/80 border border-white/10 px-2.5 py-1 text-[11px] text-[#94A3B8] hover:text-[#38BDF8] cursor-pointer"
                  >
                    {ch.label} ({ch.pct}%)
                  </button>
                ))}
              </div>
            </div>

            <div className="rounded-xl bg-[#0A0F1C]/65 border border-white/10 p-3 space-y-1">
              <p className="text-xs font-bold text-[#34D399] flex items-center gap-1.5">
                <ShieldCheck className="w-3.5 h-3.5" />
                {tr("lesson_summary_title")}
              </p>
              <p className="text-xs text-[#F1F5F9] leading-relaxed">
                {isAr ? activeUnit.summaryAr : activeUnit.summaryEn}
              </p>
            </div>

            <div className="flex flex-wrap gap-2">
              <CosmicButton
                type="button"
                tone="emerald"
                icon={<CheckCircle2 className="w-4 h-4" />}
                onClick={markActiveLectureCompleted}
              >
                {tr("mark_lesson_done")}
              </CosmicButton>

              <CosmicButton
                type="button"
                tone="gold"
                variant="outline"
                onClick={() => {
                  const title = isAr ? activeUnit.titleAr : activeUnit.titleEn;
                  setTab("quiz");
                  void generateAdaptiveQuiz(title);
                }}
              >
                {tr("generate_adaptive_quiz")}
              </CosmicButton>

              <CosmicButton
                type="button"
                tone="cyan"
                variant="subtle"
                icon={<HelpCircle className="w-4 h-4" />}
                onClick={() => {
                  const title = isAr ? activeUnit.titleAr : activeUnit.titleEn;
                  onAskAssistant(
                    isAr
                      ? `أتابع الآن درس "${title}" عند ${lectureProgress}% — هل يمكنك تبسيط الفكرة الرئيسية؟`
                      : `I'm watching "${title}" at ${lectureProgress}% — can you explain the key idea simply?`,
                    title
                  );
                }}
              >
                {tr("ask_about_lesson")}
              </CosmicButton>
            </div>
          </CosmicCard>

          <LessonRevisionDeckCard
            lessonTitle={isAr ? activeUnit.titleAr : activeUnit.titleEn}
            lessonSummary={isAr ? activeUnit.summaryAr : activeUnit.summaryEn}
          />
        </div>
      )}

      {/* QUIZ TAB */}
      {tab === "quiz" && (
        <div className="space-y-4">
          {adaptiveQuizTopic && (
            <div className="flex flex-wrap items-center justify-between gap-2 rounded-xl bg-[#EAB308]/12 border border-[#EAB308]/35 px-3.5 py-2.5 text-xs">
              <span className="font-bold text-[#EAB308]">
                {tr("adaptive_quiz_ready")}: {adaptiveQuizTopic}
              </span>
              <button
                type="button"
                onClick={resetAdaptiveQuiz}
                className="font-bold text-[#38BDF8] hover:underline cursor-pointer"
              >
                {tr("adaptive_quiz_reset")}
              </button>
            </div>
          )}

          {adaptiveQuizBusy && (
            <CosmicCard tone="gold" className="space-y-2">
              <p className="text-xs text-[#EAB308]">{tr("adaptive_quiz_loading")}</p>
              <ShimmerCard lines={4} />
            </CosmicCard>
          )}

          {adaptiveQuizError && (
            <CosmicCard tone="crimson" className="space-y-2">
              <p className="text-xs text-[#F87171]">{adaptiveQuizError}</p>
              <CosmicButton type="button" tone="crimson" variant="outline" onClick={resetAdaptiveQuiz}>
                {tr("adaptive_quiz_reset")}
              </CosmicButton>
            </CosmicCard>
          )}

          {!adaptiveQuizBusy && quizFinished && (
            <CosmicCard tone="emerald" className="text-center py-8 space-y-3">
              <p className="text-xs text-[#94A3B8]">{tr("quiz_score")}</p>
              <p className="text-4xl font-extrabold text-[#34D399] tabular-nums">
                {score} / {activeQuestions.length}
              </p>
              <CosmicButton
                type="button"
                tone="cyan"
                icon={<RotateCcw className="w-4 h-4" />}
                onClick={handleRestartQuiz}
              >
                {tr("restart_quiz")}
              </CosmicButton>
            </CosmicCard>
          )}

          {!adaptiveQuizBusy && !quizFinished && currentQuestion && (
            <CosmicCard tone="cyan" className="space-y-4">
              <div className="flex items-center justify-between gap-2 text-xs">
                <StatusBadge
                  tone="gold"
                  label={isAr ? currentQuestion.topicTagAr : currentQuestion.topicTagEn}
                />
                <span className="font-bold text-[#94A3B8] tabular-nums">
                  {qIndex + 1} / {activeQuestions.length}
                </span>
              </div>

              <h3 className="text-base font-bold text-[#F1F5F9]">
                {isAr ? currentQuestion.promptAr : currentQuestion.promptEn}
              </h3>

              {currentQuestion.formula && (
                <div
                  dir="ltr"
                  className="rounded-xl bg-[#0A0F1C] border border-white/10 px-3.5 py-2.5 text-sm font-mono-tabular text-[#38BDF8] text-center"
                >
                  {currentQuestion.formula}
                </div>
              )}

              <div className="space-y-2">
                {currentQuestion.options.map((opt, idx) => {
                  const isSel = selectedOpt === idx;
                  const isRight = idx === currentQuestion.correctIndex;
                  let style = "bg-[#0A0F1C]/75 border-white/15 text-[#F1F5F9]";
                  if (submittedAnswer) {
                    if (isRight) style = "bg-[#34D399]/18 border-[#34D399] text-[#34D399]";
                    else if (isSel) style = "bg-[#F87171]/18 border-[#F87171] text-[#F87171]";
                  } else if (isSel) {
                    style = "bg-[#38BDF8]/20 border-[#38BDF8] text-[#38BDF8]";
                  }
                  return (
                    <button
                      key={idx}
                      type="button"
                      disabled={submittedAnswer}
                      onClick={() => setSelectedOpt(idx)}
                      className={`w-full text-start rounded-xl border px-3.5 py-2.5 text-sm font-semibold transition-colors cursor-pointer ${style}`}
                    >
                      {opt}
                    </button>
                  );
                })}
              </div>

              {submittedAnswer && selectedOpt !== currentQuestion.correctIndex && (
                <div className="rounded-xl bg-[#FBBF24]/12 border border-[#FBBF24]/35 p-3 space-y-1">
                  <p className="text-xs font-bold text-[#FBBF24]">{tr("remedial_hint")}</p>
                  <p className="text-xs text-[#F1F5F9]">
                    {isAr ? currentQuestion.remedialAr : currentQuestion.remedialEn}
                  </p>
                </div>
              )}

              <div className="flex justify-end gap-2">
                {!submittedAnswer ? (
                  <CosmicButton
                    type="button"
                    tone="cyan"
                    disabled={selectedOpt === null}
                    onClick={handleCheckAnswer}
                  >
                    {tr("submit_answer")}
                  </CosmicButton>
                ) : (
                  <CosmicButton type="button" tone="emerald" onClick={handleNextQuestion}>
                    {tr("next_question")}
                  </CosmicButton>
                )}
              </div>
            </CosmicCard>
          )}
        </div>
      )}
    </div>
  );
};
