import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../domain/exercises/catalog.dart';
import '../../domain/exercises/exercise.dart';
import '../../domain/progression.dart';
import '../app_database.dart';

/// Plan mit seinen Übungen (sortiert).
class RoutineWithExercises {
  const RoutineWithExercises(this.routine, this.exercises);

  final Routine routine;
  final List<RoutineExercise> exercises;
}

/// Eintrag beim Anlegen eines Plans.
class PlanEntry {
  const PlanEntry(
    this.exerciseId, {
    this.sets = 3,
    this.repMin = 8,
    this.repMax = 12,
    this.targetSeconds,
    this.restSeconds = 90,
  });

  final String exerciseId;
  final int sets;
  final int repMin;
  final int repMax;
  final int? targetSeconds;
  final int restSeconds;

  /// Vorgabe passend zur Übung.
  factory PlanEntry.defaultFor(String exerciseId, Tracking tracking) {
    final t = Target.defaultFor(tracking);
    return switch (tracking) {
      Tracking.duration => PlanEntry(
        exerciseId,
        sets: t.sets,
        targetSeconds: t.seconds,
        restSeconds: 60,
      ),
      Tracking.cardio => PlanEntry(
        exerciseId,
        sets: 1,
        targetSeconds: t.minutes * 60,
        restSeconds: 0,
      ),
      Tracking.reps => PlanEntry(
        exerciseId,
        sets: t.sets,
        repMin: t.repMin,
        repMax: t.repMax,
        restSeconds: 60,
      ),
      Tracking.weightReps => PlanEntry(exerciseId),
    };
  }
}

class RoutineRepository {
  RoutineRepository(this.db);

  final AppDatabase db;
  static const _uuid = Uuid();

  /// Aktive Pläne in Reihenfolge (= Reihum-Reihenfolge).
  Future<List<Routine>> routines() =>
      (db.select(db.routines)
            ..where((t) => t.archived.equals(false))
            ..orderBy([
              (t) => OrderingTerm(expression: t.sortOrder),
              (t) => OrderingTerm(expression: t.createdAt),
            ]))
          .get();

  Stream<List<RoutineWithExercises>> watchAll() {
    final query = db.select(db.routines)
      ..where((t) => t.archived.equals(false))
      ..orderBy([
        (t) => OrderingTerm(expression: t.sortOrder),
        (t) => OrderingTerm(expression: t.createdAt),
      ]);
    return query.watch().asyncMap((routines) async {
      final items = await (db.select(db.routineExercises)
            ..where((t) => t.routineId.isIn(routines.map((r) => r.id)))
            ..orderBy([(t) => OrderingTerm(expression: t.position)]))
          .get();
      return [
        for (final r in routines)
          RoutineWithExercises(r, [
            for (final i in items)
              if (i.routineId == r.id) i,
          ]),
      ];
    });
  }

  Future<RoutineWithExercises?> byId(String id) async {
    final routine = await (db.select(
      db.routines,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    if (routine == null) return null;
    return RoutineWithExercises(routine, await exercisesOf(id));
  }

  Future<List<RoutineExercise>> exercisesOf(String routineId) =>
      (db.select(db.routineExercises)
            ..where((t) => t.routineId.equals(routineId))
            ..orderBy([(t) => OrderingTerm(expression: t.position)]))
          .get();

  /// Legt einen Plan an oder ersetzt Name und Übungen eines bestehenden.
  Future<String> save({
    String? id,
    required String name,
    required List<PlanEntry> entries,
  }) async {
    final routineId = id ?? _uuid.v4();
    await db.transaction(() async {
      final existing = await (db.select(
        db.routines,
      )..where((t) => t.id.equals(routineId))).getSingleOrNull();
      if (existing == null) {
        final count = await db.routines.count().getSingle();
        await db
            .into(db.routines)
            .insert(
              RoutinesCompanion.insert(
                id: routineId,
                name: name.trim(),
                sortOrder: Value(count),
                createdAt: DateTime.now(),
              ),
            );
      } else {
        await (db.update(db.routines)..where((t) => t.id.equals(routineId)))
            .write(RoutinesCompanion(name: Value(name.trim())));
      }
      await (db.delete(
        db.routineExercises,
      )..where((t) => t.routineId.equals(routineId))).go();
      for (var i = 0; i < entries.length; i++) {
        final e = entries[i];
        await db
            .into(db.routineExercises)
            .insert(
              RoutineExercisesCompanion.insert(
                id: _uuid.v4(),
                routineId: routineId,
                exerciseId: e.exerciseId,
                position: Value(i),
                sets: Value(e.sets),
                repMin: Value(e.repMin),
                repMax: Value(e.repMax),
                targetSeconds: Value(e.targetSeconds),
                restSeconds: Value(e.restSeconds),
              ),
            );
      }
    });
    return routineId;
  }

  /// Plan ausblenden (Verlauf bleibt erhalten).
  Future<void> archive(String id) =>
      (db.update(db.routines)..where((t) => t.id.equals(id))).write(
        const RoutinesCompanion(archived: Value(true)),
      );

  /// Neue Reihenfolge (Reihum-Reihenfolge).
  Future<void> reorder(List<String> ids) => db.transaction(() async {
    for (var i = 0; i < ids.length; i++) {
      await (db.update(db.routines)..where((t) => t.id.equals(ids[i])))
          .write(RoutinesCompanion(sortOrder: Value(i)));
    }
  });

  /// Übung im Plan ersetzen (z. B. schwerere Variante übernehmen).
  Future<void> replaceExercise(String routineId, String from, String to) =>
      (db.update(db.routineExercises)..where(
            (t) => t.routineId.equals(routineId) & t.exerciseId.equals(from),
          ))
          .write(RoutineExercisesCompanion(exerciseId: Value(to)));

  /// Plan aus einer Vorlage (IDs, die es nicht gibt, werden übersprungen).
  Future<String> createFromTemplate(String name, List<PlanEntry> entries) =>
      save(
        name: name,
        entries: [
          for (final e in entries)
            if (Catalog.isBuiltin(e.exerciseId)) e,
        ],
      );
}
