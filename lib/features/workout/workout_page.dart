import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/services.dart';
import '../../data/app_database.dart';
import '../../data/repositories/exercise_repository.dart';
import '../../data/repositories/workout_repository.dart';
import '../../data/settings.dart';
import '../../domain/exercises/catalog.dart';
import '../../domain/exercises/exercise.dart';
import '../../domain/progression.dart';
import '../../l10n/l10n.dart';
import '../../widgets/common.dart';
import '../../widgets/labels.dart';
import '../exercises/instructions.dart';
import '../exercises/library_page.dart';
import 'finish_page.dart';
import 'hold_timer.dart';

/// Laufendes Training: Sätze abhaken, Werte anpassen, Pausen-Timer.
///
/// Alles steht sofort in der Datenbank — die App darf jederzeit geschlossen
/// werden; „Heute“ bietet dann „Fortsetzen“ an.
class WorkoutPage extends StatefulWidget {
  const WorkoutPage({super.key, required this.workoutId});

  final String workoutId;

  @override
  State<WorkoutPage> createState() => _WorkoutPageState();
}

class _WorkoutPageState extends State<WorkoutPage> {
  late final Stream<SessionView?> _session;
  Map<String, Exercise> _exercises = {};
  final Map<String, Suggestion> _suggestions = {};
  Timer? _clock;
  DateTime? _restEnd;
  int _restTotal = 0;
  bool _restEnabled = true;
  bool _finishing = false;

  @override
  void initState() {
    super.initState();
    final s = context.services;
    _session = s.workouts.watchSession(widget.workoutId);
    _clock = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    s.settings
        .flag(SettingKeys.restTimer, fallback: true)
        .then((v) => _restEnabled = v);
  }

  @override
  void dispose() {
    _clock?.cancel();
    super.dispose();
  }

  void _tick() {
    if (!mounted) return;
    final end = _restEnd;
    if (end != null && !DateTime.now().isBefore(end)) {
      _restEnd = null;
      HapticFeedback.heavyImpact();
      SystemSound.play(SystemSoundType.alert);
    }
    setState(() {});
  }

  /// Namen und Vorschläge für neu hinzugekommene Übungen laden.
  Future<void> _ensureLoaded(SessionView view) async {
    final s = context.services;
    final lang = context.lang;
    final missing = [
      for (final e in view.exercises)
        if (!_exercises.containsKey(e.exerciseId)) e.exerciseId,
    ];
    if (missing.isEmpty) return;
    final loaded = await s.exercises.byIds(missing, lang);
    for (final e in view.exercises) {
      final ex = loaded[e.exerciseId];
      if (ex == null || _suggestions.containsKey(e.exerciseId)) continue;
      _suggestions[e.exerciseId] = await s.workouts.suggestion(
        e.exerciseId,
        ex.tracking,
        e.target(ex.tracking),
      );
    }
    if (!mounted) return;
    setState(() {
      _exercises = {
        ..._exercises,
        ...loaded,
        for (final id in missing)
          if (!loaded.containsKey(id)) id: Exercise.unknown(id, id),
      };
    });
  }

  void _startRest(int seconds) {
    if (!_restEnabled || seconds <= 0) return;
    setState(() {
      _restTotal = seconds;
      _restEnd = DateTime.now().add(Duration(seconds: seconds));
    });
  }

  void _adjustRest(int delta) {
    final end = _restEnd;
    if (end == null) return;
    setState(() {
      _restEnd = end.add(Duration(seconds: delta));
      _restTotal = (_restTotal + delta).clamp(1, 3600);
    });
  }

  Future<void> _toggle(WorkoutSet set, SessionExercise e) async {
    final s = context.services;
    final done = !set.done;
    await s.workouts.setDone(set.id, done);
    if (done) {
      HapticFeedback.lightImpact();
      _startRest(e.restSeconds);
    } else {
      setState(() => _restEnd = null);
    }
  }

  Future<void> _addExercise() async {
    final picked = await pickExercise(context);
    if (picked == null || !mounted) return;
    await context.services.workouts.addExercise(widget.workoutId, picked);
  }

