import '../core/models/kashkool_models.dart';

class SeedData {
  static const List<GroupEntity> groups = [
    GroupEntity(
      id: 'grp-math-3sec',
      nameAr: 'الصف الثالث الثانوي — تفاضل وتكامل (مجموعة أ)',
      nameEn: 'Grade 3 Sec — Calculus (Group A)',
      subjectAr: 'الرياضيات البحتة',
      subjectEn: 'Pure Mathematics',
      scheduleAr: 'السبت والثلاثاء 4:00 م',
      scheduleEn: 'Sat & Tue 4:00 PM',
      enrolled: 44,
      capacity: 50,
      pricePerSessionPiasters: 8000,
      centerSplitPercent: 20,
    ),
    GroupEntity(
      id: 'grp-phys-3sec',
      nameAr: 'الصف الثالث الثانوي — الفيزياء الحديثة (مجموعة ب)',
      nameEn: 'Grade 3 Sec — Modern Physics (Group B)',
      subjectAr: 'الفيزياء',
      subjectEn: 'Physics',
      scheduleAr: 'الأحد والأربعاء 6:00 م',
      scheduleEn: 'Sun & Wed 6:00 PM',
      enrolled: 38,
      capacity: 40,
      pricePerSessionPiasters: 9000,
      centerSplitPercent: 20,
    ),
  ];

  static const List<StudentEntity> students = [
    StudentEntity(
      id: 'stu-1',
      nameAr: 'أحمد محمد علي',
      nameEn: 'Ahmed Mohamed Ali',
      phone: '+201012345678',
      groupId: 'grp-math-3sec',
      walletBalancePiasters: 24000,
      dueBalancePiasters: 0,
      streakDays: 14,
      masteryPercent: 88,
      isBlocked: false,
      qrActivationCode: 'KSH2026A',
      parentInviteCode: 'KSHP-2026A',
    ),
    StudentEntity(
      id: 'stu-2',
      nameAr: 'سارة خالد حسن',
      nameEn: 'Sara Khaled Hassan',
      phone: '+201122334455',
      groupId: 'grp-math-3sec',
      walletBalancePiasters: 5000,
      dueBalancePiasters: 8000,
      streakDays: 9,
      masteryPercent: 92,
      isBlocked: false,
      qrActivationCode: 'KSH2026B',
      parentInviteCode: 'KSHP-2026B',
    ),
  ];

  static final List<AttendanceEntity> attendance = [
    AttendanceEntity(
      id: 'att-1',
      studentId: 'stu-1',
      groupId: 'grp-math-3sec',
      feedbackStatus: 'valid',
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    AttendanceEntity(
      id: 'att-2',
      studentId: 'stu-2',
      groupId: 'grp-math-3sec',
      feedbackStatus: 'due',
      timestamp: DateTime.now().subtract(const Duration(hours: 1)),
    ),
  ];

  static final List<LedgerEntryEntity> ledger = [
    LedgerEntryEntity(
      id: 'led-1',
      studentId: 'stu-1',
      studentNameAr: 'أحمد محمد علي',
      studentNameEn: 'Ahmed Mohamed Ali',
      kind: LedgerKind.cashTopup,
      amountPiasters: 24000,
      note: 'شحن محفظة الحصص',
      timestamp: DateTime.now().subtract(const Duration(days: 1)),
    ),
    LedgerEntryEntity(
      id: 'led-2',
      studentId: 'stu-2',
      studentNameAr: 'سارة خالد حسن',
      studentNameEn: 'Sara Khaled Hassan',
      kind: LedgerKind.partialInstallment,
      amountPiasters: 5000,
      note: 'دفعة أولى',
      timestamp: DateTime.now().subtract(const Duration(hours: 5)),
    ),
  ];

  static const List<PaymentSubmissionEntity> submissions = [
    PaymentSubmissionEntity(
      id: 'sub-1',
      studentId: 'stu-1',
      channelName: 'InstaPay',
      amountPiasters: 16000,
      senderReference: 'TRX-884210',
      status: SubmissionStatus.pending,
    ),
  ];

  static const List<CourseUnit> courses = [
    CourseUnit(
      id: 'crs-1',
      titleAr: 'الاشتقاق الضمني والبارامتري',
      titleEn: 'Implicit & Parametric Differentiation',
      subjectAr: 'التفاضل',
      subjectEn: 'Calculus',
      durationMinutes: 45,
      summaryAr: 'شرح قاعدة السلسلة وتطبيقاتها في مسائل الثانوية العامة.',
      summaryEn: 'Chain rule and Thanaweya Amma exam applications.',
    ),
    CourseUnit(
      id: 'crs-2',
      titleAr: 'قوانين كيرشوف للدوائر الكهربية',
      titleEn: "Kirchhoff's Circuit Laws",
      subjectAr: 'الفيزياء',
      subjectEn: 'Physics',
      durationMinutes: 50,
      summaryAr: 'تحليل العقد والمسارات المغلقة خطوة بخطوة.',
      summaryEn: 'Step-by-step node and loop analysis.',
    ),
  ];

  static const List<QuizQuestion> quizQuestions = [
    QuizQuestion(
      id: 'q-1',
      topicTagAr: 'قاعدة السلسلة',
      topicTagEn: 'Chain Rule',
      promptAr: "إذا كانت ص = (٣س - ١)²، أوجد ص'(١).",
      promptEn: "If y = (3x - 1)^2, find y'(1).",
      formula: 'y = (3x - 1)^2',
      options: ['6', '12', '4', '18'],
      correctIndex: 1,
      remedialAr: "ص' = ٢(٣س - ١) × ٣ = ٦(٣س - ١). عند س = ١ تكون ١٢.",
      remedialEn: "y' = 2(3x - 1) * 3 = 6(3x - 1). At x = 1, y'(1) = 12.",
    ),
    QuizQuestion(
      id: 'q-2',
      topicTagAr: 'قانون كيرشوف الأول',
      topicTagEn: "Kirchhoff's Current Law",
      promptAr: 'مجموع التيارات الداخلة عند نقطة تفرع يساوي:',
      promptEn: 'The sum of currents entering a junction equals:',
      formula: 'Σ I_in = Σ I_out',
      options: [
        'صفر دائماً',
        'مجموع التيارات الخارجة',
        'فرق الجهد الكلي',
        'المقاومة المكافئة',
      ],
      correctIndex: 1,
      remedialAr: 'قانون حفظ الشحنة: مجموع التيارات الداخلة يساوي الخارجة.',
      remedialEn: 'Conservation of charge: sum of entering currents equals leaving.',
    ),
  ];
}
