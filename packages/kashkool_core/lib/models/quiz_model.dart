import '../enums/platform_enums.dart';

/// Question Bank items (LaTeX/Image/MCQ/Essay) & Quiz attempts.

class QuizModel {
  final String quizId;
  final String title;
  final String description;
  final List<QuestionItem> questions;
  final int timeLimitMinutes;
  final QuestionDifficulty difficulty;

  const QuizModel({
    required this.quizId,
    required this.title,
    required this.description,
    required this.questions,
    required this.timeLimitMinutes,
    required this.difficulty,
  });
}

class QuestionItem {
  final String id;
  final String text;
  final List<String> options;
  final int correctIndex;

  const QuestionItem({
    required this.id,
    required this.text,
    required this.options,
    required this.correctIndex,
  });
}
