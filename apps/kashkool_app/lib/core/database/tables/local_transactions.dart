import 'package:drift/drift.dart';

class LocalTransactions extends Table {
  TextColumn get transactionId => text()();
  TextColumn get userId => text()();
  RealColumn get amount => real()();
  TextColumn get channel => text()(); // cashToWallet / fawry / vodafoneCash / instaPay
  DateTimeColumn get timestamp => dateTime()();
  TextColumn get description => text()();
  TextColumn get syncStatus => text()();

  @override
  Set<Column> get primaryKey => {transactionId};
}
