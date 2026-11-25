package com.dig.kashkool.ui.viewmodel

import com.dig.kashkool.core.analytics.AttendanceChartMode
import com.dig.kashkool.core.analytics.AttendanceDashboardSnapshot
import com.dig.kashkool.core.analytics.AttendanceWindow
import com.dig.kashkool.core.firebase.AiOperationalBriefing
import com.dig.kashkool.core.firebase.LessonRevisionDeck
import com.dig.kashkool.core.firebase.ParentWeeklyDigest
import com.dig.kashkool.core.firebase.ReceiptScanResult
import com.dig.kashkool.core.firebase.SecretaryNoticeDraft
import com.dig.kashkool.core.firebase.TeacherLessonPlan
import com.dig.kashkool.core.l10n.AppLanguage
import com.dig.kashkool.core.or.SystemOperatingReport
import com.dig.kashkool.core.utils.CompressedReceiptResult
import com.dig.kashkool.core.utils.QrVerifyStatus
import com.dig.kashkool.data.local.AttendanceEntity
import com.dig.kashkool.data.local.GroupEntity
import com.dig.kashkool.data.local.LedgerEntryEntity
import com.dig.kashkool.data.local.PaymentChannelEntity
import com.dig.kashkool.data.local.PaymentSubmissionEntity
import com.dig.kashkool.data.local.PerformanceEvaluationEntity
import com.dig.kashkool.data.local.Resource
import com.dig.kashkool.data.local.StudentEntity
import com.dig.kashkool.data.local.UserRole

enum class AuthMode { QR, EMAIL, PHONE }

data class AuthUiState(
    val mode: AuthMode = AuthMode.QR,
    val awaitingOtp: Boolean = false,
    val identifier: String = "",
    val busy: Boolean = false,
    val errorMessage: String? = null,
)

data class ScanFeedback(
    val studentName: String,
    val status: String, // "valid", "due", "blocked", "already", "invalid"
    val detail: String = "",
    val alreadyCheckedIn: Boolean = false,
    val timestampMillis: Long = System.currentTimeMillis(),
)

data class QrVerificationBanner(
    val status: QrVerifyStatus,
    val tokenPreview: String,
    val checkedAtMillis: Long = System.currentTimeMillis(),
)

data class AssistantMessage(
    val fromUser: Boolean,
    val text: String,
    val suggestions: List<String> = emptyList(),
    val attachedPhotoUri: String? = null,
)

data class QuizQuestion(
    val id: String,
    val topicTagAr: String,
    val topicTagEn: String,
    val promptAr: String,
    val promptEn: String,
    val formula: String,
    val options: List<String>,
    val correctIndex: Int,
    val remedialAr: String,
    val remedialEn: String,
)

data class CourseUnit(
    val id: String,
    val gradeAr: String,
    val gradeEn: String,
    val titleAr: String,
    val titleEn: String,
    val duration: String,
    val dataEstimateMb: Int,
    val summaryAr: String = "",
    val summaryEn: String = "",
)

data class CenterPlanTier(
    val id: String,
    val nameAr: String,
    val nameEn: String,
    val monthlyPiasters: Long,
    val maxStudents: Int,
    val highlightAr: String,
    val highlightEn: String,
)

data class RescueItem(
    val id: String,
    val topicAr: String,
    val topicEn: String,
    val hintAr: String,
    val hintEn: String,
    val boostPercent: Int,
)

data class ShiftReconciliation(
    val cashCollectedPiasters: Long,
    val electronicTransfersPiasters: Long,
    val voidedTotalPiasters: Long,
    val netDrawerCashPiasters: Long,
)

sealed interface AiBriefingState {
    data object Idle : AiBriefingState
    data object Loading : AiBriefingState
    data class Success(val briefing: AiOperationalBriefing) : AiBriefingState
    data class Error(val message: String) : AiBriefingState
}

sealed interface EvaluationUiState {
    data object Idle : EvaluationUiState
    data object Loading : EvaluationUiState
    data class Success(val evaluation: PerformanceEvaluationEntity) : EvaluationUiState
    data class Error(val message: String) : EvaluationUiState
}

