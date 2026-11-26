import {
  AnnouncementEntity,
  AttendanceEntity,
  AvailabilityStatus,
  GroupEntity,
  HomeworkAssignmentEntity,
  HomeworkSubmissionEntity,
  LedgerEntryEntity,
  LedgerKind,
  MakeupSessionEntity,
  MistakeBankEntry,
  ParentAlertEntity,
  PaymentChannelEntity,
  ResourceItem,
  ResourceType,
  StudentEntity,
  SupportTicketEntity,
  UserRole,
} from "../types/kashkool";

export const seedGroups: GroupEntity[] = [
  {
    id: "grp-math-3sec",
    nameAr: "الصف الثالث الثانوي — تفاضل وتكامل (مجموعة أ)",
    nameEn: "Grade 3 Sec — Calculus (Group A)",
    subjectAr: "الرياضيات البحتة",
    subjectEn: "Pure Mathematics",
    scheduleAr: "السبت والثلاثاء 4:00 م",
    scheduleEn: "Sat & Tue 4:00 PM",
    enrolled: 44,
    capacity: 50,
    pricePerSessionPiasters: 8000,
    centerSplitPercent: 20,
    syncStatus: "synced",
  },
  {
    id: "grp-phys-3sec",
    nameAr: "الصف الثالث الثانوي — الفيزياء الحديثة (مجموعة ب)",
    nameEn: "Grade 3 Sec — Modern Physics (Group B)",
    subjectAr: "الفيزياء",
    subjectEn: "Physics",
    scheduleAr: "الأحد والأربعاء 6:00 م",
    scheduleEn: "Sun & Wed 6:00 PM",
    enrolled: 38,
    capacity: 40,
    pricePerSessionPiasters: 9000,
    centerSplitPercent: 20,
    syncStatus: "synced",
  },
  {
    id: "grp-statics-2sec",
    nameAr: "الصف الثاني الثانوي — الاستاتيكا والهندسة",
    nameEn: "Grade 2 Sec — Statics & Geometry",
    subjectAr: "تطبيقات الرياضيات",
    subjectEn: "Applied Math",
    scheduleAr: "الإثنين والخميس 5:00 م",
    scheduleEn: "Mon & Thu 5:00 PM",
    enrolled: 29,
    capacity: 45,
    pricePerSessionPiasters: 7000,
    centerSplitPercent: 20,
    syncStatus: "synced",
  },
];

export const seedStudents: StudentEntity[] = [
  {
    id: "stu-1",
    nameAr: "أحمد محمد علي",
    nameEn: "Ahmed Mohamed Ali",
    phone: "+201012345678",
    groupId: "grp-math-3sec",
    walletBalancePiasters: 24000,
    dueBalancePiasters: 0,
    streakDays: 14,
    masteryPercent: 88,
    isBlocked: false,
    qrActivationCode: "KSH2026A",
    parentInviteCode: "KSHP-2026A",
  },
  {
    id: "stu-2",
    nameAr: "سارة خالد حسن",
    nameEn: "Sara Khaled Hassan",
    phone: "+201122334455",
    groupId: "grp-math-3sec",
    walletBalancePiasters: 5000,
    dueBalancePiasters: 8000,
    streakDays: 9,
    masteryPercent: 92,
    isBlocked: false,
    qrActivationCode: "KSH2026B",
    parentInviteCode: "KSHP-2026B",
  },
  {
    id: "stu-3",
    nameAr: "يوسف طارق إبراهيم",
    nameEn: "Youssef Tarek Ibrahim",
    phone: "+201234567890",
    groupId: "grp-phys-3sec",
    walletBalancePiasters: 18000,
    dueBalancePiasters: 0,
    streakDays: 6,
    masteryPercent: 79,
    isBlocked: false,
    qrActivationCode: null,
    parentInviteCode: "KSHP-2026C",
  },
  {
    id: "stu-4",
    nameAr: "مريم عادل محمود",
    nameEn: "Mariam Adel Mahmoud",
    phone: "+201555667788",
    groupId: "grp-statics-2sec",
    walletBalancePiasters: 0,
    dueBalancePiasters: 0,
    streakDays: 0,
    masteryPercent: 65,
    isBlocked: true,
    qrActivationCode: null,
    parentInviteCode: "KSHP-2026D",
  },
];

