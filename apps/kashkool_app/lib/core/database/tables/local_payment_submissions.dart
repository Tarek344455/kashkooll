import 'package:drift/drift.dart';

/// Local (offline-first) cache of payment receipt submissions.
///
/// Mirrors `public.payment_submissions` from Supabase so the student tracking
/// screen reads from the Drift cache first and stays responsive on flaky
/// mobile data. Rows stay `syncStatus = 'pending'` until the sync engine pushes
/// them to the server; status flips (`approved` / `rejected`) happen through the
/// same immutable-ledger flow.
class LocalPaymentSubmissions extends Table {
  TextColumn get submissionId => text()();
  TextColumn get tenantId => text()();
  TextColumn get studentId => text()();
  TextColumn get channelId => text()();
  IntColumn get amountPiasters => integer()();
  TextColumn get senderReference => text()();
  TextColumn get receiptUrl => text()();
  TextColumn get status => text()();
  TextColumn get syncStatus => text()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {submissionId};
}