sealed interface ReceiptScanUiState {
    data object Idle : ReceiptScanUiState
    data object Loading : ReceiptScanUiState
    data class Success(val result: ReceiptScanResult) : ReceiptScanUiState
    data class Error(val message: String) : ReceiptScanUiState
}

sealed interface RevisionDeckUiState {
    data object Idle : RevisionDeckUiState
    data object Loading : RevisionDeckUiState
    data class Success(val deck: LessonRevisionDeck) : RevisionDeckUiState
    data class Error(val message: String) : RevisionDeckUiState
}

sealed interface ParentDigestUiState {
    data object Idle : ParentDigestUiState
    data object Loading : ParentDigestUiState
    data class Success(val digest: ParentWeeklyDigest) : ParentDigestUiState
    data class Error(val message: String) : ParentDigestUiState
}

sealed interface SecretaryNoticeUiState {
    data object Idle : SecretaryNoticeUiState
    data class Loading(val studentName: String) : SecretaryNoticeUiState
    data class Success(val studentName: String, val draft: SecretaryNoticeDraft) : SecretaryNoticeUiState
    data class Error(val studentName: String, val message: String) : SecretaryNoticeUiState
}

sealed interface TeacherPlanUiState {
    data object Idle : TeacherPlanUiState
    data object Loading : TeacherPlanUiState
    data class Success(val plan: TeacherLessonPlan) : TeacherPlanUiState
    data class Error(val message: String) : TeacherPlanUiState
}

data class KashkoolUiState(
    val loading: Boolean = true,
    val language: AppLanguage = AppLanguage.AR,
    val signedIn: Boolean = false,
    val activeRole: UserRole = UserRole.STUDENT,
    val userLabel: String = "+201012345678",
    val backendConfigured: Boolean = false,
    val auth: AuthUiState = AuthUiState(),
    val groups: List<GroupEntity> = emptyList(),
    val students: List<StudentEntity> = emptyList(),
    val attendance: List<AttendanceEntity> = emptyList(),
    val ledger: List<LedgerEntryEntity> = emptyList(),
    val channels: List<PaymentChannelEntity> = emptyList(),
    val allChannels: List<PaymentChannelEntity> = emptyList(),
    val submissions: List<PaymentSubmissionEntity> = emptyList(),
    val resources: List<Resource> = emptyList(),
    val qrToken: String = "",
    val qrSecondsRemaining: Int = 30,
    val activeStudentQrToken: String = "",
    val activeStudentCardCode: String = "",
    val activeStudentCardPayload: String = "",
    val activeStudentCheckedInToday: Boolean = false,
    val scannerScanCount: Int = 0,
    val lastScanFeedback: ScanFeedback? = null,
    val qrVerificationBanner: QrVerificationBanner? = null,
    val snackbarMessage: String? = null,
    val assistantMessages: List<AssistantMessage> = emptyList(),
    val assistantBusy: Boolean = false,
    val assistantError: String? = null,
    val activeLectureId: String? = null,
    val activeLectureTitle: String? = null,
    val completedCourseIds: Set<String> = emptySet(),
    val adaptiveQuizQuestions: List<QuizQuestion>? = null,
    val adaptiveQuizTopic: String? = null,
    val adaptiveQuizBusy: Boolean = false,
    val adaptiveQuizError: String? = null,
    val pendingSyncCount: Int = 0,
    val syncBusy: Boolean = false,
    val lowDataMode: Boolean = true,
    val generatedQrCode: String? = null,
    val generatedQrStudentName: String? = null,
    val compressedReceipt: CompressedReceiptResult? = null,
    val receiptCompressing: Boolean = false,
    val streakShieldActive: Boolean = false,
    val rescueItems: List<RescueItem> = emptyList(),
    val reassurancePulseAtMillis: Long = System.currentTimeMillis(),
    val rushModeEnabled: Boolean = false,
    val activeCenterPlanId: String = "plan-pro",
    val settlementSplitPercent: Int = 20,
    val assistantWagesPiasters: Long = 15000L,
    val centerPlans: List<CenterPlanTier> = KashkoolCatalog.centerPlans,
    val shiftReconciliation: ShiftReconciliation = ShiftReconciliation(0L, 0L, 0L, 0L),
    val operatingReport: SystemOperatingReport? = null,
    val aiBriefingState: AiBriefingState = AiBriefingState.Idle,
    val evaluations: List<PerformanceEvaluationEntity> = emptyList(),
    val evaluationState: EvaluationUiState = EvaluationUiState.Idle,
    val receiptScanState: ReceiptScanUiState = ReceiptScanUiState.Idle,
    val revisionDeckState: RevisionDeckUiState = RevisionDeckUiState.Idle,
    val parentDigestState: ParentDigestUiState = ParentDigestUiState.Idle,
    val secretaryNoticeState: SecretaryNoticeUiState = SecretaryNoticeUiState.Idle,
    val teacherPlanState: TeacherPlanUiState = TeacherPlanUiState.Idle,
    val studyBudgetMinutes: Int = 15,
    val attendanceWindow: AttendanceWindow = AttendanceWindow.DAYS_14,
    val attendanceChartMode: AttendanceChartMode = AttendanceChartMode.AREA_TREND,
    val attendanceGroupFilter: String? = null,
    val attendanceDashboard: AttendanceDashboardSnapshot? = null,
)

