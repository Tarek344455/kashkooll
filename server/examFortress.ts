import crypto from "node:crypto";
import { aegisSecurity } from "./aegisSecurity";

export interface ExamQuestionInput {
  id?: string;
  topicTagAr: string;
  topicTagEn: string;
  promptAr: string;
  promptEn: string;
  formula?: string;
  options: string[];
  correctIndex: number;
  points?: number;
  remedialAr: string;
  remedialEn: string;
}

export interface ExamQuestionStored {
  id: string;
  topicTagAr: string;
  topicTagEn: string;
  promptAr: string;
  promptEn: string;
  formula: string;
  options: string[];
  points: number;
}

export interface ExamQuestionKey {
  questionId: string;
  correctIndex: number;
  remedialAr: string;
  remedialEn: string;
}

export interface ExamDefinition {
  id: string;
  tenantId: string;
  groupId: string;
  titleAr: string;
  titleEn: string;
  subjectAr: string;
  subjectEn: string;
  durationMinutes: number;
  passPercent: number;
  maxViolations: number;
  isPublished: boolean;
  createdBy: string;
  createdAtMillis: number;
}

export interface SanitizedExamQuestion {
  id: string;
  topicTagAr: string;
  topicTagEn: string;
  promptAr: string;
  promptEn: string;
  formula: string;
  options: string[];
  points: number;
}

export type ExamViolationType =
  | "heartbeat"
  | "tab_switch"
  | "window_blur"
  | "fullscreen_exit"
  | "copy_attempt"
  | "paste_attempt"
  | "screen_capture_key"
  | "split_screen"
  | "dev_tools";

export interface ExamSecurityEvent {
  id: string;
  eventType: ExamViolationType;
  detail: string;
  occurredAtMillis: number;
}

export type ExamAttemptStatus = "in_progress" | "submitted" | "locked_violation" | "expired";

export interface ExamCertificate {
  id: string;
  attemptId: string;
  examId: string;
  studentId: string;
  studentName: string;
  examTitleAr: string;
  examTitleEn: string;
  percentScore: number;
  certHash: string;
  qrPayload: string;
  issuedAtMillis: number;
}

export interface GradedQuestionResult {
  questionId: string;
  topicTagAr: string;
  topicTagEn: string;
  promptAr: string;
  promptEn: string;
  selectedOptionText: string | null;
  correctOptionText: string;
  isCorrect: boolean;
  pointsEarned: number;
  maxPoints: number;
  remedialAr: string;
  remedialEn: string;
}

export interface ExamAttempt {
  id: string;
  examId: string;
  studentId: string;
  studentName: string;
  studentCode: string;
  deviceId: string;
  status: ExamAttemptStatus;
  questionOrder: string[];
  optionPermutations: Record<string, number[]>;
  answersByQuestion: Record<string, number>;
  violationsCount: number;
  securityEvents: ExamSecurityEvent[];
  forensicWatermark: string;
  startedAtMillis: number;
  hardDeadlineAtMillis: number;
  lastHeartbeatAtMillis: number;
  submittedAtMillis: number | null;
  scorePoints: number;
  maxPoints: number;
  percentScore: number;
  certificate: ExamCertificate | null;
}

export interface ExamResultPayload {
  attemptId: string;
  examId: string;
  examTitleAr: string;
  examTitleEn: string;
  studentId: string;
  studentName: string;
  status: ExamAttemptStatus;
  scorePoints: number;
  maxPoints: number;
  percentScore: number;
  passPercent: number;
  passed: boolean;
  rank: number;
  totalGraded: number;
  percentile: number;
  violationsCount: number;
  submittedAtMillis: number;
  certificate: ExamCertificate | null;
  breakdown: GradedQuestionResult[];
  mistakes: Array<{
    questionId: string;
    topicTagAr: string;
    topicTagEn: string;
    promptAr: string;
    promptEn: string;
    wrongAnswer: string;
    correctAnswer: string;
    remedialAr: string;
    remedialEn: string;
  }>;
}

function seededPrng(seedHex: string): () => number {
  let hash = crypto.createHash("sha256").update(seedHex).digest();
  let cursor = 0;
  return () => {
    if (cursor + 4 > hash.length) {
      hash = crypto.createHash("sha256").update(hash).digest();
      cursor = 0;
    }
    const val = hash.readUInt32BE(cursor);
    cursor += 4;
    return val / 0x100000000;
  };
}

function deterministicShuffle<T>(items: T[], rand: () => number): T[] {
  const arr = [...items];
  for (let i = arr.length - 1; i > 0; i--) {
    const j = Math.floor(rand() * (i + 1));
    const tmp = arr[i];
    arr[i] = arr[j];
    arr[j] = tmp;
  }
  return arr;
}

