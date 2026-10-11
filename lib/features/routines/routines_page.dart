import 'package:flutter/material.dart';

import '../../app/services.dart';
import '../../data/repositories/exercise_repository.dart';
import '../../data/repositories/routine_repository.dart';
import '../../data/starter_plans.dart';
import '../../l10n/l10n.dart';
import '../../widgets/common.dart';
import '../workout/start.dart';
import 'routine_edit_page.dart';

/// Trainingspläne. Die Reihenfolge ist die Reihum-Reihenfolge (A → B → A …).
class RoutinesPage extends StatelessWidget {
  const RoutinesPage({super.key});

  Future<void> _addTemplate(BuildContext context) async {
    final l10n = context.l10n;
    final lang = context.lang;
    final s = context.services;
    final plan = await showModalBottomSheet<StarterPlan>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: Text(
                l10n.routineTemplates,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            for (final p in const [
              StarterPlans.gymA,
              StarterPlans.gymB,
              StarterPlans.homeA,
              StarterPlans.homeB,
            ])
              ListTile(
                leading: const Icon(Icons.content_copy_outlined),
                title: Text(p.name.of(lang)),
                subtitle: Text(l10n.routineExerciseCount(p.entries.length)),
                onTap: () => Navigator.pop(context, p),
              ),
          ],
        ),
      ),
    );
    if (plan == null) return;
    await s.routines.createFromTemplate(plan.name.of(lang), plan.entries);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final s = context.services;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.tabPlans),
        actions: [
          IconButton(
            tooltip: l10n.routineTemplates,
            icon: const Icon(Icons.library_add_outlined),
            onPressed: () => _addTemplate(context),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'new-routine',
        icon: const Icon(Icons.add),
        label: Text(l10n.routineNew),
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const RoutineEditPage()),
        ),
      ),
      body: StreamBuilder<List<RoutineWithExercises>>(
        stream: s.routines.watchAll(),
        builder: (context, snapshot) {
          final list = snapshot.data;
          if (list == null) return const SizedBox.shrink();
          if (list.isEmpty) {
            return EmptyState(
              icon: Icons.list_alt,
              title: l10n.routineEmptyTitle,
              message: l10n.routineEmptyText,
              action: OutlinedButton.icon(
                icon: const Icon(Icons.library_add_outlined),
                label: Text(l10n.routineTemplates),
                onPressed: () => _addTemplate(context),
              ),
            );
          }
          return ReorderableListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
            header: Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
              child: Text(
                l10n.routineRotationHint,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            itemCount: list.length,
            onReorderItem: (from, to) {
              final ids = [for (final r in list) r.routine.id];
              final id = ids.removeAt(from);
              ids.insert(to, id);
              s.routines.reorder(ids);
            },
            itemBuilder: (context, i) => Padding(
              key: ValueKey(list[i].routine.id),
              padding: const EdgeInsets.only(bottom: 8),
              child: _RoutineCard(item: list[i]),
            ),
          );
        },
      ),
    );
  }
}

class _RoutineCard extends StatelessWidget {
  const _RoutineCard({required this.item});

  final RoutineWithExercises item;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final s = context.services;
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => RoutineEditPage(routineId: item.routine.id),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.routine.name, style: theme.textTheme.titleMedium),
                    const SizedBox(height: 4),
                    FutureBuilder<Map<String, Exercise>>(
                      future: s.exercises.byIds(
                        item.exercises.map((e) => e.exerciseId),
                        context.lang,
                      ),
                      builder: (context, names) => Text(
                        [
                          for (final e in item.exercises)
                            names.data?[e.exerciseId]?.name ?? '',
                        ].where((n) => n.isNotEmpty).join(' · '),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton.filledTonal(
                tooltip: l10n.workoutStart,
                icon: const Icon(Icons.play_arrow),
                onPressed: () =>
                    startWorkout(context, routineId: item.routine.id),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
