import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:mai_fitness/data/app_database.dart';
import 'package:mai_fitness/data/repositories/exercise_repository.dart';
import 'package:mai_fitness/data/repositories/progress_repository.dart';
import 'package:mai_fitness/data/repositories/routine_repository.dart';
import 'package:mai_fitness/data/repositories/workout_repository.dart';
import 'package:mai_fitness/data/settings.dart';
import 'package:mai_fitness/data/starter_plans.dart';
import 'package:mai_fitness/domain/exercises/exercise.dart';
import 'package:mai_fitness/domain/progression.dart';
import 'package:mai_fitness/home_widgets/widget_snapshot.dart';
import 'package:mai_fitness/l10n/l10n.dart';
import 'package:mai_fitness/services/csv_export.dart';

import 'helpers.dart';

void main() {
  late AppDatabase db;
  late RoutineRepository routines;
  late WorkoutRepository workouts;
  late ProgressRepository progress;

  setUp(() {
    db = testDb();
    routines = RoutineRepository(db);
    workouts = WorkoutRepository(db);
    progress = ProgressRepository(db);
  });
  tearDown(() => db.close());

  /// Alle Sätze eines Trainings mit Werten abhaken und abschließen.
  Future<FinishSummary?> train(
    String workoutId, {
    double? weight,
    int? reps,
    int? seconds,
    DateTime? at,
  }) async {
    final view = (await workouts.session(workoutId))!;
    for (final e in view.exercises) {
      for (final s in e.sets) {
        await workouts.updateSet(
          s.id,
          weightKg: weight == null ? const Value.absent() : Value(weight),
          reps: reps == null ? const Value.absent() : Value(reps),
          seconds: seconds == null ? const Value.absent() : Value(seconds),
        );
        await workouts.setDone(s.id, true);
      }
    }
    return workouts.finish(workoutId, now: at);
  }

  test('Plan aus Vorlage → Training mit Sätzen nach Ziel', () async {
    final id = await routines.createFromTemplate('Ganzkörper A', StarterPlans.gymA.entries);
    final plan = (await routines.byId(id))!;
    expect(plan.exercises.map((e) => e.exerciseId).first, 'leg_press');

    final w = await workouts.start(routineId: id, name: 'Ganzkörper A');
    final view = (await workouts.session(w))!;
    expect(view.exercises, hasLength(StarterPlans.gymA.entries.length));
    expect(view.exercises.first.sets, hasLength(3));
    // Erstes Mal: kein Gewicht vorgegeben, untere Wiederholungszahl.
    expect(view.exercises.first.sets.first.weightKg, isNull);
    expect(view.exercises.first.sets.first.reps, 8);
    // Plank: Zielzeit statt Wiederholungen.
    final plank = view.exercises.last;
    expect(plank.exerciseId, 'plank');
    expect(plank.sets.first.seconds, 30);
    expect(plank.sets.first.reps, isNull);

    // Es läuft nur ein Training gleichzeitig.
    expect(await workouts.start(name: 'Frei'), w);
  });

  test('Steigerung: geschafft → nächstes Training mit mehr Gewicht', () async {
    final id = await routines.save(
      name: 'Beine',
      entries: const [PlanEntry('leg_press', sets: 3, repMin: 8, repMax: 12)],
    );
    final first = await workouts.start(
      routineId: id,
      name: 'Beine',
      now: DateTime(2026, 10, 1, 17),
    );
    final s1 = await train(first, weight: 80, reps: 12, at: DateTime(2026, 10, 1, 18));
    expect(s1!.records, isEmpty, reason: 'erstes Mal ist der Ausgangswert');
    expect(s1.volumeKg, 80 * 12 * 3);

    final second = await workouts.start(
      routineId: id,
      name: 'Beine',
      now: DateTime(2026, 10, 3, 17),
    );
    final view = (await workouts.session(second))!;
    // Beinpresse: Sprung 5 kg.
    expect(view.exercises.single.sets.first.weightKg, 85);
    expect(view.exercises.single.sets.first.reps, 8);

    final s2 = await train(second, weight: 85, reps: 10, at: DateTime(2026, 10, 3, 18));
    expect(s2!.records, hasLength(1));
    expect(s2.records.single.previous, closeTo(112, 0.1));

    final history = await workouts.history('leg_press');
    expect(history, hasLength(2));
    expect(history.first.sets.first.weightKg, 85);

    final s = await workouts.suggestion('leg_press', Tracking.weightReps, const Target());
    expect(s.kind, SuggestionKind.moreReps);
    expect(s.reps, 11);
  });

  test('nicht abgehakte Sätze zählen nicht; leeres Training wird verworfen', () async {
    final w = await workouts.start(name: 'Frei');
    await workouts.addExercise(w, 'push_up');
    expect(await workouts.finish(w), isNull);
    expect(await workouts.active(), isNull);

    final w2 = await workouts.start(name: 'Frei');
    await workouts.addExercise(w2, 'push_up');
    final view = (await workouts.session(w2))!;
    final set = view.exercises.single.sets.first;
    await workouts.updateSet(set.id, reps: const Value(12));
    await workouts.setDone(set.id, true);
    final summary = await workouts.finish(w2);
    expect(summary!.sets, 1);
    final after = (await workouts.session(w2))!;
    expect(after.totalSets, 1, reason: 'offene Sätze werden entfernt');
  });

  test('Satz hinzufügen/entfernen, Übung tauschen', () async {
    final w = await workouts.start(name: 'Frei');
    await workouts.addExercise(w, 'knee_push_up');
    var view = (await workouts.session(w))!;
    await workouts.addSet(w, view.exercises.single.order);
    view = (await workouts.session(w))!;
    expect(view.exercises.single.sets, hasLength(4));
    await workouts.removeSet(view.exercises.single.sets.last.id);
    await workouts.swapExercise(w, view.exercises.single.order, 'push_up');
    view = (await workouts.session(w))!;
    expect(view.exercises.single.exerciseId, 'push_up');
    expect(view.exercises.single.sets, hasLength(3));
  });

  test('Erfolge werden einmalig freigeschaltet', () async {
    await Settings(db).set(SettingKeys.trainingDays, '1,3');
    final w = await workouts.start(name: 'Frei', now: DateTime(2026, 10, 12, 6, 30));
    await workouts.addExercise(w, 'plank');
    await train(w, seconds: 65, at: DateTime(2026, 10, 12, 7));

    final fresh = await progress.unlockNew();
    expect(fresh.map((a) => a.id), containsAll(['first_workout', 'plank_60']));
    expect(await progress.unlockNew(), isEmpty);

    final stats = await progress.achievementStats();
    expect(stats.workouts, 1);
    expect(stats.earlyWorkouts, 1);
    expect(stats.maxPlankSeconds, 65);
    expect(await progress.weeklyGoal(), 2);
  });

  test('Training löschen entfernt auch Rekorde', () async {
    final w1 = await workouts.start(name: 'A', now: DateTime(2026, 10, 1));
    await workouts.addExercise(w1, 'push_up');
    await train(w1, reps: 10, at: DateTime(2026, 10, 1, 1));
    final w2 = await workouts.start(name: 'A', now: DateTime(2026, 10, 3));
    await workouts.addExercise(w2, 'push_up');
    final s = await train(w2, reps: 12, at: DateTime(2026, 10, 3, 1));
    expect(s!.records, hasLength(1));
    await workouts.discard(w2);
    expect(await db.select(db.personalRecords).get(), isEmpty);
  });

  test('eigene Übung: anlegen, im Verlauf behalten, ausblenden', () async {
    final repo = ExerciseRepository(db);
    final id = await repo.saveCustom(
      name: ' Rückenzug ',
      equipment: Equipment.cable,
      tracking: Tracking.weightReps,
      primary: Muscle.back,
    );
    expect((await repo.byId(id, 'de'))!.name, 'Rückenzug');
    final all = await repo.all('de');
    expect(all.where((e) => e.isCustom), hasLength(1));
    await repo.archiveCustom(id);
    expect((await repo.all('de')).where((e) => e.isCustom), isEmpty);
    expect(await repo.byId(id, 'de'), isNotNull);
  });

  test('Widget-Stand: nächster Plan reihum mit Vorschlägen', () async {
    final a = await routines.createFromTemplate('A', StarterPlans.homeA.entries);
    await routines.createFromTemplate('B', StarterPlans.homeB.entries);
    await Settings(db).set(SettingKeys.trainingDays, '1,3,5');
    final w = await workouts.start(routineId: a, name: 'A', now: DateTime(2026, 10, 12, 18));
    await train(w, reps: 20, seconds: 30, at: DateTime(2026, 10, 12, 19));

    // Montagabend nach dem Training: nächster Plan B am Mittwoch.
    final snap = await WidgetSnapshot.build(
      db,
      lookupAppLocalizations(AppLocale.german),
      now: DateTime(2026, 10, 12, 20),
    );
    final next = snap['next']! as Map<String, Object?>;
    expect(next['name'], 'B');
    expect(next['day'], '2026-10-14');
    expect((next['exercises']! as List), isNotEmpty);
    expect((snap['week']! as Map)['done'], 1);
    expect((snap['labels']! as Map)['weekdays'], hasLength(7));
  });

  test('CSV: deutsch mit Semikolon und Dezimalkomma', () async {
    final w = await workouts.start(name: 'Brust; Rücken', now: DateTime(2026, 10, 1, 18));
    await workouts.addExercise(w, 'chest_press_machine');
    await train(w, weight: 42.5, reps: 10, at: DateTime(2026, 10, 1, 19));
    final csv = await CsvExport.build(
      db,
      'de',
      header: const ['Datum', 'Training', 'Übung', 'Satz', 'kg', 'Wdh', 's'],
    );
    final lines = csv.trim().split('\n');
    expect(lines, hasLength(4));
    expect(lines[1], contains('"Brust; Rücken"'));
    expect(lines[1], contains(';42,5;10;'));
  });
}
