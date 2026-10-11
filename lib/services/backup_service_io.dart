import 'dart:io';
import 'dart:isolate';

import 'package:drift/native.dart';
import 'package:mai_backup_format/mai_backup_format.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;

import '../data/app_database.dart';
import '../l10n/l10n.dart';

export 'package:mai_backup_format/mai_backup_format.dart'
    show BackupException, BackupCrypto;

const backupSupported = true;

/// Kennung im Manifest — Sicherungen anderer Mai-Apps werden abgelehnt.
const backupAppId = 'mai_fitness';

/// Verschlüsselte Komplettsicherung der Datenbank (`.maifit`).
///
/// Format wie Mai Doctor Hub: AES-256-GCM, Schlüssel per PBKDF2 aus dem
/// Sicherungspasswort, Inhalt = ZIP mit unverschlüsseltem SQLite-Snapshot
/// und Manifest. Ältere Schemaversionen werden beim Restore migriert.
class BackupService {
  BackupService(
    this._db, {
    Future<Directory> Function()? tempDir,
    this.iterations = BackupCrypto.defaultIterations,
  }) : _tempDir = tempDir ?? getTemporaryDirectory;

  final AppDatabase _db;
  final Future<Directory> Function() _tempDir;

  /// PBKDF2-Runden; in Tests reduziert.
  final int iterations;

  static String suggestedFileName(DateTime now) =>
      'mai-fitness-${now.year}-${_two(now.month)}-${_two(now.day)}.maifit';

  /// Schreibt die verschlüsselte Sicherung in den Temp-Ordner. Aufrufer
  /// teilt die Datei und löscht sie danach.
  Future<File> createBackupFile(String passphrase) async {
    if (passphrase.length < BackupCrypto.minPassphraseLength) {
      throw BackupException(AppLocale.strings.backupPassphraseTooShort);
    }
    final work = await _workDir();
    try {
      final snapshot = p.join(work.path, 'db.sqlite');
      // Konsistente Kopie, auch während die App die DB offen hat.
      await _db.customStatement('VACUUM INTO ?', [snapshot]);
      // Die Kopie trägt den Geräteschlüssel → entschlüsseln; geschützt wird
      // sie danach durch das Sicherungspasswort (geräteunabhängig).
      await _db.customStatement('ATTACH DATABASE ? AS snap', [snapshot]);
      try {
        await _db.customStatement("PRAGMA snap.rekey = ''");
      } finally {
        await _db.customStatement('DETACH DATABASE snap');
      }
      final database = await File(snapshot).readAsBytes();
      final manifest = <String, Object?>{
        'app': backupAppId,
        'format': 1,
        'schemaVersion': _db.schemaVersion,
        'createdAt': DateTime.now().toUtc().toIso8601String(),
      };
      final rounds = iterations;
      final sealed = await Isolate.run(
        () => BackupCrypto.encrypt(
          BackupArchive.build(database: database, manifest: manifest),
          passphrase,
          iterations: rounds,
        ),
      );
      final out = File(
        p.join(
          (await _tempDir()).path,
          'export_${DateTime.now().microsecondsSinceEpoch}.maifit',
        ),
      );
      await out.writeAsBytes(sealed, flush: true);
      return out;
    } finally {
      await work.delete(recursive: true);
    }
  }

  /// Ersetzt **alle** Daten durch den Inhalt der Sicherung unter [path];
  /// liefert den Zeitpunkt der Sicherung.
  Future<DateTime> restoreFile(String path, String passphrase) async {
    final sealed = await File(path).readAsBytes();
    final contents = await Isolate.run(
      () => BackupArchive.open(sealed, passphrase),
    );
    final strings = AppLocale.strings;
    if (contents.app != backupAppId) {
      throw BackupException(strings.backupWrongApp);
    }
    final work = await _workDir();
    try {
      final restorePath = p.join(work.path, 'restore.sqlite');
      await File(restorePath).writeAsBytes(contents.database, flush: true);
      await _migrateSnapshot(restorePath);
      await _replaceData(restorePath);
      return contents.createdAt ?? DateTime.now();
    } finally {
      await work.delete(recursive: true);
    }
  }

  /// Bringt eine ältere Sicherung auf das aktuelle Schema; lehnt neuere ab.
  Future<void> _migrateSnapshot(String path) async {
    final raw = sqlite.sqlite3.open(path);
    final int version;
    try {
      version = raw.userVersion;
    } finally {
      raw.close();
    }
    if (version > _db.schemaVersion) {
      throw BackupException(AppLocale.strings.backupTooNew);
    }
    final snapshot = AppDatabase(NativeDatabase(File(path)));
    try {
      await snapshot.customSelect('SELECT 1').get(); // öffnet + migriert
    } finally {
      await snapshot.close();
    }
  }

  Future<void> _replaceData(String restorePath) async {
    final tables = _db.allTables.toList();
    // KEY '': Sicherungs-DB ist unverschlüsselt (sonst gälte der Geräteschlüssel).
    await _db.customStatement("ATTACH DATABASE ? AS bk KEY ''", [
      restorePath,
    ]);
    try {
      await _db.transaction(() async {
        // Abhängige Tabellen zuerst leeren, Elterntabellen zuerst füllen.
        for (final table in tables.reversed) {
          await _db.customStatement('DELETE FROM "${table.actualTableName}"');
        }
        for (final table in tables) {
          final columns = table.$columns.map((c) => '"${c.name}"').join(', ');
          final name = table.actualTableName;
          await _db.customStatement(
            'INSERT INTO main."$name" ($columns) SELECT $columns FROM bk."$name"',
          );
        }
      });
    } finally {
      await _db.customStatement('DETACH DATABASE bk');
    }
    _db.markTablesUpdated(tables);
  }

  Future<Directory> _workDir() async {
    final dir = Directory(
      p.join(
        (await _tempDir()).path,
        'backup_${DateTime.now().microsecondsSinceEpoch}',
      ),
    );
    return dir.create(recursive: true);
  }

  static String _two(int v) => v.toString().padLeft(2, '0');
}
