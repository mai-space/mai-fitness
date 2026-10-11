import 'package:flutter/foundation.dart';

export 'connection_stub.dart' if (dart.library.io) 'connection_io.dart';

/// Ergebnis beim Öffnen der App-Datenbank.
class DatabaseOpenStatus {
  const DatabaseOpenStatus({required this.encrypted, this.unreadableCopy});

  final bool encrypted;

  /// Gesetzt, wenn eine vorhandene Datenbank nicht entschlüsselt werden
  /// konnte (z. B. Schlüssel verloren) und beiseitegelegt wurde.
  final String? unreadableCopy;
}

/// Wird gesetzt, sobald die Datenbank geöffnet ist.
final databaseOpenStatus = ValueNotifier<DatabaseOpenStatus?>(null);
