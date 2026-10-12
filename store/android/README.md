# Play Store: Fitness (Android)

Alles zum Herauskopieren in die Play Console (Store-Präsenz →
Haupteintrag im Play Store). Deutsch ist `de-DE`, Englisch `en-US`
(in der Play Console als Übersetzung hinzufügen).

| Datei | Feld in der Play Console | Vorgabe |
|---|---|---|
| `de-DE/title.txt`, `en-US/title.txt` | App-Name | max. 30 Zeichen (28 / 25) |
| `de-DE/short_description.txt`, `en-US/…` | Kurzbeschreibung | max. 80 Zeichen (74 / 77) |
| `de-DE/full_description.txt`, `en-US/…` | Vollständige Beschreibung | max. 4000 Zeichen (≈ 2250 / 2050) |
| `icon_512.png` | App-Symbol | 512 × 512 PNG, für beide Sprachen |
| `de-DE/feature_graphic.png`, `en-US/…` | Vorstellungsgrafik | 1024 × 500 PNG |
| `de-DE/phone_0*.png`, `en-US/…` | Screenshots → Smartphone | 8 Stück, 1080 × 1920 PNG |

Reihenfolge der Screenshots = Dateiname (01 Heute, 02 Training läuft,
03 Anleitung, 04 Verlauf mit Prognose, 05 Fortschritt, 06 Einrichtung mit
Datenschutz-Punkten, 07 Erfolge, 08 Übungsbibliothek).

Datenschutzerklärung und Datensicherheit stehen nicht hier, sondern im
Projektordner `play-store/fitness/` (`play-console.md`); URL:
`https://mai-space.github.io/mai-fitness/datenschutz/`.

## Hinweise

- **Wear OS:** Die Beschreibung erwähnt Kachel und Komplikation. Lädst du die
  Uhr-App (`mai-fitness-wear.apk`) nicht mit hoch, die Zeile „Wear OS: …“
  unter „Dranbleiben“ bzw. „Keep going“ streichen.
- **Keine Heilversprechen:** Die Texte beschreiben nur, was die App tut
  (Plan, Anleitung, Steigerung, Verlauf), und enthalten den Hinweis, dass sie
  keine Beratung ersetzt.

## Wie die Bilder entstehen

Keine echten Daten: Die Screenshots sind die echten Bildschirme der App,
gerendert in einem Flutter-Widget-Test mit einer frisch angelegten
In-Memory-Datenbank. Darin trainiert eine erfundene Beispielperson acht
Wochen lang den Einsteigerplan „Studio“; Gewichte und Wiederholungen kommen
aus der echten Steigerungslogik der App. Schrift ist Roboto wie auf Android;
Statusleiste und Systemleisten fehlen (für Play erlaubt).

Neu erzeugen (z. B. nach UI-Änderungen):

```bash
STORE_SCREENSHOTS=1 flutter test test/store/store_screenshots_test.dart
python3 tool/generate_icons.py   # icon_512.png (pip install cairosvg pillow)
```

Ohne `STORE_SCREENSHOTS=1` wird der Test übersprungen (normaler Testlauf
und CI bleiben unberührt). Datumsangaben in den Bildern richten sich nach
dem Tag der Erzeugung.