object KashkoolCatalog {
    val centerPlans: List<CenterPlanTier> = listOf(
        CenterPlanTier(
            id = "plan-starter",
            nameAr = "الباقة الأساسية",
            nameEn = "Starter Center",
            monthlyPiasters = 35000L,
            maxStudents = 100,
            highlightAr = "حتى 100 طالب · الحضور والدفتر المالي",
            highlightEn = "Up to 100 students · Attendance & Ledger",
        ),
        CenterPlanTier(
            id = "plan-pro",
            nameAr = "الباقة الاحترافية",
            nameEn = "Pro Center",
            monthlyPiasters = 75000L,
            maxStudents = 350,
            highlightAr = "حتى 350 طالب · متابعة ولي الأمر وتقارير التحصيل",
            highlightEn = "Up to 350 students · Parent Portal & Collections",
        ),
        CenterPlanTier(
            id = "plan-enterprise",
            nameAr = "باقة السناتر الكبرى",
            nameEn = "Enterprise Network",
            monthlyPiasters = 150000L,
            maxStudents = 1500,
            highlightAr = "حتى 1500 طالب · تعدد الفروع ومراقبة الفروع",
            highlightEn = "Up to 1500 students · Multi-branch Operations",
        ),
    )

    val courses: List<CourseUnit> = listOf(
        CourseUnit(
            id = "c1",
            gradeAr = "الصف الثالث الثانوي — الرياضيات",
            gradeEn = "Grade 3 Sec — Pure Math",
            titleAr = "التفاضل: التكامل بالتجزيء والكسور الجزئية",
            titleEn = "Calculus: Integration by Parts & Partial Fractions",
            duration = "1:45:00",
            dataEstimateMb = 42,
            summaryAr = "القاعدة الأساسية: ∫u dv = u·v − ∫v du. اختر u بأولوية اللوغاريتم ثم كثيرات الحدود، وفي الكسور الجزئية حلّل المقام أولاً.",
            summaryEn = "Core Rule: ∫u dv = u·v − ∫v du. Prioritize log then polynomial for u; factor denominator first for partial fractions.",
        ),
        CourseUnit(
            id = "c2",
            gradeAr = "الصف الثالث الثانوي — الرياضيات",
            gradeEn = "Grade 3 Sec — Pure Math",
            titleAr = "التكامل المحدد وحجوم الأجسام الدورانية",
            titleEn = "Definite Integrals & Volumes of Revolution",
            duration = "1:30:00",
            dataEstimateMb = 36,
            summaryAr = "حجم الدوران حول محور السينات: V = π ∫[a..b] y² dx مع التأكد من نقاط التقاطع وحدود التكامل قبل التعويض.",
            summaryEn = "Volume around x-axis: V = π ∫[a..b] y² dx. Always solve intersection bounds before integrating.",
        ),
        CourseUnit(
            id = "c3",
            gradeAr = "الصف الثالث الثانوي — الفيزياء",
            gradeEn = "Grade 3 Sec — Physics",
            titleAr = "التيار الكهربائي وقوانين كيرشوف",
            titleEn = "Electric Current & Kirchhoff's Laws",
            duration = "1:20:00",
            dataEstimateMb = 31,
            summaryAr = "كيرشوف الأول: مجموع التيارات الداخلة عند عقدة = الخارجة. كيرشوف الثاني: ΣV_b = Σ(I·R) داخل أي مسار مغلق.",
            summaryEn = "KCL: ΣI_in = ΣI_out at any junction. KVL: ΣEMF = Σ(I·R) around every closed loop.",
        ),
        CourseUnit(
            id = "c4",
            gradeAr = "الصف الثاني الثانوي — تطبيقات",
            gradeEn = "Grade 2 Sec — Applied Math",
            titleAr = "الاستاتيكا: محصلة قوتين متلاقيتين في نقطة",
            titleEn = "Statics: Resultant of Two Concurrent Forces",
            duration = "0:50:00",
            dataEstimateMb = 22,
            summaryAr = "قانون المحصلة: R² = F₁² + F₂² + 2F₁F₂ cos(α)، وزاوية الميل tan(θ) = (F₂ sin α) / (F₁ + F₂ cos α).",
            summaryEn = "Resultant: R² = F₁² + F₂² + 2F₁F₂ cos(α); angle tan(θ) = (F₂ sin α) / (F₁ + F₂ cos α).",
        ),
    )