export class ExamFortressService {
  private readonly exams = new Map<string, ExamDefinition>();
  private readonly questionsByExam = new Map<string, ExamQuestionStored[]>();
  private readonly questionByIdByExam = new Map<string, Map<string, ExamQuestionStored>>();
  private readonly totalPointsByExam = new Map<string, number>();
  // STRICTLY SERVER-ONLY: never exposed to students while an attempt is in progress or in listings
  private readonly questionKeysByExam = new Map<string, Map<string, ExamQuestionKey>>();
  private readonly attempts = new Map<string, ExamAttempt>();
  private readonly attemptsByExam = new Map<string, ExamAttempt[]>();
  private readonly gradedScoreCountsByExam = new Map<string, Int32Array>();
  private readonly totalGradedByExam = new Map<string, number>();
  private readonly attemptByExamStudent = new Map<string, string>();
  private readonly certificates = new Map<string, ExamCertificate>();

  constructor() {
    this.seedDefaultExams();
  }

  private seedDefaultExams(): void {
    const now = Date.now();
    this.registerExamInternal({
      id: "exam-math-calc-1",
      tenantId: "demo-centre",
      groupId: "grp-math-3sec",
      titleAr: "امتحان تقييم التفاضل والتكامل — الوحدة الأولى",
      titleEn: "Calculus Unit 1 — Proctored Assessment",
      subjectAr: "الرياضيات البحتة",
      subjectEn: "Pure Mathematics",
      durationMinutes: 20,
      passPercent: 60,
      maxViolations: 3,
      isPublished: true,
      createdBy: "teacher-1",
      createdAtMillis: now - 3_600_000,
      questions: [
        {
          id: "exq-calc-1",
          topicTagAr: "مشتقات الدوال المثلثية",
          topicTagEn: "Trigonometric Derivatives",
          promptAr: "إذا كانت د(س) = جا(٣س) + جتا(٢س)، أوجد قيمة د'(٠).",
          promptEn: "If f(x) = sin(3x) + cos(2x), find f'(0).",
          formula: "f(x) = sin(3x) + cos(2x)",
          options: ["1", "3", "-2", "5"],
          correctIndex: 1,
          points: 2,
          remedialAr: "مشتقة جا(٣س) هي ٣جتا(٣س) ومشتقة جتا(٢س) هي -٢جا(٢س)، وعند س=٠ يكون الناتج ٣(١) - ٠ = ٣.",
          remedialEn: "d/dx sin(3x) = 3cos(3x) and d/dx cos(2x) = -2sin(2x); at x=0 this evaluates to 3.",
        },
        {
          id: "exq-calc-2",
          topicTagAr: "قاعدة السلسلة",
          topicTagEn: "Chain Rule",
          promptAr: "أوجد مشتقة ص = (٢س² + ١)³ عند س = ١.",
          promptEn: "Find dy/dx for y = (2x² + 1)³ at x = 1.",
          formula: "y = (2x^2 + 1)^3",
          options: ["36", "108", "54", "27"],
          correctIndex: 1,
          points: 2,
          remedialAr: "ص' = ٣(٢س² + ١)² · ٤س. عند س=١: ٣ × ٩ × ٤ = ١٠٨.",
          remedialEn: "y' = 3(2x² + 1)² · 4x. At x = 1: 3 · 9 · 4 = 108.",
        },
        {
          id: "exq-calc-3",
          topicTagAr: "الاشتقاق الضمني",
          topicTagEn: "Implicit Differentiation",
          promptAr: "إذا كان س² + ص² = ٢٥، أوجد ميل المماس عند النقطة (٣، ٤).",
          promptEn: "Given x² + y² = 25, find the slope of the tangent at (3, 4).",
          formula: "x^2 + y^2 = 25",
          options: ["-3/4", "3/4", "-4/3", "4/3"],
          correctIndex: 0,
          points: 2,
          remedialAr: "بالاشتقاق الضمني: ٢س + ٢ص(دص/دس) = ٠ ⇐ دص/دس = -س/ص = -٣/٤.",
          remedialEn: "Differentiating implicitly: 2x + 2y(dy/dx) = 0 => dy/dx = -x/y = -3/4.",
        },
        {
          id: "exq-calc-4",
          topicTagAr: "القيم العظمى والصغرى",
          topicTagEn: "Local Extrema",
          promptAr: "للدالة د(س) = س³ - ٣س² + ٤، عند أي قيمة لـ س توجد نقطة قيمة صغرى محلية؟",
          promptEn: "For f(x) = x³ - 3x² + 4, at which x does a local minimum occur?",
          formula: "f(x) = x^3 - 3x^2 + 4",
          options: ["x = 0", "x = 2", "x = 1", "x = -1"],
          correctIndex: 1,
          points: 2,
          remedialAr: "د'(س) = ٣س² - ٦س = ٠ عند س=٠ أو س=٢. والمشتقة الثانية د''(٢) = ٦ > ٠ إذن صغرى محلية عند س=٢.",
          remedialEn: "f'(x) = 3x² - 6x = 0 at x=0, 2. Since f''(2) = 6 > 0, x = 2 is a local minimum.",
        },
      ],
    });

    this.registerExamInternal({
      id: "exam-phys-mod-1",
      tenantId: "demo-centre",
      groupId: "grp-phys-3sec",
      titleAr: "اختبار كيرشوف والحث الكهرومغناطيسي المحصّن",
      titleEn: "Kirchhoff & Electromagnetic Induction — Fortress Exam",
      subjectAr: "الفيزياء",
      subjectEn: "Physics",
      durationMinutes: 15,
      passPercent: 60,
      maxViolations: 3,
      isPublished: true,
      createdBy: "teacher-1",
      createdAtMillis: now - 1_800_000,
      questions: [
        {
          id: "exq-phys-1",
          topicTagAr: "قانون كيرشوف الأول",
          topicTagEn: "Kirchhoff Current Law",
          promptAr: "أي مبدأ فيزيائي يمثّل الأساس المباشر لقانون كيرشوف الأول عند أي عقدة؟",
          promptEn: "Which conservation law directly underlies Kirchhoff's First Law at a circuit node?",
          formula: "Sum(I_in) = Sum(I_out)",
          options: ["حفظ الشحنة الكهربائية", "حفظ الطاقة", "حفظ كمية التحرك", "قانون فاراداي"],
          correctIndex: 0,
          points: 2,
          remedialAr: "قانون كيرشوف الأول يعبر عن حفظ الشحنة الكهربائية؛ فلا تتراكم شحنات عند العقدة.",
          remedialEn: "Kirchhoff's junction rule expresses conservation of electric charge.",
        },
        {
          id: "exq-phys-2",
          topicTagAr: "قانون فاراداي ولنز",
          topicTagEn: "Faraday & Lenz Law",
          promptAr: "ملف عدد لفاته ٢٠٠ لفة يتغير الفيض خلاله بمعدل ٠.٠٤ ويبر/ث. ما مقدار القوة الدافعة المستحثة؟",
          promptEn: "A 200-turn coil experiences a flux change rate of 0.04 Wb/s. What is the induced EMF magnitude?",
          formula: "|EMF| = N * (dPhi / dt)",
          options: ["4 V", "8 V", "16 V", "0.8 V"],
          correctIndex: 1,
          points: 2,
          remedialAr: "ق.د.ك المستحثة = ن × (ΔΦ/Δt) = ٢٠٠ × ٠.٠٤ = ٨ فولت.",
          remedialEn: "|EMF| = N · |dPhi/dt| = 200 × 0.04 = 8 V.",
        },
        {
          id: "exq-phys-3",
          topicTagAr: "المحول المثالي",
          topicTagEn: "Ideal Transformer",
          promptAr: "محول مثالي خافض للجهد نسبة لفاته ١٠:١ متصل بمصدر ٢٢٠ فولت. كم يكون جهد الثانوي؟",
          promptEn: "An ideal step-down transformer has turns ratio 10:1 connected to 220V primary. Find secondary voltage.",
          formula: "Vs / Vp = Ns / Np",
          options: ["22 V", "2200 V", "11 V", "44 V"],
          correctIndex: 0,
          points: 2,
          remedialAr: "جهد الثانوي = ٢٢٠ × (١ / ١٠) = ٢٢ فولت.",
          remedialEn: "Vs = Vp × (Ns / Np) = 220 × (1 / 10) = 22 V.",
        },
      ],
    });
  }

