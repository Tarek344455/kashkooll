import '../enums/platform_enums.dart';

/// Immutable User entity with deviceFingerprint & role claims.

class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final UserRole role;
  final String tenantId;
  final String deviceFingerprint;
  final bool isEmailVerified;
  final int createdAt;

  const UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.role,
    required this.tenantId,
    required this.deviceFingerprint,
    required this.isEmailVerified,
    required this.createdAt,
  });

  UserModel copyWith({
    String? uid,
    String? email,
    String? displayName,
    UserRole? role,
    String? tenantId,
    String? deviceFingerprint,
    bool? isEmailVerified,
    int? createdAt,
  }) =>
      UserModel(
        uid: uid ?? this.uid,
        email: email ?? this.email,
        displayName: displayName ?? this.displayName,
        role: role ?? this.role,
        tenantId: tenantId ?? this.tenantId,
        deviceFingerprint: deviceFingerprint ?? this.deviceFingerprint,
        isEmailVerified: isEmailVerified ?? this.isEmailVerified,
        createdAt: createdAt ?? this.createdAt,
      );

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'role': role.toString().split('.').last,
      'tenantId': tenantId,
      'deviceFingerprint': deviceFingerprint,
      'isEmailVerified': isEmailVerified,
      'createdAt': createdAt,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] as String,
      email: map['email'] as String,
      displayName: map['displayName'] as String,
      role: UserRole.values.firstWhere((e) => e.toString().split('.').last == map['role']),
      tenantId: map['tenantId'] as String,
      deviceFingerprint: map['deviceFingerprint'] as String,
      isEmailVerified: map['isEmailVerified'] as bool,
      createdAt: map['createdAt'] as int,
    );
  }

  @override
  String toString() => 'UserModel{uid: $uid, role: $role, tenant: $tenantId}';

  @override
  bool operator ==(Object other) => identical(this, other) || other is UserModel && uid == other.uid;

  @override
  int get hashCode => uid.hashCode;
}
