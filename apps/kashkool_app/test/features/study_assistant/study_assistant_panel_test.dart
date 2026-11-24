import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kashkool_app/core/services/spaceship_ai_client.dart';
import 'package:kashkool_app/features/study_assistant/presentation/study_assistant_panel.dart';
import 'package:kashkool_app/features/study_assistant/providers/study_assistant_controller.dart';

import 'fake_study_assistant_repository.dart';

Widget host(FakeStudyAssistantRepository repository) {
  return ProviderScope(
    overrides: [studyAssistantRepositoryProvider.overrideWithValue(repository)],
    child: const MaterialApp(
      home: Scaffold(
        body: SizedBox(
          height: 720,
          width: 400,
          child: StudyAssistantPanel(
            subject: 'الرياضيات',
            lesson: 'التكامل بالتجزئة',
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('empty state offers a real starting action', (tester) async {
    await tester.pumpWidget(host(FakeStudyAssistantRepository()));
    await tester.pump();
    await tester.pump();

    expect(find.text('جاهز نبدأ الدرس'), findsOneWidget);
    expect(find.text('ابدأ الشرح'), findsOneWidget);
  });

  testWidgets('tapping the start action renders the answer', (tester) async {
    final repository = FakeStudyAssistantRepository(
      reply: (_) => const AssistantReply(
        text: 'ما المعطيات في المسألة؟',
        suggestions: ['أعطني تلميح'],
      ),
    );
    await tester.pumpWidget(host(repository));
    await tester.pump();
    await tester.pump();

    await tester.tap(find.text('ابدأ الشرح'));
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    expect(find.text('ما المعطيات في المسألة؟'), findsOneWidget);
    expect(find.text('أعطني تلميح'), findsOneWidget);
    expect(repository.calls, hasLength(1));
    expect(repository.contexts.single.lesson, 'التكامل بالتجزئة');
  });

  testWidgets('a failed turn shows the error and a retry button',
      (tester) async {
    final repository = FakeStudyAssistantRepository(
      failure: const AssistantException(AssistantFailure.timeout, 'timeout'),
    );
    await tester.pumpWidget(host(repository));
    await tester.pump();
    await tester.pump();

    await tester.tap(find.text('ابدأ الشرح'));
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    expect(find.text('إعادة المحاولة'), findsOneWidget);
    expect(find.textContaining('أعد المحاولة بعد لحظات'), findsOneWidget);

    repository.failure = null;
    await tester.tap(find.text('إعادة المحاولة'));
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    expect(find.text('رد المساعد'), findsOneWidget);
    expect(find.text('إعادة المحاولة'), findsNothing);
  });

  testWidgets('an offline gateway blocks the empty state with an error',
      (tester) async {
    await tester.pumpWidget(
      host(FakeStudyAssistantRepository(available: false)),
    );
    await tester.pump();
    await tester.pump();

    expect(find.textContaining('تعذّر الوصول'), findsOneWidget);
    expect(find.text('إعادة المحاولة'), findsOneWidget);
    expect(find.text('ابدأ الشرح'), findsNothing);
  });
}
