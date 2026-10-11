import 'package:drift/drift.dart';

import '../domain/exercises/exercise.dart';
import 'connection/connection.dart';

part 'app_database.g.dart';

// Alle Enums werden als Index gespeichert (`intEnum`): neue Werte nur hinten
// anhängen, nie umsortieren oder löschen.

/// Einstellungen als Schlüssel/Wert (tolerant lesen, siehe SettingsKeys).
class LocalSettings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column<Object>> get primaryKey => {key};
}

/// Eigene Übungen. Eingebaute stehen im Code (`builtinExercises`).
class CustomExercises extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  IntColumn get equipment => intEnum<Equipment>()();
  IntColumn get tracking => intEnum<Tracking>()();
  IntColumn get primaryMuscle => intEnum<Muscle>()();
  TextColumn get notes => text().nullable()();
  BoolColumn get archived => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Trainingsplan („Ganzkörper A“). Pläne werden reihum trainiert.
class Routines extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  BoolColumn get archived => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Übung in einem Plan, mit Ziel (Sätze, Wiederholungsbereich, Pause).
class RoutineExercises extends Table {
  TextColumn get id => text()();
  TextColumn get routineId => text()();
  TextColumn get exerciseId => text()();
  IntColumn get position => integer().withDefault(const Constant(0))();
  IntColumn get sets => integer().withDefault(const Constant(3))();
  IntColumn get repMin => integer().withDefault(const Constant(8))();
  IntColumn get repMax => integer().withDefault(const Constant(12))();

  /// Haltezeit je Satz (Sekunden) bzw. Dauer (Minuten × 60) bei Ausdauer.
  IntColumn get targetSeconds => integer().nullable()();
  IntColumn get restSeconds => integer().withDefault(const Constant(90))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Ein Training. Läuft, solange `finishedAt` leer ist (überlebt das
/// Schließen der App).
class Workouts extends Table {
  TextColumn get id => text()();
  TextColumn get routineId => text().nullable()();
  TextColumn get name => text()();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get finishedAt => dateTime().nullable()();
  TextColumn get note => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Ein Satz in einem Training. Vorgeschlagene Werte stehen schon vor dem
/// Abhaken drin; gezählt wird nur `done`.
class WorkoutSets extends Table {
  TextColumn get id => text()();
  TextColumn get workoutId => text()();
  TextColumn get exerciseId => text()();

  /// Reihenfolge der Übung im Training.
  IntColumn get exerciseOrder => integer()();
  IntColumn get setIndex => integer()();
  RealColumn get weightKg => real().nullable()();
  IntColumn get reps => integer().nullable()();

  /// Haltezeit bzw. Ausdauer-Dauer in Sekunden.
  IntColumn get seconds => integer().nullable()();
  BoolColumn get done => boolean().withDefault(const Constant(false))();
  DateTimeColumn get completedAt => dateTime().nullable()();

  /// Ziel aus dem Plan zum Zeitpunkt des Trainings (für die Progression).
  IntColumn get repMin => integer().nullable()();
  IntColumn get repMax => integer().nullable()();
  IntColumn get restSeconds => integer().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Freigeschaltete Erfolge (ID aus `Achievements.all`).
class UnlockedAchievements extends Table {
  TextColumn get id => text()();
  DateTimeColumn get unlockedAt => dateTime()();

  /// In der App schon gezeigt (Hinweis „neu“).
  BoolColumn get seen => boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Persönliche Rekorde (für Erfolge und „Neuer Rekord!“-Hinweise).
class PersonalRecords extends Table {
  TextColumn get id => text()();
  TextColumn get exerciseId => text()();
  TextColumn get workoutId => text()();

  /// Leistungswert (siehe `Stats.performance`).
  RealColumn get value => real()();
  RealColumn get previous => real().nullable()();
  DateTimeColumn get achievedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DriftDatabase(
  tables: [
    LocalSettings,
    CustomExercises,
    Routines,
    RoutineExercises,
    Workouts,
    WorkoutSets,
    UnlockedAchievements,
    PersonalRecords,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
    : super(executor ?? openAppDatabase());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await _createIndexes();
    },
    // Schritte strikt aufsteigend: jeder Block bringt v(n-1) → v(n).
    // Beispiel: if (from < 2) { await m.addColumn(...); }
    onUpgrade: (m, from, to) async {},
  );

  Future<void> _createIndexes() async {
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_workout_sets_workout '
      'ON workout_sets (workout_id, exercise_order, set_index)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_workout_sets_exercise '
      'ON workout_sets (exercise_id, done)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_workouts_started '
      'ON workouts (started_at)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_routine_exercises_routine '
      'ON routine_exercises (routine_id, position)',
    );
  }
}
