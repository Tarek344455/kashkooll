import React, { createContext, useCallback, useContext, useEffect, useMemo, useState } from "react";
import {
  AiOperationalBriefing,
  AppLanguage,
  AssistantMessage,
  AsyncUiState,
  AttendanceChartMode,
  AttendanceDashboardSnapshot,
  AttendanceEntity,
  AttendanceWindow,
  AuthMode,
  AuthUiState,
  AvailabilityStatus,
  CenterPlanTier,
  CompressedReceiptResult,
  CourseUnit,
  EvaluationTargetType,
  GroupEntity,
  LedgerEntryEntity,
  LedgerKind,
  LessonRevisionDeck,
  ParentWeeklyDigest,
  PaymentChannelEntity,
  PaymentSubmissionEntity,
  PerformanceEvaluationEntity,
  QrPayloadKind,
  QrVerificationBanner,
  QrVerifyStatus,
  QuizQuestion,
  ReceiptScanResult,
  RescueItem,
  ResourceItem,
  ResourceType,
  ScanFeedback,
  SecretaryNoticeUiState,
  ShiftReconciliation,
  StudentEntity,
  SubmissionStatus,
  SystemOperatingReport,
  TeacherLessonPlan,
  UserRole,
} from "../types/kashkool";
import {
  initialAttendance,
  initialLedgerEntries,
  initialResources,
  seedChannels,
  seedGroups,
  seedStudents,
} from "../data/seeds";
import { centerPlans, coursesCatalog, quizCatalog } from "../data/catalog";
import { t, ledgerKindLabel } from "../core/l10n/appStrings";
import { DynamicQrEngine, EgyptValidators } from "../core/utils/egyptValidators";
import { OperationsResearchEngine } from "../core/or/operationsResearchEngine";
import { AttendanceAnalyticsEngine, startOfDayMillis } from "../core/analytics/attendanceAnalyticsEngine";
import { KashkoolMessageBuilders } from "../core/utils/messageBuilders";
import { AiToolkitClient } from "../services/aiToolkitClient";
import { compressImageFile } from "../core/utils/browserUtils";
import {
  bootstrapSupabaseClient,
  requestSupabaseEmailOtp,
  requestSupabasePhoneOtp,
  signOutSupabase,
  subscribeToCenterRealtime,
  syncPendingToSupabase,
  verifySupabaseEmailOtp,
  verifySupabasePhoneOtp,
} from "../services/supabaseClient";

const STORAGE_KEY = "kashkool_web_store_v1";
const SESSION_ID = "sess-nokhba-today";
const SESSION_SECRET = "kashkool-local-session-hmac-secret-2026";
const qrEngine = new DynamicQrEngine(SESSION_ID, SESSION_SECRET, 30);

interface PersistedData {
  language: AppLanguage;
  signedIn: boolean;
  activeRole: UserRole;
  userLabel: string;
  lowDataMode: boolean;
  streakShieldActive: boolean;
  activeCenterPlanId: string;
  rescueIds: string[];
  settlementSplitPercent: number;
  assistantWagesPiasters: number;
  completedCourseIds: string[];
  groups: GroupEntity[];
  students: StudentEntity[];
  attendance: AttendanceEntity[];
  ledger: LedgerEntryEntity[];
  channels: PaymentChannelEntity[];
  submissions: PaymentSubmissionEntity[];
  resources: ResourceItem[];
  evaluations: PerformanceEvaluationEntity[];
}

function createInitialPersisted(): PersistedData {
  const now = Date.now();
  return {
    language: AppLanguage.AR,
    signedIn: false,
    activeRole: UserRole.STUDENT,
    userLabel: "+201012345678",
    lowDataMode: true,
    streakShieldActive: false,
    activeCenterPlanId: "plan-pro",
    rescueIds: ["q2"],
    settlementSplitPercent: 20,
    assistantWagesPiasters: 15000,
    completedCourseIds: [],
    groups: seedGroups,
    students: seedStudents,
    attendance: initialAttendance(now),
    ledger: initialLedgerEntries(now),
    channels: seedChannels,
    submissions: [],
    resources: initialResources(now),
    evaluations: [],
  };
}

function loadPersisted(): PersistedData {
  try {
    const raw = localStorage.getItem(STORAGE_KEY);
    if (!raw) return createInitialPersisted();
    const parsed = JSON.parse(raw) as Partial<PersistedData>;
    const fallback = createInitialPersisted();
    return {
      ...fallback,
      ...parsed,
      groups: Array.isArray(parsed.groups) && parsed.groups.length > 0 ? parsed.groups : fallback.groups,
      students: Array.isArray(parsed.students) && parsed.students.length > 0 ? parsed.students : fallback.students,
      channels: Array.isArray(parsed.channels) && parsed.channels.length > 0 ? parsed.channels : fallback.channels,
      attendance: Array.isArray(parsed.attendance) ? parsed.attendance : fallback.attendance,
      ledger: Array.isArray(parsed.ledger) ? parsed.ledger : fallback.ledger,
      submissions: Array.isArray(parsed.submissions) ? parsed.submissions : [],
      resources: Array.isArray(parsed.resources) && parsed.resources.length > 0 ? parsed.resources : fallback.resources,
      evaluations: Array.isArray(parsed.evaluations) ? parsed.evaluations : [],
      rescueIds: Array.isArray(parsed.rescueIds) ? parsed.rescueIds : fallback.rescueIds,
      completedCourseIds: Array.isArray(parsed.completedCourseIds) ? parsed.completedCourseIds : [],
    };
  } catch {
    return createInitialPersisted();
  }
}

export interface KashkoolContextValue {
  // Persisted + Computed State
  language: AppLanguage;
  signedIn: boolean;
  activeRole: UserRole;
  userLabel: string;
  groups: GroupEntity[];
  students: StudentEntity[];
  attendance: AttendanceEntity[];
  ledger: LedgerEntryEntity[];
  channels: PaymentChannelEntity[]; // active channels
  allChannels: PaymentChannelEntity[];
  submissions: PaymentSubmissionEntity[];
  resources: ResourceItem[];
  evaluations: PerformanceEvaluationEntity[];
  lowDataMode: boolean;
  streakShieldActive: boolean;
  activeCenterPlanId: string;
  centerPlans: CenterPlanTier[];
  settlementSplitPercent: number;
  assistantWagesPiasters: number;
  completedCourseIds: Set<string>;
  courses: CourseUnit[];
  quizQuestions: QuizQuestion[];
  rescueItems: RescueItem[];
  pendingSyncCount: number;
  shiftReconciliation: ShiftReconciliation;
  operatingReport: SystemOperatingReport;
  attendanceDashboard: AttendanceDashboardSnapshot;

  // Dynamic QR & Student Pass
  qrToken: string;
  qrSecondsRemaining: number;
  activeStudent: StudentEntity | undefined;
  activeStudentQrToken: string;
  activeStudentCardCode: string;
  activeStudentCardPayload: string;
  activeStudentCheckedInToday: boolean;

  // Transient UI States
  auth: AuthUiState;
  scannerScanCount: number;
  lastScanFeedback: ScanFeedback | null;
  qrVerificationBanner: QrVerificationBanner | null;
  snackbarMessage: string | null;
  assistantMessages: AssistantMessage[];
  assistantBusy: boolean;
  assistantError: string | null;
  activeLectureId: string | null;
  activeLectureTitle: string | null;
  adaptiveQuizQuestions: QuizQuestion[] | null;
  adaptiveQuizTopic: string | null;
  adaptiveQuizBusy: boolean;
  adaptiveQuizError: string | null;
  syncBusy: boolean;
  supabaseConfigured: boolean;
  generatedQrCode: string | null;
  generatedQrStudentName: string | null;
  compressedReceipt: CompressedReceiptResult | null;
  receiptCompressing: boolean;
  reassurancePulseAtMillis: number;
  rushModeEnabled: boolean;
  studyBudgetMinutes: number;
  attendanceWindow: AttendanceWindow;
  attendanceChartMode: AttendanceChartMode;
  attendanceGroupFilter: string | null;
  aiBriefingState: AsyncUiState<AiOperationalBriefing>;
  evaluationState: AsyncUiState<PerformanceEvaluationEntity>;
  receiptScanState: AsyncUiState<ReceiptScanResult>;
  revisionDeckState: AsyncUiState<LessonRevisionDeck>;
  parentDigestState: AsyncUiState<ParentWeeklyDigest>;
  secretaryNoticeState: SecretaryNoticeUiState;
  teacherPlanState: AsyncUiState<TeacherLessonPlan>;

