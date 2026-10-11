import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../domain/exercises/catalog.dart';
import '../../domain/exercises/exercise.dart';
import '../../domain/progression.dart';
import '../../domain/stats.dart';
import '../app_database.dart';
import 'exercise_repository.dart';
import 'routine_repository.dart';

/// Eine Übung im laufenden (oder vergangenen) Training.
class SessionExercise {
  const SessionExercise({
    required this.exerciseId,
    required this.order,
    required this.sets,
  });

  final String exerciseId;
  final int order;
  final List<WorkoutSet> sets;

  Target target(Tracking tracking) {
    final first = sets.isEmpty ? null : sets.first;
    final base = Target.defaultFor(tracking);
    return Target(
      sets: sets.isEmpty ? base.sets : sets.length,
      repMin: first?.repMin ?? base.repMin,
      repMax: first?.repMax ?? base.repMax,
      seconds: base.seconds,
      minutes: base.minutes,
    );
  }

  int get restSeconds => sets.isEmpty ? 90 : (sets.first.restSeconds ?? 90);

  List<WorkoutSet> get doneSets => [
    for (final s in sets)
      if (s.done) s,
  ];
}

class SessionView {
  const SessionView(this.workout, this.exercises);

  final Workout workout;
  final List<SessionExercise> exercises;

  int get doneSets =>
      exercises.fold(0, (sum, e) => sum + e.doneSets.length);
  int get totalSets => exercises.fold(0, (sum, e) => sum + e.sets.length);
}

/// Rekord in einem Training.
class RecordInfo {
  const RecordInfo(this.exerciseId, this.value, this.previous);

  final String exerciseId;
  final double value;
  final double? previous;
}

/// Ergebnis nach „Training beenden“.
class FinishSummary {
  const FinishSummary({
    required this.workout,
    required this.sets,
    required this.volumeKg,
    required this.records,
  });

  final Workout workout;
  final int sets;
  final double volumeKg;
  final List<RecordInfo> records;
}

/// Abgeschlossenes Training für Listen.
class WorkoutSummary {
  const WorkoutSummary({
    required this.workout,
    required this.exerciseIds,
    required this.sets,
    required this.volumeKg,
  });

  final Workout workout;
  final List<String> exerciseIds;
  final int sets;
  final double volumeKg;

  Duration get duration =>
      (workout.finishedAt ?? workout.startedAt).difference(workout.startedAt);
}

class WorkoutRepository {
  WorkoutRepository(this.db);

  final AppDatabase db;
  static const _uuid = Uuid();

  // ---------------------------------------------------------------------------
  // Laufendes Training
  // ---------------------------------------------------------------------------

  Stream<Workout?> watchActive() =>
      (db.select(db.workouts)
            ..where((t) => t.finishedAt.isNull())
            ..orderBy([
              (t) => OrderingTerm(
                expression: t.startedAt,
                mode: OrderingMode.desc,
              ),
            ])
            ..limit(1))
          .watchSingleOrNull();

  Future<Workout?> active() =>
      (db.select(db.workouts)
            ..where((t) => t.finishedAt.isNull())
            ..orderBy([
              (t) => OrderingTerm(
                expression: t.startedAt,
                mode: OrderingMode.desc,
              ),
            ])
            ..limit(1))
          .getSingleOrNull();

  /// Startet ein Training (aus einem Plan oder frei) mit vorgeschlagenen
  /// Werten. Läuft schon eines, wird dieses zurückgegeben.
  Future<String> start({
    String? routineId,
    required String name,
    DateTime? now,
  }) async {
    final running = await active();
    if (running != null) return running.id;
    final id = _uuid.v4();
    final entries = routineId == null
        ? const <RoutineExercise>[]
        : await RoutineRepository(db).exercisesOf(routineId);
    await db.transaction(() async {
      await db
          .into(db.workouts)
          .insert(
            WorkoutsCompanion.insert(
              id: id,
              routineId: Value(routineId),
              name: name,
              startedAt: now ?? DateTime.now(),
            ),
          );
      for (var i = 0; i < entries.length; i++) {
        final e = entries[i];
        await _insertSets(
          workoutId: id,
          exerciseId: e.exerciseId,
          order: i,
          sets: e.sets,
          repMin: e.repMin,
          repMax: e.repMax,
          targetSeconds: e.targetSeconds,
          restSeconds: e.restSeconds,
        );
      }
    });
    return id;
  }

