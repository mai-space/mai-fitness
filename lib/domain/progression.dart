import 'dart:math' as math;

import 'exercises/exercise.dart';

/// Ziel einer Übung im Trainingsplan.
class Target {
  const Target({
    this.sets = 3,
    this.repMin = 8,
    this.repMax = 12,
    this.seconds = 30,
    this.minutes = 20,
  });

  final int sets;
  final int repMin;
  final int repMax;

  /// Haltezeit je Satz (Tracking.duration).
  final int seconds;

  /// Dauer (Tracking.cardio).
  final int minutes;

  /// Sinnvolle Vorgabe, wenn kein Plan etwas festlegt.
  static Target defaultFor(Tracking tracking) => switch (tracking) {
    Tracking.weightReps => const Target(),
    Tracking.reps => const Target(repMin: 8, repMax: 15),
    Tracking.duration => const Target(seconds: 30),
    Tracking.cardio => const Target(sets: 1, minutes: 20),
  };
}

/// Ein erledigter Satz aus dem Verlauf.
class SetResult {
  const SetResult({this.weightKg, this.reps, this.seconds});

  final double? weightKg;
  final int? reps;

  /// Sekunden (Haltezeit bzw. Ausdauer-Dauer).
  final int? seconds;
}

/// Alle erledigten Sätze einer Übung in einem Training.
class SessionResult {
  const SessionResult(this.at, this.sets);

  final DateTime at;
  final List<SetResult> sets;
}

/// Art des Vorschlags (für Hinweis und Symbol in der App).
enum SuggestionKind {
  /// Erstes Mal: leicht beginnen, Technik lernen.
  first,

  /// Mehr Gewicht.
  increaseWeight,

  /// Gleiches Gewicht, eine Wiederholung mehr anpeilen.
  moreReps,

  /// Länger halten bzw. länger trainieren.
  moreTime,

  /// Zeit für die schwerere Variante.
  harderVariation,

  /// Zweimal nicht geschafft: etwas leichter, sauber wieder aufbauen.
  deload,

  /// Leichtere Variante empfohlen.
  easierVariation,

  /// Wie zuletzt.
  repeat,
}

/// Vorschlag für das nächste Training einer Übung.
class Suggestion {
  const Suggestion({
    required this.kind,
    this.weightKg,
    this.reps,
    this.seconds,
    this.delta,
    this.variationId,
  });

  final SuggestionKind kind;
  final double? weightKg;
  final int? reps;

  /// Sekunden je Satz (Halten) bzw. gesamt (Ausdauer).
  final int? seconds;

  /// Änderung gegenüber zuletzt (kg, Wiederholungen oder Sekunden).
  final num? delta;

  /// Empfohlene Variante (harder/easier).
  final String? variationId;
}

/// Automatische Steigerung („progressive overload“) — reine Logik.
///
/// * Gewicht + Wiederholungen: doppelte Progression. Erst alle Sätze bis zur
///   oberen Wiederholungszahl steigern, dann Gewicht erhöhen und wieder unten
///   im Bereich anfangen. Zweimal in Folge unter dem Bereich → 10 % leichter.
/// * Körpergewicht: Wiederholungen steigern; oben im Bereich angekommen, die
///   schwerere Variante vorschlagen (falls vorhanden).
/// * Halten: +5 s (bzw. +10 %), Ausdauer: +1 min.
abstract final class Progression {
  /// Gewichtssprung in kg.
  static double incrementFor(ExerciseInfo? info, Equipment equipment, Muscle primary) {
    if (info?.increment != null) return info!.increment!;
    if (equipment == Equipment.dumbbell) return 2;
    const lower = {Muscle.quads, Muscle.hamstrings, Muscle.glutes};
    if (lower.contains(primary) &&
        (equipment == Equipment.machine || equipment == Equipment.barbell)) {
      return 5;
    }
    return 2.5;
  }

  /// Rundet auf den Gewichtssprung (nie unter einen Sprung).
  static double roundTo(double kg, double step) {
    final rounded = (kg / step).round() * step;
    return math.max(step, double.parse(rounded.toStringAsFixed(2)));
  }

  /// [history]: neueste Trainings zuerst; nur erledigte Sätze.
  static Suggestion suggest({
    required Tracking tracking,
    required Target target,
    required List<SessionResult> history,
    double increment = 2.5,
    String? harderId,
    String? easierId,
  }) {
    final sessions = history.where((s) => s.sets.isNotEmpty).toList();
    return switch (tracking) {
      Tracking.weightReps => _weightReps(target, sessions, increment),
      Tracking.reps => _reps(target, sessions, harderId, easierId),
      Tracking.duration => _duration(target, sessions),
      Tracking.cardio => _cardio(target, sessions),
    };
  }

