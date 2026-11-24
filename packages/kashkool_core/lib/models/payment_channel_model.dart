/// Payment channels a teacher/center accepts payments on, plus student
/// receipt submissions and the immutable ledger they feed.
///
/// All money uses piasters (int minor units: 1 EGP = 100 piasters).

import '../utils/egypt_validators.dart';

/// Status of a student receipt submission.
enum PaymentSubmissionStatus {
  pending,
  approved,
  rejected,
}

/// A configured payment channel for a tenant (teacher or center account).
class PaymentChannelModel {
  final String id;
  final String tenantId;
  final String name;
  final String channelType; // vodafone_cash / insta_pay / fawry / cash
  final String accountRef;  // phone / wallet / merchant ref
  final int feePiasters;
  final int minAmountPiasters;
  final int maxAmountPiasters;
  final bool active;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PaymentChannelModel({
    required this.id,
    required this.tenantId,
    required this.name,
    required this.channelType,
    required this.accountRef,
    this.feePiasters = 0,
    this.minAmountPiasters = 0,
    required this.maxAmountPiasters,
    this.active = true,
    required this.createdAt,
    required this.updatedAt,
  });

  PaymentChannelModel copyWith({
    String? id,
    String? tenantId,
    String? name,
    String? channelType,
    String? accountRef,
    int? feePiasters,
    int? minAmountPiasters,
    int? maxAmountPiasters,
    bool? active,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      PaymentChannelModel(
        id: id ?? this.id,
        tenantId: tenantId ?? this.tenantId,
        name: name ?? this.name,
        channelType: channelType ?? this.channelType,
        accountRef: accountRef ?? this.accountRef,
        feePiasters: feePiasters ?? this.feePiasters,
        minAmountPiasters: minAmountPiasters ?? this.minAmountPiasters,
        maxAmountPiasters: maxAmountPiasters ?? this.maxAmountPiasters,
        active: active ?? this.active,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'tenant_id': tenantId,
        'name': name,
        'channel_type': channelType,
        'account_ref': accountRef,
        'fee_piasters': feePiasters,
        'min_amount_piasters': minAmountPiasters,
        'max_amount_piasters': maxAmountPiasters,
        'active': active,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  factory PaymentChannelModel.fromJson(Map<String, dynamic> json) =>
      PaymentChannelModel(
        id: json['id'] as String,
        tenantId: json['tenant_id'] as String,
        name: json['name'] as String,
        channelType: json['channel_type'] as String,
        accountRef: json['account_ref'] as String,
        feePiasters: (json['fee_piasters'] as num?)?.toInt() ?? 0,
        minAmountPiasters: (json['min_amount_piasters'] as num?)?.toInt() ?? 0,
        maxAmountPiasters: (json['max_amount_piasters'] as num?)?.toInt() ?? 0,
        active: json['active'] as bool? ?? true,
        createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
            DateTime.now(),
        updatedAt: DateTime.tryParse(json['updated_at'] as String? ?? '') ??
            DateTime.now(),
      );
}

/// A student receipt submission awaiting approval or rejection.
class PaymentSubmissionModel {
  final String id;
  final String tenantId;
  final String studentId;
  final String channelId;
  final String? channelName;
  final int amountPiasters;
  final String senderReference;
  final String receiptUrl;
  final PaymentSubmissionStatus status;
  final String? reviewedBy;
  final DateTime? reviewedAt;
  final String? rejectionReason;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PaymentSubmissionModel({
    required this.id,
    required this.tenantId,
    required this.studentId,
    required this.channelId,
    this.channelName,
    required this.amountPiasters,
    required this.senderReference,
    required this.receiptUrl,
    required this.status,
    this.reviewedBy,
    this.reviewedAt,
    this.rejectionReason,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isPending => status == PaymentSubmissionStatus.pending;
  bool get isApproved => status == PaymentSubmissionStatus.approved;
  bool get isRejected => status == PaymentSubmissionStatus.rejected;

  PaymentSubmissionModel copyWith({
    String? id,
    String? tenantId,
    String? studentId,
    String? channelId,
    String? channelName,
    int? amountPiasters,
    String? senderReference,
    String? receiptUrl,
    PaymentSubmissionStatus? status,
    String? reviewedBy,
    DateTime? reviewedAt,
    String? rejectionReason,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      PaymentSubmissionModel(
        id: id ?? this.id,
        tenantId: tenantId ?? this.tenantId,
        studentId: studentId ?? this.studentId,
        channelId: channelId ?? this.channelId,
        channelName: channelName ?? this.channelName,
        amountPiasters: amountPiasters ?? this.amountPiasters,
        senderReference: senderReference ?? this.senderReference,
        receiptUrl: receiptUrl ?? this.receiptUrl,
        status: status ?? this.status,
        reviewedBy: reviewedBy ?? this.reviewedBy,
        reviewedAt: reviewedAt ?? this.reviewedAt,
        rejectionReason: rejectionReason ?? this.rejectionReason,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'tenant_id': tenantId,
        'student_id': studentId,
        'channel_id': channelId,
        'channel_name': channelName,
        'amount_piasters': amountPiasters,
        'sender_reference': senderReference,
        'receipt_url': receiptUrl,
        'status': status.toString().split('.').last,
        'reviewed_by': reviewedBy,
        'reviewed_at': reviewedAt?.toIso8601String(),
        'rejection_reason': rejectionReason,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  factory PaymentSubmissionModel.fromJson(Map<String, dynamic> json) =>
      PaymentSubmissionModel(
        id: json['id'] as String,
        tenantId: json['tenant_id'] as String,
        studentId: json['student_id'] as String,
        channelId: json['channel_id'] as String,
        channelName: json['channel_name'] as String?,
        amountPiasters: (json['amount_piasters'] as num?)?.toInt() ?? 0,
        senderReference: json['sender_reference'] as String,
        receiptUrl: json['receipt_url'] as String,
        status: _statusFromJson(json['status'] as String?),
        reviewedBy: json['reviewed_by'] as String?,
        reviewedAt: DateTime.tryParse(json['reviewed_at'] as String? ?? ''),
        rejectionReason: json['rejection_reason'] as String?,
        createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
            DateTime.now(),
        updatedAt: DateTime.tryParse(json['updated_at'] as String? ?? '') ??
            DateTime.now(),
      );
}

PaymentSubmissionStatus _statusFromJson(String? value) {
  switch (value) {
    case 'approved':
      return PaymentSubmissionStatus.approved;
    case 'rejected':
      return PaymentSubmissionStatus.rejected;
    default:
      return PaymentSubmissionStatus.pending;
  }
}

/// An immutable entry in the financial ledger (append-only).
class LedgerEntryModel {
  final String id;
  final String tenantId;
  final String studentId;
  final int amountPiasters; // negative = money out
  final String kind; // payment / topup / charge / void / refund / settlement
  final String channel;
  final String? referenceId;
  final String? idempotencyKey;
  final String? voidsEntryId;
  final String note;
  final String? createdBy;
  final DateTime createdAt;

  const LedgerEntryModel({
    required this.id,
    required this.tenantId,
    required this.studentId,
    required this.amountPiasters,
    required this.kind,
    this.channel = 'cash',
    this.referenceId,
    this.idempotencyKey,
    this.voidsEntryId,
    this.note = '',
    this.createdBy,
    required this.createdAt,
  });

  bool get isCredit => amountPiasters > 0;
  bool get isDebit => amountPiasters < 0;

  LedgerEntryModel copyWith({
    String? id,
    String? tenantId,
    String? studentId,
    int? amountPiasters,
    String? kind,
    String? channel,
    String? referenceId,
    String? idempotencyKey,
    String? voidsEntryId,
    String? note,
    String? createdBy,
    DateTime? createdAt,
  }) =>
      LedgerEntryModel(
        id: id ?? this.id,
        tenantId: tenantId ?? this.tenantId,
        studentId: studentId ?? this.studentId,
        amountPiasters: amountPiasters ?? this.amountPiasters,
        kind: kind ?? this.kind,
        channel: channel ?? this.channel,
        referenceId: referenceId ?? this.referenceId,
        idempotencyKey: idempotencyKey ?? this.idempotencyKey,
        voidsEntryId: voidsEntryId ?? this.voidsEntryId,
        note: note ?? this.note,
        createdBy: createdBy ?? this.createdBy,
        createdAt: createdAt ?? this.createdAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'tenant_id': tenantId,
        'student_id': studentId,
        'amount_piasters': amountPiasters,
        'kind': kind,
        'channel': channel,
        'reference_id': referenceId,
        'idempotency_key': idempotencyKey,
        'voids_entry_id': voidsEntryId,
        'note': note,
        'created_by': createdBy,
        'created_at': createdAt.toIso8601String(),
      };

  factory LedgerEntryModel.fromJson(Map<String, dynamic> json) =>
      LedgerEntryModel(
        id: json['id'] as String,
        tenantId: json['tenant_id'] as String,
        studentId: json['student_id'] as String,
        amountPiasters: (json['amount_piasters'] as num?)?.toInt() ?? 0,
        kind: json['kind'] as String,
        channel: json['channel'] as String? ?? 'cash',
        referenceId: json['reference_id'] as String?,
        idempotencyKey: json['idempotency_key'] as String?,
        voidsEntryId: json['voids_entry_id'] as String?,
        note: json['note'] as String? ?? '',
        createdBy: json['created_by'] as String?,
        createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
            DateTime.now(),
      );
}

/// Format an integer piasters amount as an EGP string with two decimals.
String formatPiasters(int piasters) => EgyptValidators.formatPiasters(piasters);
