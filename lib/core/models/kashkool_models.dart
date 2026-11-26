enum AppLanguage { ar, en }

enum UserRole { student, secretary, teacher, parent }

enum AppDestination {
  home,
  desk,
  analytics,
  teacher,
  courses,
  wallet,
  assistant,
  parent,
}

enum LedgerKind {
  cashTopup,
  partialInstallment,
  bookReservation,
  discount,
  sessionCharge,
  settlement,
  voidEntry,
}

enum SubmissionStatus { pending, approved, rejected }

enum EmotionalPulse {
  examAnxiety,
  frustration,
  burnout,
  lowConfidence,
  curiosity,
  distraction,
  calm,
}

enum RoutingLane {
  ultraFastEmpathetic,
  deepCognitiveReasoning,
  visionMultimodal,
  structuredJson,
}

class CognitiveMeta {
  final EmotionalPulse emotion;
  final RoutingLane lane;
  final String strategyAr;
  final String strategyEn;
  final int? ttftMs;

  const CognitiveMeta({
    required this.emotion,
    required this.lane,
    required this.strategyAr,
    required this.strategyEn,
    this.ttftMs,
  });
}

class GroupEntity {
  final String id;
  final String nameAr;
  final String nameEn;
  final String subjectAr;
  final String subjectEn;
  final String scheduleAr;
  final String scheduleEn;
  final int enrolled;
  final int capacity;
  final int pricePerSessionPiasters;
  final int centerSplitPercent;

  const GroupEntity({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.subjectAr,
    required this.subjectEn,
    required this.scheduleAr,
    required this.scheduleEn,
    required this.enrolled,
    required this.capacity,
    required this.pricePerSessionPiasters,
    required this.centerSplitPercent,
  });
}

class StudentEntity {
  final String id;
  final String nameAr;
  final String nameEn;
  final String phone;
  final String groupId;
  final int walletBalancePiasters;
  final int dueBalancePiasters;
  final int streakDays;
  final int masteryPercent;
  final bool isBlocked;
  final String qrActivationCode;
  final String parentInviteCode;

  const StudentEntity({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.phone,
    required this.groupId,
    required this.walletBalancePiasters,
    required this.dueBalancePiasters,
    required this.streakDays,
    required this.masteryPercent,
    required this.isBlocked,
    required this.qrActivationCode,
    required this.parentInviteCode,
  });

  StudentEntity copyWith({
    int? walletBalancePiasters,
    int? dueBalancePiasters,
    int? streakDays,
    int? masteryPercent,
    bool? isBlocked,
  }) {
    return StudentEntity(
      id: id,
      nameAr: nameAr,
      nameEn: nameEn,
      phone: phone,
      groupId: groupId,
      walletBalancePiasters: walletBalancePiasters ?? this.walletBalancePiasters,
      dueBalancePiasters: dueBalancePiasters ?? this.dueBalancePiasters,
      streakDays: streakDays ?? this.streakDays,
      masteryPercent: masteryPercent ?? this.masteryPercent,
      isBlocked: isBlocked ?? this.isBlocked,
      qrActivationCode: qrActivationCode,
      parentInviteCode: parentInviteCode,
    );
  }
}

class AttendanceEntity {
  final String id;
  final String studentId;
  final String groupId;
  final String feedbackStatus; // 'valid' | 'due' | 'blocked'
  final DateTime timestamp;

  const AttendanceEntity({
    required this.id,
    required this.studentId,
    required this.groupId,
    required this.feedbackStatus,
    required this.timestamp,
  });
}

class LedgerEntryEntity {
  final String id;
  final String studentId;
  final String studentNameAr;
  final String studentNameEn;
  final LedgerKind kind;
  final int amountPiasters;
  final String note;
  final String? voidedEntryId;
  final DateTime timestamp;

  const LedgerEntryEntity({
    required this.id,
    required this.studentId,
    required this.studentNameAr,
    required this.studentNameEn,
    required this.kind,
    required this.amountPiasters,
    required this.note,
    this.voidedEntryId,
    required this.timestamp,
  });
}

class PaymentSubmissionEntity {
  final String id;
  final String studentId;
  final String channelName;
  final int amountPiasters;
  final String senderReference;
  final SubmissionStatus status;
  final String? rejectionReason;

  const PaymentSubmissionEntity({
    required this.id,
    required this.studentId,
    required this.channelName,
    required this.amountPiasters,
    required this.senderReference,
    required this.status,
    this.rejectionReason,
  });

  PaymentSubmissionEntity copyWith({
    SubmissionStatus? status,
    String? rejectionReason,
  }) {
    return PaymentSubmissionEntity(
      id: id,
      studentId: studentId,
      channelName: channelName,
      amountPiasters: amountPiasters,
      senderReference: senderReference,
      status: status ?? this.status,
      rejectionReason: rejectionReason ?? this.rejectionReason,
    );
  }
}

class CourseUnit {
  final String id;
  final String titleAr;
  final String titleEn;
  final String subjectAr;
  final String subjectEn;
  final int durationMinutes;
  final String summaryAr;
  final String summaryEn;

  const CourseUnit({
    required this.id,
    required this.titleAr,
    required this.titleEn,
    required this.subjectAr,
    required this.subjectEn,
    required this.durationMinutes,
    required this.summaryAr,
    required this.summaryEn,
  });
}

class QuizQuestion {
  final String id;
  final String topicTagAr;
  final String topicTagEn;
  final String promptAr;
  final String promptEn;
  final String formula;
  final List<String> options;
  final int correctIndex;
  final String remedialAr;
  final String remedialEn;

  const QuizQuestion({
    required this.id,
    required this.topicTagAr,
    required this.topicTagEn,
    required this.promptAr,
    required this.promptEn,
    required this.formula,
    required this.options,
    required this.correctIndex,
    required this.remedialAr,
    required this.remedialEn,
  });
}

class AssistantMessage {
  final String id;
  final bool fromUser;
  final String text;
  final CognitiveMeta? cognitiveMeta;

  const AssistantMessage({
    required this.id,
    required this.fromUser,
    required this.text,
    this.cognitiveMeta,
  });
}