export const seedChannels: PaymentChannelEntity[] = [
  {
    id: "ch-cashdesk",
    nameAr: "خزينة السنتر (بدون عمولة)",
    nameEn: "Center Cash Desk (0 Fee)",
    channelType: "cash_desk",
    accountRef: "شباك السكرتارية - قاعة أ",
    maxAmountPiasters: 500000,
    feePiasters: 0,
    isActive: true,
  },
  {
    id: "ch-instapay",
    nameAr: "إنستاباي — سنتر النخبة",
    nameEn: "InstaPay — Al-Nokhba Center",
    channelType: "insta_pay",
    accountRef: "kashkool.nokhba@instapay",
    maxAmountPiasters: 500000,
    feePiasters: 0,
    isActive: true,
  },
  {
    id: "ch-vfcash",
    nameAr: "فودافون كاش",
    nameEn: "Vodafone Cash",
    channelType: "vodafone_cash",
    accountRef: "01098765432",
    maxAmountPiasters: 300000,
    feePiasters: 500,
    isActive: true,
  },
  {
    id: "ch-etisalat",
    nameAr: "اتصالات كاش",
    nameEn: "Etisalat Cash",
    channelType: "etisalat_cash",
    accountRef: "01198765432",
    maxAmountPiasters: 300000,
    feePiasters: 500,
    isActive: true,
  },
  {
    id: "ch-orange",
    nameAr: "أورانج كاش",
    nameEn: "Orange Cash",
    channelType: "orange_cash",
    accountRef: "01298765432",
    maxAmountPiasters: 300000,
    feePiasters: 500,
    isActive: true,
  },
  {
    id: "ch-wepay",
    nameAr: "وي باي (WE Pay)",
    nameEn: "WE Pay",
    channelType: "we_pay",
    accountRef: "01598765432",
    maxAmountPiasters: 300000,
    feePiasters: 500,
    isActive: true,
  },
  {
    id: "ch-fawry",
    nameAr: "فوري باي",
    nameEn: "Fawry Pay",
    channelType: "fawry",
    accountRef: "78412",
    maxAmountPiasters: 400000,
    feePiasters: 1000,
    isActive: true,
  },
];

export function initialLedgerEntries(nowMillis: number): LedgerEntryEntity[] {
  return [
    {
      id: "led-seed-1",
      studentId: "stu-1",
      studentNameAr: "أحمد محمد علي",
      studentNameEn: "Ahmed Mohamed Ali",
      kind: LedgerKind.CASH_TOPUP,
      amountPiasters: 24000,
      remainingDuePiasters: 0,
      note: "شحن محفظة الحصص الشهرية",
      createdByRole: "secretary",
      createdAtMillis: nowMillis - 86_400_000,
      syncStatus: "synced",
    },
    {
      id: "led-seed-2",
      studentId: "stu-2",
      studentNameAr: "سارة خالد حسن",
      studentNameEn: "Sara Khaled Hassan",
      kind: LedgerKind.PARTIAL_INSTALLMENT,
      amountPiasters: 5000,
      remainingDuePiasters: 8000,
      note: "دفع جزئي لحصة التفاضل — متبقي 80 ج.م",
      createdByRole: "secretary",
      createdAtMillis: nowMillis - 43_200_000,
      syncStatus: "synced",
    },
  ];
}

export function initialResources(nowMillis: number): ResourceItem[] {
  return [
    {
      id: "res-hall-a",
      name: "قاعة النخبة الرئيسية (50 مقعد)",
      type: ResourceType.TOOL,
      availabilityStatus: AvailabilityStatus.IN_USE,
      tenantId: "demo-centre",
      costPiasters: 0,
      syncStatus: "synced",
      updatedAtMillis: nowMillis - 10_000,
    },
    {
      id: "res-hall-b",
      name: "قاعة التفوق + بروجكتور تفاعلي",
      type: ResourceType.TOOL,
      availabilityStatus: AvailabilityStatus.AVAILABLE,
      tenantId: "demo-centre",
      costPiasters: 0,
      syncStatus: "synced",
      updatedAtMillis: nowMillis - 20_000,
    },
    {
      id: "res-ta-karim",
      name: "أ. كريم سامي — مساعد التصحيح والطابور",
      type: ResourceType.HUMAN,
      availabilityStatus: AvailabilityStatus.AVAILABLE,
      tenantId: "demo-centre",
      costPiasters: 15000,
      syncStatus: "synced",
      updatedAtMillis: nowMillis - 30_000,
    },
    {
      id: "res-booklets",
      name: "ملازم المراجعة النهائية (120 نسخة)",
      type: ResourceType.FINANCIAL,
      availabilityStatus: AvailabilityStatus.AVAILABLE,
      tenantId: "demo-centre",
      costPiasters: 5000,
      syncStatus: "synced",
      updatedAtMillis: nowMillis - 40_000,
    },
  ];
}

