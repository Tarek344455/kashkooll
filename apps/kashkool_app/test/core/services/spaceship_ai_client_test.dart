import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kashkool_app/core/network/network_client.dart';
import 'package:kashkool_app/core/services/spaceship_ai_client.dart';

SpaceshipAiClient clientFor(MockClient mock) {
  return SpaceshipAiClient(NetworkClient(httpClient: mock));
}

http.Response completion(String content) {
  return http.Response(
    jsonEncode({
      'choices': [
        {
          'message': {'role': 'assistant', 'content': content},
          'finish_reason': 'stop',
        },
      ],
    }),
    200,
    headers: {'content-type': 'application/json; charset=utf-8'},
  );
}

void main() {
  group('SpaceshipAiClient.chat', () {
    test('returns the answer and splits model-generated follow-ups', () async {
      final client = clientFor(MockClient((_) async => completion(
            'خطوة أولى: ما المعطيات في المسألة؟\n'
            '[[SUGGESTIONS]] أعطني تلميح | راجع القانون معايا',
          )));

      final reply = await client.chat(
        role: KashkoolAiRole.student,
        turns: const [AssistantTurn.learner('ابدأ الدرس')],
      );

      expect(reply.text, 'خطوة أولى: ما المعطيات في المسألة؟');
      expect(reply.text, isNot(contains('[[SUGGESTIONS]]')));
      expect(reply.suggestions, ['أعطني تلميح', 'راجع القانون معايا']);
      expect(reply.isUsable, isTrue);
    });

    test('sends the whole history in order with the savior model', () async {
      late Map<String, dynamic> sent;
      final client = clientFor(MockClient((request) async {
        sent = jsonDecode(request.body) as Map<String, dynamic>;
        return completion('answer');
      }));

      await client.chat(
        role: KashkoolAiRole.teacher,
        subject: 'الفيزياء',
        grade: 'الثالث الثانوي',
        turns: const [
          AssistantTurn.learner('سؤال أول'),
          AssistantTurn.assistant('رد أول'),
          AssistantTurn.learner('سؤال ثاني'),
        ],
      );

      expect(sent['model'], 'kashkool-savior');
      final messages = (sent['messages'] as List).cast<Map<String, dynamic>>();
      expect(messages.first['role'], 'system');
      expect(messages.first['content'], contains('الفيزياء'));
      expect(messages.skip(1).map((m) => m['role']).toList(),
          ['user', 'assistant', 'user']);
      expect(messages.skip(1).map((m) => m['content']).toList(),
          ['سؤال أول', 'رد أول', 'سؤال ثاني']);
    });

    test('keeps only the most recent turns to bound the context', () async {
      late Map<String, dynamic> sent;
      final client = clientFor(MockClient((request) async {
        sent = jsonDecode(request.body) as Map<String, dynamic>;
        return completion('answer');
      }));

      final turns = [
        for (var i = 0; i < SpaceshipAiClient.maxContextTurns + 6; i++)
          AssistantTurn.learner('سؤال $i'),
      ];
      await client.chat(role: KashkoolAiRole.student, turns: turns);

      final messages = (sent['messages'] as List).cast<Map<String, dynamic>>();
      expect(messages.length, SpaceshipAiClient.maxContextTurns + 1);
      expect(messages.last['content'],
          'سؤال ${SpaceshipAiClient.maxContextTurns + 5}');
    });

    test('throws a typed failure instead of inventing an answer', () async {
      final client = clientFor(
        MockClient((_) async => http.Response('{"error":"boom"}', 503)),
      );

      await expectLater(
        client.chat(
          role: KashkoolAiRole.godMode,
          turns: const [AssistantTurn.learner('كم إجمالي التحصيل اليوم؟')],
        ),
        throwsA(
          isA<AssistantException>()
              .having((e) => e.failure, 'failure', AssistantFailure.rejected)
              .having((e) => e.userMessage, 'userMessage', isNotEmpty),
        ),
      );
    });

    test('reports an unreachable gateway on transport failure', () async {
      final client = clientFor(MockClient((_) async {
        throw http.ClientException('connection refused');
      }));

      await expectLater(
        client.chat(
          role: KashkoolAiRole.student,
          turns: const [AssistantTurn.learner('سؤال')],
        ),
        throwsA(isA<AssistantException>().having(
          (e) => e.failure,
          'failure',
          AssistantFailure.unreachable,
        )),
      );
    });

    test('rejects a 200 response without a usable completion', () async {
      final client = clientFor(
        MockClient((_) async => http.Response('{"choices":[]}', 200)),
      );

      await expectLater(
        client.chat(
          role: KashkoolAiRole.student,
          turns: const [AssistantTurn.learner('سؤال')],
        ),
        throwsA(isA<AssistantException>().having(
          (e) => e.failure,
          'failure',
          AssistantFailure.invalidResponse,
        )),
      );
    });

    test('refuses an empty conversation without calling the gateway', () async {
      var called = false;
      final client = clientFor(MockClient((_) async {
        called = true;
        return completion('answer');
      }));

      await expectLater(
        client.chat(role: KashkoolAiRole.student, turns: const []),
        throwsA(isA<AssistantException>()),
      );
      expect(called, isFalse);
    });
  });

  group('SpaceshipAiClient.checkAvailability', () {
    test('is true for a healthy gateway', () async {
      final client = clientFor(
        MockClient((_) async => http.Response('{"status":"ok"}', 200)),
      );
      expect(await client.checkAvailability(), isTrue);
    });

    test('is false when the gateway answers with an error', () async {
      final client = clientFor(
        MockClient((_) async => http.Response('{"status":"down"}', 503)),
      );
      expect(await client.checkAvailability(), isFalse);
    });

    test('is false when the gateway is unreachable', () async {
      final client = clientFor(MockClient((_) async {
        throw http.ClientException('offline');
      }));
      expect(await client.checkAvailability(), isFalse);
    });
  });
}
