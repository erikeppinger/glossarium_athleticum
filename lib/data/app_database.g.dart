// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $ExercisesTable extends Exercises
    with TableInfo<$ExercisesTable, Exercise> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ExercisesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _movementPatternMeta = const VerificationMeta(
    'movementPattern',
  );
  @override
  late final GeneratedColumn<String> movementPattern = GeneratedColumn<String>(
    'movement_pattern',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _muscleGroupsMeta = const VerificationMeta(
    'muscleGroups',
  );
  @override
  late final GeneratedColumn<String> muscleGroups = GeneratedColumn<String>(
    'muscle_groups',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _equipmentMeta = const VerificationMeta(
    'equipment',
  );
  @override
  late final GeneratedColumn<String> equipment = GeneratedColumn<String>(
    'equipment',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _difficultyMeta = const VerificationMeta(
    'difficulty',
  );
  @override
  late final GeneratedColumn<String> difficulty = GeneratedColumn<String>(
    'difficulty',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _measurementTypeMeta = const VerificationMeta(
    'measurementType',
  );
  @override
  late final GeneratedColumn<String> measurementType = GeneratedColumn<String>(
    'measurement_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _safetyNotesMeta = const VerificationMeta(
    'safetyNotes',
  );
  @override
  late final GeneratedColumn<String> safetyNotes = GeneratedColumn<String>(
    'safety_notes',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _videoReferenceMeta = const VerificationMeta(
    'videoReference',
  );
  @override
  late final GeneratedColumn<String> videoReference = GeneratedColumn<String>(
    'video_reference',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _isCustomMeta = const VerificationMeta(
    'isCustom',
  );
  @override
  late final GeneratedColumn<bool> isCustom = GeneratedColumn<bool>(
    'is_custom',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_custom" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    category,
    movementPattern,
    muscleGroups,
    equipment,
    difficulty,
    measurementType,
    description,
    safetyNotes,
    videoReference,
    isCustom,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'exercises';
  @override
  VerificationContext validateIntegrity(
    Insertable<Exercise> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('movement_pattern')) {
      context.handle(
        _movementPatternMeta,
        movementPattern.isAcceptableOrUnknown(
          data['movement_pattern']!,
          _movementPatternMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_movementPatternMeta);
    }
    if (data.containsKey('muscle_groups')) {
      context.handle(
        _muscleGroupsMeta,
        muscleGroups.isAcceptableOrUnknown(
          data['muscle_groups']!,
          _muscleGroupsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_muscleGroupsMeta);
    }
    if (data.containsKey('equipment')) {
      context.handle(
        _equipmentMeta,
        equipment.isAcceptableOrUnknown(data['equipment']!, _equipmentMeta),
      );
    } else if (isInserting) {
      context.missing(_equipmentMeta);
    }
    if (data.containsKey('difficulty')) {
      context.handle(
        _difficultyMeta,
        difficulty.isAcceptableOrUnknown(data['difficulty']!, _difficultyMeta),
      );
    } else if (isInserting) {
      context.missing(_difficultyMeta);
    }
    if (data.containsKey('measurement_type')) {
      context.handle(
        _measurementTypeMeta,
        measurementType.isAcceptableOrUnknown(
          data['measurement_type']!,
          _measurementTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_measurementTypeMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('safety_notes')) {
      context.handle(
        _safetyNotesMeta,
        safetyNotes.isAcceptableOrUnknown(
          data['safety_notes']!,
          _safetyNotesMeta,
        ),
      );
    }
    if (data.containsKey('video_reference')) {
      context.handle(
        _videoReferenceMeta,
        videoReference.isAcceptableOrUnknown(
          data['video_reference']!,
          _videoReferenceMeta,
        ),
      );
    }
    if (data.containsKey('is_custom')) {
      context.handle(
        _isCustomMeta,
        isCustom.isAcceptableOrUnknown(data['is_custom']!, _isCustomMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Exercise map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Exercise(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      movementPattern: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}movement_pattern'],
      )!,
      muscleGroups: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}muscle_groups'],
      )!,
      equipment: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}equipment'],
      )!,
      difficulty: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}difficulty'],
      )!,
      measurementType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}measurement_type'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      )!,
      safetyNotes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}safety_notes'],
      )!,
      videoReference: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}video_reference'],
      )!,
      isCustom: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_custom'],
      )!,
    );
  }

  @override
  $ExercisesTable createAlias(String alias) {
    return $ExercisesTable(attachedDatabase, alias);
  }
}

class Exercise extends DataClass implements Insertable<Exercise> {
  final String id;
  final String name;
  final String category;
  final String movementPattern;

  /// Comma-separated (e.g. "Shoulders,Upper Back"); split at the call site.
  final String muscleGroups;
  final String equipment;
  final String difficulty;

