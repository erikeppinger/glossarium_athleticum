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
  static const VerificationMeta _sourcePlanNameMeta = const VerificationMeta(
    'sourcePlanName',
  );
  @override
  late final GeneratedColumn<String> sourcePlanName = GeneratedColumn<String>(
    'source_plan_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _authorMeta = const VerificationMeta('author');
  @override
  late final GeneratedColumn<String> author = GeneratedColumn<String>(
    'author',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _imagePathMeta = const VerificationMeta(
    'imagePath',
  );
  @override
  late final GeneratedColumn<String> imagePath = GeneratedColumn<String>(
    'image_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _imagePathsMeta = const VerificationMeta(
    'imagePaths',
  );
  @override
  late final GeneratedColumn<String> imagePaths = GeneratedColumn<String>(
    'image_paths',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isFavoriteMeta = const VerificationMeta(
    'isFavorite',
  );
  @override
  late final GeneratedColumn<bool> isFavorite = GeneratedColumn<bool>(
    'is_favorite',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_favorite" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _embeddingAllowedMeta = const VerificationMeta(
    'embeddingAllowed',
  );
  @override
  late final GeneratedColumn<bool> embeddingAllowed = GeneratedColumn<bool>(
    'embedding_allowed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("embedding_allowed" IN (0, 1))',
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
    sourcePlanName,
    author,
    imagePath,
    imagePaths,
    isFavorite,
    embeddingAllowed,
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
    if (data.containsKey('source_plan_name')) {
      context.handle(
        _sourcePlanNameMeta,
        sourcePlanName.isAcceptableOrUnknown(
          data['source_plan_name']!,
          _sourcePlanNameMeta,
        ),
      );
    }
    if (data.containsKey('author')) {
      context.handle(
        _authorMeta,
        author.isAcceptableOrUnknown(data['author']!, _authorMeta),
      );
    }
    if (data.containsKey('image_path')) {
      context.handle(
        _imagePathMeta,
        imagePath.isAcceptableOrUnknown(data['image_path']!, _imagePathMeta),
      );
    }
    if (data.containsKey('image_paths')) {
      context.handle(
        _imagePathsMeta,
        imagePaths.isAcceptableOrUnknown(data['image_paths']!, _imagePathsMeta),
      );
    }
    if (data.containsKey('is_favorite')) {
      context.handle(
        _isFavoriteMeta,
        isFavorite.isAcceptableOrUnknown(data['is_favorite']!, _isFavoriteMeta),
      );
    }
    if (data.containsKey('embedding_allowed')) {
      context.handle(
        _embeddingAllowedMeta,
        embeddingAllowed.isAcceptableOrUnknown(
          data['embedding_allowed']!,
          _embeddingAllowedMeta,
        ),
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
      sourcePlanName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_plan_name'],
      ),
      author: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}author'],
      ),
      imagePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}image_path'],
      ),
      imagePaths: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}image_paths'],
      ),
      isFavorite: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_favorite'],
      )!,
      embeddingAllowed: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}embedding_allowed'],
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

  /// Name of the plan whose import/creation flow created this exercise, if
  /// any - a snapshot (not a foreign key) so it survives that plan being
  /// deleted later. Null for seed-library exercises and ones created
  /// standalone via `create_exercise_screen.dart`.
  final String? sourcePlanName;

  /// Free-text creator/author name (e.g. a coach's name), optionally set
  /// when creating a custom exercise. Null if not provided.
  final String? author;

  /// Deprecated - superseded by [imagePaths] below (a single exercise can now
  /// have up to `maxExerciseImages` photos, see lib/logic/exercise_images.dart).
  /// Kept only so a very old exported plan/backup JSON's single `image_path`
  /// field still has somewhere to land on import; every current read/write
  /// site uses [imagePaths] instead. Never written by anything but the
  /// schema 11->12 migration's one-time backfill.
  final String? imagePath;

  /// Comma-separated filenames (relative to the attachments directory, see
  /// lib/data/local_storage.dart - not absolute paths, because the app's
  /// sandbox path changes across reinstalls and OS upgrades) of up to
  /// `maxExerciseImages` user-attached photos, in display order. Null/empty
  /// when none are attached.
  ///
  /// Deliberately user-supplied rather than bundled stock imagery: shipping
  /// scraped exercise photos would be a licensing problem for anyone
  /// publishing the app, and a user's own photos of their actual setup are
  /// more useful anyway.
  final String? imagePaths;

  /// Starred by the user for quick access via the "Favorites only" filter
  /// chip on the Exercise Library screen - purely a personal-device
  /// convenience, not part of any exported plan/backup JSON.
  final bool isFavorite;

  /// Opt-in to show [videoReference] as an embedded player (YouTube only -
  /// see lib/logic/video_embedding.dart) instead of just a tappable link.
  /// Defaults to false: embedding is never turned on implicitly, including
  /// on import, since whoever adds a video is asserting they have the right
  /// to embed it - see docs/DISCLAIMER.md's "Embedded video" section. This
  /// travels with the exercise through export/import/backup exactly like
  /// [videoReference] itself, so a shared library preserves the author's
  /// own choice rather than resetting it.
  final bool embeddingAllowed;
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
    this.sourcePlanName,
    this.author,
    this.imagePath,
    this.imagePaths,
    required this.isFavorite,
    required this.embeddingAllowed,
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
    if (!nullToAbsent || sourcePlanName != null) {
      map['source_plan_name'] = Variable<String>(sourcePlanName);
    }
    if (!nullToAbsent || author != null) {
      map['author'] = Variable<String>(author);
    }
    if (!nullToAbsent || imagePath != null) {
      map['image_path'] = Variable<String>(imagePath);
    }
    if (!nullToAbsent || imagePaths != null) {
      map['image_paths'] = Variable<String>(imagePaths);
    }
    map['is_favorite'] = Variable<bool>(isFavorite);
    map['embedding_allowed'] = Variable<bool>(embeddingAllowed);
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
      sourcePlanName: sourcePlanName == null && nullToAbsent
          ? const Value.absent()
          : Value(sourcePlanName),
      author: author == null && nullToAbsent
          ? const Value.absent()
          : Value(author),
      imagePath: imagePath == null && nullToAbsent
          ? const Value.absent()
          : Value(imagePath),
      imagePaths: imagePaths == null && nullToAbsent
          ? const Value.absent()
          : Value(imagePaths),
      isFavorite: Value(isFavorite),
      embeddingAllowed: Value(embeddingAllowed),
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
      sourcePlanName: serializer.fromJson<String?>(json['sourcePlanName']),
      author: serializer.fromJson<String?>(json['author']),
      imagePath: serializer.fromJson<String?>(json['imagePath']),
      imagePaths: serializer.fromJson<String?>(json['imagePaths']),
      isFavorite: serializer.fromJson<bool>(json['isFavorite']),
      embeddingAllowed: serializer.fromJson<bool>(json['embeddingAllowed']),
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
      'sourcePlanName': serializer.toJson<String?>(sourcePlanName),
      'author': serializer.toJson<String?>(author),
      'imagePath': serializer.toJson<String?>(imagePath),
      'imagePaths': serializer.toJson<String?>(imagePaths),
      'isFavorite': serializer.toJson<bool>(isFavorite),
      'embeddingAllowed': serializer.toJson<bool>(embeddingAllowed),
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
    Value<String?> sourcePlanName = const Value.absent(),
    Value<String?> author = const Value.absent(),
    Value<String?> imagePath = const Value.absent(),
    Value<String?> imagePaths = const Value.absent(),
    bool? isFavorite,
    bool? embeddingAllowed,
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
    sourcePlanName: sourcePlanName.present
        ? sourcePlanName.value
        : this.sourcePlanName,
    author: author.present ? author.value : this.author,
    imagePath: imagePath.present ? imagePath.value : this.imagePath,
    imagePaths: imagePaths.present ? imagePaths.value : this.imagePaths,
    isFavorite: isFavorite ?? this.isFavorite,
    embeddingAllowed: embeddingAllowed ?? this.embeddingAllowed,
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
      sourcePlanName: data.sourcePlanName.present
          ? data.sourcePlanName.value
          : this.sourcePlanName,
      author: data.author.present ? data.author.value : this.author,
      imagePath: data.imagePath.present ? data.imagePath.value : this.imagePath,
      imagePaths: data.imagePaths.present
          ? data.imagePaths.value
          : this.imagePaths,
      isFavorite: data.isFavorite.present
          ? data.isFavorite.value
          : this.isFavorite,
      embeddingAllowed: data.embeddingAllowed.present
          ? data.embeddingAllowed.value
          : this.embeddingAllowed,
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
          ..write('isCustom: $isCustom, ')
          ..write('sourcePlanName: $sourcePlanName, ')
          ..write('author: $author, ')
          ..write('imagePath: $imagePath, ')
          ..write('imagePaths: $imagePaths, ')
          ..write('isFavorite: $isFavorite, ')
          ..write('embeddingAllowed: $embeddingAllowed')
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
    sourcePlanName,
    author,
    imagePath,
    imagePaths,
    isFavorite,
    embeddingAllowed,
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
          other.isCustom == this.isCustom &&
          other.sourcePlanName == this.sourcePlanName &&
          other.author == this.author &&
          other.imagePath == this.imagePath &&
          other.imagePaths == this.imagePaths &&
          other.isFavorite == this.isFavorite &&
          other.embeddingAllowed == this.embeddingAllowed);
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
  final Value<String?> sourcePlanName;
  final Value<String?> author;
  final Value<String?> imagePath;
  final Value<String?> imagePaths;
  final Value<bool> isFavorite;
  final Value<bool> embeddingAllowed;
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
    this.sourcePlanName = const Value.absent(),
    this.author = const Value.absent(),
    this.imagePath = const Value.absent(),
    this.imagePaths = const Value.absent(),
    this.isFavorite = const Value.absent(),
    this.embeddingAllowed = const Value.absent(),
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
    this.sourcePlanName = const Value.absent(),
    this.author = const Value.absent(),
    this.imagePath = const Value.absent(),
    this.imagePaths = const Value.absent(),
    this.isFavorite = const Value.absent(),
    this.embeddingAllowed = const Value.absent(),
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
    Expression<String>? sourcePlanName,
    Expression<String>? author,
    Expression<String>? imagePath,
    Expression<String>? imagePaths,
    Expression<bool>? isFavorite,
    Expression<bool>? embeddingAllowed,
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
      if (sourcePlanName != null) 'source_plan_name': sourcePlanName,
      if (author != null) 'author': author,
      if (imagePath != null) 'image_path': imagePath,
      if (imagePaths != null) 'image_paths': imagePaths,
      if (isFavorite != null) 'is_favorite': isFavorite,
      if (embeddingAllowed != null) 'embedding_allowed': embeddingAllowed,
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
    Value<String?>? sourcePlanName,
    Value<String?>? author,
    Value<String?>? imagePath,
    Value<String?>? imagePaths,
    Value<bool>? isFavorite,
    Value<bool>? embeddingAllowed,
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
      sourcePlanName: sourcePlanName ?? this.sourcePlanName,
      author: author ?? this.author,
      imagePath: imagePath ?? this.imagePath,
      imagePaths: imagePaths ?? this.imagePaths,
      isFavorite: isFavorite ?? this.isFavorite,
      embeddingAllowed: embeddingAllowed ?? this.embeddingAllowed,
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
    if (sourcePlanName.present) {
      map['source_plan_name'] = Variable<String>(sourcePlanName.value);
    }
    if (author.present) {
      map['author'] = Variable<String>(author.value);
    }
    if (imagePath.present) {
      map['image_path'] = Variable<String>(imagePath.value);
    }
    if (imagePaths.present) {
      map['image_paths'] = Variable<String>(imagePaths.value);
    }
    if (isFavorite.present) {
      map['is_favorite'] = Variable<bool>(isFavorite.value);
    }
    if (embeddingAllowed.present) {
      map['embedding_allowed'] = Variable<bool>(embeddingAllowed.value);
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
          ..write('sourcePlanName: $sourcePlanName, ')
          ..write('author: $author, ')
          ..write('imagePath: $imagePath, ')
          ..write('imagePaths: $imagePaths, ')
          ..write('isFavorite: $isFavorite, ')
          ..write('embeddingAllowed: $embeddingAllowed, ')
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
  static const VerificationMeta _createdByMeta = const VerificationMeta(
    'createdBy',
  );
  @override
  late final GeneratedColumn<String> createdBy = GeneratedColumn<String>(
    'created_by',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
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
  static const VerificationMeta _archivedAtMeta = const VerificationMeta(
    'archivedAt',
  );
  @override
  late final GeneratedColumn<DateTime> archivedAt = GeneratedColumn<DateTime>(
    'archived_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _reportPreferenceMeta = const VerificationMeta(
    'reportPreference',
  );
  @override
  late final GeneratedColumn<String> reportPreference = GeneratedColumn<String>(
    'report_preference',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('notAsked'),
  );
  static const VerificationMeta _reportFrequencyDaysMeta =
      const VerificationMeta('reportFrequencyDays');
  @override
  late final GeneratedColumn<int> reportFrequencyDays = GeneratedColumn<int>(
    'report_frequency_days',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _reportOptInAtMeta = const VerificationMeta(
    'reportOptInAt',
  );
  @override
  late final GeneratedColumn<DateTime> reportOptInAt =
      GeneratedColumn<DateTime>(
        'report_opt_in_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    notes,
    createdBy,
    createdAt,
    updatedAt,
    archivedAt,
    reportPreference,
    reportFrequencyDays,
    reportOptInAt,
  ];
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
    if (data.containsKey('created_by')) {
      context.handle(
        _createdByMeta,
        createdBy.isAcceptableOrUnknown(data['created_by']!, _createdByMeta),
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
    if (data.containsKey('archived_at')) {
      context.handle(
        _archivedAtMeta,
        archivedAt.isAcceptableOrUnknown(data['archived_at']!, _archivedAtMeta),
      );
    }
    if (data.containsKey('report_preference')) {
      context.handle(
        _reportPreferenceMeta,
        reportPreference.isAcceptableOrUnknown(
          data['report_preference']!,
          _reportPreferenceMeta,
        ),
      );
    }
    if (data.containsKey('report_frequency_days')) {
      context.handle(
        _reportFrequencyDaysMeta,
        reportFrequencyDays.isAcceptableOrUnknown(
          data['report_frequency_days']!,
          _reportFrequencyDaysMeta,
        ),
      );
    }
    if (data.containsKey('report_opt_in_at')) {
      context.handle(
        _reportOptInAtMeta,
        reportOptInAt.isAcceptableOrUnknown(
          data['report_opt_in_at']!,
          _reportOptInAtMeta,
        ),
      );
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
      createdBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_by'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      archivedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}archived_at'],
      ),
      reportPreference: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}report_preference'],
      )!,
      reportFrequencyDays: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}report_frequency_days'],
      ),
      reportOptInAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}report_opt_in_at'],
      ),
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

  /// Who authored this plan (e.g. a trainer's name), for a plan handed off
  /// as a file to someone else to train from - purely free text, no real
  /// identity/account system behind it (this app has none). Null for a plan
  /// someone built for themselves, which is the common case and has no
  /// "author" worth stating. Unlike `Exercises.author`/`sourcePlanName`
  /// (which get *regenerated* per import - see `plan_json_import.dart`),
  /// this round-trips the original value through export/import unchanged,
  /// since the whole point is a trainer's name surviving the handoff to a
  /// client's device.
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Set when the plan is archived - hidden from the plan list but fully
  /// intact and restorable. Archiving is the reversible way to get a plan
  /// out of the way; deleting is the irreversible one. Null = active.
  final DateTime? archivedAt;

  /// Tri-state opt-in for a periodic "check your progress on this plan"
  /// reminder - 'notAsked'/'enabled'/'declined', same reasoning as
  /// `BodyTracking`: a "no" is remembered rather than asked again. Per-plan
  /// (not a device-wide setting, unlike the existing weekly-digest
  /// notification) since interest in check-ins can differ per plan. Asked
  /// once at first session start - see plan_report_prompt.dart.
  final String reportPreference;

  /// Days between reminders once enabled (7/14/30 offered at opt-in time) -
  /// null until enabled.
  final int? reportFrequencyDays;

  /// When the plan owner opted in - the anchor point reminders are computed
  /// from each time they're rebuilt, so "every 7 days" means every 7 days
  /// from when they said yes, not from some arbitrary fixed epoch.
  final DateTime? reportOptInAt;
  const Plan({
    required this.id,
    required this.name,
    required this.notes,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.archivedAt,
    required this.reportPreference,
    this.reportFrequencyDays,
    this.reportOptInAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['notes'] = Variable<String>(notes);
    if (!nullToAbsent || createdBy != null) {
      map['created_by'] = Variable<String>(createdBy);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || archivedAt != null) {
      map['archived_at'] = Variable<DateTime>(archivedAt);
    }
    map['report_preference'] = Variable<String>(reportPreference);
    if (!nullToAbsent || reportFrequencyDays != null) {
      map['report_frequency_days'] = Variable<int>(reportFrequencyDays);
    }
    if (!nullToAbsent || reportOptInAt != null) {
      map['report_opt_in_at'] = Variable<DateTime>(reportOptInAt);
    }
    return map;
  }

  PlansCompanion toCompanion(bool nullToAbsent) {
    return PlansCompanion(
      id: Value(id),
      name: Value(name),
      notes: Value(notes),
      createdBy: createdBy == null && nullToAbsent
          ? const Value.absent()
          : Value(createdBy),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      archivedAt: archivedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(archivedAt),
      reportPreference: Value(reportPreference),
      reportFrequencyDays: reportFrequencyDays == null && nullToAbsent
          ? const Value.absent()
          : Value(reportFrequencyDays),
      reportOptInAt: reportOptInAt == null && nullToAbsent
          ? const Value.absent()
          : Value(reportOptInAt),
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
      createdBy: serializer.fromJson<String?>(json['createdBy']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      archivedAt: serializer.fromJson<DateTime?>(json['archivedAt']),
      reportPreference: serializer.fromJson<String>(json['reportPreference']),
      reportFrequencyDays: serializer.fromJson<int?>(
        json['reportFrequencyDays'],
      ),
      reportOptInAt: serializer.fromJson<DateTime?>(json['reportOptInAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'notes': serializer.toJson<String>(notes),
      'createdBy': serializer.toJson<String?>(createdBy),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'archivedAt': serializer.toJson<DateTime?>(archivedAt),
      'reportPreference': serializer.toJson<String>(reportPreference),
      'reportFrequencyDays': serializer.toJson<int?>(reportFrequencyDays),
      'reportOptInAt': serializer.toJson<DateTime?>(reportOptInAt),
    };
  }

  Plan copyWith({
    String? id,
    String? name,
    String? notes,
    Value<String?> createdBy = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> archivedAt = const Value.absent(),
    String? reportPreference,
    Value<int?> reportFrequencyDays = const Value.absent(),
    Value<DateTime?> reportOptInAt = const Value.absent(),
  }) => Plan(
    id: id ?? this.id,
    name: name ?? this.name,
    notes: notes ?? this.notes,
    createdBy: createdBy.present ? createdBy.value : this.createdBy,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    archivedAt: archivedAt.present ? archivedAt.value : this.archivedAt,
    reportPreference: reportPreference ?? this.reportPreference,
    reportFrequencyDays: reportFrequencyDays.present
        ? reportFrequencyDays.value
        : this.reportFrequencyDays,
    reportOptInAt: reportOptInAt.present
        ? reportOptInAt.value
        : this.reportOptInAt,
  );
  Plan copyWithCompanion(PlansCompanion data) {
    return Plan(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      notes: data.notes.present ? data.notes.value : this.notes,
      createdBy: data.createdBy.present ? data.createdBy.value : this.createdBy,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      archivedAt: data.archivedAt.present
          ? data.archivedAt.value
          : this.archivedAt,
      reportPreference: data.reportPreference.present
          ? data.reportPreference.value
          : this.reportPreference,
      reportFrequencyDays: data.reportFrequencyDays.present
          ? data.reportFrequencyDays.value
          : this.reportFrequencyDays,
      reportOptInAt: data.reportOptInAt.present
          ? data.reportOptInAt.value
          : this.reportOptInAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Plan(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('notes: $notes, ')
          ..write('createdBy: $createdBy, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('archivedAt: $archivedAt, ')
          ..write('reportPreference: $reportPreference, ')
          ..write('reportFrequencyDays: $reportFrequencyDays, ')
          ..write('reportOptInAt: $reportOptInAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    notes,
    createdBy,
    createdAt,
    updatedAt,
    archivedAt,
    reportPreference,
    reportFrequencyDays,
    reportOptInAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Plan &&
          other.id == this.id &&
          other.name == this.name &&
          other.notes == this.notes &&
          other.createdBy == this.createdBy &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.archivedAt == this.archivedAt &&
          other.reportPreference == this.reportPreference &&
          other.reportFrequencyDays == this.reportFrequencyDays &&
          other.reportOptInAt == this.reportOptInAt);
}

class PlansCompanion extends UpdateCompanion<Plan> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> notes;
  final Value<String?> createdBy;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> archivedAt;
  final Value<String> reportPreference;
  final Value<int?> reportFrequencyDays;
  final Value<DateTime?> reportOptInAt;
  final Value<int> rowid;
  const PlansCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdBy = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.archivedAt = const Value.absent(),
    this.reportPreference = const Value.absent(),
    this.reportFrequencyDays = const Value.absent(),
    this.reportOptInAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PlansCompanion.insert({
    required String id,
    required String name,
    this.notes = const Value.absent(),
    this.createdBy = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.archivedAt = const Value.absent(),
    this.reportPreference = const Value.absent(),
    this.reportFrequencyDays = const Value.absent(),
    this.reportOptInAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<Plan> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? notes,
    Expression<String>? createdBy,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? archivedAt,
    Expression<String>? reportPreference,
    Expression<int>? reportFrequencyDays,
    Expression<DateTime>? reportOptInAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (notes != null) 'notes': notes,
      if (createdBy != null) 'created_by': createdBy,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (archivedAt != null) 'archived_at': archivedAt,
      if (reportPreference != null) 'report_preference': reportPreference,
      if (reportFrequencyDays != null)
        'report_frequency_days': reportFrequencyDays,
      if (reportOptInAt != null) 'report_opt_in_at': reportOptInAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PlansCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? notes,
    Value<String?>? createdBy,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? archivedAt,
    Value<String>? reportPreference,
    Value<int?>? reportFrequencyDays,
    Value<DateTime?>? reportOptInAt,
    Value<int>? rowid,
  }) {
    return PlansCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      notes: notes ?? this.notes,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      archivedAt: archivedAt ?? this.archivedAt,
      reportPreference: reportPreference ?? this.reportPreference,
      reportFrequencyDays: reportFrequencyDays ?? this.reportFrequencyDays,
      reportOptInAt: reportOptInAt ?? this.reportOptInAt,
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
    if (createdBy.present) {
      map['created_by'] = Variable<String>(createdBy.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (archivedAt.present) {
      map['archived_at'] = Variable<DateTime>(archivedAt.value);
    }
    if (reportPreference.present) {
      map['report_preference'] = Variable<String>(reportPreference.value);
    }
    if (reportFrequencyDays.present) {
      map['report_frequency_days'] = Variable<int>(reportFrequencyDays.value);
    }
    if (reportOptInAt.present) {
      map['report_opt_in_at'] = Variable<DateTime>(reportOptInAt.value);
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
          ..write('createdBy: $createdBy, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('archivedAt: $archivedAt, ')
          ..write('reportPreference: $reportPreference, ')
          ..write('reportFrequencyDays: $reportFrequencyDays, ')
          ..write('reportOptInAt: $reportOptInAt, ')
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
  @override
  List<GeneratedColumn> get $columns => [
    id,
    planId,
    weekNumber,
    day,
    sessionName,
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
  const PlanSession({
    required this.id,
    required this.planId,
    required this.weekNumber,
    required this.day,
    required this.sessionName,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['plan_id'] = Variable<String>(planId);
    map['week_number'] = Variable<int>(weekNumber);
    map['day'] = Variable<String>(day);
    map['session_name'] = Variable<String>(sessionName);
    return map;
  }

  PlanSessionsCompanion toCompanion(bool nullToAbsent) {
    return PlanSessionsCompanion(
      id: Value(id),
      planId: Value(planId),
      weekNumber: Value(weekNumber),
      day: Value(day),
      sessionName: Value(sessionName),
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
    };
  }

  PlanSession copyWith({
    int? id,
    String? planId,
    int? weekNumber,
    String? day,
    String? sessionName,
  }) => PlanSession(
    id: id ?? this.id,
    planId: planId ?? this.planId,
    weekNumber: weekNumber ?? this.weekNumber,
    day: day ?? this.day,
    sessionName: sessionName ?? this.sessionName,
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
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlanSession(')
          ..write('id: $id, ')
          ..write('planId: $planId, ')
          ..write('weekNumber: $weekNumber, ')
          ..write('day: $day, ')
          ..write('sessionName: $sessionName')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, planId, weekNumber, day, sessionName);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlanSession &&
          other.id == this.id &&
          other.planId == this.planId &&
          other.weekNumber == this.weekNumber &&
          other.day == this.day &&
          other.sessionName == this.sessionName);
}

class PlanSessionsCompanion extends UpdateCompanion<PlanSession> {
  final Value<int> id;
  final Value<String> planId;
  final Value<int> weekNumber;
  final Value<String> day;
  final Value<String> sessionName;
  const PlanSessionsCompanion({
    this.id = const Value.absent(),
    this.planId = const Value.absent(),
    this.weekNumber = const Value.absent(),
    this.day = const Value.absent(),
    this.sessionName = const Value.absent(),
  });
  PlanSessionsCompanion.insert({
    this.id = const Value.absent(),
    required String planId,
    required int weekNumber,
    required String day,
    required String sessionName,
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
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (planId != null) 'plan_id': planId,
      if (weekNumber != null) 'week_number': weekNumber,
      if (day != null) 'day': day,
      if (sessionName != null) 'session_name': sessionName,
    });
  }

  PlanSessionsCompanion copyWith({
    Value<int>? id,
    Value<String>? planId,
    Value<int>? weekNumber,
    Value<String>? day,
    Value<String>? sessionName,
  }) {
    return PlanSessionsCompanion(
      id: id ?? this.id,
      planId: planId ?? this.planId,
      weekNumber: weekNumber ?? this.weekNumber,
      day: day ?? this.day,
      sessionName: sessionName ?? this.sessionName,
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
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlanSessionsCompanion(')
          ..write('id: $id, ')
          ..write('planId: $planId, ')
          ..write('weekNumber: $weekNumber, ')
          ..write('day: $day, ')
          ..write('sessionName: $sessionName')
          ..write(')'))
        .toString();
  }
}

class $PlanSessionDatesTable extends PlanSessionDates
    with TableInfo<$PlanSessionDatesTable, PlanSessionDate> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlanSessionDatesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, sessionId, date];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'plan_session_dates';
  @override
  VerificationContext validateIntegrity(
    Insertable<PlanSessionDate> instance, {
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
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PlanSessionDate map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PlanSessionDate(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}session_id'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date'],
      )!,
    );
  }

  @override
  $PlanSessionDatesTable createAlias(String alias) {
    return $PlanSessionDatesTable(attachedDatabase, alias);
  }
}

class PlanSessionDate extends DataClass implements Insertable<PlanSessionDate> {
  final int id;
  final int sessionId;
  final DateTime date;
  const PlanSessionDate({
    required this.id,
    required this.sessionId,
    required this.date,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['session_id'] = Variable<int>(sessionId);
    map['date'] = Variable<DateTime>(date);
    return map;
  }

  PlanSessionDatesCompanion toCompanion(bool nullToAbsent) {
    return PlanSessionDatesCompanion(
      id: Value(id),
      sessionId: Value(sessionId),
      date: Value(date),
    );
  }

  factory PlanSessionDate.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PlanSessionDate(
      id: serializer.fromJson<int>(json['id']),
      sessionId: serializer.fromJson<int>(json['sessionId']),
      date: serializer.fromJson<DateTime>(json['date']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'sessionId': serializer.toJson<int>(sessionId),
      'date': serializer.toJson<DateTime>(date),
    };
  }

  PlanSessionDate copyWith({int? id, int? sessionId, DateTime? date}) =>
      PlanSessionDate(
        id: id ?? this.id,
        sessionId: sessionId ?? this.sessionId,
        date: date ?? this.date,
      );
  PlanSessionDate copyWithCompanion(PlanSessionDatesCompanion data) {
    return PlanSessionDate(
      id: data.id.present ? data.id.value : this.id,
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      date: data.date.present ? data.date.value : this.date,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlanSessionDate(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('date: $date')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, sessionId, date);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlanSessionDate &&
          other.id == this.id &&
          other.sessionId == this.sessionId &&
          other.date == this.date);
}

class PlanSessionDatesCompanion extends UpdateCompanion<PlanSessionDate> {
  final Value<int> id;
  final Value<int> sessionId;
  final Value<DateTime> date;
  const PlanSessionDatesCompanion({
    this.id = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.date = const Value.absent(),
  });
  PlanSessionDatesCompanion.insert({
    this.id = const Value.absent(),
    required int sessionId,
    required DateTime date,
  }) : sessionId = Value(sessionId),
       date = Value(date);
  static Insertable<PlanSessionDate> custom({
    Expression<int>? id,
    Expression<int>? sessionId,
    Expression<DateTime>? date,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sessionId != null) 'session_id': sessionId,
      if (date != null) 'date': date,
    });
  }

  PlanSessionDatesCompanion copyWith({
    Value<int>? id,
    Value<int>? sessionId,
    Value<DateTime>? date,
  }) {
    return PlanSessionDatesCompanion(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      date: date ?? this.date,
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
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlanSessionDatesCompanion(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('date: $date')
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
  static const VerificationMeta _supersetGroupIdMeta = const VerificationMeta(
    'supersetGroupId',
  );
  @override
  late final GeneratedColumn<int> supersetGroupId = GeneratedColumn<int>(
    'superset_group_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _embeddingAllowedMeta = const VerificationMeta(
    'embeddingAllowed',
  );
  @override
  late final GeneratedColumn<bool> embeddingAllowed = GeneratedColumn<bool>(
    'embedding_allowed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("embedding_allowed" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
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
    supersetGroupId,
    embeddingAllowed,
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
    if (data.containsKey('superset_group_id')) {
      context.handle(
        _supersetGroupIdMeta,
        supersetGroupId.isAcceptableOrUnknown(
          data['superset_group_id']!,
          _supersetGroupIdMeta,
        ),
      );
    }
    if (data.containsKey('embedding_allowed')) {
      context.handle(
        _embeddingAllowedMeta,
        embeddingAllowed.isAcceptableOrUnknown(
          data['embedding_allowed']!,
          _embeddingAllowedMeta,
        ),
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
      supersetGroupId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}superset_group_id'],
      ),
      embeddingAllowed: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}embedding_allowed'],
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

  /// Non-null when this row is one member of a superset/circuit within its
  /// own session - every row sharing the same value is done back-to-back
  /// in round-robin order with one shared rest between rounds (see
  /// execution_screen.dart's `_groupedExercisesFor`/`_SupersetCard`). A
  /// small integer **scoped only to its own session** - not a foreign key,
  /// not globally unique - so two different sessions can each legitimately
  /// have a group numbered 1 without colliding, and grouping survives
  /// cloning a session (duplicateSessionToWeeks) or forking a plan for
  /// free. Set/cleared via PlanDao.setSupersetGroup/clearSupersetGroup.
  final int? supersetGroupId;

  /// Same opt-in as Exercises.embeddingAllowed, but for this specific
  /// prescription's own [videoUrl] - a plan's video can differ from the
  /// library exercise's own (e.g. a trainer's demo of this exact variation),
  /// so it carries its own independent flag rather than inheriting the
  /// library exercise's. Note: nothing renders a plan exercise's video today
  /// (see execution_screen.dart) - this only stamps the author's choice
  /// through import/fork/export so it isn't lost once a display exists.
  final bool embeddingAllowed;
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
    this.supersetGroupId,
    required this.embeddingAllowed,
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
    if (!nullToAbsent || supersetGroupId != null) {
      map['superset_group_id'] = Variable<int>(supersetGroupId);
    }
    map['embedding_allowed'] = Variable<bool>(embeddingAllowed);
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
      supersetGroupId: supersetGroupId == null && nullToAbsent
          ? const Value.absent()
          : Value(supersetGroupId),
      embeddingAllowed: Value(embeddingAllowed),
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
      supersetGroupId: serializer.fromJson<int?>(json['supersetGroupId']),
      embeddingAllowed: serializer.fromJson<bool>(json['embeddingAllowed']),
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
      'supersetGroupId': serializer.toJson<int?>(supersetGroupId),
      'embeddingAllowed': serializer.toJson<bool>(embeddingAllowed),
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
    Value<int?> supersetGroupId = const Value.absent(),
    bool? embeddingAllowed,
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
    supersetGroupId: supersetGroupId.present
        ? supersetGroupId.value
        : this.supersetGroupId,
    embeddingAllowed: embeddingAllowed ?? this.embeddingAllowed,
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
      supersetGroupId: data.supersetGroupId.present
          ? data.supersetGroupId.value
          : this.supersetGroupId,
      embeddingAllowed: data.embeddingAllowed.present
          ? data.embeddingAllowed.value
          : this.embeddingAllowed,
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
          ..write('videoUrl: $videoUrl, ')
          ..write('supersetGroupId: $supersetGroupId, ')
          ..write('embeddingAllowed: $embeddingAllowed')
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
    supersetGroupId,
    embeddingAllowed,
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
          other.videoUrl == this.videoUrl &&
          other.supersetGroupId == this.supersetGroupId &&
          other.embeddingAllowed == this.embeddingAllowed);
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
  final Value<int?> supersetGroupId;
  final Value<bool> embeddingAllowed;
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
    this.supersetGroupId = const Value.absent(),
    this.embeddingAllowed = const Value.absent(),
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
    this.supersetGroupId = const Value.absent(),
    this.embeddingAllowed = const Value.absent(),
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
    Expression<int>? supersetGroupId,
    Expression<bool>? embeddingAllowed,
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
      if (supersetGroupId != null) 'superset_group_id': supersetGroupId,
      if (embeddingAllowed != null) 'embedding_allowed': embeddingAllowed,
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
    Value<int?>? supersetGroupId,
    Value<bool>? embeddingAllowed,
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
      supersetGroupId: supersetGroupId ?? this.supersetGroupId,
      embeddingAllowed: embeddingAllowed ?? this.embeddingAllowed,
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
    if (supersetGroupId.present) {
      map['superset_group_id'] = Variable<int>(supersetGroupId.value);
    }
    if (embeddingAllowed.present) {
      map['embedding_allowed'] = Variable<bool>(embeddingAllowed.value);
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
          ..write('videoUrl: $videoUrl, ')
          ..write('supersetGroupId: $supersetGroupId, ')
          ..write('embeddingAllowed: $embeddingAllowed')
          ..write(')'))
        .toString();
  }
}

class $SessionLogsTable extends SessionLogs
    with TableInfo<$SessionLogsTable, SessionLog> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SessionLogsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _planSessionIdMeta = const VerificationMeta(
    'planSessionId',
  );
  @override
  late final GeneratedColumn<int> planSessionId = GeneratedColumn<int>(
    'plan_session_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES plan_sessions (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _loggedAtMeta = const VerificationMeta(
    'loggedAt',
  );
  @override
  late final GeneratedColumn<DateTime> loggedAt = GeneratedColumn<DateTime>(
    'logged_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _finishedAtMeta = const VerificationMeta(
    'finishedAt',
  );
  @override
  late final GeneratedColumn<DateTime> finishedAt = GeneratedColumn<DateTime>(
    'finished_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _activityNameMeta = const VerificationMeta(
    'activityName',
  );
  @override
  late final GeneratedColumn<String> activityName = GeneratedColumn<String>(
    'activity_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _durationSecMeta = const VerificationMeta(
    'durationSec',
  );
  @override
  late final GeneratedColumn<double> durationSec = GeneratedColumn<double>(
    'duration_sec',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _distanceMeta = const VerificationMeta(
    'distance',
  );
  @override
  late final GeneratedColumn<double> distance = GeneratedColumn<double>(
    'distance',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    planSessionId,
    loggedAt,
    finishedAt,
    notes,
    activityName,
    durationSec,
    distance,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'session_logs';
  @override
  VerificationContext validateIntegrity(
    Insertable<SessionLog> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('plan_session_id')) {
      context.handle(
        _planSessionIdMeta,
        planSessionId.isAcceptableOrUnknown(
          data['plan_session_id']!,
          _planSessionIdMeta,
        ),
      );
    }
    if (data.containsKey('logged_at')) {
      context.handle(
        _loggedAtMeta,
        loggedAt.isAcceptableOrUnknown(data['logged_at']!, _loggedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_loggedAtMeta);
    }
    if (data.containsKey('finished_at')) {
      context.handle(
        _finishedAtMeta,
        finishedAt.isAcceptableOrUnknown(data['finished_at']!, _finishedAtMeta),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('activity_name')) {
      context.handle(
        _activityNameMeta,
        activityName.isAcceptableOrUnknown(
          data['activity_name']!,
          _activityNameMeta,
        ),
      );
    }
    if (data.containsKey('duration_sec')) {
      context.handle(
        _durationSecMeta,
        durationSec.isAcceptableOrUnknown(
          data['duration_sec']!,
          _durationSecMeta,
        ),
      );
    }
    if (data.containsKey('distance')) {
      context.handle(
        _distanceMeta,
        distance.isAcceptableOrUnknown(data['distance']!, _distanceMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SessionLog map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SessionLog(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      planSessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}plan_session_id'],
      ),
      loggedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}logged_at'],
      )!,
      finishedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}finished_at'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      activityName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}activity_name'],
      ),
      durationSec: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}duration_sec'],
      ),
      distance: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}distance'],
      ),
    );
  }

  @override
  $SessionLogsTable createAlias(String alias) {
    return $SessionLogsTable(attachedDatabase, alias);
  }
}

class SessionLog extends DataClass implements Insertable<SessionLog> {
  final String id;
  final int? planSessionId;
  final DateTime loggedAt;

  /// Null means this row is a **draft** - an in-progress execution-mode
  /// session autosaved (see `execution_screen.dart`'s app-lifecycle
  /// observer) so a set already checked off survives the app process being
  /// killed while backgrounded, without ever showing up anywhere a real,
  /// finished workout would (Progress, History, Calendar, backup export -
  /// every one of `SessionLogDao`'s read queries filters on
  /// `finishedAt.isNotNull()`). Set the instant a row is created for
  /// [SessionLogDao.createSessionLog]/[SessionLogDao.createAdHocActivity] -
  /// those two are the only ways a *real* log has ever been created, so
  /// existing rows predating this column are backfilled to `loggedAt` in the
  /// schema 10->11 migration. A draft row is replaced wholesale (delete +
  /// reinsert) on every autosave rather than diffed/updated in place - see
  /// [SessionLogDao.saveDraft].
  final DateTime? finishedAt;

  /// Optional free-text note taken right after finishing, e.g. "felt heavy
  /// today" - surfaced on the workout's own detail screen.
  final String? notes;

  /// Non-null only for an ad-hoc activity (e.g. "Walk", "Run", "Yoga") -
  /// null for a normal plan-session log, which gets its name from the plan
  /// session it belongs to instead.
  final String? activityName;
  final double? durationSec;
  final double? distance;
  const SessionLog({
    required this.id,
    this.planSessionId,
    required this.loggedAt,
    this.finishedAt,
    this.notes,
    this.activityName,
    this.durationSec,
    this.distance,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || planSessionId != null) {
      map['plan_session_id'] = Variable<int>(planSessionId);
    }
    map['logged_at'] = Variable<DateTime>(loggedAt);
    if (!nullToAbsent || finishedAt != null) {
      map['finished_at'] = Variable<DateTime>(finishedAt);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    if (!nullToAbsent || activityName != null) {
      map['activity_name'] = Variable<String>(activityName);
    }
    if (!nullToAbsent || durationSec != null) {
      map['duration_sec'] = Variable<double>(durationSec);
    }
    if (!nullToAbsent || distance != null) {
      map['distance'] = Variable<double>(distance);
    }
    return map;
  }

  SessionLogsCompanion toCompanion(bool nullToAbsent) {
    return SessionLogsCompanion(
      id: Value(id),
      planSessionId: planSessionId == null && nullToAbsent
          ? const Value.absent()
          : Value(planSessionId),
      loggedAt: Value(loggedAt),
      finishedAt: finishedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(finishedAt),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      activityName: activityName == null && nullToAbsent
          ? const Value.absent()
          : Value(activityName),
      durationSec: durationSec == null && nullToAbsent
          ? const Value.absent()
          : Value(durationSec),
      distance: distance == null && nullToAbsent
          ? const Value.absent()
          : Value(distance),
    );
  }

  factory SessionLog.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SessionLog(
      id: serializer.fromJson<String>(json['id']),
      planSessionId: serializer.fromJson<int?>(json['planSessionId']),
      loggedAt: serializer.fromJson<DateTime>(json['loggedAt']),
      finishedAt: serializer.fromJson<DateTime?>(json['finishedAt']),
      notes: serializer.fromJson<String?>(json['notes']),
      activityName: serializer.fromJson<String?>(json['activityName']),
      durationSec: serializer.fromJson<double?>(json['durationSec']),
      distance: serializer.fromJson<double?>(json['distance']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'planSessionId': serializer.toJson<int?>(planSessionId),
      'loggedAt': serializer.toJson<DateTime>(loggedAt),
      'finishedAt': serializer.toJson<DateTime?>(finishedAt),
      'notes': serializer.toJson<String?>(notes),
      'activityName': serializer.toJson<String?>(activityName),
      'durationSec': serializer.toJson<double?>(durationSec),
      'distance': serializer.toJson<double?>(distance),
    };
  }

  SessionLog copyWith({
    String? id,
    Value<int?> planSessionId = const Value.absent(),
    DateTime? loggedAt,
    Value<DateTime?> finishedAt = const Value.absent(),
    Value<String?> notes = const Value.absent(),
    Value<String?> activityName = const Value.absent(),
    Value<double?> durationSec = const Value.absent(),
    Value<double?> distance = const Value.absent(),
  }) => SessionLog(
    id: id ?? this.id,
    planSessionId: planSessionId.present
        ? planSessionId.value
        : this.planSessionId,
    loggedAt: loggedAt ?? this.loggedAt,
    finishedAt: finishedAt.present ? finishedAt.value : this.finishedAt,
    notes: notes.present ? notes.value : this.notes,
    activityName: activityName.present ? activityName.value : this.activityName,
    durationSec: durationSec.present ? durationSec.value : this.durationSec,
    distance: distance.present ? distance.value : this.distance,
  );
  SessionLog copyWithCompanion(SessionLogsCompanion data) {
    return SessionLog(
      id: data.id.present ? data.id.value : this.id,
      planSessionId: data.planSessionId.present
          ? data.planSessionId.value
          : this.planSessionId,
      loggedAt: data.loggedAt.present ? data.loggedAt.value : this.loggedAt,
      finishedAt: data.finishedAt.present
          ? data.finishedAt.value
          : this.finishedAt,
      notes: data.notes.present ? data.notes.value : this.notes,
      activityName: data.activityName.present
          ? data.activityName.value
          : this.activityName,
      durationSec: data.durationSec.present
          ? data.durationSec.value
          : this.durationSec,
      distance: data.distance.present ? data.distance.value : this.distance,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SessionLog(')
          ..write('id: $id, ')
          ..write('planSessionId: $planSessionId, ')
          ..write('loggedAt: $loggedAt, ')
          ..write('finishedAt: $finishedAt, ')
          ..write('notes: $notes, ')
          ..write('activityName: $activityName, ')
          ..write('durationSec: $durationSec, ')
          ..write('distance: $distance')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    planSessionId,
    loggedAt,
    finishedAt,
    notes,
    activityName,
    durationSec,
    distance,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SessionLog &&
          other.id == this.id &&
          other.planSessionId == this.planSessionId &&
          other.loggedAt == this.loggedAt &&
          other.finishedAt == this.finishedAt &&
          other.notes == this.notes &&
          other.activityName == this.activityName &&
          other.durationSec == this.durationSec &&
          other.distance == this.distance);
}

class SessionLogsCompanion extends UpdateCompanion<SessionLog> {
  final Value<String> id;
  final Value<int?> planSessionId;
  final Value<DateTime> loggedAt;
  final Value<DateTime?> finishedAt;
  final Value<String?> notes;
  final Value<String?> activityName;
  final Value<double?> durationSec;
  final Value<double?> distance;
  final Value<int> rowid;
  const SessionLogsCompanion({
    this.id = const Value.absent(),
    this.planSessionId = const Value.absent(),
    this.loggedAt = const Value.absent(),
    this.finishedAt = const Value.absent(),
    this.notes = const Value.absent(),
    this.activityName = const Value.absent(),
    this.durationSec = const Value.absent(),
    this.distance = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SessionLogsCompanion.insert({
    required String id,
    this.planSessionId = const Value.absent(),
    required DateTime loggedAt,
    this.finishedAt = const Value.absent(),
    this.notes = const Value.absent(),
    this.activityName = const Value.absent(),
    this.durationSec = const Value.absent(),
    this.distance = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       loggedAt = Value(loggedAt);
  static Insertable<SessionLog> custom({
    Expression<String>? id,
    Expression<int>? planSessionId,
    Expression<DateTime>? loggedAt,
    Expression<DateTime>? finishedAt,
    Expression<String>? notes,
    Expression<String>? activityName,
    Expression<double>? durationSec,
    Expression<double>? distance,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (planSessionId != null) 'plan_session_id': planSessionId,
      if (loggedAt != null) 'logged_at': loggedAt,
      if (finishedAt != null) 'finished_at': finishedAt,
      if (notes != null) 'notes': notes,
      if (activityName != null) 'activity_name': activityName,
      if (durationSec != null) 'duration_sec': durationSec,
      if (distance != null) 'distance': distance,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SessionLogsCompanion copyWith({
    Value<String>? id,
    Value<int?>? planSessionId,
    Value<DateTime>? loggedAt,
    Value<DateTime?>? finishedAt,
    Value<String?>? notes,
    Value<String?>? activityName,
    Value<double?>? durationSec,
    Value<double?>? distance,
    Value<int>? rowid,
  }) {
    return SessionLogsCompanion(
      id: id ?? this.id,
      planSessionId: planSessionId ?? this.planSessionId,
      loggedAt: loggedAt ?? this.loggedAt,
      finishedAt: finishedAt ?? this.finishedAt,
      notes: notes ?? this.notes,
      activityName: activityName ?? this.activityName,
      durationSec: durationSec ?? this.durationSec,
      distance: distance ?? this.distance,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (planSessionId.present) {
      map['plan_session_id'] = Variable<int>(planSessionId.value);
    }
    if (loggedAt.present) {
      map['logged_at'] = Variable<DateTime>(loggedAt.value);
    }
    if (finishedAt.present) {
      map['finished_at'] = Variable<DateTime>(finishedAt.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (activityName.present) {
      map['activity_name'] = Variable<String>(activityName.value);
    }
    if (durationSec.present) {
      map['duration_sec'] = Variable<double>(durationSec.value);
    }
    if (distance.present) {
      map['distance'] = Variable<double>(distance.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SessionLogsCompanion(')
          ..write('id: $id, ')
          ..write('planSessionId: $planSessionId, ')
          ..write('loggedAt: $loggedAt, ')
          ..write('finishedAt: $finishedAt, ')
          ..write('notes: $notes, ')
          ..write('activityName: $activityName, ')
          ..write('durationSec: $durationSec, ')
          ..write('distance: $distance, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LoggedSetsTable extends LoggedSets
    with TableInfo<$LoggedSetsTable, LoggedSet> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LoggedSetsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _sessionLogIdMeta = const VerificationMeta(
    'sessionLogId',
  );
  @override
  late final GeneratedColumn<String> sessionLogId = GeneratedColumn<String>(
    'session_log_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES session_logs (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _exerciseIdMeta = const VerificationMeta(
    'exerciseId',
  );
  @override
  late final GeneratedColumn<String> exerciseId = GeneratedColumn<String>(
    'exercise_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES exercises (id)',
    ),
  );
  static const VerificationMeta _setNumberMeta = const VerificationMeta(
    'setNumber',
  );
  @override
  late final GeneratedColumn<int> setNumber = GeneratedColumn<int>(
    'set_number',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _repsMeta = const VerificationMeta('reps');
  @override
  late final GeneratedColumn<int> reps = GeneratedColumn<int>(
    'reps',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _weightMeta = const VerificationMeta('weight');
  @override
  late final GeneratedColumn<double> weight = GeneratedColumn<double>(
    'weight',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _durationSecMeta = const VerificationMeta(
    'durationSec',
  );
  @override
  late final GeneratedColumn<double> durationSec = GeneratedColumn<double>(
    'duration_sec',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _distanceMeta = const VerificationMeta(
    'distance',
  );
  @override
  late final GeneratedColumn<double> distance = GeneratedColumn<double>(
    'distance',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _rpeMeta = const VerificationMeta('rpe');
  @override
  late final GeneratedColumn<double> rpe = GeneratedColumn<double>(
    'rpe',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isPrMeta = const VerificationMeta('isPr');
  @override
  late final GeneratedColumn<bool> isPr = GeneratedColumn<bool>(
    'is_pr',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_pr" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sessionLogId,
    exerciseId,
    setNumber,
    reps,
    weight,
    durationSec,
    distance,
    rpe,
    isPr,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'logged_sets';
  @override
  VerificationContext validateIntegrity(
    Insertable<LoggedSet> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('session_log_id')) {
      context.handle(
        _sessionLogIdMeta,
        sessionLogId.isAcceptableOrUnknown(
          data['session_log_id']!,
          _sessionLogIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sessionLogIdMeta);
    }
    if (data.containsKey('exercise_id')) {
      context.handle(
        _exerciseIdMeta,
        exerciseId.isAcceptableOrUnknown(data['exercise_id']!, _exerciseIdMeta),
      );
    } else if (isInserting) {
      context.missing(_exerciseIdMeta);
    }
    if (data.containsKey('set_number')) {
      context.handle(
        _setNumberMeta,
        setNumber.isAcceptableOrUnknown(data['set_number']!, _setNumberMeta),
      );
    } else if (isInserting) {
      context.missing(_setNumberMeta);
    }
    if (data.containsKey('reps')) {
      context.handle(
        _repsMeta,
        reps.isAcceptableOrUnknown(data['reps']!, _repsMeta),
      );
    }
    if (data.containsKey('weight')) {
      context.handle(
        _weightMeta,
        weight.isAcceptableOrUnknown(data['weight']!, _weightMeta),
      );
    }
    if (data.containsKey('duration_sec')) {
      context.handle(
        _durationSecMeta,
        durationSec.isAcceptableOrUnknown(
          data['duration_sec']!,
          _durationSecMeta,
        ),
      );
    }
    if (data.containsKey('distance')) {
      context.handle(
        _distanceMeta,
        distance.isAcceptableOrUnknown(data['distance']!, _distanceMeta),
      );
    }
    if (data.containsKey('rpe')) {
      context.handle(
        _rpeMeta,
        rpe.isAcceptableOrUnknown(data['rpe']!, _rpeMeta),
      );
    }
    if (data.containsKey('is_pr')) {
      context.handle(
        _isPrMeta,
        isPr.isAcceptableOrUnknown(data['is_pr']!, _isPrMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LoggedSet map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LoggedSet(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      sessionLogId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}session_log_id'],
      )!,
      exerciseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}exercise_id'],
      )!,
      setNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}set_number'],
      )!,
      reps: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}reps'],
      ),
      weight: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}weight'],
      ),
      durationSec: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}duration_sec'],
      ),
      distance: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}distance'],
      ),
      rpe: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}rpe'],
      ),
      isPr: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_pr'],
      )!,
    );
  }

  @override
  $LoggedSetsTable createAlias(String alias) {
    return $LoggedSetsTable(attachedDatabase, alias);
  }
}

class LoggedSet extends DataClass implements Insertable<LoggedSet> {
  final int id;
  final String sessionLogId;
  final String exerciseId;
  final int setNumber;
  final int? reps;
  final double? weight;
  final double? durationSec;
  final double? distance;
  final double? rpe;
  final bool isPr;
  const LoggedSet({
    required this.id,
    required this.sessionLogId,
    required this.exerciseId,
    required this.setNumber,
    this.reps,
    this.weight,
    this.durationSec,
    this.distance,
    this.rpe,
    required this.isPr,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['session_log_id'] = Variable<String>(sessionLogId);
    map['exercise_id'] = Variable<String>(exerciseId);
    map['set_number'] = Variable<int>(setNumber);
    if (!nullToAbsent || reps != null) {
      map['reps'] = Variable<int>(reps);
    }
    if (!nullToAbsent || weight != null) {
      map['weight'] = Variable<double>(weight);
    }
    if (!nullToAbsent || durationSec != null) {
      map['duration_sec'] = Variable<double>(durationSec);
    }
    if (!nullToAbsent || distance != null) {
      map['distance'] = Variable<double>(distance);
    }
    if (!nullToAbsent || rpe != null) {
      map['rpe'] = Variable<double>(rpe);
    }
    map['is_pr'] = Variable<bool>(isPr);
    return map;
  }

  LoggedSetsCompanion toCompanion(bool nullToAbsent) {
    return LoggedSetsCompanion(
      id: Value(id),
      sessionLogId: Value(sessionLogId),
      exerciseId: Value(exerciseId),
      setNumber: Value(setNumber),
      reps: reps == null && nullToAbsent ? const Value.absent() : Value(reps),
      weight: weight == null && nullToAbsent
          ? const Value.absent()
          : Value(weight),
      durationSec: durationSec == null && nullToAbsent
          ? const Value.absent()
          : Value(durationSec),
      distance: distance == null && nullToAbsent
          ? const Value.absent()
          : Value(distance),
      rpe: rpe == null && nullToAbsent ? const Value.absent() : Value(rpe),
      isPr: Value(isPr),
    );
  }

  factory LoggedSet.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LoggedSet(
      id: serializer.fromJson<int>(json['id']),
      sessionLogId: serializer.fromJson<String>(json['sessionLogId']),
      exerciseId: serializer.fromJson<String>(json['exerciseId']),
      setNumber: serializer.fromJson<int>(json['setNumber']),
      reps: serializer.fromJson<int?>(json['reps']),
      weight: serializer.fromJson<double?>(json['weight']),
      durationSec: serializer.fromJson<double?>(json['durationSec']),
      distance: serializer.fromJson<double?>(json['distance']),
      rpe: serializer.fromJson<double?>(json['rpe']),
      isPr: serializer.fromJson<bool>(json['isPr']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'sessionLogId': serializer.toJson<String>(sessionLogId),
      'exerciseId': serializer.toJson<String>(exerciseId),
      'setNumber': serializer.toJson<int>(setNumber),
      'reps': serializer.toJson<int?>(reps),
      'weight': serializer.toJson<double?>(weight),
      'durationSec': serializer.toJson<double?>(durationSec),
      'distance': serializer.toJson<double?>(distance),
      'rpe': serializer.toJson<double?>(rpe),
      'isPr': serializer.toJson<bool>(isPr),
    };
  }

  LoggedSet copyWith({
    int? id,
    String? sessionLogId,
    String? exerciseId,
    int? setNumber,
    Value<int?> reps = const Value.absent(),
    Value<double?> weight = const Value.absent(),
    Value<double?> durationSec = const Value.absent(),
    Value<double?> distance = const Value.absent(),
    Value<double?> rpe = const Value.absent(),
    bool? isPr,
  }) => LoggedSet(
    id: id ?? this.id,
    sessionLogId: sessionLogId ?? this.sessionLogId,
    exerciseId: exerciseId ?? this.exerciseId,
    setNumber: setNumber ?? this.setNumber,
    reps: reps.present ? reps.value : this.reps,
    weight: weight.present ? weight.value : this.weight,
    durationSec: durationSec.present ? durationSec.value : this.durationSec,
    distance: distance.present ? distance.value : this.distance,
    rpe: rpe.present ? rpe.value : this.rpe,
    isPr: isPr ?? this.isPr,
  );
  LoggedSet copyWithCompanion(LoggedSetsCompanion data) {
    return LoggedSet(
      id: data.id.present ? data.id.value : this.id,
      sessionLogId: data.sessionLogId.present
          ? data.sessionLogId.value
          : this.sessionLogId,
      exerciseId: data.exerciseId.present
          ? data.exerciseId.value
          : this.exerciseId,
      setNumber: data.setNumber.present ? data.setNumber.value : this.setNumber,
      reps: data.reps.present ? data.reps.value : this.reps,
      weight: data.weight.present ? data.weight.value : this.weight,
      durationSec: data.durationSec.present
          ? data.durationSec.value
          : this.durationSec,
      distance: data.distance.present ? data.distance.value : this.distance,
      rpe: data.rpe.present ? data.rpe.value : this.rpe,
      isPr: data.isPr.present ? data.isPr.value : this.isPr,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LoggedSet(')
          ..write('id: $id, ')
          ..write('sessionLogId: $sessionLogId, ')
          ..write('exerciseId: $exerciseId, ')
          ..write('setNumber: $setNumber, ')
          ..write('reps: $reps, ')
          ..write('weight: $weight, ')
          ..write('durationSec: $durationSec, ')
          ..write('distance: $distance, ')
          ..write('rpe: $rpe, ')
          ..write('isPr: $isPr')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    sessionLogId,
    exerciseId,
    setNumber,
    reps,
    weight,
    durationSec,
    distance,
    rpe,
    isPr,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LoggedSet &&
          other.id == this.id &&
          other.sessionLogId == this.sessionLogId &&
          other.exerciseId == this.exerciseId &&
          other.setNumber == this.setNumber &&
          other.reps == this.reps &&
          other.weight == this.weight &&
          other.durationSec == this.durationSec &&
          other.distance == this.distance &&
          other.rpe == this.rpe &&
          other.isPr == this.isPr);
}

class LoggedSetsCompanion extends UpdateCompanion<LoggedSet> {
  final Value<int> id;
  final Value<String> sessionLogId;
  final Value<String> exerciseId;
  final Value<int> setNumber;
  final Value<int?> reps;
  final Value<double?> weight;
  final Value<double?> durationSec;
  final Value<double?> distance;
  final Value<double?> rpe;
  final Value<bool> isPr;
  const LoggedSetsCompanion({
    this.id = const Value.absent(),
    this.sessionLogId = const Value.absent(),
    this.exerciseId = const Value.absent(),
    this.setNumber = const Value.absent(),
    this.reps = const Value.absent(),
    this.weight = const Value.absent(),
    this.durationSec = const Value.absent(),
    this.distance = const Value.absent(),
    this.rpe = const Value.absent(),
    this.isPr = const Value.absent(),
  });
  LoggedSetsCompanion.insert({
    this.id = const Value.absent(),
    required String sessionLogId,
    required String exerciseId,
    required int setNumber,
    this.reps = const Value.absent(),
    this.weight = const Value.absent(),
    this.durationSec = const Value.absent(),
    this.distance = const Value.absent(),
    this.rpe = const Value.absent(),
    this.isPr = const Value.absent(),
  }) : sessionLogId = Value(sessionLogId),
       exerciseId = Value(exerciseId),
       setNumber = Value(setNumber);
  static Insertable<LoggedSet> custom({
    Expression<int>? id,
    Expression<String>? sessionLogId,
    Expression<String>? exerciseId,
    Expression<int>? setNumber,
    Expression<int>? reps,
    Expression<double>? weight,
    Expression<double>? durationSec,
    Expression<double>? distance,
    Expression<double>? rpe,
    Expression<bool>? isPr,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sessionLogId != null) 'session_log_id': sessionLogId,
      if (exerciseId != null) 'exercise_id': exerciseId,
      if (setNumber != null) 'set_number': setNumber,
      if (reps != null) 'reps': reps,
      if (weight != null) 'weight': weight,
      if (durationSec != null) 'duration_sec': durationSec,
      if (distance != null) 'distance': distance,
      if (rpe != null) 'rpe': rpe,
      if (isPr != null) 'is_pr': isPr,
    });
  }

  LoggedSetsCompanion copyWith({
    Value<int>? id,
    Value<String>? sessionLogId,
    Value<String>? exerciseId,
    Value<int>? setNumber,
    Value<int?>? reps,
    Value<double?>? weight,
    Value<double?>? durationSec,
    Value<double?>? distance,
    Value<double?>? rpe,
    Value<bool>? isPr,
  }) {
    return LoggedSetsCompanion(
      id: id ?? this.id,
      sessionLogId: sessionLogId ?? this.sessionLogId,
      exerciseId: exerciseId ?? this.exerciseId,
      setNumber: setNumber ?? this.setNumber,
      reps: reps ?? this.reps,
      weight: weight ?? this.weight,
      durationSec: durationSec ?? this.durationSec,
      distance: distance ?? this.distance,
      rpe: rpe ?? this.rpe,
      isPr: isPr ?? this.isPr,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (sessionLogId.present) {
      map['session_log_id'] = Variable<String>(sessionLogId.value);
    }
    if (exerciseId.present) {
      map['exercise_id'] = Variable<String>(exerciseId.value);
    }
    if (setNumber.present) {
      map['set_number'] = Variable<int>(setNumber.value);
    }
    if (reps.present) {
      map['reps'] = Variable<int>(reps.value);
    }
    if (weight.present) {
      map['weight'] = Variable<double>(weight.value);
    }
    if (durationSec.present) {
      map['duration_sec'] = Variable<double>(durationSec.value);
    }
    if (distance.present) {
      map['distance'] = Variable<double>(distance.value);
    }
    if (rpe.present) {
      map['rpe'] = Variable<double>(rpe.value);
    }
    if (isPr.present) {
      map['is_pr'] = Variable<bool>(isPr.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LoggedSetsCompanion(')
          ..write('id: $id, ')
          ..write('sessionLogId: $sessionLogId, ')
          ..write('exerciseId: $exerciseId, ')
          ..write('setNumber: $setNumber, ')
          ..write('reps: $reps, ')
          ..write('weight: $weight, ')
          ..write('durationSec: $durationSec, ')
          ..write('distance: $distance, ')
          ..write('rpe: $rpe, ')
          ..write('isPr: $isPr')
          ..write(')'))
        .toString();
  }
}

class $BodyMeasurementsTable extends BodyMeasurements
    with TableInfo<$BodyMeasurementsTable, BodyMeasurement> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BodyMeasurementsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _measuredAtMeta = const VerificationMeta(
    'measuredAt',
  );
  @override
  late final GeneratedColumn<DateTime> measuredAt = GeneratedColumn<DateTime>(
    'measured_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _weightKgMeta = const VerificationMeta(
    'weightKg',
  );
  @override
  late final GeneratedColumn<double> weightKg = GeneratedColumn<double>(
    'weight_kg',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _bodyFatPercentMeta = const VerificationMeta(
    'bodyFatPercent',
  );
  @override
  late final GeneratedColumn<double> bodyFatPercent = GeneratedColumn<double>(
    'body_fat_percent',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _chestCmMeta = const VerificationMeta(
    'chestCm',
  );
  @override
  late final GeneratedColumn<double> chestCm = GeneratedColumn<double>(
    'chest_cm',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _waistCmMeta = const VerificationMeta(
    'waistCm',
  );
  @override
  late final GeneratedColumn<double> waistCm = GeneratedColumn<double>(
    'waist_cm',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _hipsCmMeta = const VerificationMeta('hipsCm');
  @override
  late final GeneratedColumn<double> hipsCm = GeneratedColumn<double>(
    'hips_cm',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _thighCmMeta = const VerificationMeta(
    'thighCm',
  );
  @override
  late final GeneratedColumn<double> thighCm = GeneratedColumn<double>(
    'thigh_cm',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _armCmMeta = const VerificationMeta('armCm');
  @override
  late final GeneratedColumn<double> armCm = GeneratedColumn<double>(
    'arm_cm',
    aliasedName,
    true,
    type: DriftSqlType.double,
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
  @override
  List<GeneratedColumn> get $columns => [
    id,
    measuredAt,
    weightKg,
    bodyFatPercent,
    chestCm,
    waistCm,
    hipsCm,
    thighCm,
    armCm,
    notes,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'body_measurements';
  @override
  VerificationContext validateIntegrity(
    Insertable<BodyMeasurement> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('measured_at')) {
      context.handle(
        _measuredAtMeta,
        measuredAt.isAcceptableOrUnknown(data['measured_at']!, _measuredAtMeta),
      );
    } else if (isInserting) {
      context.missing(_measuredAtMeta);
    }
    if (data.containsKey('weight_kg')) {
      context.handle(
        _weightKgMeta,
        weightKg.isAcceptableOrUnknown(data['weight_kg']!, _weightKgMeta),
      );
    }
    if (data.containsKey('body_fat_percent')) {
      context.handle(
        _bodyFatPercentMeta,
        bodyFatPercent.isAcceptableOrUnknown(
          data['body_fat_percent']!,
          _bodyFatPercentMeta,
        ),
      );
    }
    if (data.containsKey('chest_cm')) {
      context.handle(
        _chestCmMeta,
        chestCm.isAcceptableOrUnknown(data['chest_cm']!, _chestCmMeta),
      );
    }
    if (data.containsKey('waist_cm')) {
      context.handle(
        _waistCmMeta,
        waistCm.isAcceptableOrUnknown(data['waist_cm']!, _waistCmMeta),
      );
    }
    if (data.containsKey('hips_cm')) {
      context.handle(
        _hipsCmMeta,
        hipsCm.isAcceptableOrUnknown(data['hips_cm']!, _hipsCmMeta),
      );
    }
    if (data.containsKey('thigh_cm')) {
      context.handle(
        _thighCmMeta,
        thighCm.isAcceptableOrUnknown(data['thigh_cm']!, _thighCmMeta),
      );
    }
    if (data.containsKey('arm_cm')) {
      context.handle(
        _armCmMeta,
        armCm.isAcceptableOrUnknown(data['arm_cm']!, _armCmMeta),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BodyMeasurement map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BodyMeasurement(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      measuredAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}measured_at'],
      )!,
      weightKg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}weight_kg'],
      ),
      bodyFatPercent: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}body_fat_percent'],
      ),
      chestCm: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}chest_cm'],
      ),
      waistCm: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}waist_cm'],
      ),
      hipsCm: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}hips_cm'],
      ),
      thighCm: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}thigh_cm'],
      ),
      armCm: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}arm_cm'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      )!,
    );
  }

  @override
  $BodyMeasurementsTable createAlias(String alias) {
    return $BodyMeasurementsTable(attachedDatabase, alias);
  }
}

class BodyMeasurement extends DataClass implements Insertable<BodyMeasurement> {
  final String id;

  /// Date-only (time component zeroed by the DAO) - at most one entry per
  /// day, so re-recording the same day updates rather than duplicates.
  final DateTime measuredAt;
  final double? weightKg;
  final double? bodyFatPercent;
  final double? chestCm;
  final double? waistCm;
  final double? hipsCm;
  final double? thighCm;
  final double? armCm;
  final String notes;
  const BodyMeasurement({
    required this.id,
    required this.measuredAt,
    this.weightKg,
    this.bodyFatPercent,
    this.chestCm,
    this.waistCm,
    this.hipsCm,
    this.thighCm,
    this.armCm,
    required this.notes,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['measured_at'] = Variable<DateTime>(measuredAt);
    if (!nullToAbsent || weightKg != null) {
      map['weight_kg'] = Variable<double>(weightKg);
    }
    if (!nullToAbsent || bodyFatPercent != null) {
      map['body_fat_percent'] = Variable<double>(bodyFatPercent);
    }
    if (!nullToAbsent || chestCm != null) {
      map['chest_cm'] = Variable<double>(chestCm);
    }
    if (!nullToAbsent || waistCm != null) {
      map['waist_cm'] = Variable<double>(waistCm);
    }
    if (!nullToAbsent || hipsCm != null) {
      map['hips_cm'] = Variable<double>(hipsCm);
    }
    if (!nullToAbsent || thighCm != null) {
      map['thigh_cm'] = Variable<double>(thighCm);
    }
    if (!nullToAbsent || armCm != null) {
      map['arm_cm'] = Variable<double>(armCm);
    }
    map['notes'] = Variable<String>(notes);
    return map;
  }

  BodyMeasurementsCompanion toCompanion(bool nullToAbsent) {
    return BodyMeasurementsCompanion(
      id: Value(id),
      measuredAt: Value(measuredAt),
      weightKg: weightKg == null && nullToAbsent
          ? const Value.absent()
          : Value(weightKg),
      bodyFatPercent: bodyFatPercent == null && nullToAbsent
          ? const Value.absent()
          : Value(bodyFatPercent),
      chestCm: chestCm == null && nullToAbsent
          ? const Value.absent()
          : Value(chestCm),
      waistCm: waistCm == null && nullToAbsent
          ? const Value.absent()
          : Value(waistCm),
      hipsCm: hipsCm == null && nullToAbsent
          ? const Value.absent()
          : Value(hipsCm),
      thighCm: thighCm == null && nullToAbsent
          ? const Value.absent()
          : Value(thighCm),
      armCm: armCm == null && nullToAbsent
          ? const Value.absent()
          : Value(armCm),
      notes: Value(notes),
    );
  }

  factory BodyMeasurement.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BodyMeasurement(
      id: serializer.fromJson<String>(json['id']),
      measuredAt: serializer.fromJson<DateTime>(json['measuredAt']),
      weightKg: serializer.fromJson<double?>(json['weightKg']),
      bodyFatPercent: serializer.fromJson<double?>(json['bodyFatPercent']),
      chestCm: serializer.fromJson<double?>(json['chestCm']),
      waistCm: serializer.fromJson<double?>(json['waistCm']),
      hipsCm: serializer.fromJson<double?>(json['hipsCm']),
      thighCm: serializer.fromJson<double?>(json['thighCm']),
      armCm: serializer.fromJson<double?>(json['armCm']),
      notes: serializer.fromJson<String>(json['notes']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'measuredAt': serializer.toJson<DateTime>(measuredAt),
      'weightKg': serializer.toJson<double?>(weightKg),
      'bodyFatPercent': serializer.toJson<double?>(bodyFatPercent),
      'chestCm': serializer.toJson<double?>(chestCm),
      'waistCm': serializer.toJson<double?>(waistCm),
      'hipsCm': serializer.toJson<double?>(hipsCm),
      'thighCm': serializer.toJson<double?>(thighCm),
      'armCm': serializer.toJson<double?>(armCm),
      'notes': serializer.toJson<String>(notes),
    };
  }

  BodyMeasurement copyWith({
    String? id,
    DateTime? measuredAt,
    Value<double?> weightKg = const Value.absent(),
    Value<double?> bodyFatPercent = const Value.absent(),
    Value<double?> chestCm = const Value.absent(),
    Value<double?> waistCm = const Value.absent(),
    Value<double?> hipsCm = const Value.absent(),
    Value<double?> thighCm = const Value.absent(),
    Value<double?> armCm = const Value.absent(),
    String? notes,
  }) => BodyMeasurement(
    id: id ?? this.id,
    measuredAt: measuredAt ?? this.measuredAt,
    weightKg: weightKg.present ? weightKg.value : this.weightKg,
    bodyFatPercent: bodyFatPercent.present
        ? bodyFatPercent.value
        : this.bodyFatPercent,
    chestCm: chestCm.present ? chestCm.value : this.chestCm,
    waistCm: waistCm.present ? waistCm.value : this.waistCm,
    hipsCm: hipsCm.present ? hipsCm.value : this.hipsCm,
    thighCm: thighCm.present ? thighCm.value : this.thighCm,
    armCm: armCm.present ? armCm.value : this.armCm,
    notes: notes ?? this.notes,
  );
  BodyMeasurement copyWithCompanion(BodyMeasurementsCompanion data) {
    return BodyMeasurement(
      id: data.id.present ? data.id.value : this.id,
      measuredAt: data.measuredAt.present
          ? data.measuredAt.value
          : this.measuredAt,
      weightKg: data.weightKg.present ? data.weightKg.value : this.weightKg,
      bodyFatPercent: data.bodyFatPercent.present
          ? data.bodyFatPercent.value
          : this.bodyFatPercent,
      chestCm: data.chestCm.present ? data.chestCm.value : this.chestCm,
      waistCm: data.waistCm.present ? data.waistCm.value : this.waistCm,
      hipsCm: data.hipsCm.present ? data.hipsCm.value : this.hipsCm,
      thighCm: data.thighCm.present ? data.thighCm.value : this.thighCm,
      armCm: data.armCm.present ? data.armCm.value : this.armCm,
      notes: data.notes.present ? data.notes.value : this.notes,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BodyMeasurement(')
          ..write('id: $id, ')
          ..write('measuredAt: $measuredAt, ')
          ..write('weightKg: $weightKg, ')
          ..write('bodyFatPercent: $bodyFatPercent, ')
          ..write('chestCm: $chestCm, ')
          ..write('waistCm: $waistCm, ')
          ..write('hipsCm: $hipsCm, ')
          ..write('thighCm: $thighCm, ')
          ..write('armCm: $armCm, ')
          ..write('notes: $notes')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    measuredAt,
    weightKg,
    bodyFatPercent,
    chestCm,
    waistCm,
    hipsCm,
    thighCm,
    armCm,
    notes,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BodyMeasurement &&
          other.id == this.id &&
          other.measuredAt == this.measuredAt &&
          other.weightKg == this.weightKg &&
          other.bodyFatPercent == this.bodyFatPercent &&
          other.chestCm == this.chestCm &&
          other.waistCm == this.waistCm &&
          other.hipsCm == this.hipsCm &&
          other.thighCm == this.thighCm &&
          other.armCm == this.armCm &&
          other.notes == this.notes);
}

class BodyMeasurementsCompanion extends UpdateCompanion<BodyMeasurement> {
  final Value<String> id;
  final Value<DateTime> measuredAt;
  final Value<double?> weightKg;
  final Value<double?> bodyFatPercent;
  final Value<double?> chestCm;
  final Value<double?> waistCm;
  final Value<double?> hipsCm;
  final Value<double?> thighCm;
  final Value<double?> armCm;
  final Value<String> notes;
  final Value<int> rowid;
  const BodyMeasurementsCompanion({
    this.id = const Value.absent(),
    this.measuredAt = const Value.absent(),
    this.weightKg = const Value.absent(),
    this.bodyFatPercent = const Value.absent(),
    this.chestCm = const Value.absent(),
    this.waistCm = const Value.absent(),
    this.hipsCm = const Value.absent(),
    this.thighCm = const Value.absent(),
    this.armCm = const Value.absent(),
    this.notes = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BodyMeasurementsCompanion.insert({
    required String id,
    required DateTime measuredAt,
    this.weightKg = const Value.absent(),
    this.bodyFatPercent = const Value.absent(),
    this.chestCm = const Value.absent(),
    this.waistCm = const Value.absent(),
    this.hipsCm = const Value.absent(),
    this.thighCm = const Value.absent(),
    this.armCm = const Value.absent(),
    this.notes = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       measuredAt = Value(measuredAt);
  static Insertable<BodyMeasurement> custom({
    Expression<String>? id,
    Expression<DateTime>? measuredAt,
    Expression<double>? weightKg,
    Expression<double>? bodyFatPercent,
    Expression<double>? chestCm,
    Expression<double>? waistCm,
    Expression<double>? hipsCm,
    Expression<double>? thighCm,
    Expression<double>? armCm,
    Expression<String>? notes,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (measuredAt != null) 'measured_at': measuredAt,
      if (weightKg != null) 'weight_kg': weightKg,
      if (bodyFatPercent != null) 'body_fat_percent': bodyFatPercent,
      if (chestCm != null) 'chest_cm': chestCm,
      if (waistCm != null) 'waist_cm': waistCm,
      if (hipsCm != null) 'hips_cm': hipsCm,
      if (thighCm != null) 'thigh_cm': thighCm,
      if (armCm != null) 'arm_cm': armCm,
      if (notes != null) 'notes': notes,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BodyMeasurementsCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? measuredAt,
    Value<double?>? weightKg,
    Value<double?>? bodyFatPercent,
    Value<double?>? chestCm,
    Value<double?>? waistCm,
    Value<double?>? hipsCm,
    Value<double?>? thighCm,
    Value<double?>? armCm,
    Value<String>? notes,
    Value<int>? rowid,
  }) {
    return BodyMeasurementsCompanion(
      id: id ?? this.id,
      measuredAt: measuredAt ?? this.measuredAt,
      weightKg: weightKg ?? this.weightKg,
      bodyFatPercent: bodyFatPercent ?? this.bodyFatPercent,
      chestCm: chestCm ?? this.chestCm,
      waistCm: waistCm ?? this.waistCm,
      hipsCm: hipsCm ?? this.hipsCm,
      thighCm: thighCm ?? this.thighCm,
      armCm: armCm ?? this.armCm,
      notes: notes ?? this.notes,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (measuredAt.present) {
      map['measured_at'] = Variable<DateTime>(measuredAt.value);
    }
    if (weightKg.present) {
      map['weight_kg'] = Variable<double>(weightKg.value);
    }
    if (bodyFatPercent.present) {
      map['body_fat_percent'] = Variable<double>(bodyFatPercent.value);
    }
    if (chestCm.present) {
      map['chest_cm'] = Variable<double>(chestCm.value);
    }
    if (waistCm.present) {
      map['waist_cm'] = Variable<double>(waistCm.value);
    }
    if (hipsCm.present) {
      map['hips_cm'] = Variable<double>(hipsCm.value);
    }
    if (thighCm.present) {
      map['thigh_cm'] = Variable<double>(thighCm.value);
    }
    if (armCm.present) {
      map['arm_cm'] = Variable<double>(armCm.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BodyMeasurementsCompanion(')
          ..write('id: $id, ')
          ..write('measuredAt: $measuredAt, ')
          ..write('weightKg: $weightKg, ')
          ..write('bodyFatPercent: $bodyFatPercent, ')
          ..write('chestCm: $chestCm, ')
          ..write('waistCm: $waistCm, ')
          ..write('hipsCm: $hipsCm, ')
          ..write('thighCm: $thighCm, ')
          ..write('armCm: $armCm, ')
          ..write('notes: $notes, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BlocksTable extends Blocks with TableInfo<$BlocksTable, Block> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BlocksTable(this.attachedDatabase, [this._alias]);
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
  static const String $name = 'blocks';
  @override
  VerificationContext validateIntegrity(
    Insertable<Block> instance, {
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
  Block map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Block(
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
  $BlocksTable createAlias(String alias) {
    return $BlocksTable(attachedDatabase, alias);
  }
}

class Block extends DataClass implements Insertable<Block> {
  final String id;
  final String name;
  final String notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Block({
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

  BlocksCompanion toCompanion(bool nullToAbsent) {
    return BlocksCompanion(
      id: Value(id),
      name: Value(name),
      notes: Value(notes),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Block.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Block(
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

  Block copyWith({
    String? id,
    String? name,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Block(
    id: id ?? this.id,
    name: name ?? this.name,
    notes: notes ?? this.notes,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Block copyWithCompanion(BlocksCompanion data) {
    return Block(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      notes: data.notes.present ? data.notes.value : this.notes,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Block(')
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
      (other is Block &&
          other.id == this.id &&
          other.name == this.name &&
          other.notes == this.notes &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class BlocksCompanion extends UpdateCompanion<Block> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> notes;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const BlocksCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BlocksCompanion.insert({
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
  static Insertable<Block> custom({
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

  BlocksCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? notes,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return BlocksCompanion(
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
    return (StringBuffer('BlocksCompanion(')
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

class $BlockExercisesTable extends BlockExercises
    with TableInfo<$BlockExercisesTable, BlockExercise> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BlockExercisesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _blockIdMeta = const VerificationMeta(
    'blockId',
  );
  @override
  late final GeneratedColumn<String> blockId = GeneratedColumn<String>(
    'block_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES blocks (id) ON DELETE CASCADE',
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
  static const VerificationMeta _embeddingAllowedMeta = const VerificationMeta(
    'embeddingAllowed',
  );
  @override
  late final GeneratedColumn<bool> embeddingAllowed = GeneratedColumn<bool>(
    'embedding_allowed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("embedding_allowed" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    blockId,
    order,
    exerciseId,
    exerciseName,
    sets,
    reps,
    weightIntensity,
    restSec,
    notes,
    videoUrl,
    embeddingAllowed,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'block_exercises';
  @override
  VerificationContext validateIntegrity(
    Insertable<BlockExercise> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('block_id')) {
      context.handle(
        _blockIdMeta,
        blockId.isAcceptableOrUnknown(data['block_id']!, _blockIdMeta),
      );
    } else if (isInserting) {
      context.missing(_blockIdMeta);
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
    if (data.containsKey('embedding_allowed')) {
      context.handle(
        _embeddingAllowedMeta,
        embeddingAllowed.isAcceptableOrUnknown(
          data['embedding_allowed']!,
          _embeddingAllowedMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BlockExercise map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BlockExercise(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      blockId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}block_id'],
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
      embeddingAllowed: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}embedding_allowed'],
      )!,
    );
  }

  @override
  $BlockExercisesTable createAlias(String alias) {
    return $BlockExercisesTable(attachedDatabase, alias);
  }
}

class BlockExercise extends DataClass implements Insertable<BlockExercise> {
  final int id;
  final String blockId;
  final int order;

  /// Resolved match against Exercises.id, same as `PlanExercises.exerciseId`.
  final String? exerciseId;
  final String exerciseName;
  final int sets;
  final String reps;
  final String weightIntensity;
  final int? restSec;
  final String notes;
  final String videoUrl;

  /// Same opt-in as `Exercises.embeddingAllowed`/`PlanExercises.embeddingAllowed`,
  /// carried through the block's own stamp-on-insert copy (see
  /// `BlockExerciseToPlanInput.toPlanInput()`) so it isn't silently reset.
  final bool embeddingAllowed;
  const BlockExercise({
    required this.id,
    required this.blockId,
    required this.order,
    this.exerciseId,
    required this.exerciseName,
    required this.sets,
    required this.reps,
    required this.weightIntensity,
    this.restSec,
    required this.notes,
    required this.videoUrl,
    required this.embeddingAllowed,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['block_id'] = Variable<String>(blockId);
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
    map['embedding_allowed'] = Variable<bool>(embeddingAllowed);
    return map;
  }

  BlockExercisesCompanion toCompanion(bool nullToAbsent) {
    return BlockExercisesCompanion(
      id: Value(id),
      blockId: Value(blockId),
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
      embeddingAllowed: Value(embeddingAllowed),
    );
  }

  factory BlockExercise.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BlockExercise(
      id: serializer.fromJson<int>(json['id']),
      blockId: serializer.fromJson<String>(json['blockId']),
      order: serializer.fromJson<int>(json['order']),
      exerciseId: serializer.fromJson<String?>(json['exerciseId']),
      exerciseName: serializer.fromJson<String>(json['exerciseName']),
      sets: serializer.fromJson<int>(json['sets']),
      reps: serializer.fromJson<String>(json['reps']),
      weightIntensity: serializer.fromJson<String>(json['weightIntensity']),
      restSec: serializer.fromJson<int?>(json['restSec']),
      notes: serializer.fromJson<String>(json['notes']),
      videoUrl: serializer.fromJson<String>(json['videoUrl']),
      embeddingAllowed: serializer.fromJson<bool>(json['embeddingAllowed']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'blockId': serializer.toJson<String>(blockId),
      'order': serializer.toJson<int>(order),
      'exerciseId': serializer.toJson<String?>(exerciseId),
      'exerciseName': serializer.toJson<String>(exerciseName),
      'sets': serializer.toJson<int>(sets),
      'reps': serializer.toJson<String>(reps),
      'weightIntensity': serializer.toJson<String>(weightIntensity),
      'restSec': serializer.toJson<int?>(restSec),
      'notes': serializer.toJson<String>(notes),
      'videoUrl': serializer.toJson<String>(videoUrl),
      'embeddingAllowed': serializer.toJson<bool>(embeddingAllowed),
    };
  }

  BlockExercise copyWith({
    int? id,
    String? blockId,
    int? order,
    Value<String?> exerciseId = const Value.absent(),
    String? exerciseName,
    int? sets,
    String? reps,
    String? weightIntensity,
    Value<int?> restSec = const Value.absent(),
    String? notes,
    String? videoUrl,
    bool? embeddingAllowed,
  }) => BlockExercise(
    id: id ?? this.id,
    blockId: blockId ?? this.blockId,
    order: order ?? this.order,
    exerciseId: exerciseId.present ? exerciseId.value : this.exerciseId,
    exerciseName: exerciseName ?? this.exerciseName,
    sets: sets ?? this.sets,
    reps: reps ?? this.reps,
    weightIntensity: weightIntensity ?? this.weightIntensity,
    restSec: restSec.present ? restSec.value : this.restSec,
    notes: notes ?? this.notes,
    videoUrl: videoUrl ?? this.videoUrl,
    embeddingAllowed: embeddingAllowed ?? this.embeddingAllowed,
  );
  BlockExercise copyWithCompanion(BlockExercisesCompanion data) {
    return BlockExercise(
      id: data.id.present ? data.id.value : this.id,
      blockId: data.blockId.present ? data.blockId.value : this.blockId,
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
      embeddingAllowed: data.embeddingAllowed.present
          ? data.embeddingAllowed.value
          : this.embeddingAllowed,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BlockExercise(')
          ..write('id: $id, ')
          ..write('blockId: $blockId, ')
          ..write('order: $order, ')
          ..write('exerciseId: $exerciseId, ')
          ..write('exerciseName: $exerciseName, ')
          ..write('sets: $sets, ')
          ..write('reps: $reps, ')
          ..write('weightIntensity: $weightIntensity, ')
          ..write('restSec: $restSec, ')
          ..write('notes: $notes, ')
          ..write('videoUrl: $videoUrl, ')
          ..write('embeddingAllowed: $embeddingAllowed')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    blockId,
    order,
    exerciseId,
    exerciseName,
    sets,
    reps,
    weightIntensity,
    restSec,
    notes,
    videoUrl,
    embeddingAllowed,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BlockExercise &&
          other.id == this.id &&
          other.blockId == this.blockId &&
          other.order == this.order &&
          other.exerciseId == this.exerciseId &&
          other.exerciseName == this.exerciseName &&
          other.sets == this.sets &&
          other.reps == this.reps &&
          other.weightIntensity == this.weightIntensity &&
          other.restSec == this.restSec &&
          other.notes == this.notes &&
          other.videoUrl == this.videoUrl &&
          other.embeddingAllowed == this.embeddingAllowed);
}

class BlockExercisesCompanion extends UpdateCompanion<BlockExercise> {
  final Value<int> id;
  final Value<String> blockId;
  final Value<int> order;
  final Value<String?> exerciseId;
  final Value<String> exerciseName;
  final Value<int> sets;
  final Value<String> reps;
  final Value<String> weightIntensity;
  final Value<int?> restSec;
  final Value<String> notes;
  final Value<String> videoUrl;
  final Value<bool> embeddingAllowed;
  const BlockExercisesCompanion({
    this.id = const Value.absent(),
    this.blockId = const Value.absent(),
    this.order = const Value.absent(),
    this.exerciseId = const Value.absent(),
    this.exerciseName = const Value.absent(),
    this.sets = const Value.absent(),
    this.reps = const Value.absent(),
    this.weightIntensity = const Value.absent(),
    this.restSec = const Value.absent(),
    this.notes = const Value.absent(),
    this.videoUrl = const Value.absent(),
    this.embeddingAllowed = const Value.absent(),
  });
  BlockExercisesCompanion.insert({
    this.id = const Value.absent(),
    required String blockId,
    required int order,
    this.exerciseId = const Value.absent(),
    required String exerciseName,
    required int sets,
    required String reps,
    this.weightIntensity = const Value.absent(),
    this.restSec = const Value.absent(),
    this.notes = const Value.absent(),
    this.videoUrl = const Value.absent(),
    this.embeddingAllowed = const Value.absent(),
  }) : blockId = Value(blockId),
       order = Value(order),
       exerciseName = Value(exerciseName),
       sets = Value(sets),
       reps = Value(reps);
  static Insertable<BlockExercise> custom({
    Expression<int>? id,
    Expression<String>? blockId,
    Expression<int>? order,
    Expression<String>? exerciseId,
    Expression<String>? exerciseName,
    Expression<int>? sets,
    Expression<String>? reps,
    Expression<String>? weightIntensity,
    Expression<int>? restSec,
    Expression<String>? notes,
    Expression<String>? videoUrl,
    Expression<bool>? embeddingAllowed,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (blockId != null) 'block_id': blockId,
      if (order != null) 'order': order,
      if (exerciseId != null) 'exercise_id': exerciseId,
      if (exerciseName != null) 'exercise_name': exerciseName,
      if (sets != null) 'sets': sets,
      if (reps != null) 'reps': reps,
      if (weightIntensity != null) 'weight_intensity': weightIntensity,
      if (restSec != null) 'rest_sec': restSec,
      if (notes != null) 'notes': notes,
      if (videoUrl != null) 'video_url': videoUrl,
      if (embeddingAllowed != null) 'embedding_allowed': embeddingAllowed,
    });
  }

  BlockExercisesCompanion copyWith({
    Value<int>? id,
    Value<String>? blockId,
    Value<int>? order,
    Value<String?>? exerciseId,
    Value<String>? exerciseName,
    Value<int>? sets,
    Value<String>? reps,
    Value<String>? weightIntensity,
    Value<int?>? restSec,
    Value<String>? notes,
    Value<String>? videoUrl,
    Value<bool>? embeddingAllowed,
  }) {
    return BlockExercisesCompanion(
      id: id ?? this.id,
      blockId: blockId ?? this.blockId,
      order: order ?? this.order,
      exerciseId: exerciseId ?? this.exerciseId,
      exerciseName: exerciseName ?? this.exerciseName,
      sets: sets ?? this.sets,
      reps: reps ?? this.reps,
      weightIntensity: weightIntensity ?? this.weightIntensity,
      restSec: restSec ?? this.restSec,
      notes: notes ?? this.notes,
      videoUrl: videoUrl ?? this.videoUrl,
      embeddingAllowed: embeddingAllowed ?? this.embeddingAllowed,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (blockId.present) {
      map['block_id'] = Variable<String>(blockId.value);
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
    if (embeddingAllowed.present) {
      map['embedding_allowed'] = Variable<bool>(embeddingAllowed.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BlockExercisesCompanion(')
          ..write('id: $id, ')
          ..write('blockId: $blockId, ')
          ..write('order: $order, ')
          ..write('exerciseId: $exerciseId, ')
          ..write('exerciseName: $exerciseName, ')
          ..write('sets: $sets, ')
          ..write('reps: $reps, ')
          ..write('weightIntensity: $weightIntensity, ')
          ..write('restSec: $restSec, ')
          ..write('notes: $notes, ')
          ..write('videoUrl: $videoUrl, ')
          ..write('embeddingAllowed: $embeddingAllowed')
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
  late final $PlanSessionDatesTable planSessionDates = $PlanSessionDatesTable(
    this,
  );
  late final $PlanExercisesTable planExercises = $PlanExercisesTable(this);
  late final $SessionLogsTable sessionLogs = $SessionLogsTable(this);
  late final $LoggedSetsTable loggedSets = $LoggedSetsTable(this);
  late final $BodyMeasurementsTable bodyMeasurements = $BodyMeasurementsTable(
    this,
  );
  late final $BlocksTable blocks = $BlocksTable(this);
  late final $BlockExercisesTable blockExercises = $BlockExercisesTable(this);
  late final ExerciseDao exerciseDao = ExerciseDao(this as AppDatabase);
  late final PlanDao planDao = PlanDao(this as AppDatabase);
  late final SessionLogDao sessionLogDao = SessionLogDao(this as AppDatabase);
  late final MaintenanceDao maintenanceDao = MaintenanceDao(
    this as AppDatabase,
  );
  late final BodyMeasurementDao bodyMeasurementDao = BodyMeasurementDao(
    this as AppDatabase,
  );
  late final BlockDao blockDao = BlockDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    exercises,
    plans,
    planSessions,
    planSessionDates,
    planExercises,
    sessionLogs,
    loggedSets,
    bodyMeasurements,
    blocks,
    blockExercises,
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
      result: [TableUpdate('plan_session_dates', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'plan_sessions',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('plan_exercises', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'plan_sessions',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('session_logs', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'session_logs',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('logged_sets', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'blocks',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('block_exercises', kind: UpdateKind.delete)],
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
  Value<String?> sourcePlanName,
  Value<String?> author,
  Value<String?> imagePath,
  Value<String?> imagePaths,
  Value<bool> isFavorite,
  Value<bool> embeddingAllowed,
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
  Value<String?> sourcePlanName,
  Value<String?> author,
  Value<String?> imagePath,
  Value<String?> imagePaths,
  Value<bool> isFavorite,
  Value<bool> embeddingAllowed,
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

  static MultiTypedResultKey<$LoggedSetsTable, List<LoggedSet>>
  _loggedSetsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.loggedSets,
    aliasName: 'exercises__id__logged_sets__exercise_id',
  );

  $$LoggedSetsTableProcessedTableManager get loggedSetsRefs {
    final manager = $$LoggedSetsTableTableManager(
      $_db,
      $_db.loggedSets,
    ).filter((f) => f.exerciseId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_loggedSetsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$BlockExercisesTable, List<BlockExercise>>
  _blockExercisesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.blockExercises,
    aliasName: 'exercises__id__block_exercises__exercise_id',
  );

  $$BlockExercisesTableProcessedTableManager get blockExercisesRefs {
    final manager = $$BlockExercisesTableTableManager(
      $_db,
      $_db.blockExercises,
    ).filter((f) => f.exerciseId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_blockExercisesRefsTable($_db));
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

  ColumnFilters<String> get sourcePlanName => $composableBuilder(
    column: $table.sourcePlanName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get author => $composableBuilder(
    column: $table.author,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get imagePath => $composableBuilder(
    column: $table.imagePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get imagePaths => $composableBuilder(
    column: $table.imagePaths,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get embeddingAllowed => $composableBuilder(
    column: $table.embeddingAllowed,
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

  Expression<bool> loggedSetsRefs(
    Expression<bool> Function($$LoggedSetsTableFilterComposer f) f,
  ) {
    final $$LoggedSetsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.loggedSets,
      getReferencedColumn: (t) => t.exerciseId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LoggedSetsTableFilterComposer(
            $db: $db,
            $table: $db.loggedSets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> blockExercisesRefs(
    Expression<bool> Function($$BlockExercisesTableFilterComposer f) f,
  ) {
    final $$BlockExercisesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.blockExercises,
      getReferencedColumn: (t) => t.exerciseId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BlockExercisesTableFilterComposer(
            $db: $db,
            $table: $db.blockExercises,
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

  ColumnOrderings<String> get sourcePlanName => $composableBuilder(
    column: $table.sourcePlanName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get author => $composableBuilder(
    column: $table.author,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get imagePath => $composableBuilder(
    column: $table.imagePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get imagePaths => $composableBuilder(
    column: $table.imagePaths,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get embeddingAllowed => $composableBuilder(
    column: $table.embeddingAllowed,
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

  GeneratedColumn<String> get sourcePlanName => $composableBuilder(
    column: $table.sourcePlanName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get author =>
      $composableBuilder(column: $table.author, builder: (column) => column);

  GeneratedColumn<String> get imagePath =>
      $composableBuilder(column: $table.imagePath, builder: (column) => column);

  GeneratedColumn<String> get imagePaths => $composableBuilder(
    column: $table.imagePaths,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get embeddingAllowed => $composableBuilder(
    column: $table.embeddingAllowed,
    builder: (column) => column,
  );

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

  Expression<T> loggedSetsRefs<T extends Object>(
    Expression<T> Function($$LoggedSetsTableAnnotationComposer a) f,
  ) {
    final $$LoggedSetsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.loggedSets,
      getReferencedColumn: (t) => t.exerciseId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LoggedSetsTableAnnotationComposer(
            $db: $db,
            $table: $db.loggedSets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> blockExercisesRefs<T extends Object>(
    Expression<T> Function($$BlockExercisesTableAnnotationComposer a) f,
  ) {
    final $$BlockExercisesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.blockExercises,
      getReferencedColumn: (t) => t.exerciseId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BlockExercisesTableAnnotationComposer(
            $db: $db,
            $table: $db.blockExercises,
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
          PrefetchHooks Function({
            bool planExercisesRefs,
            bool loggedSetsRefs,
            bool blockExercisesRefs,
          })
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
                Value<String?> sourcePlanName = const Value.absent(),
                Value<String?> author = const Value.absent(),
                Value<String?> imagePath = const Value.absent(),
                Value<String?> imagePaths = const Value.absent(),
                Value<bool> isFavorite = const Value.absent(),
                Value<bool> embeddingAllowed = const Value.absent(),
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
                sourcePlanName: sourcePlanName,
                author: author,
                imagePath: imagePath,
                imagePaths: imagePaths,
                isFavorite: isFavorite,
                embeddingAllowed: embeddingAllowed,
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
                Value<String?> sourcePlanName = const Value.absent(),
                Value<String?> author = const Value.absent(),
                Value<String?> imagePath = const Value.absent(),
                Value<String?> imagePaths = const Value.absent(),
                Value<bool> isFavorite = const Value.absent(),
                Value<bool> embeddingAllowed = const Value.absent(),
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
                sourcePlanName: sourcePlanName,
                author: author,
                imagePath: imagePath,
                imagePaths: imagePaths,
                isFavorite: isFavorite,
                embeddingAllowed: embeddingAllowed,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ExercisesTable, Exercise>(table),
                  $$ExercisesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                planExercisesRefs = false,
                loggedSetsRefs = false,
                blockExercisesRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (planExercisesRefs) db.planExercises,
                    if (loggedSetsRefs) db.loggedSets,
                    if (blockExercisesRefs) db.blockExercises,
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
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.exerciseId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (loggedSetsRefs)
                        await $_getPrefetchedData<
                          Exercise,
                          $ExercisesTable,
                          LoggedSet
                        >(
                          currentTable: table,
                          referencedTable: $$ExercisesTableReferences
                              ._loggedSetsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ExercisesTableReferences(
                                db,
                                table,
                                p0,
                              ).loggedSetsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.exerciseId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (blockExercisesRefs)
                        await $_getPrefetchedData<
                          Exercise,
                          $ExercisesTable,
                          BlockExercise
                        >(
                          currentTable: table,
                          referencedTable: $$ExercisesTableReferences
                              ._blockExercisesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ExercisesTableReferences(
                                db,
                                table,
                                p0,
                              ).blockExercisesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.exerciseId == item.id,
                              ),
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
      PrefetchHooks Function({
        bool planExercisesRefs,
        bool loggedSetsRefs,
        bool blockExercisesRefs,
      })
    >;
typedef $$PlansTableCreateCompanionBuilder = PlansCompanion Function({
  required String id,
  required String name,
  Value<String> notes,
  Value<String?> createdBy,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<DateTime?> archivedAt,
  Value<String> reportPreference,
  Value<int?> reportFrequencyDays,
  Value<DateTime?> reportOptInAt,
  Value<int> rowid,
});
typedef $$PlansTableUpdateCompanionBuilder = PlansCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<String> notes,
  Value<String?> createdBy,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> archivedAt,
  Value<String> reportPreference,
  Value<int?> reportFrequencyDays,
  Value<DateTime?> reportOptInAt,
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

  ColumnFilters<String> get createdBy => $composableBuilder(
    column: $table.createdBy,
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

  ColumnFilters<DateTime> get archivedAt => $composableBuilder(
    column: $table.archivedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reportPreference => $composableBuilder(
    column: $table.reportPreference,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get reportFrequencyDays => $composableBuilder(
    column: $table.reportFrequencyDays,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get reportOptInAt => $composableBuilder(
    column: $table.reportOptInAt,
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

  ColumnOrderings<String> get createdBy => $composableBuilder(
    column: $table.createdBy,
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

  ColumnOrderings<DateTime> get archivedAt => $composableBuilder(
    column: $table.archivedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reportPreference => $composableBuilder(
    column: $table.reportPreference,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get reportFrequencyDays => $composableBuilder(
    column: $table.reportFrequencyDays,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get reportOptInAt => $composableBuilder(
    column: $table.reportOptInAt,
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

  GeneratedColumn<String> get createdBy =>
      $composableBuilder(column: $table.createdBy, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get archivedAt => $composableBuilder(
    column: $table.archivedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get reportPreference => $composableBuilder(
    column: $table.reportPreference,
    builder: (column) => column,
  );

  GeneratedColumn<int> get reportFrequencyDays => $composableBuilder(
    column: $table.reportFrequencyDays,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get reportOptInAt => $composableBuilder(
    column: $table.reportOptInAt,
    builder: (column) => column,
  );

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
                Value<String?> createdBy = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> archivedAt = const Value.absent(),
                Value<String> reportPreference = const Value.absent(),
                Value<int?> reportFrequencyDays = const Value.absent(),
                Value<DateTime?> reportOptInAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PlansCompanion(
                id: id,
                name: name,
                notes: notes,
                createdBy: createdBy,
                createdAt: createdAt,
                updatedAt: updatedAt,
                archivedAt: archivedAt,
                reportPreference: reportPreference,
                reportFrequencyDays: reportFrequencyDays,
                reportOptInAt: reportOptInAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<String> notes = const Value.absent(),
                Value<String?> createdBy = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<DateTime?> archivedAt = const Value.absent(),
                Value<String> reportPreference = const Value.absent(),
                Value<int?> reportFrequencyDays = const Value.absent(),
                Value<DateTime?> reportOptInAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PlansCompanion.insert(
                id: id,
                name: name,
                notes: notes,
                createdBy: createdBy,
                createdAt: createdAt,
                updatedAt: updatedAt,
                archivedAt: archivedAt,
                reportPreference: reportPreference,
                reportFrequencyDays: reportFrequencyDays,
                reportOptInAt: reportOptInAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PlansTable, Plan>(table),
                  $$PlansTableReferences(db, table, e),
                ),
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
    });
typedef $$PlanSessionsTableUpdateCompanionBuilder =
    PlanSessionsCompanion Function({
      Value<int> id,
      Value<String> planId,
      Value<int> weekNumber,
      Value<String> day,
      Value<String> sessionName,
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

  static MultiTypedResultKey<$PlanSessionDatesTable, List<PlanSessionDate>>
  _planSessionDatesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.planSessionDates,
    aliasName: 'plan_sessions__id__plan_session_dates__session_id',
  );

  $$PlanSessionDatesTableProcessedTableManager get planSessionDatesRefs {
    final manager = $$PlanSessionDatesTableTableManager(
      $_db,
      $_db.planSessionDates,
    ).filter((f) => f.sessionId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _planSessionDatesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
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

  static MultiTypedResultKey<$SessionLogsTable, List<SessionLog>>
  _sessionLogsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.sessionLogs,
    aliasName: 'plan_sessions__id__session_logs__plan_session_id',
  );

  $$SessionLogsTableProcessedTableManager get sessionLogsRefs {
    final manager = $$SessionLogsTableTableManager(
      $_db,
      $_db.sessionLogs,
    ).filter((f) => f.planSessionId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_sessionLogsRefsTable($_db));
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

  Expression<bool> planSessionDatesRefs(
    Expression<bool> Function($$PlanSessionDatesTableFilterComposer f) f,
  ) {
    final $$PlanSessionDatesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.planSessionDates,
      getReferencedColumn: (t) => t.sessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlanSessionDatesTableFilterComposer(
            $db: $db,
            $table: $db.planSessionDates,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
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

  Expression<bool> sessionLogsRefs(
    Expression<bool> Function($$SessionLogsTableFilterComposer f) f,
  ) {
    final $$SessionLogsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.sessionLogs,
      getReferencedColumn: (t) => t.planSessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionLogsTableFilterComposer(
            $db: $db,
            $table: $db.sessionLogs,
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

  Expression<T> planSessionDatesRefs<T extends Object>(
    Expression<T> Function($$PlanSessionDatesTableAnnotationComposer a) f,
  ) {
    final $$PlanSessionDatesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.planSessionDates,
      getReferencedColumn: (t) => t.sessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlanSessionDatesTableAnnotationComposer(
            $db: $db,
            $table: $db.planSessionDates,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
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

  Expression<T> sessionLogsRefs<T extends Object>(
    Expression<T> Function($$SessionLogsTableAnnotationComposer a) f,
  ) {
    final $$SessionLogsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.sessionLogs,
      getReferencedColumn: (t) => t.planSessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionLogsTableAnnotationComposer(
            $db: $db,
            $table: $db.sessionLogs,
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
          PrefetchHooks Function({
            bool planId,
            bool planSessionDatesRefs,
            bool planExercisesRefs,
            bool sessionLogsRefs,
          })
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
              }) => PlanSessionsCompanion(
                id: id,
                planId: planId,
                weekNumber: weekNumber,
                day: day,
                sessionName: sessionName,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String planId,
                required int weekNumber,
                required String day,
                required String sessionName,
              }) => PlanSessionsCompanion.insert(
                id: id,
                planId: planId,
                weekNumber: weekNumber,
                day: day,
                sessionName: sessionName,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PlanSessionsTable, PlanSession>(table),
                  $$PlanSessionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                planId = false,
                planSessionDatesRefs = false,
                planExercisesRefs = false,
                sessionLogsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (planSessionDatesRefs) db.planSessionDates,
                    if (planExercisesRefs) db.planExercises,
                    if (sessionLogsRefs) db.sessionLogs,
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
                      if (planSessionDatesRefs)
                        await $_getPrefetchedData<
                          PlanSession,
                          $PlanSessionsTable,
                          PlanSessionDate
                        >(
                          currentTable: table,
                          referencedTable: $$PlanSessionsTableReferences
                              ._planSessionDatesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$PlanSessionsTableReferences(
                                db,
                                table,
                                p0,
                              ).planSessionDatesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.sessionId == item.id,
                              ),
                          typedResults: items,
                        ),
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
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.sessionId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (sessionLogsRefs)
                        await $_getPrefetchedData<
                          PlanSession,
                          $PlanSessionsTable,
                          SessionLog
                        >(
                          currentTable: table,
                          referencedTable: $$PlanSessionsTableReferences
                              ._sessionLogsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$PlanSessionsTableReferences(
                                db,
                                table,
                                p0,
                              ).sessionLogsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.planSessionId == item.id,
                              ),
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
      PrefetchHooks Function({
        bool planId,
        bool planSessionDatesRefs,
        bool planExercisesRefs,
        bool sessionLogsRefs,
      })
    >;
typedef $$PlanSessionDatesTableCreateCompanionBuilder =
    PlanSessionDatesCompanion Function({
      Value<int> id,
      required int sessionId,
      required DateTime date,
    });
typedef $$PlanSessionDatesTableUpdateCompanionBuilder =
    PlanSessionDatesCompanion Function({
      Value<int> id,
      Value<int> sessionId,
      Value<DateTime> date,
    });

final class $$PlanSessionDatesTableReferences
    extends
        BaseReferences<_$AppDatabase, $PlanSessionDatesTable, PlanSessionDate> {
  $$PlanSessionDatesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $PlanSessionsTable _sessionIdTable(_$AppDatabase db) => db.planSessions
      .createAlias('plan_session_dates__session_id__plan_sessions__id');

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
}

class $$PlanSessionDatesTableFilterComposer
    extends Composer<_$AppDatabase, $PlanSessionDatesTable> {
  $$PlanSessionDatesTableFilterComposer({
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

  ColumnFilters<DateTime> get date => $composableBuilder(
    column: $table.date,
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
}

class $$PlanSessionDatesTableOrderingComposer
    extends Composer<_$AppDatabase, $PlanSessionDatesTable> {
  $$PlanSessionDatesTableOrderingComposer({
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

  ColumnOrderings<DateTime> get date => $composableBuilder(
    column: $table.date,
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
}

class $$PlanSessionDatesTableAnnotationComposer
    extends Composer<_$AppDatabase, $PlanSessionDatesTable> {
  $$PlanSessionDatesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

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
}

class $$PlanSessionDatesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PlanSessionDatesTable,
          PlanSessionDate,
          $$PlanSessionDatesTableFilterComposer,
          $$PlanSessionDatesTableOrderingComposer,
          $$PlanSessionDatesTableAnnotationComposer,
          $$PlanSessionDatesTableCreateCompanionBuilder,
          $$PlanSessionDatesTableUpdateCompanionBuilder,
          (PlanSessionDate, $$PlanSessionDatesTableReferences),
          PlanSessionDate,
          PrefetchHooks Function({bool sessionId})
        > {
  $$PlanSessionDatesTableTableManager(
    _$AppDatabase db,
    $PlanSessionDatesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlanSessionDatesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlanSessionDatesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PlanSessionDatesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> sessionId = const Value.absent(),
                Value<DateTime> date = const Value.absent(),
              }) => PlanSessionDatesCompanion(
                id: id,
                sessionId: sessionId,
                date: date,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int sessionId,
                required DateTime date,
              }) => PlanSessionDatesCompanion.insert(
                id: id,
                sessionId: sessionId,
                date: date,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PlanSessionDatesTable, PlanSessionDate>(table),
                  $$PlanSessionDatesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({sessionId = false}) {
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
                        referencedTable: $$PlanSessionDatesTableReferences
                            ._sessionIdTable(db),
                        referencedColumn: $$PlanSessionDatesTableReferences
                            ._sessionIdTable(db)
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

typedef $$PlanSessionDatesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PlanSessionDatesTable,
      PlanSessionDate,
      $$PlanSessionDatesTableFilterComposer,
      $$PlanSessionDatesTableOrderingComposer,
      $$PlanSessionDatesTableAnnotationComposer,
      $$PlanSessionDatesTableCreateCompanionBuilder,
      $$PlanSessionDatesTableUpdateCompanionBuilder,
      (PlanSessionDate, $$PlanSessionDatesTableReferences),
      PlanSessionDate,
      PrefetchHooks Function({bool sessionId})
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
      Value<int?> supersetGroupId,
      Value<bool> embeddingAllowed,
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
      Value<int?> supersetGroupId,
      Value<bool> embeddingAllowed,
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

  ColumnFilters<int> get supersetGroupId => $composableBuilder(
    column: $table.supersetGroupId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get embeddingAllowed => $composableBuilder(
    column: $table.embeddingAllowed,
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

  ColumnOrderings<int> get supersetGroupId => $composableBuilder(
    column: $table.supersetGroupId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get embeddingAllowed => $composableBuilder(
    column: $table.embeddingAllowed,
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

  GeneratedColumn<int> get supersetGroupId => $composableBuilder(
    column: $table.supersetGroupId,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get embeddingAllowed => $composableBuilder(
    column: $table.embeddingAllowed,
    builder: (column) => column,
  );

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
                Value<int?> supersetGroupId = const Value.absent(),
                Value<bool> embeddingAllowed = const Value.absent(),
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
                supersetGroupId: supersetGroupId,
                embeddingAllowed: embeddingAllowed,
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
                Value<int?> supersetGroupId = const Value.absent(),
                Value<bool> embeddingAllowed = const Value.absent(),
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
                supersetGroupId: supersetGroupId,
                embeddingAllowed: embeddingAllowed,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PlanExercisesTable, PlanExercise>(table),
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
typedef $$SessionLogsTableCreateCompanionBuilder =
    SessionLogsCompanion Function({
      required String id,
      Value<int?> planSessionId,
      required DateTime loggedAt,
      Value<DateTime?> finishedAt,
      Value<String?> notes,
      Value<String?> activityName,
      Value<double?> durationSec,
      Value<double?> distance,
      Value<int> rowid,
    });
typedef $$SessionLogsTableUpdateCompanionBuilder =
    SessionLogsCompanion Function({
      Value<String> id,
      Value<int?> planSessionId,
      Value<DateTime> loggedAt,
      Value<DateTime?> finishedAt,
      Value<String?> notes,
      Value<String?> activityName,
      Value<double?> durationSec,
      Value<double?> distance,
      Value<int> rowid,
    });

final class $$SessionLogsTableReferences
    extends BaseReferences<_$AppDatabase, $SessionLogsTable, SessionLog> {
  $$SessionLogsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $PlanSessionsTable _planSessionIdTable(_$AppDatabase db) => db
      .planSessions
      .createAlias('session_logs__plan_session_id__plan_sessions__id');

  $$PlanSessionsTableProcessedTableManager? get planSessionId {
    final $_column = $_itemColumn<int>('plan_session_id');
    if ($_column == null) return null;
    final manager = $$PlanSessionsTableTableManager(
      $_db,
      $_db.planSessions,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_planSessionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$LoggedSetsTable, List<LoggedSet>>
  _loggedSetsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.loggedSets,
    aliasName: 'session_logs__id__logged_sets__session_log_id',
  );

  $$LoggedSetsTableProcessedTableManager get loggedSetsRefs {
    final manager = $$LoggedSetsTableTableManager(
      $_db,
      $_db.loggedSets,
    ).filter((f) => f.sessionLogId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_loggedSetsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$SessionLogsTableFilterComposer
    extends Composer<_$AppDatabase, $SessionLogsTable> {
  $$SessionLogsTableFilterComposer({
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

  ColumnFilters<DateTime> get loggedAt => $composableBuilder(
    column: $table.loggedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get finishedAt => $composableBuilder(
    column: $table.finishedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get activityName => $composableBuilder(
    column: $table.activityName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get durationSec => $composableBuilder(
    column: $table.durationSec,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get distance => $composableBuilder(
    column: $table.distance,
    builder: (column) => ColumnFilters(column),
  );

  $$PlanSessionsTableFilterComposer get planSessionId {
    final $$PlanSessionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.planSessionId,
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

  Expression<bool> loggedSetsRefs(
    Expression<bool> Function($$LoggedSetsTableFilterComposer f) f,
  ) {
    final $$LoggedSetsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.loggedSets,
      getReferencedColumn: (t) => t.sessionLogId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LoggedSetsTableFilterComposer(
            $db: $db,
            $table: $db.loggedSets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SessionLogsTableOrderingComposer
    extends Composer<_$AppDatabase, $SessionLogsTable> {
  $$SessionLogsTableOrderingComposer({
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

  ColumnOrderings<DateTime> get loggedAt => $composableBuilder(
    column: $table.loggedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get finishedAt => $composableBuilder(
    column: $table.finishedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get activityName => $composableBuilder(
    column: $table.activityName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get durationSec => $composableBuilder(
    column: $table.durationSec,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get distance => $composableBuilder(
    column: $table.distance,
    builder: (column) => ColumnOrderings(column),
  );

  $$PlanSessionsTableOrderingComposer get planSessionId {
    final $$PlanSessionsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.planSessionId,
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
}

class $$SessionLogsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SessionLogsTable> {
  $$SessionLogsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get loggedAt =>
      $composableBuilder(column: $table.loggedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get finishedAt => $composableBuilder(
    column: $table.finishedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<String> get activityName => $composableBuilder(
    column: $table.activityName,
    builder: (column) => column,
  );

  GeneratedColumn<double> get durationSec => $composableBuilder(
    column: $table.durationSec,
    builder: (column) => column,
  );

  GeneratedColumn<double> get distance =>
      $composableBuilder(column: $table.distance, builder: (column) => column);

  $$PlanSessionsTableAnnotationComposer get planSessionId {
    final $$PlanSessionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.planSessionId,
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

  Expression<T> loggedSetsRefs<T extends Object>(
    Expression<T> Function($$LoggedSetsTableAnnotationComposer a) f,
  ) {
    final $$LoggedSetsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.loggedSets,
      getReferencedColumn: (t) => t.sessionLogId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LoggedSetsTableAnnotationComposer(
            $db: $db,
            $table: $db.loggedSets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SessionLogsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SessionLogsTable,
          SessionLog,
          $$SessionLogsTableFilterComposer,
          $$SessionLogsTableOrderingComposer,
          $$SessionLogsTableAnnotationComposer,
          $$SessionLogsTableCreateCompanionBuilder,
          $$SessionLogsTableUpdateCompanionBuilder,
          (SessionLog, $$SessionLogsTableReferences),
          SessionLog,
          PrefetchHooks Function({bool planSessionId, bool loggedSetsRefs})
        > {
  $$SessionLogsTableTableManager(_$AppDatabase db, $SessionLogsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SessionLogsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SessionLogsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SessionLogsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int?> planSessionId = const Value.absent(),
                Value<DateTime> loggedAt = const Value.absent(),
                Value<DateTime?> finishedAt = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String?> activityName = const Value.absent(),
                Value<double?> durationSec = const Value.absent(),
                Value<double?> distance = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SessionLogsCompanion(
                id: id,
                planSessionId: planSessionId,
                loggedAt: loggedAt,
                finishedAt: finishedAt,
                notes: notes,
                activityName: activityName,
                durationSec: durationSec,
                distance: distance,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<int?> planSessionId = const Value.absent(),
                required DateTime loggedAt,
                Value<DateTime?> finishedAt = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String?> activityName = const Value.absent(),
                Value<double?> durationSec = const Value.absent(),
                Value<double?> distance = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SessionLogsCompanion.insert(
                id: id,
                planSessionId: planSessionId,
                loggedAt: loggedAt,
                finishedAt: finishedAt,
                notes: notes,
                activityName: activityName,
                durationSec: durationSec,
                distance: distance,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SessionLogsTable, SessionLog>(table),
                  $$SessionLogsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({planSessionId = false, loggedSetsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [if (loggedSetsRefs) db.loggedSets],
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
                        if (planSessionId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.planSessionId,
                            referencedTable: $$SessionLogsTableReferences
                                ._planSessionIdTable(db),
                            referencedColumn: $$SessionLogsTableReferences
                                ._planSessionIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (loggedSetsRefs)
                        await $_getPrefetchedData<
                          SessionLog,
                          $SessionLogsTable,
                          LoggedSet
                        >(
                          currentTable: table,
                          referencedTable: $$SessionLogsTableReferences
                              ._loggedSetsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$SessionLogsTableReferences(
                                db,
                                table,
                                p0,
                              ).loggedSetsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.sessionLogId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$SessionLogsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SessionLogsTable,
      SessionLog,
      $$SessionLogsTableFilterComposer,
      $$SessionLogsTableOrderingComposer,
      $$SessionLogsTableAnnotationComposer,
      $$SessionLogsTableCreateCompanionBuilder,
      $$SessionLogsTableUpdateCompanionBuilder,
      (SessionLog, $$SessionLogsTableReferences),
      SessionLog,
      PrefetchHooks Function({bool planSessionId, bool loggedSetsRefs})
    >;
typedef $$LoggedSetsTableCreateCompanionBuilder = LoggedSetsCompanion Function({
  Value<int> id,
  required String sessionLogId,
  required String exerciseId,
  required int setNumber,
  Value<int?> reps,
  Value<double?> weight,
  Value<double?> durationSec,
  Value<double?> distance,
  Value<double?> rpe,
  Value<bool> isPr,
});
typedef $$LoggedSetsTableUpdateCompanionBuilder = LoggedSetsCompanion Function({
  Value<int> id,
  Value<String> sessionLogId,
  Value<String> exerciseId,
  Value<int> setNumber,
  Value<int?> reps,
  Value<double?> weight,
  Value<double?> durationSec,
  Value<double?> distance,
  Value<double?> rpe,
  Value<bool> isPr,
});

final class $$LoggedSetsTableReferences
    extends BaseReferences<_$AppDatabase, $LoggedSetsTable, LoggedSet> {
  $$LoggedSetsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $SessionLogsTable _sessionLogIdTable(_$AppDatabase db) => db
      .sessionLogs
      .createAlias('logged_sets__session_log_id__session_logs__id');

  $$SessionLogsTableProcessedTableManager get sessionLogId {
    final $_column = $_itemColumn<String>('session_log_id')!;

    final manager = $$SessionLogsTableTableManager(
      $_db,
      $_db.sessionLogs,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_sessionLogIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $ExercisesTable _exerciseIdTable(_$AppDatabase db) =>
      db.exercises.createAlias('logged_sets__exercise_id__exercises__id');

  $$ExercisesTableProcessedTableManager get exerciseId {
    final $_column = $_itemColumn<String>('exercise_id')!;

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

class $$LoggedSetsTableFilterComposer
    extends Composer<_$AppDatabase, $LoggedSetsTable> {
  $$LoggedSetsTableFilterComposer({
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

  ColumnFilters<int> get setNumber => $composableBuilder(
    column: $table.setNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get reps => $composableBuilder(
    column: $table.reps,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get weight => $composableBuilder(
    column: $table.weight,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get durationSec => $composableBuilder(
    column: $table.durationSec,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get distance => $composableBuilder(
    column: $table.distance,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get rpe => $composableBuilder(
    column: $table.rpe,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isPr => $composableBuilder(
    column: $table.isPr,
    builder: (column) => ColumnFilters(column),
  );

  $$SessionLogsTableFilterComposer get sessionLogId {
    final $$SessionLogsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionLogId,
      referencedTable: $db.sessionLogs,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionLogsTableFilterComposer(
            $db: $db,
            $table: $db.sessionLogs,
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

class $$LoggedSetsTableOrderingComposer
    extends Composer<_$AppDatabase, $LoggedSetsTable> {
  $$LoggedSetsTableOrderingComposer({
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

  ColumnOrderings<int> get setNumber => $composableBuilder(
    column: $table.setNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get reps => $composableBuilder(
    column: $table.reps,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get weight => $composableBuilder(
    column: $table.weight,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get durationSec => $composableBuilder(
    column: $table.durationSec,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get distance => $composableBuilder(
    column: $table.distance,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get rpe => $composableBuilder(
    column: $table.rpe,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isPr => $composableBuilder(
    column: $table.isPr,
    builder: (column) => ColumnOrderings(column),
  );

  $$SessionLogsTableOrderingComposer get sessionLogId {
    final $$SessionLogsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionLogId,
      referencedTable: $db.sessionLogs,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionLogsTableOrderingComposer(
            $db: $db,
            $table: $db.sessionLogs,
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

class $$LoggedSetsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LoggedSetsTable> {
  $$LoggedSetsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get setNumber =>
      $composableBuilder(column: $table.setNumber, builder: (column) => column);

  GeneratedColumn<int> get reps =>
      $composableBuilder(column: $table.reps, builder: (column) => column);

  GeneratedColumn<double> get weight =>
      $composableBuilder(column: $table.weight, builder: (column) => column);

  GeneratedColumn<double> get durationSec => $composableBuilder(
    column: $table.durationSec,
    builder: (column) => column,
  );

  GeneratedColumn<double> get distance =>
      $composableBuilder(column: $table.distance, builder: (column) => column);

  GeneratedColumn<double> get rpe =>
      $composableBuilder(column: $table.rpe, builder: (column) => column);

  GeneratedColumn<bool> get isPr =>
      $composableBuilder(column: $table.isPr, builder: (column) => column);

  $$SessionLogsTableAnnotationComposer get sessionLogId {
    final $$SessionLogsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionLogId,
      referencedTable: $db.sessionLogs,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionLogsTableAnnotationComposer(
            $db: $db,
            $table: $db.sessionLogs,
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

class $$LoggedSetsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LoggedSetsTable,
          LoggedSet,
          $$LoggedSetsTableFilterComposer,
          $$LoggedSetsTableOrderingComposer,
          $$LoggedSetsTableAnnotationComposer,
          $$LoggedSetsTableCreateCompanionBuilder,
          $$LoggedSetsTableUpdateCompanionBuilder,
          (LoggedSet, $$LoggedSetsTableReferences),
          LoggedSet,
          PrefetchHooks Function({bool sessionLogId, bool exerciseId})
        > {
  $$LoggedSetsTableTableManager(_$AppDatabase db, $LoggedSetsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LoggedSetsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LoggedSetsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LoggedSetsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> sessionLogId = const Value.absent(),
                Value<String> exerciseId = const Value.absent(),
                Value<int> setNumber = const Value.absent(),
                Value<int?> reps = const Value.absent(),
                Value<double?> weight = const Value.absent(),
                Value<double?> durationSec = const Value.absent(),
                Value<double?> distance = const Value.absent(),
                Value<double?> rpe = const Value.absent(),
                Value<bool> isPr = const Value.absent(),
              }) => LoggedSetsCompanion(
                id: id,
                sessionLogId: sessionLogId,
                exerciseId: exerciseId,
                setNumber: setNumber,
                reps: reps,
                weight: weight,
                durationSec: durationSec,
                distance: distance,
                rpe: rpe,
                isPr: isPr,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String sessionLogId,
                required String exerciseId,
                required int setNumber,
                Value<int?> reps = const Value.absent(),
                Value<double?> weight = const Value.absent(),
                Value<double?> durationSec = const Value.absent(),
                Value<double?> distance = const Value.absent(),
                Value<double?> rpe = const Value.absent(),
                Value<bool> isPr = const Value.absent(),
              }) => LoggedSetsCompanion.insert(
                id: id,
                sessionLogId: sessionLogId,
                exerciseId: exerciseId,
                setNumber: setNumber,
                reps: reps,
                weight: weight,
                durationSec: durationSec,
                distance: distance,
                rpe: rpe,
                isPr: isPr,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LoggedSetsTable, LoggedSet>(table),
                  $$LoggedSetsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({sessionLogId = false, exerciseId = false}) {
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
                    if (sessionLogId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.sessionLogId,
                        referencedTable: $$LoggedSetsTableReferences
                            ._sessionLogIdTable(db),
                        referencedColumn: $$LoggedSetsTableReferences
                            ._sessionLogIdTable(db)
                            .id,
                      ) as T;
                    }
                    if (exerciseId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.exerciseId,
                        referencedTable: $$LoggedSetsTableReferences
                            ._exerciseIdTable(db),
                        referencedColumn: $$LoggedSetsTableReferences
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

typedef $$LoggedSetsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LoggedSetsTable,
      LoggedSet,
      $$LoggedSetsTableFilterComposer,
      $$LoggedSetsTableOrderingComposer,
      $$LoggedSetsTableAnnotationComposer,
      $$LoggedSetsTableCreateCompanionBuilder,
      $$LoggedSetsTableUpdateCompanionBuilder,
      (LoggedSet, $$LoggedSetsTableReferences),
      LoggedSet,
      PrefetchHooks Function({bool sessionLogId, bool exerciseId})
    >;
typedef $$BodyMeasurementsTableCreateCompanionBuilder =
    BodyMeasurementsCompanion Function({
      required String id,
      required DateTime measuredAt,
      Value<double?> weightKg,
      Value<double?> bodyFatPercent,
      Value<double?> chestCm,
      Value<double?> waistCm,
      Value<double?> hipsCm,
      Value<double?> thighCm,
      Value<double?> armCm,
      Value<String> notes,
      Value<int> rowid,
    });
typedef $$BodyMeasurementsTableUpdateCompanionBuilder =
    BodyMeasurementsCompanion Function({
      Value<String> id,
      Value<DateTime> measuredAt,
      Value<double?> weightKg,
      Value<double?> bodyFatPercent,
      Value<double?> chestCm,
      Value<double?> waistCm,
      Value<double?> hipsCm,
      Value<double?> thighCm,
      Value<double?> armCm,
      Value<String> notes,
      Value<int> rowid,
    });

class $$BodyMeasurementsTableFilterComposer
    extends Composer<_$AppDatabase, $BodyMeasurementsTable> {
  $$BodyMeasurementsTableFilterComposer({
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

  ColumnFilters<DateTime> get measuredAt => $composableBuilder(
    column: $table.measuredAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get weightKg => $composableBuilder(
    column: $table.weightKg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get bodyFatPercent => $composableBuilder(
    column: $table.bodyFatPercent,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get chestCm => $composableBuilder(
    column: $table.chestCm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get waistCm => $composableBuilder(
    column: $table.waistCm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get hipsCm => $composableBuilder(
    column: $table.hipsCm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get thighCm => $composableBuilder(
    column: $table.thighCm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get armCm => $composableBuilder(
    column: $table.armCm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );
}

class $$BodyMeasurementsTableOrderingComposer
    extends Composer<_$AppDatabase, $BodyMeasurementsTable> {
  $$BodyMeasurementsTableOrderingComposer({
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

  ColumnOrderings<DateTime> get measuredAt => $composableBuilder(
    column: $table.measuredAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get weightKg => $composableBuilder(
    column: $table.weightKg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get bodyFatPercent => $composableBuilder(
    column: $table.bodyFatPercent,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get chestCm => $composableBuilder(
    column: $table.chestCm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get waistCm => $composableBuilder(
    column: $table.waistCm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get hipsCm => $composableBuilder(
    column: $table.hipsCm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get thighCm => $composableBuilder(
    column: $table.thighCm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get armCm => $composableBuilder(
    column: $table.armCm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BodyMeasurementsTableAnnotationComposer
    extends Composer<_$AppDatabase, $BodyMeasurementsTable> {
  $$BodyMeasurementsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get measuredAt => $composableBuilder(
    column: $table.measuredAt,
    builder: (column) => column,
  );

  GeneratedColumn<double> get weightKg =>
      $composableBuilder(column: $table.weightKg, builder: (column) => column);

  GeneratedColumn<double> get bodyFatPercent => $composableBuilder(
    column: $table.bodyFatPercent,
    builder: (column) => column,
  );

  GeneratedColumn<double> get chestCm =>
      $composableBuilder(column: $table.chestCm, builder: (column) => column);

  GeneratedColumn<double> get waistCm =>
      $composableBuilder(column: $table.waistCm, builder: (column) => column);

  GeneratedColumn<double> get hipsCm =>
      $composableBuilder(column: $table.hipsCm, builder: (column) => column);

  GeneratedColumn<double> get thighCm =>
      $composableBuilder(column: $table.thighCm, builder: (column) => column);

  GeneratedColumn<double> get armCm =>
      $composableBuilder(column: $table.armCm, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);
}

class $$BodyMeasurementsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BodyMeasurementsTable,
          BodyMeasurement,
          $$BodyMeasurementsTableFilterComposer,
          $$BodyMeasurementsTableOrderingComposer,
          $$BodyMeasurementsTableAnnotationComposer,
          $$BodyMeasurementsTableCreateCompanionBuilder,
          $$BodyMeasurementsTableUpdateCompanionBuilder,
          (
            BodyMeasurement,
            BaseReferences<
              _$AppDatabase,
              $BodyMeasurementsTable,
              BodyMeasurement
            >,
          ),
          BodyMeasurement,
          PrefetchHooks Function()
        > {
  $$BodyMeasurementsTableTableManager(
    _$AppDatabase db,
    $BodyMeasurementsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BodyMeasurementsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BodyMeasurementsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BodyMeasurementsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> measuredAt = const Value.absent(),
                Value<double?> weightKg = const Value.absent(),
                Value<double?> bodyFatPercent = const Value.absent(),
                Value<double?> chestCm = const Value.absent(),
                Value<double?> waistCm = const Value.absent(),
                Value<double?> hipsCm = const Value.absent(),
                Value<double?> thighCm = const Value.absent(),
                Value<double?> armCm = const Value.absent(),
                Value<String> notes = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BodyMeasurementsCompanion(
                id: id,
                measuredAt: measuredAt,
                weightKg: weightKg,
                bodyFatPercent: bodyFatPercent,
                chestCm: chestCm,
                waistCm: waistCm,
                hipsCm: hipsCm,
                thighCm: thighCm,
                armCm: armCm,
                notes: notes,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required DateTime measuredAt,
                Value<double?> weightKg = const Value.absent(),
                Value<double?> bodyFatPercent = const Value.absent(),
                Value<double?> chestCm = const Value.absent(),
                Value<double?> waistCm = const Value.absent(),
                Value<double?> hipsCm = const Value.absent(),
                Value<double?> thighCm = const Value.absent(),
                Value<double?> armCm = const Value.absent(),
                Value<String> notes = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BodyMeasurementsCompanion.insert(
                id: id,
                measuredAt: measuredAt,
                weightKg: weightKg,
                bodyFatPercent: bodyFatPercent,
                chestCm: chestCm,
                waistCm: waistCm,
                hipsCm: hipsCm,
                thighCm: thighCm,
                armCm: armCm,
                notes: notes,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$BodyMeasurementsTable, BodyMeasurement>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $BodyMeasurementsTable,
                    BodyMeasurement
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$BodyMeasurementsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BodyMeasurementsTable,
      BodyMeasurement,
      $$BodyMeasurementsTableFilterComposer,
      $$BodyMeasurementsTableOrderingComposer,
      $$BodyMeasurementsTableAnnotationComposer,
      $$BodyMeasurementsTableCreateCompanionBuilder,
      $$BodyMeasurementsTableUpdateCompanionBuilder,
      (
        BodyMeasurement,
        BaseReferences<_$AppDatabase, $BodyMeasurementsTable, BodyMeasurement>,
      ),
      BodyMeasurement,
      PrefetchHooks Function()
    >;
typedef $$BlocksTableCreateCompanionBuilder = BlocksCompanion Function({
  required String id,
  required String name,
  Value<String> notes,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$BlocksTableUpdateCompanionBuilder = BlocksCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<String> notes,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

final class $$BlocksTableReferences
    extends BaseReferences<_$AppDatabase, $BlocksTable, Block> {
  $$BlocksTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$BlockExercisesTable, List<BlockExercise>>
  _blockExercisesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.blockExercises,
    aliasName: 'blocks__id__block_exercises__block_id',
  );

  $$BlockExercisesTableProcessedTableManager get blockExercisesRefs {
    final manager = $$BlockExercisesTableTableManager(
      $_db,
      $_db.blockExercises,
    ).filter((f) => f.blockId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_blockExercisesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$BlocksTableFilterComposer
    extends Composer<_$AppDatabase, $BlocksTable> {
  $$BlocksTableFilterComposer({
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

  Expression<bool> blockExercisesRefs(
    Expression<bool> Function($$BlockExercisesTableFilterComposer f) f,
  ) {
    final $$BlockExercisesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.blockExercises,
      getReferencedColumn: (t) => t.blockId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BlockExercisesTableFilterComposer(
            $db: $db,
            $table: $db.blockExercises,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$BlocksTableOrderingComposer
    extends Composer<_$AppDatabase, $BlocksTable> {
  $$BlocksTableOrderingComposer({
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

class $$BlocksTableAnnotationComposer
    extends Composer<_$AppDatabase, $BlocksTable> {
  $$BlocksTableAnnotationComposer({
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

  Expression<T> blockExercisesRefs<T extends Object>(
    Expression<T> Function($$BlockExercisesTableAnnotationComposer a) f,
  ) {
    final $$BlockExercisesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.blockExercises,
      getReferencedColumn: (t) => t.blockId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BlockExercisesTableAnnotationComposer(
            $db: $db,
            $table: $db.blockExercises,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$BlocksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BlocksTable,
          Block,
          $$BlocksTableFilterComposer,
          $$BlocksTableOrderingComposer,
          $$BlocksTableAnnotationComposer,
          $$BlocksTableCreateCompanionBuilder,
          $$BlocksTableUpdateCompanionBuilder,
          (Block, $$BlocksTableReferences),
          Block,
          PrefetchHooks Function({bool blockExercisesRefs})
        > {
  $$BlocksTableTableManager(_$AppDatabase db, $BlocksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BlocksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BlocksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BlocksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> notes = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BlocksCompanion(
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
              }) => BlocksCompanion.insert(
                id: id,
                name: name,
                notes: notes,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$BlocksTable, Block>(table),
                  $$BlocksTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({blockExercisesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (blockExercisesRefs) db.blockExercises,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (blockExercisesRefs)
                    await $_getPrefetchedData<
                      Block,
                      $BlocksTable,
                      BlockExercise
                    >(
                      currentTable: table,
                      referencedTable: $$BlocksTableReferences
                          ._blockExercisesRefsTable(db),
                      managerFromTypedResult: (p0) => $$BlocksTableReferences(
                        db,
                        table,
                        p0,
                      ).blockExercisesRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.blockId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$BlocksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BlocksTable,
      Block,
      $$BlocksTableFilterComposer,
      $$BlocksTableOrderingComposer,
      $$BlocksTableAnnotationComposer,
      $$BlocksTableCreateCompanionBuilder,
      $$BlocksTableUpdateCompanionBuilder,
      (Block, $$BlocksTableReferences),
      Block,
      PrefetchHooks Function({bool blockExercisesRefs})
    >;
typedef $$BlockExercisesTableCreateCompanionBuilder =
    BlockExercisesCompanion Function({
      Value<int> id,
      required String blockId,
      required int order,
      Value<String?> exerciseId,
      required String exerciseName,
      required int sets,
      required String reps,
      Value<String> weightIntensity,
      Value<int?> restSec,
      Value<String> notes,
      Value<String> videoUrl,
      Value<bool> embeddingAllowed,
    });
typedef $$BlockExercisesTableUpdateCompanionBuilder =
    BlockExercisesCompanion Function({
      Value<int> id,
      Value<String> blockId,
      Value<int> order,
      Value<String?> exerciseId,
      Value<String> exerciseName,
      Value<int> sets,
      Value<String> reps,
      Value<String> weightIntensity,
      Value<int?> restSec,
      Value<String> notes,
      Value<String> videoUrl,
      Value<bool> embeddingAllowed,
    });

final class $$BlockExercisesTableReferences
    extends BaseReferences<_$AppDatabase, $BlockExercisesTable, BlockExercise> {
  $$BlockExercisesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $BlocksTable _blockIdTable(_$AppDatabase db) =>
      db.blocks.createAlias('block_exercises__block_id__blocks__id');

  $$BlocksTableProcessedTableManager get blockId {
    final $_column = $_itemColumn<String>('block_id')!;

    final manager = $$BlocksTableTableManager(
      $_db,
      $_db.blocks,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_blockIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $ExercisesTable _exerciseIdTable(_$AppDatabase db) =>
      db.exercises.createAlias('block_exercises__exercise_id__exercises__id');

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

class $$BlockExercisesTableFilterComposer
    extends Composer<_$AppDatabase, $BlockExercisesTable> {
  $$BlockExercisesTableFilterComposer({
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

  ColumnFilters<bool> get embeddingAllowed => $composableBuilder(
    column: $table.embeddingAllowed,
    builder: (column) => ColumnFilters(column),
  );

  $$BlocksTableFilterComposer get blockId {
    final $$BlocksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.blockId,
      referencedTable: $db.blocks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BlocksTableFilterComposer(
            $db: $db,
            $table: $db.blocks,
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

class $$BlockExercisesTableOrderingComposer
    extends Composer<_$AppDatabase, $BlockExercisesTable> {
  $$BlockExercisesTableOrderingComposer({
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

  ColumnOrderings<bool> get embeddingAllowed => $composableBuilder(
    column: $table.embeddingAllowed,
    builder: (column) => ColumnOrderings(column),
  );

  $$BlocksTableOrderingComposer get blockId {
    final $$BlocksTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.blockId,
      referencedTable: $db.blocks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BlocksTableOrderingComposer(
            $db: $db,
            $table: $db.blocks,
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

class $$BlockExercisesTableAnnotationComposer
    extends Composer<_$AppDatabase, $BlockExercisesTable> {
  $$BlockExercisesTableAnnotationComposer({
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

  GeneratedColumn<bool> get embeddingAllowed => $composableBuilder(
    column: $table.embeddingAllowed,
    builder: (column) => column,
  );

  $$BlocksTableAnnotationComposer get blockId {
    final $$BlocksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.blockId,
      referencedTable: $db.blocks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BlocksTableAnnotationComposer(
            $db: $db,
            $table: $db.blocks,
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

class $$BlockExercisesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BlockExercisesTable,
          BlockExercise,
          $$BlockExercisesTableFilterComposer,
          $$BlockExercisesTableOrderingComposer,
          $$BlockExercisesTableAnnotationComposer,
          $$BlockExercisesTableCreateCompanionBuilder,
          $$BlockExercisesTableUpdateCompanionBuilder,
          (BlockExercise, $$BlockExercisesTableReferences),
          BlockExercise,
          PrefetchHooks Function({bool blockId, bool exerciseId})
        > {
  $$BlockExercisesTableTableManager(
    _$AppDatabase db,
    $BlockExercisesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BlockExercisesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BlockExercisesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BlockExercisesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> blockId = const Value.absent(),
                Value<int> order = const Value.absent(),
                Value<String?> exerciseId = const Value.absent(),
                Value<String> exerciseName = const Value.absent(),
                Value<int> sets = const Value.absent(),
                Value<String> reps = const Value.absent(),
                Value<String> weightIntensity = const Value.absent(),
                Value<int?> restSec = const Value.absent(),
                Value<String> notes = const Value.absent(),
                Value<String> videoUrl = const Value.absent(),
                Value<bool> embeddingAllowed = const Value.absent(),
              }) => BlockExercisesCompanion(
                id: id,
                blockId: blockId,
                order: order,
                exerciseId: exerciseId,
                exerciseName: exerciseName,
                sets: sets,
                reps: reps,
                weightIntensity: weightIntensity,
                restSec: restSec,
                notes: notes,
                videoUrl: videoUrl,
                embeddingAllowed: embeddingAllowed,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String blockId,
                required int order,
                Value<String?> exerciseId = const Value.absent(),
                required String exerciseName,
                required int sets,
                required String reps,
                Value<String> weightIntensity = const Value.absent(),
                Value<int?> restSec = const Value.absent(),
                Value<String> notes = const Value.absent(),
                Value<String> videoUrl = const Value.absent(),
                Value<bool> embeddingAllowed = const Value.absent(),
              }) => BlockExercisesCompanion.insert(
                id: id,
                blockId: blockId,
                order: order,
                exerciseId: exerciseId,
                exerciseName: exerciseName,
                sets: sets,
                reps: reps,
                weightIntensity: weightIntensity,
                restSec: restSec,
                notes: notes,
                videoUrl: videoUrl,
                embeddingAllowed: embeddingAllowed,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$BlockExercisesTable, BlockExercise>(table),
                  $$BlockExercisesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({blockId = false, exerciseId = false}) {
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
                    if (blockId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.blockId,
                        referencedTable: $$BlockExercisesTableReferences
                            ._blockIdTable(db),
                        referencedColumn: $$BlockExercisesTableReferences
                            ._blockIdTable(db)
                            .id,
                      ) as T;
                    }
                    if (exerciseId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.exerciseId,
                        referencedTable: $$BlockExercisesTableReferences
                            ._exerciseIdTable(db),
                        referencedColumn: $$BlockExercisesTableReferences
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

typedef $$BlockExercisesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BlockExercisesTable,
      BlockExercise,
      $$BlockExercisesTableFilterComposer,
      $$BlockExercisesTableOrderingComposer,
      $$BlockExercisesTableAnnotationComposer,
      $$BlockExercisesTableCreateCompanionBuilder,
      $$BlockExercisesTableUpdateCompanionBuilder,
      (BlockExercise, $$BlockExercisesTableReferences),
      BlockExercise,
      PrefetchHooks Function({bool blockId, bool exerciseId})
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
  $$PlanSessionDatesTableTableManager get planSessionDates =>
      $$PlanSessionDatesTableTableManager(_db, _db.planSessionDates);
  $$PlanExercisesTableTableManager get planExercises =>
      $$PlanExercisesTableTableManager(_db, _db.planExercises);
  $$SessionLogsTableTableManager get sessionLogs =>
      $$SessionLogsTableTableManager(_db, _db.sessionLogs);
  $$LoggedSetsTableTableManager get loggedSets =>
      $$LoggedSetsTableTableManager(_db, _db.loggedSets);
  $$BodyMeasurementsTableTableManager get bodyMeasurements =>
      $$BodyMeasurementsTableTableManager(_db, _db.bodyMeasurements);
  $$BlocksTableTableManager get blocks =>
      $$BlocksTableTableManager(_db, _db.blocks);
  $$BlockExercisesTableTableManager get blockExercises =>
      $$BlockExercisesTableTableManager(_db, _db.blockExercises);
}
