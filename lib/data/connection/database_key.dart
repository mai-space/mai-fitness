import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Liefert den Schlüssel der App-Datenbank.
abstract interface class DatabaseKeyStore {
  /// Hex-Schlüssel; `null` = Plattform ohne Verschlüsselung.
  /// Wirft [DatabaseKeyLost], wenn ein gespeicherter Schlüssel endgültig
  /// nicht mehr entpackt werden kann, und [DatabaseKeyUnavailable] bei
  /// vorübergehenden Fehlern (dann nichts verwerfen).
  Future<String?> getOrCreate();

  /// Legt den gespeicherten Schlüssel beiseite (nur bei unlesbarer
  /// Datenbank); er wird nicht gelöscht.
  Future<void> reset();
}

class DatabaseKeyLost implements Exception {
  const DatabaseKeyLost(this.cause);

  final Object cause;

  @override
  String toString() => 'DatabaseKeyLost: $cause';
}

/// Schlüssel gerade nicht lesbar (I/O, Keystore belegt) — kann beim nächsten
/// Versuch wieder klappen. Datenbank und Schlüssel bleiben unangetastet.
class DatabaseKeyUnavailable implements Exception {
  const DatabaseKeyUnavailable(this.cause);

  final Object cause;

  @override
  String toString() => 'DatabaseKeyUnavailable: $cause';
}

/// Android: Schlüssel im Keystore verpackt, nie im Backup (siehe
/// `DatabaseKeyChannel.kt`). Andere Plattformen: unverschlüsselt (iOS folgt,
/// siehe project-docs/KONZEPT.md).
class PlatformDatabaseKeyStore implements DatabaseKeyStore {
  const PlatformDatabaseKeyStore({@visibleForTesting this.operatingSystem});

  /// Für Tests; sonst `Platform.operatingSystem`.
  final String? operatingSystem;

  static const _channel = MethodChannel('mai/db_key');

  bool get _supported => switch (operatingSystem ?? Platform.operatingSystem) {
    'android' => true,
    _ => false,
  };

  @override
  Future<String?> getOrCreate() async {
    if (!_supported) return null;
    try {
      return await _channel.invokeMethod<String>('getOrCreate');
    } on PlatformException catch (e) {
      // Nur der ausdrückliche Verlust darf zum Beiseitelegen führen.
      if (e.code == 'KEY_LOST') throw DatabaseKeyLost(e);
      throw DatabaseKeyUnavailable(e);
    }
  }

  @override
  Future<void> reset() async {
    if (_supported) await _channel.invokeMethod<void>('reset');
  }
}
