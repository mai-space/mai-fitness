import 'dart:math' as math;

import 'package:drift/drift.dart';

import '../../domain/achievements.dart';
import '../../domain/exercises/catalog.dart';
import '../../domain/exercises/exercise.dart';
import '../../domain/schedule.dart';
import '../../domain/stats.dart';
import '../app_database.dart';
import '../settings.dart';

/// Überblick für „Heute“ und „Fortschritt“.
class Overview {
  const Overview({
    required this.workouts,
    required this.thisWeek,
    required this.weeklyGoal,
    required this.streak,
    required this.volumeKg,
    required this.records,
    required this.perWeek,
    this.lastWorkout,
  });

  final int workouts;
  final int thisWeek;
  final int weeklyGoal;

  /// Wochen in Folge mit erreichtem Wochenziel.
  final int streak;
  final double volumeKg;
  final int records;

  /// Trainings je Woche, älteste zuerst (letzte 12 Wochen inkl. dieser).
  final List<int> perWeek;
  final DateTime? lastWorkout;
}

class ProgressRepository {
  ProgressRepository(this.db);

  final AppDatabase db;

  static const _pushUps = {'push_up', 'pike_push_up'};
  static const _planks = {'plank'};

  /// Wochenziel: Einstellung, sonst Anzahl Trainingstage, sonst 2.
  Future<int> weeklyGoal() async {
    final settings = Settings(db);
    final days = Schedule.parseWeekdays(
      await settings.get(SettingKeys.trainingDays),
    );
    return settings.number(
      SettingKeys.weeklyGoal,
      days.isEmpty ? 2 : days.length,
    );
  }

  Future<Overview> overview({DateTime? now}) async {
    final t = now ?? DateTime.now();
    final goal = await weeklyGoal();
    final workouts = await (db.select(
      db.workouts,
    )..where((w) => w.finishedAt.isNotNull())).get();
    final dates = [for (final w in workouts) w.startedAt];
    final week = Stats.weekStart(t);
    final perWeek = List<int>.filled(12, 0);
    for (final d in dates) {
      final weeksAgo = week.difference(Stats.weekStart(d)).inDays ~/ 7;
      if (weeksAgo >= 0 && weeksAgo < 12) perWeek[11 - weeksAgo]++;
    }
    final volume = await _volume();
    final records = await db.personalRecords.count().getSingle();
    return Overview(
      workouts: workouts.length,
      thisWeek: perWeek.last,
      weeklyGoal: goal,
      streak: Stats.weekStreak(dates, goal, t),
      volumeKg: volume,
      records: records,
      perWeek: perWeek,
      lastWorkout: dates.isEmpty ? null : dates.reduce((a, b) => a.isAfter(b) ? a : b),
    );
  }

  Future<double> _volume() async {
    final row = await db
        .customSelect(
          'SELECT COALESCE(SUM(s.weight_kg * s.reps), 0) AS v '
          'FROM workout_sets s JOIN workouts w ON w.id = s.workout_id '
          'WHERE s.done = 1 AND w.finished_at IS NOT NULL',
          readsFrom: {db.workoutSets, db.workouts},
        )
        .getSingle();
    return row.read<double>('v');
  }

