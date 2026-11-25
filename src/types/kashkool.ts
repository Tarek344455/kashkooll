export enum AppLanguage {
  AR = "ar",
  EN = "en",
}

export enum UserRole {
  STUDENT = "student",
  SECRETARY = "secretary",
  TEACHER = "teacher",
  PARENT = "parent",
}

export enum LedgerKind {
  CASH_TOPUP = "cash_topup",
  PARTIAL_INSTALLMENT = "partial_installment",
  BOOK_RESERVATION = "book_reservation",
  DISCOUNT = "discount",
  SESSION_CHARGE = "session_charge",
  SETTLEMENT = "settlement",
  VOID_ENTRY = "void_entry",
}

export enum SubmissionStatus {
  PENDING = "pending",
  APPROVED = "approved",
  REJECTED = "rejected",
}

export enum AuthMode {
  QR = "QR",
  EMAIL = "EMAIL",
  PHONE = "PHONE",
}

export enum ResourceType {
  HUMAN = "human",
  TOOL = "tool",
  FINANCIAL = "financial",
}

export enum AvailabilityStatus {
  AVAILABLE = "available",
  IN_USE = "in_use",
  RESERVED = "reserved",
  UNAVAILABLE = "unavailable",
}

export enum EvaluationTargetType {
  TEACHER = "teacher",
  STUDENT = "student",
}

export enum AttendanceWindow {
  DAYS_7 = 7,
  DAYS_14 = 14,
  DAYS_30 = 30,
}

export enum AttendanceChartMode {
  AREA_TREND = "AREA_TREND",
  STACKED_BARS = "STACKED_BARS",
}

export enum QrVerifyStatus {
  VALID = "VALID",
  EXPIRED = "EXPIRED",
  INVALID = "INVALID",
}

export enum QrPayloadKind {
  STUDENT_DYNAMIC = "STUDENT_DYNAMIC",
  STUDENT_CARD = "STUDENT_CARD",
  SESSION_GATE = "SESSION_GATE",
  UNKNOWN = "UNKNOWN",
}

export interface QrVerifyResult {
  status: QrVerifyStatus;
  sessionId: string | null;
}

export interface StudentQrVerifyResult {
  status: QrVerifyStatus;
  kind: QrPayloadKind;
  studentId?: string | null;
  sessionId?: string | null;
  activationCode?: string | null;
}

export enum StudentRiskTier {
  CRITICAL = "critical",
  WATCH = "watch",
  HEALTHY = "healthy",
}

export interface GroupEntity {
  id: string;
  nameAr: string;
  nameEn: string;
  subjectAr: string;
  subjectEn: string;
  scheduleAr: string;
  scheduleEn: string;
  enrolled: number;
  capacity: number;
  pricePerSessionPiasters: number;
  centerSplitPercent: number;
  syncStatus: string;
}

export interface StudentEntity {
  id: string;
  nameAr: string;
  nameEn: string;
  phone: string;
  groupId: string;
  walletBalancePiasters: number;
  dueBalancePiasters: number;
  streakDays: number;
  masteryPercent: number;
  isBlocked: boolean;
  qrActivationCode?: string | null;
}

export interface AttendanceEntity {
  id: string;
  studentId: string;
  studentNameAr: string;
  studentNameEn: string;
  groupId: string;
  sessionId: string;
  feedbackStatus: "valid" | "due" | "blocked";
  timestampMillis: number;
  syncStatus: string;
}

export interface LedgerEntryEntity {
  id: string;
  studentId: string;
  studentNameAr: string;
  studentNameEn: string;
  kind: LedgerKind | string;
  amountPiasters: number;
  remainingDuePiasters: number;
  note: string;
  voidedEntryId?: string | null;
  createdByRole: string;
  createdAtMillis: number;
  syncStatus: string;
}

export interface PaymentChannelEntity {
  id: string;
  nameAr: string;
  nameEn: string;
  channelType: string;
  accountRef: string;
  maxAmountPiasters: number;
  feePiasters: number;
  isActive: boolean;
}

export interface PaymentSubmissionEntity {
  id: string;
  studentId: string;
  studentNameAr: string;
  studentNameEn: string;
  channelId: string;
  channelName: string;
  amountPiasters: number;
  senderReference: string;
  receiptUri?: string | null;
  status: SubmissionStatus | string;
  rejectionReason?: string | null;
  createdAtMillis: number;
  syncStatus: string;
}

export interface ResourceItem {
  id: string;
  name: string;
  type: ResourceType;
  availabilityStatus: AvailabilityStatus;
  tenantId: string;
  costPiasters: number;
  syncStatus: string;
  updatedAtMillis: number;
}