  private registerExamInternal(params: {
    id: string;
    tenantId: string;
    groupId: string;
    titleAr: string;
    titleEn: string;
    subjectAr: string;
    subjectEn: string;
    durationMinutes: number;
    passPercent: number;
    maxViolations: number;
    isPublished: boolean;
    createdBy: string;
    createdAtMillis: number;
    questions: ExamQuestionInput[];
  }): ExamDefinition {
    const def: ExamDefinition = {
      id: params.id,
      tenantId: params.tenantId,
      groupId: params.groupId,
      titleAr: params.titleAr,
      titleEn: params.titleEn,
      subjectAr: params.subjectAr,
      subjectEn: params.subjectEn,
      durationMinutes: params.durationMinutes,
      passPercent: params.passPercent,
      maxViolations: params.maxViolations,
      isPublished: params.isPublished,
      createdBy: params.createdBy,
      createdAtMillis: params.createdAtMillis,
    };

    const storedQs: ExamQuestionStored[] = [];
    const keyMap = new Map<string, ExamQuestionKey>();

    params.questions.forEach((q, idx) => {
      const qId = q.id?.trim() || `${params.id}-q-${idx + 1}`;
      const cleanOpts = q.options.map((o) => o.trim()).filter(Boolean).slice(0, 4);
      const safeIdx = Math.min(Math.max(0, Number(q.correctIndex) || 0), Math.max(0, cleanOpts.length - 1));
      storedQs.push({
        id: qId,
        topicTagAr: q.topicTagAr,
        topicTagEn: q.topicTagEn,
        promptAr: q.promptAr,
        promptEn: q.promptEn,
        formula: q.formula?.trim() || "",
        options: cleanOpts,
        points: Math.max(1, Number(q.points) || 1),
      });
      keyMap.set(qId, {
        questionId: qId,
        correctIndex: safeIdx,
        remedialAr: q.remedialAr,
        remedialEn: q.remedialEn,
      });
    });

    const byIdMap = new Map<string, ExamQuestionStored>();
    let totalPoints = 0;
    for (const sq of storedQs) {
      byIdMap.set(sq.id, sq);
      totalPoints += sq.points;
    }

    this.exams.set(def.id, def);
    this.questionsByExam.set(def.id, storedQs);
    this.questionByIdByExam.set(def.id, byIdMap);
    this.totalPointsByExam.set(def.id, totalPoints);
    this.questionKeysByExam.set(def.id, keyMap);
    return def;
  }

