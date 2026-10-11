import 'package:flutter_test/flutter_test.dart';
import 'package:mai_fitness/domain/exercises/exercise.dart';
import 'package:mai_fitness/domain/progression.dart';
import 'package:mai_fitness/domain/stats.dart';

void main() {
  test('1RM nach Epley', () {
    expect(Stats.oneRepMax(100, 1), 100);
    expect(Stats.oneRepMax(60, 10), closeTo(80, 0.01));
    expect(Stats.oneRepMax(0, 10), 0);
  });

  test('Leistungswert je Art', () {
    const sets = [
      SetResult(weightKg: 60, reps: 10),
      SetResult(weightKg: 70, reps: 5),
    ];
    expect(Stats.performance(Tracking.weightReps, sets), 81.7);
    expect(
      Stats.performance(Tracking.reps, const [SetResult(reps: 12), SetResult(reps: 9)]),
      12,
    );
    expect(
      Stats.performance(Tracking.cardio, const [SetResult(seconds: 1500)]),
      25,
    );
    expect(Stats.performance(Tracking.reps, const []), isNull);
    expect(Stats.volume(sets), 950);
  });

  group('Wochenserie', () {
    // Montag, 12.10.2026.
    final now = DateTime(2026, 10, 14, 18);
    test('laufende Woche unterbricht nicht', () {
      final dates = [
        DateTime(2026, 10, 5), DateTime(2026, 10, 7), // Vorwoche: 2
        DateTime(2026, 9, 28), DateTime(2026, 9, 30), // davor: 2
      ];
      expect(Stats.weekStreak(dates, 2, now), 2);
    });

    test('laufende Woche zählt, sobald das Ziel erreicht ist', () {
      final dates = [
        DateTime(2026, 10, 12), DateTime(2026, 10, 13),
        DateTime(2026, 10, 5), DateTime(2026, 10, 7),
      ];
      expect(Stats.weekStreak(dates, 2, now), 2);
    });

    test('Lücke beendet die Serie', () {
      final dates = [DateTime(2026, 10, 5), DateTime(2026, 9, 21)];
      expect(Stats.weekStreak(dates, 1, now), 1);
      expect(Stats.bestWeekStreak(dates, 1), 1);
    });

    test('beste Serie', () {
      final dates = [
        for (var w = 0; w < 5; w++) DateTime(2026, 6, 1 + 7 * w),
        DateTime(2026, 9, 1),
      ];
      expect(Stats.bestWeekStreak(dates, 1), 5);
    });
  });

  group('Prognose', () {
    final now = DateTime(2026, 10, 10);

    test('zu wenig Daten → keine Prognose', () {
      expect(Forecast.of([Point(now, 50)], now), isNull);
      expect(
        Forecast.of([
          Point(now.subtract(const Duration(days: 2)), 50),
          Point(now.subtract(const Duration(days: 1)), 51),
          Point(now, 52),
        ], now),
        isNull,
        reason: 'weniger als eine Woche',
      );
    });

    test('steigender Verlauf → steigende Prognose, gedämpft', () {
      final points = [
        for (var i = 0; i < 6; i++)
          Point(now.subtract(Duration(days: 35 - i * 7)), 50.0 + i * 1),
      ];
      final p = Forecast.of(points, now)!;
      expect(p.trend, Trend.rising);
      expect(p.perWeek, closeTo(1, 0.05));
      expect(p.in4Weeks, greaterThan(p.current));
      // Zweite Hälfte nur halb so steil.
      expect(p.in8Weeks - p.in4Weeks, closeTo((p.in4Weeks - p.current) / 2, 0.2));
      expect(p.weeksUntil(p.current + 2), closeTo(2, 0.2));
    });

    test('unrealistische Sprünge werden gedeckelt (3 %/Woche)', () {
      final points = [
        Point(now.subtract(const Duration(days: 14)), 20),
        Point(now.subtract(const Duration(days: 7)), 40),
        Point(now, 60),
      ];
      final p = Forecast.of(points, now)!;
      expect(p.perWeek, lessThanOrEqualTo(p.current * Forecast.maxWeeklyGain + 0.1));
    });

    test('flacher Verlauf → Plateau', () {
      final points = [
        for (var i = 0; i < 5; i++)
          Point(now.subtract(Duration(days: 28 - i * 7)), 60),
      ];
      final p = Forecast.of(points, now)!;
      expect(p.trend, Trend.flat);
      expect(p.weeksUntil(70), isNull);
    });
  });
}
