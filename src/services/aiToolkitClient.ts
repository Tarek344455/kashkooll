import {
  AiOperationalBriefing,
  AppLanguage,
  AssistantMessage,
  CognitiveMeta,
  EmotionalPulse,
  EvaluationTargetType,
  GroupEntity,
  LessonRevisionDeck,
  ParentWeeklyDigest,
  PerformanceEvaluationEntity,
  QuizQuestion,
  ReceiptScanResult,
  SecretaryNoticeDraft,
  StudentAiMemory,
  StudentEntity,
  StudentOrProfile,
  SystemOperatingReport,
  TeacherLessonPlan,
  UserRole,
} from "../types/kashkool";
import { EgyptValidators } from "../core/utils/egyptValidators";
import {
  buildDirectCognitivePlan,
  directBrowserAi,
  sanitizeDirectOutput,
  type DirectChatMessage,
} from "./directAiClient";

function getBrowserActorId(): string {
  try {
    const key = "kashkool_browser_actor_id";
    let id = localStorage.getItem(key);
    if (!id) {
      id = `usr-${Math.random().toString(36).slice(2, 10)}-${Date.now().toString(36)}`;
      localStorage.setItem(key, id);
    }
    return id;
  } catch {
    return "usr-ephemeral";
  }
}

async function postJson<T>(url: string, body: unknown): Promise<T> {
  const res = await fetch(url, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "x-kashkool-actor": getBrowserActorId(),
    },
    body: JSON.stringify(body),
  });
  const data = await res.json().catch(() => ({}));
  if (!res.ok) {
    throw new Error((data as { error?: string }).error || `Request failed (${res.status})`);
  }
  return data as T;
}

async function directJsonWithFallback<T>(params: {
  prompt: string;
  systemPrompt: string;
  temperature?: number;
  fallbackUrl: string;
  fallbackBody: unknown;
}): Promise<T> {
  try {
    return await postJson<T>(params.fallbackUrl, params.fallbackBody);
  } catch (serverErr) {
    try {
      const { data } = await directBrowserAi.chatJson<T>({
        messages: [{ role: "user", content: params.prompt }],
        systemPrompt: params.systemPrompt,
        temperature: params.temperature ?? 0.4,
      });
      return data;
    } catch {
      throw serverErr;
    }
  }
}

