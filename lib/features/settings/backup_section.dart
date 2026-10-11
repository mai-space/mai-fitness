import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../app/services.dart';
import '../../l10n/l10n.dart';
import '../../services/backup_service.dart';
import '../../services/csv_export.dart';
import '../../widgets/common.dart';

/// Einstellungen → Daten: verschlüsselte Sicherung (Export/Import) und
/// Trainingsverlauf als Tabelle.
class BackupSection extends StatefulWidget {
  const BackupSection({super.key});

  @override
  State<BackupSection> createState() => _BackupSectionState();
}

class _BackupSectionState extends State<BackupSection> {
  bool _busy = false;

  Future<void> _run(Future<void> Function() task) async {
    setState(() => _busy = true);
    try {
      await task();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _csv() async {
    final l10n = context.l10n;
    final s = context.services;
    final lang = context.lang;
    await _run(() async {
      try {
        final csv = await CsvExport.build(
          s.db,
          lang,
          header: [
            l10n.csvDate,
            l10n.csvWorkout,
            l10n.csvExercise,
            l10n.csvSet,
            l10n.csvWeight,
            l10n.csvReps,
            l10n.csvSeconds,
          ],
        );
        final dir = await getTemporaryDirectory();
        final now = DateTime.now();
        final file = File(
          p.join(
            dir.path,
            'mai-fitness-${DateFormat('yyyy-MM-dd').format(now)}.csv',
          ),
        );
        // BOM: Excel erkennt so UTF-8 (Umlaute).
        await file.writeAsString('﻿$csv', flush: true);
        try {
          await SharePlus.instance.share(
            ShareParams(
              files: [XFile(file.path, mimeType: 'text/csv')],
              subject: l10n.csvShareSubject,
            ),
          );
        } finally {
          try {
            await file.delete();
          } catch (_) {}
        }
      } catch (e) {
        debugPrint('CSV-Export fehlgeschlagen: $e');
        if (mounted) showSnack(context, l10n.backupFailed);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (!backupSupported) return Text(l10n.backupUnsupported);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.backupIntro),
        const SizedBox(height: 12),
        if (_busy) const LinearProgressIndicator(),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _busy
                    ? null
                    : () => _run(() => createBackup(context)),
                icon: const Icon(Icons.upload_file),
                label: Text(l10n.backupCreate),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _busy
                    ? null
                    : () => _run(() => restoreBackup(context)),
                icon: const Icon(Icons.restore),
                label: Text(l10n.backupRestore),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: _busy ? null : _csv,
          icon: const Icon(Icons.table_chart_outlined),
          label: Text(l10n.csvExport),
        ),
      ],
    );
  }
}

/// Verschlüsselte Sicherung erstellen und teilen.
Future<void> createBackup(BuildContext context) async {
  final l10n = context.l10n;
  final passphrase = await _askPassphrase(context, confirm: true);
  if (passphrase == null || !context.mounted) return;
  final service = BackupService(context.services.db);
  try {
    final file = await service.createBackupFile(passphrase);
    try {
      final result = await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'application/octet-stream')],
          fileNameOverrides: [BackupService.suggestedFileName(DateTime.now())],
          subject: l10n.backupShareSubject,
        ),
      );
      if (result.status != ShareResultStatus.dismissed && context.mounted) {
        showSnack(context, l10n.backupCreated);
      }
    } finally {
      try {
        await file.delete();
      } catch (_) {}
    }
  } on BackupException catch (e) {
    if (context.mounted) showSnack(context, e.message);
  } catch (e) {
    debugPrint('Sicherung fehlgeschlagen: $e');
    if (context.mounted) showSnack(context, l10n.backupFailed);
  }
}

/// Sicherung auswählen und **alle** Daten damit ersetzen.
Future<void> restoreBackup(BuildContext context) async {
  final l10n = context.l10n;
  final files = await FilePicker.pickFiles(dialogTitle: l10n.backupPick);
  if (files.isEmpty || !context.mounted) return;
  final ok = await confirm(
    context,
    title: l10n.backupRestoreConfirmTitle,
    message: l10n.backupRestoreConfirmText,
    confirmLabel: l10n.backupReplace,
    cancelLabel: l10n.commonCancel,
    destructive: true,
  );
  if (!ok || !context.mounted) return;
  final passphrase = await _askPassphrase(context, confirm: false);
  if (passphrase == null || !context.mounted) return;
  final service = BackupService(context.services.db);
  try {
    final (path, staged) = await _localPath(files.first);
    try {
      final createdAt = await service.restoreFile(path, passphrase);
      if (context.mounted) {
        showSnack(
          context,
          l10n.backupRestored(
            DateFormat.yMd(l10n.localeName).add_Hm().format(createdAt.toLocal()),
          ),
        );
      }
    } finally {
      if (staged) {
        try {
          await File(path).delete();
        } catch (_) {}
      }
    }
  } on BackupException catch (e) {
    if (context.mounted) showSnack(context, e.message);
  } catch (e) {
    debugPrint('Wiederherstellung fehlgeschlagen: $e');
    if (context.mounted) showSnack(context, l10n.backupFailed);
  }
}

/// Lokaler Pfad der Auswahl; ohne Pfad (`content://`) wird in den
/// Temp-Ordner kopiert (staged = danach löschen).
Future<(String, bool)> _localPath(PlatformFile file) async {
  final direct = file.path;
  if (direct != null) return (direct, false);
  final target = File(
    p.join(
      (await getTemporaryDirectory()).path,
      'import_${DateTime.now().microsecondsSinceEpoch}.maifit',
    ),
  );
  final sink = target.openWrite();
  try {
    await sink.addStream(file.readAsByteStream());
  } finally {
    await sink.close();
  }
  return (target.path, true);
}

/// Fragt das Sicherungspasswort ab (beim Erstellen doppelt).
Future<String?> _askPassphrase(BuildContext context, {required bool confirm}) {
  return showDialog<String>(
    context: context,
    builder: (_) => _PassphraseDialog(confirm: confirm),
  );
}

class _PassphraseDialog extends StatefulWidget {
  const _PassphraseDialog({required this.confirm});

  final bool confirm;

  @override
  State<_PassphraseDialog> createState() => _PassphraseDialogState();
}

class _PassphraseDialogState extends State<_PassphraseDialog> {
  final _form = GlobalKey<FormState>();
  final _first = TextEditingController();
  final _second = TextEditingController();

  @override
  void dispose() {
    _first.dispose();
    _second.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(widget.confirm ? l10n.backupCreate : l10n.backupRestore),
      content: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.confirm
                  ? l10n.backupPassphraseCreateHint
                  : l10n.backupPassphraseRestoreHint,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _first,
              obscureText: true,
              autofocus: true,
              decoration: InputDecoration(labelText: l10n.backupPassphrase),
              validator: (v) =>
                  (v ?? '').length < BackupCrypto.minPassphraseLength
                  ? l10n.backupPassphraseTooShort
                  : null,
            ),
            if (widget.confirm) ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: _second,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: l10n.backupPassphraseRepeat,
                ),
                validator: (v) =>
                    v != _first.text ? l10n.backupPassphraseMismatch : null,
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(
          onPressed: () {
            if (_form.currentState!.validate()) {
              Navigator.pop(context, _first.text);
            }
          },
          child: Text(l10n.commonContinue),
        ),
      ],
    );
  }
}
