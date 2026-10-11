import 'package:flutter/material.dart';

import '../../app/services.dart';
import '../../data/repositories/exercise_repository.dart';
import '../../domain/exercises/exercise.dart';
import '../../l10n/l10n.dart';
import '../../widgets/labels.dart';

/// Eigene Übung anlegen oder bearbeiten; liefert die ID.
class CustomExercisePage extends StatefulWidget {
  const CustomExercisePage({super.key, this.exercise});

  final Exercise? exercise;

  @override
  State<CustomExercisePage> createState() => _CustomExercisePageState();
}

class _CustomExercisePageState extends State<CustomExercisePage> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.exercise?.name);
  late final _notes = TextEditingController(text: widget.exercise?.notes);
  late Equipment _equipment = widget.exercise?.equipment ?? Equipment.machine;
  late Tracking _tracking = widget.exercise?.tracking ?? Tracking.weightReps;
  late Muscle _muscle = widget.exercise?.primary ?? Muscle.chest;

  @override
  void dispose() {
    _name.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final id = await context.services.exercises.saveCustom(
      id: widget.exercise?.id,
      name: _name.text,
      equipment: _equipment,
      tracking: _tracking,
      primary: _muscle,
      notes: _notes.text,
    );
    if (mounted) Navigator.of(context).pop(id);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.exercise == null ? l10n.exerciseCustomNew : l10n.exerciseCustomEdit,
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilledButton(onPressed: _save, child: Text(l10n.commonSave)),
          ),
        ],
      ),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _name,
              autofocus: widget.exercise == null,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(labelText: l10n.exerciseName),
              validator: (v) =>
                  (v ?? '').trim().isEmpty ? l10n.exerciseNameMissing : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<Tracking>(
              initialValue: _tracking,
              decoration: InputDecoration(labelText: l10n.exerciseTracking),
              items: [
                for (final t in Tracking.values)
                  DropdownMenuItem(value: t, child: Text(l10n.trackingName(t))),
              ],
              onChanged: (v) => setState(() => _tracking = v ?? _tracking),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<Equipment>(
              initialValue: _equipment,
              decoration: InputDecoration(labelText: l10n.exerciseEquipment),
              items: [
                for (final e in Equipment.values)
                  DropdownMenuItem(value: e, child: Text(l10n.equipmentName(e))),
              ],
              onChanged: (v) => setState(() => _equipment = v ?? _equipment),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<Muscle>(
              initialValue: _muscle,
              decoration: InputDecoration(labelText: l10n.exerciseMuscle),
              items: [
                for (final m in Muscle.values)
                  DropdownMenuItem(value: m, child: Text(l10n.muscleName(m))),
              ],
              onChanged: (v) => setState(() => _muscle = v ?? _muscle),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notes,
              minLines: 3,
              maxLines: 8,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: l10n.exerciseNotes,
                hintText: l10n.exerciseNotesHint,
                alignLabelWithHint: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