  Future<void> _finish(SessionView view) async {
    final l10n = context.l10n;
    final s = context.services;
    final open = view.totalSets - view.doneSets;
    if (view.doneSets == 0) {
      final discard = await confirm(
        context,
        title: l10n.workoutDiscardTitle,
        message: l10n.workoutNothingDone,
        confirmLabel: l10n.workoutDiscard,
        cancelLabel: l10n.commonCancel,
        destructive: true,
      );
      if (!discard || !mounted) return;
      await s.workouts.discard(widget.workoutId);
      if (mounted) Navigator.of(context).pop();
      return;
    }
    if (open > 0) {
      final ok = await confirm(
        context,
        title: l10n.workoutFinishTitle,
        message: l10n.workoutFinishOpenSets(open),
        confirmLabel: l10n.workoutFinish,
        cancelLabel: l10n.commonBack,
      );
      if (!ok || !mounted) return;
    }
    setState(() => _finishing = true);
    final summary = await s.workouts.finish(widget.workoutId);
    final achievements = await s.progress.unlockNew();
    if (!mounted) return;
    if (summary == null) {
      Navigator.of(context).pop();
      return;
    }
    await Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => FinishPage(
          summary: summary,
          achievements: achievements,
          exercises: _exercises,
        ),
      ),
    );
  }

  Future<void> _menu(SessionView view) async {
    final l10n = context.l10n;
    final s = context.services;
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.timer_outlined),
              title: Text(l10n.workoutRestTimer),
              trailing: Switch(
                value: _restEnabled,
                onChanged: (v) => Navigator.pop(context, v ? 'rest_on' : 'rest_off'),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: Text(l10n.workoutDiscard),
              onTap: () => Navigator.pop(context, 'discard'),
            ),
          ],
        ),
      ),
    );
    if (!mounted || action == null) return;
    switch (action) {
      case 'rest_on' || 'rest_off':
        final on = action == 'rest_on';
        setState(() {
          _restEnabled = on;
          if (!on) _restEnd = null;
        });
        await s.settings.setFlag(SettingKeys.restTimer, on);
      case 'discard':
        final ok = await confirm(
          context,
          title: l10n.workoutDiscardTitle,
          message: l10n.workoutDiscardText,
          confirmLabel: l10n.workoutDiscard,
          cancelLabel: l10n.commonCancel,
          destructive: true,
        );
        if (!ok || !mounted) return;
        await s.workouts.discard(widget.workoutId);
        if (mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return StreamBuilder<SessionView?>(
      stream: _session,
      builder: (context, snapshot) {
        final view = snapshot.data;
        if (view == null) {
          return Scaffold(
            appBar: AppBar(),
            body: snapshot.connectionState == ConnectionState.waiting
                ? const Center(child: CircularProgressIndicator())
                : const SizedBox.shrink(),
          );
        }
        _ensureLoaded(view);
        final elapsed = DateTime.now().difference(view.workout.startedAt);
        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(view.workout.name, overflow: TextOverflow.ellipsis),
                Text(
                  '${_clockText(elapsed)} · ${l10n.setsProgress(view.doneSets, view.totalSets)}',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ],
            ),
            actions: [
              IconButton(
                tooltip: l10n.commonMore,
                icon: const Icon(Icons.more_vert),
                onPressed: () => _menu(view),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilledButton(
                  onPressed: _finishing ? null : () => _finish(view),
                  child: Text(l10n.workoutFinish),
                ),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 120),
            children: [
              if (view.exercises.isEmpty)
                EmptyState(
                  icon: Icons.fitness_center,
                  title: l10n.workoutEmptyTitle,
                  message: l10n.workoutEmptyText,
                ),
              for (final e in view.exercises)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _ExerciseCard(
                    key: ValueKey('ex-${e.order}'),
                    entry: e,
                    exercise: _exercises[e.exerciseId],
                    suggestion: _suggestions[e.exerciseId],
                    workoutId: widget.workoutId,
                    onToggle: (set) => _toggle(set, e),
                    onSwap: (to) async {
                      _suggestions.remove(to);
                      await context.services.workouts.swapExercise(
                        widget.workoutId,
                        e.order,
                        to,
                      );
                    },
                  ),
                ),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                ),
                icon: const Icon(Icons.add),
                label: Text(l10n.workoutAddExercise),
                onPressed: _addExercise,
              ),
            ],
          ),
          bottomNavigationBar: _restEnd == null
              ? null
              : _RestBar(
                  remaining: _restEnd!.difference(DateTime.now()),
                  total: _restTotal,
                  onAdjust: _adjustRest,
                  onSkip: () => setState(() => _restEnd = null),
                ),
        );
      },
    );
  }

  static String _clockText(Duration d) {
    final h = d.inHours;
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }
}