  static Suggestion _weightReps(
    Target target,
    List<SessionResult> sessions,
    double increment,
  ) {
    if (sessions.isEmpty) {
      return Suggestion(kind: SuggestionKind.first, reps: target.repMin);
    }
    final last = sessions.first;
    final weight = _topWeight(last);
    if (weight == null) {
      // Ohne Gewicht protokolliert: wie Körpergewicht steigern.
      return _reps(target, sessions, null, null);
    }
    final atTop = last.sets.where((s) => (s.weightKg ?? 0) >= weight).toList();
    final allMax =
        atTop.length >= target.sets &&
        atTop.every((s) => (s.reps ?? 0) >= target.repMax);
    if (allMax) {
      return Suggestion(
        kind: SuggestionKind.increaseWeight,
        weightKg: weight + increment,
        reps: target.repMin,
        delta: increment,
      );
    }
    if (_failed(last, target, weight) &&
        sessions.length > 1 &&
        _topWeight(sessions[1]) == weight &&
        _failed(sessions[1], target, weight)) {
      final lighter = roundTo(weight * 0.9, increment);
      if (lighter < weight) {
        return Suggestion(
          kind: SuggestionKind.deload,
          weightKg: lighter,
          reps: target.repMax,
          delta: lighter - weight,
        );
      }
    }
    final minReps = atTop.map((s) => s.reps ?? 0).fold<int>(1 << 30, math.min);
    final reps = (minReps + 1).clamp(target.repMin, target.repMax);
    return Suggestion(
      kind: SuggestionKind.moreReps,
      weightKg: weight,
      reps: reps,
      delta: reps - minReps,
    );
  }

  static double? _topWeight(SessionResult s) {
    double? top;
    for (final set in s.sets) {
      final w = set.weightKg;
      if (w != null && w > 0 && (top == null || w > top)) top = w;
    }
    return top;
  }

  /// Unter dem Wiederholungsbereich geblieben (bei [weight]).
  static bool _failed(SessionResult s, Target target, double weight) => s.sets
      .where((x) => (x.weightKg ?? 0) >= weight)
      .any((x) => (x.reps ?? 0) < target.repMin);

  static Suggestion _reps(
    Target target,
    List<SessionResult> sessions,
    String? harderId,
    String? easierId,
  ) {
    if (sessions.isEmpty) {
      return Suggestion(kind: SuggestionKind.first, reps: target.repMin);
    }
    int minOf(SessionResult s) =>
        s.sets.map((x) => x.reps ?? 0).fold<int>(1 << 30, math.min);
    final last = sessions.first;
    final minReps = minOf(last);
    final complete = last.sets.length >= target.sets;
    if (complete && minReps >= target.repMax) {
      if (harderId != null) {
        return Suggestion(
          kind: SuggestionKind.harderVariation,
          reps: target.repMin,
          variationId: harderId,
        );
      }
      // Keine schwerere Variante: über den Bereich hinaus steigern.
      return Suggestion(
        kind: SuggestionKind.moreReps,
        reps: minReps + 1,
        delta: 1,
      );
    }
    if (easierId != null &&
        sessions.length > 1 &&
        minReps < target.repMin &&
        minOf(sessions[1]) < target.repMin) {
      return Suggestion(
        kind: SuggestionKind.easierVariation,
        reps: target.repMin,
        variationId: easierId,
      );
    }
    final reps = (minReps + 1).clamp(target.repMin, target.repMax);
    return Suggestion(
      kind: SuggestionKind.moreReps,
      reps: reps,
      delta: reps - minReps,
    );
  }

  static Suggestion _duration(Target target, List<SessionResult> sessions) {
    if (sessions.isEmpty) {
      return Suggestion(kind: SuggestionKind.first, seconds: target.seconds);
    }
    final last = sessions.first;
    final minSec = last.sets
        .map((x) => x.seconds ?? 0)
        .fold<int>(1 << 30, math.min);
    final goal = math.max(target.seconds, minSec);
    final complete = last.sets.length >= target.sets;
    if (complete && minSec >= goal) {
      // +10 %, mindestens 5 s, auf 5 s gerundet.
      final step = math.max(5, ((minSec * 0.1) / 5).round() * 5);
      return Suggestion(
        kind: SuggestionKind.moreTime,
        seconds: minSec + step,
        delta: step,
      );
    }
    return Suggestion(kind: SuggestionKind.repeat, seconds: goal);
  }

  static Suggestion _cardio(Target target, List<SessionResult> sessions) {
    if (sessions.isEmpty) {
      return Suggestion(kind: SuggestionKind.first, seconds: target.minutes * 60);
    }
    final total = sessions.first.sets.fold<int>(
      0,
      (sum, x) => sum + (x.seconds ?? 0),
    );
    if (total <= 0) {
      return Suggestion(kind: SuggestionKind.repeat, seconds: target.minutes * 60);
    }
    return Suggestion(
      kind: SuggestionKind.moreTime,
      seconds: total + 60,
      delta: 60,
    );
  }
}
