import 'package:flutter/material.dart';

import '../../data/repositories/exercise_repository.dart';
import '../../data/repositories/workout_repository.dart';
import '../../domain/achievements.dart';
import '../../domain/exercises/exercise.dart';
import '../../l10n/l10n.dart';
import '../../widgets/common.dart';
import '../../widgets/labels.dart';
import '../progress/achievements_page.dart';

/// Zusammenfassung nach dem Training: Dauer, Sätze, Rekorde, neue Erfolge.
class FinishPage extends StatelessWidget {
  const FinishPage({
    super.key,
    required this.summary,
    required this.achievements,
    required this.exercises,
  });

  final FinishSummary summary;
  final List<Achievement> achievements;
  final Map<String, Exercise> exercises;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final w = summary.workout;
    final duration = (w.finishedAt ?? DateTime.now()).difference(w.startedAt);
    return Scaffold(
      appBar: AppBar(automaticallyImplyLeading: false),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
        children: [
          Icon(Icons.emoji_events, size: 72, color: theme.colorScheme.primary),
          const SizedBox(height: 12),
          Text(
            l10n.finishTitle,
            style: theme.textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            w.name,
            style: theme.textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          PaddedCard(
            child: Row(
              children: [
                Expanded(
                  child: StatTile(
                    icon: Icons.timer_outlined,
                    value: formatDuration(duration, l10n),
                    label: l10n.statDuration,
                  ),
                ),
                Expanded(
                  child: StatTile(
                    icon: Icons.repeat,
                    value: '${summary.sets}',
                    label: l10n.statSets,
                  ),
                ),
                if (summary.volumeKg > 0)
                  Expanded(
                    child: StatTile(
                      icon: Icons.fitness_center,
                      value: formatVolume(summary.volumeKg, l10n),
                      label: l10n.statVolume,
                    ),
                  ),
              ],
            ),
          ),
          if (summary.records.isNotEmpty) ...[
            SectionTitle(l10n.finishRecords),
            for (final r in summary.records)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.military_tech),
                  title: Text(exercises[r.exerciseId]?.name ?? r.exerciseId),
                  subtitle: Text(
                    recordText(
                      exercises[r.exerciseId]?.tracking ?? Tracking.weightReps,
                      r.value,
                      r.previous,
                      l10n,
                    ),
                  ),
                ),
              ),
          ],
          if (achievements.isNotEmpty) ...[
            SectionTitle(l10n.finishAchievements),
            for (final a in achievements)
              Card(
                color: theme.colorScheme.tertiaryContainer,
                child: ListTile(
                  leading: Icon(achievementIcon(a)),
                  title: Text(a.title.of(l10n.localeName)),
                  subtitle: Text(a.description.of(l10n.localeName)),
                ),
              ),
          ],
          const SizedBox(height: 24),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.commonDone),
          ),
        ],
      ),
    );
  }
}

/// Leistungswert mit Einheit (Rekorde, Prognose).
String performanceText(Tracking tracking, double value, AppLocalizations l10n) =>
    switch (tracking) {
      Tracking.weightReps => formatKg(value, l10n),
      Tracking.reps => l10n.unitReps(value.round()),
      Tracking.duration => formatSeconds(value.round()),
      Tracking.cardio => formatMinutes(value.round(), l10n),
    };

/// „Geschätztes Maximum 80 kg (vorher 75 kg)“.
String recordText(
  Tracking tracking,
  double value,
  double? previous,
  AppLocalizations l10n,
) {
  final now = performanceText(tracking, value, l10n);
  final label = tracking == Tracking.weightReps ? l10n.recordOneRepMax(now) : now;
  if (previous == null) return label;
  return l10n.recordPrevious(label, performanceText(tracking, previous, l10n));
}
