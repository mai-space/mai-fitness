import '../data/app_database.dart';
import '../data/repositories/exercise_repository.dart';
import '../data/repositories/progress_repository.dart';
import '../data/repositories/routine_repository.dart';
import '../data/repositories/workout_repository.dart';
import '../data/settings.dart';
import '../domain/exercises/exercise.dart';
import '../domain/progression.dart';
import '../domain/schedule.dart';
import '../l10n/l10n.dart';
import '../widgets/labels.dart';

/// Stand für das Homescreen-Widget „Nächstes Training“ — ein JSON-Dokument,
/// das die native Seite ohne Flutter anzeigt.
///
/// „Heute“/„Morgen“ entscheidet die native Seite anhand von `day` selbst,
/// damit das Widget auch nach Mitternacht stimmt, ohne dass die App läuft.
///
/// Format nur erweitern (`v` bleibt 1); die native Seite ignoriert
/// unbekannte Felder.
abstract final class WidgetSnapshot {
  static const version = 1;
  static const maxExercises = 8;

  static String dayKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  static Future<Map<String, Object?>> build(
    AppDatabase db,
    AppLocalizations l10n, {
    DateTime? now,
  }) async {
    final t = now ?? DateTime.now();
    final today = DateTime(t.year, t.month, t.day);
    final lang = l10n.localeName;
    final settings = Settings(db);
    final workouts = WorkoutRepository(db);
    final routines = await RoutineRepository(db).routines();
    final weekdays = Schedule.parseWeekdays(
      await settings.get(SettingKeys.trainingDays),
    );
    final history = await workouts.watchHistory(limit: 1).first;
    final last = history.isEmpty ? null : history.first.workout;
    final next = Schedule.next(
      routineIds: [for (final r in routines) r.id],
      weekdays: weekdays,
      now: t,
      lastRoutineId: last?.routineId,
      trainedToday: last != null && !last.startedAt.isBefore(today),
    );
    final overview = await ProgressRepository(db).overview(now: t);
    final active = await workouts.active();

    Map<String, Object?>? nextJson;
    if (next != null) {
      final plan = await RoutineRepository(db).byId(next.routineId);
      if (plan != null) {
        final exercises = await ExerciseRepository(
          db,
        ).byIds(plan.exercises.map((e) => e.exerciseId), lang);
        final rows = <Map<String, Object?>>[];
        for (final entry in plan.exercises.take(maxExercises)) {
          final ex = exercises[entry.exerciseId];
          if (ex == null) continue;
          final target = Target(
            sets: entry.sets,
            repMin: entry.repMin,
            repMax: entry.repMax,
            seconds: entry.targetSeconds ?? 30,
            minutes: ((entry.targetSeconds ?? 1200) / 60).round(),
          );
          final s = await workouts.suggestion(ex.id, ex.tracking, target);
          rows.add({
            'name': ex.name,
            'detail': _detail(l10n, ex.tracking, entry, s),
            'up': _isStep(s.kind),
          });
        }
        nextJson = {
          'routineId': plan.routine.id,
          'name': plan.routine.name,
          'day': next.day == null ? null : dayKey(next.day!),
          'exercises': rows,
          'more': (plan.exercises.length - maxExercises).clamp(0, 999),
        };
      }
    }

    final moreCount = (nextJson?['more'] as int?) ?? 0;
    return {
      'v': version,
      'generatedAt': t.millisecondsSinceEpoch,
      'labels': {
        'title': l10n.widgetNextTitle,
        'today': l10n.commonToday,
        'tomorrow': l10n.commonTomorrow,
        'anyDay': l10n.widgetAnyDay,
        'start': l10n.workoutStart,
        'resume': l10n.workoutResume,
        'empty': l10n.widgetEmpty,
        'week': l10n.widgetWeek(overview.thisWeek, overview.weeklyGoal),
        'more': l10n.widgetMore(moreCount),
        'weekdays': [
          for (var i = 1; i <= 7; i++) l10n.weekdayShort(i),
        ],
      },
      'next': nextJson,
      'active': active == null ? null : {'name': active.name},
      'week': {'done': overview.thisWeek, 'goal': overview.weeklyGoal},
      'streak': overview.streak,
    };
  }

  static bool _isStep(SuggestionKind k) =>
      k == SuggestionKind.increaseWeight ||
      k == SuggestionKind.moreTime ||
      k == SuggestionKind.harderVariation;

  /// „3 × 8–12 · 40 kg“, „3 × 30 s“, „20 min“.
  static String _detail(
    AppLocalizations l10n,
    Tracking tracking,
    RoutineExercise entry,
    Suggestion s,
  ) {
    switch (tracking) {
      case Tracking.weightReps:
        final reps = '${entry.sets} × ${s.reps ?? entry.repMin}';
        return s.weightKg == null ? reps : '$reps · ${formatKg(s.weightKg!, l10n)}';
      case Tracking.reps:
        return '${entry.sets} × ${s.reps ?? entry.repMin}';
      case Tracking.duration:
        return '${entry.sets} × ${formatSeconds(s.seconds ?? 30)}';
      case Tracking.cardio:
        return formatMinutes(((s.seconds ?? 1200) / 60).round(), l10n);
    }
  }
}
