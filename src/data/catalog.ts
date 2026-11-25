import { CenterPlanTier, CourseUnit, QuizQuestion } from "../types/kashkool";

export const centerPlans: CenterPlanTier[] = [
  {
    id: "plan-starter",
    nameAr: "الباقة الأساسية",
    nameEn: "Starter Center",
    monthlyPiasters: 35000,
    maxStudents: 100,
    highlightAr: "حتى 100 طالب · الحضور والدفتر المالي",
    highlightEn: "Up to 100 students · Attendance & Ledger",
  },
  {
    id: "plan-pro",
    nameAr: "الباقة الاحترافية",
    nameEn: "Pro Center",
    monthlyPiasters: 75000,
    maxStudents: 350,
    highlightAr: "حتى 350 طالب · متابعة ولي الأمر وتقارير التحصيل",
    highlightEn: "Up to 350 students · Parent Portal & Collections",
  },
  {
    id: "plan-enterprise",
    nameAr: "باقة السناتر الكبرى",
    nameEn: "Enterprise Network",
    monthlyPiasters: 150000,
    maxStudents: 1500,
    highlightAr: "حتى 1500 طالب · تعدد الفروع ومراقبة الفروع",
    highlightEn: "Up to 1500 students · Multi-branch Operations",
  },
];

export const coursesCatalog: CourseUnit[] = [
  {
    id: "c1",
    gradeAr: "الصف الثالث الثانوي — الرياضيات",
    gradeEn: "Grade 3 Sec — Pure Math",
    titleAr: "التفاضل: التكامل بالتجزيء والكسور الجزئية",
    titleEn: "Calculus: Integration by Parts & Partial Fractions",
    duration: "1:45:00",
    dataEstimateMb: 42,
    summaryAr:
      "القاعدة الأساسية: ∫u dv = u·v − ∫v du. اختر u بأولوية اللوغاريتم ثم كثيرات الحدود، وفي الكسور الجزئية حلّل المقام أولاً.",
    summaryEn:
      "Core Rule: ∫u dv = u·v − ∫v du. Prioritize log then polynomial for u; factor denominator first for partial fractions.",
  },
  {
    id: "c2",
    gradeAr: "الصف الثالث الثانوي — الرياضيات",
    gradeEn: "Grade 3 Sec — Pure Math",
    titleAr: "التكامل المحدد وحجوم الأجسام الدورانية",
    titleEn: "Definite Integrals & Volumes of Revolution",
    duration: "1:30:00",
    dataEstimateMb: 36,
    summaryAr:
      "حجم الدوران حول محور السينات: V = π ∫[a..b] y² dx مع التأكد من نقاط التقاطع وحدود التكامل قبل التعويض.",
    summaryEn:
      "Volume around x-axis: V = π ∫[a..b] y² dx. Always solve intersection bounds before integrating.",
  },
  {
    id: "c3",
    gradeAr: "الصف الثالث الثانوي — الفيزياء",
    gradeEn: "Grade 3 Sec — Physics",
    titleAr: "التيار الكهربائي وقوانين كيرشوف",
    titleEn: "Electric Current & Kirchhoff's Laws",
    duration: "1:20:00",
    dataEstimateMb: 31,
    summaryAr:
      "كيرشوف الأول: مجموع التيارات الداخلة عند عقدة = الخارجة. كيرشوف الثاني: ΣV_b = Σ(I·R) داخل أي مسار مغلق.",
    summaryEn:
      "KCL: ΣI_in = ΣI_out at any junction. KVL: ΣEMF = Σ(I·R) around every closed loop.",
  },
  {
    id: "c4",
    gradeAr: "الصف الثاني الثانوي — تطبيقات",
    gradeEn: "Grade 2 Sec — Applied Math",
    titleAr: "الاستاتيكا: محصلة قوتين متلاقيتين في نقطة",
    titleEn: "Statics: Resultant of Two Concurrent Forces",
    duration: "0:50:00",
    dataEstimateMb: 22,
    summaryAr:
      "قانون المحصلة: R² = F₁² + F₂² + 2F₁F₂ cos(α)، وزاوية الميل tan(θ) = (F₂ sin α) / (F₁ + F₂ cos α).",
    summaryEn:
      "Resultant: R² = F₁² + F₂² + 2F₁F₂ cos(α); angle tan(θ) = (F₂ sin α) / (F₁ + F₂ cos α).",
  },
];

export const quizCatalog: QuizQuestion[] = [
  {
    id: "q1",
    topicTagAr: "المعادلات الخطية",
    topicTagEn: "Linear Equations",
    promptAr: "أوجد قيمة x التي تحقق المعادلة:",
    promptEn: "Solve for x in the equation:",
    formula: "2x + 5 = 15",
    options: ["x = 5", "x = 10", "x = 4", "x = 7.5"],
    correctIndex: 0,
    remedialAr: "تذكير: اطرح 5 من الطرفين أولاً لتحصل على 2x = 10، ثم اقسم على 2.",
    remedialEn: "Tip: Subtract 5 from both sides to get 2x = 10, then divide by 2.",
  },
  {
    id: "q2",
    topicTagAr: "التفاضل الأساسي",
    topicTagEn: "Basic Derivatives",
    promptAr: "ما مشتقة الدالة التالية بالنسبة إلى x؟",
    promptEn: "What is the derivative with respect to x?",
    formula: "f(x) = 3x² + 4x - 7",
    options: ["6x + 4", "3x + 4", "6x² + 4", "6x - 7"],
    correctIndex: 0,
    remedialAr: "تذكير: مشتقة axⁿ هي n·axⁿ⁻¹ ومشتقة الثابت صفر.",
    remedialEn: "Tip: The derivative of ax^n is n*a*x^(n-1), and constants derive to 0.",
  },
  {
    id: "q3",
    topicTagAr: "قانون أوم",
    topicTagEn: "Ohm's Law",
    promptAr: "مقاومة قيمتها 6 أوم يمر بها تيار شدته 3 أمبير، احسب فرق الجهد:",
    promptEn: "A 6 Ω resistor carries 3 A of current. Find the voltage:",
    formula: "V = I × R",
    options: ["2 V", "9 V", "18 V", "0.5 V"],
    correctIndex: 2,
    remedialAr: "تذكير: فرق الجهد V = شدة التيار I × المقاومة R = 3 × 6 = 18 فولت.",
    remedialEn: "Tip: Voltage V = Current I * Resistance R = 3 * 6 = 18 V.",
  },
];