  /// One of "Weight x Reps", "Time", "Distance" - drives session-logging inputs.
  final String measurementType;
  final String description;
  final String safetyNotes;
  final String videoReference;
  final bool isCustom;
  const Exercise({
    required this.id,
    required this.name,
    required this.category,
    required this.movementPattern,
    required this.muscleGroups,
    required this.equipment,
    required this.difficulty,
    required this.measurementType,
    required this.description,
    required this.safetyNotes,
    required this.videoReference,
    required this.isCustom,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['category'] = Variable<String>(category);
    map['movement_pattern'] = Variable<String>(movementPattern);
    map['muscle_groups'] = Variable<String>(muscleGroups);
    map['equipment'] = Variable<String>(equipment);
    map['difficulty'] = Variable<String>(difficulty);
    map['measurement_type'] = Variable<String>(measurementType);
    map['description'] = Variable<String>(description);
    map['safety_notes'] = Variable<String>(safetyNotes);
    map['video_reference'] = Variable<String>(videoReference);
    map['is_custom'] = Variable<bool>(isCustom);
    return map;
  }

  ExercisesCompanion toCompanion(bool nullToAbsent) {
    return ExercisesCompanion(
      id: Value(id),
      name: Value(name),
      category: Value(category),
      movementPattern: Value(movementPattern),
      muscleGroups: Value(muscleGroups),
      equipment: Value(equipment),
      difficulty: Value(difficulty),
      measurementType: Value(measurementType),
      description: Value(description),
      safetyNotes: Value(safetyNotes),
      videoReference: Value(videoReference),
      isCustom: Value(isCustom),
    );
  }

  factory Exercise.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Exercise(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      category: serializer.fromJson<String>(json['category']),
      movementPattern: serializer.fromJson<String>(json['movementPattern']),
      muscleGroups: serializer.fromJson<String>(json['muscleGroups']),
      equipment: serializer.fromJson<String>(json['equipment']),
      difficulty: serializer.fromJson<String>(json['difficulty']),
      measurementType: serializer.fromJson<String>(json['measurementType']),
      description: serializer.fromJson<String>(json['description']),
      safetyNotes: serializer.fromJson<String>(json['safetyNotes']),
      videoReference: serializer.fromJson<String>(json['videoReference']),
      isCustom: serializer.fromJson<bool>(json['isCustom']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'category': serializer.toJson<String>(category),
      'movementPattern': serializer.toJson<String>(movementPattern),
      'muscleGroups': serializer.toJson<String>(muscleGroups),
      'equipment': serializer.toJson<String>(equipment),
      'difficulty': serializer.toJson<String>(difficulty),
      'measurementType': serializer.toJson<String>(measurementType),
      'description': serializer.toJson<String>(description),
      'safetyNotes': serializer.toJson<String>(safetyNotes),
      'videoReference': serializer.toJson<String>(videoReference),
      'isCustom': serializer.toJson<bool>(isCustom),
    };
  }

  Exercise copyWith({
    String? id,
    String? name,
    String? category,
    String? movementPattern,
    String? muscleGroups,
    String? equipment,
    String? difficulty,
    String? measurementType,
    String? description,
    String? safetyNotes,
    String? videoReference,
    bool? isCustom,
  }) => Exercise(
    id: id ?? this.id,
    name: name ?? this.name,
    category: category ?? this.category,
    movementPattern: movementPattern ?? this.movementPattern,
    muscleGroups: muscleGroups ?? this.muscleGroups,
    equipment: equipment ?? this.equipment,
    difficulty: difficulty ?? this.difficulty,
    measurementType: measurementType ?? this.measurementType,
    description: description ?? this.description,
    safetyNotes: safetyNotes ?? this.safetyNotes,
    videoReference: videoReference ?? this.videoReference,
    isCustom: isCustom ?? this.isCustom,
  );
  Exercise copyWithCompanion(ExercisesCompanion data) {
    return Exercise(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      category: data.category.present ? data.category.value : this.category,
      movementPattern: data.movementPattern.present
          ? data.movementPattern.value
          : this.movementPattern,
      muscleGroups: data.muscleGroups.present
          ? data.muscleGroups.value
          : this.muscleGroups,
      equipment: data.equipment.present ? data.equipment.value : this.equipment,
      difficulty: data.difficulty.present
          ? data.difficulty.value
          : this.difficulty,
      measurementType: data.measurementType.present
          ? data.measurementType.value
          : this.measurementType,
      description: data.description.present
          ? data.description.value
          : this.description,
      safetyNotes: data.safetyNotes.present
          ? data.safetyNotes.value
          : this.safetyNotes,
      videoReference: data.videoReference.present
          ? data.videoReference.value
          : this.videoReference,
      isCustom: data.isCustom.present ? data.isCustom.value : this.isCustom,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Exercise(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('category: $category, ')
          ..write('movementPattern: $movementPattern, ')
          ..write('muscleGroups: $muscleGroups, ')
          ..write('equipment: $equipment, ')
          ..write('difficulty: $difficulty, ')
          ..write('measurementType: $measurementType, ')
          ..write('description: $description, ')
          ..write('safetyNotes: $safetyNotes, ')
          ..write('videoReference: $videoReference, ')
          ..write('isCustom: $isCustom')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    category,
    movementPattern,
    muscleGroups,
    equipment,
    difficulty,
    measurementType,
    description,
    safetyNotes,
    videoReference,
    isCustom,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Exercise &&
          other.id == this.id &&
          other.name == this.name &&
          other.category == this.category &&
          other.movementPattern == this.movementPattern &&
          other.muscleGroups == this.muscleGroups &&
          other.equipment == this.equipment &&
          other.difficulty == this.difficulty &&
          other.measurementType == this.measurementType &&
          other.description == this.description &&
          other.safetyNotes == this.safetyNotes &&
          other.videoReference == this.videoReference &&
          other.isCustom == this.isCustom);
}

class ExercisesCompanion extends UpdateCompanion<Exercise> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> category;
  final Value<String> movementPattern;
  final Value<String> muscleGroups;
  final Value<String> equipment;
  final Value<String> difficulty;
  final Value<String> measurementType;
  final Value<String> description;
  final Value<String> safetyNotes;
  final Value<String> videoReference;
  final Value<bool> isCustom;
  final Value<int> rowid;
  const ExercisesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.category = const Value.absent(),
    this.movementPattern = const Value.absent(),
    this.muscleGroups = const Value.absent(),
    this.equipment = const Value.absent(),
    this.difficulty = const Value.absent(),
    this.measurementType = const Value.absent(),
    this.description = const Value.absent(),
    this.safetyNotes = const Value.absent(),
    this.videoReference = const Value.absent(),
    this.isCustom = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ExercisesCompanion.insert({
    required String id,
    required String name,
    required String category,
    required String movementPattern,
    required String muscleGroups,
    required String equipment,
    required String difficulty,
    required String measurementType,
    this.description = const Value.absent(),
    this.safetyNotes = const Value.absent(),
    this.videoReference = const Value.absent(),
    this.isCustom = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       category = Value(category),
       movementPattern = Value(movementPattern),
       muscleGroups = Value(muscleGroups),
       equipment = Value(equipment),
       difficulty = Value(difficulty),
       measurementType = Value(measurementType);
  static Insertable<Exercise> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? category,
    Expression<String>? movementPattern,
    Expression<String>? muscleGroups,
    Expression<String>? equipment,
    Expression<String>? difficulty,
    Expression<String>? measurementType,
    Expression<String>? description,
    Expression<String>? safetyNotes,
    Expression<String>? videoReference,
    Expression<bool>? isCustom,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (category != null) 'category': category,
      if (movementPattern != null) 'movement_pattern': movementPattern,
      if (muscleGroups != null) 'muscle_groups': muscleGroups,
      if (equipment != null) 'equipment': equipment,
      if (difficulty != null) 'difficulty': difficulty,
      if (measurementType != null) 'measurement_type': measurementType,
      if (description != null) 'description': description,
      if (safetyNotes != null) 'safety_notes': safetyNotes,
      if (videoReference != null) 'video_reference': videoReference,
      if (isCustom != null) 'is_custom': isCustom,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ExercisesCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? category,
    Value<String>? movementPattern,
    Value<String>? muscleGroups,
    Value<String>? equipment,
    Value<String>? difficulty,
    Value<String>? measurementType,
    Value<String>? description,
    Value<String>? safetyNotes,
    Value<String>? videoReference,
    Value<bool>? isCustom,
    Value<int>? rowid,
  }) {
    return ExercisesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      movementPattern: movementPattern ?? this.movementPattern,
      muscleGroups: muscleGroups ?? this.muscleGroups,
      equipment: equipment ?? this.equipment,
      difficulty: difficulty ?? this.difficulty,
      measurementType: measurementType ?? this.measurementType,
      description: description ?? this.description,
      safetyNotes: safetyNotes ?? this.safetyNotes,
      videoReference: videoReference ?? this.videoReference,
      isCustom: isCustom ?? this.isCustom,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (movementPattern.present) {
      map['movement_pattern'] = Variable<String>(movementPattern.value);
    }
    if (muscleGroups.present) {
      map['muscle_groups'] = Variable<String>(muscleGroups.value);
    }
    if (equipment.present) {
      map['equipment'] = Variable<String>(equipment.value);
    }
    if (difficulty.present) {
      map['difficulty'] = Variable<String>(difficulty.value);
    }
    if (measurementType.present) {
      map['measurement_type'] = Variable<String>(measurementType.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (safetyNotes.present) {
      map['safety_notes'] = Variable<String>(safetyNotes.value);
    }
    if (videoReference.present) {
      map['video_reference'] = Variable<String>(videoReference.value);
    }
    if (isCustom.present) {
      map['is_custom'] = Variable<bool>(isCustom.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ExercisesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('category: $category, ')
          ..write('movementPattern: $movementPattern, ')
          ..write('muscleGroups: $muscleGroups, ')
          ..write('equipment: $equipment, ')
          ..write('difficulty: $difficulty, ')
          ..write('measurementType: $measurementType, ')
          ..write('description: $description, ')
          ..write('safetyNotes: $safetyNotes, ')
          ..write('videoReference: $videoReference, ')
          ..write('isCustom: $isCustom, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PlansTable extends Plans with TableInfo<$PlansTable, Plan> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlansTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, notes, createdAt, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'plans';
  @override
  VerificationContext validateIntegrity(
    Insertable<Plan> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Plan map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Plan(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $PlansTable createAlias(String alias) {
    return $PlansTable(attachedDatabase, alias);
  }
}

class Plan extends DataClass implements Insertable<Plan> {
  final String id;
  final String name;
  final String notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Plan({
    required this.id,
    required this.name,
    required this.notes,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['notes'] = Variable<String>(notes);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  PlansCompanion toCompanion(bool nullToAbsent) {
    return PlansCompanion(
      id: Value(id),
      name: Value(name),
      notes: Value(notes),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Plan.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Plan(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      notes: serializer.fromJson<String>(json['notes']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'notes': serializer.toJson<String>(notes),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Plan copyWith({
    String? id,
    String? name,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Plan(
    id: id ?? this.id,
    name: name ?? this.name,
    notes: notes ?? this.notes,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Plan copyWithCompanion(PlansCompanion data) {
    return Plan(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      notes: data.notes.present ? data.notes.value : this.notes,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Plan(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, notes, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Plan &&
          other.id == this.id &&
          other.name == this.name &&
          other.notes == this.notes &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class PlansCompanion extends UpdateCompanion<Plan> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> notes;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const PlansCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PlansCompanion.insert({
    required String id,
    required String name,
    this.notes = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<Plan> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? notes,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (notes != null) 'notes': notes,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PlansCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? notes,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return PlansCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlansCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PlanSessionsTable extends PlanSessions
    with TableInfo<$PlanSessionsTable, PlanSession> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlanSessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _planIdMeta = const VerificationMeta('planId');
  @override
  late final GeneratedColumn<String> planId = GeneratedColumn<String>(
    'plan_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES plans (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _weekNumberMeta = const VerificationMeta(
    'weekNumber',
  );
  @override
  late final GeneratedColumn<int> weekNumber = GeneratedColumn<int>(
    'week_number',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dayMeta = const VerificationMeta('day');
  @override
  late final GeneratedColumn<String> day = GeneratedColumn<String>(
    'day',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sessionNameMeta = const VerificationMeta(
    'sessionName',
  );
  @override
  late final GeneratedColumn<String> sessionName = GeneratedColumn<String>(
    'session_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _assignedDateMeta = const VerificationMeta(
    'assignedDate',
  );
  @override
  late final GeneratedColumn<DateTime> assignedDate = GeneratedColumn<DateTime>(
    'assigned_date',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    planId,
    weekNumber,
    day,
    sessionName,
    assignedDate,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'plan_sessions';
  @override
  VerificationContext validateIntegrity(
    Insertable<PlanSession> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('plan_id')) {
      context.handle(
        _planIdMeta,
        planId.isAcceptableOrUnknown(data['plan_id']!, _planIdMeta),
      );
    } else if (isInserting) {
      context.missing(_planIdMeta);
    }
    if (data.containsKey('week_number')) {
      context.handle(
        _weekNumberMeta,
        weekNumber.isAcceptableOrUnknown(data['week_number']!, _weekNumberMeta),
      );
    } else if (isInserting) {
      context.missing(_weekNumberMeta);
    }
    if (data.containsKey('day')) {
      context.handle(
        _dayMeta,
        day.isAcceptableOrUnknown(data['day']!, _dayMeta),
      );
    } else if (isInserting) {
      context.missing(_dayMeta);
    }
    if (data.containsKey('session_name')) {
      context.handle(
        _sessionNameMeta,
        sessionName.isAcceptableOrUnknown(
          data['session_name']!,
          _sessionNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sessionNameMeta);
    }
    if (data.containsKey('assigned_date')) {
      context.handle(
        _assignedDateMeta,
        assignedDate.isAcceptableOrUnknown(
          data['assigned_date']!,
          _assignedDateMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PlanSession map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PlanSession(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      planId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}plan_id'],
      )!,
      weekNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}week_number'],
      )!,
      day: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}day'],
      )!,
      sessionName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}session_name'],
      )!,
      assignedDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}assigned_date'],
      ),
    );
  }

  @override
  $PlanSessionsTable createAlias(String alias) {
    return $PlanSessionsTable(attachedDatabase, alias);
  }
}

class PlanSession extends DataClass implements Insertable<PlanSession> {
  final int id;
  final String planId;
  final int weekNumber;
  final String day;
  final String sessionName;

  /// Null while still template-only; set once placed on the calendar.
  final DateTime? assignedDate;
  const PlanSession({
    required this.id,
    required this.planId,
    required this.weekNumber,
    required this.day,
    required this.sessionName,
    this.assignedDate,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['plan_id'] = Variable<String>(planId);
    map['week_number'] = Variable<int>(weekNumber);
    map['day'] = Variable<String>(day);
    map['session_name'] = Variable<String>(sessionName);
    if (!nullToAbsent || assignedDate != null) {
      map['assigned_date'] = Variable<DateTime>(assignedDate);
    }
    return map;
  }

  PlanSessionsCompanion toCompanion(bool nullToAbsent) {
    return PlanSessionsCompanion(
      id: Value(id),
      planId: Value(planId),
      weekNumber: Value(weekNumber),
      day: Value(day),
      sessionName: Value(sessionName),
      assignedDate: assignedDate == null && nullToAbsent
          ? const Value.absent()
          : Value(assignedDate),
    );
  }

  factory PlanSession.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PlanSession(
      id: serializer.fromJson<int>(json['id']),
      planId: serializer.fromJson<String>(json['planId']),
      weekNumber: serializer.fromJson<int>(json['weekNumber']),
      day: serializer.fromJson<String>(json['day']),
      sessionName: serializer.fromJson<String>(json['sessionName']),
      assignedDate: serializer.fromJson<DateTime?>(json['assignedDate']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'planId': serializer.toJson<String>(planId),
      'weekNumber': serializer.toJson<int>(weekNumber),
      'day': serializer.toJson<String>(day),
      'sessionName': serializer.toJson<String>(sessionName),
      'assignedDate': serializer.toJson<DateTime?>(assignedDate),
    };
  }

  PlanSession copyWith({
    int? id,
    String? planId,
    int? weekNumber,
    String? day,
    String? sessionName,
    Value<DateTime?> assignedDate = const Value.absent(),
  }) => PlanSession(
    id: id ?? this.id,
    planId: planId ?? this.planId,
    weekNumber: weekNumber ?? this.weekNumber,
    day: day ?? this.day,
    sessionName: sessionName ?? this.sessionName,
    assignedDate: assignedDate.present ? assignedDate.value : this.assignedDate,
  );
  PlanSession copyWithCompanion(PlanSessionsCompanion data) {
    return PlanSession(
      id: data.id.present ? data.id.value : this.id,
      planId: data.planId.present ? data.planId.value : this.planId,
      weekNumber: data.weekNumber.present
          ? data.weekNumber.value
          : this.weekNumber,
      day: data.day.present ? data.day.value : this.day,
      sessionName: data.sessionName.present
          ? data.sessionName.value
          : this.sessionName,
      assignedDate: data.assignedDate.present
          ? data.assignedDate.value
          : this.assignedDate,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlanSession(')
          ..write('id: $id, ')
          ..write('planId: $planId, ')
          ..write('weekNumber: $weekNumber, ')
          ..write('day: $day, ')
          ..write('sessionName: $sessionName, ')
          ..write('assignedDate: $assignedDate')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, planId, weekNumber, day, sessionName, assignedDate);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlanSession &&
          other.id == this.id &&
          other.planId == this.planId &&
          other.weekNumber == this.weekNumber &&
          other.day == this.day &&
          other.sessionName == this.sessionName &&
          other.assignedDate == this.assignedDate);
}

class PlanSessionsCompanion extends UpdateCompanion<PlanSession> {
  final Value<int> id;
  final Value<String> planId;
  final Value<int> weekNumber;
  final Value<String> day;
  final Value<String> sessionName;
  final Value<DateTime?> assignedDate;
  const PlanSessionsCompanion({
    this.id = const Value.absent(),
    this.planId = const Value.absent(),
    this.weekNumber = const Value.absent(),
    this.day = const Value.absent(),
    this.sessionName = const Value.absent(),
    this.assignedDate = const Value.absent(),
  });
  PlanSessionsCompanion.insert({
    this.id = const Value.absent(),
    required String planId,
    required int weekNumber,
    required String day,
    required String sessionName,
    this.assignedDate = const Value.absent(),
  }) : planId = Value(planId),
       weekNumber = Value(weekNumber),
       day = Value(day),
       sessionName = Value(sessionName);
  static Insertable<PlanSession> custom({
    Expression<int>? id,
    Expression<String>? planId,
    Expression<int>? weekNumber,
    Expression<String>? day,
    Expression<String>? sessionName,
    Expression<DateTime>? assignedDate,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (planId != null) 'plan_id': planId,
      if (weekNumber != null) 'week_number': weekNumber,
      if (day != null) 'day': day,
      if (sessionName != null) 'session_name': sessionName,
      if (assignedDate != null) 'assigned_date': assignedDate,
    });
  }

  PlanSessionsCompanion copyWith({
    Value<int>? id,
    Value<String>? planId,
    Value<int>? weekNumber,
    Value<String>? day,
    Value<String>? sessionName,
    Value<DateTime?>? assignedDate,
  }) {
    return PlanSessionsCompanion(
      id: id ?? this.id,
      planId: planId ?? this.planId,
      weekNumber: weekNumber ?? this.weekNumber,
      day: day ?? this.day,
      sessionName: sessionName ?? this.sessionName,
      assignedDate: assignedDate ?? this.assignedDate,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (planId.present) {
      map['plan_id'] = Variable<String>(planId.value);
    }
    if (weekNumber.present) {
      map['week_number'] = Variable<int>(weekNumber.value);
    }
    if (day.present) {
      map['day'] = Variable<String>(day.value);
    }
    if (sessionName.present) {
      map['session_name'] = Variable<String>(sessionName.value);
    }
    if (assignedDate.present) {
      map['assigned_date'] = Variable<DateTime>(assignedDate.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlanSessionsCompanion(')
          ..write('id: $id, ')
          ..write('planId: $planId, ')
          ..write('weekNumber: $weekNumber, ')
          ..write('day: $day, ')
          ..write('sessionName: $sessionName, ')
          ..write('assignedDate: $assignedDate')
          ..write(')'))
        .toString();
  }
}

class $PlanExercisesTable extends PlanExercises
    with TableInfo<$PlanExercisesTable, PlanExercise> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlanExercisesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _sessionIdMeta = const VerificationMeta(
    'sessionId',
  );
  @override
  late final GeneratedColumn<int> sessionId = GeneratedColumn<int>(
    'session_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES plan_sessions (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _orderMeta = const VerificationMeta('order');
  @override
  late final GeneratedColumn<int> order = GeneratedColumn<int>(
    'order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _exerciseIdMeta = const VerificationMeta(
    'exerciseId',
  );
  @override
  late final GeneratedColumn<String> exerciseId = GeneratedColumn<String>(
    'exercise_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES exercises (id)',
    ),
  );
  static const VerificationMeta _exerciseNameMeta = const VerificationMeta(
    'exerciseName',
  );
  @override
  late final GeneratedColumn<String> exerciseName = GeneratedColumn<String>(
    'exercise_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _setsMeta = const VerificationMeta('sets');
  @override
  late final GeneratedColumn<int> sets = GeneratedColumn<int>(
    'sets',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _repsMeta = const VerificationMeta('reps');
  @override
  late final GeneratedColumn<String> reps = GeneratedColumn<String>(
    'reps',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _weightIntensityMeta = const VerificationMeta(
    'weightIntensity',
  );
  @override
  late final GeneratedColumn<String> weightIntensity = GeneratedColumn<String>(
    'weight_intensity',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _restSecMeta = const VerificationMeta(
    'restSec',
  );
  @override
  late final GeneratedColumn<int> restSec = GeneratedColumn<int>(
    'rest_sec',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _videoUrlMeta = const VerificationMeta(
    'videoUrl',
  );
  @override
  late final GeneratedColumn<String> videoUrl = GeneratedColumn<String>(
    'video_url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sessionId,
    order,
    exerciseId,
    exerciseName,
    sets,
    reps,
    weightIntensity,
    restSec,
    notes,
    videoUrl,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'plan_exercises';
  @override
  VerificationContext validateIntegrity(
    Insertable<PlanExercise> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('session_id')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('order')) {
      context.handle(
        _orderMeta,
        order.isAcceptableOrUnknown(data['order']!, _orderMeta),
      );
    } else if (isInserting) {
      context.missing(_orderMeta);
    }
    if (data.containsKey('exercise_id')) {
      context.handle(
        _exerciseIdMeta,
        exerciseId.isAcceptableOrUnknown(data['exercise_id']!, _exerciseIdMeta),
      );
    }
    if (data.containsKey('exercise_name')) {
      context.handle(
        _exerciseNameMeta,
        exerciseName.isAcceptableOrUnknown(
          data['exercise_name']!,
          _exerciseNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_exerciseNameMeta);
    }
    if (data.containsKey('sets')) {
      context.handle(
        _setsMeta,
        sets.isAcceptableOrUnknown(data['sets']!, _setsMeta),
      );
    } else if (isInserting) {
      context.missing(_setsMeta);
    }
    if (data.containsKey('reps')) {
      context.handle(
        _repsMeta,
        reps.isAcceptableOrUnknown(data['reps']!, _repsMeta),
      );
    } else if (isInserting) {
      context.missing(_repsMeta);
    }
    if (data.containsKey('weight_intensity')) {
      context.handle(
        _weightIntensityMeta,
        weightIntensity.isAcceptableOrUnknown(
          data['weight_intensity']!,
          _weightIntensityMeta,
        ),
      );
    }
    if (data.containsKey('rest_sec')) {
      context.handle(
        _restSecMeta,
        restSec.isAcceptableOrUnknown(data['rest_sec']!, _restSecMeta),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('video_url')) {
      context.handle(
        _videoUrlMeta,
        videoUrl.isAcceptableOrUnknown(data['video_url']!, _videoUrlMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PlanExercise map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PlanExercise(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}session_id'],
      )!,
      order: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}order'],
      )!,
      exerciseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}exercise_id'],
      ),
      exerciseName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}exercise_name'],
      )!,
      sets: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sets'],
      )!,
      reps: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reps'],
      )!,
      weightIntensity: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}weight_intensity'],
      )!,
      restSec: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rest_sec'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      )!,
      videoUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}video_url'],
      )!,
    );
  }

  @override
  $PlanExercisesTable createAlias(String alias) {
    return $PlanExercisesTable(attachedDatabase, alias);
  }
}

class PlanExercise extends DataClass implements Insertable<PlanExercise> {
  final int id;
  final int sessionId;
  final int order;

  /// Resolved match against Exercises.id; null until the import-preview
  /// screen resolves it (or the row was built from the in-app library directly).
  final String? exerciseId;

  /// Raw name as typed/imported - kept even after resolution so re-export
  /// round-trips the original text.
  final String exerciseName;
  final int sets;
  final String reps;
  final String weightIntensity;
  final int? restSec;
  final String notes;
  final String videoUrl;
  const PlanExercise({
    required this.id,
    required this.sessionId,
    required this.order,
    this.exerciseId,
    required this.exerciseName,
    required this.sets,
    required this.reps,
    required this.weightIntensity,
    this.restSec,
    required this.notes,
    required this.videoUrl,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['session_id'] = Variable<int>(sessionId);
    map['order'] = Variable<int>(order);
    if (!nullToAbsent || exerciseId != null) {
      map['exercise_id'] = Variable<String>(exerciseId);
    }
    map['exercise_name'] = Variable<String>(exerciseName);
    map['sets'] = Variable<int>(sets);
    map['reps'] = Variable<String>(reps);
    map['weight_intensity'] = Variable<String>(weightIntensity);
    if (!nullToAbsent || restSec != null) {
      map['rest_sec'] = Variable<int>(restSec);
    }
    map['notes'] = Variable<String>(notes);
    map['video_url'] = Variable<String>(videoUrl);
    return map;
  }

  PlanExercisesCompanion toCompanion(bool nullToAbsent) {
    return PlanExercisesCompanion(
      id: Value(id),
      sessionId: Value(sessionId),
      order: Value(order),
      exerciseId: exerciseId == null && nullToAbsent
          ? const Value.absent()
          : Value(exerciseId),
      exerciseName: Value(exerciseName),
      sets: Value(sets),
      reps: Value(reps),
      weightIntensity: Value(weightIntensity),
      restSec: restSec == null && nullToAbsent
          ? const Value.absent()
          : Value(restSec),
      notes: Value(notes),
      videoUrl: Value(videoUrl),
    );
  }

  factory PlanExercise.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PlanExercise(
      id: serializer.fromJson<int>(json['id']),
      sessionId: serializer.fromJson<int>(json['sessionId']),
      order: serializer.fromJson<int>(json['order']),
      exerciseId: serializer.fromJson<String?>(json['exerciseId']),
      exerciseName: serializer.fromJson<String>(json['exerciseName']),
      sets: serializer.fromJson<int>(json['sets']),
      reps: serializer.fromJson<String>(json['reps']),
      weightIntensity: serializer.fromJson<String>(json['weightIntensity']),
      restSec: serializer.fromJson<int?>(json['restSec']),
      notes: serializer.fromJson<String>(json['notes']),
      videoUrl: serializer.fromJson<String>(json['videoUrl']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'sessionId': serializer.toJson<int>(sessionId),
      'order': serializer.toJson<int>(order),
      'exerciseId': serializer.toJson<String?>(exerciseId),
      'exerciseName': serializer.toJson<String>(exerciseName),
      'sets': serializer.toJson<int>(sets),
      'reps': serializer.toJson<String>(reps),
      'weightIntensity': serializer.toJson<String>(weightIntensity),
      'restSec': serializer.toJson<int?>(restSec),
      'notes': serializer.toJson<String>(notes),
      'videoUrl': serializer.toJson<String>(videoUrl),
    };
  }

  PlanExercise copyWith({
    int? id,
    int? sessionId,
    int? order,
    Value<String?> exerciseId = const Value.absent(),
    String? exerciseName,
    int? sets,
    String? reps,
    String? weightIntensity,
    Value<int?> restSec = const Value.absent(),
    String? notes,
    String? videoUrl,
  }) => PlanExercise(
    id: id ?? this.id,
    sessionId: sessionId ?? this.sessionId,
    order: order ?? this.order,
    exerciseId: exerciseId.present ? exerciseId.value : this.exerciseId,
    exerciseName: exerciseName ?? this.exerciseName,
    sets: sets ?? this.sets,
    reps: reps ?? this.reps,
    weightIntensity: weightIntensity ?? this.weightIntensity,
    restSec: restSec.present ? restSec.value : this.restSec,
    notes: notes ?? this.notes,
    videoUrl: videoUrl ?? this.videoUrl,
  );
  PlanExercise copyWithCompanion(PlanExercisesCompanion data) {
    return PlanExercise(
      id: data.id.present ? data.id.value : this.id,
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      order: data.order.present ? data.order.value : this.order,
      exerciseId: data.exerciseId.present
          ? data.exerciseId.value
          : this.exerciseId,
      exerciseName: data.exerciseName.present
          ? data.exerciseName.value
          : this.exerciseName,
      sets: data.sets.present ? data.sets.value : this.sets,
      reps: data.reps.present ? data.reps.value : this.reps,
      weightIntensity: data.weightIntensity.present
          ? data.weightIntensity.value
          : this.weightIntensity,
      restSec: data.restSec.present ? data.restSec.value : this.restSec,
      notes: data.notes.present ? data.notes.value : this.notes,
      videoUrl: data.videoUrl.present ? data.videoUrl.value : this.videoUrl,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlanExercise(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('order: $order, ')
          ..write('exerciseId: $exerciseId, ')
          ..write('exerciseName: $exerciseName, ')
          ..write('sets: $sets, ')
          ..write('reps: $reps, ')
          ..write('weightIntensity: $weightIntensity, ')
          ..write('restSec: $restSec, ')
          ..write('notes: $notes, ')
          ..write('videoUrl: $videoUrl')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    sessionId,
    order,
    exerciseId,
    exerciseName,
    sets,
    reps,
    weightIntensity,
    restSec,
    notes,
    videoUrl,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlanExercise &&
          other.id == this.id &&
          other.sessionId == this.sessionId &&
          other.order == this.order &&
          other.exerciseId == this.exerciseId &&
          other.exerciseName == this.exerciseName &&
          other.sets == this.sets &&
          other.reps == this.reps &&
          other.weightIntensity == this.weightIntensity &&
          other.restSec == this.restSec &&
          other.notes == this.notes &&
          other.videoUrl == this.videoUrl);
}

class PlanExercisesCompanion extends UpdateCompanion<PlanExercise> {
  final Value<int> id;
  final Value<int> sessionId;
  final Value<int> order;
  final Value<String?> exerciseId;
  final Value<String> exerciseName;
  final Value<int> sets;
  final Value<String> reps;
  final Value<String> weightIntensity;
  final Value<int?> restSec;
  final Value<String> notes;
  final Value<String> videoUrl;
  const PlanExercisesCompanion({
    this.id = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.order = const Value.absent(),
    this.exerciseId = const Value.absent(),
    this.exerciseName = const Value.absent(),
    this.sets = const Value.absent(),
    this.reps = const Value.absent(),
    this.weightIntensity = const Value.absent(),
    this.restSec = const Value.absent(),
    this.notes = const Value.absent(),
    this.videoUrl = const Value.absent(),
  });
  PlanExercisesCompanion.insert({
    this.id = const Value.absent(),
    required int sessionId,
    required int order,
    this.exerciseId = const Value.absent(),
    required String exerciseName,
    required int sets,
    required String reps,
    this.weightIntensity = const Value.absent(),
    this.restSec = const Value.absent(),
    this.notes = const Value.absent(),
    this.videoUrl = const Value.absent(),
  }) : sessionId = Value(sessionId),
       order = Value(order),
       exerciseName = Value(exerciseName),
       sets = Value(sets),
       reps = Value(reps);
  static Insertable<PlanExercise> custom({
    Expression<int>? id,
    Expression<int>? sessionId,
    Expression<int>? order,
    Expression<String>? exerciseId,
    Expression<String>? exerciseName,
    Expression<int>? sets,
    Expression<String>? reps,
    Expression<String>? weightIntensity,
    Expression<int>? restSec,
    Expression<String>? notes,
    Expression<String>? videoUrl,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sessionId != null) 'session_id': sessionId,
      if (order != null) 'order': order,
      if (exerciseId != null) 'exercise_id': exerciseId,
      if (exerciseName != null) 'exercise_name': exerciseName,
      if (sets != null) 'sets': sets,
      if (reps != null) 'reps': reps,
      if (weightIntensity != null) 'weight_intensity': weightIntensity,
      if (restSec != null) 'rest_sec': restSec,
      if (notes != null) 'notes': notes,
      if (videoUrl != null) 'video_url': videoUrl,
    });
  }

  PlanExercisesCompanion copyWith({
    Value<int>? id,
    Value<int>? sessionId,
    Value<int>? order,
    Value<String?>? exerciseId,
    Value<String>? exerciseName,
    Value<int>? sets,
    Value<String>? reps,
    Value<String>? weightIntensity,
    Value<int?>? restSec,
    Value<String>? notes,
    Value<String>? videoUrl,
  }) {
    return PlanExercisesCompanion(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      order: order ?? this.order,
      exerciseId: exerciseId ?? this.exerciseId,
      exerciseName: exerciseName ?? this.exerciseName,
      sets: sets ?? this.sets,
      reps: reps ?? this.reps,
      weightIntensity: weightIntensity ?? this.weightIntensity,
      restSec: restSec ?? this.restSec,
      notes: notes ?? this.notes,
      videoUrl: videoUrl ?? this.videoUrl,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (sessionId.present) {
      map['session_id'] = Variable<int>(sessionId.value);
    }
    if (order.present) {
      map['order'] = Variable<int>(order.value);
    }
    if (exerciseId.present) {
      map['exercise_id'] = Variable<String>(exerciseId.value);
    }
    if (exerciseName.present) {
      map['exercise_name'] = Variable<String>(exerciseName.value);
    }
    if (sets.present) {
      map['sets'] = Variable<int>(sets.value);
    }
    if (reps.present) {
      map['reps'] = Variable<String>(reps.value);
    }
    if (weightIntensity.present) {
      map['weight_intensity'] = Variable<String>(weightIntensity.value);
    }
    if (restSec.present) {
      map['rest_sec'] = Variable<int>(restSec.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (videoUrl.present) {
      map['video_url'] = Variable<String>(videoUrl.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlanExercisesCompanion(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('order: $order, ')
          ..write('exerciseId: $exerciseId, ')
          ..write('exerciseName: $exerciseName, ')
          ..write('sets: $sets, ')
          ..write('reps: $reps, ')
          ..write('weightIntensity: $weightIntensity, ')
          ..write('restSec: $restSec, ')
          ..write('notes: $notes, ')
          ..write('videoUrl: $videoUrl')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ExercisesTable exercises = $ExercisesTable(this);
  late final $PlansTable plans = $PlansTable(this);
  late final $PlanSessionsTable planSessions = $PlanSessionsTable(this);
  late final $PlanExercisesTable planExercises = $PlanExercisesTable(this);
  late final ExerciseDao exerciseDao = ExerciseDao(this as AppDatabase);
  late final PlanDao planDao = PlanDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    exercises,
    plans,
    planSessions,
    planExercises,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'plans',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('plan_sessions', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'plan_sessions',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('plan_exercises', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$ExercisesTableCreateCompanionBuilder = ExercisesCompanion Function({
  required String id,
  required String name,
  required String category,
  required String movementPattern,
  required String muscleGroups,
  required String equipment,
  required String difficulty,
  required String measurementType,
  Value<String> description,
  Value<String> safetyNotes,
  Value<String> videoReference,
  Value<bool> isCustom,
  Value<int> rowid,
});
typedef $$ExercisesTableUpdateCompanionBuilder = ExercisesCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<String> category,
  Value<String> movementPattern,
  Value<String> muscleGroups,
  Value<String> equipment,
  Value<String> difficulty,
  Value<String> measurementType,
  Value<String> description,
  Value<String> safetyNotes,
  Value<String> videoReference,
  Value<bool> isCustom,
  Value<int> rowid,
});

final class $$ExercisesTableReferences
    extends BaseReferences<_$AppDatabase, $ExercisesTable, Exercise> {
  $$ExercisesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$PlanExercisesTable, List<PlanExercise>>
  _planExercisesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.planExercises,
    aliasName: 'exercises__id__plan_exercises__exercise_id',
  );

  $$PlanExercisesTableProcessedTableManager get planExercisesRefs {
    final manager = $$PlanExercisesTableTableManager(
      $_db,
      $_db.planExercises,
    ).filter((f) => f.exerciseId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_planExercisesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ExercisesTableFilterComposer
    extends Composer<_$AppDatabase, $ExercisesTable> {
  $$ExercisesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get movementPattern => $composableBuilder(
    column: $table.movementPattern,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get muscleGroups => $composableBuilder(
    column: $table.muscleGroups,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get equipment => $composableBuilder(
    column: $table.equipment,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get difficulty => $composableBuilder(
    column: $table.difficulty,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get measurementType => $composableBuilder(
    column: $table.measurementType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get safetyNotes => $composableBuilder(
    column: $table.safetyNotes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get videoReference => $composableBuilder(
    column: $table.videoReference,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isCustom => $composableBuilder(
    column: $table.isCustom,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> planExercisesRefs(
    Expression<bool> Function($$PlanExercisesTableFilterComposer f) f,
  ) {
    final $$PlanExercisesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.planExercises,
      getReferencedColumn: (t) => t.exerciseId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlanExercisesTableFilterComposer(
            $db: $db,
            $table: $db.planExercises,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ExercisesTableOrderingComposer
    extends Composer<_$AppDatabase, $ExercisesTable> {
  $$ExercisesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get movementPattern => $composableBuilder(
    column: $table.movementPattern,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get muscleGroups => $composableBuilder(
    column: $table.muscleGroups,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get equipment => $composableBuilder(
    column: $table.equipment,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get difficulty => $composableBuilder(
    column: $table.difficulty,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get measurementType => $composableBuilder(
    column: $table.measurementType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get safetyNotes => $composableBuilder(
    column: $table.safetyNotes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get videoReference => $composableBuilder(
    column: $table.videoReference,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isCustom => $composableBuilder(
    column: $table.isCustom,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ExercisesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ExercisesTable> {
  $$ExercisesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get movementPattern => $composableBuilder(
    column: $table.movementPattern,
    builder: (column) => column,
  );

  GeneratedColumn<String> get muscleGroups => $composableBuilder(
    column: $table.muscleGroups,
    builder: (column) => column,
  );

  GeneratedColumn<String> get equipment =>
      $composableBuilder(column: $table.equipment, builder: (column) => column);

  GeneratedColumn<String> get difficulty => $composableBuilder(
    column: $table.difficulty,
    builder: (column) => column,
  );

  GeneratedColumn<String> get measurementType => $composableBuilder(
    column: $table.measurementType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get safetyNotes => $composableBuilder(
    column: $table.safetyNotes,
    builder: (column) => column,
  );

  GeneratedColumn<String> get videoReference => $composableBuilder(
    column: $table.videoReference,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isCustom =>
      $composableBuilder(column: $table.isCustom, builder: (column) => column);

  Expression<T> planExercisesRefs<T extends Object>(
    Expression<T> Function($$PlanExercisesTableAnnotationComposer a) f,
  ) {
    final $$PlanExercisesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.planExercises,
      getReferencedColumn: (t) => t.exerciseId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlanExercisesTableAnnotationComposer(
            $db: $db,
            $table: $db.planExercises,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ExercisesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ExercisesTable,
          Exercise,
          $$ExercisesTableFilterComposer,
          $$ExercisesTableOrderingComposer,
          $$ExercisesTableAnnotationComposer,
          $$ExercisesTableCreateCompanionBuilder,
          $$ExercisesTableUpdateCompanionBuilder,
          (Exercise, $$ExercisesTableReferences),
          Exercise,
          PrefetchHooks Function({bool planExercisesRefs})
        > {
  $$ExercisesTableTableManager(_$AppDatabase db, $ExercisesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ExercisesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ExercisesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ExercisesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<String> movementPattern = const Value.absent(),
                Value<String> muscleGroups = const Value.absent(),
                Value<String> equipment = const Value.absent(),
                Value<String> difficulty = const Value.absent(),
                Value<String> measurementType = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<String> safetyNotes = const Value.absent(),
                Value<String> videoReference = const Value.absent(),
                Value<bool> isCustom = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ExercisesCompanion(
                id: id,
                name: name,
                category: category,
                movementPattern: movementPattern,
                muscleGroups: muscleGroups,
                equipment: equipment,
                difficulty: difficulty,
                measurementType: measurementType,
                description: description,
                safetyNotes: safetyNotes,
                videoReference: videoReference,
                isCustom: isCustom,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String category,
                required String movementPattern,
                required String muscleGroups,
                required String equipment,
                required String difficulty,
                required String measurementType,
                Value<String> description = const Value.absent(),
                Value<String> safetyNotes = const Value.absent(),
                Value<String> videoReference = const Value.absent(),
                Value<bool> isCustom = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ExercisesCompanion.insert(
                id: id,
                name: name,
                category: category,
                movementPattern: movementPattern,
                muscleGroups: muscleGroups,
                equipment: equipment,
                difficulty: difficulty,
                measurementType: measurementType,
                description: description,
                safetyNotes: safetyNotes,
                videoReference: videoReference,
                isCustom: isCustom,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ExercisesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({planExercisesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (planExercisesRefs) db.planExercises,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (planExercisesRefs)
                    await $_getPrefetchedData<
                      Exercise,
                      $ExercisesTable,
                      PlanExercise
                    >(
                      currentTable: table,
                      referencedTable: $$ExercisesTableReferences
                          ._planExercisesRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$ExercisesTableReferences(
                            db,
                            table,
                            p0,
                          ).planExercisesRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.exerciseId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$ExercisesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ExercisesTable,
      Exercise,
      $$ExercisesTableFilterComposer,
      $$ExercisesTableOrderingComposer,
      $$ExercisesTableAnnotationComposer,
      $$ExercisesTableCreateCompanionBuilder,
      $$ExercisesTableUpdateCompanionBuilder,
      (Exercise, $$ExercisesTableReferences),
      Exercise,
      PrefetchHooks Function({bool planExercisesRefs})
    >;
typedef $$PlansTableCreateCompanionBuilder = PlansCompanion Function({
  required String id,
  required String name,
  Value<String> notes,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$PlansTableUpdateCompanionBuilder = PlansCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<String> notes,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

final class $$PlansTableReferences
    extends BaseReferences<_$AppDatabase, $PlansTable, Plan> {
  $$PlansTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$PlanSessionsTable, List<PlanSession>>
  _planSessionsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.planSessions,
    aliasName: 'plans__id__plan_sessions__plan_id',
  );

  $$PlanSessionsTableProcessedTableManager get planSessionsRefs {
    final manager = $$PlanSessionsTableTableManager(
      $_db,
      $_db.planSessions,
    ).filter((f) => f.planId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_planSessionsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$PlansTableFilterComposer extends Composer<_$AppDatabase, $PlansTable> {
  $$PlansTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> planSessionsRefs(
    Expression<bool> Function($$PlanSessionsTableFilterComposer f) f,
  ) {
    final $$PlanSessionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.planSessions,
      getReferencedColumn: (t) => t.planId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlanSessionsTableFilterComposer(
            $db: $db,
            $table: $db.planSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PlansTableOrderingComposer
    extends Composer<_$AppDatabase, $PlansTable> {
  $$PlansTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PlansTableAnnotationComposer
    extends Composer<_$AppDatabase, $PlansTable> {
  $$PlansTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> planSessionsRefs<T extends Object>(
    Expression<T> Function($$PlanSessionsTableAnnotationComposer a) f,
  ) {
    final $$PlanSessionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.planSessions,
      getReferencedColumn: (t) => t.planId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlanSessionsTableAnnotationComposer(
            $db: $db,
            $table: $db.planSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PlansTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PlansTable,
          Plan,
          $$PlansTableFilterComposer,
          $$PlansTableOrderingComposer,
          $$PlansTableAnnotationComposer,
          $$PlansTableCreateCompanionBuilder,
          $$PlansTableUpdateCompanionBuilder,
          (Plan, $$PlansTableReferences),
          Plan,
          PrefetchHooks Function({bool planSessionsRefs})
        > {
  $$PlansTableTableManager(_$AppDatabase db, $PlansTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlansTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlansTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PlansTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> notes = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PlansCompanion(
                id: id,
                name: name,
                notes: notes,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<String> notes = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => PlansCompanion.insert(
                id: id,
                name: name,
                notes: notes,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$PlansTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback: ({planSessionsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (planSessionsRefs) db.planSessions],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (planSessionsRefs)
                    await $_getPrefetchedData<Plan, $PlansTable, PlanSession>(
                      currentTable: table,
                      referencedTable: $$PlansTableReferences
                          ._planSessionsRefsTable(db),
                      managerFromTypedResult: (p0) => $$PlansTableReferences(
                        db,
                        table,
                        p0,
                      ).planSessionsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.planId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$PlansTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PlansTable,
      Plan,
      $$PlansTableFilterComposer,
      $$PlansTableOrderingComposer,
      $$PlansTableAnnotationComposer,
      $$PlansTableCreateCompanionBuilder,
      $$PlansTableUpdateCompanionBuilder,
      (Plan, $$PlansTableReferences),
      Plan,
      PrefetchHooks Function({bool planSessionsRefs})
    >;
typedef $$PlanSessionsTableCreateCompanionBuilder =
    PlanSessionsCompanion Function({
      Value<int> id,
      required String planId,
      required int weekNumber,
      required String day,
      required String sessionName,
      Value<DateTime?> assignedDate,
    });
typedef $$PlanSessionsTableUpdateCompanionBuilder =
    PlanSessionsCompanion Function({
      Value<int> id,
      Value<String> planId,
      Value<int> weekNumber,
      Value<String> day,
      Value<String> sessionName,
      Value<DateTime?> assignedDate,
    });

final class $$PlanSessionsTableReferences
    extends BaseReferences<_$AppDatabase, $PlanSessionsTable, PlanSession> {
  $$PlanSessionsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $PlansTable _planIdTable(_$AppDatabase db) =>
      db.plans.createAlias('plan_sessions__plan_id__plans__id');

  $$PlansTableProcessedTableManager get planId {
    final $_column = $_itemColumn<String>('plan_id')!;

    final manager = $$PlansTableTableManager(
      $_db,
      $_db.plans,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_planIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$PlanExercisesTable, List<PlanExercise>>
  _planExercisesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.planExercises,
    aliasName: 'plan_sessions__id__plan_exercises__session_id',
  );

  $$PlanExercisesTableProcessedTableManager get planExercisesRefs {
    final manager = $$PlanExercisesTableTableManager(
      $_db,
      $_db.planExercises,
    ).filter((f) => f.sessionId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_planExercisesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$PlanSessionsTableFilterComposer
    extends Composer<_$AppDatabase, $PlanSessionsTable> {
  $$PlanSessionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get weekNumber => $composableBuilder(
    column: $table.weekNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get day => $composableBuilder(
    column: $table.day,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sessionName => $composableBuilder(
    column: $table.sessionName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get assignedDate => $composableBuilder(
    column: $table.assignedDate,
    builder: (column) => ColumnFilters(column),
  );

  $$PlansTableFilterComposer get planId {
    final $$PlansTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.planId,
      referencedTable: $db.plans,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlansTableFilterComposer(
            $db: $db,
            $table: $db.plans,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> planExercisesRefs(
    Expression<bool> Function($$PlanExercisesTableFilterComposer f) f,
  ) {
    final $$PlanExercisesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.planExercises,
      getReferencedColumn: (t) => t.sessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlanExercisesTableFilterComposer(
            $db: $db,
            $table: $db.planExercises,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PlanSessionsTableOrderingComposer
    extends Composer<_$AppDatabase, $PlanSessionsTable> {
  $$PlanSessionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get weekNumber => $composableBuilder(
    column: $table.weekNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get day => $composableBuilder(
    column: $table.day,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sessionName => $composableBuilder(
    column: $table.sessionName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get assignedDate => $composableBuilder(
    column: $table.assignedDate,
    builder: (column) => ColumnOrderings(column),
  );

  $$PlansTableOrderingComposer get planId {
    final $$PlansTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.planId,
      referencedTable: $db.plans,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlansTableOrderingComposer(
            $db: $db,
            $table: $db.plans,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PlanSessionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PlanSessionsTable> {
  $$PlanSessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get weekNumber => $composableBuilder(
    column: $table.weekNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get day =>
      $composableBuilder(column: $table.day, builder: (column) => column);

  GeneratedColumn<String> get sessionName => $composableBuilder(
    column: $table.sessionName,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get assignedDate => $composableBuilder(
    column: $table.assignedDate,
    builder: (column) => column,
  );

  $$PlansTableAnnotationComposer get planId {
    final $$PlansTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.planId,
      referencedTable: $db.plans,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlansTableAnnotationComposer(
            $db: $db,
            $table: $db.plans,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> planExercisesRefs<T extends Object>(
    Expression<T> Function($$PlanExercisesTableAnnotationComposer a) f,
  ) {
    final $$PlanExercisesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.planExercises,
      getReferencedColumn: (t) => t.sessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlanExercisesTableAnnotationComposer(
            $db: $db,
            $table: $db.planExercises,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PlanSessionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PlanSessionsTable,
          PlanSession,
          $$PlanSessionsTableFilterComposer,
          $$PlanSessionsTableOrderingComposer,
          $$PlanSessionsTableAnnotationComposer,
          $$PlanSessionsTableCreateCompanionBuilder,
          $$PlanSessionsTableUpdateCompanionBuilder,
          (PlanSession, $$PlanSessionsTableReferences),
          PlanSession,
          PrefetchHooks Function({bool planId, bool planExercisesRefs})
        > {
  $$PlanSessionsTableTableManager(_$AppDatabase db, $PlanSessionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlanSessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlanSessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PlanSessionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> planId = const Value.absent(),
                Value<int> weekNumber = const Value.absent(),
                Value<String> day = const Value.absent(),
                Value<String> sessionName = const Value.absent(),
                Value<DateTime?> assignedDate = const Value.absent(),
              }) => PlanSessionsCompanion(
                id: id,
                planId: planId,
                weekNumber: weekNumber,
                day: day,
                sessionName: sessionName,
                assignedDate: assignedDate,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String planId,
                required int weekNumber,
                required String day,
                required String sessionName,
                Value<DateTime?> assignedDate = const Value.absent(),
              }) => PlanSessionsCompanion.insert(
                id: id,
                planId: planId,
                weekNumber: weekNumber,
                day: day,
                sessionName: sessionName,
                assignedDate: assignedDate,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$PlanSessionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({planId = false, planExercisesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (planExercisesRefs) db.planExercises,
              ],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (planId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.planId,
                        referencedTable: $$PlanSessionsTableReferences
                            ._planIdTable(db),
                        referencedColumn: $$PlanSessionsTableReferences
                            ._planIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (planExercisesRefs)
                    await $_getPrefetchedData<
                      PlanSession,
                      $PlanSessionsTable,
                      PlanExercise
                    >(
                      currentTable: table,
                      referencedTable: $$PlanSessionsTableReferences
                          ._planExercisesRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$PlanSessionsTableReferences(
                            db,
                            table,
                            p0,
                          ).planExercisesRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.sessionId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$PlanSessionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PlanSessionsTable,
      PlanSession,
      $$PlanSessionsTableFilterComposer,
      $$PlanSessionsTableOrderingComposer,
      $$PlanSessionsTableAnnotationComposer,
      $$PlanSessionsTableCreateCompanionBuilder,
      $$PlanSessionsTableUpdateCompanionBuilder,
      (PlanSession, $$PlanSessionsTableReferences),
      PlanSession,
      PrefetchHooks Function({bool planId, bool planExercisesRefs})
    >;
typedef $$PlanExercisesTableCreateCompanionBuilder =
    PlanExercisesCompanion Function({
      Value<int> id,
      required int sessionId,
      required int order,
      Value<String?> exerciseId,
      required String exerciseName,
      required int sets,
      required String reps,
      Value<String> weightIntensity,
      Value<int?> restSec,
      Value<String> notes,
      Value<String> videoUrl,
    });
typedef $$PlanExercisesTableUpdateCompanionBuilder =
    PlanExercisesCompanion Function({
      Value<int> id,
      Value<int> sessionId,
      Value<int> order,
      Value<String?> exerciseId,
      Value<String> exerciseName,
      Value<int> sets,
      Value<String> reps,
      Value<String> weightIntensity,
      Value<int?> restSec,
      Value<String> notes,
      Value<String> videoUrl,
    });

final class $$PlanExercisesTableReferences
    extends BaseReferences<_$AppDatabase, $PlanExercisesTable, PlanExercise> {
  $$PlanExercisesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $PlanSessionsTable _sessionIdTable(_$AppDatabase db) => db.planSessions
      .createAlias('plan_exercises__session_id__plan_sessions__id');

  $$PlanSessionsTableProcessedTableManager get sessionId {
    final $_column = $_itemColumn<int>('session_id')!;

    final manager = $$PlanSessionsTableTableManager(
      $_db,
      $_db.planSessions,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_sessionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $ExercisesTable _exerciseIdTable(_$AppDatabase db) =>
      db.exercises.createAlias('plan_exercises__exercise_id__exercises__id');

  $$ExercisesTableProcessedTableManager? get exerciseId {
    final $_column = $_itemColumn<String>('exercise_id');
    if ($_column == null) return null;
    final manager = $$ExercisesTableTableManager(
      $_db,
      $_db.exercises,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_exerciseIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$PlanExercisesTableFilterComposer
    extends Composer<_$AppDatabase, $PlanExercisesTable> {
  $$PlanExercisesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get order => $composableBuilder(
    column: $table.order,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get exerciseName => $composableBuilder(
    column: $table.exerciseName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sets => $composableBuilder(
    column: $table.sets,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reps => $composableBuilder(
    column: $table.reps,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get weightIntensity => $composableBuilder(
    column: $table.weightIntensity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get restSec => $composableBuilder(
    column: $table.restSec,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get videoUrl => $composableBuilder(
    column: $table.videoUrl,
    builder: (column) => ColumnFilters(column),
  );

  $$PlanSessionsTableFilterComposer get sessionId {
    final $$PlanSessionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.planSessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlanSessionsTableFilterComposer(
            $db: $db,
            $table: $db.planSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ExercisesTableFilterComposer get exerciseId {
    final $$ExercisesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.exerciseId,
      referencedTable: $db.exercises,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExercisesTableFilterComposer(
            $db: $db,
            $table: $db.exercises,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PlanExercisesTableOrderingComposer
    extends Composer<_$AppDatabase, $PlanExercisesTable> {
  $$PlanExercisesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get order => $composableBuilder(
    column: $table.order,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get exerciseName => $composableBuilder(
    column: $table.exerciseName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sets => $composableBuilder(
    column: $table.sets,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reps => $composableBuilder(
    column: $table.reps,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get weightIntensity => $composableBuilder(
    column: $table.weightIntensity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get restSec => $composableBuilder(
    column: $table.restSec,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get videoUrl => $composableBuilder(
    column: $table.videoUrl,
    builder: (column) => ColumnOrderings(column),
  );

  $$PlanSessionsTableOrderingComposer get sessionId {
    final $$PlanSessionsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.planSessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlanSessionsTableOrderingComposer(
            $db: $db,
            $table: $db.planSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ExercisesTableOrderingComposer get exerciseId {
    final $$ExercisesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.exerciseId,
      referencedTable: $db.exercises,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExercisesTableOrderingComposer(
            $db: $db,
            $table: $db.exercises,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PlanExercisesTableAnnotationComposer
    extends Composer<_$AppDatabase, $PlanExercisesTable> {
  $$PlanExercisesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get order =>
      $composableBuilder(column: $table.order, builder: (column) => column);

  GeneratedColumn<String> get exerciseName => $composableBuilder(
    column: $table.exerciseName,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sets =>
      $composableBuilder(column: $table.sets, builder: (column) => column);

  GeneratedColumn<String> get reps =>
      $composableBuilder(column: $table.reps, builder: (column) => column);

  GeneratedColumn<String> get weightIntensity => $composableBuilder(
    column: $table.weightIntensity,
    builder: (column) => column,
  );

  GeneratedColumn<int> get restSec =>
      $composableBuilder(column: $table.restSec, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<String> get videoUrl =>
      $composableBuilder(column: $table.videoUrl, builder: (column) => column);

  $$PlanSessionsTableAnnotationComposer get sessionId {
    final $$PlanSessionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.planSessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlanSessionsTableAnnotationComposer(
            $db: $db,
            $table: $db.planSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ExercisesTableAnnotationComposer get exerciseId {
    final $$ExercisesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.exerciseId,
      referencedTable: $db.exercises,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExercisesTableAnnotationComposer(
            $db: $db,
            $table: $db.exercises,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PlanExercisesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PlanExercisesTable,
          PlanExercise,
          $$PlanExercisesTableFilterComposer,
          $$PlanExercisesTableOrderingComposer,
          $$PlanExercisesTableAnnotationComposer,
          $$PlanExercisesTableCreateCompanionBuilder,
          $$PlanExercisesTableUpdateCompanionBuilder,
          (PlanExercise, $$PlanExercisesTableReferences),
          PlanExercise,
          PrefetchHooks Function({bool sessionId, bool exerciseId})
        > {
  $$PlanExercisesTableTableManager(_$AppDatabase db, $PlanExercisesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlanExercisesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlanExercisesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PlanExercisesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> sessionId = const Value.absent(),
                Value<int> order = const Value.absent(),
                Value<String?> exerciseId = const Value.absent(),
                Value<String> exerciseName = const Value.absent(),
                Value<int> sets = const Value.absent(),
                Value<String> reps = const Value.absent(),
                Value<String> weightIntensity = const Value.absent(),
                Value<int?> restSec = const Value.absent(),
                Value<String> notes = const Value.absent(),
                Value<String> videoUrl = const Value.absent(),
              }) => PlanExercisesCompanion(
                id: id,
                sessionId: sessionId,
                order: order,
                exerciseId: exerciseId,
                exerciseName: exerciseName,
                sets: sets,
                reps: reps,
                weightIntensity: weightIntensity,
                restSec: restSec,
                notes: notes,
                videoUrl: videoUrl,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int sessionId,
                required int order,
                Value<String?> exerciseId = const Value.absent(),
                required String exerciseName,
                required int sets,
                required String reps,
                Value<String> weightIntensity = const Value.absent(),
                Value<int?> restSec = const Value.absent(),
                Value<String> notes = const Value.absent(),
                Value<String> videoUrl = const Value.absent(),
              }) => PlanExercisesCompanion.insert(
                id: id,
                sessionId: sessionId,
                order: order,
                exerciseId: exerciseId,
                exerciseName: exerciseName,
                sets: sets,
                reps: reps,
                weightIntensity: weightIntensity,
                restSec: restSec,
                notes: notes,
                videoUrl: videoUrl,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$PlanExercisesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({sessionId = false, exerciseId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (sessionId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.sessionId,
                        referencedTable: $$PlanExercisesTableReferences
                            ._sessionIdTable(db),
                        referencedColumn: $$PlanExercisesTableReferences
                            ._sessionIdTable(db)
                            .id,
                      ) as T;
                    }
                    if (exerciseId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.exerciseId,
                        referencedTable: $$PlanExercisesTableReferences
                            ._exerciseIdTable(db),
                        referencedColumn: $$PlanExercisesTableReferences
                            ._exerciseIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$PlanExercisesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PlanExercisesTable,
      PlanExercise,
      $$PlanExercisesTableFilterComposer,
      $$PlanExercisesTableOrderingComposer,
      $$PlanExercisesTableAnnotationComposer,
      $$PlanExercisesTableCreateCompanionBuilder,
      $$PlanExercisesTableUpdateCompanionBuilder,
      (PlanExercise, $$PlanExercisesTableReferences),
      PlanExercise,
      PrefetchHooks Function({bool sessionId, bool exerciseId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ExercisesTableTableManager get exercises =>
      $$ExercisesTableTableManager(_db, _db.exercises);
  $$PlansTableTableManager get plans =>
      $$PlansTableTableManager(_db, _db.plans);
  $$PlanSessionsTableTableManager get planSessions =>
      $$PlanSessionsTableTableManager(_db, _db.planSessions);
  $$PlanExercisesTableTableManager get planExercises =>
      $$PlanExercisesTableTableManager(_db, _db.planExercises);
}
