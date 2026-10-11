import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../app/services.dart';
import '../../data/app_database.dart';
import '../../domain/achievements.dart';
import '../../l10n/l10n.dart';

/// Symbol eines Erfolgs.
IconData achievementIcon(Achievement a) {
  final id = a.id;
  if (id.startsWith('workouts') || id == 'first_workout') return Icons.flag;
  if (id.startsWith('streak')) return Icons.local_fire_department;
  if (id.startsWith('volume')) return Icons.fitness_center;
  if (id.contains('record')) return Icons.military_tech;
  if (id.startsWith('push_ups')) return Icons.sports_gymnastics;
  if (id.startsWith('plank')) return Icons.self_improvement;
  if (id.startsWith('explorer')) return Icons.explore;
  if (id.startsWith('cardio')) return Icons.directions_run;
  return switch (id) {
    'early_bird' => Icons.wb_twilight,
    'night_owl' => Icons.nightlight_round,
    'full_body_week' => Icons.accessibility_new,
    'comeback' => Icons.replay,
    _ => Icons.emoji_events,
  };
}

/// Alle Erfolge: erreichte mit Datum, offene mit Fortschritt.
class AchievementsPage extends StatefulWidget {
  const AchievementsPage({super.key});

  @override
  State<AchievementsPage> createState() => _AchievementsPageState();
}

class _AchievementsPageState extends State<AchievementsPage> {
  late final Future<AchievementStats> _stats = context.services.progress
      .achievementStats();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final s = context.services;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.achievementsTitle)),
      body: FutureBuilder<AchievementStats>(
        future: _stats,
        builder: (context, stats) => StreamBuilder<Map<String, UnlockedAchievement>>(
          stream: s.progress.watchUnlocked(),
          builder: (context, unlocked) {
            final st = stats.data;
            final got = unlocked.data;
            if (st == null || got == null) return const SizedBox.shrink();
            final reached = [
              for (final a in Achievements.all)
                if (got.containsKey(a.id)) a,
            ];
            final open = [
              for (final a in Achievements.all)
                if (!got.containsKey(a.id)) a,
            ]..sort((a, b) => b.progress(st).compareTo(a.progress(st)));
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                Text(
                  l10n.achievementsCount(reached.length, Achievements.all.length),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: reached.length / Achievements.all.length,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 16),
                for (final a in reached)
                  _AchievementTile(achievement: a, unlocked: got[a.id], stats: st),
                for (final a in open)
                  _AchievementTile(achievement: a, stats: st),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _AchievementTile extends StatelessWidget {
  const _AchievementTile({
    required this.achievement,
    required this.stats,
    this.unlocked,
  });

  final Achievement achievement;
  final AchievementStats stats;
  final UnlockedAchievement? unlocked;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final a = achievement;
    final done = unlocked != null;
    final progress = a.progress(stats);
    return Card(
      color: done ? theme.colorScheme.tertiaryContainer : null,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: done
              ? theme.colorScheme.tertiary
              : theme.colorScheme.surfaceContainerHighest,
          foregroundColor: done
              ? theme.colorScheme.onTertiary
              : theme.colorScheme.onSurfaceVariant,
          child: Icon(achievementIcon(a)),
        ),
        title: Text(a.title.of(l10n.localeName)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(a.description.of(l10n.localeName)),
            if (done)
              Text(
                l10n.achievementsUnlockedAt(
                  DateFormat.yMMMd(l10n.localeName).format(unlocked!.unlockedAt),
                ),
                style: theme.textTheme.bodySmall,
              )
            else ...[
              const SizedBox(height: 6),
              LinearProgressIndicator(
                value: progress,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
