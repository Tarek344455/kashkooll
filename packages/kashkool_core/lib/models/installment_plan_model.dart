/// Installment plan models for Zero-Cost payment flexibility (متبقي عليه / تقسيط).
///
/// All money uses piasters (int minor units: 1 EGP = 100 piasters).

import 'package:kashkool_core/kashkool_core.dart' show formatPiasters;

/// Status of an installment plan.
enum InstallmentPlanStatus {
  active,
  completed,
  cancelled,
  overdue,
}

/// Status of an individual installment payment.
enum InstallmentPaymentStatus {
  pending,
  paid,
  overdue,
  cancelled,
}

/// A payment plan allowing a student to pay in installments instead of full.
class InstallmentPlanModel {
  final String id;
  final String tenantId;
  final String studentId;
  final String? groupId;
  final int totalAmountPiasters;
  final int paidAmountPiasters;
  final int remainingPiasters;
  final int numberOfInstallments;
  final int installmentAmountPiasters;
  final DateTime startDate;
  final DateTime endDate;
  final InstallmentPlanStatus status;
  final String? description;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  const InstallmentPlanModel({
    required this.id,
    required this.tenantId,
    required this.studentId,
    this.groupId,
    required this.totalAmountPiasters,
    this.paidAmountPiasters = 0,
    required this.remainingPiasters,
    required this.numberOfInstallments,
    required this.installmentAmountPiasters,
    required this.startDate,
    required this.endDate,
    required this.status,
    this.description,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Percentage of the plan paid (0–100).
  double get paidPercentage =>
      totalAmountPiasters == 0 ? 0.0 : (paidAmountPiasters / totalAmountPiasters * 100);

  /// Whether the plan is fully paid.
  bool get isCompleted => status == InstallmentPlanStatus.completed;

  /// Whether the plan has any remaining balance.
  bool get hasRemainingBalance => remainingPiasters > 0;

  InstallmentPlanModel copyWith({
    String? id,
    String? tenantId,
    String? studentId,
    String? groupId,
    int? totalAmountPiasters,
    int? paidAmountPiasters,
    int? remainingPiasters,
    int? numberOfInstallments,
    int? installmentAmountPiasters,
    String? description,
    String? createdBy,
    DateTime? startDate,
    DateTime? endDate,
    InstallmentPlanStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      InstallmentPlanModel(
        id: id ?? this.id,
        tenantId: tenantId ?? this.tenantId,
        studentId: studentId ?? this.studentId,
        groupId: groupId ?? this.groupId,
        totalAmountPiasters: totalAmountPiasters ?? this.totalAmountPiasters,
        paidAmountPiasters: paidAmountPiasters ?? this.paidAmountPiasters,
        remainingPiasters: remainingPiasters ?? this.remainingPiasters,
        numberOfInstallments: numberOfInstallments ?? this.numberOfInstallments,
        installmentAmountPiasters:
            installmentAmountPiasters ?? this.installmentAmountPiasters,
        startDate: startDate ?? this.startDate,
        endDate: endDate ?? this.endDate,
        status: status ?? this.status,
        description: description ?? this.description,
        createdBy: createdBy ?? this.createdBy,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'tenant_id': tenantId,
        'student_id': studentId,
        'group_id': groupId,
        'total_amount_piasters': totalAmountPiasters,
        'paid_amount_piasters': paidAmountPiasters,
        'remaining_piasters': remainingPiasters,
        'number_of_installments': numberOfInstallments,
        'installment_amount_piasters': installmentAmountPiasters,
        'start_date': startDate.toIso8601String(),
        'end_date': endDate.toIso8601String(),
        'status': status.toString().split('.').last,
        'description': description,
        'created_by': createdBy,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  factory InstallmentPlanModel.fromJson(Map<String, dynamic> json) =>
      InstallmentPlanModel(
        id: json['id'] as String,
        tenantId: json['tenant_id'] as String,
        studentId: json['student_id'] as String,
        groupId: json['group_id'] as String?,
        totalAmountPiasters: (json['total_amount_piasters'] as num?)?.toInt() ?? 0,
        paidAmountPiasters: (json['paid_amount_piasters'] as num?)?.toInt() ?? 0,
        remainingPiasters: (json['remaining_piasters'] as num?)?.toInt() ?? 0,
        numberOfInstallments:
            (json['number_of_installments'] as num?)?.toInt() ?? 0,
        installmentAmountPiasters:
            (json['installment_amount_piasters'] as num?)?.toInt() ?? 0,
        startDate: DateTime.tryParse(json['start_date'] as String? ?? '') ??
            DateTime.now(),
        endDate: DateTime.tryParse(json['end_date'] as String? ?? '') ??
            DateTime.now(),
        status: _planStatusFromJson(json['status'] as String?),
        description: json['description'] as String?,
        createdBy: json['created_by'] as String?,
        createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
            DateTime.now(),
        updatedAt: DateTime.tryParse(json['updated_at'] as String? ?? '') ??
            DateTime.now(),
      );
}

/// An individual installment payment within a plan.
class InstallmentPaymentModel {
  final String id;
  final String planId;
  final String tenantId;
  final String studentId;
  final int amountPiasters;
  final DateTime dueDate;
  final DateTime? paidDate;
  final InstallmentPaymentStatus status;
  final String? receiptUrl;
  final String? submissionId;
  final String note;
  final DateTime createdAt;
  final DateTime updatedAt;

  const InstallmentPaymentModel({
    required this.id,
    required this.planId,
    required this.tenantId,
    required this.studentId,
    required this.amountPiasters,
    required this.dueDate,
    this.paidDate,
    required this.status,
    this.receiptUrl,
    this.submissionId,
    this.note = '',
    required this.createdAt,
    required this.updatedAt,
  });

  /// Whether this installment is overdue (not paid and past due date).
  bool get isOverdue =>
      status == InstallmentPaymentStatus.pending &&
      DateTime.now().isAfter(dueDate);

  InstallmentPaymentModel copyWith({
    String? id,
    String? planId,
    String? tenantId,
    String? studentId,
    int? amountPiasters,
    DateTime? dueDate,
    DateTime? paidDate,
    InstallmentPaymentStatus? status,
    String? receiptUrl,
    String? submissionId,
    String? note,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      InstallmentPaymentModel(
        id: id ?? this.id,
        planId: planId ?? this.planId,
        tenantId: tenantId ?? this.tenantId,
        studentId: studentId ?? this.studentId,
        amountPiasters: amountPiasters ?? this.amountPiasters,
        dueDate: dueDate ?? this.dueDate,
        paidDate: paidDate ?? this.paidDate,
        status: status ?? this.status,
        receiptUrl: receiptUrl ?? this.receiptUrl,
        submissionId: submissionId ?? this.submissionId,
        note: note ?? this.note,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'plan_id': planId,
        'tenant_id': tenantId,
        'student_id': studentId,
        'amount_piasters': amountPiasters,
        'due_date': dueDate.toIso8601String(),
        'paid_date': paidDate?.toIso8601String(),
        'status': status.toString().split('.').last,
        'receipt_url': receiptUrl,
        'submission_id': submissionId,
        'note': note,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  factory InstallmentPaymentModel.fromJson(Map<String, dynamic> json) =>
      InstallmentPaymentModel(
        id: json['id'] as String,
        planId: json['plan_id'] as String,
        tenantId: json['tenant_id'] as String,
        studentId: json['student_id'] as String,
        amountPiasters: (json['amount_piasters'] as num?)?.toInt() ?? 0,
        dueDate: DateTime.tryParse(json['due_date'] as String? ?? '') ??
            DateTime.now(),
        paidDate: DateTime.tryParse(json['paid_date'] as String? ?? ''),
        status: _paymentStatusFromJson(json['status'] as String?),
        receiptUrl: json['receipt_url'] as String?,
        submissionId: json['submission_id'] as String?,
        note: json['note'] as String? ?? '',
        createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
            DateTime.now(),
        updatedAt: DateTime.tryParse(json['updated_at'] as String? ?? '') ??
            DateTime.now(),
      );
}

InstallmentPlanStatus _planStatusFromJson(String? value) {
  switch (value) {
    case 'completed':
      return InstallmentPlanStatus.completed;
    case 'cancelled':
      return InstallmentPlanStatus.cancelled;
    case 'overdue':
      return InstallmentPlanStatus.overdue;
    default:
      return InstallmentPlanStatus.active;
  }
}

InstallmentPaymentStatus _paymentStatusFromJson(String? value) {
  switch (value) {
    case 'paid':
      return InstallmentPaymentStatus.paid;
    case 'overdue':
      return InstallmentPaymentStatus.overdue;
    case 'cancelled':
      return InstallmentPaymentStatus.cancelled;
    default:
      return InstallmentPaymentStatus.pending;
  }
}

/// Format remaining balance as EGP string.
String formatRemainingPiasters(int piasters) => formatPiasters(piasters);
