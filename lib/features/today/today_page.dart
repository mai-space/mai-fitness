import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../app/services.dart';
import '../../data/app_database.dart';
import '../../data/repositories/exercise_repository.dart';
import '../../data/repositories/progress_repository.dart';
import '../../data/repositories/routine_repository.dart';
import '../../data/repositories/workout_repository.dart';
import '../../domain/achievements.dart';
import '../../domain/schedule.dart';
import '../../l10n/l10n.dart';
import '../../widgets/common.dart';
import '../../widgets/labels.dart';
import '../progress/achievements_page.dart';
import '../progress/workout_detail_page.dart';
import '../routines/routine_edit_page.dart';
import '../settings/settings_page.dart';
import '../workout/start.dart';

/// Startseite: nächstes Training, Wochenziel, neue Erfolge, letzte Trainings.
class TodayPage extends StatefulWidget {
  const TodayPage({super.key, required this.onOpenTab});

  final ValueChanged<int> onOpenTab;

  @override
  State<TodayPage> createState() => _TodayPageState();
}

class _TodayData {
  const _TodayData({
    required this.next,
    required this.plan,
    required this.names,
    required this.overview,
  });

  final NextWorkout? next;
  final RoutineWithExercises? plan;
  final Map<String, Exercise> names;
  final Overview overview;
}

class _TodayPageState extends State<TodayPage> {
  late final Stream<_TodayData> _data;

  @override
  void initState() {
    super.initState();
    final s = context.services;
    // Neu laden bei jeder Änderung an Plänen, Trainings oder Einstellungen.
    _data = s.db
        .tableUpdates()
        .map((_) => null)
        .cast<void>()
        .transform(_startWith())
        .asyncMap((_) => _load(s));
  }

  static StreamTransformer<void, void> _startWith() =>
      StreamTransformer.fromBind((input) async* {
        yield null;
        yield* input;
      });

  Future<_TodayData> _load(AppServices s) async {
    final next = await nextWorkout(s);
    final plan = next == null ? null : await s.routines.byId(next.routineId);
    final names = plan == null
        ? <String, Exercise>{}
        : await s.exercises.byIds(
            plan.exercises.map((e) => e.exerciseId),
            mounted ? context.lang : 'de',
          );
    return _TodayData(
      next: next,
      plan: plan,
      names: names,
      overview: await s.progress.overview(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final s = context.services;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.tabToday),
        actions: [
          IconButton(
            tooltip: l10n.settingsTitle,
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const SettingsPage()),
            ),
          ),
        ],
      ),
      body: StreamBuilder<_TodayData>(
        stream: _data,
        builder: (context, snapshot) {
          final data = snapshot.data;
          if (data == null) return const SizedBox.shrink();
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              StreamBuilder<Workout?>(
                stream: s.workouts.watchActive(),
                builder: (context, active) => active.data == null
                    ? const SizedBox.shrink()
                    : Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _ActiveCard(workout: active.data!),
                      ),
              ),
              _NextCard(data: data, onOpenTab: widget.onOpenTab),
              const SizedBox(height: 12),
              _WeekCard(overview: data.overview),
              const _NewAchievements(),
              _RecentWorkouts(onOpenTab: widget.onOpenTab),
            ],
          );
        },
      ),
    );
  }
}

class _ActiveCard extends StatelessWidget {
  const _ActiveCard({required this.workout});

  final Workout workout;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    return PaddedCard(
      color: scheme.primaryContainer,
      onTap: () => openWorkout(context, workout.id),
      child: Row(
        children: [
          Icon(Icons.timer_outlined, color: scheme.onPrimaryContainer),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.workoutRunning,
                  style: Theme.of(context).textTheme.labelMedium,
                ),
                Text(
                  workout.name,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          ),
          FilledButton(
            onPressed: () => openWorkout(context, workout.id),
            child: Text(l10n.workoutResume),
          ),
        ],
      ),
    );
  }
}

/// Tag des nächsten Trainings: „Heute“, „Morgen“, „Mi., 15.10.“.
String dayLabel(DateTime? day, AppLocalizations l10n, {DateTime? now}) {
  if (day == null) return l10n.nextAnyDay;
  final t = now ?? DateTime.now();
  final today = DateTime(t.year, t.month, t.day);
  final diff = day.difference(today).inDays;
  if (diff <= 0) return l10n.commonToday;
  if (diff == 1) return l10n.commonTomorrow;
  return DateFormat.MMMEd(l10n.localeName).format(day);
}

class _NextCard extends StatelessWidget {
  const _NextCard({required this.data, required this.onOpenTab});