  /// Kennzahlen für die Erfolge.
  Future<AchievementStats> achievementStats() async {
    final goal = await weeklyGoal();
    final workouts = await (db.select(db.workouts)
          ..where((w) => w.finishedAt.isNotNull())
          ..orderBy([(w) => OrderingTerm(expression: w.startedAt)]))
        .get();
    final finished = {for (final w in workouts) w.id: w};
    final sets = await (db.select(
      db.workoutSets,
    )..where((s) => s.done.equals(true))).get();
    final custom = {
      for (final c in await db.select(db.customExercises).get()) c.id: c,
    };

    Muscle? muscleOf(String id) =>
        Catalog.byId(id)?.primary ?? custom[id]?.primaryMuscle;
    Tracking? trackingOf(String id) =>
        Catalog.byId(id)?.tracking ?? custom[id]?.tracking;

    var maxPushUps = 0;
    var maxPlank = 0;
    var cardioSeconds = 0;
    final exercises = <String>{};
    final musclesByWeek = <DateTime, Set<String>>{};
    for (final s in sets) {
      final w = finished[s.workoutId];
      if (w == null) continue;
      exercises.add(s.exerciseId);
      if (_pushUps.contains(s.exerciseId)) {
        maxPushUps = math.max(maxPushUps, s.reps ?? 0);
      }
      if (_planks.contains(s.exerciseId)) {
        maxPlank = math.max(maxPlank, s.seconds ?? 0);
      }
      if (trackingOf(s.exerciseId) == Tracking.cardio) {
        cardioSeconds += s.seconds ?? 0;
      }
      final group = _bodyPart(muscleOf(s.exerciseId));
      if (group != null) {
        (musclesByWeek[Stats.weekStart(w.startedAt)] ??= {}).add(group);
      }
    }
    var comeback = false;
    for (var i = 1; i < workouts.length; i++) {
      if (workouts[i].startedAt.difference(workouts[i - 1].startedAt).inDays >=
          14) {
        comeback = true;
      }
    }
    return AchievementStats(
      workouts: workouts.length,
      bestWeekStreak: Stats.bestWeekStreak([
        for (final w in workouts) w.startedAt,
      ], goal),
      volumeKg: await _volume(),
      records: await db.personalRecords.count().getSingle(),
      maxPushUps: maxPushUps,
      maxPlankSeconds: maxPlank,
      distinctExercises: exercises.length,
      earlyWorkouts: workouts.where((w) => w.startedAt.hour < 7).length,
      lateWorkouts: workouts.where((w) => w.startedAt.hour >= 21).length,
      cardioMinutes: cardioSeconds ~/ 60,
      fullBodyWeek: musclesByWeek.values.any((g) => g.length >= 5),
      comeback: comeback,
    );
  }

  /// Grobe Körperpartie für „Von Kopf bis Fuß“.
  static String? _bodyPart(Muscle? m) => switch (m) {
    Muscle.chest => 'chest',
    Muscle.back => 'back',
    Muscle.shoulders => 'shoulders',
    Muscle.quads || Muscle.hamstrings || Muscle.glutes || Muscle.calves =>
      'legs',
    Muscle.core => 'core',
    _ => null,
  };

  /// Neu erreichte Erfolge eintragen und zurückgeben.
  Future<List<Achievement>> unlockNew({DateTime? now}) async {
    final stats = await achievementStats();
    final reached = Achievements.reached(stats);
    final have = {
      for (final r in await db.select(db.unlockedAchievements).get()) r.id,
    };
    final fresh = [
      for (final a in Achievements.all)
        if (reached.contains(a.id) && !have.contains(a.id)) a,
    ];
    final at = now ?? DateTime.now();
    await db.batch((b) {
      for (final a in fresh) {
        b.insert(
          db.unlockedAchievements,
          UnlockedAchievementsCompanion.insert(id: a.id, unlockedAt: at),
          mode: InsertMode.insertOrIgnore,
        );
      }
    });
    return fresh;
  }

  Stream<Map<String, UnlockedAchievement>> watchUnlocked() => db
      .select(db.unlockedAchievements)
      .watch()
      .map((rows) => {for (final r in rows) r.id: r});

  Future<void> markSeen() => db
      .update(db.unlockedAchievements)
      .write(const UnlockedAchievementsCompanion(seen: Value(true)));

  /// Rekorde einer Übung, neueste zuerst.
  Future<List<PersonalRecord>> recordsOf(String exerciseId) =>
      (db.select(db.personalRecords)
            ..where((r) => r.exerciseId.equals(exerciseId))
            ..orderBy([
              (r) => OrderingTerm(
                expression: r.achievedAt,
                mode: OrderingMode.desc,
              ),
            ]))
          .get();

  /// Letzte Rekorde über alle Übungen.
  Stream<List<PersonalRecord>> watchRecentRecords({int limit = 10}) =>
      (db.select(db.personalRecords)
            ..orderBy([
              (r) => OrderingTerm(
                expression: r.achievedAt,
                mode: OrderingMode.desc,
              ),
            ])
            ..limit(limit))
          .watch();
}