export function initialAttendance(nowMillis: number): AttendanceEntity[] {
  const day = 86_400_000;
  const entries: AttendanceEntity[] = [];
  const dayOffsets = [13, 12, 10, 9, 7, 6, 5, 4, 3, 2, 1];
  dayOffsets.forEach((daysAgo, idx) => {
    const baseTime = nowMillis - daysAgo * day;
    entries.push({
      id: `att-seed-stu1-${daysAgo}`,
      studentId: "stu-1",
      studentNameAr: "أحمد محمد علي",
      studentNameEn: "Ahmed Mohamed Ali",
      groupId: "grp-math-3sec",
      sessionId: `sess-hist-${daysAgo}`,
      feedbackStatus: "valid",
      timestampMillis: baseTime - 3_600_000,
      syncStatus: "synced",
    });
    if (idx % 2 === 0 || daysAgo <= 5) {
      entries.push({
        id: `att-seed-stu2-${daysAgo}`,
        studentId: "stu-2",
        studentNameAr: "سارة خالد حسن",
        studentNameEn: "Sara Khaled Hassan",
        groupId: "grp-math-3sec",
        sessionId: `sess-hist-${daysAgo}`,
        feedbackStatus: daysAgo <= 3 ? "due" : "valid",
        timestampMillis: baseTime - 2_400_000,
        syncStatus: "synced",
      });
    }
    if (idx % 3 !== 1 || daysAgo <= 4) {
      entries.push({
        id: `att-seed-stu3-${daysAgo}`,
        studentId: "stu-3",
        studentNameAr: "يوسف طارق إبراهيم",
        studentNameEn: "Youssef Tarek Ibrahim",
        groupId: "grp-phys-3sec",
        sessionId: `sess-hist-${daysAgo}`,
        feedbackStatus: "valid",
        timestampMillis: baseTime - 1_800_000,
        syncStatus: "synced",
      });
    }
    if (daysAgo === 9 || daysAgo === 4 || daysAgo === 1) {
      entries.push({
        id: `att-seed-stu4-${daysAgo}`,
        studentId: "stu-4",
        studentNameAr: "مريم عادل محمود",
        studentNameEn: "Mariam Adel Mahmoud",
        groupId: "grp-statics-2sec",
        sessionId: `sess-hist-${daysAgo}`,
        feedbackStatus: "blocked",
        timestampMillis: baseTime - 1_200_000,
        syncStatus: "synced",
      });
    }
  });
  return entries;
}

export function initialHomeworkAssignments(nowMillis: number): HomeworkAssignmentEntity[] {
  return [
    {
      id: "hw-calc-1",
      groupId: "grp-math-3sec",
      titleAr: "واجب قاعدة السلسلة والمشتقات العليا",
      titleEn: "Chain Rule & Higher Derivatives Sheet",
      descriptionAr: "حل المسائل من ١ إلى ٨ في ملزمة التفاضل مع كتابة خطوات الحل بوضوح أو إرفاق صورة الكشكول.",
      descriptionEn: "Solve exercises 1–8 from the Calculus booklet with clear steps or attach a notebook photo.",
      dueDateLabel: "الخميس القادم 8:00 م",
      maxScore: 20,
      createdAtMillis: nowMillis - 7_200_000,
    },
    {
      id: "hw-phys-1",
      groupId: "grp-phys-3sec",
      titleAr: "شيت قانون كيرشوف الثاني",
      titleEn: "Kirchhoff Voltage Law Problem Set",
      descriptionAr: "تطبيق مسارات كيرشوف المغلقة على ٣ دوائر كهربية متدرجة الصعوبة.",
      descriptionEn: "Apply closed-loop equations on 3 multi-branch circuits.",
      dueDateLabel: "الجمعة 6:00 م",
      maxScore: 20,
      createdAtMillis: nowMillis - 14_400_000,
    },
  ];
}

export function initialHomeworkSubmissions(nowMillis: number): HomeworkSubmissionEntity[] {
  return [
    {
      id: "hwsub-1",
      assignmentId: "hw-calc-1",
      studentId: "stu-2",
      studentNameAr: "سارة خالد حسن",
      studentNameEn: "Sara Khaled Hassan",
      notes: "تم حل جميع المسائل الثمانية مع التحقق من إشارة المشتقة الثانية.",
      attachmentDataUrl: null,
      score: null,
      feedback: null,
      status: "submitted",
      submittedAtMillis: nowMillis - 1_800_000,
      syncStatus: "synced",
    },
  ];
}