export const AiToolkitClient = {
  async fetchStudentMemory(studentId: string): Promise<StudentAiMemory> {
    const res = await fetch(`/api/ai/memory?studentId=${encodeURIComponent(studentId)}`, {
      headers: {
        "x-kashkool-actor": studentId,
        "x-kashkool-role": "student",
      },
    });
    const data = (await res.json().catch(() => ({}))) as { memory?: StudentAiMemory; error?: string };
    if (!res.ok || !data.memory) {
      throw new Error(data.error || "Could not load adaptive memory");
    }
    return data.memory;
  },

  async updateStudentMemory(
    studentId: string,
    patch: Partial<Pick<StudentAiMemory, "learningPace" | "preferredStyle" | "tonePreference" | "academicTrack" | "weakTopics">>
  ): Promise<StudentAiMemory> {
    const res = await fetch("/api/ai/memory", {
      method: "PUT",
      headers: {
        "Content-Type": "application/json",
        "x-kashkool-actor": studentId,
        "x-kashkool-role": "student",
      },
      body: JSON.stringify({ studentId, ...patch }),
    });
    const data = (await res.json().catch(() => ({}))) as { memory?: StudentAiMemory; error?: string };
    if (!res.ok || !data.memory) {
      throw new Error(data.error || "Could not update adaptive memory");
    }
    return data.memory;
  },

  async resetStudentMemory(studentId: string): Promise<StudentAiMemory> {
    const res = await fetch(`/api/ai/memory?studentId=${encodeURIComponent(studentId)}`, {
      method: "DELETE",
      headers: {
        "x-kashkool-actor": studentId,
        "x-kashkool-role": "student",
      },
    });
    const data = (await res.json().catch(() => ({}))) as { memory?: StudentAiMemory; error?: string };
    if (!res.ok || !data.memory) {
      throw new Error(data.error || "Could not reset adaptive memory");
    }
    return data.memory;
  },

  async streamStudyChat(params: {
    prompt: string;
    history: AssistantMessage[];
    photoDataUrl?: string | null;
    role: UserRole;
    subject: string;
    report: SystemOperatingReport;
    lang: AppLanguage;
    explicitMood?: EmotionalPulse | null;
    studentId?: string;
    memory?: StudentAiMemory | null;
    onMeta?: (meta: CognitiveMeta) => void;
    onChunk: (accumulated: string) => void;
  }): Promise<{ text: string; meta?: CognitiveMeta }> {
    const knapsackSummary =
      params.report.studyKnapsack.selectedItems
        .map((i) => (params.lang === AppLanguage.AR ? i.titleAr : i.titleEn))
        .join(", ") || (params.lang === AppLanguage.AR ? "لا توجد موضوعات متأخرة" : "No overdue topics");

    const hasPhoto = typeof params.photoDataUrl === "string" && params.photoDataUrl.trim().length > 0;
    const isAr = params.lang === AppLanguage.AR;
    const actorId = params.studentId ?? getBrowserActorId();

    const localPlan = buildDirectCognitivePlan({
      prompt: params.prompt,
      explicitMood: params.explicitMood,
      memory: params.memory,
      isArabic: isAr,
      subject: params.subject,
    });
    params.onMeta?.(localPlan.meta);

    if (localPlan.cheatingGuardReply) {
      params.onChunk(localPlan.cheatingGuardReply);
      void fetch("/api/ai/telemetry-ingest", {
        method: "POST",
        headers: { "Content-Type": "application/json", "x-kashkool-actor": actorId },
        body: JSON.stringify({
          studentId: actorId,
          subject: params.subject,
          emotion: localPlan.meta.emotion,
          lane: localPlan.meta.lane,
          modelId: "kashkool-cognitive-guard",
          providerId: "client-guard",
          ttftMs: 12,
          totalLatencyMs: 15,
          cheatingAttemptFlagged: true,
          promptInjectionFlagged: localPlan.promptInjectionFlagged,
          promptExcerpt: params.prompt,
          responseExcerpt: localPlan.cheatingGuardReply,
          strategyCode: `${localPlan.meta.emotion} -> ${localPlan.meta.lane}`,
        }),
      }).catch(() => undefined);
      return { text: localPlan.cheatingGuardReply, meta: localPlan.meta };
    }

    // Primary path: per-actor backend cognitive router (/api/ai/study-chat) with full memory vault,
    // Kilo/Groq/DeepSeek/OpenRouter/NVIDIA failover, and vision support.
    // Falls back to direct browser AI providers if the backend is unreachable.
    let res: Response | null = null;
    try {
      res = await fetch("/api/ai/study-chat", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "x-kashkool-actor": actorId,
        },
        body: JSON.stringify({
          prompt: params.prompt,
          history: params.history,
          photoDataUrl: params.photoDataUrl ?? null,
          role: params.role,
          subject: params.subject,
          knapsackSummary,
          certaintyScore: params.report.certaintyScorePercent,
          lang: params.lang,
          explicitMood: params.explicitMood ?? null,
          studentId: actorId,
        }),
      });
    } catch {
      res = null;
    }

    if ((!res || !res.ok) && !hasPhoto) {
      const langHint = isAr ? "Arabic (clear Egyptian empathetic style)" : "English";
      const contextualPrompt = [
        `Language: ${langHint}`,
        `User Role: ${params.role}`,
        `Lesson / Context: ${params.subject}`,
        `Verified 15-min Rescue Focus: ${knapsackSummary}`,
        "",
        "Question / Request:",
        params.prompt,
        "",
        "Respond warmly with numbered steps and a concise rule takeaway.",
      ].join("\n");

      const historyMessages: DirectChatMessage[] = params.history
        .slice(1)
        .slice(-6)
        .map((m) => ({
          role: m.fromUser ? "user" : "assistant",
          content: String(m.text ?? "").slice(0, 600),
        }));

      const directRes = await directBrowserAi.chat({
        messages: [...historyMessages, { role: "user", content: contextualPrompt }],
        systemPrompt: localPlan.systemPrompt,
        temperature: 0.55,
        onChunk: (accumulated) => params.onChunk(accumulated),
      });
      const cleanFinal = sanitizeDirectOutput(directRes.text);
      const enrichedMeta: CognitiveMeta = { ...localPlan.meta, ttftMs: directRes.ttftMs };
      params.onMeta?.(enrichedMeta);
      params.onChunk(cleanFinal);
      return { text: cleanFinal, meta: enrichedMeta };
    }

    if (!res) {
      throw new Error("Study helper backend unreachable.");
    }
    if (!res.ok) {
      const errBody = await res.json().catch(() => ({}));
      throw new Error((errBody as { error?: string }).error || `Assistant error (${res.status})`);
    }
    if (!res.body) {
      throw new Error("Streaming unsupported by browser response.");
    }

    const reader = res.body.getReader();
    const decoder = new TextDecoder();
    let buffer = "";
    let accumulated = "";
    let serverMeta: CognitiveMeta | undefined = localPlan.meta;

    while (true) {
      const { value, done } = await reader.read();
      if (done) break;
      buffer += decoder.decode(value, { stream: true });
      const lines = buffer.split(/\r?\n\r?\n/);
      buffer = lines.pop() ?? "";
      for (const line of lines) {
        const clean = line.replace(/^data:\s*/, "").trim();
        if (!clean) continue;
        const parsed = JSON.parse(clean) as {
          meta?: CognitiveMeta;
          chunk?: string;
          reset?: boolean;
          error?: string;
          done?: boolean;
          ttftMs?: number;
        };
        if (parsed.error) throw new Error(parsed.error);
        if (parsed.reset) {
          accumulated = "";
        }
        if (parsed.meta) {
          serverMeta = parsed.meta;
          params.onMeta?.(parsed.meta);
        }
        if (parsed.chunk) {
          accumulated += parsed.chunk;
          const visible = sanitizeDirectOutput(accumulated, true);
          if (visible) {
            params.onChunk(visible);
          }
        }
        if (parsed.done && typeof parsed.ttftMs === "number" && serverMeta) {
          serverMeta = { ...serverMeta, ttftMs: parsed.ttftMs };
          params.onMeta?.(serverMeta);
        }
      }
    }

    const safeFinal = sanitizeDirectOutput(accumulated);
    if (!accumulated.trim()) {
      throw new Error("Empty response from study helper.");
    }
    return { text: safeFinal, meta: serverMeta };
  },

  async generateAdaptiveQuiz(lessonTitle: string, lang: AppLanguage): Promise<QuizQuestion[]> {
    const langLabel = lang === AppLanguage.AR ? "Natural Egyptian Arabic (Thanaweya Amma style)" : "Clear English";
    const prompt = [
      `Generate 3 high-quality multiple-choice practice questions strictly focused on: "${lessonTitle}".`,
      `Output language: ${langLabel}.`,
      "Return ONLY valid JSON (no markdown fences or commentary) matching this exact schema:",
      JSON.stringify({
        questions: [
          {
            topicTag: "string",
            prompt: "string",
            formula: "ASCII/Unicode LTR math or physics expression",
            options: ["opt1", "opt2", "opt3", "opt4"],
            correctIndex: 0,
            remedial: "brief calm 1-sentence explanation hint",
          },
        ],
      }),
    ].join("\n");

    const data = await directJsonWithFallback<{
      questions?: Array<{
        topicTag?: string;
        prompt?: string;
        formula?: string;
        options?: string[];
        correctIndex?: number;
        remedial?: string;
      }>;
    }>({
      prompt,
      systemPrompt: "You are Kashkool's curriculum quiz author. Output valid JSON strictly following the requested schema.",
      temperature: 0.4,
      fallbackUrl: "/api/ai/adaptive-quiz",
      fallbackBody: { lessonTitle, lang },
    });

    const arr = data.questions ?? [];
    const parsed: QuizQuestion[] = arr
      .map((item, idx) => {
        const opts = (item.options ?? []).filter((o) => o && o.trim().length > 0).slice(0, 4);
        const qPrompt = (item.prompt ?? "").trim();
        if (!qPrompt || opts.length < 2) return null;
        const tag = (item.topicTag ?? "").trim() || lessonTitle;
        const hint = (item.remedial ?? "").trim();
        const correctIdx = Math.min(opts.length - 1, Math.max(0, Number(item.correctIndex ?? 0)));
        return {
          id: `ai-q-${Date.now()}-${idx}`,
          topicTagAr: tag,
          topicTagEn: tag,
          promptAr: qPrompt,
          promptEn: qPrompt,
          formula: (item.formula ?? "").trim() || "f(x)",
          options: opts,
          correctIndex: correctIdx,
          remedialAr: hint,
          remedialEn: hint,
        };
      })
      .filter((x): x is QuizQuestion => x !== null);

    if (parsed.length === 0) {
      throw new Error("Could not parse generated quiz questions.");
    }
    return parsed;
  },

  async scanPaymentReceipt(imageDataUrl: string, lang: AppLanguage): Promise<ReceiptScanResult> {
    // Vision requires multimodal model routed securely via per-actor backend
    const data = await postJson<Partial<ReceiptScanResult>>("/api/ai/scan-receipt", {
      imageDataUrl,
      lang,
    });
    const clarity =
      data.clarityStatus === "high" || data.clarityStatus === "low" ? data.clarityStatus : "medium";
    return {
      amountEgp: String(data.amountEgp ?? "").trim(),
      referenceNumber: String(data.referenceNumber ?? "").trim(),
      detectedChannelType: String(data.detectedChannelType ?? "unknown").trim(),
      clarityStatus: clarity,
      verificationNote: String(data.verificationNote ?? "").trim(),
    };
  },

  async generateLessonRevisionDeck(
    lessonTitle: string,
    lessonSummary: string,
    lang: AppLanguage
  ): Promise<LessonRevisionDeck> {
    const langLabel = lang === AppLanguage.AR ? "Natural Egyptian Arabic (Thanaweya Amma)" : "Clear English";
    const prompt = [
      `Output strictly in ${langLabel}.`,
      `Build a lightweight, high-retention 5-minute revision deck for:`,
      `Lesson: "${lessonTitle}"`,
      `Key Notes: "${lessonSummary}"`,
      "Include 4 active-recall flashcards (front + concise back), 2-3 common Egyptian exam traps, and 1 memorable hook.",
      "Return ONLY valid JSON matching:",
      JSON.stringify({
        lessonTitle: "string",
        memoryHook: "string",
        flashcards: [{ front: "string", back: "string" }],
        commonTraps: ["string"],
      }),
    ].join("\n");

    const data = await directJsonWithFallback<Partial<LessonRevisionDeck>>({
      prompt,
      systemPrompt: "You are Kashkool's Egyptian Thanaweya Amma revision designer. Respond only with valid JSON.",
      temperature: 0.5,
      fallbackUrl: "/api/ai/revision-deck",
      fallbackBody: { lessonTitle, lessonSummary, lang },
    });
    return {
      lessonTitle: data.lessonTitle ?? lessonTitle,
      memoryHook: data.memoryHook ?? "",
      flashcards: Array.isArray(data.flashcards) ? data.flashcards : [],
      commonTraps: Array.isArray(data.commonTraps) ? data.commonTraps : [],
    };
  },

  async composeParentWeeklyDigest(params: {
    student: StudentEntity;
    attendanceCount: number;
    weakTopics: string[];
    lang: AppLanguage;
    orProfile?: StudentOrProfile;
  }): Promise<ParentWeeklyDigest> {
    const { student, attendanceCount, weakTopics, lang, orProfile } = params;
    const langLabel = lang === AppLanguage.AR ? "Warm Egyptian Arabic (RTL)" : "Clear Warm English";
    const studentName = lang === AppLanguage.AR ? student.nameAr : student.nameEn;
    const wallet = EgyptValidators.formatPiasters(student.walletBalancePiasters, lang);
    const dues = EgyptValidators.formatPiasters(student.dueBalancePiasters, lang);
    const topics = weakTopics.length > 0 ? weakTopics.join(", ") : "All topics on track";
    const orLine = orProfile
      ? `OR Risk Tier: ${orProfile.riskTier} (score ${orProfile.riskScore}/100), Covered Sessions: ${orProfile.coveredSessions}, Suggested Top-up: ${EgyptValidators.formatPiasters(orProfile.recommendedInstallmentPiasters, lang)}`
      : "";

    const prompt = `Output strictly in ${langLabel} without any technical jargon.
Write a calm, trustworthy weekly digest for the parent of:
- Student: ${studentName}
- Subject Mastery: ${student.masteryPercent}%
- Streak Days: ${student.streakDays}
- Recorded Check-ins: ${attendanceCount}
- Wallet Balance: ${wallet} | Pending Dues: ${dues}
- Focus Topics: ${topics}
${orLine ? `- ${orLine}` : ""}

Produce: headline, weeklyNarrative, cheerMessage (ready to send to the student), and 1 practical homeSupportTip.`;

    const fullPrompt = [
      prompt,
      "",
      "Return ONLY valid JSON matching:",
      JSON.stringify({
        headline: "string",
        weeklyNarrative: "string",
        cheerMessage: "string",
        homeSupportTip: "string",
      }),
    ].join("\n");

    const data = await directJsonWithFallback<Partial<ParentWeeklyDigest>>({
      prompt: fullPrompt,
      systemPrompt: "You are Kashkool's calm Egyptian parent advisor. Respond only with valid JSON.",
      temperature: 0.5,
      fallbackUrl: "/api/ai/parent-digest",
      fallbackBody: { prompt },
    });
    return {
      headline: data.headline ?? "",
      weeklyNarrative: data.weeklyNarrative ?? "",
      cheerMessage: data.cheerMessage ?? "",
      homeSupportTip: data.homeSupportTip ?? "",
    };
  },

  async composeSecretaryNotice(params: {
    student: StudentEntity;
    groupName: string;
    lang: AppLanguage;
    orProfile?: StudentOrProfile;
  }): Promise<SecretaryNoticeDraft> {
    const { student, groupName, lang, orProfile } = params;
    const langLabel = lang === AppLanguage.AR ? "Polite Egyptian Arabic" : "Polite Clear English";
    const studentName = lang === AppLanguage.AR ? student.nameAr : student.nameEn;
    const dues = EgyptValidators.formatPiasters(student.dueBalancePiasters, lang);
    const wallet = EgyptValidators.formatPiasters(student.walletBalancePiasters, lang);
    const suggested = orProfile
      ? EgyptValidators.formatPiasters(orProfile.recommendedInstallmentPiasters, lang)
      : "";
    const statusContext = student.isBlocked
      ? "Account temporarily paused — ask parent/student to contact reception desk gently."
      : student.dueBalancePiasters > 0
        ? `Gentle, dignified reminder of pending balance (${dues}, optimal installment plan: ${suggested}) and next session in ${groupName}.`
        : `Positive attendance confirmation and warm welcome for next session in ${groupName} (wallet balance: ${wallet}).`;

    const prompt = `Output strictly in ${langLabel}.
Draft a short WhatsApp message (3-4 lines max) from Al-Nokhba Center reception desk regarding student "${studentName}".
Context: ${statusContext}
Keep tone respectful, calm, and Egyptian center authentic. Never expose technical terms.`;

    const fullPrompt = [
      prompt,
      "",
      "Return ONLY valid JSON matching:",
      JSON.stringify({ toneTag: "string", messageText: "string" }),
    ].join("\n");

    const data = await directJsonWithFallback<Partial<SecretaryNoticeDraft>>({
      prompt: fullPrompt,
      systemPrompt: "You draft polite Egyptian reception desk messages. Respond only with valid JSON.",
      temperature: 0.5,
      fallbackUrl: "/api/ai/secretary-notice",
      fallbackBody: { prompt },
    });
    return {
      toneTag: data.toneTag ?? "",
      messageText: data.messageText ?? "",
    };
  },

  async generateTeacherLessonPlan(params: {
    group: GroupEntity;
    avgMasteryPercent: number;
    lang: AppLanguage;
    report?: SystemOperatingReport | null;
  }): Promise<TeacherLessonPlan> {
    const { group, avgMasteryPercent, lang, report } = params;
    const langLabel =
      lang === AppLanguage.AR ? "Natural Egyptian Arabic (Thanaweya Amma teacher style)" : "Clear English";
    const groupTitle = lang === AppLanguage.AR ? group.nameAr : group.nameEn;
    const subject = lang === AppLanguage.AR ? group.subjectAr : group.subjectEn;
    const orContext = report
      ? `Hall Balance Score: ${report.groupAllocation.balanceScorePercent}%, Safety Margin: ${report.financialCertainty.marginOfSafetyPercent}%, Resource Status: ${report.resourceConflict.summaryEn}`
      : "";

    const prompt = `Output strictly in ${langLabel}.
Create a practical 90-minute session execution plan & tiered homework for:
- Group: ${groupTitle}
- Subject: ${subject}
- Enrolled Students: ${group.enrolled}/${group.capacity}
- Average Group Mastery: ${avgMasteryPercent}%
${orContext ? `- ${orContext}` : ""}

Include 4 pacingSteps with minute blocks, 2 basicHomework items, 2 challengeHomework problems, and 2 assistantChecklist items.`;

    const fullPrompt = [
      prompt,
      "",
      "Return ONLY valid JSON matching:",
      JSON.stringify({
        topicTitle: "string",
        pacingSteps: ["string"],
        basicHomework: ["string"],
        challengeHomework: ["string"],
        assistantChecklist: ["string"],
      }),
    ].join("\n");

    const data = await directJsonWithFallback<Partial<TeacherLessonPlan>>({
      prompt: fullPrompt,
      systemPrompt: "You are Kashkool's instructional pacing planner. Respond only with valid JSON.",
      temperature: 0.5,
      fallbackUrl: "/api/ai/teacher-plan",
      fallbackBody: { prompt },
    });
    return {
      topicTitle: data.topicTitle ?? groupTitle,
      pacingSteps: Array.isArray(data.pacingSteps) ? data.pacingSteps : [],
      basicHomework: Array.isArray(data.basicHomework) ? data.basicHomework : [],
      challengeHomework: Array.isArray(data.challengeHomework) ? data.challengeHomework : [],
      assistantChecklist: Array.isArray(data.assistantChecklist) ? data.assistantChecklist : [],
    };
  },

  async generateOperationalBriefing(
    report: SystemOperatingReport,
    role: UserRole,
    lang: AppLanguage
  ): Promise<AiOperationalBriefing> {
    const langLabel = lang === AppLanguage.AR ? "Natural Egyptian Commercial Arabic (RTL)" : "Clear English";
    const netFormatted = EgyptValidators.formatPiasters(report.financialCertainty.netPayoutPiasters, lang);
    const prompt = `Output strictly in ${langLabel}.
Role: ${role}
Exact Verified Operations Research Metrics (DO NOT alter these numbers):
- Operational Certainty Index: ${report.certaintyScorePercent}%
- Hall Utilization: ${report.groupAllocation.utilizationPercent}% (${report.groupAllocation.totalEnrolled}/${report.groupAllocation.totalCapacity} seats)
- Recommended Seat Shift: ${report.groupAllocation.recommendedSeatShift}
- Break-Even Attendance: ${report.financialCertainty.breakEvenAttendance} vs Attended: ${report.financialCertainty.attendedCount} (Safety Margin: ${report.financialCertainty.marginOfSafetyPercent}%)
- Net Teacher Payout: ${netFormatted}
- Ledger Balanced: ${report.financialCertainty.ledgerBalanced}
- Queue Lanes: ${report.queueDispatch.activeLanes}, Expected Wait: ${report.queueDispatch.expectedWaitSeconds}s
- Study Knapsack 15-min Optimal Gain: +${report.studyKnapsack.guaranteedGainPercent}%
- Hall/Resource Status: ${report.resourceConflict.summaryEn}

Summarize the single best decision and 2-3 immediate trust-building actions for this user role without using technical jargon.`;

    const fullPrompt = [
      prompt,
      "",
      "Return ONLY valid JSON matching:",
      JSON.stringify({
        headline: "string",
        confidenceStatement: "string",
        topDecision: "string",
        nextActionSteps: ["string"],
        trustGuarantee: "string",
      }),
    ].join("\n");

    const data = await directJsonWithFallback<Partial<AiOperationalBriefing>>({
      prompt: fullPrompt,
      systemPrompt:
        "You are Kashkool's Operations Advisor. Never alter the exact numbers provided. Respond only with valid JSON.",
      temperature: 0.4,
      fallbackUrl: "/api/ai/operational-briefing",
      fallbackBody: { prompt },
    });
    return {
      headline: data.headline ?? "",
      confidenceStatement: data.confidenceStatement ?? "",
      topDecision: data.topDecision ?? "",
      nextActionSteps: Array.isArray(data.nextActionSteps) ? data.nextActionSteps : [],
      trustGuarantee: data.trustGuarantee ?? "",
    };
  },

  async evaluateStudentPerformance(params: {
    student: StudentEntity;
    groupName: string;
    attendedSessionsCount: number;
    completedLessonsCount: number;
    weakTopicTitles: string[];
    lang: AppLanguage;
  }): Promise<PerformanceEvaluationEntity> {
    const { student, groupName, attendedSessionsCount, completedLessonsCount, weakTopicTitles, lang } = params;
    const langLabel = lang === AppLanguage.AR ? "Natural Egyptian Arabic (RTL)" : "Clear English";
    const studentName = lang === AppLanguage.AR ? student.nameAr : student.nameEn;
    const walletFormatted = EgyptValidators.formatPiasters(student.walletBalancePiasters, lang);
    const duesFormatted = EgyptValidators.formatPiasters(student.dueBalancePiasters, lang);
    const weakList = weakTopicTitles.length > 0 ? weakTopicTitles.join(", ") : "None";

    const prompt = `Output strictly in ${langLabel}.
Evaluate STUDENT academic & commitment performance based ONLY on these verified Kashkool records:
- Student Name: ${studentName}
- Group: ${groupName}
- Current Mastery Score: ${student.masteryPercent}%
- Attendance Streak Days: ${student.streakDays}
- Recorded Check-ins: ${attendedSessionsCount}
- Completed Digital Lessons: ${completedLessonsCount}
- Pending Remedial Topics: ${weakList}
- Session Wallet Balance: ${walletFormatted} (Pending Dues: ${duesFormatted})

Provide an encouraging, transparent, evidence-backed evaluation with concrete strengths, constructive growth areas, and immediate next steps.`;

    const fullPrompt = [
      prompt,
      "",
      "Return ONLY valid JSON matching:",
      JSON.stringify({
        overallScore: 88,
        trustBadge: "string",
        analyticalSummary: "string",
        instantFeedback: "string",
        strengths: ["string"],
        improvementAreas: ["string"],
        nextActionPlan: ["string"],
        trustVerificationNote: "string",
      }),
    ].join("\n");

    const raw = await directJsonWithFallback<{
      overallScore?: number;
      trustBadge?: string;
      analyticalSummary?: string;
      instantFeedback?: string;
      strengths?: string[];
      improvementAreas?: string[];
      nextActionPlan?: string[];
      trustVerificationNote?: string;
    }>({
      prompt: fullPrompt,
      systemPrompt:
        "You are Kashkool's Academic Evaluation & Trust Specialist in Egypt. Never use buzzwords like AI, LLM, bot, API, or pricing jargon. Always cite exact verified figures provided in the prompt. Respond only with valid JSON.",
      temperature: 0.4,
      fallbackUrl: "/api/ai/evaluate",
      fallbackBody: { prompt },
    });

    return {
      id: `eval-student-${student.id}`,
      targetId: student.id,
      targetName: studentName,
      targetType: EvaluationTargetType.STUDENT,
      languageCode: lang,
      overallScore: Math.min(100, Math.max(40, Number(raw.overallScore ?? 82))),
      trustBadge: (raw.trustBadge ?? "").trim(),
      analyticalSummary: (raw.analyticalSummary ?? "").trim(),
      instantFeedback: (raw.instantFeedback ?? "").trim(),
      strengths: Array.isArray(raw.strengths) ? raw.strengths : [],
      improvementAreas: Array.isArray(raw.improvementAreas) ? raw.improvementAreas : [],
      nextActionPlan: Array.isArray(raw.nextActionPlan) ? raw.nextActionPlan : [],
      trustVerificationNote: (raw.trustVerificationNote ?? "").trim(),
      evaluatedAtMillis: Date.now(),
    };
  },

  async evaluateTeacherPerformance(params: {
    teacherLabel: string;
    report: SystemOperatingReport;
    studentCount: number;
    avgStudentMastery: number;
    pendingReceiptsCount: number;
    lang: AppLanguage;
  }): Promise<PerformanceEvaluationEntity> {
    const { teacherLabel, report, studentCount, avgStudentMastery, pendingReceiptsCount, lang } = params;
    const langLabel = lang === AppLanguage.AR ? "Natural Egyptian Arabic (RTL)" : "Clear English";
    const netFormatted = EgyptValidators.formatPiasters(report.financialCertainty.netPayoutPiasters, lang);

    const prompt = `Output strictly in ${langLabel}.
Evaluate TEACHER & EDUCATIONAL CENTER performance based ONLY on these verified Kashkool records:
- Teacher / Center: ${teacherLabel}
- Total Enrolled Students: ${studentCount} (Average Mastery: ${avgStudentMastery}%)
- Hall Utilization: ${report.groupAllocation.utilizationPercent}% (${report.groupAllocation.totalEnrolled}/${report.groupAllocation.totalCapacity} seats)
- Today's Attendance: ${report.financialCertainty.attendedCount} vs Break-Even: ${report.financialCertainty.breakEvenAttendance} (Safety Margin: ${report.financialCertainty.marginOfSafetyPercent}%)
- Net Verified Payout: ${netFormatted} (Ledger Balanced: ${report.financialCertainty.ledgerBalanced})
- Hall & Resource Readiness: ${report.resourceConflict.summaryEn}
- Operational Certainty Index: ${report.certaintyScorePercent}%
- Pending Payment Receipts Queue: ${pendingReceiptsCount}

Provide an analytical, transparent evaluation highlighting instructional impact, operational discipline, hall management, and trust-building next steps.`;

    const fullPrompt = [
      prompt,
      "",
      "Return ONLY valid JSON matching:",
      JSON.stringify({
        overallScore: 88,
        trustBadge: "string",
        analyticalSummary: "string",
        instantFeedback: "string",
        strengths: ["string"],
        improvementAreas: ["string"],
        nextActionPlan: ["string"],
        trustVerificationNote: "string",
      }),
    ].join("\n");

    const raw = await directJsonWithFallback<{
      overallScore?: number;
      trustBadge?: string;
      analyticalSummary?: string;
      instantFeedback?: string;
      strengths?: string[];
      improvementAreas?: string[];
      nextActionPlan?: string[];
      trustVerificationNote?: string;
    }>({
      prompt: fullPrompt,
      systemPrompt:
        "You are Kashkool's Academic Evaluation & Trust Specialist in Egypt. Never use buzzwords like AI, LLM, bot, API, or pricing jargon. Always cite exact verified figures provided in the prompt. Respond only with valid JSON.",
      temperature: 0.4,
      fallbackUrl: "/api/ai/evaluate",
      fallbackBody: { prompt },
    });

    return {
      id: "eval-teacher-teacher-center",
      targetId: "teacher-center",
      targetName: teacherLabel,
      targetType: EvaluationTargetType.TEACHER,
      languageCode: lang,
      overallScore: Math.min(100, Math.max(40, Number(raw.overallScore ?? 88))),
      trustBadge: (raw.trustBadge ?? "").trim(),
      analyticalSummary: (raw.analyticalSummary ?? "").trim(),
      instantFeedback: (raw.instantFeedback ?? "").trim(),
      strengths: Array.isArray(raw.strengths) ? raw.strengths : [],
      improvementAreas: Array.isArray(raw.improvementAreas) ? raw.improvementAreas : [],
      nextActionPlan: Array.isArray(raw.nextActionPlan) ? raw.nextActionPlan : [],
      trustVerificationNote: (raw.trustVerificationNote ?? "").trim(),
      evaluatedAtMillis: Date.now(),
    };
  },

  async explainMistake(params: {
    topicTag: string;
    questionPrompt: string;
    wrongAnswer: string;
    correctAnswer: string;
    lang: AppLanguage;
  }): Promise<{ whyMistakeHappens: string; stepByStepFix: string[]; goldenRule: string }> {
    const langLabel = params.lang === AppLanguage.AR ? "Clear Egyptian Arabic (Thanaweya Amma)" : "Clear English";
    const prompt = [
      `Output strictly in ${langLabel}.`,
      `Topic: ${params.topicTag}`,
      `Question: ${params.questionPrompt}`,
      `Student's Wrong Choice: ${params.wrongAnswer}`,
      `Correct Answer: ${params.correctAnswer}`,
      "Return ONLY valid JSON matching:",
      JSON.stringify({
        whyMistakeHappens: "1-2 sentences explaining the trap",
        stepByStepFix: ["step 1", "step 2", "step 3"],
        goldenRule: "1 crisp rule to remember in exams",
      }),
    ].join("\n");

    const data = await directJsonWithFallback<{
      whyMistakeHappens?: string;
      stepByStepFix?: string[];
      goldenRule?: string;
    }>({
      prompt,
      systemPrompt: "You are Kashkool's Mistake Bank Tutor in Egypt. Respond only with valid JSON.",
      temperature: 0.4,
      fallbackUrl: "/api/ai/mistake-explain",
      fallbackBody: params,
    });
    return {
      whyMistakeHappens: String(data.whyMistakeHappens ?? "").trim(),
      stepByStepFix: Array.isArray(data.stepByStepFix) ? data.stepByStepFix : [],
      goldenRule: String(data.goldenRule ?? "").trim(),
    };
  },

  async generateExamDraft(params: {
    subject: string;
    topic: string;
    questionCount?: number;
    lang: AppLanguage;
  }): Promise<{
    titleAr: string;
    titleEn: string;
    questions: Array<{
      topicTagAr: string;
      topicTagEn: string;
      promptAr: string;
      promptEn: string;
      formula?: string;
      options: string[];
      correctIndex: number;
      points: number;
      remedialAr: string;
      remedialEn: string;
    }>;
  }> {
    const langLabel = params.lang === AppLanguage.AR ? "Natural Egyptian Arabic (Thanaweya Amma)" : "Clear English";
    const count = Math.min(8, Math.max(2, Number(params.questionCount) || 4));
    const prompt = [
      `Output strictly in ${langLabel}.`,
      `Create ${count} high-precision Egyptian Thanaweya Amma exam questions for Subject "${params.subject}" on Topic "${params.topic}".`,
      "Return ONLY valid JSON matching:",
      JSON.stringify({
        titleAr: "string",
        titleEn: "string",
        questions: [
          {
            topicTagAr: "string",
            topicTagEn: "string",
            promptAr: "string",
            promptEn: "string",
            formula: "ASCII math/physics expression",
            options: ["opt1", "opt2", "opt3", "opt4"],
            correctIndex: 0,
            points: 2,
            remedialAr: "brief explanation in Arabic",
            remedialEn: "brief explanation in English",
          },
        ],
      }),
    ].join("\n");

    return directJsonWithFallback({
      prompt,
      systemPrompt: "You are Kashkool's official Thanaweya Amma exam author. Output ONLY valid JSON.",
      temperature: 0.4,
      fallbackUrl: "/api/ai/exam-generator",
      fallbackBody: params,
    });
  },
};
