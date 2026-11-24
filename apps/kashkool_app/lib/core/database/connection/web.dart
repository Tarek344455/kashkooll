import 'package:drift/drift.dart';
import 'package:drift/wasm.dart';

/// Opens drift's browser database backed by the bundled SQLite WASM build.
///
/// [sqlite3.wasm] and [drift_worker.js] live in `web/` and are copied into the
/// build output by the Flutter web tool.
QueryExecutor openConnection() {
  return LazyDatabase(() async {
    final result = await WasmDatabase.open(
      databaseName: 'kashkool',
      sqlite3Uri: Uri.parse('sqlite3.wasm'),
      driftWorkerUri: Uri.parse('drift_worker.js'),
    );
    return result.resolvedExecutor;
  });
}