  // Actions
  tr: (key: string) => string;
  showSnackbar: (msg: string) => void;
  clearSnackbar: () => void;
  toggleLanguage: () => void;
  setAuthMode: (mode: AuthMode) => void;
  requestOtp: (input: string) => void;
  verifyOtp: (code: string) => void;
  activateWithQr: (code: string) => void;
  enterOfflineWorkspace: (role: UserRole) => void;
  switchRole: (role: UserRole) => void;
  signOut: () => void;
  syncNow: () => void;
  toggleLowDataMode: () => void;
  toggleStreakShield: () => void;
  completeRescueItem: (questionId: string) => void;
  recordQuizOutcome: (questionId: string, correct: boolean) => void;
  triggerParentReassurance: () => void;
  buildEncouragementMessage: () => string;
  buildParentReportShareText: () => string;
  notifyMessageCopied: () => void;
  toggleRushMode: () => void;
  discreetAllowWithParentNotice: (student: StudentEntity) => void;
  notifyQrCopied: () => void;
  setAttendanceWindow: (w: AttendanceWindow) => void;
  setAttendanceChartMode: (m: AttendanceChartMode) => void;
  setAttendanceGroupFilter: (groupId: string | null) => void;
  verifyGateQrToken: (rawToken: string) => void;
  scanQrForAttendance: (rawPayload: string) => void;
  addWalkInStudent: (name: string, phone: string, groupId: string, initialTopUpEgp: string) => void;
  toggleStudentBlocked: (student: StudentEntity) => void;
  addResource: (name: string, type: ResourceType, costEgp: string) => void;
  cycleResourceStatus: (resource: ResourceItem) => void;
  updateStudyBudgetMinutes: (minutes: number) => void;
  executeOrSeatRebalance: () => void;
  updateSettlementControls: (splitPercent: number, assistantWagesEgp: number) => void;
  addPaymentChannel: (name: string, type: string, accountRef: string, feeEgp: string) => void;
  toggleChannelActive: (channel: PaymentChannelEntity) => void;
  submitCenterPlanUpgrade: (plan: CenterPlanTier, channel: PaymentChannelEntity, senderRef: string) => void;
  generateQrForStudent: (student: StudentEntity) => void;
  dismissGeneratedQr: () => void;
  compressAndAttachReceipt: (file: File) => Promise<void>;
  clearCompressedReceipt: () => void;
  scanAttachedReceipt: () => Promise<void>;
  checkInStudent: (student: StudentEntity) => void;
  recordCashDeskEntry: (student: StudentEntity, kind: LedgerKind, amountEgpText: string, note: string) => void;
  voidLedgerEntry: (entryId: string, reason: string) => void;
  executeDailySettlement: (netPayoutPiasters: number, attendedCount: number) => void;
  createGroup: (name: string, schedule: string, capacityText: string, priceEgpText: string) => void;
  submitPaymentReceipt: (channel: PaymentChannelEntity, amountEgpText: string, senderRef: string) => void;
  approveSubmission: (submission: PaymentSubmissionEntity) => void;
  rejectSubmission: (submission: PaymentSubmissionEntity, reason: string) => void;
  openLecture: (unit: CourseUnit) => void;
  closeLecture: () => void;
  generateLessonRevisionDeck: (lessonTitle: string, lessonSummary: string) => Promise<void>;
  markActiveLectureCompleted: () => void;
  generateAdaptiveQuiz: (lessonTitle: string) => Promise<void>;
  resetAdaptiveQuiz: () => void;
  askStudyAssistant: (prompt: string, subject?: string, photoDataUrl?: string | null) => Promise<void>;
  requestOperationalBriefing: () => Promise<void>;
  evaluateTeacherPerformance: () => Promise<void>;
  evaluateStudentPerformance: (studentId?: string | null) => Promise<void>;
  buildEvaluationShareText: (evaluation: PerformanceEvaluationEntity) => string;
  refreshParentWeeklyDigest: () => Promise<void>;
  composeSecretaryNotice: (student: StudentEntity) => Promise<void>;
  dismissSecretaryNotice: () => void;
  generateTeacherLessonPlan: (group: GroupEntity) => Promise<void>;
  buildThermalReceipt: () => string;
}

const KashkoolContext = createContext<KashkoolContextValue | null>(null);