  listExamsForRole(role: string, studentId?: string): Array<{
    exam: ExamDefinition;
    questionCount: number;
    totalPoints: number;
    myAttempt: {
      attemptId: string;
      status: ExamAttemptStatus;
      percentScore: number;
      violationsCount: number;
      hardDeadlineAtMillis: number;
      certificate: ExamCertificate | null;
    } | null;
  }> {
    const isStaff = role === "teacher" || role === "secretary" || role === "center_admin";
    return Array.from(this.exams.values())
      .filter((e) => isStaff || e.isPublished)
      .sort((a, b) => b.createdAtMillis - a.createdAtMillis)
      .map((exam) => {
        const qs = this.questionsByExam.get(exam.id) ?? [];
        const totalPoints = qs.reduce((s, q) => s + q.points, 0);
        const attemptId = studentId ? this.attemptByExamStudent.get(`${exam.id}:${studentId}`) : undefined;
        const attempt = attemptId ? this.attempts.get(attemptId) : undefined;
        return {
          exam,
          questionCount: qs.length,
          totalPoints,
          myAttempt: attempt
            ? {
                attemptId: attempt.id,
                status: attempt.status,
                percentScore: attempt.percentScore,
                violationsCount: attempt.violationsCount,
                hardDeadlineAtMillis: attempt.hardDeadlineAtMillis,
                certificate: attempt.certificate,
              }
            : null,
        };
      });
  }

  createExam(params: {
    tenantId?: string;
    groupId: string;
    titleAr: string;
    titleEn?: string;
    subjectAr: string;
    subjectEn?: string;
    durationMinutes: number;
    passPercent?: number;
    maxViolations?: number;
    questions: ExamQuestionInput[];
    actorId: string;
    actorRole: string;
  }): ExamDefinition {
    if (!["teacher", "secretary", "center_admin"].includes(params.actorRole)) {
      throw new Error("FORBIDDEN: Only teacher or center staff can create exams.");
    }
    if (!params.titleAr.trim() || !Array.isArray(params.questions) || params.questions.length === 0) {
      throw new Error("VALIDATION: Exam title and at least one question are required.");
    }
    for (const q of params.questions) {
      if (!q.promptAr.trim() || !Array.isArray(q.options) || q.options.length < 2) {
        throw new Error("VALIDATION: Every question needs a prompt and at least 2 options.");
      }
    }
    const examId = `exam-${Date.now()}-${crypto.randomUUID().slice(0, 6)}`;
    const def = this.registerExamInternal({
      id: examId,
      tenantId: params.tenantId ?? "demo-centre",
      groupId: params.groupId || "grp-math-3sec",
      titleAr: params.titleAr.trim(),
      titleEn: params.titleEn?.trim() || params.titleAr.trim(),
      subjectAr: params.subjectAr.trim() || "الرياضيات البحتة",
      subjectEn: params.subjectEn?.trim() || "Mathematics",
      durationMinutes: Math.min(180, Math.max(5, Number(params.durationMinutes) || 20)),
      passPercent: Math.min(100, Math.max(30, Number(params.passPercent) || 60)),
      maxViolations: Math.min(10, Math.max(1, Number(params.maxViolations) || 3)),
      isPublished: true,
      createdBy: params.actorId,
      createdAtMillis: Date.now(),
      questions: params.questions,
    });

    aegisSecurity.recordAudit({
      tenantId: def.tenantId,
      actorId: params.actorId,
      actorRole: params.actorRole,
      action: "EXAM_CREATED",
      targetTable: "exams",
      targetId: def.id,
      detail: `Published fortress exam "${def.titleEn}" (${params.questions.length} questions, keys isolated)`,
    });

    return def;
  }

  private buildSanitizedQuestions(attempt: ExamAttempt): SanitizedExamQuestion[] {
    const byId = this.questionByIdByExam.get(attempt.examId);
    if (!byId) return [];
    const out: SanitizedExamQuestion[] = [];
    for (const qId of attempt.questionOrder) {
      const q = byId.get(qId);
      if (!q) continue;
      const perm = attempt.optionPermutations[qId] ?? q.options.map((_, i) => i);
      const shuffledOptions = perm.map((origIdx) => q.options[origIdx] ?? "");
      out.push({
        id: q.id,
        topicTagAr: q.topicTagAr,
        topicTagEn: q.topicTagEn,
        promptAr: q.promptAr,
        promptEn: q.promptEn,
        formula: q.formula,
        options: shuffledOptions,
        points: q.points,
      });
    }
    return out;
  }