/// Pausen-Timer unten.
class _RestBar extends StatelessWidget {
  const _RestBar({
    required this.remaining,
    required this.total,
    required this.onAdjust,
    required this.onSkip,
  });

  final Duration remaining;
  final int total;
  final ValueChanged<int> onAdjust;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final secs = remaining.inSeconds.clamp(0, 3600);
    final text = '${secs ~/ 60}:${(secs % 60).toString().padLeft(2, '0')}';
    return Material(
      color: theme.colorScheme.secondaryContainer,
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            LinearProgressIndicator(
              value: total <= 0 ? 0 : 1 - secs / total,
              minHeight: 4,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
              child: Row(
                children: [
                  Icon(
                    Icons.hourglass_bottom,
                    color: theme.colorScheme.onSecondaryContainer,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.workoutRest(text),
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: theme.colorScheme.onSecondaryContainer,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => onAdjust(-15),
                    child: const Text('−15'),
                  ),
                  TextButton(
                    onPressed: () => onAdjust(15),
                    child: const Text('+15'),
                  ),
                  FilledButton.tonal(
                    onPressed: onSkip,
                    child: Text(l10n.workoutRestSkip),
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

class _ExerciseCard extends StatelessWidget {
  const _ExerciseCard({
    super.key,
    required this.entry,
    required this.exercise,
    required this.suggestion,
    required this.workoutId,
    required this.onToggle,
    required this.onSwap,
  });

  final SessionExercise entry;
  final Exercise? exercise;
  final Suggestion? suggestion;
  final String workoutId;
  final ValueChanged<WorkoutSet> onToggle;
  final ValueChanged<String> onSwap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final ex = exercise;
    if (ex == null) {
      return const Card(child: SizedBox(height: 120));
    }
    final s = context.services;
    final info = ex.info;
    final allDone = entry.sets.isNotEmpty && entry.sets.every((x) => x.done);
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => showInstructions(context, ex),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  ex.name,
                                  style: theme.textTheme.titleMedium,
                                ),
                              ),
                              if (allDone) ...[
                                const SizedBox(width: 6),
                                Icon(
                                  Icons.check_circle,
                                  size: 18,
                                  color: theme.colorScheme.primary,
                                ),
                              ],
                            ],
                          ),
                          Text(
                            '${l10n.muscleName(ex.primary)} · ${_targetText(l10n, ex.tracking)}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  tooltip: l10n.commonMore,
                  onSelected: (v) async {
                    switch (v) {
                      case 'info':
                        await showInstructions(context, ex);
                      case 'remove':
                        await s.workouts.removeExercise(workoutId, entry.order);
                      case final id:
                        onSwap(id.substring(5));
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'info',
                      child: Text(l10n.exerciseInstructions),
                    ),
                    if (info?.easier != null)
                      PopupMenuItem(
                        value: 'swap:${info!.easier}',
                        child: Text(
                          l10n.workoutSwapEasier(
                            Catalog.byId(info.easier!)!.name.of(l10n.localeName),
                          ),
                        ),
                      ),
                    if (info?.harder != null)
                      PopupMenuItem(
                        value: 'swap:${info!.harder}',
                        child: Text(
                          l10n.workoutSwapHarder(
                            Catalog.byId(info.harder!)!.name.of(l10n.localeName),
                          ),
                        ),
                      ),
                    PopupMenuItem(
                      value: 'remove',
                      child: Text(l10n.workoutRemoveExercise),
                    ),
                  ],
                ),
              ],
            ),
            if (suggestion != null)
              _SuggestionHint(
                suggestion: suggestion!,
                tracking: ex.tracking,
                onSwap: onSwap,
              ),
            const SizedBox(height: 4),
            _SetHeader(tracking: ex.tracking),
            for (final set in entry.sets)
              _SetRow(
                key: ValueKey(set.id),
                set: set,
                tracking: ex.tracking,
                onToggle: () => onToggle(set),
              ),
            Row(
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.add, size: 18),
                  label: Text(l10n.workoutAddSet),
                  onPressed: () => s.workouts.addSet(workoutId, entry.order),
                ),
                const Spacer(),
                if (entry.sets.length > 1)
                  TextButton.icon(
                    icon: const Icon(Icons.remove, size: 18),
                    label: Text(l10n.workoutRemoveSet),
                    onPressed: () => s.workouts.removeSet(entry.sets.last.id),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _targetText(AppLocalizations l10n, Tracking tracking) {
    final first = entry.sets.isEmpty ? null : entry.sets.first;
    return switch (tracking) {
      Tracking.weightReps || Tracking.reps => l10n.targetReps(
        entry.sets.length,
        '${first?.repMin ?? 8}–${first?.repMax ?? 12}',
      ),
      Tracking.duration => l10n.targetSets(entry.sets.length),
      Tracking.cardio => l10n.trackingCardio,
    };
  }
}

