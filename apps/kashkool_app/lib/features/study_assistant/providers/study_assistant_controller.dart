import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/spaceship_ai_client.dart';
import '../data/study_assistant_repository.dart';

/// One rendered line of the conversation.
class StudyAssistantMessage {
  const StudyAssistantMessage({
    required this.id,
    required this.author,
    required this.text,
    this.suggestions = const [],
  });

  final String id;
  final AssistantTurnAuthor author;
  final String text;
  final List<String> suggestions;

  bool get isAssistant => author == AssistantTurnAuthor.assistant;

  /// The shape the gateway expects when replaying history.
  AssistantTurn toTurn() => AssistantTurn(author: author, text: text);
}

/// Everything the assistant surface must render.
class StudyAssistantState {
  const StudyAssistantState({
    this.context,
    this.messages = const [],
    this.isProbing = false,
    this.isSending = false,
    this.gatewayReachable,
    this.errorMessage,
    this.failedPrompt,
  });

  /// Lesson the conversation is bound to. Null until [configure] runs.
  final StudyAssistantContext? context;

  final List<StudyAssistantMessage> messages;

  /// A health probe is in flight.
  final bool isProbing;

  /// An answer is in flight.
  final bool isSending;

  /// `null` while unknown, then true/false from the last probe.
  final bool? gatewayReachable;

  /// Arabic message for the error state. Null when the last turn succeeded.
  final String? errorMessage;

  /// Prompt that failed, so retry resends exactly it.
  final String? failedPrompt;

  bool get isEmpty => messages.isEmpty;

  bool get isBusy => isProbing || isSending;

  bool get isOffline => gatewayReachable == false;

  StudyAssistantState copyWith({
    StudyAssistantContext? context,
    List<StudyAssistantMessage>? messages,
    bool? isProbing,
    bool? isSending,
    bool? gatewayReachable,
    String? errorMessage,
    String? failedPrompt,
    bool clearError = false,
    bool clearReachability = false,
  }) {
    return StudyAssistantState(
      context: context ?? this.context,
      messages: messages ?? this.messages,
      isProbing: isProbing ?? this.isProbing,
      isSending: isSending ?? this.isSending,
      gatewayReachable: clearReachability
          ? null
          : (gatewayReachable ?? this.gatewayReachable),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      failedPrompt: clearError ? null : (failedPrompt ?? this.failedPrompt),
    );
  }
}

/// Controller for the study assistant conversation.
///
/// Owns the four UI states the project requires: probing/sending (loading),
/// empty, error with retry, and populated. It never fabricates an answer: a
/// failed request becomes a visible error, and every message here was produced
/// either by the learner or by the gateway.
class StudyAssistantController extends Notifier<StudyAssistantState> {
  @override
  StudyAssistantState build() => const StudyAssistantState();

  StudyAssistantRepository get _repository =>
      ref.read(studyAssistantRepositoryProvider);

  /// Binds the conversation to a lesson and probes the gateway.
  ///
  /// Re-binding to a different lesson starts a fresh thread; re-binding to the
  /// same lesson keeps the existing conversation intact.
  Future<void> configure(StudyAssistantContext context) async {
    if (state.context == context) return;
    state = StudyAssistantState(context: context);
    await probe();
  }

  /// Switches the academic voice without discarding the thread.
  void setRole(KashkoolAiRole role) {
    final current = state.context;
    if (current == null || current.role == role) return;
    state = state.copyWith(context: current.copyWith(role: role));
  }

  /// Checks whether the gateway is reachable, without sending a question.
  Future<void> probe() async {
    if (state.isProbing) return;
    state = state.copyWith(isProbing: true, clearError: true);
    var reachable = false;
    try {
      reachable = await _repository.isAvailable();
    } catch (_) {
      reachable = false;
    }
    state = state.copyWith(
      isProbing: false,
      gatewayReachable: reachable,
      errorMessage: reachable
          ? null
          : 'تعذّر الوصول إلى محرك المساعدة. تأكد من الاتصال بالشبكة ثم أعد المحاولة.',
      clearError: reachable,
    );
  }

  /// Sends a learner message and appends the answer.
  Future<void> send(String prompt) async {
    final text = prompt.trim();
    final context = state.context;
    if (text.isEmpty || context == null || state.isSending) return;

    final learnerMessage = StudyAssistantMessage(
      id: _nextId(),
      author: AssistantTurnAuthor.learner,
      text: text,
    );

    state = state.copyWith(
      messages: [...state.messages, learnerMessage],
      isSending: true,
      clearError: true,
    );

    await _request(context);
  }

  /// Re-sends the prompt that failed, without duplicating the user bubble.
  Future<void> retry() async {
    final context = state.context;
    if (context == null || state.isSending) return;

    final failed = state.failedPrompt;
    if (failed == null || failed.isEmpty) {
      await probe();
      return;
    }

    state = state.copyWith(isSending: true, clearError: true);
    await _request(context);
  }

  /// Clears the thread and keeps the lesson binding.
  void clearConversation() {
    state = state.copyWith(messages: const [], clearError: true);
  }

  Future<void> _request(StudyAssistantContext context) async {
    try {
      final reply = await _repository.reply(
        context: context,
        history: state.messages.map((message) => message.toTurn()).toList(),
      );

      if (!reply.isUsable) {
        throw const AssistantException(
          AssistantFailure.invalidResponse,
          'Gateway reply had no visible text',
        );
      }

      state = state.copyWith(
        messages: [
          ...state.messages,
          StudyAssistantMessage(
            id: _nextId(),
            author: AssistantTurnAuthor.assistant,
            text: reply.text,
            suggestions: reply.suggestions,
          ),
        ],
        isSending: false,
        gatewayReachable: true,
        clearError: true,
      );
    } on AssistantException catch (error) {
      state = state.copyWith(
        isSending: false,
        gatewayReachable: error.failure == AssistantFailure.unreachable
            ? false
            : state.gatewayReachable,
        errorMessage: error.userMessage,
        failedPrompt: _lastLearnerPrompt(),
      );
    } catch (_) {
      state = state.copyWith(
        isSending: false,
        errorMessage: 'حدث خطأ غير متوقع أثناء تجهيز الإجابة. أعد المحاولة.',
        failedPrompt: _lastLearnerPrompt(),
      );
    }
  }

  String? _lastLearnerPrompt() {
    for (final message in state.messages.reversed) {
      if (!message.isAssistant) return message.text;
    }
    return null;
  }

  int _sequence = 0;

  String _nextId() {
    _sequence++;
    return '${DateTime.now().microsecondsSinceEpoch}-$_sequence';
  }
}

/// Repository provider, overridable in tests.
final studyAssistantRepositoryProvider = Provider<StudyAssistantRepository>((ref) {
  return StudyAssistantRepository(ref.watch(spaceshipAiClientProvider));
});

/// Conversation controller.
final studyAssistantProvider =
    NotifierProvider<StudyAssistantController, StudyAssistantState>(
  StudyAssistantController.new,
);
