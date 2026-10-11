import 'package:flutter/material.dart';

import '../../app/services.dart';
import '../../data/repositories/exercise_repository.dart';
import '../../domain/exercises/exercise.dart';
import '../../l10n/l10n.dart';
import '../../widgets/common.dart';
import '../../widgets/labels.dart';
import 'custom_exercise_page.dart';
import 'exercise_detail_page.dart';
import 'instructions.dart';

/// Grobe Ausrüstungs-Filter.
enum EquipmentFilter { all, machines, freeWeights, bodyweight, cardio }

bool _matches(EquipmentFilter f, Equipment e) => switch (f) {
  EquipmentFilter.all => true,
  EquipmentFilter.machines => e == Equipment.machine || e == Equipment.cable,
  EquipmentFilter.freeWeights =>
    e == Equipment.barbell || e == Equipment.dumbbell,
  EquipmentFilter.bodyweight => e == Equipment.bodyweight || e == Equipment.bar,
  EquipmentFilter.cardio => e == Equipment.cardioMachine,
};

/// Übung auswählen (Plan, Training); liefert die ID.
Future<String?> pickExercise(BuildContext context) => Navigator.of(context)
    .push<String>(
      MaterialPageRoute(builder: (_) => const LibraryPage(picker: true)),
    );

/// Übungsbibliothek mit Suche und Filtern; als Auswahl mit [picker].
class LibraryPage extends StatefulWidget {
  const LibraryPage({super.key, this.picker = false});

  final bool picker;

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  final _search = TextEditingController();
  EquipmentFilter _filter = EquipmentFilter.all;
  Muscle? _muscle;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  String _filterName(EquipmentFilter f, AppLocalizations l10n) => switch (f) {
    EquipmentFilter.all => l10n.filterAll,
    EquipmentFilter.machines => l10n.filterMachines,
    EquipmentFilter.freeWeights => l10n.filterFreeWeights,
    EquipmentFilter.bodyweight => l10n.filterBodyweight,
    EquipmentFilter.cardio => l10n.filterCardio,
  };

  Future<void> _open(Exercise e) async {
    if (widget.picker) {
      Navigator.of(context).pop(e.id);
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ExerciseDetailPage(exerciseId: e.id),
      ),
    );
  }

  Future<void> _create() async {
    final id = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const CustomExercisePage()),
    );
    if (id != null && widget.picker && mounted) Navigator.of(context).pop(id);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final s = context.services;
    final query = _search.text.trim().toLowerCase();
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.picker ? l10n.exercisePick : l10n.tabExercises),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'new-exercise',
        icon: const Icon(Icons.add),
        label: Text(l10n.exerciseCustomNew),
        onPressed: _create,
      ),
      body: StreamBuilder<List<Exercise>>(
        stream: s.exercises.watchAll(context.lang),
        builder: (context, snapshot) {
          final all = snapshot.data ?? const <Exercise>[];
          final list = [
            for (final e in all)
              if (_matches(_filter, e.equipment) &&
                  (_muscle == null ||
                      e.primary == _muscle ||
                      e.secondary.contains(_muscle)) &&
                  (query.isEmpty || e.name.toLowerCase().contains(query)))
                e,
          ];
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: TextField(
                    controller: _search,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search),
                      hintText: l10n.exerciseSearch,
                      suffixIcon: query.isEmpty
                          ? null
                          : IconButton(
                              tooltip: l10n.commonClear,
                              icon: const Icon(Icons.clear),
                              onPressed: () => setState(_search.clear),
                            ),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Row(
                    children: [
                      for (final f in EquipmentFilter.values)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(_filterName(f, l10n)),
                            selected: _filter == f,
                            onSelected: (_) => setState(() => _filter = f),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Row(
                    children: [
                      for (final m in Muscle.values)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(l10n.muscleName(m)),
                            selected: _muscle == m,
                            onSelected: (v) =>
                                setState(() => _muscle = v ? m : null),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              if (snapshot.hasData && list.isEmpty)
                SliverToBoxAdapter(
                  child: EmptyState(
                    icon: Icons.search_off,
                    title: l10n.exerciseNoneTitle,
                    message: l10n.exerciseNoneText,
                  ),
                ),
              SliverList.builder(
                itemCount: list.length,
                itemBuilder: (context, i) {
                  final e = list[i];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.primaryContainer,
                      child: Icon(muscleIcon(e.primary)),
                    ),
                    title: Text(e.name),
                    subtitle: Text(
                      '${l10n.muscleName(e.primary)} · ${l10n.equipmentName(e.equipment)}',
                    ),
                    trailing: widget.picker
                        ? IconButton(
                            tooltip: l10n.exerciseInstructions,
                            icon: const Icon(Icons.info_outline),
                            onPressed: () => showInstructions(context, e),
                          )
                        : (e.isCustom
                              ? const Icon(Icons.person_outline)
                              : null),
                    onTap: () => _open(e),
                  );
                },
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 96)),
            ],
          );
        },
      ),
    );
  }
}
