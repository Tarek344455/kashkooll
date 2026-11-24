/// Digital Certificate models (الشهادات الرقمية القابلة للتحقق).
///
/// All certificates have a unique number and QR code for public verification.

/// A digital certificate issued when a student completes a group/session.
class CertificateModel {
  final String id;
  final String tenantId;
  final String studentId;
  final String groupId;
  final String certificateNumber;
  final String title;
  final DateTime issuedAt;
  final DateTime? expiresAt;
  final String qrCodePayload;
  final String? pdfUrl;
  final bool isVerified;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CertificateModel({
    required this.id,
    required this.tenantId,
    required this.studentId,
    required this.groupId,
    required this.certificateNumber,
    required this.title,
    required this.issuedAt,
    this.expiresAt,
    required this.qrCodePayload,
    this.pdfUrl,
    required this.isVerified,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Whether the certificate is still valid (not expired and verified).
  bool get isValid {
    if (!isVerified) return false;
    if (expiresAt != null && DateTime.now().isAfter(expiresAt!)) return false;
    return true;
  }

  CertificateModel copyWith({
    String? id,
    String? tenantId,
    String? studentId,
    String? groupId,
    String? certificateNumber,
    String? title,
    DateTime? issuedAt,
    DateTime? expiresAt,
    String? qrCodePayload,
    String? pdfUrl,
    bool? isVerified,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      CertificateModel(
        id: id ?? this.id,
        tenantId: tenantId ?? this.tenantId,
        studentId: studentId ?? this.studentId,
        groupId: groupId ?? this.groupId,
        certificateNumber: certificateNumber ?? this.certificateNumber,
        title: title ?? this.title,
        issuedAt: issuedAt ?? this.issuedAt,
        expiresAt: expiresAt ?? this.expiresAt,
        qrCodePayload: qrCodePayload ?? this.qrCodePayload,
        pdfUrl: pdfUrl ?? this.pdfUrl,
        isVerified: isVerified ?? this.isVerified,
        createdBy: createdBy ?? this.createdBy,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'tenant_id': tenantId,
        'student_id': studentId,
        'group_id': groupId,
        'certificate_number': certificateNumber,
        'title': title,
        'issued_at': issuedAt.toIso8601String(),
        'expires_at': expiresAt?.toIso8601String(),
        'qr_code_payload': qrCodePayload,
        'pdf_url': pdfUrl,
        'is_verified': isVerified,
        'created_by': createdBy,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  factory CertificateModel.fromJson(Map<String, dynamic> json) =>
      CertificateModel(
        id: json['id'] as String,
        tenantId: json['tenant_id'] as String,
        studentId: json['student_id'] as String,
        groupId: json['group_id'] as String,
        certificateNumber: json['certificate_number'] as String,
        title: json['title'] as String,
        issuedAt: DateTime.tryParse(json['issued_at'] as String? ?? '') ??
            DateTime.now(),
        expiresAt: DateTime.tryParse(json['expires_at'] as String? ?? ''),
        qrCodePayload: json['qr_code_payload'] as String? ?? '',
        pdfUrl: json['pdf_url'] as String?,
        isVerified: json['is_verified'] as bool? ?? false,
        createdBy: json['created_by'] as String?,
        createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
            DateTime.now(),
        updatedAt: DateTime.tryParse(json['updated_at'] as String? ?? '') ??
            DateTime.now(),
      );
}

/// Result of a public certificate verification.
class CertificateVerificationResult {
  final bool valid;
  final String result; // valid / invalid / expired
  final String? certificateId;
  final String? certificateNumber;
  final String? studentId;
  final String? groupId;
  final String? title;
  final DateTime? issuedAt;
  final DateTime? expiresAt;
  final String? message;

  const CertificateVerificationResult({
    required this.valid,
    required this.result,
    this.certificateId,
    this.certificateNumber,
    this.studentId,
    this.groupId,
    this.title,
    this.issuedAt,
    this.expiresAt,
    this.message,
  });

  factory CertificateVerificationResult.fromJson(Map<String, dynamic> json) =>
      CertificateVerificationResult(
        valid: json['valid'] as bool? ?? false,
        result: json['result'] as String? ?? 'invalid',
        certificateId: json['certificateId'] as String?,
        certificateNumber: json['certificateNumber'] as String?,
        studentId: json['studentId'] as String?,
        groupId: json['groupId'] as String?,
        title: json['title'] as String?,
        issuedAt: DateTime.tryParse(json['issuedAt'] as String? ?? ''),
        expiresAt: DateTime.tryParse(json['expiresAt'] as String? ?? ''),
        message: json['message'] as String?,
      );
}