  final _TodayData data;
  final ValueChanged<int> onOpenTab;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final plan = data.plan;
    if (plan == null) {
      return PaddedCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.nextNoPlanTitle, style: theme.textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(l10n.nextNoPlanText),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  icon: const Icon(Icons.add),
                  label: Text(l10n.routineNew),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const RoutineEditPage(),
                    ),
                  ),
                ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.bolt_outlined),
                  label: Text(l10n.workoutFree),
                  onPressed: () => startWorkout(context),
                ),
              ],
            ),
          ],
        ),
      );
    }
    final names = [
      for (final e in plan.exercises) data.names[e.exerciseId]?.name ?? '',
    ].where((n) => n.isNotEmpty).toList();
    return PaddedCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${l10n.nextTitle} · ${dayLabel(data.next?.day, l10n)}',
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(plan.routine.name, style: theme.textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(
            l10n.nextExercises(names.length, names.take(4).join(' · ')),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                  ),
                  icon: const Icon(Icons.play_arrow),
                  label: Text(l10n.workoutStart),
                  onPressed: () =>
                      startWorkout(context, routineId: plan.routine.id),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.outlined(
                tooltip: l10n.workoutFree,
                icon: const Icon(Icons.bolt_outlined),
                onPressed: () => startWorkout(context),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WeekCard extends StatelessWidget {
  const _WeekCard({required this.overview});

  final Overview overview;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final goal = overview.weeklyGoal;
    final done = overview.thisWeek;
    return PaddedCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.weekTitle,
                  style: theme.textTheme.titleMedium,
                ),
              ),
              if (overview.streak > 0) ...[
                Icon(
                  Icons.local_fire_department,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 4),
                Text(l10n.weekStreak(overview.streak)),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              for (var i = 0; i < goal; i++)
                Expanded(
                  child: Container(
                    height: 10,
                    margin: const EdgeInsets.only(right: 6),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(5),
                      color: i < done
                          ? theme.colorScheme.primary
                          : theme.colorScheme.surfaceContainerHighest,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            done >= goal
                ? l10n.weekGoalReached(done)
                : l10n.weekProgress(done, goal),
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _NewAchievements extends StatelessWidget {
  const _NewAchievements();

  @override
  Widget build(BuildContext context) {
    final s = context.services;
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return StreamBuilder<Map<String, UnlockedAchievement>>(
      stream: s.progress.watchUnlocked(),
      builder: (context, snapshot) {
        final fresh = [
          for (final u in (snapshot.data ?? const {}).values)
            if (!u.seen) ?Achievements.byId(u.id),
        ];
        if (fresh.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(top: 12),
          child: PaddedCard(
            color: theme.colorScheme.tertiaryContainer,
            onTap: () async {
              await Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const AchievementsPage(),
                ),
              );
              await s.progress.markSeen();
            },
            child: Row(
              children: [
                Icon(
                  Icons.emoji_events,
                  color: theme.colorScheme.onTertiaryContainer,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.achievementsNew(fresh.length),
                        style: theme.textTheme.titleMedium,
                      ),
                      Text(
                        fresh
                            .map((a) => a.title.of(l10n.localeName))
                            .join(' · '),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _RecentWorkouts extends StatelessWidget {
  const _RecentWorkouts({required this.onOpenTab});

  final ValueChanged<int> onOpenTab;

  @override
  Widget build(BuildContext context) {
    final s = context.services;
    final l10n = context.l10n;
    return StreamBuilder<List<WorkoutSummary>>(
      stream: s.workouts.watchHistory(limit: 3),
      builder: (context, snapshot) {
        final list = snapshot.data ?? const [];
        if (list.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SectionTitle(
              l10n.recentTitle,
              trailing: TextButton(
                onPressed: () => onOpenTab(2),
                child: Text(l10n.recentAll),
              ),
            ),
            for (final w in list)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: WorkoutTile(summary: w),
              ),
          ],
        );
      },
    );
  }
}

/// Abgeschlossenes Training in Listen.
class WorkoutTile extends StatelessWidget {
  const WorkoutTile({super.key, required this.summary});

  final WorkoutSummary summary;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final w = summary.workout;
    final date = DateFormat.MMMEd(l10n.localeName).format(w.startedAt);
    return Card(
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.check)),
        title: Text(w.name),
        subtitle: Text(
          [
            date,
            formatDuration(summary.duration, l10n),
            l10n.setsCount(summary.sets),
            if (summary.volumeKg > 0) formatVolume(summary.volumeKg, l10n),
          ].join(' · '),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => WorkoutDetailPage(workoutId: w.id),
          ),
        ),
      ),
    );
  }
}