export const KashkoolProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [persisted, setPersisted] = useState<PersistedData>(() => loadPersisted());
  const [qrEpochSeconds, setQrEpochSeconds] = useState(() => Math.floor(Date.now() / 1000));

  // Transient states
  const [auth, setAuth] = useState<AuthUiState>({
    mode: AuthMode.QR,
    awaitingOtp: false,
    identifier: "",
    busy: false,
    errorMessage: null,
  });
  const [scannerScanCount, setScannerScanCount] = useState(0);
  const [lastScanFeedback, setLastScanFeedback] = useState<ScanFeedback | null>(null);
  const [qrVerificationBanner, setQrVerificationBanner] = useState<QrVerificationBanner | null>(null);
  const [snackbarMessage, setSnackbarMessage] = useState<string | null>(null);
  const [assistantMessages, setAssistantMessages] = useState<AssistantMessage[]>(() => [
    KashkoolMessageBuilders.initialAssistantMessage(),
  ]);
  const [assistantBusy, setAssistantBusy] = useState(false);
  const [assistantError, setAssistantError] = useState<string | null>(null);
  const [activeLectureId, setActiveLectureId] = useState<string | null>(null);
  const [activeLectureTitle, setActiveLectureTitle] = useState<string | null>(null);
  const [adaptiveQuizQuestions, setAdaptiveQuizQuestions] = useState<QuizQuestion[] | null>(null);
  const [adaptiveQuizTopic, setAdaptiveQuizTopic] = useState<string | null>(null);
  const [adaptiveQuizBusy, setAdaptiveQuizBusy] = useState(false);
  const [adaptiveQuizError, setAdaptiveQuizError] = useState<string | null>(null);
  const [syncBusy, setSyncBusy] = useState(false);
  const [supabaseConfigured, setSupabaseConfigured] = useState(false);
  const [generatedQrCode, setGeneratedQrCode] = useState<string | null>(null);
  const [generatedQrStudentName, setGeneratedQrStudentName] = useState<string | null>(null);
  const [compressedReceipt, setCompressedReceipt] = useState<CompressedReceiptResult | null>(null);
  const [receiptCompressing, setReceiptCompressing] = useState(false);
  const [reassurancePulseAtMillis, setReassurancePulseAtMillis] = useState(() => Date.now());
  const [rushModeEnabled, setRushModeEnabled] = useState(false);
  const [studyBudgetMinutes, setStudyBudgetMinutes] = useState(15);
  const [attendanceWindow, setAttendanceWindow] = useState<AttendanceWindow>(AttendanceWindow.DAYS_14);
  const [attendanceChartMode, setAttendanceChartMode] = useState<AttendanceChartMode>(
    AttendanceChartMode.AREA_TREND
  );
  const [attendanceGroupFilter, setAttendanceGroupFilter] = useState<string | null>(null);

  const [aiBriefingState, setAiBriefingState] = useState<AsyncUiState<AiOperationalBriefing>>({ status: "idle" });
  const [evaluationState, setEvaluationState] = useState<AsyncUiState<PerformanceEvaluationEntity>>({ status: "idle" });
  const [receiptScanState, setReceiptScanState] = useState<AsyncUiState<ReceiptScanResult>>({ status: "idle" });
  const [revisionDeckState, setRevisionDeckState] = useState<AsyncUiState<LessonRevisionDeck>>({ status: "idle" });
  const [parentDigestState, setParentDigestState] = useState<AsyncUiState<ParentWeeklyDigest>>({ status: "idle" });
  const [secretaryNoticeState, setSecretaryNoticeState] = useState<SecretaryNoticeUiState>({ status: "idle" });
  const [teacherPlanState, setTeacherPlanState] = useState<AsyncUiState<TeacherLessonPlan>>({ status: "idle" });

  // Sync HTML dir/lang with current language
  useEffect(() => {
    const isRtl = persisted.language === AppLanguage.AR;
    document.documentElement.lang = persisted.language;
    document.documentElement.dir = isRtl ? "rtl" : "ltr";
  }, [persisted.language]);

  // Persist to localStorage
  useEffect(() => {
    try {
      localStorage.setItem(STORAGE_KEY, JSON.stringify(persisted));
    } catch {
      // Ignore storage quota errors
    }
  }, [persisted]);

  // 1-second timer for 30s rotating HMAC tokens
  useEffect(() => {
    const timer = window.setInterval(() => {
      setQrEpochSeconds(Math.floor(Date.now() / 1000));
    }, 1000);
    return () => window.clearInterval(timer);
  }, []);

  // Auto-dismiss snackbar after 4 seconds
  useEffect(() => {
    if (!snackbarMessage) return;
    const id = window.setTimeout(() => setSnackbarMessage(null), 4000);
    return () => window.clearTimeout(id);
  }, [snackbarMessage]);

  // Bootstrap Supabase client & support ?autostart=1
  useEffect(() => {
    let cancelled = false;
    const params = new URLSearchParams(window.location.search);
    if (params.get("autostart") === "1") {
      setPersisted((p) => (p.signedIn ? p : { ...p, signedIn: true }));
    }

    let unsubscribe: () => void = () => undefined;
    void bootstrapSupabaseClient().then(async (client) => {
      if (cancelled || !client) return;
      setSupabaseConfigured(true);
      const { data } = await client.auth.getSession();
      if (!cancelled && data.session) {
        unsubscribe = subscribeToCenterRealtime("demo-centre", () => {
          setSnackbarMessage((prev) => prev ?? t("sync_done", persisted.language));
        });
      }
    });
    return () => {
      cancelled = true;
      unsubscribe();
    };
  }, []);

  const tr = useCallback((key: string) => t(key, persisted.language), [persisted.language]);
  const showSnackbar = useCallback((msg: string) => setSnackbarMessage(msg), []);
  const clearSnackbar = useCallback(() => setSnackbarMessage(null), []);

  const activeChannels = useMemo(
    () => persisted.channels.filter((c) => c.isActive),
    [persisted.channels]
  );

  const completedCourseSet = useMemo(
    () => new Set(persisted.completedCourseIds),
    [persisted.completedCourseIds]
  );

  const rescueItems: RescueItem[] = useMemo(() => {
    const pool = [...(adaptiveQuizQuestions ?? []), ...quizCatalog];
    return persisted.rescueIds
      .map((qId, idx) => {
        const q = pool.find((item) => item.id === qId);
        if (!q) return null;
        return {
          id: q.id,
          topicAr: q.topicTagAr,
          topicEn: q.topicTagEn,
          hintAr: q.remedialAr,
          hintEn: q.remedialEn,
          boostPercent: 4 + idx * 2,
        };
      })
      .filter((x): x is RescueItem => x !== null);
  }, [persisted.rescueIds, adaptiveQuizQuestions]);

  const shiftReconciliation: ShiftReconciliation = useMemo(() => {
    const approvedSubmissionTotal = persisted.submissions
      .filter((s) => s.status === SubmissionStatus.APPROVED)
      .reduce((acc, s) => acc + s.amountPiasters, 0);
    const grossCashAndCollections = persisted.ledger
      .filter(
        (e) =>
          e.kind === LedgerKind.CASH_TOPUP ||
          e.kind === LedgerKind.PARTIAL_INSTALLMENT ||
          e.kind === LedgerKind.BOOK_RESERVATION
      )
      .reduce((acc, e) => acc + e.amountPiasters, 0);
    const cashTotal = Math.max(0, grossCashAndCollections - approvedSubmissionTotal);
    const voidTotal = persisted.ledger
      .filter((e) => e.kind === LedgerKind.VOID_ENTRY)
      .reduce((acc, e) => acc + Math.abs(e.amountPiasters), 0);

    return {
      cashCollectedPiasters: cashTotal,
      electronicTransfersPiasters: approvedSubmissionTotal,
      voidedTotalPiasters: voidTotal,
      netDrawerCashPiasters: Math.max(0, cashTotal - voidTotal),
    };
  }, [persisted.ledger, persisted.submissions]);

  const operatingReport = useMemo(() => {
    const candidates = rescueItems.map((item, idx) => ({
      id: item.id,
      titleAr: item.topicAr,
      titleEn: item.topicEn,
      minutesRequired: 5 + idx * 2,
      masteryGainPercent: item.boostPercent,
    }));
    const courseCandidates = coursesCatalog.map((c) => ({
      id: c.id,
      titleAr: c.titleAr,
      titleEn: c.titleEn,
      dataEstimateMb: c.dataEstimateMb,
    }));
    return OperationsResearchEngine.evaluateSystem({
      role: persisted.activeRole,
      groups: persisted.groups,
      students: persisted.students,
      attendance: persisted.attendance,
      ledger: persisted.ledger,
      submissions: persisted.submissions,
      rescueCandidates: candidates,
      rushModeEnabled,
      resources: persisted.resources,
      assistantWagesPiasters: persisted.assistantWagesPiasters,
      splitPercentOverride: persisted.settlementSplitPercent,
      channels: activeChannels,
      courses: courseCandidates,
      completedCourseIds: completedCourseSet,
      lowDataMode: persisted.lowDataMode,
      studyBudgetMinutes,
    });
  }, [
    persisted.activeRole,
    persisted.groups,
    persisted.students,
    persisted.attendance,
    persisted.ledger,
    persisted.submissions,
    persisted.resources,
    persisted.assistantWagesPiasters,
    persisted.settlementSplitPercent,
    persisted.lowDataMode,
    rescueItems,
    rushModeEnabled,
    activeChannels,
    completedCourseSet,
    studyBudgetMinutes,
  ]);

  const attendanceDashboard = useMemo(
    () =>
      AttendanceAnalyticsEngine.compute({
        attendance: persisted.attendance,
        groups: persisted.groups,
        students: persisted.students,
        window: attendanceWindow,
        selectedGroupId: attendanceGroupFilter,
      }),
    [persisted.attendance, persisted.groups, persisted.students, attendanceWindow, attendanceGroupFilter]
  );

  const pendingSyncCount = useMemo(() => {
    return (
      persisted.groups.filter((g) => g.syncStatus === "pending").length +
      persisted.attendance.filter((a) => a.syncStatus === "pending").length +
      persisted.ledger.filter((l) => l.syncStatus === "pending").length +
      persisted.submissions.filter((s) => s.syncStatus === "pending").length +
      persisted.resources.filter((r) => r.syncStatus === "pending").length
    );
  }, [persisted.groups, persisted.attendance, persisted.ledger, persisted.submissions, persisted.resources]);

  const qrToken = useMemo(() => qrEngine.tokenAt(qrEpochSeconds), [qrEpochSeconds]);
  const qrSecondsRemaining = useMemo(() => qrEngine.secondsRemaining(qrEpochSeconds), [qrEpochSeconds]);

  const activeStudent = useMemo(() => {
    const match = /QR:([A-Za-z0-9]+)/.exec(persisted.userLabel);
    const qrCode = match?.[1];
    if (qrCode) {
      const found = persisted.students.find(
        (s) => s.qrActivationCode?.toLowerCase() === qrCode.toLowerCase()
      );
      if (found) return found;
    }
    return persisted.students.find((s) => s.id === "stu-1") ?? persisted.students[0];
  }, [persisted.students, persisted.userLabel]);

  const activeStudentQrToken = useMemo(
    () => (activeStudent ? qrEngine.studentTokenAt(activeStudent.id, qrEpochSeconds) : ""),
    [activeStudent, qrEpochSeconds]
  );

  const activeStudentCardCode = activeStudent?.qrActivationCode ?? "";
  const activeStudentCardPayload = useMemo(
    () =>
      activeStudent && activeStudentCardCode
        ? qrEngine.cardPayloadFor(activeStudent.id, activeStudentCardCode)
        : "",
    [activeStudent, activeStudentCardCode]
  );

  const activeStudentCheckedInToday = useMemo(() => {
    if (!activeStudent) return false;
    const todayStart = startOfDayMillis(Date.now());
    return persisted.attendance.some(
      (a) =>
        a.studentId === activeStudent.id &&
        a.sessionId === SESSION_ID &&
        a.timestampMillis >= todayStart &&
        a.feedbackStatus !== "blocked"
    );
  }, [activeStudent, persisted.attendance]);

  // Actions
  const toggleLanguage = useCallback(() => {
    setPersisted((p) => ({
      ...p,
      language: p.language === AppLanguage.AR ? AppLanguage.EN : AppLanguage.AR,
    }));
  }, []);

  const setAuthMode = useCallback((mode: AuthMode) => {
    setAuth({ mode, awaitingOtp: false, identifier: "", busy: false, errorMessage: null });
  }, []);

  const requestOtp = useCallback(
    (input: string) => {
      const trimmed = input.trim();
      if (auth.mode === AuthMode.PHONE) {
        const norm = EgyptValidators.normalizeEgyptianPhone(trimmed);
        if (!norm) {
          setAuth((a) => ({ ...a, errorMessage: t("err_invalid_phone", persisted.language) }));
          return;
        }
        setAuth((a) => ({ ...a, awaitingOtp: true, identifier: norm, errorMessage: null }));
        if (supabaseConfigured) {
          void requestSupabasePhoneOtp(norm);
        } else {
          setSnackbarMessage(
            persisted.language === AppLanguage.AR
              ? "استخدم أي 6 أرقام للمعاينة المحلية أو كود التفعيل"
              : "Enter any 6-digit code in local mode"
          );
        }
      } else if (auth.mode === AuthMode.EMAIL) {
        if (!trimmed.includes("@") || !trimmed.includes(".")) {
          setAuth((a) => ({ ...a, errorMessage: t("err_invalid_email", persisted.language) }));
          return;
        }
        const cleanEmail = trimmed.toLowerCase();
        setAuth((a) => ({ ...a, awaitingOtp: true, identifier: cleanEmail, errorMessage: null }));
        if (supabaseConfigured) {
          void requestSupabaseEmailOtp(cleanEmail);
        }
      }
    },
    [auth.mode, persisted.language, supabaseConfigured]
  );

  const verifyOtp = useCallback(
    (code: string) => {
      const cleanCode = code.trim();
      if (cleanCode.length !== 6) {
        setAuth((a) => ({ ...a, errorMessage: t("err_invalid_code", persisted.language) }));
        return;
      }

      if (supabaseConfigured && auth.identifier) {
        setAuth((a) => ({ ...a, busy: true, errorMessage: null }));
        const verifyPromise =
          auth.mode === AuthMode.EMAIL
            ? verifySupabaseEmailOtp(auth.identifier, cleanCode)
            : verifySupabasePhoneOtp(auth.identifier, cleanCode);
        void verifyPromise.then((res) => {
          if (res.ok) {
            setPersisted((p) => ({
              ...p,
              signedIn: true,
              activeRole: UserRole.STUDENT,
              userLabel: auth.identifier || "+201012345678",
            }));
            setAuth({ mode: AuthMode.QR, awaitingOtp: false, identifier: "", busy: false, errorMessage: null });
          } else {
            setAuth((a) => ({
              ...a,
              busy: false,
              errorMessage: res.error || t("err_invalid_code", persisted.language),
            }));
          }
        });
        return;
      }

      setPersisted((p) => ({
        ...p,
        signedIn: true,
        activeRole: UserRole.STUDENT,
        userLabel: auth.identifier || "+201012345678",
      }));
      setAuth({ mode: AuthMode.QR, awaitingOtp: false, identifier: "", busy: false, errorMessage: null });
    },
    [auth.identifier, auth.mode, persisted.language, supabaseConfigured]
  );

  const activateWithQr = useCallback(
    (code: string) => {
      if (!EgyptValidators.isValidQrActivationCode(code)) {
        setAuth((a) => ({ ...a, errorMessage: t("err_invalid_qr", persisted.language) }));
        return;
      }
      const norm = EgyptValidators.normalizeQrCode(code);
      setPersisted((p) => {
        const matched = p.students.find((s) => s.qrActivationCode?.toUpperCase() === norm);
        const label = matched ? `${matched.nameAr} · QR:${norm}` : `QR:${norm}`;
        return { ...p, signedIn: true, activeRole: UserRole.STUDENT, userLabel: label };
      });
      setAuth({ mode: AuthMode.QR, awaitingOtp: false, identifier: "", busy: false, errorMessage: null });
    },
    [persisted.language]
  );

  const enterOfflineWorkspace = useCallback((role: UserRole) => {
    const labelMap: Record<UserRole, string> = {
      [UserRole.STUDENT]: "+201012345678 · أحمد محمد",
      [UserRole.SECRETARY]: "مكتب السكرتارية · سنتر النخبة",
      [UserRole.TEACHER]: "أ. طارق عزت · الرياضيات والفيزياء",
      [UserRole.PARENT]: "ولي أمر · أحمد محمد",
    };
    setPersisted((p) => ({ ...p, signedIn: true, activeRole: role, userLabel: labelMap[role] }));
  }, []);

  const switchRole = useCallback((role: UserRole) => {
    setPersisted((p) => ({ ...p, activeRole: role }));
    setAiBriefingState({ status: "idle" });
  }, []);

  const signOut = useCallback(() => {
    void signOutSupabase();
    setPersisted((p) => ({ ...p, signedIn: false }));
  }, []);

  const syncNow = useCallback(() => {
    setSyncBusy(true);
    void syncPendingToSupabase({
      tenantId: "demo-centre",
      groups: persisted.groups,
      students: persisted.students,
      attendance: persisted.attendance,
      ledger: persisted.ledger,
      submissions: persisted.submissions,
      channels: persisted.channels,
    }).then((result) => {
      if (!result.error) {
        setPersisted((p) => ({
          ...p,
          groups: p.groups.map((g) => ({ ...g, syncStatus: "synced" })),
          attendance: p.attendance.map((a) => ({ ...a, syncStatus: "synced" })),
          ledger: p.ledger.map((l) => ({ ...l, syncStatus: "synced" })),
          submissions: p.submissions.map((s) => ({ ...s, syncStatus: "synced" })),
          resources: p.resources.map((r) => ({ ...r, syncStatus: "synced" })),
        }));
      }
      setSyncBusy(false);
      setSnackbarMessage(result.error ?? t("sync_done", persisted.language));
    });
  }, [
    persisted.language,
    persisted.groups,
    persisted.students,
    persisted.attendance,
    persisted.ledger,
    persisted.submissions,
    persisted.channels,
  ]);

  const toggleLowDataMode = useCallback(() => {
    setPersisted((p) => ({ ...p, lowDataMode: !p.lowDataMode }));
  }, []);

  const toggleStreakShield = useCallback(() => {
    setPersisted((p) => ({ ...p, streakShieldActive: !p.streakShieldActive }));
  }, []);

  const completeRescueItem = useCallback((questionId: string) => {
    setPersisted((p) => ({
      ...p,
      rescueIds: p.rescueIds.filter((id) => id !== questionId),
    }));
  }, []);

  const recordQuizOutcome = useCallback((questionId: string, correct: boolean) => {
    setPersisted((p) => {
      const next = new Set(p.rescueIds);
      if (correct) next.delete(questionId);
      else next.add(questionId);
      return { ...p, rescueIds: Array.from(next) };
    });
  }, []);

  const triggerParentReassurance = useCallback(() => {
    setReassurancePulseAtMillis(Date.now());
    setSnackbarMessage(t("parent_reassure_title", persisted.language));
  }, [persisted.language]);

  const buildEncouragementMessage = useCallback(
    () => KashkoolMessageBuilders.buildEncouragementMessage(persisted.students[0], persisted.language),
    [persisted.students, persisted.language]
  );

  const buildParentReportShareText = useCallback(
    () =>
      KashkoolMessageBuilders.buildParentReportShareText(
        persisted.students[0],
        persisted.attendance,
        persisted.language
      ),
    [persisted.students, persisted.attendance, persisted.language]
  );

  const notifyMessageCopied = useCallback(() => {
    setSnackbarMessage(t("parent_cheer_copied", persisted.language));
  }, [persisted.language]);

  const toggleRushMode = useCallback(() => setRushModeEnabled((v) => !v), []);

  const checkInStudent = useCallback(
    (student: StudentEntity) => {
      const status: "valid" | "due" | "blocked" = student.isBlocked
        ? "blocked"
        : student.dueBalancePiasters > 0
          ? "due"
          : "valid";
      const rec: AttendanceEntity = {
        id: `att-${crypto.randomUUID()}`,
        studentId: student.id,
        studentNameAr: student.nameAr,
        studentNameEn: student.nameEn,
        groupId: student.groupId,
        sessionId: SESSION_ID,
        feedbackStatus: status,
        timestampMillis: Date.now(),
        syncStatus: "pending",
      };
      setPersisted((p) => ({
        ...p,
        attendance: [rec, ...p.attendance],
        students: student.isBlocked
          ? p.students
          : p.students.map((s) => (s.id === student.id ? { ...s, streakDays: s.streakDays + 1 } : s)),
      }));
      const name = persisted.language === AppLanguage.AR ? student.nameAr : student.nameEn;
      setLastScanFeedback({
        studentName: name,
        status,
        detail: "",
        alreadyCheckedIn: false,
        timestampMillis: Date.now(),
      });
    },
    [persisted.language]
  );

  const discreetAllowWithParentNotice = useCallback(
    (student: StudentEntity) => {
      checkInStudent(student);
      const name = persisted.language === AppLanguage.AR ? student.nameAr : student.nameEn;
      setLastScanFeedback({
        studentName: name,
        status: "due",
        detail: "",
        alreadyCheckedIn: false,
        timestampMillis: Date.now(),
      });
      setSnackbarMessage(t("discreet_due_done", persisted.language));
    },
    [checkInStudent, persisted.language]
  );

  const notifyQrCopied = useCallback(() => {
    setSnackbarMessage(t("student_qr_copied", persisted.language));
  }, [persisted.language]);

  const verifyGateQrToken = useCallback((rawToken: string) => {
    const trimmed = rawToken.trim();
    if (
      trimmed.startsWith("KSHS|") ||
      trimmed.startsWith("KSHC|") ||
      EgyptValidators.isValidQrActivationCode(trimmed)
    ) {
      scanQrForAttendance(trimmed);
      return;
    }
    const result = qrEngine.verifyToken(trimmed);
    setQrVerificationBanner({
      status: result.status,
      tokenPreview: trimmed.slice(0, 28),
      checkedAtMillis: Date.now(),
    });
  }, []);

  const scanQrForAttendance = useCallback(
    (rawPayload: string) => {
      const lang = persisted.language;
      const preview = rawPayload.trim().slice(0, 28);
      const verified = qrEngine.verifyScannedPayload(rawPayload);

      if (verified.status === QrVerifyStatus.EXPIRED) {
        const msg = t("qr_result_expired", lang);
        setLastScanFeedback({
          studentName: msg,
          status: "due",
          detail: preview,
          alreadyCheckedIn: false,
          timestampMillis: Date.now(),
        });
        setQrVerificationBanner({ status: QrVerifyStatus.EXPIRED, tokenPreview: preview, checkedAtMillis: Date.now() });
        setSnackbarMessage(msg);
        return;
      }

      if (verified.status === QrVerifyStatus.INVALID) {
        const msg = t("qr_result_invalid", lang);
        setLastScanFeedback({
          studentName: msg,
          status: "blocked",
          detail: preview,
          alreadyCheckedIn: false,
          timestampMillis: Date.now(),
        });
        setQrVerificationBanner({ status: QrVerifyStatus.INVALID, tokenPreview: preview, checkedAtMillis: Date.now() });
        setSnackbarMessage(msg);
        return;
      }

      if (verified.kind === QrPayloadKind.SESSION_GATE) {
        setQrVerificationBanner({ status: QrVerifyStatus.VALID, tokenPreview: preview, checkedAtMillis: Date.now() });
        setSnackbarMessage(t("qr_result_valid", lang));
        return;
      }

      const resolved =
        (verified.studentId ? persisted.students.find((s) => s.id === verified.studentId) : undefined) ??
        (verified.activationCode
          ? persisted.students.find(
              (s) => s.qrActivationCode?.toUpperCase() === verified.activationCode?.toUpperCase()
            )
          : undefined);

      if (!resolved) {
        const msg = t("qr_student_not_found", lang);
        setLastScanFeedback({
          studentName: msg,
          status: "blocked",
          detail: preview,
          alreadyCheckedIn: false,
          timestampMillis: Date.now(),
        });
        setQrVerificationBanner({ status: QrVerifyStatus.INVALID, tokenPreview: preview, checkedAtMillis: Date.now() });
        setSnackbarMessage(msg);
        return;
      }

      const name = lang === AppLanguage.AR ? resolved.nameAr : resolved.nameEn;

      if (resolved.isBlocked) {
        checkInStudent(resolved);
        setLastScanFeedback({
          studentName: name,
          status: "blocked",
          detail: t("scan_blocked", lang),
          alreadyCheckedIn: false,
          timestampMillis: Date.now(),
        });
        setQrVerificationBanner({ status: QrVerifyStatus.INVALID, tokenPreview: preview, checkedAtMillis: Date.now() });
        setSnackbarMessage(`${name} · ${t("scan_blocked", lang)}`);
        return;
      }

      const todayStart = startOfDayMillis(Date.now());
      const already = persisted.attendance.some(
        (a) =>
          a.studentId === resolved.id &&
          a.sessionId === SESSION_ID &&
          a.timestampMillis >= todayStart &&
          a.feedbackStatus !== "blocked"
      );

      if (already) {
        setLastScanFeedback({
          studentName: name,
          status: "already",
          detail: t("qr_already_checked_in", lang),
          alreadyCheckedIn: true,
          timestampMillis: Date.now(),
        });
        setQrVerificationBanner({ status: QrVerifyStatus.VALID, tokenPreview: preview, checkedAtMillis: Date.now() });
        setSnackbarMessage(`${name} · ${t("qr_already_checked_in", lang)}`);
        return;
      }

      checkInStudent(resolved);
      setScannerScanCount((c) => c + 1);
      setQrVerificationBanner({ status: QrVerifyStatus.VALID, tokenPreview: preview, checkedAtMillis: Date.now() });

      if (resolved.dueBalancePiasters > 0) {
        const dueFormatted = EgyptValidators.formatPiasters(resolved.dueBalancePiasters, lang);
        setLastScanFeedback({
          studentName: name,
          status: "due",
          detail: `${t("due_balance", lang)}: ${dueFormatted}`,
          alreadyCheckedIn: false,
          timestampMillis: Date.now(),
        });
        setSnackbarMessage(
          lang === AppLanguage.AR
            ? `تم حضور ${name} · متبقي ${dueFormatted}`
            : `${name} checked in · Due ${dueFormatted}`
        );
      } else {
        setLastScanFeedback({
          studentName: name,
          status: "valid",
          detail: t("scan_valid", lang),
          alreadyCheckedIn: false,
          timestampMillis: Date.now(),
        });
        setSnackbarMessage(lang === AppLanguage.AR ? `تم تسجيل حضور ${name}` : `Checked in ${name}`);
      }
    },
    [persisted.language, persisted.students, persisted.attendance, checkInStudent]
  );

  const appendFinancialEntryInternal = useCallback(
    (
      studentId: string,
      kind: LedgerKind,
      amountPiasters: number,
      note: string,
      role: UserRole
    ) => {
      const now = Date.now();
      setPersisted((p) => {
        const target = p.students.find((s) => s.id === studentId);
        if (!target) return p;
        let newWallet = target.walletBalancePiasters;
        let newDue = target.dueBalancePiasters;

        switch (kind) {
          case LedgerKind.CASH_TOPUP:
            newWallet += amountPiasters;
            break;
          case LedgerKind.PARTIAL_INSTALLMENT: {
            const paidTowardsDue = Math.min(newDue, amountPiasters);
            newDue = Math.max(0, newDue - paidTowardsDue);
            newWallet += amountPiasters - paidTowardsDue;
            break;
          }
          case LedgerKind.BOOK_RESERVATION:
            if (newWallet >= amountPiasters) {
              newWallet -= amountPiasters;
            } else {
              newDue += amountPiasters - newWallet;
              newWallet = 0;
            }
            break;
          case LedgerKind.DISCOUNT:
            newDue = Math.max(0, newDue - amountPiasters);
            break;
          default:
            break;
        }

        const entry: LedgerEntryEntity = {
          id: `led-${crypto.randomUUID()}`,
          studentId: target.id,
          studentNameAr: target.nameAr,
          studentNameEn: target.nameEn,
          kind,
          amountPiasters,
          remainingDuePiasters: newDue,
          note,
          createdByRole: role,
          createdAtMillis: now,
          syncStatus: "pending",
        };

        return {
          ...p,
          students: p.students.map((s) =>
            s.id === studentId ? { ...s, walletBalancePiasters: newWallet, dueBalancePiasters: newDue } : s
          ),
          ledger: [entry, ...p.ledger],
        };
      });
    },
    []
  );

  const addWalkInStudent = useCallback(
    (name: string, phone: string, groupId: string, initialTopUpEgp: string) => {
      if (!name.trim() || !groupId) return;
      const topUp = EgyptValidators.egpStringToPiasters(initialTopUpEgp) ?? 0;
      const cleanPhone = EgyptValidators.normalizeEgyptianPhone(phone) || phone.trim();
      const newId = `stu-${crypto.randomUUID()}`;
      const newStudent: StudentEntity = {
        id: newId,
        nameAr: name.trim(),
        nameEn: name.trim(),
        phone: cleanPhone,
        groupId,
        walletBalancePiasters: 0,
        dueBalancePiasters: 0,
        streakDays: 1,
        masteryPercent: 75,
        isBlocked: false,
        qrActivationCode: EgyptValidators.generateActivationCode(8),
      };

      setPersisted((p) => ({
        ...p,
        students: [newStudent, ...p.students],
        groups: p.groups.map((g) =>
          g.id === groupId ? { ...g, enrolled: Math.min(g.capacity, g.enrolled + 1), syncStatus: "pending" } : g
        ),
      }));

      if (topUp > 0) {
        appendFinancialEntryInternal(
          newId,
          LedgerKind.CASH_TOPUP,
          topUp,
          "تسجيل فوري وشحن مبدئي على الباب",
          UserRole.SECRETARY
        );
      }
      setSnackbarMessage(t("walkin_added", persisted.language));
    },
    [appendFinancialEntryInternal, persisted.language]
  );

  const toggleStudentBlocked = useCallback((student: StudentEntity) => {
    setPersisted((p) => ({
      ...p,
      students: p.students.map((s) => (s.id === student.id ? { ...s, isBlocked: !s.isBlocked } : s)),
    }));
  }, []);

  const addResource = useCallback((name: string, type: ResourceType, costEgp: string) => {
    if (!name.trim()) return;
    const costPiasters = EgyptValidators.egpStringToPiasters(costEgp) ?? 0;
    const item: ResourceItem = {
      id: `res-${crypto.randomUUID()}`,
      name: name.trim(),
      type,
      availabilityStatus: AvailabilityStatus.AVAILABLE,
      tenantId: "demo-centre",
      costPiasters,
      syncStatus: "pending",
      updatedAtMillis: Date.now(),
    };
    setPersisted((p) => ({ ...p, resources: [item, ...p.resources] }));
  }, []);

  const cycleResourceStatus = useCallback((resource: ResourceItem) => {
    const order: AvailabilityStatus[] = [
      AvailabilityStatus.AVAILABLE,
      AvailabilityStatus.IN_USE,
      AvailabilityStatus.RESERVED,
      AvailabilityStatus.UNAVAILABLE,
    ];
    const next = order[(order.indexOf(resource.availabilityStatus) + 1) % order.length];
    setPersisted((p) => ({
      ...p,
      resources: p.resources.map((r) =>
        r.id === resource.id ? { ...r, availabilityStatus: next, updatedAtMillis: Date.now(), syncStatus: "pending" } : r
      ),
    }));
  }, []);

  const updateStudyBudgetMinutes = useCallback((minutes: number) => {
    setStudyBudgetMinutes(Math.min(60, Math.max(10, minutes)));
  }, []);

  const executeOrSeatRebalance = useCallback(() => {
    const alloc = operatingReport.groupAllocation;
    const plans =
      alloc.transferPlans.length > 0
        ? alloc.transferPlans
        : alloc.bottleneckGroupId && alloc.slackGroupId && alloc.recommendedSeatShift > 0
          ? [
              {
                fromGroupId: alloc.bottleneckGroupId,
                toGroupId: alloc.slackGroupId,
                seatsToMove: alloc.recommendedSeatShift,
              },
            ]
          : [];
    if (plans.length === 0) return;

    let shiftedAny = false;
    setPersisted((p) => {
      let groups = [...p.groups];
      let students = [...p.students];
      for (const plan of plans) {
        const fromIdx = groups.findIndex((g) => g.id === plan.fromGroupId);
        const toIdx = groups.findIndex((g) => g.id === plan.toGroupId);
        if (fromIdx === -1 || toIdx === -1) continue;
        const fromG = groups[fromIdx];
        const toG = groups[toIdx];
        const actual = Math.min(plan.seatsToMove, fromG.enrolled, Math.max(0, toG.capacity - toG.enrolled));
        if (actual <= 0) continue;
        shiftedAny = true;
        groups[fromIdx] = { ...fromG, enrolled: fromG.enrolled - actual, syncStatus: "pending" };
        groups[toIdx] = { ...toG, enrolled: toG.enrolled + actual, syncStatus: "pending" };
        let movedStu = 0;
        students = students.map((st) => {
          if (st.groupId === fromG.id && movedStu < actual) {
            movedStu++;
            return { ...st, groupId: toG.id };
          }
          return st;
        });
      }
      return { ...p, groups, students };
    });

    if (shiftedAny) {
      setSnackbarMessage(t("rebalance_done", persisted.language));
    }
  }, [operatingReport.groupAllocation, persisted.language]);

  const updateSettlementControls = useCallback((splitPercent: number, assistantWagesEgp: number) => {
    setPersisted((p) => ({
      ...p,
      settlementSplitPercent: Math.min(50, Math.max(5, splitPercent)),
      assistantWagesPiasters: Math.min(100_000, Math.max(0, assistantWagesEgp * 100)),
    }));
  }, []);

  const addPaymentChannel = useCallback(
    (name: string, type: string, accountRef: string, feeEgp: string) => {
      if (!name.trim() || !accountRef.trim()) return;
      const feePiasters = EgyptValidators.egpStringToPiasters(feeEgp) ?? 0;
      const newCh: PaymentChannelEntity = {
        id: `ch-${Date.now()}`,
        nameAr: name.trim(),
        nameEn: name.trim(),
        channelType: type,
        accountRef: accountRef.trim(),
        maxAmountPiasters: 500_000,
        feePiasters,
        isActive: true,
      };
      setPersisted((p) => ({ ...p, channels: [...p.channels, newCh] }));
    },
    []
  );

  const toggleChannelActive = useCallback((channel: PaymentChannelEntity) => {
    setPersisted((p) => ({
      ...p,
      channels: p.channels.map((c) => (c.id === channel.id ? { ...c, isActive: !c.isActive } : c)),
    }));
  }, []);

  const submitCenterPlanUpgrade = useCallback(
    (plan: CenterPlanTier, channel: PaymentChannelEntity, senderRef: string) => {
      const lang = persisted.language;
      const planName = lang === AppLanguage.AR ? plan.nameAr : plan.nameEn;
      const sub: PaymentSubmissionEntity = {
        id: `plan-sub-${plan.id}-${crypto.randomUUID()}`,
        studentId: "center-owner",
        studentNameAr: `اشتراك سنتر النخبة · ${planName}`,
        studentNameEn: `Center Subscription · ${planName}`,
        channelId: channel.id,
        channelName: lang === AppLanguage.AR ? channel.nameAr : channel.nameEn,
        amountPiasters: plan.monthlyPiasters,
        senderReference: senderRef.trim(),
        receiptUri: null,
        status: SubmissionStatus.PENDING,
        createdAtMillis: Date.now(),
        syncStatus: "pending",
      };
      setPersisted((p) => ({ ...p, submissions: [sub, ...p.submissions] }));
      setSnackbarMessage(t("plan_submitted", lang));
    },
    [persisted.language]
  );

  const generateQrForStudent = useCallback(
    (student: StudentEntity) => {
      const code = EgyptValidators.generateActivationCode(8);
      setPersisted((p) => ({
        ...p,
        students: p.students.map((s) => (s.id === student.id ? { ...s, qrActivationCode: code } : s)),
      }));
      const name = persisted.language === AppLanguage.AR ? student.nameAr : student.nameEn;
      setGeneratedQrCode(code);
      setGeneratedQrStudentName(name);
    },
    [persisted.language]
  );

  const dismissGeneratedQr = useCallback(() => {
    setGeneratedQrCode(null);
    setGeneratedQrStudentName(null);
  }, []);

  const compressAndAttachReceipt = useCallback(
    async (file: File) => {
      setReceiptCompressing(true);
      setReceiptScanState({ status: "idle" });
      try {
        const res = await compressImageFile(file);
        setCompressedReceipt(res);
      } catch {
        setSnackbarMessage(t("compression_failed", persisted.language));
      } finally {
        setReceiptCompressing(false);
      }
    },
    [persisted.language]
  );

  const clearCompressedReceipt = useCallback(() => {
    setCompressedReceipt(null);
    setReceiptScanState({ status: "idle" });
  }, []);

  const scanAttachedReceipt = useCallback(async () => {
    if (!compressedReceipt) return;
    const lang = persisted.language;
    setReceiptScanState({ status: "loading" });
    try {
      const result = await AiToolkitClient.scanPaymentReceipt(compressedReceipt.dataUrl, lang);
      setReceiptScanState({ status: "success", data: result });
    } catch (err) {
      setReceiptScanState({
        status: "error",
        message: err instanceof Error ? err.message : t("scan_receipt_error", lang),
      });
    }
  }, [compressedReceipt, persisted.language]);

  const recordCashDeskEntry = useCallback(
    (student: StudentEntity, kind: LedgerKind, amountEgpText: string, note: string) => {
      const piasters = EgyptValidators.egpStringToPiasters(amountEgpText);
      if (!piasters) return;
      const finalNote = note.trim() || ledgerKindLabel(kind, persisted.language);
      appendFinancialEntryInternal(student.id, kind, piasters, finalNote, persisted.activeRole);
      const formatted = EgyptValidators.formatPiasters(piasters, persisted.language);
      setSnackbarMessage(
        persisted.language === AppLanguage.AR
          ? `تم تسجيل ${formatted} بنجاح`
          : `Recorded ${formatted} to ledger`
      );
    },
    [appendFinancialEntryInternal, persisted.language, persisted.activeRole]
  );

  const voidLedgerEntry = useCallback(
    (entryId: string, reason: string) => {
      if (!reason.trim()) return;
      setPersisted((p) => {
        const original = p.ledger.find((l) => l.id === entryId);
        if (!original || original.kind === LedgerKind.VOID_ENTRY) return p;
        const students =
          original.kind === LedgerKind.CASH_TOPUP
            ? p.students.map((s) =>
                s.id === original.studentId
                  ? { ...s, walletBalancePiasters: Math.max(0, s.walletBalancePiasters - original.amountPiasters) }
                  : s
              )
            : p.students;
        const voidEntry: LedgerEntryEntity = {
          id: `void-${crypto.randomUUID()}`,
          studentId: original.studentId,
          studentNameAr: original.studentNameAr,
          studentNameEn: original.studentNameEn,
          kind: LedgerKind.VOID_ENTRY,
          amountPiasters: -original.amountPiasters,
          remainingDuePiasters: 0,
          note: reason.trim(),
          voidedEntryId: original.id,
          createdByRole: p.activeRole,
          createdAtMillis: Date.now(),
          syncStatus: "pending",
        };
        return { ...p, students, ledger: [voidEntry, ...p.ledger] };
      });
      setSnackbarMessage(
        persisted.language === AppLanguage.AR ? "تم تسجيل عكس القيد في الدفتر" : "Void entry appended"
      );
    },
    [persisted.language]
  );

  const executeDailySettlement = useCallback(
    (netPayoutPiasters: number, attendedCount: number) => {
      const entry: LedgerEntryEntity = {
        id: `settle-${crypto.randomUUID()}`,
        studentId: "center-settlement",
        studentNameAr: "تسوية نهاية اليوم",
        studentNameEn: "End-of-Day Settlement",
        kind: LedgerKind.SETTLEMENT,
        amountPiasters: netPayoutPiasters,
        remainingDuePiasters: 0,
        note: `تسوية يومية تلقائية · ${attendedCount} حضور`,
        createdByRole: UserRole.TEACHER,
        createdAtMillis: Date.now(),
        syncStatus: "pending",
      };
      setPersisted((p) => ({ ...p, ledger: [entry, ...p.ledger] }));
      setSnackbarMessage(t("settlement_done", persisted.language));
    },
    [persisted.language]
  );

  const createGroup = useCallback(
    (name: string, schedule: string, capacityText: string, priceEgpText: string) => {
      if (!name.trim()) return;
      const capacity = Math.max(1, Number.parseInt(capacityText.trim(), 10) || 40);
      const pricePiasters = EgyptValidators.egpStringToPiasters(priceEgpText) ?? 8000;
      const newGroup: GroupEntity = {
        id: `grp-${Date.now()}`,
        nameAr: name.trim(),
        nameEn: name.trim(),
        subjectAr: "الثانوية العامة",
        subjectEn: "High School",
        scheduleAr: schedule.trim() || "السبت والثلاثاء 4 م",
        scheduleEn: schedule.trim() || "Sat & Tue 4:00 PM",
        enrolled: 0,
        capacity,
        pricePerSessionPiasters: pricePiasters,
        centerSplitPercent: 20,
        syncStatus: "pending",
      };
      setPersisted((p) => ({ ...p, groups: [...p.groups, newGroup] }));
    },
    []
  );

  const submitPaymentReceipt = useCallback(
    (channel: PaymentChannelEntity, amountEgpText: string, senderRef: string) => {
      const piasters = EgyptValidators.egpStringToPiasters(amountEgpText);
      if (!piasters || !senderRef.trim()) return;
      const lang = persisted.language;
      const sub: PaymentSubmissionEntity = {
        id: `sub-${crypto.randomUUID()}`,
        studentId: "stu-1",
        studentNameAr: "أحمد محمد علي",
        studentNameEn: "Ahmed Mohamed Ali",
        channelId: channel.id,
        channelName: lang === AppLanguage.AR ? channel.nameAr : channel.nameEn,
        amountPiasters: piasters,
        senderReference: senderRef.trim(),
        receiptUri: compressedReceipt?.dataUrl ?? null,
        status: SubmissionStatus.PENDING,
        createdAtMillis: Date.now(),
        syncStatus: "pending",
      };
      setPersisted((p) => ({ ...p, submissions: [sub, ...p.submissions] }));
      setCompressedReceipt(null);
      setReceiptScanState({ status: "idle" });
      setSnackbarMessage(lang === AppLanguage.AR ? "تم إرسال الإيصال للمراجعة" : "Receipt submitted");
    },
    [persisted.language, compressedReceipt]
  );

  const approveSubmission = useCallback(
    (submission: PaymentSubmissionEntity) => {
      if (submission.status !== SubmissionStatus.PENDING) return;
      if (submission.studentId === "center-owner") {
        const resolvedPlan =
          submission.id.includes("plan-enterprise") || submission.amountPiasters >= 150_000
            ? "plan-enterprise"
            : submission.id.includes("plan-pro") || submission.amountPiasters >= 75_000
              ? "plan-pro"
              : "plan-starter";
        const planLedger: LedgerEntryEntity = {
          id: `led-plan-${crypto.randomUUID()}`,
          studentId: "center-owner",
          studentNameAr: submission.studentNameAr,
          studentNameEn: submission.studentNameEn,
          kind: LedgerKind.SETTLEMENT,
          amountPiasters: submission.amountPiasters,
          remainingDuePiasters: 0,
          note: `${submission.channelName} · ${submission.senderReference}`,
          createdByRole: UserRole.TEACHER,
          createdAtMillis: Date.now(),
          syncStatus: "pending",
        };
        setPersisted((p) => ({
          ...p,
          activeCenterPlanId: resolvedPlan,
          submissions: p.submissions.map((s) =>
            s.id === submission.id ? { ...s, status: SubmissionStatus.APPROVED } : s
          ),
          ledger: [planLedger, ...p.ledger],
        }));
        return;
      }

      setPersisted((p) => ({
        ...p,
        submissions: p.submissions.map((s) =>
          s.id === submission.id ? { ...s, status: SubmissionStatus.APPROVED } : s
        ),
      }));
      appendFinancialEntryInternal(
        submission.studentId,
        LedgerKind.CASH_TOPUP,
        submission.amountPiasters,
        `${submission.channelName} · ${submission.senderReference}`,
        UserRole.SECRETARY
      );
    },
    [appendFinancialEntryInternal]
  );

  const rejectSubmission = useCallback((submission: PaymentSubmissionEntity, reason: string) => {
    if (!reason.trim() || submission.status !== SubmissionStatus.PENDING) return;
    setPersisted((p) => ({
      ...p,
      submissions: p.submissions.map((s) =>
        s.id === submission.id
          ? { ...s, status: SubmissionStatus.REJECTED, rejectionReason: reason.trim() }
          : s
      ),
    }));
  }, []);

  const openLecture = useCallback(
    (unit: CourseUnit) => {
      setActiveLectureId(unit.id);
      setActiveLectureTitle(persisted.language === AppLanguage.AR ? unit.titleAr : unit.titleEn);
      setRevisionDeckState({ status: "idle" });
    },
    [persisted.language]
  );

  const closeLecture = useCallback(() => {
    setActiveLectureId(null);
    setActiveLectureTitle(null);
    setRevisionDeckState({ status: "idle" });
  }, []);

  const generateLessonRevisionDeck = useCallback(
    async (lessonTitle: string, lessonSummary: string) => {
      setRevisionDeckState({ status: "loading" });
      try {
        const deck = await AiToolkitClient.generateLessonRevisionDeck(
          lessonTitle,
          lessonSummary,
          persisted.language
        );
        setRevisionDeckState({ status: "success", data: deck });
      } catch (err) {
        setRevisionDeckState({
          status: "error",
          message: err instanceof Error ? err.message : t("revision_deck_error", persisted.language),
        });
      }
    },
    [persisted.language]
  );

  const markActiveLectureCompleted = useCallback(() => {
    if (!activeLectureId) return;
    setPersisted((p) => {
      const exists = p.completedCourseIds.includes(activeLectureId);
      if (exists) return p;
      return {
        ...p,
        completedCourseIds: [...p.completedCourseIds, activeLectureId],
        students: p.students.map((s) =>
          s.id === "stu-1" ? { ...s, masteryPercent: Math.min(100, s.masteryPercent + 3) } : s
        ),
      };
    });
    setSnackbarMessage(t("lesson_completed_badge", persisted.language));
  }, [activeLectureId, persisted.language]);

  const generateAdaptiveQuiz = useCallback(
    async (lessonTitle: string) => {
      setAdaptiveQuizBusy(true);
      setAdaptiveQuizError(null);
      setAdaptiveQuizTopic(lessonTitle);
      try {
        const questions = await AiToolkitClient.generateAdaptiveQuiz(lessonTitle, persisted.language);
        setAdaptiveQuizQuestions(questions);
      } catch (err) {
        setAdaptiveQuizError(err instanceof Error ? err.message : "Adaptive quiz unavailable");
      } finally {
        setAdaptiveQuizBusy(false);
      }
    },
    [persisted.language]
  );

  const resetAdaptiveQuiz = useCallback(() => {
    setAdaptiveQuizQuestions(null);
    setAdaptiveQuizTopic(null);
    setAdaptiveQuizError(null);
  }, []);

  const askStudyAssistant = useCallback(
    async (prompt: string, subject = "الرياضيات والفيزياء", photoDataUrl: string | null = null) => {
      const lang = persisted.language;
      const clean =
        prompt.trim() ||
        (photoDataUrl
          ? lang === AppLanguage.AR
            ? "اشرح وحل هذه المسألة خطوة بخطوة"
            : "Solve and explain this problem step by step"
          : "");
      if (!clean) return;

      const userMsg: AssistantMessage = {
        id: `msg-u-${Date.now()}`,
        fromUser: true,
        text: clean,
        suggestions: [],
        attachedPhotoDataUrl: photoDataUrl,
      };
      const priorHistory = assistantMessages;
      const botId = `msg-b-${Date.now() + 1}`;
      setAssistantMessages((prev) => [...prev, userMsg]);
      setAssistantBusy(true);
      setAssistantError(null);

      try {
        let addedBubble = false;
        const fullText = await AiToolkitClient.streamStudyChat({
          prompt: clean,
          history: priorHistory,
          photoDataUrl,
          role: persisted.activeRole,
          subject,
          report: operatingReport,
          lang,
          onChunk: (accumulated) => {
            setAssistantMessages((prev) => {
              if (!addedBubble) {
                addedBubble = true;
                return [...prev, { id: botId, fromUser: false, text: accumulated, suggestions: [] }];
              }
              return prev.map((m) => (m.id === botId ? { ...m, text: accumulated } : m));
            });
          },
        });
        const followUps =
          lang === AppLanguage.AR
            ? ["اشرح الخطوة السابقة ببساطة", "أعطني مسألة تدريب"]
            : ["Explain the last step simply", "Give me a practice problem"];
        setAssistantMessages((prev) =>
          prev.map((m) => (m.id === botId ? { ...m, text: fullText, suggestions: followUps } : m))
        );
      } catch (err) {
        setAssistantError(err instanceof Error ? err.message : "Assistant unavailable");
      } finally {
        setAssistantBusy(false);
      }
    },
    [assistantMessages, persisted.language, persisted.activeRole, operatingReport]
  );

  const requestOperationalBriefing = useCallback(async () => {
    setAiBriefingState({ status: "loading" });
    try {
      const briefing = await AiToolkitClient.generateOperationalBriefing(
        operatingReport,
        persisted.activeRole,
        persisted.language
      );
      setAiBriefingState({ status: "success", data: briefing });
    } catch (err) {
      setAiBriefingState({
        status: "error",
        message: err instanceof Error ? err.message : "Briefing failed",
      });
    }
  }, [operatingReport, persisted.activeRole, persisted.language]);

  const upsertEvaluation = useCallback((ev: PerformanceEvaluationEntity) => {
    setPersisted((p) => ({
      ...p,
      evaluations: [ev, ...p.evaluations.filter((item) => item.id !== ev.id)],
    }));
  }, []);

  const evaluateTeacherPerformance = useCallback(async () => {
    const lang = persisted.language;
    const teacherLabel =
      lang === AppLanguage.AR ? "أ. طارق عزت · سنتر النخبة" : "Mr. Tarek Ezzat · Al-Nokhba Center";
    const avgMastery =
      persisted.students.length > 0
        ? Math.floor(persisted.students.reduce((s, st) => s + st.masteryPercent, 0) / persisted.students.length)
        : 85;
    const pendingCount = persisted.submissions.filter((s) => s.status === SubmissionStatus.PENDING).length;

    setEvaluationState({ status: "loading" });
    try {
      const ev = await AiToolkitClient.evaluateTeacherPerformance({
        teacherLabel,
        report: operatingReport,
        studentCount: persisted.students.length,
        avgStudentMastery: avgMastery,
        pendingReceiptsCount: pendingCount,
        lang,
      });
      upsertEvaluation(ev);
      setEvaluationState({ status: "success", data: ev });
    } catch (err) {
      setEvaluationState({
        status: "error",
        message: err instanceof Error ? err.message : "Evaluation failed",
      });
    }
  }, [persisted.language, persisted.students, persisted.submissions, operatingReport, upsertEvaluation]);

  const evaluateStudentPerformance = useCallback(
    async (studentId?: string | null) => {
      const lang = persisted.language;
      const target =
        (studentId ? persisted.students.find((s) => s.id === studentId) : undefined) ?? persisted.students[0];
      if (!target) return;
      const grp = persisted.groups.find((g) => g.id === target.groupId);
      const groupName = grp
        ? lang === AppLanguage.AR
          ? grp.nameAr
          : grp.nameEn
        : lang === AppLanguage.AR
          ? "المجموعة الأساسية"
          : "Main Group";
      const attendedCount = persisted.attendance.filter((a) => a.studentId === target.id).length;
      const weakTopics = rescueItems.map((r) => (lang === AppLanguage.AR ? r.topicAr : r.topicEn));

      setEvaluationState({ status: "loading" });
      try {
        const ev = await AiToolkitClient.evaluateStudentPerformance({
          student: target,
          groupName,
          attendedSessionsCount: attendedCount,
          completedLessonsCount: persisted.completedCourseIds.length,
          weakTopicTitles: weakTopics,
          lang,
        });
        upsertEvaluation(ev);
        setEvaluationState({ status: "success", data: ev });
      } catch (err) {
        setEvaluationState({
          status: "error",
          message: err instanceof Error ? err.message : "Evaluation failed",
        });
      }
    },
    [
      persisted.language,
      persisted.students,
      persisted.groups,
      persisted.attendance,
      persisted.completedCourseIds.length,
      rescueItems,
      upsertEvaluation,
    ]
  );

  const buildEvaluationShareText = useCallback(
    (evaluation: PerformanceEvaluationEntity) =>
      KashkoolMessageBuilders.buildEvaluationShareText(evaluation, persisted.language),
    [persisted.language]
  );

  const refreshParentWeeklyDigest = useCallback(async () => {
    const student = persisted.students[0];
    if (!student) return;
    const lang = persisted.language;
    const attendanceCount = persisted.attendance.filter((a) => a.studentId === student.id).length;
    const weakTopics = rescueItems.map((r) => (lang === AppLanguage.AR ? r.topicAr : r.topicEn));
    const orProfile = operatingReport.studentProfiles[student.id];

    setParentDigestState({ status: "loading" });
    try {
      const digest = await AiToolkitClient.composeParentWeeklyDigest({
        student,
        attendanceCount,
        weakTopics,
        lang,
        orProfile,
      });
      setParentDigestState({ status: "success", data: digest });
    } catch (err) {
      setParentDigestState({
        status: "error",
        message: err instanceof Error ? err.message : t("parent_digest_error", lang),
      });
    }
  }, [persisted.students, persisted.language, persisted.attendance, rescueItems, operatingReport.studentProfiles]);

  const composeSecretaryNotice = useCallback(
    async (student: StudentEntity) => {
      const lang = persisted.language;
      const studentName = lang === AppLanguage.AR ? student.nameAr : student.nameEn;
      const grp = persisted.groups.find((g) => g.id === student.groupId);
      const groupName = grp
        ? lang === AppLanguage.AR
          ? grp.nameAr
          : grp.nameEn
        : lang === AppLanguage.AR
          ? "المجموعة الأساسية"
          : "Main Group";
      const orProfile = operatingReport.studentProfiles[student.id];

      setSecretaryNoticeState({ status: "loading", studentName });
      try {
        const draft = await AiToolkitClient.composeSecretaryNotice({
          student,
          groupName,
          lang,
          orProfile,
        });
        setSecretaryNoticeState({ status: "success", studentName, draft });
      } catch (err) {
        setSecretaryNoticeState({
          status: "error",
          studentName,
          message: err instanceof Error ? err.message : t("draft_notice_error", lang),
        });
      }
    },
    [persisted.language, persisted.groups, operatingReport.studentProfiles]
  );

  const dismissSecretaryNotice = useCallback(() => {
    setSecretaryNoticeState({ status: "idle" });
  }, []);

  const generateTeacherLessonPlan = useCallback(
    async (group: GroupEntity) => {
      const lang = persisted.language;
      const avgMastery =
        persisted.students.length > 0
          ? Math.floor(persisted.students.reduce((s, st) => s + st.masteryPercent, 0) / persisted.students.length)
          : 85;
      setTeacherPlanState({ status: "loading" });
      try {
        const plan = await AiToolkitClient.generateTeacherLessonPlan({
          group,
          avgMasteryPercent: avgMastery,
          lang,
          report: operatingReport,
        });
        setTeacherPlanState({ status: "success", data: plan });
      } catch (err) {
        setTeacherPlanState({
          status: "error",
          message: err instanceof Error ? err.message : t("teacher_plan_error", lang),
        });
      }
    },
    [persisted.language, persisted.students, operatingReport]
  );

  const buildThermalReceipt = useCallback(
    () =>
      KashkoolMessageBuilders.buildThermalReceipt(
        shiftReconciliation,
        persisted.attendance,
        persisted.language
      ),
    [shiftReconciliation, persisted.attendance, persisted.language]
  );

  // Sync latest persisted Evaluation if user previously saved one
  useEffect(() => {
    if (evaluationState.status === "idle" && persisted.evaluations.length > 0) {
      const targetMatch = persisted.evaluations.find((ev) =>
        persisted.activeRole === UserRole.TEACHER
          ? ev.targetType === EvaluationTargetType.TEACHER
          : ev.targetType === EvaluationTargetType.STUDENT
      );
      if (targetMatch) {
        setEvaluationState({ status: "success", data: targetMatch });
      }
    }
  }, [persisted.activeRole, persisted.evaluations, evaluationState.status]);

  const value: KashkoolContextValue = {
    language: persisted.language,
    signedIn: persisted.signedIn,
    activeRole: persisted.activeRole,
    userLabel: persisted.userLabel,
    groups: persisted.groups,
    students: persisted.students,
    attendance: persisted.attendance,
    ledger: persisted.ledger,
    channels: activeChannels,
    allChannels: persisted.channels,
    submissions: persisted.submissions,
    resources: persisted.resources,
    evaluations: persisted.evaluations,
    lowDataMode: persisted.lowDataMode,
    streakShieldActive: persisted.streakShieldActive,
    activeCenterPlanId: persisted.activeCenterPlanId,
    centerPlans,
    settlementSplitPercent: persisted.settlementSplitPercent,
    assistantWagesPiasters: persisted.assistantWagesPiasters,
    completedCourseIds: completedCourseSet,
    courses: coursesCatalog,
    quizQuestions: quizCatalog,
    rescueItems,
    pendingSyncCount,
    shiftReconciliation,
    operatingReport,
    attendanceDashboard,
    qrToken,
    qrSecondsRemaining,
    activeStudent,
    activeStudentQrToken,
    activeStudentCardCode,
    activeStudentCardPayload,
    activeStudentCheckedInToday,
    auth,
    scannerScanCount,
    lastScanFeedback,
    qrVerificationBanner,
    snackbarMessage,
    assistantMessages,
    assistantBusy,
    assistantError,
    activeLectureId,
    activeLectureTitle,
    adaptiveQuizQuestions,
    adaptiveQuizTopic,
    adaptiveQuizBusy,
    adaptiveQuizError,
    syncBusy,
    supabaseConfigured,
    generatedQrCode,
    generatedQrStudentName,
    compressedReceipt,
    receiptCompressing,
    reassurancePulseAtMillis,
    rushModeEnabled,
    studyBudgetMinutes,
    attendanceWindow,
    attendanceChartMode,
    attendanceGroupFilter,
    aiBriefingState,
    evaluationState,
    receiptScanState,
    revisionDeckState,
    parentDigestState,
    secretaryNoticeState,
    teacherPlanState,
    tr,
    showSnackbar,
    clearSnackbar,
    toggleLanguage,
    setAuthMode,
    requestOtp,
    verifyOtp,
    activateWithQr,
    enterOfflineWorkspace,
    switchRole,
    signOut,
    syncNow,
    toggleLowDataMode,
    toggleStreakShield,
    completeRescueItem,
    recordQuizOutcome,
    triggerParentReassurance,
    buildEncouragementMessage,
    buildParentReportShareText,
    notifyMessageCopied,
    toggleRushMode,
    discreetAllowWithParentNotice,
    notifyQrCopied,
    setAttendanceWindow,
    setAttendanceChartMode,
    setAttendanceGroupFilter,
    verifyGateQrToken,
    scanQrForAttendance,
    addWalkInStudent,
    toggleStudentBlocked,
    addResource,
    cycleResourceStatus,
    updateStudyBudgetMinutes,
    executeOrSeatRebalance,
    updateSettlementControls,
    addPaymentChannel,
    toggleChannelActive,
    submitCenterPlanUpgrade,
    generateQrForStudent,
    dismissGeneratedQr,
    compressAndAttachReceipt,
    clearCompressedReceipt,
    scanAttachedReceipt,
    checkInStudent,
    recordCashDeskEntry,
    voidLedgerEntry,
    executeDailySettlement,
    createGroup,
    submitPaymentReceipt,
    approveSubmission,
    rejectSubmission,
    openLecture,
    closeLecture,
    generateLessonRevisionDeck,
    markActiveLectureCompleted,
    generateAdaptiveQuiz,
    resetAdaptiveQuiz,
    askStudyAssistant,
    requestOperationalBriefing,
    evaluateTeacherPerformance,
    evaluateStudentPerformance,
    buildEvaluationShareText,
    refreshParentWeeklyDigest,
    composeSecretaryNotice,
    dismissSecretaryNotice,
    generateTeacherLessonPlan,
    buildThermalReceipt,
  };

  return <KashkoolContext.Provider value={value}>{children}</KashkoolContext.Provider>;
};

export function useKashkool(): KashkoolContextValue {
  const ctx = useContext(KashkoolContext);
  if (!ctx) throw new Error("useKashkool must be used within KashkoolProvider");
  return ctx;
}
