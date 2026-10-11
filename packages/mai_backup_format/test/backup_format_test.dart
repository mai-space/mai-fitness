import 'dart:typed_data';

import 'package:mai_backup_format/mai_backup_format.dart';
import 'package:test/test.dart';

void main() {
  test('build → encrypt → open round-trip', () async {
    final zip = BackupArchive.build(
      database: Uint8List.fromList([1, 2, 3]),
      manifest: {
        'app': 'mai_budget_planer',
        'schemaVersion': 2,
        'createdAt': '2026-10-05T10:00:00.000Z',
      },
      files: {'extra/a.txt': Uint8List.fromList([9, 9])},
    );
    final sealed = await BackupCrypto.encrypt(zip, 'passwort!', iterations: 1000);
    final contents = await BackupArchive.open(sealed, 'passwort!');
    expect(contents.database, [1, 2, 3]);
    expect(contents.app, 'mai_budget_planer');
    expect(contents.schemaVersion, 2);
    expect(contents.createdAt, DateTime.utc(2026, 10, 5, 10));
    expect(contents.files['extra/a.txt'], [9, 9]);
  });

  test('wrong passphrase fails with a BackupException', () async {
    final sealed = await BackupCrypto.encrypt(
      Uint8List.fromList([1, 2, 3]),
      'richtiges-passwort',
      iterations: 1000,
    );
    expect(
      () => BackupCrypto.decrypt(sealed, 'falsches-passwort'),
      throwsA(isA<BackupException>()),
    );
  });

  test('rejects short passphrases', () {
    expect(
      () => BackupCrypto.encrypt(Uint8List(1), 'kurz', iterations: 1000),
      throwsA(isA<BackupException>()),
    );
  });

  test('rejects garbage and incomplete archives', () async {
    expect(
      () => BackupArchive.read(Uint8List.fromList([0, 1, 2])),
      throwsA(isA<BackupException>()),
    );
    final sealed = await BackupCrypto.encrypt(
      Uint8List.fromList([0, 1, 2]),
      'passwort!',
      iterations: 1000,
    );
    expect(
      () => BackupArchive.open(sealed, 'passwort!'),
      throwsA(isA<BackupException>()),
    );
  });
}
