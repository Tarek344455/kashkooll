package com.dig.kashkool.data.local

object KashkoolSeeds {
    val groups: List<GroupEntity> = listOf(
        GroupEntity(
            id = "grp-math-3sec",
            nameAr = "الصف الثالث الثانوي — تفاضل وتكامل (مجموعة أ)",
            nameEn = "Grade 3 Sec — Calculus (Group A)",
            subjectAr = "الرياضيات البحتة",
            subjectEn = "Pure Mathematics",
            scheduleAr = "السبت والثلاثاء 4:00 م",
            scheduleEn = "Sat & Tue 4:00 PM",
            enrolled = 44,
            capacity = 50,
            pricePerSessionPiasters = 8000L,
            centerSplitPercent = 20,
        ),
        GroupEntity(
            id = "grp-phys-3sec",
            nameAr = "الصف الثالث الثانوي — الفيزياء الحديثة (مجموعة ب)",
            nameEn = "Grade 3 Sec — Modern Physics (Group B)",
            subjectAr = "الفيزياء",
            subjectEn = "Physics",
            scheduleAr = "الأحد والأربعاء 6:00 م",
            scheduleEn = "Sun & Wed 6:00 PM",
            enrolled = 38,
            capacity = 40,
            pricePerSessionPiasters = 9000L,
            centerSplitPercent = 20,
        ),
        GroupEntity(
            id = "grp-statics-2sec",
            nameAr = "الصف الثاني الثانوي — الاستاتيكا والهندسة",
            nameEn = "Grade 2 Sec — Statics & Geometry",
            subjectAr = "تطبيقات الرياضيات",
            subjectEn = "Applied Math",
            scheduleAr = "الإثنين والخميس 5:00 م",
            scheduleEn = "Mon & Thu 5:00 PM",
            enrolled = 29,
            capacity = 45,
            pricePerSessionPiasters = 7000L,
            centerSplitPercent = 20,
        ),
    )

    val students: List<StudentEntity> = listOf(
        StudentEntity(
            id = "stu-1",
            nameAr = "أحمد محمد علي",
            nameEn = "Ahmed Mohamed Ali",
            phone = "+201012345678",
            groupId = "grp-math-3sec",
            walletBalancePiasters = 24000L,
            dueBalancePiasters = 0L,
            streakDays = 14,
            masteryPercent = 88,
            qrActivationCode = "KSH2026A",
        ),
        StudentEntity(
            id = "stu-2",
            nameAr = "سارة خالد حسن",
            nameEn = "Sara Khaled Hassan",
            phone = "+201122334455",
            groupId = "grp-math-3sec",
            walletBalancePiasters = 5000L,
            dueBalancePiasters = 8000L,
            streakDays = 9,
            masteryPercent = 92,
            qrActivationCode = "KSH2026B",
        ),
        StudentEntity(
            id = "stu-3",
            nameAr = "يوسف طارق إبراهيم",
            nameEn = "Youssef Tarek Ibrahim",
            phone = "+201234567890",
            groupId = "grp-phys-3sec",
            walletBalancePiasters = 18000L,
            dueBalancePiasters = 0L,
            streakDays = 6,
            masteryPercent = 79,
        ),
        StudentEntity(
            id = "stu-4",
            nameAr = "مريم عادل محمود",
            nameEn = "Mariam Adel Mahmoud",
            phone = "+201555667788",
            groupId = "grp-statics-2sec",
            walletBalancePiasters = 0L,
            dueBalancePiasters = 0L,
            streakDays = 0,
            masteryPercent = 65,
            isBlocked = true,
        ),
    )

    val channels: List<PaymentChannelEntity> = listOf(
        PaymentChannelEntity(
            id = "ch-cashdesk",
            nameAr = "خزينة السنتر (بدون عمولة)",
            nameEn = "Center Cash Desk (0 Fee)",
            channelType = "cash_desk",
            accountRef = "شباك السكرتارية - قاعة أ",
            maxAmountPiasters = 500000L,
            feePiasters = 0L,
        ),
        PaymentChannelEntity(
            id = "ch-instapay",
            nameAr = "إنستاباي — سنتر النخبة",
            nameEn = "InstaPay — Al-Nokhba Center",
            channelType = "insta_pay",
            accountRef = "kashkool.nokhba@instapay",
            maxAmountPiasters = 500000L,
            feePiasters = 0L,
        ),
        PaymentChannelEntity(
            id = "ch-vfcash",
            nameAr = "فودافون كاش",
            nameEn = "Vodafone Cash",
            channelType = "vodafone_cash",
            accountRef = "01098765432",
            maxAmountPiasters = 300000L,
            feePiasters = 500L,
        ),
        PaymentChannelEntity(
            id = "ch-etisalat",
            nameAr = "اتصالات كاش",
            nameEn = "Etisalat Cash",
            channelType = "etisalat_cash",
            accountRef = "01198765432",
            maxAmountPiasters = 300000L,
            feePiasters = 500L,
        ),
        PaymentChannelEntity(
            id = "ch-orange",
            nameAr = "أورانج كاش",
            nameEn = "Orange Cash",
            channelType = "orange_cash",
            accountRef = "01298765432",
            maxAmountPiasters = 300000L,
            feePiasters = 500L,
        ),
        PaymentChannelEntity(
            id = "ch-wepay",
            nameAr = "وي باي (WE Pay)",
            nameEn = "WE Pay",
            channelType = "we_pay",
            accountRef = "01598765432",
            maxAmountPiasters = 300000L,
            feePiasters = 500L,
        ),
        PaymentChannelEntity(
            id = "ch-fawry",
            nameAr = "فوري باي",
            nameEn = "Fawry Pay",
            channelType = "fawry",
            accountRef = "78412",
            maxAmountPiasters = 400000L,
            feePiasters = 1000L,
        ),
    )

