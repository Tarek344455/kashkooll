import 'package:drift/drift.dart';

class LocalSessions extends Table {
  TextColumn get sessionId => text()();
  TextColumn get tenantId => text()();
  TextColumn get groupId => text()();
  TextColumn get title => text()();
  TextColumn get type => text()(); // offline / online
  DateTimeColumn get startTime => dateTime()();
  TextColumn get qrSecret => text()();
  DateTimeColumn get syncedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {sessionId};
}
