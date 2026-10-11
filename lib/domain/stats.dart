import 'dart:math' as math;

import 'exercises/exercise.dart';
import 'progression.dart';

/// Kennzahlen und Prognosen — reine Logik, vollständig getestet.
abstract final class Stats {
  /// Geschätztes Maximalgewicht für eine Wiederholung (Epley).
  static double oneRepMax(double weightKg, int reps) {
    if (reps <= 0 || weightKg <= 0) return 0;
    if (reps == 1) return weightKg;
    return weightKg * (1 + reps / 30);
  }

  /// Leistungswert einer Übung in einem Training (für Verlauf, Rekorde und
  /// Prognose): geschätztes 1RM, beste Wiederholungszahl, längste Haltezeit
  /// bzw. Ausdauer-Minuten.
  static double? performance(Tracking tracking, List<SetResult> sets) {
    if (sets.isEmpty) return null;
    switch (tracking) {
      case Tracking.weightReps:
        var best = 0.0;
        var bestReps = 0;
        for (final s in sets) {
          best = math.max(best, oneRepMax(s.weightKg ?? 0, s.reps ?? 0));
          bestReps = math.max(bestReps, s.reps ?? 0);
        }
        // Ohne Gewicht protokolliert: Wiederholungen zählen.
        return best > 0 ? _round1(best) : (bestReps > 0 ? bestReps.toDouble() : null);
      case Tracking.reps:
        final best = sets.map((s) => s.reps ?? 0).fold<int>(0, math.max);
        return best > 0 ? best.toDouble() : null;
      case Tracking.duration:
        final best = sets.map((s) => s.seconds ?? 0).fold<int>(0, math.max);
        return best > 0 ? best.toDouble() : null;
      case Tracking.cardio:
        final total = sets.fold<int>(0, (sum, s) => sum + (s.seconds ?? 0));
        return total > 0 ? _round1(total / 60) : null;
    }
  }

  /// Bewegte Last (kg × Wiederholungen).
  static double volume(Iterable<SetResult> sets) => sets.fold(
    0.0,
    (sum, s) => sum + (s.weightKg ?? 0) * (s.reps ?? 0),
  );

  static double _round1(double v) => (v * 10).round() / 10;

  /// Montag 00:00 der Woche von [day].
  static DateTime weekStart(DateTime day) {
    final d = DateTime(day.year, day.month, day.day);
    return DateTime(d.year, d.month, d.day - (d.weekday - 1));
  }

