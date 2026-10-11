/// Übungen: eingebaute Bibliothek (Code, zweisprachig) und eigene Übungen
/// (Datenbank). Eingebaute IDs sind fest und werden nie umbenannt — der
/// Trainingsverlauf hängt daran.
library;

/// Text in beiden App-Sprachen.
class L {
  const L(this.de, this.en);

  final String de;
  final String en;

  String of(String languageCode) => languageCode == 'de' ? de : en;
}

/// Wie eine Übung gezählt wird. Index wird gespeichert — nur am Ende
/// erweitern.
enum Tracking {
  /// Wiederholungen mit Zusatzgewicht (Geräte, Hanteln).
  weightReps,

  /// Nur Wiederholungen (Körpergewicht).
  reps,

  /// Haltezeit in Sekunden (Plank, Wandsitzen).
  duration,

  /// Ausdauer: Minuten (Laufband, Ergometer).
  cardio,
}

/// Ausrüstung. Index wird gespeichert — nur am Ende erweitern.
enum Equipment {
  /// Gerät im Studio (geführte Bewegung).
  machine,

  /// Kabelzug.
  cable,

  /// Langhantel.
  barbell,

  /// Kurzhanteln.
  dumbbell,

  /// Ohne Geräte (Körpergewicht).
  bodyweight,

  /// Klimmzugstange, Dip-Barren, Bank o. Ä. — einfache Hilfsmittel.
  bar,

  /// Ausdauergerät (Laufband, Fahrrad, Rudergerät, Crosstrainer).
  cardioMachine,
}

/// Muskelgruppe. Index wird gespeichert — nur am Ende erweitern.
enum Muscle {
  chest,
  back,
  shoulders,
  biceps,
  triceps,
  core,
  quads,
  hamstrings,
  glutes,
  calves,
  fullBody,
  cardio,
}

/// Eine eingebaute Übung mit Anleitung.
class ExerciseInfo {
  const ExerciseInfo({
    required this.id,
    required this.name,
    required this.equipment,
    required this.tracking,
    required this.primary,
    this.secondary = const [],
    required this.setup,
    required this.steps,
    required this.tips,
    required this.mistakes,
    this.beginner = true,
    this.easier,
    this.harder,
    this.increment,
  });

  /// Feste ID (`leg_press`) — nie ändern.
  final String id;
  final L name;
  final Equipment equipment;
  final Tracking tracking;
  final Muscle primary;
  final List<Muscle> secondary;

  /// Einstellung des Geräts bzw. Ausgangsposition.
  final L setup;

  /// Ablauf, Schritt für Schritt.
  final List<L> steps;

  /// Hinweise für saubere Ausführung (Atmung, Tempo).
  final List<L> tips;

  /// Häufige Fehler.
  final List<L> mistakes;

  /// Für Einsteiger geeignet.
  final bool beginner;

  /// IDs leichterer/schwererer Varianten (Progression ohne Gewicht).
  final String? easier;
  final String? harder;

  /// Gewichtssprung in kg; `null` = Standard nach Ausrüstung/Muskel.
  final double? increment;
}
