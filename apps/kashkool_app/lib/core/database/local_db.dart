import 'package:drift/drift.dart';
import 'connection/connection.dart';
import 'tables/local_students.dart';
import 'tables/local_sessions.dart';
import 'tables/local_attendance.dart';
import 'tables/local_transactions.dart';
import 'tables/local_quizzes.dart';
import 'tables/local_payment_submissions.dart';
import 'tables/sync_queue_table.dart';

part 'local_db.g.dart';

@DriftDatabase(tables: [
  LocalStudents,
  LocalSessions,
  LocalAttendance,
  LocalTransactions,
  LocalQuizzes,
  LocalPaymentSubmissions,
  SyncQueueTable,
])
class LocalDb extends _$LocalDb {
  LocalDb() : super(openConnection());

  /// In-memory / injected executor used by unit tests.
  LocalDb.forTesting(super.executor);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.database.customStatement('''
              CREATE TABLE IF NOT EXISTS local_payment_submissions (
                submission_id TEXT NOT NULL PRIMARY KEY,
                tenant_id TEXT NOT NULL,
                student_id TEXT NOT NULL,
                channel_id TEXT NOT NULL,
                amount_piasters INTEGER NOT NULL,
                sender_reference TEXT NOT NULL,
                receipt_url TEXT NOT NULL,
                status TEXT NOT NULL,
                sync_status TEXT NOT NULL,
                created_at INTEGER NOT NULL
              );
            ''');
          }
        },
      );

  // Students
  Future<List<LocalStudent>> getAllStudents() =>
      select(localStudents).get();

  /// Live roster for the cash desk: emits whenever a student is added.
  Stream<List<LocalStudent>> watchStudents() =>
      select(localStudents).watch();

  Future<void> upsertStudent(LocalStudentsCompanion student) =>
      into(localStudents).insertOnConflictUpdate(student);

  // Sessions
  Future<List<LocalSession>> getAllSessions() =>
      select(localSessions).get();

  Future<void> upsertSession(LocalSessionsCompanion session) =>
      into(localSessions).insertOnConflictUpdate(session);

  // Attendance
  Future<List<LocalAttendanceData>> getPendingAttendance() =>
      (select(localAttendance)
            ..where((t) => t.syncStatus.equals('pending')))
          .get();

  static const _completedStatus = Value('completed');

  Future<void> markAttendanceSynced(int id) =>
      (update(localAttendance)..where((t) => t.id.equals(id))).write(
        const LocalAttendanceCompanion(syncStatus: _completedStatus),
      );

  Future<List<LocalAttendanceData>> getAttendanceForSession(String sessionId) =>
      (select(localAttendance)
            ..where((t) => t.sessionId.equals(sessionId)))
        .get();

  /// Records a scan. Stays `pending` until the sync engine uploads it.
  Future<int> insertAttendance(LocalAttendanceCompanion entry) =>
      into(localAttendance).insert(entry);

  /// Undoes a mis-scan before the batch is printed.
  Future<void> deleteAttendance(String studentId, String sessionId) =>
      (delete(localAttendance)
            ..where((t) =>
                t.studentId.equals(studentId) & t.sessionId.equals(sessionId)))
          .go();

  // Transactions
  Future<List<LocalTransaction>> getPendingTransactions() =>
      (select(localTransactions)
            ..where((t) => t.syncStatus.equals('pending')))
          .get();

  /// Records a cash-desk top-up. Stays `pending` until synced.
  Future<void> insertTransaction(LocalTransactionsCompanion entry) =>
      into(localTransactions).insert(entry);

  /// All transactions (used by dashboard revenue calculation).
  Future<List<LocalTransaction>> getAllTransactions() =>
      select(localTransactions).get();

  // Quizzes
  Future<List<LocalQuiz>> getAllQuizzes() =>
      select(localQuizzes).get();

  // Payment submissions (offline cache)
  Future<List<LocalPaymentSubmission>> getAllPaymentSubmissions() =>
      select(localPaymentSubmissions).get();

  Future<List<LocalPaymentSubmission>> getPendingPaymentSubmissions() =>
      (select(localPaymentSubmissions)
            ..where((t) => t.syncStatus.equals('pending')))
          .get();

  Stream<List<LocalPaymentSubmission>> watchAllPaymentSubmissions() =>
      select(localPaymentSubmissions).watch();

  Future<void> insertPaymentSubmission(
      LocalPaymentSubmissionsCompanion entry) =>
      into(localPaymentSubmissions).insert(entry);

  Future<void> updatePaymentSubmissionStatus(
    String submissionId,
    String status, {
    String? syncStatus,
  }) =>
      (update(localPaymentSubmissions)
            ..where((t) => t.submissionId.equals(submissionId)))
          .write(LocalPaymentSubmissionsCompanion(
            status: Value(status),
            syncStatus: Value(syncStatus ?? 'completed'),
          ));

  // Sync Queue
  Future<List<SyncQueueTableData>> getSyncQueueOrdered() =>
      (select(syncQueueTable)
            ..orderBy([(t) => OrderingTerm(expression: t.priority)]))
          .get();

  Future<void> upsertSyncQueueItem(SyncQueueTableCompanion item) =>
      into(syncQueueTable).insert(item);
}