/// Hinweis zur automatischen Steigerung.
class _SuggestionHint extends StatelessWidget {
  const _SuggestionHint({
    required this.suggestion,
    required this.tracking,
    required this.onSwap,
  });

  final Suggestion suggestion;
  final Tracking tracking;
  final ValueChanged<String> onSwap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final text = suggestionText(suggestion, l10n);
    if (text == null) return const SizedBox.shrink();
    final up = switch (suggestion.kind) {
      SuggestionKind.increaseWeight ||
      SuggestionKind.moreTime ||
      SuggestionKind.harderVariation => true,
      _ => false,
    };
    final variation = suggestion.variationId;
    return Container(
      margin: const EdgeInsets.only(top: 4, right: 8, bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: up
            ? theme.colorScheme.primaryContainer
            : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            up ? Icons.trending_up : Icons.flag_outlined,
            size: 18,
            color: up
                ? theme.colorScheme.onPrimaryContainer
                : theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
          if (variation != null)
            TextButton(
              onPressed: () => onSwap(variation),
              child: Text(l10n.workoutSwap),
            ),
        ],
      ),
    );
  }
}

/// Text zum Vorschlag (auch für Übungsdetails).
String? suggestionText(Suggestion s, AppLocalizations l10n) {
  final lang = l10n.localeName;
  String variation() =>
      Catalog.byId(s.variationId ?? '')?.name.of(lang) ?? '';
  return switch (s.kind) {
    SuggestionKind.first => l10n.suggestFirst,
    SuggestionKind.increaseWeight => l10n.suggestIncrease(
      formatKg((s.delta ?? 0).toDouble(), l10n),
    ),
    SuggestionKind.moreReps => l10n.suggestReps(s.reps ?? 0),
    SuggestionKind.moreTime => l10n.suggestTime(
      formatSeconds((s.delta ?? 0).toInt()),
    ),
    SuggestionKind.harderVariation => l10n.suggestHarder(variation()),
    SuggestionKind.easierVariation => l10n.suggestEasier(variation()),
    SuggestionKind.deload => l10n.suggestDeload(
      formatKg(s.weightKg ?? 0, l10n),
    ),
    SuggestionKind.repeat => null,
  };
}

class _SetHeader extends StatelessWidget {
  const _SetHeader({required this.tracking});

  final Tracking tracking;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final style = Theme.of(context).textTheme.labelSmall?.copyWith(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 2, right: 56),
      child: Row(
        children: [
          SizedBox(width: 36, child: Text(l10n.setLabel, style: style)),
          if (tracking == Tracking.weightReps)
            Expanded(child: Text(l10n.unitKgShort, style: style)),
          if (tracking == Tracking.weightReps || tracking == Tracking.reps)
            Expanded(child: Text(l10n.repsLabel, style: style)),
          if (tracking == Tracking.duration)
            Expanded(child: Text(l10n.secondsLabel, style: style)),
          if (tracking == Tracking.cardio)
            Expanded(child: Text(l10n.minutesLabel, style: style)),
        ],
      ),
    );
  }
}

/// Eine Satzzeile: Werte direkt editierbar, großer Haken.
class _SetRow extends StatefulWidget {
  const _SetRow({
    super.key,
    required this.set,
    required this.tracking,
    required this.onToggle,
  });

  final WorkoutSet set;
  final Tracking tracking;
  final VoidCallback onToggle;

  @override
  State<_SetRow> createState() => _SetRowState();
}

class _SetRowState extends State<_SetRow> {
  late final _weight = TextEditingController(text: _kg(widget.set.weightKg));
  late final _reps = TextEditingController(text: _int(widget.set.reps));
  late final _seconds = TextEditingController(
    text: widget.tracking == Tracking.cardio
        ? _int(widget.set.seconds == null ? null : widget.set.seconds! ~/ 60)
        : _int(widget.set.seconds),
  );
  final _focus = FocusScopeNode();