  startAttempt(params: {
    examId: string;
    studentId: string;
    studentName: string;
    studentCode?: string;
    deviceId: string;
  }): {
    exam: ExamDefinition;
    attemptId: string;
    status: ExamAttemptStatus;
    startedAtMillis: number;
    hardDeadlineAtMillis: number;
    serverNowMillis: number;
    forensicWatermark: string;
    violationsCount: number;
    maxViolations: number;
    answersByQuestion: Record<string, number>;
    questions: SanitizedExamQuestion[];
  } {
    const exam = this.exams.get(params.examId);
    if (!exam) {
      throw new Error("NOT_FOUND: Exam not found.");
    }
    const questions = this.questionsByExam.get(exam.id) ?? [];
    if (questions.length === 0) {
      throw new Error("VALIDATION: Exam has no questions.");
    }

    const compositeKey = `${exam.id}:${params.studentId}`;
    const existingId = this.attemptByExamStudent.get(compositeKey);
    if (existingId) {
      const existing = this.attempts.get(existingId);
      if (existing) {
        if (existing.status === "in_progress" && Date.now() > existing.hardDeadlineAtMillis + 2000) {
          this.submitAndGrade({ attemptId: existing.id, studentId: params.studentId, forcedBySecurity: true, forceReason: "expired" });
        }
        return {
          exam,
          attemptId: existing.id,
          status: existing.status,
          startedAtMillis: existing.startedAtMillis,
          hardDeadlineAtMillis: existing.hardDeadlineAtMillis,
          serverNowMillis: Date.now(),
          forensicWatermark: existing.forensicWatermark,
          violationsCount: existing.violationsCount,
          maxViolations: exam.maxViolations,
          answersByQuestion: { ...existing.answersByQuestion },
          questions: existing.status === "in_progress" ? this.buildSanitizedQuestions(existing) : [],
        };
      }
    }

    const attemptId = `attx-${crypto.randomUUID()}`;
    const now = Date.now();
    const hardDeadlineAtMillis = now + exam.durationMinutes * 60_000;
    const seed = crypto
      .createHmac("sha256", aegisSecurity.getHmacSecret())
      .update(`${exam.id}:${params.studentId}:${attemptId}`)
      .digest("hex");
    const rand = seededPrng(seed);

    const shuffledQs = deterministicShuffle(questions, rand);
    const questionOrder = shuffledQs.map((q) => q.id);
    const optionPermutations: Record<string, number[]> = {};
    for (const q of shuffledQs) {
      const indices = q.options.map((_, i) => i);
      optionPermutations[q.id] = deterministicShuffle(indices, rand);
    }

    const cleanCode = params.studentCode?.trim() || params.studentId.toUpperCase();
    const watermark = `${params.studentName} · ${cleanCode} · ${params.deviceId.slice(0, 12)}`;

    const attempt: ExamAttempt = {
      id: attemptId,
      examId: exam.id,
      studentId: params.studentId,
      studentName: params.studentName,
      studentCode: cleanCode,
      deviceId: params.deviceId,
      status: "in_progress",
      questionOrder,
      optionPermutations,
      answersByQuestion: {},
      violationsCount: 0,
      securityEvents: [],
      forensicWatermark: watermark,
      startedAtMillis: now,
      hardDeadlineAtMillis,
      lastHeartbeatAtMillis: now,
      submittedAtMillis: null,
      scorePoints: 0,
      maxPoints: this.totalPointsByExam.get(exam.id) ?? 0,
      percentScore: 0,
      certificate: null,
    };

    this.attempts.set(attemptId, attempt);
    let examAttempts = this.attemptsByExam.get(exam.id);
    if (!examAttempts) {
      examAttempts = [];
      this.attemptsByExam.set(exam.id, examAttempts);
    }
    examAttempts.push(attempt);
    this.attemptByExamStudent.set(compositeKey, attemptId);

    aegisSecurity.bindDevice({
      tenantId: exam.tenantId,
      actorId: params.studentId,
      deviceFingerprint: params.deviceId,
      deviceLabel: `Exam Client (${cleanCode})`,
    });

    aegisSecurity.recordAudit({
      tenantId: exam.tenantId,
      actorId: params.studentId,
      actorRole: "student",
      action: "EXAM_ATTEMPT_STARTED",
      targetTable: "exam_attempts",
      targetId: attempt.id,
      detail: `Started ${exam.id}; deadlineMs=${hardDeadlineAtMillis}`,
    });

    return {
      exam,
      attemptId: attempt.id,
      status: attempt.status,
      startedAtMillis: attempt.startedAtMillis,
      hardDeadlineAtMillis: attempt.hardDeadlineAtMillis,
      serverNowMillis: now,
      forensicWatermark: attempt.forensicWatermark,
      violationsCount: 0,
      maxViolations: exam.maxViolations,
      answersByQuestion: {},
      questions: this.buildSanitizedQuestions(attempt),
    };
  }

