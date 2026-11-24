import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kashkool_app/core/services/spaceship_ai_client.dart';
import 'package:kashkool_app/features/study_assistant/data/study_assistant_repository.dart';
import 'package:kashkool_app/features/study_assistant/providers/study_assistant_controller.dart';

import 'fake_study_assistant_repository.dart';

const _context = StudyAssistantContext(
  subject: 'Ø§Ù„Ø±ÙŠØ§Ø¶ÙŠØ§Øª',
  lesson: 'Ø§Ù„ØªÙƒØ§Ù…Ù„ Ø¨Ø§Ù„ØªØ¬Ø²ÙŠØ¡',
  role: KashkoolAiRole.student,
);

ProviderContainer _containerWith(FakeStudyAssistantRepository repository) {
  final container = ProviderContainer(
    overrides: [studyAssistantRepositoryProvider.overrideWithValue(repository)],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  test('starts empty and probes the gateway on configure', () async {
    final repository = FakeStudyAssistantRepository();
    final container = _containerWith(repository);
    final notifier = container.read(studyAssistantProvider.notifier);

    expect(container.read(studyAssistantProvider).isEmpty, isTrue);

    await notifier.configure(_context);
    final state = container.read(studyAssistantProvider);

    expect(state.context, _context);
    expect(state.gatewayReachable, isTrue);
    expect(state.errorMessage, isNull);
    expect(state.isEmpty, isTrue);
  });

  test('send appends the learner turn and the answer', () async {
    final repository = FakeStudyAssistantRepository(
      reply: (_) => const AssistantReply(
        text: 'Ù…Ø§ Ø§Ù„Ù…Ø¹Ø·ÙŠØ§ØªØŸ',
        suggestions: ['ØªÙ„Ù…ÙŠØ­'],
      ),
    );
    final container = _containerWith(repository);
    final notifier = container.read(studyAssistantProvider.notifier);
    await notifier.configure(_context);

    await notifier.send('Ø§Ø¨Ø¯Ø£ Ø§Ù„Ø¯Ø±Ø³');

    final state = container.read(studyAssistantProvider);
    expect(state.messages, hasLength(2));
    expect(state.messages[0].isAssistant, isFalse);
    expect(state.messages[0].text, 'Ø§Ø¨Ø¯Ø£ Ø§Ù„Ø¯Ø±Ø³');
    expect(state.messages[1].isAssistant, isTrue);
    expect(state.messages[1].text, 'Ù…Ø§ Ø§Ù„Ù…Ø¹Ø·ÙŠØ§ØªØŸ');
    expect(state.messages[1].suggestions, ['ØªÙ„Ù…ÙŠØ­']);
    expect(state.isSending, isFalse);
    expect(repository.calls.single, hasLength(1));
  });

  test('the second turn sends the previous answer as context', () async {
    final repository = FakeStudyAssistantRepository(
      reply: (history) => AssistantReply(text: 'Ø±Ø¯ ${history.length}'),
    );
    final container = _containerWith(repository);
    final notifier = container.read(studyAssistantProvider.notifier);
    await notifier.configure(_context);

    await notifier.send('Ø³Ø¤Ø§Ù„ Ø£ÙˆÙ„');
    await notifier.send('Ø³Ø¤Ø§Ù„ Ø«Ø§Ù†ÙŠ');

    expect(repository.calls.last.map((t) => t.text).toList(),
        ['Ø³Ø¤Ø§Ù„ Ø£ÙˆÙ„', 'Ø±Ø¯ 1', 'Ø³Ø¤Ø§Ù„ Ø«Ø§Ù†ÙŠ']);
  });

  test('a failure becomes a visible error with the prompt kept for retry',
      () async {
    final repository = FakeStudyAssistantRepository(
      failure: const AssistantException(AssistantFailure.timeout, 'timeout'),
    );
    final container = _containerWith(repository);
    final notifier = container.read(studyAssistantProvider.notifier);
    await notifier.configure(_context);

    await notifier.send('Ø³Ø¤Ø§Ù„ ØµØ¹Ø¨');

    var state = container.read(studyAssistantProvider);
    expect(state.errorMessage, isNotNull);
    expect(state.failedPrompt, 'Ø³Ø¤Ø§Ù„ ØµØ¹Ø¨');
    expect(state.messages, hasLength(1), reason: 'only the learner turn');
    expect(state.isSending, isFalse);
    expect(state.isEmpty, isFalse);

    // Recover, then retry: no duplicated learner bubble.
    repository.failure = null;
    await notifier.retry();

    state = container.read(studyAssistantProvider);
    expect(state.errorMessage, isNull);
    expect(state.messages, hasLength(2));
    expect(state.messages.first.text, 'Ø³Ø¤Ø§Ù„ ØµØ¹Ø¨');
    expect(state.messages.last.isAssistant, isTrue);
  });

  test('an unreachable gateway marks the surface offline', () async {
    final repository = FakeStudyAssistantRepository(
      failure: const AssistantException(AssistantFailure.unreachable, 'refused'),
    );
    final container = _containerWith(repository);
    final notifier = container.read(studyAssistantProvider.notifier);
    await notifier.configure(_context);

    await notifier.send('Ø³Ø¤Ø§Ù„');

    final state = container.read(studyAssistantProvider);
    expect(state.isOffline, isTrue);
    expect(state.errorMessage, isNotNull);
  });

  test('probe failure shows the error state before any message', () async {
    final repository = FakeStudyAssistantRepository(available: false);
    final container = _containerWith(repository);
    final notifier = container.read(studyAssistantProvider.notifier);

    await notifier.configure(_context);

    final state = container.read(studyAssistantProvider);
    expect(state.gatewayReachable, isFalse);
    expect(state.isEmpty, isTrue);
    expect(state.errorMessage, isNotNull);
  });

  test('blank prompts and concurrent sends are ignored', () async {
    final repository = FakeStudyAssistantRepository();
    final container = _containerWith(repository);
    final notifier = container.read(studyAssistantProvider.notifier);
    await notifier.configure(_context);

    await notifier.send('   ');
    expect(container.read(studyAssistantProvider).messages, isEmpty);

    final first = notifier.send('Ø³Ø¤Ø§Ù„');
    await notifier.send('Ø³Ø¤Ø§Ù„ Ù…ØªØ²Ø§Ù…Ù†');
    await first;

    expect(container.read(studyAssistantProvider).messages, hasLength(2));
    expect(repository.calls, hasLength(1));
  });

  test('switching the voice keeps the thread', () async {
    final repository = FakeStudyAssistantRepository();
    final container = _containerWith(repository);
    final notifier = container.read(studyAssistantProvider.notifier);
    await notifier.configure(_context);
    await notifier.send('Ø³Ø¤Ø§Ù„');

    notifier.setRole(KashkoolAiRole.teacher);

    final state = container.read(studyAssistantProvider);
    expect(state.context?.role, KashkoolAiRole.teacher);
    expect(state.messages, hasLength(2));
  });

  test('re-binding to a new lesson starts a fresh thread', () async {
    final repository = FakeStudyAssistantRepository();
    final container = _containerWith(repository);
    final notifier = container.read(studyAssistantProvider.notifier);
    await notifier.configure(_context);
    await notifier.send('Ø³Ø¤Ø§Ù„');

    await notifier.configure(
      const StudyAssistantContext(
        subject: 'Ø§Ù„ÙÙŠØ²ÙŠØ§Ø¡',
        lesson: 'Ø§Ù„Ø­Ø±ÙƒØ© Ø§Ù„Ø¯Ø§Ø¦Ø±ÙŠØ©',
        role: KashkoolAiRole.student,
      ),
    );

    final state = container.read(studyAssistantProvider);
    expect(state.context?.lesson, 'Ø§Ù„Ø­Ø±ÙƒØ© Ø§Ù„Ø¯Ø§Ø¦Ø±ÙŠØ©');
    expect(state.messages, isEmpty);
  });

  test('clearConversation empties the thread but keeps the lesson', () async {
    final repository = FakeStudyAssistantRepository();
    final container = _containerWith(repository);
    final notifier = container.read(studyAssistantProvider.notifier);
    await notifier.configure(_context);
    await notifier.send('Ø³Ø¤Ø§Ù„');

    notifier.clearConversation();

    final state = container.read(studyAssistantProvider);
    expect(state.messages, isEmpty);
    expect(state.context, _context);
  });
}

