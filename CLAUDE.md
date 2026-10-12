# Fitness (mai-fitness) — Hinweise für Änderungen

Lokaler, verschlüsselter Trainingsbegleiter (Flutter, Android). Gleiche
Prinzipien und gleicher Stack wie die anderen Mai-Apps. Angezeigter Name
„Fitness“ (ohne „Mai“), Paket `space.mai.mai_fitness`, CI-Artefakt
`mai-fitness.apk`. UI Deutsch/Englisch nach Systemsprache.
Konzept: `project-docs/KONZEPT.md`.

## Datenschutz (Pflicht)

- Keine echten Trainings- oder Körperdaten ins Repo (Sicherungen, Exporte,
  Screenshots). `.gitignore` blockt `*.maifit`, `*.csv` — nicht aufweichen.
- Keine INTERNET-Berechtigung im Manifest, kein Android-Backup
  (`allowBackup=false`, `data_extraction_rules.xml`), keine Analytics.

## Rückwärtskompatibilität (ab dem ersten verteilten Build Pflicht)

- **Datenbank (drift, `lib/data/app_database.dart`)**
  - Nur additive Migrationen: neue Tabellen, neue Spalten *nullable oder mit
    Default*. Niemals Spalten/Tabellen löschen, umbenennen oder Typ ändern.
  - Jede Änderung: `schemaVersion` +1 und ein eigener Block `if (from < n)`
    in `onUpgrade` (strikt aufsteigend, alte Blöcke nie ändern).
  - Vor der Änderung das alte Schema als `test/migrations/v<alt>.sql`
    sichern (= `test/schema/current.sql`) und einen Migrationstest
    `v<alt> → v<neu>` mit Bestandsdaten ergänzen.
  - Enums (`intEnum`: `Equipment`, `Tracking`, `Muscle`) nur am Ende
    erweitern — gespeichert wird der Index.
  - IDs der eingebauten Übungen (`lib/domain/exercises/catalog_data.dart`)
    und Erfolge (`achievements.dart`) nie ändern — Verlauf und Erfolge
    hängen daran. Neue nur ergänzen.
  - Danach: `dart run build_runner build --delete-conflicting-outputs` und
    `UPDATE_SCHEMA=1 flutter test test/schema_contract_test.dart`.
- **Sicherungen (`packages/mai_backup_format`, `backup_service_io.dart`)** —
  ältere Sicherungen müssen wiederherstellbar bleiben (Restore migriert).
  Manifest nur erweitern; `app` bleibt `mai_fitness`.
- **Widget-Stand (`lib/home_widgets/widget_snapshot.dart`)** — JSON nur
  erweitern (`v` bleibt 1); die native Seite ignoriert Unbekanntes.
- **Einstellungen** — gespeicherte Werte tolerant lesen.

## Arbeitsweise

- Rechenlogik (Steigerung, Statistik, Prognose, Erfolge, Plan) ist reines
  Dart in `lib/domain/` und vollständig getestet — neue Regeln immer mit Test.
- Strings: `lib/l10n/parts/<bereich>.<de|en>.json` (neue Schlüssel anhängen),
  dann `python3 tool/merge_arb.py && flutter gen-l10n`.
- Prüfen vor jedem Commit: `flutter analyze` (sauber) und `flutter test`
  (komplett grün); bei Änderungen an `packages/mai_backup_format` dort
  `dart analyze --fatal-infos && dart test`.
- Kein `dart format` auf ganze bestehende Dateien (erzeugt fremde Diffs).
- Release-Builds laufen mit R8: neue native Bibliotheken ggf. in
  `android/app/proguard-rules.pro` (anlegen und in `build.gradle.kts`
  eintragen) absichern.
- Kommentare im Code auf Deutsch.
