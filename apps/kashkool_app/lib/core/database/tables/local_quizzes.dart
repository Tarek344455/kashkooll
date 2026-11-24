import 'package:drift/drift.dart';

/// Drift singularises `LocalQuizzes` to the awkward `LocalQuizze`; pin the
/// row class name explicitly so the rest of the code reads `LocalQuiz`.
@DataClassName('LocalQuiz')
class LocalQuizzes extends Table {
  TextColumn get quizId => text()();
  TextColumn get title => text()();
  TextColumn get tenantId => text()();
  IntColumn get timeLimitMinutes => integer()();
  TextColumn get difficulty => text()();
  DateTimeColumn get createdAt => dateTime()();
  TextColumn get syncStatus => text()();

  @override
  Set<Column> get primaryKey => {quizId};
}
