# Fitness (mai-fitness)

Trainingsbegleiter für Studio und Zuhause — **lokal, ohne Konto**, auf
Deutsch und Englisch. Gleiche Prinzipien und gleicher Stack wie die anderen
Mai-Apps (Haushalt, Budget, Ärzte).

> Erste Version (v0.1). Konzept und Roadmap: [`project-docs/KONZEPT.md`](project-docs/KONZEPT.md)

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
- **Wear OS:** Begleit-App mit Kachel „Nächstes Training“ (Plan, Tag, Woche,
  Serie) und Komplikation fürs Zifferblatt (Tag, Plan oder Wochenziel als
  Fortschritt). Eigenes APK `mai-fitness-wear.apk`, gleicher Schlüssel wie
  die Telefon-App.
- **Daten:** verschlüsselte Sicherung `.maifit` (Export/Import) und
  Trainingsverlauf als CSV.

## Datenschutz

- Alle Daten nur auf dem Gerät, Datenbank verschlüsselt (SQLite3 Multiple
  Ciphers), Schlüssel im Android Keystore.
- Keine INTERNET-Berechtigung, kein Android-Backup, keine Analytics.
- Uhr: Nur wenn auf einer gekoppelten Uhr die Fitness-Uhr-App installiert
  ist, geht ein knapper Stand (Planname, Tag, Woche, Serie — keine Übungen,
  Gewichte oder Verlauf) über die Wearable-Datenschicht der
  Google-Play-Dienste an die Uhr. Ohne Uhr-App verlässt nichts das Telefon.
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

## Veröffentlichen (Play Store)

Store-Texte, Symbol, Vorstellungsgrafik und Screenshots liegen in
[`store/android/`](store/android/README.md).

Auf `main` baut die CI zusätzlich **signierte App Bundles** (`mai-fitness.aab`
für das Telefon, `mai-fitness-wear.aab` für die Uhr) und lädt sie als Artefakt
`mai-fitness-aab` hoch, sobald die Signatur-Secrets gesetzt sind. Ohne Secrets
läuft alles wie bisher mit Debug-Key. Mit Secrets signiert die CI auf `main`
auch die APKs mit dem Upload-Schlüssel und prüft, dass kein Debug-Key in den
Bundles steckt. Schlüssel und Passwörter liegen nie im Repo: Keystore und
`android/key.properties` entstehen nur im Runner und werden danach gelöscht
(`key.properties`, `*.jks`, `*.keystore` sind in `.gitignore`).

**1. Upload-Schlüssel einmalig erzeugen** (gut aufbewahren, z. B. im
Passwort-Manager; mit Play App Signing verwaltet Google den eigentlichen
App-Schlüssel, der Upload-Schlüssel lässt sich bei Verlust zurücksetzen):

```bash
keytool -genkeypair -v -keystore upload-keystore.jks -storetype JKS \
  -keyalg RSA -keysize 2048 -validity 10000 -alias upload
base64 -w0 upload-keystore.jks > upload-keystore.jks.b64   # macOS: base64 -i upload-keystore.jks
```

**2. GitHub-Secrets anlegen** (Repo → Settings → Secrets and variables →
Actions → New repository secret), gleiche Namen wie in den anderen Mai-Apps:

| Secret | Inhalt |
|---|---|
| `ANDROID_KEYSTORE_BASE64` | Inhalt von `upload-keystore.jks.b64` |
| `ANDROID_KEYSTORE_PASSWORD` | Passwort des Keystores |
| `ANDROID_KEY_ALIAS` | Alias (`upload` im Beispiel) |
| `ANDROID_KEY_PASSWORD` | Passwort des Schlüssels |

Danach die `.b64`-Datei löschen. Der nächste Push auf `main` (oder „Re-run“
des letzten Laufs) liefert die signierten Bundles.

**3. Lokal signiert bauen** (optional): `android/key.properties` anlegen
(nicht einchecken, ist ignoriert):

```properties
storeFile=/absoluter/pfad/zu/upload-keystore.jks
storePassword=…
keyAlias=upload
keyPassword=…
```

```bash
flutter build appbundle --release
(cd android && ./gradlew :wear:bundleRelease)
```

Die Versionsnummer kommt aus `version:` in `pubspec.yaml`; für jedes neue
Bundle in der Play Console die Build-Nummer (`+N`) erhöhen.
