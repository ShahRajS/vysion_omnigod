import 'package:drift/drift.dart';
import 'package:drift/wasm.dart';

/// Opens a connection to the WebAssembly SQLite database.
QueryExecutor connect({bool inMemory = false}) {
  return LazyDatabase(() async {
    final db = await WasmDatabase.open(
      databaseName: inMemory ? 'vysion_in_memory' : 'vysion_db',
      sqlite3Uri: Uri.parse('sqlite3.wasm'),
      driftWorkerUri: Uri.parse('drift_worker.js'),
    );
    return db.resolvedExecutor;
  });
}
