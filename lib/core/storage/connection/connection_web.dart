import 'package:drift/drift.dart';
import 'package:drift/wasm.dart';

/// Opens a connection to the WebAssembly SQLite database.
QueryExecutor connect({bool inMemory = false}) {
  return LazyDatabase(() async {
    try {
      final db = await WasmDatabase.open(
        databaseName: inMemory ? 'vysion_in_memory' : 'vysion_db',
        sqlite3Uri: Uri.parse('sqlite3.wasm'),
        driftWorkerUri: Uri.parse('drift_worker.js'),
      ).timeout(const Duration(seconds: 2));
      return db.resolvedExecutor;
    } catch (e) {
      throw UnsupportedError(
        'Drift WASM database failed to initialize. '
        'Verify that sqlite3.wasm and drift_worker.js are placed in the web directory. '
        'Error: $e',
      );
    }
  });
}
