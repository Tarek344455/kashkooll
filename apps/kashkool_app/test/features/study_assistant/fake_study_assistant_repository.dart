import 'package:kashkool_app/core/services/spaceship_ai_client.dart';
import 'package:kashkool_app/features/study_assistant/data/study_assistant_repository.dart';

/// Deterministic stand-in for the gateway-backed repository.
class FakeStudyAssistantRepository implements StudyAssistantRepository {
  FakeStudyAssistantRepository({
    this.available = true,
    this.failure,
    AssistantReply Function(List<AssistantTurn> history)? reply,
  }) : _reply = reply;

  bool available;
  AssistantException? failure;
  final AssistantReply Function(List<AssistantTurn> history)? _reply;

  final List<List<AssistantTurn>> calls = [];
  final List<StudyAssistantContext> contexts = [];

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<AssistantReply> reply({
    required StudyAssistantContext context,
    required List<AssistantTurn> history,
  }) async {
    calls.add(history);
    contexts.add(context);
    final error = failure;
    if (error != null) throw error;
    final builder = _reply;
    if (builder != null) return builder(history);
    return const AssistantReply(text: 'رد المساعد');
  }
}
