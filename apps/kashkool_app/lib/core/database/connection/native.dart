import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';

/// Opens the on-device SQLite database inside the app documents directory.
///
/// Resolving the directory matters: a relative path would target the process
/// working directory (read-only on Android) and crash the first query.
QueryExecutor openConnection() {
  return LazyDatabase(() async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}${Platform.pathSeparator}kashkool.sqlite');
    return NativeDatabase(file);
  });
}
