import 'package:drift/drift.dart';

/// Stub connection function that throws an error on unsupported platforms.
QueryExecutor connect({bool inMemory = false}) {
  throw UnsupportedError(
    'Cannot create a database connection on this platform without a specific implementation.',
  );
}