  Future<Tracking> _trackingOf(String exerciseId) async {
    final info = Catalog.byId(exerciseId);
    if (info != null) return info.tracking;
    final row = await (db.select(
      db.customExercises,
    )..where((t) => t.id.equals(exerciseId))).getSingleOrNull();
    return row?.tracking ?? Tracking.weightReps;
  }

  /// Sätze mit Vorschlag aus dem Verlauf anlegen.
  Future<void> _insertSets({
    required String workoutId,
    required String exerciseId,
    required int order,
    required int sets,
    required int repMin,
    required int repMax,
    int? targetSeconds,
    required int restSeconds,
  }) async {
    final tracking = await _trackingOf(exerciseId);
    final target = Target(
      sets: sets,
      repMin: repMin,
      repMax: repMax,
      seconds: tracking == Tracking.duration ? (targetSeconds ?? 30) : 30,
      minutes: tracking == Tracking.cardio
          ? ((targetSeconds ?? 1200) / 60).round()
          : 20,
    );
    final s = await suggestion(exerciseId, tracking, target);
    for (var i = 0; i < sets; i++) {
      await db
          .into(db.workoutSets)
          .insert(
            WorkoutSetsCompanion.insert(
              id: _uuid.v4(),
              workoutId: workoutId,
              exerciseId: exerciseId,
              exerciseOrder: order,
              setIndex: i,
              weightKg: Value(s.weightKg),
              reps: Value(
                tracking == Tracking.weightReps || tracking == Tracking.reps
                    ? s.reps
                    : null,
              ),
              seconds: Value(s.seconds),
              repMin: Value(repMin),
              repMax: Value(repMax),
              restSeconds: Value(restSeconds),
            ),
          );
    }
  }

  /// Vorschlag fürs nächste Mal (nur abgeschlossene Trainings zählen).
  Future<Suggestion> suggestion(
    String exerciseId,
    Tracking tracking,
    Target target,
  ) async {
    final info = Catalog.byId(exerciseId);
    var equipment = info?.equipment;
    var primary = info?.primary;
    if (info == null) {
      final row = await (db.select(
        db.customExercises,
      )..where((t) => t.id.equals(exerciseId))).getSingleOrNull();
      equipment = row?.equipment;
      primary = row?.primaryMuscle;
    }
    return Progression.suggest(
      tracking: tracking,
      target: target,
      history: await history(exerciseId, limit: 3),
      increment: Progression.incrementFor(
        info,
        equipment ?? Equipment.machine,
        primary ?? Muscle.fullBody,
      ),
      harderId: info?.harder,
      easierId: info?.easier,
    );
  }

  Stream<SessionView?> watchSession(String workoutId) {
    final workout = (db.select(
      db.workouts,
    )..where((t) => t.id.equals(workoutId))).watchSingleOrNull();
    return workout.asyncExpand((w) {
      if (w == null) return Stream.value(null);
      return _setsQuery(workoutId).watch().map((sets) => _group(w, sets));
    });
  }

  Future<SessionView?> session(String workoutId) async {
    final w = await (db.select(
      db.workouts,
    )..where((t) => t.id.equals(workoutId))).getSingleOrNull();
    if (w == null) return null;
    return _group(w, await _setsQuery(workoutId).get());
  }

  SimpleSelectStatement<$WorkoutSetsTable, WorkoutSet> _setsQuery(
    String workoutId,
  ) =>
      db.select(db.workoutSets)
        ..where((t) => t.workoutId.equals(workoutId))
        ..orderBy([
          (t) => OrderingTerm(expression: t.exerciseOrder),
          (t) => OrderingTerm(expression: t.setIndex),
        ]);

