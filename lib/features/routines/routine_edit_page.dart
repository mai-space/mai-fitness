import 'package:flutter/material.dart';

import '../../app/services.dart';
import '../../data/repositories/exercise_repository.dart';
import '../../data/repositories/routine_repository.dart';
import '../../domain/exercises/exercise.dart';
import '../../l10n/l10n.dart';
import '../../widgets/common.dart';
import '../../widgets/labels.dart';
import '../exercises/library_page.dart';

/// Bearbeitbarer Eintrag (Zwischenstand bis „Speichern“).
class _Entry {
  _Entry(this.exercise, PlanEntry e)
    : sets = e.sets,
      repMin = e.repMin,
      repMax = e.repMax,
      targetSeconds = e.targetSeconds,
      restSeconds = e.restSeconds;

  final Exercise exercise;
  int sets;
  int repMin;
  int repMax;
  int? targetSeconds;
  int restSeconds;
  final key = UniqueKey();

  PlanEntry toPlan() => PlanEntry(
    exercise.id,
    sets: sets,
    repMin: repMin,
    repMax: repMax,
    targetSeconds: targetSeconds,
    restSeconds: restSeconds,
  );
}

/// Plan anlegen/bearbeiten: Name, Übungen, Ziel je Übung.
class RoutineEditPage extends StatefulWidget {
  const RoutineEditPage({super.key, this.routineId});

  final String? routineId;

  @override
  State<RoutineEditPage> createState() => _RoutineEditPageState();
}

class _RoutineEditPageState extends State<RoutineEditPage> {
  final _name = TextEditingController();
  final _entries = <_Entry>[];
  bool _loading = true;
  bool _dirty = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final id = widget.routineId;
    if (id != null) {
      final s = context.services;
      final lang = context.lang;
      final plan = await s.routines.byId(id);
      if (plan != null) {
        _name.text = plan.routine.name;
        final names = await s.exercises.byIds(
          plan.exercises.map((e) => e.exerciseId),
          lang,
        );
        for (final e in plan.exercises) {
          _entries.add(
            _Entry(
              names[e.exerciseId] ?? Exercise.unknown(e.exerciseId, e.exerciseId),
              PlanEntry(
                e.exerciseId,
                sets: e.sets,
                repMin: e.repMin,
                repMax: e.repMax,
                targetSeconds: e.targetSeconds,
                restSeconds: e.restSeconds,
              ),
            ),
          );
        }
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    final id = await pickExercise(context);
    if (id == null || !mounted) return;
    final ex = await context.services.exercises.byId(id, context.lang);
    if (ex == null || !mounted) return;
    setState(() {
      _entries.add(_Entry(ex, PlanEntry.defaultFor(ex.id, ex.tracking)));
      _dirty = true;
    });
  }

  Future<void> _save() async {
    final l10n = context.l10n;
    if (_name.text.trim().isEmpty) {
      showSnack(context, l10n.routineNameMissing);
      return;
    }
    await context.services.routines.save(
      id: widget.routineId,
      name: _name.text,
      entries: [for (final e in _entries) e.toPlan()],
    );
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final l10n = context.l10n;
    final ok = await confirm(
      context,
      title: l10n.routineDeleteTitle,
      message: l10n.routineDeleteText,
      confirmLabel: l10n.commonDelete,
      cancelLabel: l10n.commonCancel,
      destructive: true,
    );
    if (!ok || !mounted) return;
    await context.services.routines.archive(widget.routineId!);
    if (mounted) Navigator.of(context).pop();
  }

  Future<bool> _confirmLeave() async {
    if (!_dirty) return true;
    final l10n = context.l10n;
    return confirm(
      context,
      title: l10n.routineLeaveTitle,
      message: l10n.routineLeaveText,
      confirmLabel: l10n.routineLeaveDiscard,
      cancelLabel: l10n.commonBack,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (await _confirmLeave() && context.mounted) {
          setState(() => _dirty = false);
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.routineId == null ? l10n.routineNew : l10n.routineEdit,
          ),
          actions: [
            if (widget.routineId != null)
              IconButton(
                tooltip: l10n.commonDelete,
                icon: const Icon(Icons.delete_outline),
                onPressed: _delete,
              ),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilledButton(
                onPressed: _loading ? null : _save,
                child: Text(l10n.commonSave),
              ),
            ),
          ],
        ),
        body: _loading
            ? const SizedBox.shrink()
            : ReorderableListView.builder(
                buildDefaultDragHandles: false,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                header: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: TextField(
                    controller: _name,
                    autofocus: widget.routineId == null,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      labelText: l10n.routineName,
                      hintText: l10n.routineNameHint,
                    ),
                    onChanged: (_) => _dirty = true,
                  ),
                ),
                footer: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                    ),
                    icon: const Icon(Icons.add),
                    label: Text(l10n.workoutAddExercise),
                    onPressed: _add,
                  ),
                ),
                itemCount: _entries.length,
                onReorderItem: (from, to) => setState(() {
                  final e = _entries.removeAt(from);
                  _entries.insert(to, e);
                  _dirty = true;
                }),
                itemBuilder: (context, i) {
                  final e = _entries[i];
                  return Padding(
                    key: e.key,
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _EntryCard(
                      entry: e,
                      index: i,
                      onChanged: () => setState(() => _dirty = true),
                      onRemove: () => setState(() {
                        _entries.removeAt(i);
                        _dirty = true;
                      }),
                    ),
                  );
                },
              ),
      ),
    );
  }
}

