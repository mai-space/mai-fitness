import 'dart:async';

import 'package:drift/drift.dart' show TableUpdateQuery;
import 'package:flutter/widgets.dart';

import '../data/app_database.dart';
import '../data/repositories/exercise_repository.dart';
import '../data/repositories/progress_repository.dart';
import '../data/repositories/routine_repository.dart';
import '../data/repositories/workout_repository.dart';
import '../data/settings.dart';
import '../home_widgets/home_widgets.dart';
import '../l10n/l10n.dart';
import '../services/reminders.dart';

/// Alle Dienste der App an einem Ort (ohne zusätzliches State-Paket).
class AppServices {
  AppServices(this.db)
    : settings = Settings(db),
      exercises = ExerciseRepository(db),
      routines = RoutineRepository(db),
      workouts = WorkoutRepository(db),
      progress = ProgressRepository(db),
      reminders = Reminders(db),
      widgets = HomeWidgets(db);

  final AppDatabase db;
  final Settings settings;
  final ExerciseRepository exercises;
  final RoutineRepository routines;
  final WorkoutRepository workouts;
  final ProgressRepository progress;
  final Reminders reminders;
  final HomeWidgets widgets;

  Timer? _rescheduleTimer;
  StreamSubscription<void>? _sub;

  /// Erinnerungen nach Änderungen (Pläne, Trainings, Einstellungen) neu
  /// planen — gebündelt, damit nicht jeder Satz neu plant.
  void watchForReminders() {
    _sub ??= db
        .tableUpdates(
          TableUpdateQuery.onAllTables([
            db.routines,
            db.workouts,
            db.localSettings,
          ]),
        )
        .listen((_) => scheduleReminders());
  }

  void scheduleReminders() {
    _rescheduleTimer?.cancel();
    _rescheduleTimer = Timer(const Duration(seconds: 3), () {
      reminders.reschedule().catchError((_) {});
    });
  }

  Future<void> dispose() async {
    _rescheduleTimer?.cancel();
    await _sub?.cancel();
    await widgets.dispose();
    await db.close();
  }
}

class AppScope extends InheritedWidget {
  const AppScope({super.key, required this.services, required super.child});

  final AppServices services;

  /// Dienste ändern sich nie — daher ohne Abhängigkeit (auch in
  /// `initState` nutzbar).
  static AppServices of(BuildContext context) =>
      context.getInheritedWidgetOfExactType<AppScope>()!.services;

  @override
  bool updateShouldNotify(AppScope oldWidget) =>
      services != oldWidget.services;
}

extension AppScopeContext on BuildContext {
  AppServices get services => AppScope.of(this);

  /// Sprache für Übungsnamen der Bibliothek (= App-Sprache).
  String get lang => AppLocale.current.languageCode;
}
