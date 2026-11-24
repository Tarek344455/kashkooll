import 'package:drift/drift.dart';

class SyncQueueTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get collectionName => text()();
  TextColumn get documentId => text()();
  TextColumn get operation => text()(); // create / update / delete
  TextColumn get dataJson => text()();
  IntColumn get priority => integer()(); // 0 critical, 1 high, 2 normal
  TextColumn get status => text()(); // pending / processing / completed / failed
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
}