class _EntryCard extends StatelessWidget {
  const _EntryCard({
    required this.entry,
    required this.index,
    required this.onChanged,
    required this.onRemove,
  });

  final _Entry entry;
  final int index;
  final VoidCallback onChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final e = entry;
    final tracking = e.exercise.tracking;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 4, 4, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ReorderableDragStartListener(
                  index: index,
                  child: const Padding(
                    padding: EdgeInsets.all(12),
                    child: Icon(Icons.drag_indicator),
                  ),
                ),
                Expanded(
                  child: Text(
                    e.exercise.name,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  tooltip: l10n.commonRemove,
                  icon: const Icon(Icons.close),
                  onPressed: onRemove,
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Wrap(
                spacing: 16,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (tracking != Tracking.cardio)
                    _Stepper(
                      label: l10n.routineSets,
                      value: e.sets,
                      min: 1,
                      max: 10,
                      onChanged: (v) {
                        e.sets = v;
                        onChanged();
                      },
                    ),
                  if (tracking == Tracking.weightReps ||
                      tracking == Tracking.reps) ...[
                    _Stepper(
                      label: l10n.routineRepMin,
                      value: e.repMin,
                      min: 1,
                      max: e.repMax,
                      onChanged: (v) {
                        e.repMin = v;
                        onChanged();
                      },
                    ),
                    _Stepper(
                      label: l10n.routineRepMax,
                      value: e.repMax,
                      min: e.repMin,
                      max: 50,
                      onChanged: (v) {
                        e.repMax = v;
                        onChanged();
                      },
                    ),
                  ],
                  if (tracking == Tracking.duration)
                    _Stepper(
                      label: l10n.secondsLabel,
                      value: e.targetSeconds ?? 30,
                      min: 5,
                      max: 600,
                      step: 5,
                      onChanged: (v) {
                        e.targetSeconds = v;
                        onChanged();
                      },
                    ),
                  if (tracking == Tracking.cardio)
                    _Stepper(
                      label: l10n.minutesLabel,
                      value: (e.targetSeconds ?? 1200) ~/ 60,
                      min: 1,
                      max: 180,
                      onChanged: (v) {
                        e.targetSeconds = v * 60;
                        onChanged();
                      },
                    ),
                  if (tracking != Tracking.cardio)
                    _Stepper(
                      label: l10n.routineRest,
                      value: e.restSeconds,
                      min: 0,
                      max: 600,
                      step: 15,
                      format: formatSeconds,
                      onChanged: (v) {
                        e.restSeconds = v;
                        onChanged();
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Kompakter Zähler: − Wert +.
class _Stepper extends StatelessWidget {
  const _Stepper({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.step = 1,
    this.format,
  });

  final String label;
  final int value;
  final int min;
  final int max;
  final int step;
  final ValueChanged<int> onChanged;
  final String Function(int)? format;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.labelSmall),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              visualDensity: VisualDensity.compact,
              tooltip: '−',
              icon: const Icon(Icons.remove),
              onPressed: value - step >= min
                  ? () => onChanged(value - step)
                  : null,
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 32),
              child: Text(
                format?.call(value) ?? '$value',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium,
              ),
            ),
            IconButton(
              visualDensity: VisualDensity.compact,
              tooltip: '+',
              icon: const Icon(Icons.add),
              onPressed: value + step <= max
                  ? () => onChanged(value + step)
                  : null,
            ),
          ],
        ),
      ],
    );
  }
}
