import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/models/kashkool_models.dart';

class KashkoolAiResponse {
  final String text;
  final CognitiveMeta meta;

  const KashkoolAiResponse({required this.text, required this.meta});
}

class KashkoolAiClient {
  static const List<String> _anxietyKeywords = [
    'خايف',
    'قلقان',
    'مرعوب',
    'متوتر',
    'الامتحان بكره',
    'ليلة الامتحان',
    'anxious',
    'panic',
  ];

  static const List<String> _cheatingPatterns = [
    'أثناء الامتحان',
    'في لجنة الامتحان',
    'غششني',
    'بسرعة قبل المراقب',
    'during the live exam',
    'cheat on exam',
  ];

  static const List<String> _deepKeywords = [
    'برهن',
    'أثبت',
    'اشتق',
    'تكامل',
    'تفاضل',
    'كيرشوف',
    'فيزياء',
    'prove',
    'derive',
    'integral',
  ];

  static EmotionalPulse detectEmotion(String message) {
    final lower = message.toLowerCase();
    if (_anxietyKeywords.any(lower.contains)) return EmotionalPulse.examAnxiety;
    if (lower.contains('تعبان') || lower.contains('مرهق')) {
      return EmotionalPulse.burnout;
    }
    if (lower.contains('زهقت') || lower.contains('مش فاهم')) {
      return EmotionalPulse.frustration;
    }
    if (lower.contains('؟') || lower.contains('?') || lower.contains('ليه')) {
      return EmotionalPulse.curiosity;
    }
    return EmotionalPulse.calm;
  }

  static RoutingLane selectLane(String message, EmotionalPulse emotion) {
    final lower = message.toLowerCase();
    if ((message.length > 140 || _deepKeywords.any(lower.contains)) &&
        emotion != EmotionalPulse.burnout) {
      return RoutingLane.deepCognitiveReasoning;
    }
    return RoutingLane.ultraFastEmpathetic;
  }

  static String sanitizeOutput(String raw) {
    return raw
        .replaceAll(RegExp(r'<think>[\s\S]*?</think>', caseSensitive: false), '')
        .replaceAll(
          RegExp(r'\b(LLM|OpenRouter|Groq|DeepSeek|Kilo|llm7|Pollinations|OpenAI)\b',
              caseSensitive: false),
          'المستشار الأكاديمي',
        )
        .trim();
  }

  static Future<KashkoolAiResponse> chat({
    required String prompt,
    required String subject,
    required AppLanguage language,
  }) async {
    final emotion = detectEmotion(prompt);
    final lane = selectLane(prompt, emotion);
    final isAr = language == AppLanguage.ar;

    final meta = CognitiveMeta(
      emotion: emotion,
      lane: lane,
      strategyAr: emotion == EmotionalPulse.examAnxiety
          ? 'وضع طمأنة قبل الامتحان'
          : 'شرح منظم بالطريقة المصرية',
      strategyEn: emotion == EmotionalPulse.examAnxiety
          ? 'Exam Calm Mode'
          : 'Structured Egyptian Mentor',
    );

    final lower = prompt.toLowerCase();
    if (_cheatingPatterns.any(lower.contains)) {
      return KashkoolAiResponse(
        text: isAr
            ? 'أنا حاسس بتوترك في اللجنة، وعايزلك النجاح من قلبي؛ بس عشان مصلحتك وأمانتك مقدرش أديك إجابات امتحان شغال دلوقتي. خد نفس عميق، ركّز في اللي ذاكرته، وأول ما تخرج هنراجع كل مسألة سوا.'
            : 'I hear how stressful the exam feels, so take a slow breath. I cannot provide live exam answers, but as soon as the exam ends we will master every step together.',
        meta: meta,
      );
    }

    final systemPrompt = isAr
        ? 'أنت المساعد الدراسي الذكي في منصة كشكول بمصر. المادة: $subject. اشرح بلهجة مصرية واضحة وراقية في خطوات مرقمة.'
        : 'You are Kashkool Egyptian study mentor. Subject: $subject. Explain clearly in numbered steps.';

    final endpoints = <Map<String, String>>[
      {
        'url': 'https://ai-gateway.kilo.ai/api/v1/chat/completions',
        'model': 'nvidia/nemotron-3.5-lightning:free',
      },
      {
        'url': 'https://api.llm7.io/v1/chat/completions',
        'model': 'codestral-latest',
      },
    ];

    final started = DateTime.now();
    for (final ep in endpoints) {
      try {
        final resp = await http
            .post(
              Uri.parse(ep['url']!),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                'model': ep['model'],
                'messages': [
                  {'role': 'system', 'content': systemPrompt},
                  {'role': 'user', 'content': prompt},
                ],
                'temperature': 0.55,
                'max_tokens': 1024,
                'stream': false,
              }),
            )
            .timeout(const Duration(seconds: 12));

        if (resp.statusCode >= 200 && resp.statusCode < 300) {
          final decoded = jsonDecode(resp.body) as Map<String, dynamic>;
          final choices = decoded['choices'] as List<dynamic>?;
          final msg = choices?.isNotEmpty == true
              ? (choices!.first as Map<String, dynamic>)['message']
                  as Map<String, dynamic>?
              : null;
          final content = sanitizeOutput((msg?['content'] as String?) ?? '');
          if (content.isNotEmpty) {
            return KashkoolAiResponse(
              text: content,
              meta: CognitiveMeta(
                emotion: meta.emotion,
                lane: meta.lane,
                strategyAr: meta.strategyAr,
                strategyEn: meta.strategyEn,
                ttftMs: DateTime.now().difference(started).inMilliseconds,
              ),
            );
          }
        }
      } catch (_) {
        // Failover to next provider
      }
    }

    return KashkoolAiResponse(
      text: isAr
          ? 'أنا معاك خطوة بخطوة: قسّم المسألة لمعطيات ومطلوب، واكتب القانون الأساسي الأول وبعدين عوض بالأرقام بالراحة.'
          : 'Step by step: list your givens, write the core formula first, then substitute values carefully.',
      meta: meta,
    );
  }
}
