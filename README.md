# Fitness (mai-fitness)

Trainingsbegleiter für Studio und Zuhause — **lokal, ohne Konto**, auf
Deutsch und Englisch. Gleiche Prinzipien und gleicher Stack wie die anderen
Mai-Apps (Haushalt, Budget, Ärzte).

> Erste Version (v0.1). Konzept und Roadmap: [`docs/KONZEPT.md`](docs/KONZEPT.md)

## Features

- **Übungsbibliothek:** 63 Übungen mit Anleitung (Einstellung am Gerät,
  Ablauf, Tipps, typische Fehler, leichtere/schwerere Variante) — gängige
  Studio-Geräte, Kabelzug, freie Gewichte, Übungen ohne Geräte, Cardio.
  Eigene Übungen möglich.
- **Pläne:** Einsteigerpläne (Studio, Zuhause, beides) im Wechsel A/B,
  frei anpassbar (Sätze, Wiederholungsbereich, Pause, Reihenfolge).
- **Training:** Sätze mit Gewicht/Wiederholungen/Zeit abhaken,
  Pausen-Timer, Halte-Timer, Übung tauschen oder ergänzen.
- **Automatische Steigerung:** doppelte Progression — erst mehr
  Wiederholungen, dann mehr Gewicht; ohne Geräte die schwerere Variante;
  nach Rückschlägen leichter (Deload).
- **Fortschritt:** Wochenziel und Serie, Bestwerte, Verlauf je Übung mit
  Prognose (vorsichtig gedämpfter Trend), Trainingsverlauf.
- **Erfolge:** 30 Abzeichen (Trainings, Wochen-Serien, Volumen, Bestwerte,
  Liegestütze, Unterarmstütz, Vielfalt, Cardio, Comeback …).
- **Erinnerungen:** lokale Benachrichtigung an Trainingstagen zur
  gewählten Uhrzeit (entfällt, wenn schon trainiert).
- **Widget „Nächstes Training“:** frei skalierbar — von 1×1 (Plan und Tag)
  bis zur Übungsliste mit Zielgewichten und Start-Knopf.
- **Daten:** verschlüsselte Sicherung `.maifit` (Export/Import) und
  Trainingsverlauf als CSV.

## Datenschutz

- Alle Daten nur auf dem Gerät, Datenbank verschlüsselt (SQLite3 Multiple
  Ciphers), Schlüssel im Android Keystore.
- Keine INTERNET-Berechtigung, kein Android-Backup, keine Analytics.
- Weitergabe nur über die vom Nutzer erstellte, passwortgeschützte Sicherung
  (AES-256-GCM / PBKDF2, `packages/mai_backup_format`).

## Entwicklung

```bash
flutter pub get
flutter analyze
flutter test
(cd packages/mai_backup_format && dart test)

# nach Schema-Änderungen
dart run build_runner build --delete-conflicting-outputs
UPDATE_SCHEMA=1 flutter test test/schema_contract_test.dart

# nach Text-Änderungen
python3 tool/merge_arb.py && flutter gen-l10n

# App-Icon neu erzeugen
pip install cairosvg pillow && python3 tool/generate_icons.py

flutter run -d android
flutter build apk --release
```

Die CI baut bei jedem Push die Release-APK und lädt sie als
`mai-fitness.apk` hoch.