  static SessionView _group(Workout w, List<WorkoutSet> sets) {
    final byOrder = <int, List<WorkoutSet>>{};
    for (final s in sets) {
      (byOrder[s.exerciseOrder] ??= []).add(s);
    }
    final orders = byOrder.keys.toList()..sort();
    return SessionView(w, [
      for (final o in orders)
        SessionExercise(
          exerciseId: byOrder[o]!.first.exerciseId,
          order: o,
          sets: byOrder[o]!,
        ),
    ]);
  }

  Future<void> updateSet(
    String setId, {
    Value<double?> weightKg = const Value.absent(),
    Value<int?> reps = const Value.absent(),
    Value<int?> seconds = const Value.absent(),
  }) =>
      (db.update(db.workoutSets)..where((t) => t.id.equals(setId))).write(
        WorkoutSetsCompanion(weightKg: weightKg, reps: reps, seconds: seconds),
      );

  Future<void> setDone(String setId, bool done, {DateTime? at}) =>
      (db.update(db.workoutSets)..where((t) => t.id.equals(setId))).write(
        WorkoutSetsCompanion(
          done: Value(done),
          completedAt: Value(done ? (at ?? DateTime.now()) : null),
        ),
      );

  /// Weiteren Satz mit den Werten des letzten anhängen.
  Future<void> addSet(String workoutId, int order) async {
    final sets = await (db.select(db.workoutSets)
          ..where(
            (t) => t.workoutId.equals(workoutId) & t.exerciseOrder.equals(order),
          )
          ..orderBy([(t) => OrderingTerm(expression: t.setIndex)]))
        .get();
    if (sets.isEmpty) return;
    final last = sets.last;
    await db
        .into(db.workoutSets)
        .insert(
          WorkoutSetsCompanion.insert(
            id: _uuid.v4(),
            workoutId: workoutId,
            exerciseId: last.exerciseId,
            exerciseOrder: order,
            setIndex: last.setIndex + 1,
            weightKg: Value(last.weightKg),
            reps: Value(last.reps),
            seconds: Value(last.seconds),
            repMin: Value(last.repMin),
            repMax: Value(last.repMax),
            restSeconds: Value(last.restSeconds),
          ),
        );
  }

  Future<void> removeSet(String setId) =>
      (db.delete(db.workoutSets)..where((t) => t.id.equals(setId))).go();

  /// Übung ans Ende des Trainings anhängen (mit Vorschlag).
  Future<void> addExercise(String workoutId, String exerciseId) async {
    final maxOrder = db.workoutSets.exerciseOrder.max();
    final row = await (db.selectOnly(db.workoutSets)
          ..addColumns([maxOrder])
          ..where(db.workoutSets.workoutId.equals(workoutId)))
        .getSingle();
    final order = (row.read(maxOrder) ?? -1) + 1;
    final tracking = await _trackingOf(exerciseId);
    final entry = PlanEntry.defaultFor(exerciseId, tracking);
    await _insertSets(
      workoutId: workoutId,
      exerciseId: exerciseId,
      order: order,
      sets: entry.sets,
      repMin: entry.repMin,
      repMax: entry.repMax,
      targetSeconds: entry.targetSeconds,
      restSeconds: entry.restSeconds,
    );
  }

  Future<void> removeExercise(String workoutId, int order) =>
      (db.delete(db.workoutSets)..where(
            (t) => t.workoutId.equals(workoutId) & t.exerciseOrder.equals(order),
          ))
          .go();

  /// Übung im laufenden Training tauschen (z. B. Variante). Werte der noch
  /// offenen Sätze kommen neu aus dem Verlauf der neuen Übung.
  Future<void> swapExercise(String workoutId, int order, String to) async {
    final sets = await (db.select(db.workoutSets)
          ..where(
            (t) => t.workoutId.equals(workoutId) & t.exerciseOrder.equals(order),
          ))
        .get();
    if (sets.isEmpty) return;
    final first = sets.first;
    await db.transaction(() async {
      await removeExercise(workoutId, order);
      await _insertSets(
        workoutId: workoutId,
        exerciseId: to,
        order: order,
        sets: sets.length,
        repMin: first.repMin ?? 8,
        repMax: first.repMax ?? 12,
        targetSeconds: first.seconds,
        restSeconds: first.restSeconds ?? 90,
      );
    });
  }

