import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:mai_fitness/data/app_database.dart';

/// Frische In-Memory-Datenbank.
AppDatabase testDb() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  return AppDatabase(NativeDatabase.memory());
}