export interface PerformanceEvaluationEntity {
  id: string;
  targetId: string;
  targetName: string;
  targetType: EvaluationTargetType;
  languageCode: string;
  overallScore: number;
  trustBadge: string;
  analyticalSummary: string;
  instantFeedback: string;
  strengths: string[];
  improvementAreas: string[];
  nextActionPlan: string[];
  trustVerificationNote: string;
  evaluatedAtMillis: number;
}

export interface CompressedReceiptResult {
  dataUrl: string;
  originalBytes: number;
  compressedBytes: number;
  savingsPercent: number;
}

export interface AuthUiState {
  mode: AuthMode;
  awaitingOtp: boolean;
  identifier: string;
  busy: boolean;
  errorMessage: string | null;
}

export interface ScanFeedback {
  studentName: string;
  status: "valid" | "due" | "blocked" | "already" | "invalid";
  detail: string;
  alreadyCheckedIn: boolean;
  timestampMillis: number;
}

export interface QrVerificationBanner {
  status: QrVerifyStatus;
  tokenPreview: string;
  checkedAtMillis: number;
}

export interface AssistantMessage {
  id: string;
  fromUser: boolean;
  text: string;
  suggestions: string[];
  attachedPhotoDataUrl?: string | null;
}

export interface QuizQuestion {
  id: string;
  topicTagAr: string;
  topicTagEn: string;
  promptAr: string;
  promptEn: string;
  formula: string;
  options: string[];
  correctIndex: number;
  remedialAr: string;
  remedialEn: string;
}

export interface CourseUnit {
  id: string;
  gradeAr: string;
  gradeEn: string;
  titleAr: string;
  titleEn: string;
  duration: string;
  dataEstimateMb: number;
  summaryAr: string;
  summaryEn: string;
}

export interface CenterPlanTier {
  id: string;
  nameAr: string;
  nameEn: string;
  monthlyPiasters: number;
  maxStudents: number;
  highlightAr: string;
  highlightEn: string;
}

export interface RescueItem {
  id: string;
  topicAr: string;
  topicEn: string;
  hintAr: string;
  hintEn: string;
  boostPercent: number;
}

export interface ShiftReconciliation {
  cashCollectedPiasters: number;
  electronicTransfersPiasters: number;
  voidedTotalPiasters: number;
  netDrawerCashPiasters: number;
}

// OR Models
export interface CourseCandidate {
  id: string;
  titleAr: string;
  titleEn: string;
  dataEstimateMb: number;
}

export interface StudyCandidate {
  id: string;
  titleAr: string;
  titleEn: string;
  minutesRequired: number;
  masteryGainPercent: number;
}

export interface StudyKnapsackResult {
  timeBudgetMinutes: number;
  selectedItems: StudyCandidate[];
  totalMinutesUsed: number;
  guaranteedGainPercent: number;
}

export interface SeatTransferPlan {
  fromGroupId: string;
  fromGroupAr: string;
  fromGroupEn: string;
  toGroupId: string;
  toGroupAr: string;
  toGroupEn: string;
  seatsToMove: number;
}

export interface GroupAllocationResult {
  totalEnrolled: number;
  totalCapacity: number;
  utilizationPercent: number;
  bottleneckGroupId: string | null;
  bottleneckGroupAr: string | null;
  bottleneckGroupEn: string | null;
  bottleneckFillPercent: number;
  slackGroupId: string | null;
  slackGroupAr: string | null;
  slackGroupEn: string | null;
  recommendedSeatShift: number;
  transferPlans: SeatTransferPlan[];
  optimalWalkInGroupId: string | null;
  optimalWalkInGroupAr: string | null;
  optimalWalkInGroupEn: string | null;
  balanceScorePercent: number;
}

export interface FinancialCertaintyResult {
  attendedCount: number;
  splitPercentUsed: number;
  grossPiasters: number;
  centerSplitPiasters: number;
  assistantWagesPiasters: number;
  netPayoutPiasters: number;
  breakEvenAttendance: number;
  marginOfSafetyPercent: number;
  pendingDuesPiasters: number;
  ledgerBalanced: boolean;
  voidChainCount: number;
  resourceOverheadPiasters: number;
  netAfterResourcesPiasters: number;
  collectionEfficiencyPercent: number;
  voidRatioPercent: number;
  anomalyDetected: boolean;
  projectedWeeklyGrossPiasters: number;
}

export interface QueueDispatchResult {
  activeLanes: number;
  expectedWaitSeconds: number;
  queueUtilizationPercent: number;
  recommendExtraLane: boolean;
  erlangCWaitProbabilityPercent: number;
  expectedQueueLengthStudents: number;
  optimalLanesForSla: number;
}

export interface ResourceConflictReport {
  totalResources: number;
  availableCount: number;
  inUseCount: number;
  unavailableCount: number;
  hasHallOrScheduleConflict: boolean;
  summaryAr: string;
  summaryEn: string;
  utilizedResourceCostPiasters: number;
  conflictGroupCount: number;
}