    fun initialLedgerEntries(nowMillis: Long): List<LedgerEntryEntity> = listOf(
        LedgerEntryEntity(
            id = "led-seed-1",
            studentId = "stu-1",
            studentNameAr = "أحمد محمد علي",
            studentNameEn = "Ahmed Mohamed Ali",
            kind = LedgerKind.CASH_TOPUP.key,
            amountPiasters = 24000L,
            note = "شحن محفظة الحصص الشهرية",
            createdByRole = "secretary",
            createdAtMillis = nowMillis - 86_400_000L,
            syncStatus = "synced",
        ),
        LedgerEntryEntity(
            id = "led-seed-2",
            studentId = "stu-2",
            studentNameAr = "سارة خالد حسن",
            studentNameEn = "Sara Khaled Hassan",
            kind = LedgerKind.PARTIAL_INSTALLMENT.key,
            amountPiasters = 5000L,
            remainingDuePiasters = 8000L,
            note = "دفع جزئي لحصة التفاضل — متبقي 80 ج.م",
            createdByRole = "secretary",
            createdAtMillis = nowMillis - 43_200_000L,
            syncStatus = "synced",
        ),
    )

    fun initialResources(nowMillis: Long): List<Resource> = listOf(
        Resource(
            id = "res-hall-a",
            name = "قاعة النخبة الرئيسية (50 مقعد)",
            type = ResourceType.TOOL,
            availabilityStatus = AvailabilityStatus.IN_USE,
            costPiasters = 0L,
            syncStatus = "synced",
            updatedAtMillis = nowMillis - 10_000L,
        ),
        Resource(
            id = "res-hall-b",
            name = "قاعة التفوق + بروجكتور تفاعلي",
            type = ResourceType.TOOL,
            availabilityStatus = AvailabilityStatus.AVAILABLE,
            costPiasters = 0L,
            syncStatus = "synced",
            updatedAtMillis = nowMillis - 20_000L,
        ),
        Resource(
            id = "res-ta-karim",
            name = "أ. كريم سامي — مساعد التصحيح والطابور",
            type = ResourceType.HUMAN,
            availabilityStatus = AvailabilityStatus.AVAILABLE,
            costPiasters = 15000L,
            syncStatus = "synced",
            updatedAtMillis = nowMillis - 30_000L,
        ),
        Resource(
            id = "res-booklets",
            name = "ملازم المراجعة النهائية (120 نسخة)",
            type = ResourceType.FINANCIAL,
            availabilityStatus = AvailabilityStatus.AVAILABLE,
            costPiasters = 5000L,
            syncStatus = "synced",
            updatedAtMillis = nowMillis - 40_000L,
        ),
    )

    fun initialAttendance(nowMillis: Long): List<AttendanceEntity> {
        val day = 86_400_000L
        val entries = mutableListOf<AttendanceEntity>()
        val dayOffsets = listOf(13, 12, 10, 9, 7, 6, 5, 4, 3, 2, 1)
        dayOffsets.forEachIndexed { idx, daysAgo ->
            val baseTime = nowMillis - daysAgo * day
            entries += AttendanceEntity(
                id = "att-seed-stu1-$daysAgo",
                studentId = "stu-1",
                studentNameAr = "أحمد محمد علي",
                studentNameEn = "Ahmed Mohamed Ali",
                groupId = "grp-math-3sec",
                sessionId = "sess-hist-$daysAgo",
                feedbackStatus = "valid",
                timestampMillis = baseTime - 3_600_000L,
                syncStatus = "synced",
            )
            if (idx % 2 == 0 || daysAgo <= 5) {
                entries += AttendanceEntity(
                    id = "att-seed-stu2-$daysAgo",
                    studentId = "stu-2",
                    studentNameAr = "سارة خالد حسن",
                    studentNameEn = "Sara Khaled Hassan",
                    groupId = "grp-math-3sec",
                    sessionId = "sess-hist-$daysAgo",
                    feedbackStatus = if (daysAgo <= 3) "due" else "valid",
                    timestampMillis = baseTime - 2_400_000L,
                    syncStatus = "synced",
                )
            }
            if (idx % 3 != 1 || daysAgo <= 4) {
                entries += AttendanceEntity(
                    id = "att-seed-stu3-$daysAgo",
                    studentId = "stu-3",
                    studentNameAr = "يوسف طارق إبراهيم",
                    studentNameEn = "Youssef Tarek Ibrahim",
                    groupId = "grp-phys-3sec",
                    sessionId = "sess-hist-$daysAgo",
                    feedbackStatus = "valid",
                    timestampMillis = baseTime - 1_800_000L,
                    syncStatus = "synced",
                )
            }
            if (daysAgo in listOf(9, 4, 1)) {
                entries += AttendanceEntity(
                    id = "att-seed-stu4-$daysAgo",
                    studentId = "stu-4",
                    studentNameAr = "مريم عادل محمود",
                    studentNameEn = "Mariam Adel Mahmoud",
                    groupId = "grp-statics-2sec",
                    sessionId = "sess-hist-$daysAgo",
                    feedbackStatus = "blocked",
                    timestampMillis = baseTime - 1_200_000L,
                    syncStatus = "synced",
                )
            }
        }
        return entries
    }
}
