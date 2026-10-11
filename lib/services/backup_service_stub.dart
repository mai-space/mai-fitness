import 'dart:io' show Directory, File;

import 'package:mai_backup_format/mai_backup_format.dart';

import '../data/app_database.dart';

export 'package:mai_backup_format/mai_backup_format.dart'
    show BackupException, BackupCrypto;

/// Kennung im Manifest — Sicherungen anderer Mai-Apps werden abgelehnt.
const backupAppId = 'mai_fitness';

/// Web: keine Sicherung (nur UI-Debug).
const backupSupported = false;

class BackupService {
  BackupService(
    AppDatabase db, {
    Future<Directory> Function()? tempDir,
    int iterations = BackupCrypto.defaultIterations,
  });

  static String suggestedFileName(DateTime now) => 'mai-fitness.maifit';

  Future<File> createBackupFile(String passphrase) =>
      throw const BackupException('Sicherung ist im Web nicht verfügbar.');

  Future<DateTime> restoreFile(String path, String passphrase) =>
      throw const BackupException('Sicherung ist im Web nicht verfügbar.');
}