  upsertAnswer(params: {
    attemptId: string;
    studentId: string;
    questionId: string;
    selectedDisplayIndex: number;
    deviceId?: string;
  }): { saved: boolean; serverNowMillis: number; status: ExamAttemptStatus; reason?: string } {
    const attempt = this.attempts.get(params.attemptId);
    if (!attempt) {
      throw new Error("NOT_FOUND: Attempt not found.");
    }
    if (attempt.studentId !== params.studentId) {
      throw new Error("FORBIDDEN: Attempt belongs to a different student.");
    }
    if (attempt.status !== "in_progress") {
      return {
        saved: false,
        serverNowMillis: Date.now(),
        status: attempt.status,
        reason: `Attempt already finalized (${attempt.status}).`,
      };
    }

    const now = Date.now();
    // Strict server-authoritative deadline enforcement (ignore client timestamps completely)
    if (now > attempt.hardDeadlineAtMillis + 2000) {
      this.submitAndGrade({
        attemptId: attempt.id,
        studentId: params.studentId,
        forcedBySecurity: true,
        forceReason: "expired",
      });
      return {
        saved: false,
        serverNowMillis: now,
        status: "expired",
        reason: "DEADLINE_EXPIRED: Server deadline passed; attempt auto-submitted.",
      };
    }

    if (!attempt.questionOrder.includes(params.questionId)) {
      throw new Error("VALIDATION: Question is not part of this attempt.");
    }

    const perm = attempt.optionPermutations[params.questionId] ?? [];
    if (
      !Number.isInteger(params.selectedDisplayIndex) ||
      params.selectedDisplayIndex < 0 ||
      params.selectedDisplayIndex >= perm.length
    ) {
      throw new Error("VALIDATION: Option index out of range.");
    }

    attempt.answersByQuestion[params.questionId] = params.selectedDisplayIndex;
    attempt.lastHeartbeatAtMillis = now;
    return { saved: true, serverNowMillis: now, status: attempt.status };
  }

  recordHeartbeat(params: {
    attemptId: string;
    studentId: string;
    eventType: ExamViolationType;
    detail?: string;
    deviceId?: string;
  }): {
    status: ExamAttemptStatus;
    violationsCount: number;
    maxViolations: number;
    autoLocked: boolean;
    serverNowMillis: number;
    result?: ExamResultPayload;
  } {
    const attempt = this.attempts.get(params.attemptId);
    if (!attempt) {
      throw new Error("NOT_FOUND: Attempt not found.");
    }
    if (attempt.studentId !== params.studentId) {
      throw new Error("FORBIDDEN: Attempt ownership mismatch.");
    }
    const exam = this.exams.get(attempt.examId);
    const maxViolations = exam?.maxViolations ?? 3;
    const now = Date.now();
    attempt.lastHeartbeatAtMillis = now;

    if (attempt.status !== "in_progress") {
      return {
        status: attempt.status,
        violationsCount: attempt.violationsCount,
        maxViolations,
        autoLocked: attempt.status === "locked_violation",
        serverNowMillis: now,
      };
    }

    if (now > attempt.hardDeadlineAtMillis + 2000) {
      const result = this.submitAndGrade({
        attemptId: attempt.id,
        studentId: params.studentId,
        forcedBySecurity: true,
        forceReason: "expired",
      });
      return {
        status: attempt.status,
        violationsCount: attempt.violationsCount,
        maxViolations,
        autoLocked: false,
        serverNowMillis: now,
        result,
      };
    }

    if (params.eventType !== "heartbeat") {
      attempt.violationsCount += 1;
      const evt: ExamSecurityEvent = {
        id: `ev-${crypto.randomUUID().slice(0, 8)}`,
        eventType: params.eventType,
        detail: (params.detail ?? params.eventType).slice(0, 140),
        occurredAtMillis: now,
      };
      attempt.securityEvents.push(evt);
      aegisSecurity.recordAudit({
        tenantId: exam?.tenantId ?? "demo-centre",
        actorId: attempt.studentId,
        actorRole: "student",
        action: `EXAM_VIOLATION_${params.eventType.toUpperCase()}`,
        targetTable: "exam_security_events",
        targetId: attempt.id,
        detail: `${evt.detail} (${attempt.violationsCount}/${maxViolations})`,
      });

      if (attempt.violationsCount >= maxViolations) {
        const result = this.submitAndGrade({
          attemptId: attempt.id,
          studentId: params.studentId,
          forcedBySecurity: true,
          forceReason: "locked_violation",
        });
        return {
          status: attempt.status,
          violationsCount: attempt.violationsCount,
          maxViolations,
          autoLocked: true,
          serverNowMillis: now,
          result,
        };
      }
    }

    return {
      status: attempt.status,
      violationsCount: attempt.violationsCount,
      maxViolations,
      autoLocked: false,
      serverNowMillis: now,
    };
  }

