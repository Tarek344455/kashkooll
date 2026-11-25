import {
  AiOperationalBriefing,
  AppLanguage,
  AssistantMessage,
  EvaluationTargetType,
  GroupEntity,
  LessonRevisionDeck,
  ParentWeeklyDigest,
  PerformanceEvaluationEntity,
  QuizQuestion,
  ReceiptScanResult,
  SecretaryNoticeDraft,
  StudentEntity,
  StudentOrProfile,
  SystemOperatingReport,
  TeacherLessonPlan,
  UserRole,
} from "../types/kashkool";
import { EgyptValidators } from "../core/utils/egyptValidators";

async function postJson<T>(url: string, body: unknown): Promise<T> {
  const res = await fetch(url, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(body),
  });
  const data = await res.json().catch(() => ({}));
  if (!res.ok) {
    throw new Error((data as { error?: string }).error || `Request failed (${res.status})`);
  }
  return data as T;
}

export const AiToolkitClient = {
  async streamStudyChat(params: {
    prompt: string;
    history: AssistantMessage[];
    photoDataUrl?: string | null;
    role: UserRole;
    subject: string;
    report: SystemOperatingReport;
    lang: AppLanguage;
    onChunk: (accumulated: string) => void;
  }): Promise<string> {
    const knapsackSummary =
      params.report.studyKnapsack.selectedItems
        .map((i) => (params.lang === AppLanguage.AR ? i.titleAr : i.titleEn))
        .join(", ") || (params.lang === AppLanguage.AR ? "لا توجد موضوعات متأخرة" : "No overdue topics");

    const res = await fetch("/api/ai/study-chat", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        prompt: params.prompt,
        history: params.history,
        photoDataUrl: params.photoDataUrl ?? null,
        role: params.role,
        subject: params.subject,
        knapsackSummary,
        certaintyScore: params.report.certaintyScorePercent,
        lang: params.lang,
      }),
    });

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

    while (true) {
      const { value, done } = await reader.read();
      if (done) break;
      buffer += decoder.decode(value, { stream: true });
      const lines = buffer.split("\n\n");
      buffer = lines.pop() ?? "";
      for (const line of lines) {
        const clean = line.replace(/^data:\s*/, "").trim();
        if (!clean) continue;
        const parsed = JSON.parse(clean) as { chunk?: string; error?: string; done?: boolean };
        if (parsed.error) throw new Error(parsed.error);
        if (parsed.chunk) {
          accumulated += parsed.chunk;
          params.onChunk(accumulated);
        }
      }
    }

    if (!accumulated.trim()) {
      throw new Error("Empty response from study helper.");
    }
    return accumulated;
  },

  async generateAdaptiveQuiz(lessonTitle: string, lang: AppLanguage): Promise<QuizQuestion[]> {
    const data = await postJson<{
      questions?: Array<{
        topicTag?: string;
        prompt?: string;
        formula?: string;
        options?: string[];
        correctIndex?: number;
        remedial?: string;
      }>;
    }>("/api/ai/adaptive-quiz", { lessonTitle, lang });

    const arr = data.questions ?? [];
    const parsed: QuizQuestion[] = arr
      .map((item, idx) => {
        const opts = (item.options ?? []).filter((o) => o && o.trim().length > 0).slice(0, 4);
        const prompt = (item.prompt ?? "").trim();
        if (!prompt || opts.length < 2) return null;
        const tag = (item.topicTag ?? "").trim() || lessonTitle;
        const hint = (item.remedial ?? "").trim();
        const correctIdx = Math.min(opts.length - 1, Math.max(0, Number(item.correctIndex ?? 0)));
        return {
          id: `ai-q-${Date.now()}-${idx}`,
          topicTagAr: tag,
          topicTagEn: tag,
          promptAr: prompt,
          promptEn: prompt,
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
    const data = await postJson<Partial<LessonRevisionDeck>>("/api/ai/revision-deck", {
      lessonTitle,
      lessonSummary,
      lang,
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

    const data = await postJson<Partial<ParentWeeklyDigest>>("/api/ai/parent-digest", { prompt });
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

    const data = await postJson<Partial<SecretaryNoticeDraft>>("/api/ai/secretary-notice", { prompt });
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

    const data = await postJson<Partial<TeacherLessonPlan>>("/api/ai/teacher-plan", { prompt });
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

    const data = await postJson<Partial<AiOperationalBriefing>>("/api/ai/operational-briefing", { prompt });
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

    const raw = await postJson<{
      overallScore?: number;
      trustBadge?: string;
      analyticalSummary?: string;
      instantFeedback?: string;
      strengths?: string[];
      improvementAreas?: string[];
      nextActionPlan?: string[];
      trustVerificationNote?: string;
    }>("/api/ai/evaluate", { prompt });

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

    const raw = await postJson<{
      overallScore?: number;
      trustBadge?: string;
      analyticalSummary?: string;
      instantFeedback?: string;
      strengths?: string[];
      improvementAreas?: string[];
      nextActionPlan?: string[];
      trustVerificationNote?: string;
    }>("/api/ai/evaluate", { prompt });

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
};