export function initialMistakeBank(nowMillis: number): MistakeBankEntry[] {
  return [
    {
      id: "mis-seed-1",
      studentId: "stu-1",
      sourceType: "quiz",
      topicTagAr: "قاعدة السلسلة",
      topicTagEn: "Chain Rule",
      questionPromptAr: "أوجد مشتقة ص = جا(٣س² + ١) بالنسبة إلى س.",
      questionPromptEn: "Find d/dx of y = sin(3x² + 1).",
      wrongAnswer: "جتا(٣س² + ١)",
      correctAnswer: "٦س · جتا(٣س² + ١)",
      remedialAr: "تذكر دائماً ضرب مشتقة الدالة الخارجية في مشتقة ما بداخل القوس (٦س).",
      remedialEn: "Always multiply the outer derivative by the inner derivative (6x).",
      aiBreakdown: null,
      mastered: false,
      createdAtMillis: nowMillis - 3_600_000,
      syncStatus: "synced",
    },
  ];
}

export function initialAnnouncements(nowMillis: number): AnnouncementEntity[] {
  return [
    {
      id: "ann-1",
      groupId: null,
      titleAr: "مراجعة ليلة الامتحان المحصّنة — الأسبوع القادم",
      titleEn: "Proctored Unit Revision Assessment — Next Week",
      bodyAr: "يرجى التأكد من تفعيل كود الحضور السريع والدخول قبل موعد الامتحان بـ 10 دقائق.",
      bodyEn: "Please ensure your QR attendance pass is ready and join 10 minutes before the assessment.",
      authorName: "أ. طارق عزت",
      pinned: true,
      readByIds: ["stu-2"],
      createdAtMillis: nowMillis - 5_400_000,
    },
  ];
}

export function initialSupportTickets(nowMillis: number): SupportTicketEntity[] {
  return [
    {
      id: "tkt-1",
      authorId: "parent-1",
      authorName: "ولي أمر · أحمد محمد",
      authorRole: UserRole.PARENT,
      subject: "استفسار عن موعد الحصة التعويضية",
      message: "هل يمكن حضور حصة التفاضل التعويضية في مجموعة الثلاثاء بدلاً من السبت؟",
      replyText: "أهلاً بحضرتك، متاح الحضور التعويضي يوم الثلاثاء الساعة 4 م في قاعة النخبة.",
      status: "answered",
      createdAtMillis: nowMillis - 21_600_000,
      syncStatus: "synced",
    },
  ];
}

export function initialParentAlerts(nowMillis: number): ParentAlertEntity[] {
  return [
    {
      id: "pal-1",
      studentId: "stu-1",
      kind: "arrival",
      titleAr: "تأكيد حضور الحصة",
      titleEn: "Session Check-In Confirmed",
      bodyAr: "حضر أحمد محمد علي حصة التفاضل والتكامل في الموعد المحدد بالتمام.",
      bodyEn: "Ahmed Mohamed Ali checked in to Calculus Group A on time.",
      isRead: false,
      createdAtMillis: nowMillis - 2_400_000,
    },
    {
      id: "pal-2",
      studentId: "stu-2",
      kind: "due",
      titleAr: "تنبيه لطيف بالرصيد",
      titleEn: "Friendly Balance Reminder",
      bodyAr: "متبقي 80 ج.م على حساب سارة خالد حسن للحصة القادمة.",
      bodyEn: "80 EGP pending balance for Sara Khaled Hassan ahead of next session.",
      isRead: false,
      createdAtMillis: nowMillis - 1_200_000,
    },
  ];
}

export function initialMakeupSessions(nowMillis: number): MakeupSessionEntity[] {
  return [
    {
      id: "mkp-1",
      studentId: "stu-1",
      studentNameAr: "أحمد محمد علي",
      studentNameEn: "Ahmed Mohamed Ali",
      fromGroupId: "grp-math-3sec",
      toGroupId: "grp-phys-3sec",
      scheduledDateLabel: "الأربعاء 6:00 م",
      note: "تعويض غياب بعذر طبي",
      status: "scheduled",
      createdAtMillis: nowMillis - 9_000_000,
      syncStatus: "synced",
    },
  ];
}
