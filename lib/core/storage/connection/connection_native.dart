import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Opens a connection to the native SQLite database.
QueryExecutor connect({bool inMemory = false}) {
  if (inMemory) {
    return NativeDatabase.memory();
  }
  return LazyDatabase(() async {
    final dbDir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbDir.path, 'vysion.db'));
    return NativeDatabase(file);
  });
}
