import {
  AppLanguage,
  AssistantMessage,
  AttendanceEntity,
  PerformanceEvaluationEntity,
  ShiftReconciliation,
  StudentEntity,
} from "../../types/kashkool";
import { EgyptValidators } from "./egyptValidators";

export const KashkoolMessageBuilders = {
  initialAssistantMessage(): AssistantMessage {
    return {
      id: "assistant-welcome",
      fromUser: false,
      text: "أهلاً بك في المساعد الدراسي! اختر درساً أو اكتب سؤالك وسأشرح لك خطوة بخطوة مع مراعاة خطة المراجعة الأنسب لوقتك.",
      suggestions: [
        "اشرح التكامل بالتجزيء بمثال",
        "خطوات حل معادلات الحركة",
        "ملخص قوانين كيرشوف",
      ],
    };
  },

  buildEncouragementMessage(student: StudentEntity | undefined, lang: AppLanguage): string {
    const name = student
      ? lang === AppLanguage.AR
        ? student.nameAr
        : student.nameEn
      : lang === AppLanguage.AR
        ? "بطلي"
        : "champ";
    const mastery = student?.masteryPercent ?? 88;
    return lang === AppLanguage.AR
      ? `فخور بيك يا ${name}! انتظامك في الحضور ووصولك لـ ${mastery}% في المراجعة حاجة تفرح. كمل بنفس الهدوء والتركيز.`
      : `So proud of you, ${name}! Your steady attendance and ${mastery}% mastery show real dedication. Keep going!`;
  },

  buildParentReportShareText(
    student: StudentEntity | undefined,
    attendance: AttendanceEntity[],
    lang: AppLanguage
  ): string {
    const name = student
      ? lang === AppLanguage.AR
        ? student.nameAr
        : student.nameEn
      : lang === AppLanguage.AR
        ? "الطالب"
        : "Student";
    const wallet = EgyptValidators.formatPiasters(student?.walletBalancePiasters ?? 0, lang);
    const mastery = student?.masteryPercent ?? 0;
    const sessionsAttended = attendance.filter((a) => !student || a.studentId === student.id).length;

    return lang === AppLanguage.AR
      ? `تقرير متابعة كشكول — ${name}\n• مستوى الإتقان: ${mastery}%\n• عدد مرات الحضور المسجلة: ${sessionsAttended}\n• الرصيد المتاح: ${wallet}\nمع تحيات إدارة السنتر.`
      : `Kashkool Family Update — ${name}\n• Mastery: ${mastery}%\n• Recorded check-ins: ${sessionsAttended}\n• Wallet balance: ${wallet}`;
  },

  buildEvaluationShareText(evaluation: PerformanceEvaluationEntity, lang: AppLanguage): string {
    const strengthsText = evaluation.strengths.map((s) => `✓ ${s}`).join("\n");
    const planText = evaluation.nextActionPlan.map((s) => `→ ${s}`).join("\n");
    if (lang === AppLanguage.AR) {
      return `تقييم كشكول الموثق — ${evaluation.targetName}
المؤشر العام: ${evaluation.overallScore}/100 (${evaluation.trustBadge})

${evaluation.analyticalSummary}

ملاحظة فورية:
${evaluation.instantFeedback}

نقاط القوة:
${strengthsText}

خطوات التحسين:
${planText}

${evaluation.trustVerificationNote}`;
    }
    return `Kashkool Verified Evaluation — ${evaluation.targetName}
Overall Score: ${evaluation.overallScore}/100 (${evaluation.trustBadge})

${evaluation.analyticalSummary}

Immediate Feedback:
${evaluation.instantFeedback}

Strengths:
${strengthsText}

Action Plan:
${planText}

${evaluation.trustVerificationNote}`;
  },

  buildThermalReceipt(
    reconciliation: ShiftReconciliation,
    attendance: AttendanceEntity[],
    lang: AppLanguage
  ): string {
    const todayCount = attendance.length;
    const lines = attendance
      .slice(0, 6)
      .map((a) => {
        const n = lang === AppLanguage.AR ? a.studentNameAr : a.studentNameEn;
        return `• ${n} [${a.feedbackStatus.toUpperCase()}]`;
      })
      .join("\n");

    if (lang === AppLanguage.AR) {
      return `================================
       كشكول — إيصال الخزينة
================================
السنتر: النخبة التعليمي
عدد المسجلين اليوم: ${todayCount}
النقدية: ${EgyptValidators.formatPiasters(reconciliation.cashCollectedPiasters, "ar")}
التحويلات: ${EgyptValidators.formatPiasters(reconciliation.electronicTransfersPiasters, "ar")}
صافي الدرج: ${EgyptValidators.formatPiasters(reconciliation.netDrawerCashPiasters, "ar")}
--------------------------------
${lines}
================================`;
    }
    return `================================
      KASHKOOL THERMAL RECEIPT
================================
Center: Al-Nokhba Educational
Checked-in Today: ${todayCount}
Cash: ${EgyptValidators.formatPiasters(reconciliation.cashCollectedPiasters, "en")}
Transfers: ${EgyptValidators.formatPiasters(reconciliation.electronicTransfersPiasters, "en")}
Net Drawer: ${EgyptValidators.formatPiasters(reconciliation.netDrawerCashPiasters, "en")}
--------------------------------
${lines}
================================`;
  },
};
