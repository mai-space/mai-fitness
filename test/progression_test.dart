import 'package:flutter_test/flutter_test.dart';
import 'package:mai_fitness/domain/exercises/exercise.dart';
import 'package:mai_fitness/domain/progression.dart';

SessionResult session(List<(double?, int)> sets, {int daysAgo = 2}) =>
    SessionResult(
      DateTime(2026, 10, 10).subtract(Duration(days: daysAgo)),
      [for (final (w, r) in sets) SetResult(weightKg: w, reps: r)],
    );

void main() {
  const target = Target(sets: 3, repMin: 8, repMax: 12);

  group('Gewicht + Wiederholungen (doppelte Progression)', () {
    test('ohne Verlauf: leicht beginnen, untere Wiederholungszahl', () {
      final s = Progression.suggest(
        tracking: Tracking.weightReps,
        target: target,
        history: const [],
      );
      expect(s.kind, SuggestionKind.first);
      expect(s.weightKg, isNull);
      expect(s.reps, 8);
    });

    test('alle Sätze oben im Bereich → mehr Gewicht, wieder unten anfangen', () {
      final s = Progression.suggest(
        tracking: Tracking.weightReps,
        target: target,
        history: [session([(40, 12), (40, 12), (40, 12)])],
        increment: 2.5,
      );
      expect(s.kind, SuggestionKind.increaseWeight);
      expect(s.weightKg, 42.5);
      expect(s.reps, 8);
      expect(s.delta, 2.5);
    });

    test('noch nicht oben → gleiches Gewicht, eine Wiederholung mehr', () {
      final s = Progression.suggest(
        tracking: Tracking.weightReps,
        target: target,
        history: [session([(40, 10), (40, 9), (40, 9)])],
      );
      expect(s.kind, SuggestionKind.moreReps);
      expect(s.weightKg, 40);
      expect(s.reps, 10);
    });

    test('zu wenige Sätze geschafft → keine Steigerung', () {
      final s = Progression.suggest(
        tracking: Tracking.weightReps,
        target: target,
        history: [session([(40, 12), (40, 12)])],
      );
      expect(s.kind, SuggestionKind.moreReps);
      expect(s.weightKg, 40);
      expect(s.reps, 12);
    });

    test('zweimal unter dem Bereich → 10 % leichter (auf Sprung gerundet)', () {
      final s = Progression.suggest(
        tracking: Tracking.weightReps,
        target: target,
        history: [
          session([(50, 6), (50, 5), (50, 5)], daysAgo: 2),
          session([(50, 7), (50, 6), (50, 6)], daysAgo: 5),
        ],
        increment: 2.5,
      );
      expect(s.kind, SuggestionKind.deload);
      expect(s.weightKg, 45);
      expect(s.reps, 12);
    });

    test('einmal verfehlt → noch kein Deload', () {
      final s = Progression.suggest(
        tracking: Tracking.weightReps,
        target: target,
        history: [
          session([(50, 6), (50, 5), (50, 5)], daysAgo: 2),
          session([(47.5, 12), (47.5, 12), (47.5, 12)], daysAgo: 5),
        ],
      );
      expect(s.kind, SuggestionKind.moreReps);
      expect(s.weightKg, 50);
      expect(s.reps, 8);
    });

    test('Gewichtssprung nach Ausrüstung und Muskel', () {
      expect(
        Progression.incrementFor(null, Equipment.machine, Muscle.quads),
        5,
      );
      expect(
        Progression.incrementFor(null, Equipment.machine, Muscle.chest),
        2.5,
      );
      expect(
        Progression.incrementFor(null, Equipment.dumbbell, Muscle.biceps),
        2,
      );
    });
  });

  group('Körpergewicht', () {
    const bw = Target(sets: 3, repMin: 8, repMax: 15);

    test('Wiederholungen steigen bis zum oberen Ende', () {
      final s = Progression.suggest(
        tracking: Tracking.reps,
        target: bw,
        history: [session([(null, 10), (null, 9), (null, 9)])],
      );
      expect(s.kind, SuggestionKind.moreReps);
      expect(s.reps, 10);
    });

    test('oben angekommen → schwerere Variante', () {
      final s = Progression.suggest(
        tracking: Tracking.reps,
        target: bw,
        history: [session([(null, 15), (null, 15), (null, 16)])],
        harderId: 'push_up',
      );
      expect(s.kind, SuggestionKind.harderVariation);
      expect(s.variationId, 'push_up');
      expect(s.reps, 8);
    });

    test('ohne schwerere Variante → über den Bereich hinaus', () {
      final s = Progression.suggest(
        tracking: Tracking.reps,
        target: bw,
        history: [session([(null, 15), (null, 15), (null, 15)])],
      );
      expect(s.kind, SuggestionKind.moreReps);
      expect(s.reps, 16);
    });

    test('zweimal unter dem Bereich → leichtere Variante', () {
      final s = Progression.suggest(
        tracking: Tracking.reps,
        target: bw,
        history: [
          session([(null, 4), (null, 3), (null, 3)]),
          session([(null, 5), (null, 4), (null, 3)], daysAgo: 4),
        ],
        easierId: 'knee_push_up',
      );
      expect(s.kind, SuggestionKind.easierVariation);
      expect(s.variationId, 'knee_push_up');
    });
  });

  group('Halten und Ausdauer', () {
    test('Ziel gehalten → +5 s', () {
      final s = Progression.suggest(
        tracking: Tracking.duration,
        target: const Target(sets: 3, seconds: 30),
        history: [
          SessionResult(DateTime(2026, 10, 1), const [
            SetResult(seconds: 30),
            SetResult(seconds: 32),
            SetResult(seconds: 30),
          ]),
        ],
      );
      expect(s.kind, SuggestionKind.moreTime);
      expect(s.seconds, 35);
    });

    test('lange Haltezeit → +10 % (auf 5 s gerundet)', () {
      final s = Progression.suggest(
        tracking: Tracking.duration,
        target: const Target(sets: 1, seconds: 30),
        history: [
          SessionResult(DateTime(2026, 10, 1), const [SetResult(seconds: 120)]),
        ],
      );
      expect(s.seconds, 130);
    });

    test('Ziel verfehlt → gleiches Ziel', () {
      final s = Progression.suggest(
        tracking: Tracking.duration,
        target: const Target(sets: 3, seconds: 45),
        history: [
          SessionResult(DateTime(2026, 10, 1), const [
            SetResult(seconds: 45),
            SetResult(seconds: 30),
            SetResult(seconds: 25),
          ]),
        ],
      );
      expect(s.kind, SuggestionKind.repeat);
      expect(s.seconds, 45);
    });

    test('Ausdauer: eine Minute mehr', () {
      final s = Progression.suggest(
        tracking: Tracking.cardio,
        target: const Target(sets: 1, minutes: 20),
        history: [
          SessionResult(DateTime(2026, 10, 1), const [SetResult(seconds: 1200)]),
        ],
      );
      expect(s.seconds, 1260);
    });
  });
}