  /// Training samt Sätzen und Rekorden löschen.
  Future<void> discard(String workoutId) => db.transaction(() async {
    await (db.delete(
      db.personalRecords,
    )..where((t) => t.workoutId.equals(workoutId))).go();
    await (db.delete(
      db.workoutSets,
    )..where((t) => t.workoutId.equals(workoutId))).go();
    await (db.delete(
      db.workouts,
    )..where((t) => t.id.equals(workoutId))).go();
  });

  /// Training abschließen: offene Sätze verwerfen, Rekorde eintragen.
  /// Ohne erledigten Satz wird das Training verworfen (`null`).
  Future<FinishSummary?> finish(String workoutId, {DateTime? now}) async {
    final at = now ?? DateTime.now();
    return db.transaction(() async {
      final view = await session(workoutId);
      if (view == null) return null;
      final done = [
        for (final e in view.exercises) ...e.doneSets,
      ];
      if (done.isEmpty) {
        await discard(workoutId);
        return null;
      }
      await (db.delete(db.workoutSets)
            ..where((t) => t.workoutId.equals(workoutId) & t.done.equals(false)))
          .go();
      await (db.update(db.workouts)..where((t) => t.id.equals(workoutId)))
          .write(WorkoutsCompanion(finishedAt: Value(at)));

      final records = <RecordInfo>[];
      final seen = <String>{};
      for (final e in view.exercises) {
        if (!seen.add(e.exerciseId)) continue;
        final sets = [
          for (final x in view.exercises)
            if (x.exerciseId == e.exerciseId) ...x.doneSets,
        ];
        if (sets.isEmpty) continue;
        final tracking = await _trackingOf(e.exerciseId);
        final value = Stats.performance(tracking, _results(sets));
        if (value == null) continue;
        final previous = await bestBefore(e.exerciseId, tracking, workoutId);
        // Erstes Mal = Ausgangswert, kein Rekord.
        if (previous != null && value > previous) {
          records.add(RecordInfo(e.exerciseId, value, previous));
          await db
              .into(db.personalRecords)
              .insert(
                PersonalRecordsCompanion.insert(
                  id: _uuid.v4(),
                  exerciseId: e.exerciseId,
                  workoutId: workoutId,
                  value: value,
                  previous: Value(previous),
                  achievedAt: at,
                ),
              );
        }
      }
      final workout = await (db.select(
        db.workouts,
      )..where((t) => t.id.equals(workoutId))).getSingle();
      return FinishSummary(
        workout: workout,
        sets: done.length,
        volumeKg: Stats.volume(_results(done)),
        records: records,
      );
    });
  }

  /// Bester Leistungswert vor diesem Training (abgeschlossene Trainings).
  Future<double?> bestBefore(
    String exerciseId,
    Tracking tracking,
    String excludeWorkoutId,
  ) async {
    final rows = await _doneSetsOf(exerciseId).get();
    final byWorkout = <String, List<WorkoutSet>>{};
    for (final r in rows) {
      final set = r.readTable(db.workoutSets);
      if (set.workoutId == excludeWorkoutId) continue;
      (byWorkout[set.workoutId] ??= []).add(set);
    }
    double? best;
    for (final sets in byWorkout.values) {
      final v = Stats.performance(tracking, _results(sets));
      if (v != null && (best == null || v > best)) best = v;
    }
    return best;
  }

  JoinedSelectStatement<HasResultSet, dynamic> _doneSetsOf(String exerciseId) {
    final query = db.select(db.workoutSets).join([
      innerJoin(db.workouts, db.workouts.id.equalsExp(db.workoutSets.workoutId)),
    ]);
    query
      ..where(
        db.workoutSets.exerciseId.equals(exerciseId) &
            db.workoutSets.done.equals(true) &
            db.workouts.finishedAt.isNotNull(),
      )
      ..orderBy([
        OrderingTerm(
          expression: db.workouts.startedAt,
          mode: OrderingMode.desc,
        ),
        OrderingTerm(expression: db.workoutSets.setIndex),
      ]);
    return query;
  }

