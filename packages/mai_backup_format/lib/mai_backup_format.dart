/// Verschlüsseltes Sicherungsformat der Mai-Apps: AES-256-GCM-verschlüsseltes
/// ZIP mit SQLite-Snapshot und Manifest (Container „MAIBK“ v1).
///
/// Übernommen aus Mai Doctor Hub (`packages/mai_backup_format`); das
/// Container-Format ist identisch, das Manifest trägt zusätzlich `app`.
library;

export 'src/backup_archive.dart';
export 'src/backup_crypto.dart';
