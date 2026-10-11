import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';

import 'backup_crypto.dart';

/// Inhalt einer entschlüsselten Sicherung.
class BackupContents {
  const BackupContents({
    required this.database,
    required this.manifest,
    required this.files,
  });

  /// SQLite-Datei (`VACUUM INTO`-Snapshot).
  final Uint8List database;
  final Map<String, dynamic> manifest;

  /// Weitere Dateien: Pfad im Archiv → Bytes.
  final Map<String, Uint8List> files;

  int get schemaVersion => manifest['schemaVersion'] as int? ?? 0;

  DateTime? get createdAt =>
      DateTime.tryParse(manifest['createdAt'] as String? ?? '');

  /// Erzeugende App (z. B. `mai_budget_planer`); `null` bei Sicherungen,
  /// die das Feld noch nicht kannten.
  String? get app => manifest['app'] as String?;
}

abstract final class BackupArchive {
  static Uint8List build({
    required Uint8List database,
    required Map<String, Object?> manifest,
    Map<String, Uint8List> files = const {},
  }) {
    final archive = Archive()..add(ArchiveFile.bytes('db.sqlite', database));
    for (final MapEntry(key: name, value: bytes) in files.entries) {
      archive.add(ArchiveFile.bytes(name, bytes));
    }
    archive.add(ArchiveFile.string('manifest.json', jsonEncode(manifest)));
    return ZipEncoder().encodeBytes(archive);
  }

  static BackupContents read(Uint8List zip) {
    final Archive archive;
    try {
      archive = ZipDecoder().decodeBytes(zip);
    } catch (e) {
      throw BackupException('Sicherung ist beschädigt.', e);
    }
    final manifestFile = archive.findFile('manifest.json');
    final dbFile = archive.findFile('db.sqlite');
    if (manifestFile == null || dbFile == null) {
      throw const BackupException('Sicherung ist unvollständig.');
    }
    return BackupContents(
      database: dbFile.content,
      manifest:
          jsonDecode(utf8.decode(manifestFile.content)) as Map<String, dynamic>,
      files: {
        for (final f in archive.files)
          if (f.isFile && f.name != 'db.sqlite' && f.name != 'manifest.json')
            f.name: f.content,
      },
    );
  }

  /// Entschlüsseln + entpacken in einem Schritt.
  static Future<BackupContents> open(Uint8List sealed, String passphrase) async =>
      read(await BackupCrypto.decrypt(sealed, passphrase));
}
