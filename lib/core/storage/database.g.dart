// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $OcrHistoryTable extends OcrHistory
    with TableInfo<$OcrHistoryTable, OcrHistoryData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OcrHistoryTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _rawTextMeta =
      const VerificationMeta('rawText');
  @override
  late final GeneratedColumn<String> rawText = GeneratedColumn<String>(
      'text', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [id, rawText, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ocr_history';
  @override
  VerificationContext validateIntegrity(Insertable<OcrHistoryData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('text')) {
      context.handle(_rawTextMeta,
          rawText.isAcceptableOrUnknown(data['text']!, _rawTextMeta));
    } else if (isInserting) {
      context.missing(_rawTextMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  OcrHistoryData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OcrHistoryData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      rawText: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}text'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $OcrHistoryTable createAlias(String alias) {
    return $OcrHistoryTable(attachedDatabase, alias);
  }
}

class OcrHistoryData extends DataClass implements Insertable<OcrHistoryData> {
  /// Unique identifier.
  final int id;

  /// Extracted text.
  final String rawText;

  /// Date and time when the OCR was run.
  final DateTime createdAt;
  const OcrHistoryData(
      {required this.id, required this.rawText, required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['text'] = Variable<String>(rawText);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  OcrHistoryCompanion toCompanion(bool nullToAbsent) {
    return OcrHistoryCompanion(
      id: Value(id),
      rawText: Value(rawText),
      createdAt: Value(createdAt),
    );
  }

  factory OcrHistoryData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OcrHistoryData(
      id: serializer.fromJson<int>(json['id']),
      rawText: serializer.fromJson<String>(json['rawText']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'rawText': serializer.toJson<String>(rawText),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  OcrHistoryData copyWith({int? id, String? rawText, DateTime? createdAt}) =>
      OcrHistoryData(
        id: id ?? this.id,
        rawText: rawText ?? this.rawText,
        createdAt: createdAt ?? this.createdAt,
      );
  OcrHistoryData copyWithCompanion(OcrHistoryCompanion data) {
    return OcrHistoryData(
      id: data.id.present ? data.id.value : this.id,
      rawText: data.rawText.present ? data.rawText.value : this.rawText,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OcrHistoryData(')
          ..write('id: $id, ')
          ..write('rawText: $rawText, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, rawText, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OcrHistoryData &&
          other.id == this.id &&
          other.rawText == this.rawText &&
          other.createdAt == this.createdAt);
}

class OcrHistoryCompanion extends UpdateCompanion<OcrHistoryData> {
  final Value<int> id;
  final Value<String> rawText;
  final Value<DateTime> createdAt;
  const OcrHistoryCompanion({
    this.id = const Value.absent(),
    this.rawText = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  OcrHistoryCompanion.insert({
    this.id = const Value.absent(),
    required String rawText,
    required DateTime createdAt,
  })  : rawText = Value(rawText),
        createdAt = Value(createdAt);
  static Insertable<OcrHistoryData> custom({
    Expression<int>? id,
    Expression<String>? rawText,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (rawText != null) 'text': rawText,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  OcrHistoryCompanion copyWith(
      {Value<int>? id, Value<String>? rawText, Value<DateTime>? createdAt}) {
    return OcrHistoryCompanion(
      id: id ?? this.id,
      rawText: rawText ?? this.rawText,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (rawText.present) {
      map['text'] = Variable<String>(rawText.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OcrHistoryCompanion(')
          ..write('id: $id, ')
          ..write('rawText: $rawText, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $DescriptionHistoryTable extends DescriptionHistory
    with TableInfo<$DescriptionHistoryTable, DescriptionHistoryData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DescriptionHistoryTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
      'description', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [id, description, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'description_history';
  @override
  VerificationContext validateIntegrity(
      Insertable<DescriptionHistoryData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['description']!, _descriptionMeta));
    } else if (isInserting) {
      context.missing(_descriptionMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DescriptionHistoryData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DescriptionHistoryData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      description: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}description'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $DescriptionHistoryTable createAlias(String alias) {
    return $DescriptionHistoryTable(attachedDatabase, alias);
  }
}

class DescriptionHistoryData extends DataClass
    implements Insertable<DescriptionHistoryData> {
  /// Unique identifier.
  final int id;

  /// Scene description text.
  final String description;

  /// Date and time when the description was generated.
  final DateTime createdAt;
  const DescriptionHistoryData(
      {required this.id, required this.description, required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['description'] = Variable<String>(description);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  DescriptionHistoryCompanion toCompanion(bool nullToAbsent) {
    return DescriptionHistoryCompanion(
      id: Value(id),
      description: Value(description),
      createdAt: Value(createdAt),
    );
  }

  factory DescriptionHistoryData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DescriptionHistoryData(
      id: serializer.fromJson<int>(json['id']),
      description: serializer.fromJson<String>(json['description']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'description': serializer.toJson<String>(description),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  DescriptionHistoryData copyWith(
          {int? id, String? description, DateTime? createdAt}) =>
      DescriptionHistoryData(
        id: id ?? this.id,
        description: description ?? this.description,
        createdAt: createdAt ?? this.createdAt,
      );
  DescriptionHistoryData copyWithCompanion(DescriptionHistoryCompanion data) {
    return DescriptionHistoryData(
      id: data.id.present ? data.id.value : this.id,
      description:
          data.description.present ? data.description.value : this.description,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DescriptionHistoryData(')
          ..write('id: $id, ')
          ..write('description: $description, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, description, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DescriptionHistoryData &&
          other.id == this.id &&
          other.description == this.description &&
          other.createdAt == this.createdAt);
}

class DescriptionHistoryCompanion
    extends UpdateCompanion<DescriptionHistoryData> {
  final Value<int> id;
  final Value<String> description;
  final Value<DateTime> createdAt;
  const DescriptionHistoryCompanion({
    this.id = const Value.absent(),
    this.description = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  DescriptionHistoryCompanion.insert({
    this.id = const Value.absent(),
    required String description,
    required DateTime createdAt,
  })  : description = Value(description),
        createdAt = Value(createdAt);
  static Insertable<DescriptionHistoryData> custom({
    Expression<int>? id,
    Expression<String>? description,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (description != null) 'description': description,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  DescriptionHistoryCompanion copyWith(
      {Value<int>? id,
      Value<String>? description,
      Value<DateTime>? createdAt}) {
    return DescriptionHistoryCompanion(
      id: id ?? this.id,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DescriptionHistoryCompanion(')
          ..write('id: $id, ')
          ..write('description: $description, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $DestinationsTable extends Destinations
    with TableInfo<$DestinationsTable, Destination> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DestinationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _latitudeMeta =
      const VerificationMeta('latitude');
  @override
  late final GeneratedColumn<double> latitude = GeneratedColumn<double>(
      'latitude', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _longitudeMeta =
      const VerificationMeta('longitude');
  @override
  late final GeneratedColumn<double> longitude = GeneratedColumn<double>(
      'longitude', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, name, latitude, longitude, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'destinations';
  @override
  VerificationContext validateIntegrity(Insertable<Destination> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('latitude')) {
      context.handle(_latitudeMeta,
          latitude.isAcceptableOrUnknown(data['latitude']!, _latitudeMeta));
    } else if (isInserting) {
      context.missing(_latitudeMeta);
    }
    if (data.containsKey('longitude')) {
      context.handle(_longitudeMeta,
          longitude.isAcceptableOrUnknown(data['longitude']!, _longitudeMeta));
    } else if (isInserting) {
      context.missing(_longitudeMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Destination map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Destination(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      latitude: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}latitude'])!,
      longitude: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}longitude'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $DestinationsTable createAlias(String alias) {
    return $DestinationsTable(attachedDatabase, alias);
  }
}

class Destination extends DataClass implements Insertable<Destination> {
  /// Unique identifier.
  final int id;

  /// Name or query of the destination.
  final String name;

  /// Latitude of the target location.
  final double latitude;

  /// Longitude of the target location.
  final double longitude;

  /// Date and time when the destination was saved/visited.
  final DateTime createdAt;
  const Destination(
      {required this.id,
      required this.name,
      required this.latitude,
      required this.longitude,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['latitude'] = Variable<double>(latitude);
    map['longitude'] = Variable<double>(longitude);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  DestinationsCompanion toCompanion(bool nullToAbsent) {
    return DestinationsCompanion(
      id: Value(id),
      name: Value(name),
      latitude: Value(latitude),
      longitude: Value(longitude),
      createdAt: Value(createdAt),
    );
  }

  factory Destination.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Destination(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      latitude: serializer.fromJson<double>(json['latitude']),
      longitude: serializer.fromJson<double>(json['longitude']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'latitude': serializer.toJson<double>(latitude),
      'longitude': serializer.toJson<double>(longitude),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Destination copyWith(
          {int? id,
          String? name,
          double? latitude,
          double? longitude,
          DateTime? createdAt}) =>
      Destination(
        id: id ?? this.id,
        name: name ?? this.name,
        latitude: latitude ?? this.latitude,
        longitude: longitude ?? this.longitude,
        createdAt: createdAt ?? this.createdAt,
      );
  Destination copyWithCompanion(DestinationsCompanion data) {
    return Destination(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      latitude: data.latitude.present ? data.latitude.value : this.latitude,
      longitude: data.longitude.present ? data.longitude.value : this.longitude,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Destination(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, latitude, longitude, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Destination &&
          other.id == this.id &&
          other.name == this.name &&
          other.latitude == this.latitude &&
          other.longitude == this.longitude &&
          other.createdAt == this.createdAt);
}

class DestinationsCompanion extends UpdateCompanion<Destination> {
  final Value<int> id;
  final Value<String> name;
  final Value<double> latitude;
  final Value<double> longitude;
  final Value<DateTime> createdAt;
  const DestinationsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  DestinationsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required double latitude,
    required double longitude,
    required DateTime createdAt,
  })  : name = Value(name),
        latitude = Value(latitude),
        longitude = Value(longitude),
        createdAt = Value(createdAt);
  static Insertable<Destination> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<double>? latitude,
    Expression<double>? longitude,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  DestinationsCompanion copyWith(
      {Value<int>? id,
      Value<String>? name,
      Value<double>? latitude,
      Value<double>? longitude,
      Value<DateTime>? createdAt}) {
    return DestinationsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (latitude.present) {
      map['latitude'] = Variable<double>(latitude.value);
    }
    if (longitude.present) {
      map['longitude'] = Variable<double>(longitude.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DestinationsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $OcrHistoryTable ocrHistory = $OcrHistoryTable(this);
  late final $DescriptionHistoryTable descriptionHistory =
      $DescriptionHistoryTable(this);
  late final $DestinationsTable destinations = $DestinationsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities =>
      [ocrHistory, descriptionHistory, destinations];
}

typedef $$OcrHistoryTableCreateCompanionBuilder = OcrHistoryCompanion Function({
  Value<int> id,
  required String rawText,
  required DateTime createdAt,
});
typedef $$OcrHistoryTableUpdateCompanionBuilder = OcrHistoryCompanion Function({
  Value<int> id,
  Value<String> rawText,
  Value<DateTime> createdAt,
});

class $$OcrHistoryTableTableManager extends RootTableManager<
    _$AppDatabase,
    $OcrHistoryTable,
    OcrHistoryData,
    $$OcrHistoryTableFilterComposer,
    $$OcrHistoryTableOrderingComposer,
    $$OcrHistoryTableCreateCompanionBuilder,
    $$OcrHistoryTableUpdateCompanionBuilder> {
  $$OcrHistoryTableTableManager(_$AppDatabase db, $OcrHistoryTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$OcrHistoryTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$OcrHistoryTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> rawText = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              OcrHistoryCompanion(
            id: id,
            rawText: rawText,
            createdAt: createdAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String rawText,
            required DateTime createdAt,
          }) =>
              OcrHistoryCompanion.insert(
            id: id,
            rawText: rawText,
            createdAt: createdAt,
          ),
        ));
}

class $$OcrHistoryTableFilterComposer
    extends FilterComposer<_$AppDatabase, $OcrHistoryTable> {
  $$OcrHistoryTableFilterComposer(super.$state);
  ColumnFilters<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get rawText => $state.composableBuilder(
      column: $state.table.rawText,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));
}

class $$OcrHistoryTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $OcrHistoryTable> {
  $$OcrHistoryTableOrderingComposer(super.$state);
  ColumnOrderings<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get rawText => $state.composableBuilder(
      column: $state.table.rawText,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

typedef $$DescriptionHistoryTableCreateCompanionBuilder
    = DescriptionHistoryCompanion Function({
  Value<int> id,
  required String description,
  required DateTime createdAt,
});
typedef $$DescriptionHistoryTableUpdateCompanionBuilder
    = DescriptionHistoryCompanion Function({
  Value<int> id,
  Value<String> description,
  Value<DateTime> createdAt,
});

class $$DescriptionHistoryTableTableManager extends RootTableManager<
    _$AppDatabase,
    $DescriptionHistoryTable,
    DescriptionHistoryData,
    $$DescriptionHistoryTableFilterComposer,
    $$DescriptionHistoryTableOrderingComposer,
    $$DescriptionHistoryTableCreateCompanionBuilder,
    $$DescriptionHistoryTableUpdateCompanionBuilder> {
  $$DescriptionHistoryTableTableManager(
      _$AppDatabase db, $DescriptionHistoryTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$DescriptionHistoryTableFilterComposer(ComposerState(db, table)),
          orderingComposer: $$DescriptionHistoryTableOrderingComposer(
              ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> description = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              DescriptionHistoryCompanion(
            id: id,
            description: description,
            createdAt: createdAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String description,
            required DateTime createdAt,
          }) =>
              DescriptionHistoryCompanion.insert(
            id: id,
            description: description,
            createdAt: createdAt,
          ),
        ));
}

class $$DescriptionHistoryTableFilterComposer
    extends FilterComposer<_$AppDatabase, $DescriptionHistoryTable> {
  $$DescriptionHistoryTableFilterComposer(super.$state);
  ColumnFilters<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get description => $state.composableBuilder(
      column: $state.table.description,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));
}

class $$DescriptionHistoryTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $DescriptionHistoryTable> {
  $$DescriptionHistoryTableOrderingComposer(super.$state);
  ColumnOrderings<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get description => $state.composableBuilder(
      column: $state.table.description,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

typedef $$DestinationsTableCreateCompanionBuilder = DestinationsCompanion
    Function({
  Value<int> id,
  required String name,
  required double latitude,
  required double longitude,
  required DateTime createdAt,
});
typedef $$DestinationsTableUpdateCompanionBuilder = DestinationsCompanion
    Function({
  Value<int> id,
  Value<String> name,
  Value<double> latitude,
  Value<double> longitude,
  Value<DateTime> createdAt,
});

class $$DestinationsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $DestinationsTable,
    Destination,
    $$DestinationsTableFilterComposer,
    $$DestinationsTableOrderingComposer,
    $$DestinationsTableCreateCompanionBuilder,
    $$DestinationsTableUpdateCompanionBuilder> {
  $$DestinationsTableTableManager(_$AppDatabase db, $DestinationsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$DestinationsTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$DestinationsTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<double> latitude = const Value.absent(),
            Value<double> longitude = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              DestinationsCompanion(
            id: id,
            name: name,
            latitude: latitude,
            longitude: longitude,
            createdAt: createdAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String name,
            required double latitude,
            required double longitude,
            required DateTime createdAt,
          }) =>
              DestinationsCompanion.insert(
            id: id,
            name: name,
            latitude: latitude,
            longitude: longitude,
            createdAt: createdAt,
          ),
        ));
}

class $$DestinationsTableFilterComposer
    extends FilterComposer<_$AppDatabase, $DestinationsTable> {
  $$DestinationsTableFilterComposer(super.$state);
  ColumnFilters<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get name => $state.composableBuilder(
      column: $state.table.name,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get latitude => $state.composableBuilder(
      column: $state.table.latitude,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get longitude => $state.composableBuilder(
      column: $state.table.longitude,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));
}

class $$DestinationsTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $DestinationsTable> {
  $$DestinationsTableOrderingComposer(super.$state);
  ColumnOrderings<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get name => $state.composableBuilder(
      column: $state.table.name,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get latitude => $state.composableBuilder(
      column: $state.table.latitude,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get longitude => $state.composableBuilder(
      column: $state.table.longitude,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$OcrHistoryTableTableManager get ocrHistory =>
      $$OcrHistoryTableTableManager(_db, _db.ocrHistory);
  $$DescriptionHistoryTableTableManager get descriptionHistory =>
      $$DescriptionHistoryTableTableManager(_db, _db.descriptionHistory);
  $$DestinationsTableTableManager get destinations =>
      $$DestinationsTableTableManager(_db, _db.destinations);
}
