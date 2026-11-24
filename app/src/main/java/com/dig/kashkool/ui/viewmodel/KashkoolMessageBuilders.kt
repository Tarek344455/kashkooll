package com.dig.kashkool.ui.viewmodel

import com.dig.kashkool.core.l10n.AppLanguage
import com.dig.kashkool.core.utils.EgyptValidators
import com.dig.kashkool.data.local.AttendanceEntity
import com.dig.kashkool.data.local.PerformanceEvaluationEntity
import com.dig.kashkool.data.local.StudentEntity

object KashkoolMessageBuilders {
    fun initialAssistantMessage(): AssistantMessage = AssistantMessage(
        fromUser = false,
        text = "أهلاً بك في المساعد الدراسي! اختر درساً أو اكتب سؤالك وسأشرح لك خطوة بخطوة مع مراعاة خطة المراجعة الأنسب لوقتك.",
        suggestions = listOf(
            "اشرح التكامل بالتجزيء بمثال",
            "خطوات حل معادلات الحركة",
            "ملخص قوانين كيرشوف",
        ),
    )

    fun buildEncouragementMessage(student: StudentEntity?, lang: AppLanguage): String {
        val name = student?.let { if (lang == AppLanguage.AR) it.nameAr else it.nameEn }
            ?: if (lang == AppLanguage.AR) "بطلي" else "champ"
        val mastery = student?.masteryPercent ?: 88
        return if (lang == AppLanguage.AR) {
            "فخور بيك يا $name! انتظامك في الحضور ووصولك لـ $mastery% في المراجعة حاجة تفرح. كمل بنفس الهدوء والتركيز."
        } else {
            "So proud of you, $name! Your steady attendance and $mastery% mastery show real dedication. Keep going!"
        }
    }

    fun buildParentReportShareText(
        student: StudentEntity?,
        attendance: List<AttendanceEntity>,
        lang: AppLanguage,
    ): String {
        val name = student?.let { if (lang == AppLanguage.AR) it.nameAr else it.nameEn }
            ?: if (lang == AppLanguage.AR) "الطالب" else "Student"
        val wallet = EgyptValidators.formatPiasters(student?.walletBalancePiasters ?: 0L, lang.code)
        val mastery = student?.masteryPercent ?: 0
        val sessionsAttended = attendance.count { student == null || it.studentId == student.id }
        return if (lang == AppLanguage.AR) {
            "تقرير متابعة كشكول — $name\n• مستوى الإتقان: $mastery%\n• عدد مرات الحضور المسجلة: $sessionsAttended\n• الرصيد المتاح: $wallet\nمع تحيات إدارة السنتر."
        } else {
            "Kashkool Family Update — $name\n• Mastery: $mastery%\n• Recorded check-ins: $sessionsAttended\n• Wallet balance: $wallet"
        }
    }

    fun buildEvaluationShareText(
        evaluation: PerformanceEvaluationEntity,
        lang: AppLanguage,
    ): String {
        val strengthsText = evaluation.strengths.joinToString("\n") { "✓ $it" }
        val planText = evaluation.nextActionPlan.joinToString("\n") { "→ $it" }
        return if (lang == AppLanguage.AR) {
            """
            تقييم كشكول الموثق — ${evaluation.targetName}
            المؤشر العام: ${evaluation.overallScore}/100 (${evaluation.trustBadge})
            
            ${evaluation.analyticalSummary}
            
            ملاحظة فورية:
            ${evaluation.instantFeedback}
            
            نقاط القوة:
            $strengthsText
            
            خطوات التحسين:
            $planText
            
            ${evaluation.trustVerificationNote}
            """.trimIndent()
        } else {
            """
            Kashkool Verified Evaluation — ${evaluation.targetName}
            Overall Score: ${evaluation.overallScore}/100 (${evaluation.trustBadge})
            
            ${evaluation.analyticalSummary}
            
            Immediate Feedback:
            ${evaluation.instantFeedback}
            
            Strengths:
            $strengthsText
            
            Action Plan:
            $planText
            
            ${evaluation.trustVerificationNote}
            """.trimIndent()
        }
    }

    fun buildThermalReceipt(
        reconciliation: ShiftReconciliation,
        attendance: List<AttendanceEntity>,
        lang: AppLanguage,
    ): String {
        val todayCount = attendance.size
        val lines = attendance.take(6).joinToString("\n") {
            val n = if (lang == AppLanguage.AR) it.studentNameAr else it.studentNameEn
            "• $n [${it.feedbackStatus.uppercase()}]"
        }
        return if (lang == AppLanguage.AR) {
            """
            ================================
                   كشكول — إيصال الخزينة
            ================================
            السنتر: النخبة التعليمي
            عدد المسجلين اليوم: $todayCount
            النقدية: ${EgyptValidators.formatPiasters(reconciliation.cashCollectedPiasters, "ar")}
            التحويلات: ${EgyptValidators.formatPiasters(reconciliation.electronicTransfersPiasters, "ar")}
            صافي الدرج: ${EgyptValidators.formatPiasters(reconciliation.netDrawerCashPiasters, "ar")}
            --------------------------------
            $lines
            ================================
            """.trimIndent()
        } else {
            """
            ================================
                  KASHKOOL THERMAL RECEIPT
            ================================
            Center: Al-Nokhba Educational
            Checked-in Today: $todayCount
            Cash: ${EgyptValidators.formatPiasters(reconciliation.cashCollectedPiasters, "en")}
            Transfers: ${EgyptValidators.formatPiasters(reconciliation.electronicTransfersPiasters, "en")}
            Net Drawer: ${EgyptValidators.formatPiasters(reconciliation.netDrawerCashPiasters, "en")}
            --------------------------------
            $lines
            ================================
            """.trimIndent()
        }
    }
}