  submitAndGrade(params: {
    attemptId: string;
    studentId?: string;
    actorRole?: string;
    forcedBySecurity?: boolean;
    forceReason?: "locked_violation" | "expired";
  }): ExamResultPayload {
    const attempt = this.attempts.get(params.attemptId);
    if (!attempt) {
      throw new Error("NOT_FOUND: Attempt not found.");
    }
    const isStaff =
      params.actorRole === "teacher" || params.actorRole === "secretary" || params.actorRole === "center_admin";
    if (!params.forcedBySecurity && !isStaff && params.studentId && attempt.studentId !== params.studentId) {
      throw new Error("FORBIDDEN: Cannot submit another student's attempt.");
    }

    const exam = this.exams.get(attempt.examId);
    if (!exam) {
      throw new Error("NOT_FOUND: Exam definition missing.");
    }

    if (attempt.status === "in_progress") {
      const now = Date.now();
      const questions = this.questionsByExam.get(exam.id) ?? [];
      const keys = this.questionKeysByExam.get(exam.id) ?? new Map<string, ExamQuestionKey>();

      let scorePoints = 0;
      let maxPoints = 0;
      for (const q of questions) {
        maxPoints += q.points;
        const key = keys.get(q.id);
        const displayIdx = attempt.answersByQuestion[q.id];
        if (key !== undefined && displayIdx !== undefined) {
          const perm = attempt.optionPermutations[q.id] ?? q.options.map((_, i) => i);
          const originalIdx = perm[displayIdx];
          if (originalIdx === key.correctIndex) {
            scorePoints += q.points;
          }
        }
      }

      const percentScore = maxPoints > 0 ? Math.round((scorePoints / maxPoints) * 100) : 0;
      let finalStatus: ExamAttemptStatus = "submitted";
      if (params.forceReason === "locked_violation") {
        finalStatus = "locked_violation";
      } else if (params.forceReason === "expired" || now > attempt.hardDeadlineAtMillis + 5000) {
        finalStatus = "expired";
      }

      attempt.status = finalStatus;
      attempt.scorePoints = scorePoints;
      attempt.maxPoints = maxPoints;
      attempt.percentScore = percentScore;
      attempt.submittedAtMillis = now;

      let counts = this.gradedScoreCountsByExam.get(exam.id);
      if (!counts) {
        counts = new Int32Array(101);
        this.gradedScoreCountsByExam.set(exam.id, counts);
      }
      const clampedScore = Math.min(100, Math.max(0, percentScore));
      counts[clampedScore] += 1;
      this.totalGradedByExam.set(exam.id, (this.totalGradedByExam.get(exam.id) ?? 0) + 1);

      if (percentScore >= exam.passPercent && finalStatus !== "locked_violation") {
        const certId = `cert-${attempt.id.slice(-8).toUpperCase()}`;
        const certHash = aegisSecurity
          .signPayload(`CERT:${certId}:${exam.id}:${attempt.studentId}:${percentScore}:${now}`)
          .slice(0, 24)
          .toUpperCase();
        const cert: ExamCertificate = {
          id: certId,
          attemptId: attempt.id,
          examId: exam.id,
          studentId: attempt.studentId,
          studentName: attempt.studentName,
          examTitleAr: exam.titleAr,
          examTitleEn: exam.titleEn,
          percentScore,
          certHash,
          qrPayload: `KSHCERT|${certId}|${attempt.studentId}|${percentScore}|${certHash}`,
          issuedAtMillis: now,
        };
        attempt.certificate = cert;
        this.certificates.set(certId, cert);
      }

      aegisSecurity.recordAudit({
        tenantId: exam.tenantId,
        actorId: attempt.studentId,
        actorRole: params.forcedBySecurity ? "system" : params.actorRole ?? "student",
        action: `EXAM_${finalStatus.toUpperCase()}`,
        targetTable: "exam_attempts",
        targetId: attempt.id,
        detail: `Graded ${scorePoints}/${maxPoints} (${percentScore}%) violations=${attempt.violationsCount}`,
      });
    }

    return this.buildResultPayload(attempt, exam);
  }

  getAttemptResult(attemptId: string, actorId: string, actorRole: string): ExamResultPayload {
    const attempt = this.attempts.get(attemptId);
    if (!attempt) {
      throw new Error("NOT_FOUND: Attempt not found.");
    }
    const isStaff = actorRole === "teacher" || actorRole === "secretary" || actorRole === "center_admin";
    if (!isStaff && attempt.studentId !== actorId) {
      throw new Error("FORBIDDEN: Cannot inspect another student's result.");
    }
    if (attempt.status === "in_progress") {
      throw new Error("FORBIDDEN: Answer keys and breakdown are sealed until submission.");
    }
    const exam = this.exams.get(attempt.examId);
    if (!exam) {
      throw new Error("NOT_FOUND: Exam missing.");
    }
    return this.buildResultPayload(attempt, exam);
  }

