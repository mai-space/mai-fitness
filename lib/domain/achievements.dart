import 'dart:math' as math;

import 'exercises/exercise.dart';

/// Kennzahlen, aus denen Erfolge berechnet werden (aus dem ganzen Verlauf).
class AchievementStats {
  const AchievementStats({
    this.workouts = 0,
    this.bestWeekStreak = 0,
    this.volumeKg = 0,
    this.records = 0,
    this.maxPushUps = 0,
    this.maxPlankSeconds = 0,
    this.distinctExercises = 0,
    this.earlyWorkouts = 0,
    this.lateWorkouts = 0,
    this.cardioMinutes = 0,
    this.fullBodyWeek = false,
    this.comeback = false,
  });

  final int workouts;
  final int bestWeekStreak;
  final double volumeKg;

  /// Persönliche Rekorde insgesamt.
  final int records;

  /// Meiste Liegestütze (Standard oder schwerer) in einem Satz.
  final int maxPushUps;
  final int maxPlankSeconds;
  final int distinctExercises;

  /// Trainings mit Beginn vor 7 Uhr bzw. ab 21 Uhr.
  final int earlyWorkouts;
  final int lateWorkouts;
  final int cardioMinutes;

  /// In einer Kalenderwoche Brust, Rücken, Schultern, Beine und Rumpf.
  final bool fullBodyWeek;

  /// Nach mindestens 14 Tagen Pause wieder trainiert.
  final bool comeback;
}

/// Gruppe (für die Anzeige).
enum AchievementGroup { consistency, strength, skills, variety }

/// Ein Erfolg. IDs sind fest (gespeichert) — nie ändern.
class Achievement {
  const Achievement({
    required this.id,
    required this.group,
    required this.title,
    required this.description,
    required this.goal,
    required this.value,
  });

  final String id;
  final AchievementGroup group;
  final L title;
  final L description;

  /// Zielwert (für den Fortschrittsbalken).
  final num goal;

  /// Aktueller Wert aus den Kennzahlen.
  final num Function(AchievementStats s) value;

  double progress(AchievementStats s) =>
      goal <= 0 ? 1 : math.min(1, value(s) / goal).toDouble();

  bool reached(AchievementStats s) => value(s) >= goal;
}

/// Alle Erfolge. Neue nur anhängen; IDs nie ändern.
abstract final class Achievements {
  static int _b(bool v) => v ? 1 : 0;

  static Achievement _workouts(int n, String de, String en) => Achievement(
    id: 'workouts_$n',
    group: AchievementGroup.consistency,
    title: L(de, en),
    description: L('$n Trainings abgeschlossen', '$n workouts completed'),
    goal: n,
    value: (s) => s.workouts,
  );

  static Achievement _streak(int n, String de, String en) => Achievement(
    id: 'streak_$n',
    group: AchievementGroup.consistency,
    title: L(de, en),
    description: L(
      '$n Wochen in Folge dein Wochenziel geschafft',
      'Hit your weekly goal $n weeks in a row',
    ),
    goal: n,
    value: (s) => s.bestWeekStreak,
  );

  static Achievement _volume(int tons, String de, String en) => Achievement(
    id: 'volume_${tons}t',
    group: AchievementGroup.strength,
    title: L(de, en),
    description: L(
      'Insgesamt $tons Tonnen bewegt',
      'Lifted $tons tonnes in total',
    ),
    goal: tons * 1000,
    value: (s) => s.volumeKg,
  );

