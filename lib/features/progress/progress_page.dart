import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/services.dart';
import '../../data/repositories/exercise_repository.dart';
import '../../data/repositories/progress_repository.dart';
import '../../data/repositories/workout_repository.dart';
import '../../domain/achievements.dart';
import '../../domain/stats.dart';
import '../../l10n/l10n.dart';
import '../../widgets/charts.dart';
import '../../widgets/common.dart';
import '../../widgets/labels.dart';
import '../exercises/exercise_detail_page.dart';
import '../today/today_page.dart' show WorkoutTile;
import '../workout/finish_page.dart' show performanceText;
import 'achievements_page.dart';

/// Übung mit aktuellem Stand und Trend.
class _ExerciseProgress {
  const _ExerciseProgress(this.exercise, this.points, this.prognosis);

  final Exercise exercise;
  final List<Point> points;
  final Prognosis? prognosis;
}

class _ProgressData {
  const _ProgressData(this.overview, this.exercises, this.unlocked, this.total);

  final Overview overview;
  final List<_ExerciseProgress> exercises;
  final int unlocked;
  final int total;
}

/// Fortschritt: Wochen, Übungen mit Trend/Prognose, Erfolge, Verlauf.
class ProgressPage extends StatefulWidget {
  const ProgressPage({super.key});

  @override
  State<ProgressPage> createState() => _ProgressPageState();
}

class _ProgressPageState extends State<ProgressPage> {
  late final Stream<_ProgressData> _data;

  @override
  void initState() {
    super.initState();
    final s = context.services;
    final controller = StreamController<_ProgressData>();
    StreamSubscription<void>? sub;
    Future<void> reload() async {
      if (!mounted) return;
      final data = await _load(s, context.lang);
      if (!controller.isClosed) controller.add(data);
    }

    controller.onListen = () {
      reload();
      sub = s.workouts.changes.listen((_) => reload());
    };
    controller.onCancel = () => sub?.cancel();
    _data = controller.stream;
  }

  Future<_ProgressData> _load(AppServices s, String lang) async {
    final ids = await s.workouts.trainedExerciseIds();
    final exercises = await s.exercises.byIds(ids, lang);
    final now = DateTime.now();
    final list = <_ExerciseProgress>[];
    for (final ex in exercises.values) {
      final points = await s.workouts.performanceHistory(ex.id, ex.tracking);
      if (points.isEmpty) continue;
      list.add(_ExerciseProgress(ex, points, Forecast.of(points, now)));
    }
    list.sort((a, b) => b.points.last.at.compareTo(a.points.last.at));
    final unlocked = (await s.progress.watchUnlocked().first).length;
    return _ProgressData(
      await s.progress.overview(now: now),
      list,
      unlocked,
      Achievements.all.length,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final s = context.services;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.tabProgress)),
      body: StreamBuilder<_ProgressData>(
        stream: _data,
        builder: (context, snapshot) {
          final data = snapshot.data;
          if (data == null) return const SizedBox.shrink();
          final o = data.overview;
          if (o.workouts == 0) {
            return EmptyState(
              icon: Icons.insights,
              title: l10n.progressEmptyTitle,
              message: l10n.progressEmptyText,
            );
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              PaddedCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: StatTile(
                            icon: Icons.flag_outlined,
                            value: '${o.workouts}',
                            label: l10n.statWorkouts,
                          ),
                        ),
                        Expanded(
                          child: StatTile(
                            icon: Icons.local_fire_department_outlined,
                            value: '${o.streak}',
                            label: l10n.statStreak,
                          ),
                        ),
                        Expanded(
                          child: StatTile(
                            icon: Icons.fitness_center,
                            value: formatVolume(o.volumeKg, l10n),
                            label: l10n.statVolume,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      l10n.progressWeeks(o.weeklyGoal),
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 8),
                    WeekBars(counts: o.perWeek, goal: o.weeklyGoal),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              PaddedCard(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const AchievementsPage(),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.emoji_events_outlined,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        l10n.achievementsCount(data.unlocked, data.total),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    const Icon(Icons.chevron_right),
                  ],
                ),
              ),
              SectionTitle(l10n.progressExercises),
              for (final e in data.exercises) _ExerciseTile(item: e),
              SectionTitle(l10n.progressHistory),
              StreamBuilder<List<WorkoutSummary>>(
                stream: s.workouts.watchHistory(limit: 30),
                builder: (context, snapshot) => Column(
                  children: [
                    for (final w in snapshot.data ?? const <WorkoutSummary>[])
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: WorkoutTile(summary: w),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ExerciseTile extends StatelessWidget {
  const _ExerciseTile({required this.item});

  final _ExerciseProgress item;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final p = item.prognosis;
    final ex = item.exercise;
    final (icon, color) = switch (p?.trend) {
      Trend.rising => (Icons.trending_up, theme.colorScheme.primary),
      Trend.falling => (Icons.trending_down, theme.colorScheme.error),
      Trend.flat => (Icons.trending_flat, theme.colorScheme.onSurfaceVariant),
      null => (Icons.more_horiz, theme.colorScheme.onSurfaceVariant),
    };
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(ex.name),
        subtitle: Text(
          p == null
              ? l10n.progressNeedMore
              : l10n.progressForecast(
                  performanceText(ex.tracking, p.in8Weeks, l10n),
                ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              performanceText(ex.tracking, item.points.last.value, l10n),
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(width: 6),
            Icon(icon, color: color),
          ],
        ),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => ExerciseDetailPage(exerciseId: ex.id),
          ),
        ),
      ),
    );
  }
}
