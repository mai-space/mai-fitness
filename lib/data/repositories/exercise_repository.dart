import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../domain/exercises/catalog.dart';
import '../../domain/exercises/exercise.dart';
import '../app_database.dart';

/// Übung für die App — eingebaut (mit Anleitung) oder eigene.
class Exercise {
  const Exercise({
    required this.id,
    required this.name,
    required this.equipment,
    required this.tracking,
    required this.primary,
    this.secondary = const [],
    this.info,
    this.notes,
  });

  factory Exercise.builtin(ExerciseInfo info, String languageCode) => Exercise(
    id: info.id,
    name: info.name.of(languageCode),
    equipment: info.equipment,
    tracking: info.tracking,
    primary: info.primary,
    secondary: info.secondary,
    info: info,
  );

  factory Exercise.custom(CustomExercise row) => Exercise(
    id: row.id,
    name: row.name,
    equipment: row.equipment,
    tracking: row.tracking,
    primary: row.primaryMuscle,
    notes: row.notes,
  );

  /// Gelöschte eigene Übung, die noch im Verlauf steht.
  factory Exercise.unknown(String id, String name) => Exercise(
    id: id,
    name: name,
    equipment: Equipment.machine,
    tracking: Tracking.weightReps,
    primary: Muscle.fullBody,
  );

  final String id;
  final String name;
  final Equipment equipment;
  final Tracking tracking;
  final Muscle primary;
  final List<Muscle> secondary;

  /// Anleitung (nur eingebaute Übungen).
  final ExerciseInfo? info;
  final String? notes;

  bool get isCustom => info == null;
}

class ExerciseRepository {
  ExerciseRepository(this.db);

  final AppDatabase db;
  static const _uuid = Uuid();

  /// Alle Übungen (eingebaut + eigene, ohne archivierte), nach Name.
  Future<List<Exercise>> all(String languageCode) async {
    final custom = await (db.select(
      db.customExercises,
    )..where((t) => t.archived.equals(false))).get();
    return _merge(custom, languageCode);
  }

  Stream<List<Exercise>> watchAll(String languageCode) =>
      (db.select(db.customExercises)..where((t) => t.archived.equals(false)))
          .watch()
          .map((rows) => _merge(rows, languageCode));

  List<Exercise> _merge(List<CustomExercise> custom, String languageCode) {
    final list = [
      for (final info in builtinExercises) Exercise.builtin(info, languageCode),
      for (final row in custom) Exercise.custom(row),
    ];
    list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return list;
  }

  /// Übungen nach ID — auch archivierte eigene (für den Verlauf).
  Future<Map<String, Exercise>> byIds(
    Iterable<String> ids,
    String languageCode,
  ) async {
    final out = <String, Exercise>{};
    final customIds = <String>[];
    for (final id in ids.toSet()) {
      final info = Catalog.byId(id);
      if (info != null) {
        out[id] = Exercise.builtin(info, languageCode);
      } else {
        customIds.add(id);
      }
    }
    if (customIds.isNotEmpty) {
      final rows = await (db.select(
        db.customExercises,
      )..where((t) => t.id.isIn(customIds))).get();
      for (final r in rows) {
        out[r.id] = Exercise.custom(r);
      }
    }
    return out;
  }

  Future<Exercise?> byId(String id, String languageCode) async =>
      (await byIds([id], languageCode))[id];

  Future<String> saveCustom({
    String? id,
    required String name,
    required Equipment equipment,
    required Tracking tracking,
    required Muscle primary,
    String? notes,
  }) async {
    final key = id ?? 'custom-${_uuid.v4()}';
    await db
        .into(db.customExercises)
        .insertOnConflictUpdate(
          CustomExercisesCompanion.insert(
            id: key,
            name: name.trim(),
            equipment: equipment,
            tracking: tracking,
            primaryMuscle: primary,
            notes: Value(notes?.trim().isEmpty ?? true ? null : notes!.trim()),
            createdAt: DateTime.now(),
          ),
        );
    return key;
  }

  /// Eigene Übung ausblenden (Verlauf bleibt erhalten).
  Future<void> archiveCustom(String id) =>
      (db.update(db.customExercises)..where((t) => t.id.equals(id))).write(
        const CustomExercisesCompanion(archived: Value(true)),
      );
}