export interface PaymentChannelOptimization {
  optimalChannelId: string | null;
  optimalChannelNameAr: string | null;
  optimalChannelNameEn: string | null;
  optimalFeePiasters: number;
  feeSavingsPiasters: number;
  recommendedAmountPiasters: number;
  reasonAr: string;
  reasonEn: string;
}

export interface CoursePriorityRecommendation {
  courseId: string;
  rank: number;
  priorityScore: number;
  efficiencyPerMb: number;
  isTopPick: boolean;
  selectedInDataBudget: boolean;
  reasonAr: string;
  reasonEn: string;
}

export interface StudentOrProfile {
  studentId: string;
  riskScore: number;
  riskTier: StudentRiskTier;
  coveredSessions: number;
  recommendedInstallmentPiasters: number;
  actionKind: string;
  actionSummaryAr: string;
  actionSummaryEn: string;
}

export interface CertaintyBreakdown {
  auditScore: number;
  marginScore: number;
  capacityScore: number;
  queueSlaScore: number;
  resourceScore: number;
}

export interface OperationalDecision {
  titleAr: string;
  titleEn: string;
  detailAr: string;
  detailEn: string;
  verifiedFormula: string;
  priorityHigh: boolean;
}

export interface SystemOperatingReport {
  certaintyScorePercent: number;
  groupAllocation: GroupAllocationResult;
  financialCertainty: FinancialCertaintyResult;
  studyKnapsack: StudyKnapsackResult;
  queueDispatch: QueueDispatchResult;
  resourceConflict: ResourceConflictReport;
  decisions: OperationalDecision[];
  channelOptimization: PaymentChannelOptimization | null;
  courseRecommendations: CoursePriorityRecommendation[];
  studentProfiles: Record<string, StudentOrProfile>;
  priorityStudentIds: string[];
  certaintyBreakdown: CertaintyBreakdown;
}

// Analytics Models
export interface DailyAttendancePoint {
  dayStartMillis: number;
  shortLabel: string;
  fullDateLabel: string;
  validCount: number;
  dueCount: number;
  blockedCount: number;
  totalCount: number;
  attendanceRatePercent: number;
}

export interface GroupAttendanceSummary {
  groupId: string;
  nameAr: string;
  nameEn: string;
  checkInsInWindow: number;
  validCheckIns: number;
  enrolled: number;
  capacity: number;
  ratePercent: number;
}

export interface AttendanceDashboardSnapshot {
  window: AttendanceWindow;
  selectedGroupId: string | null;
  dailyPoints: DailyAttendancePoint[];
  totalCheckIns: number;
  todayCheckIns: number;
  todayRatePercent: number;
  validCount: number;
  dueCount: number;
  blockedCount: number;
  validRatePercent: number;
  trendDeltaPercent: number;
  peakDayLabel: string;
  peakDayCount: number;
  groupSummaries: GroupAttendanceSummary[];
  recentRecords: AttendanceEntity[];
}

// Academic / Advisor AI DTOs
export interface AiOperationalBriefing {
  headline: string;
  confidenceStatement: string;
  topDecision: string;
  nextActionSteps: string[];
  trustGuarantee: string;
}

export interface ReceiptScanResult {
  amountEgp: string;
  referenceNumber: string;
  detectedChannelType: string;
  clarityStatus: "high" | "medium" | "low";
  verificationNote: string;
}

export interface StudyFlashcard {
  front: string;
  back: string;
}

export interface LessonRevisionDeck {
  lessonTitle: string;
  memoryHook: string;
  flashcards: StudyFlashcard[];
  commonTraps: string[];
}

export interface ParentWeeklyDigest {
  headline: string;
  weeklyNarrative: string;
  cheerMessage: string;
  homeSupportTip: string;
}

export interface SecretaryNoticeDraft {
  toneTag: string;
  messageText: string;
}

export interface TeacherLessonPlan {
  topicTitle: string;
  pacingSteps: string[];
  basicHomework: string[];
  challengeHomework: string[];
  assistantChecklist: string[];
}

export type AsyncUiState<T> =
  | { status: "idle" }
  | { status: "loading" }
  | { status: "success"; data: T }
  | { status: "error"; message: string };

export type SecretaryNoticeUiState =
  | { status: "idle" }
  | { status: "loading"; studentName: string }
  | { status: "success"; studentName: string; draft: SecretaryNoticeDraft }
  | { status: "error"; studentName: string; message: string };

export type AppDestination =
  | "home"
  | "desk"
  | "analytics"
  | "teacher"
  | "courses"
  | "wallet"
  | "assistant"
  | "parent";
