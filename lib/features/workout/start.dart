import 'package:flutter/material.dart';

import '../../app/services.dart';
import '../../data/settings.dart';
import '../../domain/schedule.dart';
import '../../l10n/l10n.dart';
import 'workout_page.dart';

/// Nächster Plan (reihum) — für „Heute“, Widget und Erinnerung.
Future<NextWorkout?> nextWorkout(AppServices s, {DateTime? now}) async {
  final t = now ?? DateTime.now();
  final today = DateTime(t.year, t.month, t.day);
  final routines = await s.routines.routines();
  final history = await s.workouts.watchHistory(limit: 1).first;
  final last = history.isEmpty ? null : history.first.workout;
  return Schedule.next(
    routineIds: [for (final r in routines) r.id],
    weekdays: Schedule.parseWeekdays(
      await s.settings.get(SettingKeys.trainingDays),
    ),
    now: t,
    lastRoutineId: last?.routineId,
    trainedToday: last != null && !last.startedAt.isBefore(today),
  );
}

/// Öffnet das laufende Training.
Future<void> openWorkout(BuildContext context, String workoutId) =>
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => WorkoutPage(workoutId: workoutId),
      ),
    );

/// Startet ein Training mit [routineId] (oder frei) und öffnet es. Läuft
/// schon eines, wird dieses geöffnet.
Future<void> startWorkout(
  BuildContext context, {
  String? routineId,
  String? name,
}) async {
  final s = context.services;
  final l10n = context.l10n;
  var title = name;
  if (title == null && routineId != null) {
    title = (await s.routines.byId(routineId))?.routine.name;
  }
  final id = await s.workouts.start(
    routineId: routineId,
    name: title ?? l10n.workoutFreeName,
  );
  if (!context.mounted) return;
  await openWorkout(context, id);
}

/// Laufendes Training fortsetzen, sonst das nächste starten.
Future<void> startNext(BuildContext context) async {
  final s = context.services;
  final active = await s.workouts.active();
  if (!context.mounted) return;
  if (active != null) return openWorkout(context, active.id);
  final next = await nextWorkout(s);
  if (!context.mounted) return;
  await startWorkout(context, routineId: next?.routineId);
}