  static final List<Achievement> all = [
    Achievement(
      id: 'first_workout',
      group: AchievementGroup.consistency,
      title: const L('Der erste Schritt', 'The first step'),
      description: const L(
        'Dein erstes Training abgeschlossen',
        'Completed your first workout',
      ),
      goal: 1,
      value: (s) => s.workouts,
    ),
    _workouts(5, 'Dranbleiber', 'Keeping at it'),
    _workouts(10, 'Zweistellig', 'Double digits'),
    _workouts(25, 'Gewohnheit', 'Habit formed'),
    _workouts(50, 'Halbes Hundert', 'Half a hundred'),
    _workouts(100, 'Hundert!', 'One hundred!'),
    _workouts(250, 'Urgestein', 'Veteran'),
    _streak(2, 'Im Rhythmus', 'In the groove'),
    _streak(4, 'Ein Monat am Stück', 'A month straight'),
    _streak(8, 'Nicht zu bremsen', 'Unstoppable'),
    _streak(12, 'Ein Quartal stark', 'A strong quarter'),
    _streak(26, 'Halbes Jahr', 'Half a year'),
    _volume(1, 'Erste Tonne', 'First tonne'),
    _volume(10, 'Zehn Tonnen', 'Ten tonnes'),
    _volume(100, 'Schwergewicht', 'Heavyweight'),
    _volume(500, 'Bergversetzer', 'Mountain mover'),
    Achievement(
      id: 'first_record',
      group: AchievementGroup.strength,
      title: const L('Neuer Rekord', 'New record'),
      description: const L(
        'Deinen ersten persönlichen Rekord aufgestellt',
        'Set your first personal record',
      ),
      goal: 1,
      value: (s) => s.records,
    ),
    Achievement(
      id: 'records_10',
      group: AchievementGroup.strength,
      title: const L('Rekordjäger', 'Record hunter'),
      description: const L(
        '10 persönliche Rekorde aufgestellt',
        'Set 10 personal records',
      ),
      goal: 10,
      value: (s) => s.records,
    ),
    Achievement(
      id: 'records_50',
      group: AchievementGroup.strength,
      title: const L('Immer besser', 'Always improving'),
      description: const L(
        '50 persönliche Rekorde aufgestellt',
        'Set 50 personal records',
      ),
      goal: 50,
      value: (s) => s.records,
    ),
    Achievement(
      id: 'push_ups_10',
      group: AchievementGroup.skills,
      title: const L('Zehn am Stück', 'Ten in a row'),
      description: const L(
        '10 Liegestütze in einem Satz',
        '10 push-ups in one set',
      ),
      goal: 10,
      value: (s) => s.maxPushUps,
    ),
    Achievement(
      id: 'push_ups_25',
      group: AchievementGroup.skills,
      title: const L('Liegestütz-Profi', 'Push-up pro'),
      description: const L(
        '25 Liegestütze in einem Satz',
        '25 push-ups in one set',
      ),
      goal: 25,
      value: (s) => s.maxPushUps,
    ),
    Achievement(
      id: 'plank_60',
      group: AchievementGroup.skills,
      title: const L('Eine Minute Stahl', 'One minute of steel'),
      description: const L('60 Sekunden Plank gehalten', 'Held a plank for 60 seconds'),
      goal: 60,
      value: (s) => s.maxPlankSeconds,
    ),
    Achievement(
      id: 'plank_120',
      group: AchievementGroup.skills,
      title: const L('Fels in der Brandung', 'Rock solid'),
      description: const L(
        '2 Minuten Plank gehalten',
        'Held a plank for 2 minutes',
      ),
      goal: 120,
      value: (s) => s.maxPlankSeconds,
    ),
    Achievement(
      id: 'explorer_10',
      group: AchievementGroup.variety,
      title: const L('Entdecker', 'Explorer'),
      description: const L(
        '10 verschiedene Übungen ausprobiert',
        'Tried 10 different exercises',
      ),
      goal: 10,
      value: (s) => s.distinctExercises,
    ),
    Achievement(
      id: 'explorer_25',
      group: AchievementGroup.variety,
      title: const L('Allrounder', 'All-rounder'),
      description: const L(
        '25 verschiedene Übungen ausprobiert',
        'Tried 25 different exercises',
      ),
      goal: 25,
      value: (s) => s.distinctExercises,
    ),
    Achievement(
      id: 'full_body_week',
      group: AchievementGroup.variety,
      title: const L('Von Kopf bis Fuß', 'Head to toe'),
      description: const L(
        'In einer Woche Brust, Rücken, Schultern, Beine und Rumpf trainiert',
        'Trained chest, back, shoulders, legs and core in one week',
      ),
      goal: 1,
      value: (s) => _b(s.fullBodyWeek),
    ),
    Achievement(
      id: 'early_bird',
      group: AchievementGroup.consistency,
      title: const L('Frühaufsteher', 'Early bird'),
      description: const L(
        '5 Trainings vor 7 Uhr begonnen',
        'Started 5 workouts before 7 am',
      ),
      goal: 5,
      value: (s) => s.earlyWorkouts,
    ),
    Achievement(
      id: 'night_owl',
      group: AchievementGroup.consistency,
      title: const L('Nachteule', 'Night owl'),
      description: const L(
        '5 Trainings ab 21 Uhr begonnen',
        'Started 5 workouts after 9 pm',
      ),
      goal: 5,
      value: (s) => s.lateWorkouts,
    ),
    Achievement(
      id: 'cardio_100',
      group: AchievementGroup.variety,
      title: const L('Ausdauernd', 'Enduring'),
      description: const L(
        '100 Minuten Ausdauertraining',
        '100 minutes of cardio',
      ),
      goal: 100,
      value: (s) => s.cardioMinutes,
    ),
    Achievement(
      id: 'cardio_500',
      group: AchievementGroup.variety,
      title: const L('Langer Atem', 'Long breath'),
      description: const L(
        '500 Minuten Ausdauertraining',
        '500 minutes of cardio',
      ),
      goal: 500,
      value: (s) => s.cardioMinutes,
    ),
    Achievement(
      id: 'comeback',
      group: AchievementGroup.consistency,
      title: const L('Comeback', 'Comeback'),
      description: const L(
        'Nach mindestens zwei Wochen Pause wieder eingestiegen',
        'Came back after a break of two weeks or more',
      ),
      goal: 1,
      value: (s) => _b(s.comeback),
    ),
  ];

  static Achievement? byId(String id) {
    for (final a in all) {
      if (a.id == id) return a;
    }
    return null;
  }

  /// IDs aller erreichten Erfolge.
  static Set<String> reached(AchievementStats s) => {
    for (final a in all)
      if (a.reached(s)) a.id,
  };
}
