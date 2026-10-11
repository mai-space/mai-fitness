import 'package:flutter_test/flutter_test.dart';
import 'package:mai_fitness/domain/achievements.dart';

void main() {
  test('IDs sind eindeutig, Texte zweisprachig', () {
    final ids = Achievements.all.map((a) => a.id).toList();
    expect(ids.toSet(), hasLength(ids.length));
    for (final a in Achievements.all) {
      expect(a.title.de, isNotEmpty);
      expect(a.title.en, isNotEmpty);
      expect(a.description.de, isNotEmpty);
    }
  });

  test('nichts erreicht ohne Training', () {
    expect(Achievements.reached(const AchievementStats()), isEmpty);
  });

  test('erstes Training', () {
    final r = Achievements.reached(const AchievementStats(workouts: 1));
    expect(r, {'first_workout'});
  });

  test('Schwellen und Fortschritt', () {
    const s = AchievementStats(
      workouts: 12,
      bestWeekStreak: 4,
      volumeKg: 12500,
      records: 3,
      maxPushUps: 10,
      maxPlankSeconds: 75,
      distinctExercises: 11,
      cardioMinutes: 120,
      fullBodyWeek: true,
    );
    final r = Achievements.reached(s);
    expect(
      r,
      containsAll([
        'first_workout',
        'workouts_5',
        'workouts_10',
        'streak_2',
        'streak_4',
        'volume_1t',
        'volume_10t',
        'first_record',
        'push_ups_10',
        'plank_60',
        'explorer_10',
        'cardio_100',
        'full_body_week',
      ]),
    );
    expect(r, isNot(contains('workouts_25')));
    expect(Achievements.byId('workouts_25')!.progress(s), closeTo(12 / 25, 1e-9));
    expect(Achievements.byId('workouts_5')!.progress(s), 1);
  });
}
