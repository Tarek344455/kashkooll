import '../enums/platform_enums.dart';

/// Offline/Online class sessions & Dynamic QR attendance records.

class SessionModel {
  final String sessionId;
  final String tenantId;
  final String groupId;
  final String title;
  final SessionType type;
  final DateTime startTime;
  final String qrSecret;
  final List<String> studentIds;

  const SessionModel({
    required this.sessionId,
    required this.tenantId,
    required this.groupId,
    required this.title,
    required this.type,
    required this.startTime,
    required this.qrSecret,
    required this.studentIds,
  });

  Map<String, dynamic> toMap() {
    return {
      'sessionId': sessionId,
      'tenantId': tenantId,
      'groupId': groupId,
      'title': title,
      'type': type.toString().split('.').last,
      'startTime': startTime.toIso8601String(),
      'qrSecret': qrSecret,
      'studentIds': studentIds,
    };
  }

  factory SessionModel.fromMap(Map<String, dynamic> map) {
    return SessionModel(
      sessionId: map['sessionId'] as String,
      tenantId: map['tenantId'] as String,
      groupId: map['groupId'] as String,
      title: map['title'] as String,
      type: SessionType.values.firstWhere((e) => e.toString().split('.').last == map['type']),
      startTime: DateTime.parse(map['startTime'] as String),
      qrSecret: map['qrSecret'] as String,
      studentIds: List<String>.from(map['studentIds'] as List),
    );
  }
}
