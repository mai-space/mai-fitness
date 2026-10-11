import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../app/services.dart';
import '../../data/repositories/exercise_repository.dart';
import '../../data/repositories/workout_repository.dart';
import '../../domain/exercises/exercise.dart';
import '../../l10n/l10n.dart';
import '../../widgets/common.dart';
import '../../widgets/labels.dart';

/// Ein abgeschlossenes Training im Detail (nur lesen, löschen möglich).
class WorkoutDetailPage extends StatefulWidget {
  const WorkoutDetailPage({super.key, required this.workoutId});

  final String workoutId;

  @override
  State<WorkoutDetailPage> createState() => _WorkoutDetailPageState();
}

class _WorkoutDetailPageState extends State<WorkoutDetailPage> {
  late final Future<(SessionView?, Map<String, Exercise>)> _data = _load();

  Future<(SessionView?, Map<String, Exercise>)> _load() async {
    final s = context.services;
    final lang = context.lang;
    final view = await s.workouts.session(widget.workoutId);
    final names = view == null
        ? <String, Exercise>{}
        : await s.exercises.byIds(
            view.exercises.map((e) => e.exerciseId),
            lang,
          );
    return (view, names);
  }

  Future<void> _delete() async {
    final l10n = context.l10n;
    final ok = await confirm(
      context,
      title: l10n.historyDeleteTitle,
      message: l10n.historyDeleteText,
      confirmLabel: l10n.commonDelete,
      cancelLabel: l10n.commonCancel,
      destructive: true,
    );
    if (!ok || !mounted) return;
    await context.services.workouts.discard(widget.workoutId);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return FutureBuilder(
      future: _data,
      builder: (context, snapshot) {
        final (view, names) = snapshot.data ?? (null, <String, Exercise>{});
        return Scaffold(
          appBar: AppBar(
            title: Text(view?.workout.name ?? ''),
            actions: [
              if (view != null)
                IconButton(
                  tooltip: l10n.commonDelete,
                  icon: const Icon(Icons.delete_outline),
                  onPressed: _delete,
                ),
            ],
          ),
          body: view == null
              ? const SizedBox.shrink()
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                  children: [
                    Text(
                      DateFormat.yMMMMEEEEd(
                        l10n.localeName,
                      ).add_Hm().format(view.workout.startedAt),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    if (view.workout.finishedAt != null)
                      Text(
                        formatDuration(
                          view.workout.finishedAt!.difference(
                            view.workout.startedAt,
                          ),
                          l10n,
                        ),
                      ),
                    for (final e in view.exercises) ...[
                      SectionTitle(names[e.exerciseId]?.name ?? e.exerciseId),
                      Card(
                        child: Column(
                          children: [
                            for (final set in e.sets)
                              ListTile(
                                dense: true,
                                leading: Text('${set.setIndex + 1}'),
                                title: Text(
                                  setText(
                                    names[e.exerciseId]?.tracking ??
                                        Tracking.weightReps,
                                    set.weightKg,
                                    set.reps,
                                    set.seconds,
                                    l10n,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
        );
      },
    );
  }
}

/// „40 kg × 10“, „12 Wdh.“, „45 s“, „20 min“.
String setText(
  Tracking tracking,
  double? weight,
  int? reps,
  int? seconds,
  AppLocalizations l10n,
) => switch (tracking) {
  Tracking.weightReps =>
    weight == null || weight == 0
        ? l10n.unitReps(reps ?? 0)
        : '${formatKg(weight, l10n)} × ${reps ?? 0}',
  Tracking.reps => l10n.unitReps(reps ?? 0),
  Tracking.duration => formatSeconds(seconds ?? 0),
  Tracking.cardio => formatMinutes((seconds ?? 0) ~/ 60, l10n),
};