  private buildResultPayload(attempt: ExamAttempt, exam: ExamDefinition): ExamResultPayload {
    const byId = this.questionByIdByExam.get(exam.id) ?? new Map<string, ExamQuestionStored>();
    const keys = this.questionKeysByExam.get(exam.id) ?? new Map<string, ExamQuestionKey>();

    const breakdown: GradedQuestionResult[] = [];
    const mistakes: ExamResultPayload["mistakes"] = [];

    for (const qId of attempt.questionOrder) {
      const q = byId.get(qId);
      const key = keys.get(qId);
      if (!q || !key) continue;

      const perm = attempt.optionPermutations[qId] ?? q.options.map((_, i) => i);
      const displayIdx = attempt.answersByQuestion[qId];
      const originalIdx = displayIdx !== undefined ? perm[displayIdx] : undefined;
      const selectedText = originalIdx !== undefined ? (q.options[originalIdx] ?? null) : null;
      const correctText = q.options[key.correctIndex] ?? "";
      const isCorrect = originalIdx === key.correctIndex;

      breakdown.push({
        questionId: q.id,
        topicTagAr: q.topicTagAr,
        topicTagEn: q.topicTagEn,
        promptAr: q.promptAr,
        promptEn: q.promptEn,
        selectedOptionText: selectedText,
        correctOptionText: correctText,
        isCorrect,
        pointsEarned: isCorrect ? q.points : 0,
        maxPoints: q.points,
        remedialAr: key.remedialAr,
        remedialEn: key.remedialEn,
      });

      if (!isCorrect) {
        mistakes.push({
          questionId: q.id,
          topicTagAr: q.topicTagAr,
          topicTagEn: q.topicTagEn,
          promptAr: q.promptAr,
          promptEn: q.promptEn,
          wrongAnswer: selectedText ?? "—",
          correctAnswer: correctText,
          remedialAr: key.remedialAr,
          remedialEn: key.remedialEn,
        });
      }
    }

    const counts = this.gradedScoreCountsByExam.get(exam.id);
    const clampedScore = Math.min(100, Math.max(0, attempt.percentScore));
    let higherCount = 0;
    if (counts) {
      for (let s = clampedScore + 1; s <= 100; s++) {
        higherCount += counts[s];
      }
    }
    const totalGraded = Math.max(1, this.totalGradedByExam.get(exam.id) ?? 1);
    const rank = higherCount + 1;
    const percentile = Math.round(((totalGraded - rank + 1) / totalGraded) * 100);

    return {
      attemptId: attempt.id,
      examId: exam.id,
      examTitleAr: exam.titleAr,
      examTitleEn: exam.titleEn,
      studentId: attempt.studentId,
      studentName: attempt.studentName,
      status: attempt.status,
      scorePoints: attempt.scorePoints,
      maxPoints: attempt.maxPoints,
      percentScore: attempt.percentScore,
      passPercent: exam.passPercent,
      passed: attempt.percentScore >= exam.passPercent && attempt.status !== "locked_violation",
      rank,
      totalGraded,
      percentile,
      violationsCount: attempt.violationsCount,
      submittedAtMillis: attempt.submittedAtMillis ?? Date.now(),
      certificate: attempt.certificate,
      breakdown,
      mistakes,
    };
  }

  listAttemptsForExam(examId: string, actorRole: string): Array<{
    attemptId: string;
    studentId: string;
    studentName: string;
    studentCode: string;
    deviceId: string;
    status: ExamAttemptStatus;
    violationsCount: number;
    percentScore: number;
    answeredCount: number;
    totalQuestions: number;
    lastHeartbeatAtMillis: number;
    recentEvents: ExamSecurityEvent[];
  }> {
    if (!["teacher", "secretary", "center_admin"].includes(actorRole)) {
      throw new Error("FORBIDDEN: Staff role required for live proctoring console.");
    }
    return [...(this.attemptsByExam.get(examId) ?? [])]
      .sort((a, b) => b.lastHeartbeatAtMillis - a.lastHeartbeatAtMillis)
      .map((a) => ({
        attemptId: a.id,
        studentId: a.studentId,
        studentName: a.studentName,
        studentCode: a.studentCode,
        deviceId: a.deviceId,
        status: a.status,
        violationsCount: a.violationsCount,
        percentScore: a.percentScore,
        answeredCount: Object.keys(a.answersByQuestion).length,
        totalQuestions: a.questionOrder.length,
        lastHeartbeatAtMillis: a.lastHeartbeatAtMillis,
        recentEvents: a.securityEvents.slice(-5),
      }));
  }

  forceLockAttempt(attemptId: string, actorId: string, actorRole: string): ExamResultPayload {
    if (!["teacher", "secretary", "center_admin"].includes(actorRole)) {
      throw new Error("FORBIDDEN: Only teacher or center staff can lock an exam attempt.");
    }
    const attempt = this.attempts.get(attemptId);
    if (!attempt) {
      throw new Error("NOT_FOUND: Attempt not found.");
    }
    attempt.securityEvents.push({
      id: `ev-${crypto.randomUUID().slice(0, 8)}`,
      eventType: "dev_tools",
      detail: `Proctor remote lock by ${actorId}`,
      occurredAtMillis: Date.now(),
    });
    return this.submitAndGrade({
      attemptId,
      actorRole,
      forcedBySecurity: true,
      forceReason: "locked_violation",
    });
  }

  verifyCertificate(certId: string): ExamCertificate | null {
    return this.certificates.get(certId) ?? null;
  }
}

export const examFortress = new ExamFortressService();