  static String _kg(double? v) {
    if (v == null) return '';
    return v == v.roundToDouble() ? v.round().toString() : v.toString();
  }

  static String _int(int? v) => v?.toString() ?? '';

  @override
  void didUpdateWidget(_SetRow old) {
    super.didUpdateWidget(old);
    // Werte von außen (z. B. Variante getauscht) übernehmen, solange nicht
    // gerade getippt wird.
    if (!_focus.hasFocus) {
      _sync(_weight, _kg(widget.set.weightKg));
      _sync(_reps, _int(widget.set.reps));
    }
  }

  void _sync(TextEditingController c, String v) {
    if (c.text != v) c.text = v;
  }

  @override
  void dispose() {
    _weight.dispose();
    _reps.dispose();
    _seconds.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _save() {
    final repo = context.services.workouts;
    final weight = double.tryParse(_weight.text.replaceAll(',', '.'));
    final reps = int.tryParse(_reps.text);
    final secs = int.tryParse(_seconds.text);
    repo.updateSet(
      widget.set.id,
      weightKg: widget.tracking == Tracking.weightReps
          ? Value(weight)
          : const Value.absent(),
      reps: widget.tracking == Tracking.weightReps ||
              widget.tracking == Tracking.reps
          ? Value(reps)
          : const Value.absent(),
      seconds: switch (widget.tracking) {
        Tracking.duration => Value(secs),
        Tracking.cardio => Value(secs == null ? null : secs * 60),
        _ => const Value.absent(),
      },
    );
  }

  Future<void> _hold() async {
    final target = int.tryParse(_seconds.text) ?? 30;
    final held = await showHoldTimer(context, target);
    if (held == null || !mounted) return;
    _seconds.text = '$held';
    _save();
    if (!widget.set.done) widget.onToggle();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final done = widget.set.done;
    final l10n = context.l10n;
    Widget field(
      TextEditingController c, {
      bool decimal = false,
      required String label,
    }) => Padding(
      padding: const EdgeInsets.only(right: 8),
      child: TextField(
        controller: c,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.numberWithOptions(decimal: decimal),
        inputFormatters: [
          FilteringTextInputFormatter.allow(
            RegExp(decimal ? r'[0-9.,]' : r'[0-9]'),
          ),
        ],
        style: theme.textTheme.titleMedium,
        decoration: InputDecoration(
          isDense: true,
          hintText: '–',
          semanticCounterText: label,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
          fillColor: done ? theme.colorScheme.primaryContainer.withValues(alpha: 0.5) : null,
        ),
        onChanged: (_) => _save(),
      ),
    );

    return FocusScope(
      node: _focus,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            SizedBox(
              width: 36,
              child: Text(
                '${widget.set.setIndex + 1}',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            if (widget.tracking == Tracking.weightReps)
              Expanded(
                child: field(_weight, decimal: true, label: l10n.unitKgShort),
              ),
            if (widget.tracking == Tracking.weightReps ||
                widget.tracking == Tracking.reps)
              Expanded(child: field(_reps, label: l10n.repsLabel)),
            if (widget.tracking == Tracking.duration ||
                widget.tracking == Tracking.cardio)
              Expanded(
                child: field(
                  _seconds,
                  label: widget.tracking == Tracking.cardio
                      ? l10n.minutesLabel
                      : l10n.secondsLabel,
                ),
              ),
            if (widget.tracking == Tracking.duration)
              IconButton(
                tooltip: l10n.holdStart,
                icon: const Icon(Icons.timer_outlined),
                onPressed: _hold,
              ),
            SizedBox(
              width: 56,
              height: 48,
              child: IconButton.filledTonal(
                tooltip: done ? l10n.setUndo : l10n.setDone,
                isSelected: done,
                selectedIcon: const Icon(Icons.check),
                style: IconButton.styleFrom(
                  backgroundColor: done ? theme.colorScheme.primary : null,
                  foregroundColor: done ? theme.colorScheme.onPrimary : null,
                ),
                icon: const Icon(Icons.check),
                onPressed: () {
                  FocusScope.of(context).unfocus();
                  _save();
                  widget.onToggle();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
