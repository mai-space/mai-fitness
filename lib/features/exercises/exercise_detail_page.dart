import 'package:flutter/material.dart';

import '../../app/services.dart';
import '../../data/repositories/exercise_repository.dart';
import '../../domain/exercises/exercise.dart';
import '../../domain/progression.dart';
import '../../domain/stats.dart';
import '../../l10n/l10n.dart';
import '../../widgets/charts.dart';
import '../../widgets/common.dart';
import '../workout/finish_page.dart' show performanceText;
import '../workout/workout_page.dart' show suggestionText;
import 'custom_exercise_page.dart';
import 'instructions.dart';

class _DetailData {
  const _DetailData(this.exercise, this.points, this.prognosis, this.next);

  final Exercise exercise;
  final List<Point> points;
  final Prognosis? prognosis;
  final Suggestion next;
}

/// Übung: Anleitung, eigener Verlauf mit Prognose, Vorschlag fürs nächste
/// Mal.
class ExerciseDetailPage extends StatefulWidget {
  const ExerciseDetailPage({super.key, required this.exerciseId});

  final String exerciseId;

  @override
  State<ExerciseDetailPage> createState() => _ExerciseDetailPageState();
}

class _ExerciseDetailPageState extends State<ExerciseDetailPage> {
  late Future<_DetailData?> _data = _load();

  Future<_DetailData?> _load() async {
    final s = context.services;
    final ex = await s.exercises.byId(widget.exerciseId, context.lang);
    if (ex == null) return null;
    final points = await s.workouts.performanceHistory(ex.id, ex.tracking);
    final next = await s.workouts.suggestion(
      ex.id,
      ex.tracking,
      Target.defaultFor(ex.tracking),
    );
    return _DetailData(ex, points, Forecast.of(points, DateTime.now()), next);
  }

  Future<void> _edit(Exercise ex) async {
    await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => CustomExercisePage(exercise: ex)),
    );
    if (mounted) setState(() => _data = _load());
  }

  Future<void> _archive(Exercise ex) async {
    final l10n = context.l10n;
    final ok = await confirm(
      context,
      title: l10n.exerciseArchiveTitle,
      message: l10n.exerciseArchiveText,
      confirmLabel: l10n.commonDelete,
      cancelLabel: l10n.commonCancel,
      destructive: true,
    );
    if (!ok || !mounted) return;
    await context.services.exercises.archiveCustom(ex.id);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return FutureBuilder<_DetailData?>(
      future: _data,
      builder: (context, snapshot) {
        final data = snapshot.data;
        final ex = data?.exercise;
        return Scaffold(
          appBar: AppBar(
            title: Text(ex?.name ?? ''),
            actions: [
              if (ex != null && ex.isCustom) ...[
                IconButton(
                  tooltip: l10n.commonEdit,
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => _edit(ex),
                ),
                IconButton(
                  tooltip: l10n.commonDelete,
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _archive(ex),
                ),
              ],
            ],
          ),
          body: data == null
              ? const SizedBox.shrink()
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                  children: [
                    ExerciseInstructions(exercise: data.exercise),
                    SectionTitle(l10n.exerciseYourProgress),
                    _ProgressCard(data: data),
                  ],
                ),
        );
      },
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.data});

  final _DetailData data;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final ex = data.exercise;
    final points = data.points;
    final p = data.prognosis;
    final next = suggestionText(data.next, l10n);
    String fmt(double v) => performanceText(ex.tracking, v, l10n);
    if (points.isEmpty) {
      return PaddedCard(child: Text(l10n.exerciseNoHistory));
    }
    final best = points.map((x) => x.value).reduce((a, b) => a > b ? a : b);
    return PaddedCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            ex.tracking == Tracking.weightReps
                ? l10n.exerciseMetricOneRepMax
                : l10n.exerciseMetricBest,
            style: theme.textTheme.labelLarge,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: StatTile(value: fmt(points.last.value), label: l10n.statLast),
              ),
              Expanded(child: StatTile(value: fmt(best), label: l10n.statBest)),
              Expanded(
                child: StatTile(
                  value: '${points.length}',
                  label: l10n.statSessions,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ProgressChart(
            points: points,
            prognosis: p,
            format: (v) => v.round().toString(),
          ),
          const SizedBox(height: 12),
          if (p == null)
            Text(l10n.progressNeedMore, style: theme.textTheme.bodyMedium)
          else ...[
            Row(
              children: [
                Icon(Icons.auto_graph, color: theme.colorScheme.tertiary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.prognosisTitle,
                    style: theme.textTheme.titleSmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              switch (p.trend) {
                Trend.rising => l10n.prognosisRising(
                  fmt(p.in4Weeks),
                  fmt(p.in8Weeks),
                ),
                Trend.flat => l10n.prognosisFlat,
                Trend.falling => l10n.prognosisFalling,
              },
            ),
          ],
          if (next != null) ...[
            const Divider(height: 24),
            Row(
              children: [
                Icon(Icons.flag_outlined, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(child: Text(l10n.exerciseNextTime(next))),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
