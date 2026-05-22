import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vysion_omnigod/core/storage/connection/connection.dart' as impl;

part 'database.g.dart';

/// Table storing local OCR recognition history.
class OcrHistory extends Table {
  /// Unique identifier.
  IntColumn get id => integer().autoIncrement()();

  /// Extracted text.
  TextColumn get rawText => text().named('text')();

  /// Date and time when the OCR was run.
  DateTimeColumn get createdAt => dateTime()();
}

/// Table storing local Gemini scene descriptions.
class DescriptionHistory extends Table {
  /// Unique identifier.
  IntColumn get id => integer().autoIncrement()();

  /// Scene description text.
  TextColumn get description => text()();

  /// Date and time when the description was generated.
  DateTimeColumn get createdAt => dateTime()();
}

/// Table storing saved navigation destinations.
class Destinations extends Table {
  /// Unique identifier.
  IntColumn get id => integer().autoIncrement()();

  /// Name or query of the destination.
  TextColumn get name => text()();

  /// Latitude of the target location.
  RealColumn get latitude => real()();

  /// Longitude of the target location.
  RealColumn get longitude => real()();

  /// Date and time when the destination was saved/visited.
  DateTimeColumn get createdAt => dateTime()();
}

/// The Drift database configuration for local app storage.
@DriftDatabase(tables: [OcrHistory, DescriptionHistory, Destinations])
class AppDatabase extends _$AppDatabase {
  /// Creates the Drift database instance.
  AppDatabase() : super(impl.connect());

  /// Open database connection in memory.
  AppDatabase.inMemory() : super(impl.connect(inMemory: true));

  @override
  int get schemaVersion => 1;
}

/// Provider for the single AppDatabase instance across the application.
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() async {
    await db.close();
  });
  return db;
});
