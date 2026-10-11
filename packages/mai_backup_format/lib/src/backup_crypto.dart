import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

/// Fehler beim Ver-/Entschlüsseln — Nachricht ist für die UI gedacht.
class BackupException implements Exception {
  const BackupException(this.message, [this.cause]);

  final String message;
  final Object? cause;

  @override
  String toString() => 'BackupException: $message ($cause)';
}

/// Container-Format `.maibackup`:
///
/// ```
/// "MAIBK" 0x01 | uint32 BE Header-Länge | Header-JSON | Ciphertext | MAC(16)
/// ```
///
/// Header: `{v, kdf: "pbkdf2-sha256", iterations, salt, nonce}` (Base64).
/// Schlüssel: PBKDF2-HMAC-SHA256 aus der Passphrase, Verschlüsselung
/// AES-256-GCM; der Header ist als AAD mitauthentifiziert.
abstract final class BackupCrypto {
  static const _magic = [0x4D, 0x41, 0x49, 0x42, 0x4B, 0x01]; // MAIBK\x01

  /// OWASP-Empfehlung 2023 für PBKDF2-HMAC-SHA256.
  static const defaultIterations = 600000;
  static const minPassphraseLength = 8;

  /// Zulässige PBKDF2-Runden beim Lesen. Der Header ist vor der
  /// Passwortprüfung nicht authentifiziert — ohne Obergrenze ließe eine
  /// präparierte Datei die Schlüsselableitung beliebig lange laufen.
  /// Untergrenze niedrig, weil Tests mit 1000 Runden arbeiten.
  static const minIterations = 1000;
  static const maxIterations = 10000000;

  /// `iterations` aus einem (noch nicht authentifizierten) Header.
  static int iterationsOf(Map<String, dynamic> header) {
    final value = header['iterations'];
    if (value is! int || value < minIterations || value > maxIterations) {
      throw const BackupException('Sicherung ist beschädigt.');
    }
    return value;
  }

  static bool looksLikeBackup(Uint8List data) {
    if (data.length < _magic.length) return false;
    for (var i = 0; i < _magic.length; i++) {
      if (data[i] != _magic[i]) return false;
    }
    return true;
  }

  static Future<Uint8List> encrypt(
    Uint8List plain,
    String passphrase, {
    int iterations = defaultIterations,
  }) async {
    if (passphrase.length < minPassphraseLength) {
      throw const BackupException(
        'Passwort zu kurz (mindestens $minPassphraseLength Zeichen).',
      );
    }
    final algorithm = AesGcm.with256bits();
    final salt = SecretKeyData.random(length: 16).bytes;
    final nonce = algorithm.newNonce();
    final header = utf8.encode(
      jsonEncode({
        'v': 1,
        'kdf': 'pbkdf2-sha256',
        'iterations': iterations,
        'salt': base64Encode(salt),
        'nonce': base64Encode(nonce),
      }),
    );
    final key = await _deriveKey(passphrase, salt, iterations);
    final box = await algorithm.encrypt(
      plain,
      secretKey: key,
      nonce: nonce,
      aad: header,
    );

    final out = BytesBuilder(copy: false)
      ..add(_magic)
      ..add(_uint32(header.length))
      ..add(header)
      ..add(box.cipherText)
      ..add(box.mac.bytes);
    return out.takeBytes();
  }

  static Future<Uint8List> decrypt(Uint8List data, String passphrase) async {
    if (!looksLikeBackup(data) || data.length < _magic.length + 4) {
      throw const BackupException('Keine Mai-Sicherung.');
    }
    final headerLength = ByteData.sublistView(
      data,
      _magic.length,
      _magic.length + 4,
    ).getUint32(0);
    final headerStart = _magic.length + 4;
    final bodyStart = headerStart + headerLength;
    if (bodyStart + 16 > data.length) {
      throw const BackupException('Sicherung ist beschädigt.');
    }
    final headerBytes = data.sublist(headerStart, bodyStart);
    final Map<String, dynamic> header;
    try {
      header = jsonDecode(utf8.decode(headerBytes)) as Map<String, dynamic>;
    } catch (e) {
      throw BackupException('Sicherung ist beschädigt.', e);
    }
    if (header['v'] != 1 || header['kdf'] != 'pbkdf2-sha256') {
      throw const BackupException(
        'Sicherungsformat wird nicht unterstützt — App aktualisieren.',
      );
    }

    final key = await _deriveKey(
      passphrase,
      base64Decode(header['salt'] as String),
      iterationsOf(header),
    );
    final box = SecretBox(
      data.sublist(bodyStart, data.length - 16),
      nonce: base64Decode(header['nonce'] as String),
      mac: Mac(data.sublist(data.length - 16)),
    );
    try {
      final plain = await AesGcm.with256bits().decrypt(
        box,
        secretKey: key,
        aad: headerBytes,
      );
      return Uint8List.fromList(plain);
    } on SecretBoxAuthenticationError catch (e) {
      throw BackupException('Falsches Passwort oder beschädigte Datei.', e);
    }
  }

  static Future<SecretKey> _deriveKey(
    String passphrase,
    List<int> salt,
    int iterations,
  ) {
    return Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: iterations,
      bits: 256,
    ).deriveKeyFromPassword(password: passphrase, nonce: salt);
  }

  static List<int> _uint32(int value) =>
      (ByteData(4)..setUint32(0, value)).buffer.asUint8List();
}
