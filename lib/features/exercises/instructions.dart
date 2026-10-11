import 'package:flutter/material.dart';

import '../../data/repositories/exercise_repository.dart';
import '../../domain/exercises/exercise.dart';
import '../../l10n/l10n.dart';
import '../../widgets/labels.dart';

/// Symbol je Muskelgruppe (Bibliothek, Listen).
IconData muscleIcon(Muscle m) => switch (m) {
  Muscle.chest => Icons.accessibility_new,
  Muscle.back => Icons.airline_seat_flat,
  Muscle.shoulders => Icons.sports_gymnastics,
  Muscle.biceps || Muscle.triceps => Icons.sports_handball,
  Muscle.core => Icons.self_improvement,
  Muscle.quads || Muscle.hamstrings || Muscle.glutes || Muscle.calves =>
    Icons.directions_walk,
  Muscle.fullBody => Icons.sports_martial_arts,
  Muscle.cardio => Icons.directions_run,
};

/// Anleitung einer Übung: Einstellung, Ablauf, Tipps, häufige Fehler.
class ExerciseInstructions extends StatelessWidget {
  const ExerciseInstructions({super.key, required this.exercise});

  final Exercise exercise;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final info = exercise.info;
    final lang = l10n.localeName;
    final muscles = [
      l10n.muscleName(exercise.primary),
      for (final m in exercise.secondary) l10n.muscleName(m),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            Chip(
              avatar: const Icon(Icons.fitness_center, size: 18),
              label: Text(l10n.equipmentName(exercise.equipment)),
            ),
            for (final (i, m) in muscles.indexed)
              Chip(
                label: Text(m),
                backgroundColor: i == 0
                    ? theme.colorScheme.primaryContainer
                    : null,
              ),
            if (info != null && !info.beginner)
              Chip(
                avatar: const Icon(Icons.trending_up, size: 18),
                label: Text(l10n.exerciseAdvanced),
              ),
          ],
        ),
        if (info == null) ...[
          const SizedBox(height: 16),
          Text(
            exercise.notes ?? l10n.exerciseCustomNoNotes,
            style: theme.textTheme.bodyLarge,
          ),
        ] else ...[
          _Section(
            icon: Icons.tune,
            title: l10n.exerciseSetup,
            children: [Text(info.setup.of(lang))],
          ),
          _Section(
            icon: Icons.format_list_numbered,
            title: l10n.exerciseSteps,
            children: [
              for (final (i, step) in info.steps.indexed)
                _Numbered(number: i + 1, text: step.of(lang)),
            ],
          ),
          _Section(
            icon: Icons.lightbulb_outline,
            title: l10n.exerciseTips,
            children: [
              for (final tip in info.tips)
                _Bullet(icon: Icons.check_circle_outline, text: tip.of(lang)),
            ],
          ),
          _Section(
            icon: Icons.warning_amber_outlined,
            title: l10n.exerciseMistakes,
            children: [
              for (final m in info.mistakes)
                _Bullet(
                  icon: Icons.close,
                  text: m.of(lang),
                  color: theme.colorScheme.error,
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.icon,
    required this.title,
    required this.children,
  });

  final IconData icon;
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(title, style: theme.textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }
}

class _Numbered extends StatelessWidget {
  const _Numbered({required this.number, required this.text});

  final int number;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: theme.colorScheme.primaryContainer,
            child: Text(
              '$number',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: theme.textTheme.bodyLarge)),
        ],
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet({required this.icon, required this.text, this.color});

  final IconData icon;
  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color ?? theme.colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}

/// Anleitung als Blatt von unten (im Training).
Future<void> showInstructions(BuildContext context, Exercise exercise) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        builder: (context, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
          children: [
            Text(
              exercise.name,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            ExerciseInstructions(exercise: exercise),
          ],
        ),
      ),
    );