    val quizQuestions: List<QuizQuestion> = listOf(
        QuizQuestion(
            id = "q1",
            topicTagAr = "المعادلات الخطية",
            topicTagEn = "Linear Equations",
            promptAr = "أوجد قيمة x التي تحقق المعادلة:",
            promptEn = "Solve for x in the equation:",
            formula = "2x + 5 = 15",
            options = listOf("x = 5", "x = 10", "x = 4", "x = 7.5"),
            correctIndex = 0,
            remedialAr = "تذكير: اطرح 5 من الطرفين أولاً لتحصل على 2x = 10، ثم اقسم على 2.",
            remedialEn = "Tip: Subtract 5 from both sides to get 2x = 10, then divide by 2.",
        ),
        QuizQuestion(
            id = "q2",
            topicTagAr = "التفاضل الأساسي",
            topicTagEn = "Basic Derivatives",
            promptAr = "ما مشتقة الدالة التالية بالنسبة إلى x؟",
            promptEn = "What is the derivative with respect to x?",
            formula = "f(x) = 3x² + 4x - 7",
            options = listOf("6x + 4", "3x + 4", "6x² + 4", "6x - 7"),
            correctIndex = 0,
            remedialAr = "تذكير: مشتقة axⁿ هي n·axⁿ⁻¹ ومشتقة الثابت صفر.",
            remedialEn = "Tip: The derivative of ax^n is n*a*x^(n-1), and constants derive to 0.",
        ),
        QuizQuestion(
            id = "q3",
            topicTagAr = "قانون أوم",
            topicTagEn = "Ohm's Law",
            promptAr = "مقاومة قيمتها 6 أوم يمر بها تيار شدته 3 أمبير، احسب فرق الجهد:",
            promptEn = "A 6 Ω resistor carries 3 A of current. Find the voltage:",
            formula = "V = I × R",
            options = listOf("2 V", "9 V", "18 V", "0.5 V"),
            correctIndex = 2,
            remedialAr = "تذكير: فرق الجهد V = شدة التيار I × المقاومة R = 3 × 6 = 18 فولت.",
            remedialEn = "Tip: Voltage V = Current I * Resistance R = 3 * 6 = 18 V.",
        ),
    )
}
