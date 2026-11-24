import '../../../core/services/spaceship_ai_client.dart';

/// Everything the assistant needs to know about the current lesson.
class StudyAssistantContext {
  const StudyAssistantContext({
    required this.subject,
    required this.lesson,
    required this.role,
    this.grade = 'الصف الثالث الثانوي',
    this.tenantId,
  });

  final String subject;
  final String lesson;
  final KashkoolAiRole role;
  final String grade;
  final String? tenantId;

  bool get isTeacher => role == KashkoolAiRole.teacher;

  StudyAssistantContext copyWith({
    String? subject,
    String? lesson,
    KashkoolAiRole? role,
    String? grade,
    String? tenantId,
  }) {
    return StudyAssistantContext(
      subject: subject ?? this.subject,
      lesson: lesson ?? this.lesson,
      role: role ?? this.role,
      grade: grade ?? this.grade,
      tenantId: tenantId ?? this.tenantId,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is StudyAssistantContext &&
      other.subject == subject &&
      other.lesson == lesson &&
      other.role == role &&
      other.grade == grade &&
      other.tenantId == tenantId;

  @override
  int get hashCode => Object.hash(subject, lesson, role, grade, tenantId);
}

/// Data layer for the study assistant.
///
/// Wraps [SpaceshipAiClient] so the controller never builds prompts or parses
/// payloads itself, and so tests can swap in a fake repository.
class StudyAssistantRepository {
  StudyAssistantRepository(this._client);

  final SpaceshipAiClient _client;

  /// True when the gateway answers its health probe.
  Future<bool> isAvailable() => _client.checkAvailability();

  /// Sends the conversation and returns the next answer.
  Future<AssistantReply> reply({
    required StudyAssistantContext context,
    required List<AssistantTurn> history,
  }) {
    return _client.chat(
      role: context.role,
      turns: history,
      subject: context.subject,
      grade: context.grade,
      tenantId: context.tenantId,
    );
  }
}
