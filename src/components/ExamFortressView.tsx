import React, { useCallback, useEffect, useMemo, useRef, useState } from "react";
import {
  AlertTriangle,
  Award,
  CheckCircle2,
  Clock,
  FilePlus2,
  Lock,
  Play,
  Printer,
  RefreshCw,
  ShieldAlert,
  ShieldCheck,
  Sparkles,
  Users,
  WifiOff,
} from "lucide-react";
import { useKashkool } from "../context/KashkoolContext";
import { AiToolkitClient } from "../services/aiToolkitClient";
import {
  AppLanguage,
  ExamAttemptMonitorDto,
  ExamResultDto,
  ExamSummaryDto,
  SanitizedExamAttemptDto,
  UserRole,
} from "../types/kashkool";
import {
  CosmicButton,
  CosmicCard,
  DynamicQrCode,
  EmptyState,
  ModalDialog,
  ShimmerCard,
  StatusBadge,
} from "./CosmicUi";

interface DraftQuestion {
  topicTagAr: string;
  topicTagEn: string;
  promptAr: string;
  promptEn: string;
  formula: string;
  options: [string, string, string, string];
  correctIndex: number;
  points: number;
  remedialAr: string;
  remedialEn: string;
}

function getPersistentDeviceId(): string {
  try {
    const existing = localStorage.getItem("kashkool_device_id");
    if (existing) return existing;
    const generated = `dev-${crypto.randomUUID().slice(0, 12)}`;
    localStorage.setItem("kashkool_device_id", generated);
    return generated;
  } catch {
    return "dev-web-client";
  }
}

function formatCountdown(msRemaining: number): string {
  const totalSec = Math.max(0, Math.floor(msRemaining / 1000));
  const mins = Math.floor(totalSec / 60);
  const secs = totalSec % 60;
  return `${String(mins).padStart(2, "0")}:${String(secs).padStart(2, "0")}`;
}