  /// Wochen in Folge mit mindestens [goal] Trainings, bis heute. Die laufende
  /// Woche zählt mit, sobald das Ziel erreicht ist — und unterbricht die
  /// Serie nicht, solange sie noch läuft.
  static int weekStreak(Iterable<DateTime> workouts, int goal, DateTime now) {
    if (goal <= 0) goal = 1;
    final counts = <DateTime, int>{};
    for (final w in workouts) {
      final k = weekStart(w);
      counts[k] = (counts[k] ?? 0) + 1;
    }
    var week = weekStart(now);
    var streak = 0;
    if ((counts[week] ?? 0) >= goal) streak++;
    while (true) {
      week = DateTime(week.year, week.month, week.day - 7);
      if ((counts[week] ?? 0) >= goal) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  /// Längste Serie überhaupt (für Erfolge).
  static int bestWeekStreak(Iterable<DateTime> workouts, int goal) {
    if (goal <= 0) goal = 1;
    final counts = <DateTime, int>{};
    for (final w in workouts) {
      final k = weekStart(w);
      counts[k] = (counts[k] ?? 0) + 1;
    }
    final weeks = counts.keys.where((k) => counts[k]! >= goal).toList()..sort();
    var best = 0;
    var run = 0;
    DateTime? prev;
    for (final w in weeks) {
      final consecutive =
          prev != null &&
          DateTime(prev.year, prev.month, prev.day + 7) == w;
      run = consecutive ? run + 1 : 1;
      best = math.max(best, run);
      prev = w;
    }
    return best;
  }
}

/// Ein Messpunkt im Verlauf (Tag, Leistungswert).
class Point {
  const Point(this.at, this.value);

  final DateTime at;
  final double value;
}

enum Trend { rising, flat, falling }

/// Prognose für eine Übung.
class Prognosis {
  const Prognosis({
    required this.current,
    required this.perWeek,
    required this.in4Weeks,
    required this.in8Weeks,
    required this.trend,
  });

  /// Geglätteter aktueller Wert (Regressionsgerade heute).
  final double current;

  /// Veränderung pro Woche (in der Einheit des Werts).
  final double perWeek;
  final double in4Weeks;
  final double in8Weeks;
  final Trend trend;

  /// Wochen, bis [goal] voraussichtlich erreicht ist; `null` ohne Anstieg.
  double? weeksUntil(double goal) {
    if (goal <= current) return 0;
    if (perWeek <= 0) return null;
    return (goal - current) / perWeek;
  }
}

/// Prognose über eine lineare Regression der letzten Trainings, mit
/// realistischer Obergrenze: Anfänger steigern sich schnell, aber nicht
/// unbegrenzt — mehr als [maxWeeklyGain] (Anteil pro Woche) wird nicht
/// fortgeschrieben, und weiter in die Zukunft flacht die Kurve ab.
abstract final class Forecast {
  static const maxWeeklyGain = 0.03;
  static const minPoints = 3;
  static const minSpanDays = 7;
  static const window = Duration(days: 120);
  static const maxPoints = 12;

  static Prognosis? of(List<Point> history, DateTime now) {
    final recent =
        history
            .where((p) => now.difference(p.at) <= window && p.value > 0)
            .toList()
          ..sort((a, b) => a.at.compareTo(b.at));
    final points = recent.length > maxPoints
        ? recent.sublist(recent.length - maxPoints)
        : recent;
    if (points.length < minPoints) return null;
    final span = points.last.at.difference(points.first.at).inHours / 24;
    if (span < minSpanDays) return null;

    // x in Tagen ab dem ersten Punkt.
    final origin = points.first.at;
    final xs = [for (final p in points) p.at.difference(origin).inHours / 24];
    final ys = [for (final p in points) p.value];
    final n = points.length;
    final mx = xs.reduce((a, b) => a + b) / n;
    final my = ys.reduce((a, b) => a + b) / n;
    var sxy = 0.0;
    var sxx = 0.0;
    for (var i = 0; i < n; i++) {
      sxy += (xs[i] - mx) * (ys[i] - my);
      sxx += (xs[i] - mx) * (xs[i] - mx);
    }
    if (sxx == 0) return null;
    final slopePerDay = sxy / sxx;
    final today = now.difference(origin).inHours / 24;
    // Nicht über den besten echten Wert hinaus „glätten“ und nicht darunter
    // fallen lassen, wenn die Gerade nur wegen Ausreißern sinkt.
    final fitted = my + slopePerDay * (today - mx);
    final best = ys.reduce(math.max);
    final current = fitted.clamp(ys.last * 0.9, best);

    var perWeek = slopePerDay * 7;
    final cap = current * maxWeeklyGain;
    if (perWeek > cap) perWeek = cap;
    final flatBand = current * 0.003;
    final trend = perWeek > flatBand
        ? Trend.rising
        : (perWeek < -flatBand ? Trend.falling : Trend.flat);
    // Abflachend: zweite Hälfte (Woche 5–8) nur halbe Steigerung.
    final w4 = current + perWeek * 4;
    final w8 = w4 + perWeek * 4 * (perWeek > 0 ? 0.5 : 1);
    return Prognosis(
      current: _r(current),
      perWeek: _r(perWeek),
      in4Weeks: _r(math.max(0, w4)),
      in8Weeks: _r(math.max(0, w8)),
      trend: trend,
    );
  }

  static double _r(double v) => (v * 10).round() / 10;
}