  static List<SetResult> _results(Iterable<WorkoutSet> sets) => [
    for (final s in sets)
      SetResult(weightKg: s.weightKg, reps: s.reps, seconds: s.seconds),
  ];

  // ---------------------------------------------------------------------------
  // Verlauf
  // ---------------------------------------------------------------------------

  /// Erledigte Sätze einer Übung je Training, neueste zuerst.
  Future<List<SessionResult>> history(String exerciseId, {int? limit}) async {
    final rows = await _doneSetsOf(exerciseId).get();
    final order = <String>[];
    final byWorkout = <String, List<WorkoutSet>>{};
    final when = <String, DateTime>{};
    for (final r in rows) {
      final set = r.readTable(db.workoutSets);
      final w = r.readTable(db.workouts);
      if (!byWorkout.containsKey(w.id)) {
        if (limit != null && order.length >= limit) break;
        order.add(w.id);
        when[w.id] = w.startedAt;
      }
      (byWorkout[w.id] ??= []).add(set);
    }
    return [
      for (final id in order) SessionResult(when[id]!, _results(byWorkout[id]!)),
    ];
  }

  /// Leistungsverlauf einer Übung (älteste zuerst) für Diagramm/Prognose.
  Future<List<Point>> performanceHistory(
    String exerciseId,
    Tracking tracking,
  ) async {
    final sessions = await history(exerciseId);
    return [
      for (final s in sessions.reversed)
        if (Stats.performance(tracking, s.sets) case final v?) Point(s.at, v),
    ];
  }

  /// Abgeschlossene Trainings, neueste zuerst.
  Stream<List<WorkoutSummary>> watchHistory({int? limit}) {
    final query = db.select(db.workouts)
      ..where((t) => t.finishedAt.isNotNull())
      ..orderBy([
        (t) => OrderingTerm(expression: t.startedAt, mode: OrderingMode.desc),
      ]);
    if (limit != null) query.limit(limit);
    return query.watch().asyncMap(_summaries);
  }

  Future<List<WorkoutSummary>> _summaries(List<Workout> workouts) async {
    if (workouts.isEmpty) return const [];
    final sets = await (db.select(db.workoutSets)
          ..where(
            (t) =>
                t.workoutId.isIn(workouts.map((w) => w.id)) & t.done.equals(true),
          )
          ..orderBy([
            (t) => OrderingTerm(expression: t.exerciseOrder),
            (t) => OrderingTerm(expression: t.setIndex),
          ]))
        .get();
    final byWorkout = <String, List<WorkoutSet>>{};
    for (final s in sets) {
      (byWorkout[s.workoutId] ??= []).add(s);
    }
    return [
      for (final w in workouts)
        WorkoutSummary(
          workout: w,
          exerciseIds: {
            for (final s in byWorkout[w.id] ?? const <WorkoutSet>[]) s.exerciseId,
          }.toList(),
          sets: byWorkout[w.id]?.length ?? 0,
          volumeKg: Stats.volume(_results(byWorkout[w.id] ?? const [])),
        ),
    ];
  }

  /// Startzeitpunkte aller abgeschlossenen Trainings.
  Future<List<DateTime>> finishedDates() async {
    final rows = await (db.select(
      db.workouts,
    )..where((t) => t.finishedAt.isNotNull())).get();
    return [for (final w in rows) w.startedAt];
  }

  Stream<void> get changes =>
      db.tableUpdates(TableUpdateQuery.onAllTables([db.workouts, db.workoutSets]));

  /// Übungen, die schon einmal trainiert wurden (für die Fortschrittsseite).
  Future<List<String>> trainedExerciseIds() async {
    final rows = await (db.selectOnly(db.workoutSets, distinct: true)
          ..addColumns([db.workoutSets.exerciseId])
          ..where(db.workoutSets.done.equals(true)))
        .get();
    return [for (final r in rows) r.read(db.workoutSets.exerciseId)!];
  }

  /// Alle Daten einer Übung für die Detailseite.
  Future<List<SessionResult>> fullHistory(String exerciseId) =>
      history(exerciseId);

  /// Name einer Übung im Verlauf, falls sie gelöscht wurde.
  static Exercise fallback(String id) => Exercise.unknown(id, id);
}