export const ExamFortressView: React.FC<{
  role: UserRole;
  onOpenAssistant?: (prompt: string, subject?: string) => void;
}> = ({ role, onOpenAssistant }) => {
  const {
    language,
    activeStudent,
    linkedParentStudent,
    groups,
    userLabel,
    isOnline,
    addMistakeEntries,
    pushParentAlert,
    showSnackbar,
    tr,
  } = useKashkool();

  const isAr = language === AppLanguage.AR;
  const isStaff = role === UserRole.TEACHER || role === UserRole.SECRETARY;
  const effectiveStudent =
    role === UserRole.PARENT ? linkedParentStudent : activeStudent;
  const actorId = isStaff ? userLabel || "teacher-1" : effectiveStudent?.id || "stu-1";

  const authHeaders = useMemo(
    () => ({
      "Content-Type": "application/json",
      "x-kashkool-role": role,
      "x-kashkool-actor": actorId,
    }),
    [role, actorId]
  );

  const [exams, setExams] = useState<ExamSummaryDto[]>([]);
  const [loadingList, setLoadingList] = useState(true);
  const [listError, setListError] = useState<string | null>(null);

  // Active locked student attempt
  const [activeAttempt, setActiveAttempt] = useState<SanitizedExamAttemptDto | null>(null);
  const [answers, setAnswers] = useState<Record<string, number>>({});
  const [serverOffsetMs, setServerOffsetMs] = useState(0);
  const [nowMs, setNowMs] = useState(() => Date.now());
  const [submitting, setSubmitting] = useState(false);
  const [startingExamId, setStartingExamId] = useState<string | null>(null);
  const [offlineQueuedCount, setOfflineQueuedCount] = useState(0);
  const [securityBanner, setSecurityBanner] = useState<string | null>(null);
  const [resultView, setResultView] = useState<ExamResultDto | null>(null);
  const recordedResultAttemptIds = useRef<Set<string>>(new Set());

  // Exam-Mode Focus Override: freeze decorative floating motion while taking an exam
  useEffect(() => {
    window.dispatchEvent(
      new CustomEvent("kashkool-exam-focus", { detail: { active: Boolean(activeAttempt) } })
    );
    return () => {
      window.dispatchEvent(new CustomEvent("kashkool-exam-focus", { detail: { active: false } }));
    };
  }, [activeAttempt]);

  // Staff: Publish New Exam form
  const [createOpen, setCreateOpen] = useState(false);
  const [formTitleAr, setFormTitleAr] = useState("");
  const [formSubject, setFormSubject] = useState("الرياضيات البحتة");
  const [formTopic, setFormTopic] = useState("التفاضل وتطبيقاته");
  const [formGroupId, setFormGroupId] = useState(groups[0]?.id ?? "grp-math-3sec");
  const [formDuration, setFormDuration] = useState("20");
  const [formPassPercent, setFormPassPercent] = useState("60");
  const [formMaxViolations, setFormMaxViolations] = useState("3");
  const [draftQuestions, setDraftQuestions] = useState<DraftQuestion[]>([
    {
      topicTagAr: "قاعدة السلسلة",
      topicTagEn: "Chain Rule",
      promptAr: "إذا كانت ص = (٣س - ١)²، أوجد ص'(١).",
      promptEn: "If y = (3x - 1)^2, find y'(1).",
      formula: "y = (3x - 1)^2",
      options: ["6", "12", "4", "18"],
      correctIndex: 1,
      points: 2,
      remedialAr: "ص' = ٢(٣س - ١) × ٣ = ٦(٣س - ١). عند س=١ تكون ٦ × ٢ = ١٢.",
      remedialEn: "y' = 2(3x - 1) * 3 = 6(3x - 1). At x = 1, y'(1) = 12.",
    },
  ]);
  const [aiGenerating, setAiGenerating] = useState(false);
  const [creatingExam, setCreatingExam] = useState(false);
  const [createError, setCreateError] = useState<string | null>(null);

  // Staff: Live Proctoring Console
  const [proctorExamId, setProctorExamId] = useState<string | null>(null);
  const [proctorAttempts, setProctorAttempts] = useState<ExamAttemptMonitorDto[]>([]);
  const [loadingProctor, setLoadingProctor] = useState(false);
  const [lockingAttemptId, setLockingAttemptId] = useState<string | null>(null);

  const loadExams = useCallback(async () => {
    setLoadingList(true);
    setListError(null);
    try {
      const res = await fetch("/api/exams", { headers: authHeaders });
      const data = (await res.json()) as { exams?: ExamSummaryDto[]; error?: string };
      if (!res.ok) throw new Error(data.error || "Failed to load exams");
      setExams(data.exams ?? []);
    } catch (err) {
      setListError(err instanceof Error ? err.message : "Could not reach Exam Shield");
    } finally {
      setLoadingList(false);
    }
  }, [authHeaders]);

  useEffect(() => {
    void loadExams();
  }, [loadExams]);

  const recordMistakesAndAlert = useCallback(
    (res: ExamResultDto) => {
      if (recordedResultAttemptIds.current.has(res.attemptId)) return;
      recordedResultAttemptIds.current.add(res.attemptId);

      if (res.mistakes.length > 0 && role === UserRole.STUDENT) {
        addMistakeEntries(
          "exam",
          res.mistakes.map((m) => ({
            topicTagAr: m.topicTagAr,
            topicTagEn: m.topicTagEn,
            questionPromptAr: m.promptAr,
            questionPromptEn: m.promptEn,
            wrongAnswer: m.wrongAnswer,
            correctAnswer: m.correctAnswer,
            remedialAr: m.remedialAr,
            remedialEn: m.remedialEn,
          }))
        );
      }
      if (effectiveStudent && role === UserRole.STUDENT) {
        pushParentAlert({
          studentId: effectiveStudent.id,
          kind: "exam",
          titleAr: `نتيجة امتحان: ${res.examTitleAr}`,
          titleEn: `Exam Result: ${res.examTitleEn}`,
          bodyAr: `حصل ${effectiveStudent.nameAr} على ${res.percentScore}% (الترتيب ${res.rank} من ${res.totalGraded}).`,
          bodyEn: `${effectiveStudent.nameEn} scored ${res.percentScore}% (Rank ${res.rank}/${res.totalGraded}).`,
        });
      }
    },
    [addMistakeEntries, effectiveStudent, pushParentAlert, role]
  );

  // Offline answer queue helpers
  const queueStorageKey = activeAttempt
    ? `kashkool_offline_exam_answers_${activeAttempt.attemptId}`
    : null;

  const flushOfflineAnswers = useCallback(
    async (attemptId: string): Promise<void> => {
      const key = `kashkool_offline_exam_answers_${attemptId}`;
      try {
        const raw = localStorage.getItem(key);
        if (!raw) return;
        const queued = JSON.parse(raw) as Record<string, number>;
        const entries = Object.entries(queued);
        if (entries.length === 0) return;

        const remaining: Record<string, number> = {};
        for (const [qId, optIdx] of entries) {
          try {
            const res = await fetch(`/api/exams/attempts/${attemptId}/answer`, {
              method: "POST",
              headers: authHeaders,
              body: JSON.stringify({
                studentId: actorId,
                questionId: qId,
                selectedDisplayIndex: optIdx,
                deviceId: getPersistentDeviceId(),
              }),
            });
            if (!res.ok && res.status >= 500) {
              remaining[qId] = optIdx;
            }
          } catch {
            remaining[qId] = optIdx;
          }
        }

        if (Object.keys(remaining).length === 0) {
          localStorage.removeItem(key);
          setOfflineQueuedCount(0);
        } else {
          localStorage.setItem(key, JSON.stringify(remaining));
          setOfflineQueuedCount(Object.keys(remaining).length);
        }
      } catch {
        // Ignore storage failure
      }
    },
    [actorId, authHeaders]
  );

  const handleEnterExam = async (examId: string) => {
    setStartingExamId(examId);
    try {
      const deviceId = getPersistentDeviceId();
      const studentName = effectiveStudent
        ? isAr
          ? effectiveStudent.nameAr
          : effectiveStudent.nameEn
        : userLabel || "طالب كشكول";
      const res = await fetch(`/api/exams/${examId}/start`, {
        method: "POST",
        headers: authHeaders,
        body: JSON.stringify({
          studentId: actorId,
          studentName,
          studentCode: effectiveStudent?.qrActivationCode ?? actorId.toUpperCase(),
          deviceId,
        }),
      });
      const data = (await res.json()) as SanitizedExamAttemptDto & { error?: string };
      if (!res.ok) throw new Error(data.error || "Could not start exam");

      setServerOffsetMs(data.serverNowMillis - Date.now());
      setNowMs(Date.now());
      setSecurityBanner(null);

      if (data.status !== "in_progress") {
        // Already submitted or locked -> open certified result directly
        const resResult = await fetch(`/api/exams/attempts/${data.attemptId}/result`, {
          headers: authHeaders,
        });
        const graded = (await resResult.json()) as ExamResultDto;
        if (resResult.ok) {
          setResultView(graded);
          recordMistakesAndAlert(graded);
        }
        return;
      }

      // Restore any cached offline answers
      let mergedAnswers = { ...data.answersByQuestion };
      try {
        const cachedRaw = localStorage.getItem(`kashkool_offline_exam_answers_${data.attemptId}`);
        if (cachedRaw) {
          const cached = JSON.parse(cachedRaw) as Record<string, number>;
          mergedAnswers = { ...mergedAnswers, ...cached };
          setOfflineQueuedCount(Object.keys(cached).length);
        }
      } catch {
        // Ignore
      }

      setAnswers(mergedAnswers);
      setActiveAttempt(data);
      // Gracefully request fullscreen without failing if iframe restricts it
      document.documentElement.requestFullscreen?.().catch(() => undefined);
    } catch (err) {
      showSnackbar(err instanceof Error ? err.message : "Exam start error");
    } finally {
      setStartingExamId(null);
    }
  };

  const handleViewResult = async (attemptId: string) => {
    try {
      const res = await fetch(`/api/exams/attempts/${attemptId}/result`, {
        headers: authHeaders,
      });
      const data = (await res.json()) as ExamResultDto & { error?: string };
      if (!res.ok) throw new Error(data.error || "Result unavailable");
      setResultView(data);
      recordMistakesAndAlert(data);
    } catch (err) {
      showSnackbar(err instanceof Error ? err.message : "Could not load result");
    }
  };

  const handleSubmitExam = useCallback(async () => {
    if (!activeAttempt || submitting) return;
    setSubmitting(true);
    try {
      await flushOfflineAnswers(activeAttempt.attemptId);
      const res = await fetch(`/api/exams/attempts/${activeAttempt.attemptId}/submit`, {
        method: "POST",
        headers: authHeaders,
        body: JSON.stringify({ studentId: actorId }),
      });
      const graded = (await res.json()) as ExamResultDto & { error?: string };
      if (!res.ok) throw new Error(graded.error || "Submit failed");
      if (document.fullscreenElement) {
        document.exitFullscreen?.().catch(() => undefined);
      }
      setActiveAttempt(null);
      setResultView(graded);
      recordMistakesAndAlert(graded);
      void loadExams();
    } catch (err) {
      showSnackbar(err instanceof Error ? err.message : "Submit error");
    } finally {
      setSubmitting(false);
    }
  }, [activeAttempt, actorId, authHeaders, flushOfflineAnswers, loadExams, recordMistakesAndAlert, showSnackbar, submitting]);

  const handleSelectOption = async (questionId: string, optionIdx: number) => {
    if (!activeAttempt || activeAttempt.status !== "in_progress") return;
    setAnswers((prev) => ({ ...prev, [questionId]: optionIdx }));

    const persistOffline = () => {
      if (!queueStorageKey) return;
      try {
        const raw = localStorage.getItem(queueStorageKey);
        const cur = raw ? (JSON.parse(raw) as Record<string, number>) : {};
        cur[questionId] = optionIdx;
        localStorage.setItem(queueStorageKey, JSON.stringify(cur));
        setOfflineQueuedCount(Object.keys(cur).length);
      } catch {
        // Ignore
      }
    };

    if (!isOnline) {
      persistOffline();
      return;
    }

    try {
      const res = await fetch(`/api/exams/attempts/${activeAttempt.attemptId}/answer`, {
        method: "POST",
        headers: authHeaders,
        body: JSON.stringify({
          studentId: actorId,
          questionId,
          selectedDisplayIndex: optionIdx,
          deviceId: getPersistentDeviceId(),
        }),
      });
      if (res.status === 409) {
        // Server deadline expired -> fetch result
        void handleSubmitExam();
      } else if (!res.ok) {
        persistOffline();
      }
    } catch {
      persistOffline();
    }
  };

  // Flush offline answers automatically whenever internet reconnects
  useEffect(() => {
    if (isOnline && activeAttempt && offlineQueuedCount > 0) {
      void flushOfflineAnswers(activeAttempt.attemptId);
    }
  }, [isOnline, activeAttempt, offlineQueuedCount, flushOfflineAnswers]);

  // Countdown ticker synced with server clock offset
  useEffect(() => {
    if (!activeAttempt || activeAttempt.status !== "in_progress") return;
    const id = window.setInterval(() => {
      const estimatedServerNow = Date.now() + serverOffsetMs;
      setNowMs(Date.now());
      if (estimatedServerNow >= activeAttempt.hardDeadlineAtMillis) {
        void handleSubmitExam();
      }
    }, 1000);
    return () => window.clearInterval(id);
  }, [activeAttempt, serverOffsetMs, handleSubmitExam]);

  // Active Exam Lockdown Telemetry + Periodic 10s Heartbeat
  useEffect(() => {
    if (!activeAttempt || activeAttempt.status !== "in_progress") return;
    let lastViolationTs = 0;

    const sendSignal = async (
      eventType:
        | "heartbeat"
        | "tab_switch"
        | "window_blur"
        | "fullscreen_exit"
        | "copy_attempt"
        | "paste_attempt"
        | "screen_capture_key"
        | "dev_tools",
      detail: string
    ) => {
      if (eventType !== "heartbeat") {
        const now = Date.now();
        if (now - lastViolationTs < 1200) return;
        lastViolationTs = now;
      }
      try {
        const res = await fetch(`/api/exams/attempts/${activeAttempt.attemptId}/heartbeat`, {
          method: "POST",
          headers: authHeaders,
          body: JSON.stringify({
            studentId: actorId,
            eventType,
            detail,
            deviceId: getPersistentDeviceId(),
          }),
        });
        const data = (await res.json()) as {
          violationsCount: number;
          maxViolations: number;
          autoLocked: boolean;
          result?: ExamResultDto;
        };
        if (res.ok) {
          setActiveAttempt((prev) =>
            prev ? { ...prev, violationsCount: data.violationsCount } : prev
          );
          if (eventType !== "heartbeat") {
            setSecurityBanner(
              isAr
                ? `تنبيه نزاهة (${data.violationsCount}/${data.maxViolations}): ${detail}`
                : `Integrity alert (${data.violationsCount}/${data.maxViolations}): ${detail}`
            );
          }
          if (data.autoLocked && data.result) {
            setActiveAttempt(null);
            setResultView(data.result);
            recordMistakesAndAlert(data.result);
            showSnackbar(tr("exam_locked_banner"));
            void loadExams();
          }
        }
      } catch {
        // Network drops shouldn't crash active exam
      }
    };

    const onVisibility = () => {
      if (document.visibilityState === "hidden") {
        void sendSignal("tab_switch", isAr ? "مغادرة تبويب الامتحان" : "Left exam tab");
      }
    };
    const onBlur = () => {
      void sendSignal("window_blur", isAr ? "خروج التركيز عن نافذة الامتحان" : "Window focus lost");
    };
    const onCopyOrCut = (e: ClipboardEvent) => {
      e.preventDefault();
      void sendSignal("copy_attempt", isAr ? "محاولة نسخ محتوى الامتحان" : "Copy blocked");
    };
    const onPaste = (e: ClipboardEvent) => {
      e.preventDefault();
      void sendSignal("paste_attempt", isAr ? "محاولة لصق داخل الامتحان" : "Paste blocked");
    };
    const onContext = (e: MouseEvent) => {
      e.preventDefault();
    };
    const onKeyDown = (e: KeyboardEvent) => {
      const devCombo =
        e.key === "F12" ||
        ((e.ctrlKey || e.metaKey) && e.shiftKey && ["I", "J", "C", "i", "j", "c"].includes(e.key)) ||
        ((e.ctrlKey || e.metaKey) && ["u", "U", "c", "C"].includes(e.key));
      if (devCombo) {
        e.preventDefault();
        void sendSignal("dev_tools", `Blocked shortcut ${e.key}`);
      } else if (e.key === "PrintScreen") {
        void sendSignal("screen_capture_key", "PrintScreen pressed");
      }
    };
    const onFullscreenChange = () => {
      if (!document.fullscreenElement) {
        void sendSignal("fullscreen_exit", isAr ? "الخروج من ملء الشاشة" : "Exited fullscreen");
      }
    };

    document.addEventListener("visibilitychange", onVisibility);
    window.addEventListener("blur", onBlur);
    document.addEventListener("copy", onCopyOrCut);
    document.addEventListener("cut", onCopyOrCut);
    document.addEventListener("paste", onPaste);
    document.addEventListener("contextmenu", onContext);
    window.addEventListener("keydown", onKeyDown);
    document.addEventListener("fullscreenchange", onFullscreenChange);

    const heartbeatId = window.setInterval(() => {
      void sendSignal("heartbeat", "keepalive");
    }, 10_000);

    return () => {
      document.removeEventListener("visibilitychange", onVisibility);
      window.removeEventListener("blur", onBlur);
      document.removeEventListener("copy", onCopyOrCut);
      document.removeEventListener("cut", onCopyOrCut);
      document.removeEventListener("paste", onPaste);
      document.removeEventListener("contextmenu", onContext);
      window.removeEventListener("keydown", onKeyDown);
      document.removeEventListener("fullscreenchange", onFullscreenChange);
      window.clearInterval(heartbeatId);
    };
  }, [activeAttempt, actorId, authHeaders, isAr, loadExams, recordMistakesAndAlert, showSnackbar, tr]);

  // Staff Proctoring Console Loader
  const loadProctorAttempts = useCallback(
    async (examId: string) => {
      setProctorExamId(examId);
      setLoadingProctor(true);
      try {
        const res = await fetch(`/api/exams/${examId}/attempts`, { headers: authHeaders });
        const data = (await res.json()) as { attempts?: ExamAttemptMonitorDto[]; error?: string };
        if (!res.ok) throw new Error(data.error || "Failed to load proctor feed");
        setProctorAttempts(data.attempts ?? []);
      } catch (err) {
        showSnackbar(err instanceof Error ? err.message : "Proctor error");
      } finally {
        setLoadingProctor(false);
      }
    },
    [authHeaders, showSnackbar]
  );

  const handleForceLock = async (attemptId: string) => {
    setLockingAttemptId(attemptId);
    try {
      const res = await fetch(`/api/exams/attempts/${attemptId}/lock`, {
        method: "POST",
        headers: authHeaders,
      });
      if (!res.ok) {
        const err = (await res.json()) as { error?: string };
        throw new Error(err.error || "Lock failed");
      }
      showSnackbar(isAr ? "تم إغلاق وتسليم محاولة الطالب" : "Student attempt locked & graded");
      if (proctorExamId) void loadProctorAttempts(proctorExamId);
    } catch (err) {
      showSnackbar(err instanceof Error ? err.message : "Lock error");
    } finally {
      setLockingAttemptId(null);
    }
  };

  // Staff AI Exam Question Generator
  const handleAiGenerateDraft = async () => {
    if (!formTopic.trim() || aiGenerating) return;
    setAiGenerating(true);
    setCreateError(null);
    try {
      const draft = await AiToolkitClient.generateExamDraft({
        subject: formSubject,
        topic: formTopic,
        questionCount: 4,
        lang: language,
      });
      if (draft.titleAr && !formTitleAr.trim()) {
        setFormTitleAr(draft.titleAr);
      }
      const mapped: DraftQuestion[] = draft.questions.map((q) => {
        const opts = [...q.options, "—", "—", "—", "—"].slice(0, 4) as [
          string,
          string,
          string,
          string,
        ];
        return {
          topicTagAr: q.topicTagAr || formTopic,
          topicTagEn: q.topicTagEn || formTopic,
          promptAr: q.promptAr,
          promptEn: q.promptEn || q.promptAr,
          formula: q.formula || "",
          options: opts,
          correctIndex: Math.min(3, Math.max(0, Number(q.correctIndex) || 0)),
          points: Math.max(1, Number(q.points) || 2),
          remedialAr: q.remedialAr || "",
          remedialEn: q.remedialEn || q.remedialAr || "",
        };
      });
      if (mapped.length > 0) setDraftQuestions(mapped);
    } catch (err) {
      setCreateError(err instanceof Error ? err.message : "Draft generation failed");
    } finally {
      setAiGenerating(false);
    }
  };

  const handlePublishExam = async () => {
    setCreateError(null);
    if (!formTitleAr.trim() || draftQuestions.length === 0) {
      setCreateError(tr("validation_required"));
      return;
    }
    for (const q of draftQuestions) {
      if (!q.promptAr.trim() || q.options.filter((o) => o.trim()).length < 2) {
        setCreateError(tr("validation_required"));
        return;
      }
    }

    setCreatingExam(true);
    try {
      const res = await fetch("/api/exams", {
        method: "POST",
        headers: authHeaders,
        body: JSON.stringify({
          tenantId: "demo-centre",
          groupId: formGroupId,
          titleAr: formTitleAr.trim(),
          titleEn: formTitleAr.trim(),
          subjectAr: formSubject.trim(),
          subjectEn: formSubject.trim(),
          durationMinutes: Number(formDuration) || 20,
          passPercent: Number(formPassPercent) || 60,
          maxViolations: Number(formMaxViolations) || 3,
          questions: draftQuestions,
        }),
      });
      const data = (await res.json()) as { error?: string };
      if (!res.ok) throw new Error(data.error || "Failed to publish exam");
      setCreateOpen(false);
      setFormTitleAr("");
      showSnackbar(isAr ? "تم نشر الامتحان المحصّن بنجاح" : "Fortress Exam published");
      void loadExams();
    } catch (err) {
      setCreateError(err instanceof Error ? err.message : "Publish failed");
    } finally {
      setCreatingExam(false);
    }
  };

  // ===========================================================================
  // RENDER 1: ACTIVE LOCKED EXAM ROOM (Zero-Cheat Shield + Forensic Watermark)
  // ===========================================================================
  if (activeAttempt) {
    const remainingMs = Math.max(
      0,
      activeAttempt.hardDeadlineAtMillis - (nowMs + serverOffsetMs)
    );
    const answeredCount = Object.keys(answers).length;
    const totalCount = activeAttempt.questions.length;

    return (
      <div className="relative space-y-4 select-none">
        {/* Diagonal Tiled Forensic Watermark Overlay */}
        <div
          aria-hidden="true"
          className="pointer-events-none fixed inset-0 z-20 overflow-hidden opacity-[0.07]"
        >
          <div className="grid grid-cols-3 gap-12 -rotate-12 scale-125 py-12">
            {Array.from({ length: 12 }).map((_, i) => (
              <div key={i} className="text-xs font-mono-tabular text-[#38BDF8] text-center whitespace-nowrap">
                {activeAttempt.forensicWatermark} · {new Date(nowMs).toLocaleTimeString()}
              </div>
            ))}
          </div>
        </div>

        {/* Sticky Exam Shield Header */}
        <CosmicCard tone={activeAttempt.violationsCount > 0 ? "amber" : "cyan"} className="sticky top-16 z-30 space-y-2.5">
          <div className="flex flex-wrap items-center justify-between gap-3">
            <div className="space-y-0.5">
              <div className="flex items-center gap-2">
                <Lock className="w-4 h-4 text-[#38BDF8]" />
                <h2 className="text-sm sm:text-base font-extrabold text-[#F1F5F9]">
                  {isAr ? activeAttempt.exam.titleAr : activeAttempt.exam.titleEn}
                </h2>
              </div>
              <p className="text-[11px] text-[#94A3B8]">{tr("exam_lockdown_warning")}</p>
            </div>

            <div className="flex flex-wrap items-center gap-2">
              <div className="rounded-xl bg-[#0A0F1C] border border-[#38BDF8]/40 px-3 py-1.5 text-center">
                <p className="text-[10px] text-[#94A3B8]">{tr("exam_timer_label")}</p>
                <p
                  dir="ltr"
                  className={`text-sm font-extrabold font-mono-tabular tabular-nums ${
                    remainingMs < 120_000 ? "text-[#F87171]" : "text-[#38BDF8]"
                  }`}
                >
                  {formatCountdown(remainingMs)}
                </p>
              </div>

              <div className="rounded-xl bg-[#0A0F1C] border border-white/15 px-3 py-1.5 text-center">
                <p className="text-[10px] text-[#94A3B8]">{tr("exam_violations_label")}</p>
                <p
                  dir="ltr"
                  className={`text-sm font-extrabold tabular-nums ${
                    activeAttempt.violationsCount >= activeAttempt.maxViolations - 1
                      ? "text-[#F87171]"
                      : "text-[#FBBF24]"
                  }`}
                >
                  {activeAttempt.violationsCount} / {activeAttempt.maxViolations}
                </p>
              </div>
            </div>
          </div>

          {!isOnline && (
            <div className="flex items-center gap-2 rounded-lg bg-[#FBBF24]/15 border border-[#FBBF24]/40 px-3 py-1.5 text-xs text-[#FBBF24]">
              <WifiOff className="w-3.5 h-3.5 shrink-0" />
              <span>
                {isAr
                  ? `وضع انقطاع الشبكة: تم حفظ ${offlineQueuedCount} إجابة محلياً وسيتم إرسالها فور عودة الاتصال.`
                  : `Offline queue active: ${offlineQueuedCount} answers cached locally.`}
              </span>
            </div>
          )}

          {securityBanner && (
            <div className="flex items-center gap-2 rounded-lg bg-[#F87171]/15 border border-[#F87171]/40 px-3 py-1.5 text-xs text-[#F87171]">
              <ShieldAlert className="w-4 h-4 shrink-0" />
              <span>{securityBanner}</span>
            </div>
          )}
        </CosmicCard>

        {/* Questions List */}
        <div className="space-y-3 relative z-10">
          {activeAttempt.questions.map((q, qIdx) => {
            const selectedIdx = answers[q.id];
            return (
              <CosmicCard key={q.id} tone={selectedIdx !== undefined ? "emerald" : "slate"} className="space-y-3">
                <div className="flex items-center justify-between gap-2 text-xs">
                  <div className="flex items-center gap-2">
                    <span className="w-6 h-6 rounded-lg bg-[#38BDF8]/20 text-[#38BDF8] font-extrabold flex items-center justify-center tabular-nums">
                      {qIdx + 1}
                    </span>
                    <StatusBadge tone="gold" label={isAr ? q.topicTagAr : q.topicTagEn} />
                  </div>
                  <span className="text-[#94A3B8] tabular-nums">
                    {q.points} {isAr ? "درجة" : "pts"}
                  </span>
                </div>

                <h3 className="text-sm sm:text-base font-bold text-[#F1F5F9]">
                  {isAr ? q.promptAr : q.promptEn}
                </h3>

                {q.formula && (
                  <div
                    dir="ltr"
                    className="rounded-xl bg-[#0A0F1C] border border-white/10 px-3 py-2 text-xs font-mono-tabular text-[#38BDF8] text-center"
                  >
                    {q.formula}
                  </div>
                )}

                <div className="grid grid-cols-1 sm:grid-cols-2 gap-2">
                  {q.options.map((opt, optIdx) => {
                    const isSelected = selectedIdx === optIdx;
                    return (
                      <button
                        key={optIdx}
                        type="button"
                        onClick={() => void handleSelectOption(q.id, optIdx)}
                        className={`rounded-xl border px-3.5 py-2.5 text-start text-sm font-semibold transition-colors cursor-pointer ${
                          isSelected
                            ? "bg-[#38BDF8]/20 border-[#38BDF8] text-[#38BDF8]"
                            : "bg-[#0A0F1C]/75 border-white/15 text-[#F1F5F9] hover:border-white/30"
                        }`}
                      >
                        {opt}
                      </button>
                    );
                  })}
                </div>
              </CosmicCard>
            );
          })}
        </div>

        <CosmicCard tone="emerald" className="flex flex-wrap items-center justify-between gap-3 relative z-10">
          <span className="text-xs sm:text-sm text-[#94A3B8] tabular-nums">
            {isAr
              ? `تمت الإجابة على ${answeredCount} من ${totalCount} سؤال`
              : `Answered ${answeredCount} of ${totalCount} questions`}
          </span>
          <CosmicButton
            type="button"
            tone="emerald"
            loading={submitting}
            icon={<CheckCircle2 className="w-4 h-4" />}
            onClick={() => void handleSubmitExam()}
          >
            {submitting ? tr("exam_submitting") : tr("exam_submit_cta")}
          </CosmicButton>
        </CosmicCard>
      </div>
    );
  }

  // ===========================================================================
  // RENDER 2: EXAM LOBBY + TEACHER PROCTORING & CREATOR
  // ===========================================================================
  return (
    <div className="space-y-4">
      <div className="flex flex-wrap items-center justify-between gap-2">
        <div className="flex items-center gap-2">
          <ShieldCheck className="w-5 h-5 text-[#38BDF8]" />
          <h3 className="text-base font-extrabold text-[#F1F5F9]">{tr("exam_fortress_tab")}</h3>
          <StatusBadge tone="emerald" label={tr("exam_shield_badge")} />
        </div>

        <div className="flex flex-wrap items-center gap-2">
          <CosmicButton
            type="button"
            tone="slate"
            variant="outline"
            className="text-xs py-1.5 px-3"
            icon={<RefreshCw className="w-3.5 h-3.5" />}
            onClick={() => void loadExams()}
          >
            {isAr ? "تحديث" : "Refresh"}
          </CosmicButton>
          {isStaff && (
            <CosmicButton
              type="button"
              tone="gold"
              className="text-xs py-1.5 px-3"
              icon={<FilePlus2 className="w-3.5 h-3.5" />}
              onClick={() => {
                setCreateError(null);
                setCreateOpen(true);
              }}
            >
              {tr("exam_create_cta")}
            </CosmicButton>
          )}
        </div>
      </div>

      {loadingList ? (
        <ShimmerCard lines={4} />
      ) : listError ? (
        <CosmicCard tone="crimson" className="space-y-2">
          <p className="text-xs text-[#F87171]">{listError}</p>
          <CosmicButton type="button" tone="crimson" variant="outline" onClick={() => void loadExams()}>
            {isAr ? "إعادة المحاولة" : "Retry"}
          </CosmicButton>
        </CosmicCard>
      ) : exams.length === 0 ? (
        <EmptyState
          icon={<ShieldCheck className="w-8 h-8" />}
          message={isAr ? "لا توجد امتحانات منشورة حالياً." : "No fortress exams published yet."}
        />
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
          {exams.map((item) => {
            const att = item.myAttempt;
            const finalized = att && att.status !== "in_progress";
            return (
              <CosmicCard
                key={item.exam.id}
                tone={att?.status === "locked_violation" ? "crimson" : finalized ? "emerald" : "cyan"}
                className="space-y-3"
              >
                <div className="flex items-start justify-between gap-2">
                  <div>
                    <p className="text-xs text-[#38BDF8] font-semibold">
                      {isAr ? item.exam.subjectAr : item.exam.subjectEn}
                    </p>
                    <h4 className="text-sm font-extrabold text-[#F1F5F9]">
                      {isAr ? item.exam.titleAr : item.exam.titleEn}
                    </h4>
                  </div>
                  {att ? (
                    <StatusBadge
                      tone={
                        att.status === "locked_violation"
                          ? "crimson"
                          : att.status === "in_progress"
                            ? "amber"
                            : "emerald"
                      }
                      label={
                        att.status === "in_progress"
                          ? isAr
                            ? "قيد التنفيذ"
                            : "In Progress"
                          : att.status === "locked_violation"
                            ? isAr
                              ? "مغلق أمنياً"
                              : "Locked"
                            : `${att.percentScore}%`
                      }
                    />
                  ) : (
                    <StatusBadge
                      tone="gold"
                      label={`${item.exam.passPercent}% ${isAr ? "للنجاح" : "Pass"}`}
                    />
                  )}
                </div>

                <div className="flex flex-wrap items-center gap-3 text-xs text-[#94A3B8] tabular-nums">
                  <span className="flex items-center gap-1">
                    <Clock className="w-3.5 h-3.5" />
                    {item.exam.durationMinutes} {isAr ? "دقيقة" : "min"}
                  </span>
                  <span>
                    {item.questionCount} {isAr ? "سؤال" : "Q"} ({item.totalPoints}{" "}
                    {isAr ? "درجة" : "pts"})
                  </span>
                  <span>
                    {isAr ? `حد التنبيهات: ${item.exam.maxViolations}` : `Max Alerts: ${item.exam.maxViolations}`}
                  </span>
                </div>

                <div className="flex flex-wrap gap-2">
                  {role === UserRole.STUDENT && (
                    <>
                      {finalized && att ? (
                        <CosmicButton
                          type="button"
                          tone="emerald"
                          className="text-xs py-1.5 px-3"
                          icon={<Award className="w-3.5 h-3.5" />}
                          onClick={() => void handleViewResult(att.attemptId)}
                        >
                          {tr("exam_view_result")}
                        </CosmicButton>
                      ) : (
                        <CosmicButton
                          type="button"
                          tone="cyan"
                          loading={startingExamId === item.exam.id}
                          className="text-xs py-1.5 px-3"
                          icon={<Play className="w-3.5 h-3.5" />}
                          onClick={() => void handleEnterExam(item.exam.id)}
                        >
                          {att?.status === "in_progress" ? tr("exam_resume_cta") : tr("exam_start_cta")}
                        </CosmicButton>
                      )}
                    </>
                  )}

                  {role === UserRole.PARENT && att && att.status !== "in_progress" && (
                    <CosmicButton
                      type="button"
                      tone="emerald"
                      variant="outline"
                      className="text-xs py-1.5 px-3"
                      icon={<Award className="w-3.5 h-3.5" />}
                      onClick={() => void handleViewResult(att.attemptId)}
                    >
                      {tr("exam_view_result")}
                    </CosmicButton>
                  )}

                  {isStaff && (
                    <CosmicButton
                      type="button"
                      tone="purple"
                      variant="outline"
                      className="text-xs py-1.5 px-3"
                      icon={<Users className="w-3.5 h-3.5" />}
                      onClick={() => void loadProctorAttempts(item.exam.id)}
                    >
                      {tr("exam_proctor_console")}
                    </CosmicButton>
                  )}
                </div>
              </CosmicCard>
            );
          })}
        </div>
      )}

      {/* Staff Live Proctoring Console */}
      {isStaff && proctorExamId && (
        <CosmicCard tone="purple" className="space-y-3">
          <div className="flex flex-wrap items-center justify-between gap-2">
            <div className="flex items-center gap-2">
              <ShieldAlert className="w-4 h-4 text-[#A78BFA]" />
              <h4 className="text-sm font-bold text-[#F1F5F9]">{tr("exam_proctor_console")}</h4>
            </div>
            <CosmicButton
              type="button"
              tone="purple"
              variant="subtle"
              loading={loadingProctor}
              className="text-xs py-1 px-2.5"
              icon={<RefreshCw className="w-3.5 h-3.5" />}
              onClick={() => void loadProctorAttempts(proctorExamId)}
            >
              {isAr ? "تحديث اللجنة" : "Refresh Feed"}
            </CosmicButton>
          </div>

          {proctorAttempts.length === 0 ? (
            <p className="text-xs text-[#94A3B8]">
              {isAr ? "لم يبدأ أي طالب هذا الامتحان بعد." : "No student attempts recorded for this exam yet."}
            </p>
          ) : (
            <div className="space-y-2">
              {proctorAttempts.map((pa) => (
                <div
                  key={pa.attemptId}
                  className="rounded-xl bg-[#0A0F1C]/75 border border-white/10 p-3 flex flex-wrap items-center justify-between gap-3 text-xs"
                >
                  <div className="space-y-1">
                    <div className="flex items-center gap-2 flex-wrap">
                      <span className="font-bold text-[#F1F5F9]">{pa.studentName}</span>
                      <StatusBadge
                        tone={
                          pa.status === "locked_violation"
                            ? "crimson"
                            : pa.status === "in_progress"
                              ? "amber"
                              : "emerald"
                        }
                        label={pa.status}
                      />
                    </div>
                    <p className="text-[#94A3B8] tabular-nums">
                      {isAr ? "الأسئلة:" : "Progress:"} {pa.answeredCount}/{pa.totalQuestions} ·{" "}
                      {tr("exam_violations_label")}:{" "}
                      <span className={pa.violationsCount > 0 ? "text-[#F87171] font-bold" : ""}>
                        {pa.violationsCount}
                      </span>{" "}
                      · {pa.status !== "in_progress" ? `${pa.percentScore}%` : ""}
                    </p>
                    {pa.recentEvents.length > 0 && (
                      <p className="text-[11px] text-[#FBBF24]">
                        {pa.recentEvents.map((e) => e.detail).join(" · ")}
                      </p>
                    )}
                  </div>

                  {pa.status === "in_progress" && (
                    <CosmicButton
                      type="button"
                      tone="crimson"
                      variant="outline"
                      loading={lockingAttemptId === pa.attemptId}
                      className="text-xs py-1.5 px-2.5"
                      onClick={() => void handleForceLock(pa.attemptId)}
                    >
                      {tr("exam_force_lock")}
                    </CosmicButton>
                  )}
                </div>
              ))}
            </div>
          )}
        </CosmicCard>
      )}

      {/* Certified Result & Verifiable QR Certificate Modal */}
      <ModalDialog
        open={Boolean(resultView)}
        title={isAr ? resultView?.examTitleAr ?? "" : resultView?.examTitleEn ?? ""}
        onClose={() => setResultView(null)}
        maxWidthClass="max-w-2xl"
      >
        {resultView && (
          <div className="space-y-4">
            <div className="grid grid-cols-3 gap-2 text-center">
              <div className="rounded-xl bg-[#0A0F1C] p-3">
                <p className="text-[11px] text-[#94A3B8]">{isAr ? "الدرجة" : "Score"}</p>
                <p className="text-xl font-extrabold text-[#34D399] tabular-nums">
                  {resultView.percentScore}%
                </p>
              </div>
              <div className="rounded-xl bg-[#0A0F1C] p-3">
                <p className="text-[11px] text-[#94A3B8]">{isAr ? "الترتيب" : "Rank"}</p>
                <p className="text-xl font-extrabold text-[#38BDF8] tabular-nums">
                  #{resultView.rank} / {resultView.totalGraded}
                </p>
              </div>
              <div className="rounded-xl bg-[#0A0F1C] p-3">
                <p className="text-[11px] text-[#94A3B8]">{tr("exam_violations_label")}</p>
                <p
                  className={`text-xl font-extrabold tabular-nums ${
                    resultView.violationsCount > 0 ? "text-[#FBBF24]" : "text-[#34D399]"
                  }`}
                >
                  {resultView.violationsCount}
                </p>
              </div>
            </div>

            {resultView.certificate && (
              <div className="rounded-2xl bg-gradient-to-br from-[#0A0F1C] to-[#182238] border border-[#EAB308]/45 p-4 flex flex-col sm:flex-row items-center gap-4">
                <DynamicQrCode payload={resultView.certificate.qrPayload} size={110} />
                <div className="flex-1 space-y-1.5 text-center sm:text-start">
                  <StatusBadge tone="gold" label={tr("exam_certificate_title")} />
                  <h4 className="text-base font-extrabold text-[#F1F5F9]">
                    {resultView.certificate.studentName}
                  </h4>
                  <p className="text-xs text-[#94A3B8]">
                    {isAr ? resultView.certificate.examTitleAr : resultView.certificate.examTitleEn}
                  </p>
                  <p dir="ltr" className="text-[11px] font-mono-tabular text-[#38BDF8]">
                    HMAC: {resultView.certificate.certHash}
                  </p>
                  <CosmicButton
                    type="button"
                    tone="gold"
                    variant="outline"
                    className="text-xs py-1.5 px-3 mt-1"
                    icon={<Printer className="w-3.5 h-3.5" />}
                    onClick={() => window.print()}
                  >
                    {tr("exam_certificate_print")}
                  </CosmicButton>
                </div>
              </div>
            )}

            <div className="space-y-2">
              {resultView.breakdown.map((row, idx) => (
                <div
                  key={row.questionId}
                  className={`rounded-xl border p-3 text-xs space-y-1.5 ${
                    row.isCorrect
                      ? "bg-[#34D399]/10 border-[#34D399]/35"
                      : "bg-[#F87171]/10 border-[#F87171]/35"
                  }`}
                >
                  <div className="flex items-center justify-between gap-2">
                    <span className="font-bold text-[#F1F5F9]">
                      {idx + 1}. {isAr ? row.promptAr : row.promptEn}
                    </span>
                    <StatusBadge
                      tone={row.isCorrect ? "emerald" : "crimson"}
                      label={`${row.pointsEarned}/${row.maxPoints}`}
                    />
                  </div>
                  <p className="text-[#94A3B8]">
                    {isAr ? "إجابتك:" : "Your answer:"}{" "}
                    <span className="font-semibold text-[#F1F5F9]">{row.selectedOptionText ?? "—"}</span> ·{" "}
                    {isAr ? "الصحيحة:" : "Correct:"}{" "}
                    <span className="font-semibold text-[#34D399]">{row.correctOptionText}</span>
                  </p>
                  {!row.isCorrect && (
                    <div className="flex flex-wrap items-center justify-between gap-2 pt-1">
                      <p className="text-[#FBBF24]">{isAr ? row.remedialAr : row.remedialEn}</p>
                      {onOpenAssistant && (
                        <button
                          type="button"
                          onClick={() => {
                            setResultView(null);
                            onOpenAssistant(
                              isAr
                                ? `أخطأت في هذا السؤال: "${row.promptAr}" واخترت "${row.selectedOptionText ?? "بدون"}" بينما الصحيح هو "${row.correctOptionText}". اشرح لي الفكرة ببساطة.`
                                : `I missed "${row.promptEn}" (chose "${row.selectedOptionText ?? "none"}", correct "${row.correctOptionText}"). Explain please.`,
                              isAr ? row.topicTagAr : row.topicTagEn
                            );
                          }}
                          className="font-bold text-[#38BDF8] hover:underline cursor-pointer"
                        >
                          {tr("nav_assistant")}
                        </button>
                      )}
                    </div>
                  )}
                </div>
              ))}
            </div>
          </div>
        )}
      </ModalDialog>

      {/* Staff: Create New Fortress Exam Modal */}
      <ModalDialog
        open={createOpen}
        title={tr("exam_create_cta")}
        onClose={() => setCreateOpen(false)}
        maxWidthClass="max-w-2xl"
      >
        <div className="space-y-3">
          {createError && (
            <div className="flex items-center gap-2 rounded-xl bg-[#F87171]/15 border border-[#F87171]/40 px-3 py-2 text-xs text-[#F87171]">
              <AlertTriangle className="w-4 h-4 shrink-0" />
              <span>{createError}</span>
            </div>
          )}

          <div className="grid grid-cols-1 sm:grid-cols-2 gap-2.5">
            <div>
              <label className="block text-xs text-[#94A3B8] mb-1">
                {isAr ? "عنوان الامتحان" : "Exam Title"}
              </label>
              <input
                type="text"
                value={formTitleAr}
                onChange={(e) => setFormTitleAr(e.target.value)}
                placeholder={isAr ? "امتحان التفاضل الأسبوعي" : "Weekly Calculus Exam"}
                className="w-full rounded-xl bg-[#0A0F1C] border border-white/15 px-3 py-2 text-sm text-[#F1F5F9]"
              />
            </div>
            <div>
              <label className="block text-xs text-[#94A3B8] mb-1">{tr("groups_title")}</label>
              <select
                value={formGroupId}
                onChange={(e) => setFormGroupId(e.target.value)}
                className="w-full rounded-xl bg-[#0A0F1C] border border-white/15 px-3 py-2 text-sm text-[#F1F5F9]"
              >
                {groups.map((g) => (
                  <option key={g.id} value={g.id}>
                    {isAr ? g.nameAr : g.nameEn}
                  </option>
                ))}
              </select>
            </div>
          </div>

          <div className="grid grid-cols-2 sm:grid-cols-4 gap-2">
            <div>
              <label className="block text-xs text-[#94A3B8] mb-1">{isAr ? "المادة" : "Subject"}</label>
              <input
                type="text"
                value={formSubject}
                onChange={(e) => setFormSubject(e.target.value)}
                className="w-full rounded-xl bg-[#0A0F1C] border border-white/15 px-2.5 py-1.5 text-xs text-[#F1F5F9]"
              />
            </div>
            <div>
              <label className="block text-xs text-[#94A3B8] mb-1">{isAr ? "الموضوع" : "Topic"}</label>
              <input
                type="text"
                value={formTopic}
                onChange={(e) => setFormTopic(e.target.value)}
                className="w-full rounded-xl bg-[#0A0F1C] border border-white/15 px-2.5 py-1.5 text-xs text-[#F1F5F9]"
              />
            </div>
            <div>
              <label className="block text-xs text-[#94A3B8] mb-1">{isAr ? "المدة (د)" : "Mins"}</label>
              <input
                type="number"
                dir="ltr"
                value={formDuration}
                onChange={(e) => setFormDuration(e.target.value)}
                className="w-full rounded-xl bg-[#0A0F1C] border border-white/15 px-2.5 py-1.5 text-xs font-mono-tabular text-[#F1F5F9]"
              />
            </div>
            <div>
              <label className="block text-xs text-[#94A3B8] mb-1">
                {isAr ? "النجاح %" : "Pass %"}
              </label>
              <input
                type="number"
                dir="ltr"
                value={formPassPercent}
                onChange={(e) => setFormPassPercent(e.target.value)}
                className="w-full rounded-xl bg-[#0A0F1C] border border-white/15 px-2.5 py-1.5 text-xs font-mono-tabular text-[#F1F5F9]"
              />
            </div>
          </div>

          <div className="flex flex-wrap items-center justify-between gap-2">
            <div className="flex items-center gap-2 text-xs text-[#94A3B8]">
              <span>{isAr ? "أقصى مخالفات:" : "Max Violations:"}</span>
              <input
                type="number"
                dir="ltr"
                value={formMaxViolations}
                onChange={(e) => setFormMaxViolations(e.target.value)}
                className="w-16 rounded-lg bg-[#0A0F1C] border border-white/15 px-2 py-1 text-xs font-mono-tabular text-[#F1F5F9]"
              />
            </div>
            <CosmicButton
              type="button"
              tone="purple"
              variant="outline"
              loading={aiGenerating}
              className="text-xs py-1.5 px-3"
              icon={<Sparkles className="w-3.5 h-3.5" />}
              onClick={() => void handleAiGenerateDraft()}
            >
              {tr("exam_ai_generate_cta")}
            </CosmicButton>
          </div>

          {/* Question Drafts */}
          <div className="space-y-2.5 max-h-64 overflow-y-auto pe-1">
            {draftQuestions.map((q, qIdx) => (
              <div
                key={qIdx}
                className="rounded-xl bg-[#0A0F1C]/80 border border-white/10 p-3 space-y-2 text-xs"
              >
                <div className="flex items-center justify-between gap-2">
                  <span className="font-bold text-[#38BDF8]">Q{qIdx + 1}</span>
                  <select
                    value={q.correctIndex}
                    onChange={(e) =>
                      setDraftQuestions((prev) =>
                        prev.map((item, idx) =>
                          idx === qIdx ? { ...item, correctIndex: Number(e.target.value) } : item
                        )
                      )
                    }
                    className="rounded-lg bg-[#141D2F] border border-white/15 px-2 py-1 text-xs text-[#34D399]"
                  >
                    {q.options.map((_, oi) => (
                      <option key={oi} value={oi}>
                        {isAr ? `الصحيح: ${oi + 1}` : `Correct: #${oi + 1}`}
                      </option>
                    ))}
                  </select>
                </div>
                <input
                  type="text"
                  value={q.promptAr}
                  onChange={(e) =>
                    setDraftQuestions((prev) =>
                      prev.map((item, idx) =>
                        idx === qIdx ? { ...item, promptAr: e.target.value, promptEn: e.target.value } : item
                      )
                    )
                  }
                  placeholder={isAr ? "نص السؤال" : "Question prompt"}
                  className="w-full rounded-lg bg-[#141D2F] border border-white/10 px-2.5 py-1.5 text-xs text-[#F1F5F9]"
                />
                <div className="grid grid-cols-2 gap-1.5">
                  {q.options.map((opt, oi) => (
                    <input
                      key={oi}
                      type="text"
                      value={opt}
                      onChange={(e) =>
                        setDraftQuestions((prev) =>
                          prev.map((item, idx) => {
                            if (idx !== qIdx) return item;
                            const nextOpts = [...item.options] as [string, string, string, string];
                            nextOpts[oi] = e.target.value;
                            return { ...item, options: nextOpts };
                          })
                        )
                      }
                      placeholder={`${isAr ? "خيار" : "Option"} ${oi + 1}`}
                      className="rounded-lg bg-[#141D2F] border border-white/10 px-2 py-1 text-xs text-[#F1F5F9]"
                    />
                  ))}
                </div>
              </div>
            ))}
          </div>

          <div className="flex flex-wrap justify-between gap-2">
            <CosmicButton
              type="button"
              tone="slate"
              variant="outline"
              className="text-xs"
              onClick={() =>
                setDraftQuestions((prev) => [
                  ...prev,
                  {
                    topicTagAr: formTopic,
                    topicTagEn: formTopic,
                    promptAr: "",
                    promptEn: "",
                    formula: "",
                    options: ["", "", "", ""],
                    correctIndex: 0,
                    points: 2,
                    remedialAr: "",
                    remedialEn: "",
                  },
                ])
              }
            >
              + {isAr ? "إضافة سؤال" : "Add Question"}
            </CosmicButton>

            <CosmicButton
              type="button"
              tone="gold"
              loading={creatingExam}
              onClick={() => void handlePublishExam()}
            >
              {tr("submit")}
            </CosmicButton>
          </div>
        </div>
      </ModalDialog>
    </div>
  );
};
