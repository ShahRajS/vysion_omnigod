import 'package:drift/drift.dart';
import 'package:drift/wasm.dart';

/// Opens a connection to the WebAssembly SQLite database.
/// If WASM worker files are unavailable (e.g. `flutter run` in dev without
/// a production build), silently falls back to a no-op executor so the app
/// keeps running without crashing. History won't persist between sessions,
/// but every other feature (OCR, TTS, camera) continues to work.
QueryExecutor connect({bool inMemory = false}) {
  return LazyDatabase(() async {
    try {
      final result = await WasmDatabase.open(
        databaseName: inMemory ? 'vysion_in_memory' : 'vysion_db',
        sqlite3Uri: Uri.parse('sqlite3.wasm'),
        driftWorkerUri: Uri.parse('drift_worker.js'),
      ).timeout(const Duration(seconds: 2));
      return result.resolvedExecutor;
    } catch (_) {
      // WASM worker / sqlite3.wasm not available in this environment.
      // Return a no-op executor — data is transient but the app runs fine.
      return _NoOpExecutor();
    }
  });
}

/// A no-op [QueryExecutor] used as fallback when WASM is unavailable on web.
/// All reads return empty, all writes are silently discarded.
class _NoOpExecutor extends QueryExecutor {
  bool _opened = false;

  @override
  SqlDialect get dialect => SqlDialect.sqlite;

  @override
  Future<bool> ensureOpen(QueryExecutorUser user) async {
    if (!_opened) {
      _opened = true;
      // OpeningDetails(versionBefore, versionNow) — null means first open.
      await user.beforeOpen(this, const OpeningDetails(null, 1));
    }
    return true;
  }

  @override
  Future<List<Map<String, Object?>>> runSelect(
    String statement,
    List<Object?> args,
  ) async =>
      [];

  @override
  Future<int> runInsert(String statement, List<Object?> args) async => 0;

  @override
  Future<int> runUpdate(String statement, List<Object?> args) async => 0;

  @override
  Future<int> runDelete(String statement, List<Object?> args) async => 0;

  @override
  Future<void> runCustom(String statement, [List<Object?>? args]) async {}

  @override
  Future<void> runBatched(BatchedStatements statements) async {}

  @override
  TransactionExecutor beginTransaction() => _NoOpTransaction();

  @override
  QueryExecutor beginExclusive() => this;

  @override
  Future<void> close() async {}
}

/// A no-op [TransactionExecutor] that pairs with [_NoOpExecutor].
class _NoOpTransaction extends _NoOpExecutor
    implements TransactionExecutor {
  _NoOpTransaction();

  @override
  bool get supportsNestedTransactions => false;

  @override
  Future<void> send() async {}

  @override
  Future<void> rollback() async {}
}
