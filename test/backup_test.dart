import 'dart:io';
import 'dart:typed_data';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:mai_backup_format/mai_backup_format.dart';
import 'package:mai_fitness/data/app_database.dart';
import 'package:mai_fitness/data/repositories/routine_repository.dart';
import 'package:mai_fitness/data/repositories/workout_repository.dart';
import 'package:mai_fitness/data/settings.dart';
import 'package:mai_fitness/services/backup_service.dart';
import 'package:sqlite3/sqlite3.dart';

import 'helpers.dart';

void main() {
  late Directory tmp;
  late AppDatabase db;
  late BackupService service;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('backup_');
    db = testDb();
    service = BackupService(db, tempDir: () async => tmp, iterations: 1000);
  });
  tearDown(() async {
    await db.close();
    await tmp.delete(recursive: true);
  });

  /// Erfundene Beispieldaten: ein Plan, ein Training mit Beinpresse.
  Future<void> seed() async {
    final routines = RoutineRepository(db);
    final workouts = WorkoutRepository(db);
    final id = await routines.save(
      name: 'Ganzkörper A',
      entries: const [PlanEntry('leg_press')],
    );
    final w = await workouts.start(routineId: id, name: 'Ganzkörper A');
    final view = (await workouts.session(w))!;
    for (final s in view.exercises.single.sets) {
      await workouts.updateSet(s.id, weightKg: const Value(80), reps: const Value(10));
      await workouts.setDone(s.id, true);
    }
    await workouts.finish(w);
    await Settings(db).set(SettingKeys.trainingDays, '1,4');
  }

  test('Sicherung → alles ändern → Wiederherstellen bringt Daten zurück', () async {
    await seed();
    final file = await service.createBackupFile('geheim123');
    expect(file.path, endsWith('.maifit'));
    final bytes = await file.readAsBytes();
    expect(String.fromCharCodes(bytes), isNot(contains('Ganzk')));
    expect(BackupCrypto.looksLikeBackup(bytes), isTrue);

    final routines = RoutineRepository(db);
    await routines.archive((await routines.routines()).single.id);
    await Settings(db).set(SettingKeys.trainingDays, '2');

    await service.restoreFile(file.path, 'geheim123');
    expect((await routines.routines()).single.name, 'Ganzkörper A');
    expect(await Settings(db).get(SettingKeys.trainingDays), '1,4');
    final history = await WorkoutRepository(db).history('leg_press');
    expect(history.single.sets.first.weightKg, 80);
    expect(tmp.listSync().whereType<Directory>(), isEmpty);
  });

  test('falsches Passwort lässt Daten unverändert', () async {
    await seed();
    final file = await service.createBackupFile('geheim123');
    await RoutineRepository(db).save(name: 'B', entries: const []);
    await expectLater(
      service.restoreFile(file.path, 'falsch!!!'),
      throwsA(isA<BackupException>()),
    );
    expect(await RoutineRepository(db).routines(), hasLength(2));
  });

  test('zu kurze Passwörter werden abgelehnt', () async {
    await expectLater(
      service.createBackupFile('kurz'),
      throwsA(isA<BackupException>()),
    );
  });

  test('Sicherungen anderer Mai-Apps werden abgelehnt', () async {
    final foreign = File('${tmp.path}/budget.maibudget');
    await foreign.writeAsBytes(
      await BackupCrypto.encrypt(
        BackupArchive.build(
          database: Uint8List(0),
          manifest: {'app': 'mai_budget_planer', 'schemaVersion': 1},
        ),
        'geheim123',
        iterations: 1000,
      ),
    );
    await expectLater(
      service.restoreFile(foreign.path, 'geheim123'),
      throwsA(
        isA<BackupException>().having(
          (e) => e.message,
          'message',
          contains('keine Sicherung der Fitness-App'),
        ),
      ),
    );
  });

  test('Sicherungen aus neuerem Schema werden abgelehnt', () async {
    await seed();
    final snapshot = '${tmp.path}/newer.sqlite';
    await db.customStatement('VACUUM INTO ?', [snapshot]);
    sqlite3.open(snapshot)
      ..execute('PRAGMA user_version = 99')
      ..close();
    final file = File('${tmp.path}/newer.maifit');
    await file.writeAsBytes(
      await BackupCrypto.encrypt(
        BackupArchive.build(
          database: await File(snapshot).readAsBytes(),
          manifest: {'app': backupAppId, 'schemaVersion': 99},
        ),
        'geheim123',
        iterations: 1000,
      ),
    );
    await expectLater(
      service.restoreFile(file.path, 'geheim123'),
      throwsA(isA<BackupException>()),
    );
  });
}
