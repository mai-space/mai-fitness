# Fitness — Konzept

## Ziel

Ein Trainingsbegleiter für normale Leute: im Studio oder zu Hause, ohne
Vorwissen. Die App sagt, was heute dran ist, wie die Übung geht und mit
welchem Gewicht bzw. wie vielen Wiederholungen — und steigert das von selbst.
Erfolge und Erinnerungen helfen, dranzubleiben.

## Grundsätze

- **Lokal, ohne Konto.** Keine Cloud, keine INTERNET-Berechtigung.
- **Verschlüsselt.** Datenbank mit SQLite3 Multiple Ciphers; der Schlüssel
  liegt verpackt im Android Keystore und verlässt das Gerät nie (auch nicht
  über Google-Backups). iOS folgt später (Schlüssel im Keychain).
- **Einfacher Export/Import.** Passwortgeschützte Sicherung `.maifit`
  (gleiches Containerformat wie die anderen Mai-Apps) und CSV des Verlaufs.
- **Deutsch zuerst**, Englisch nach Systemsprache.

## Steigerung (doppelte Progression)

Jede Übung im Plan hat Sätze und einen Wiederholungsbereich (z. B. 3 × 8–12).

1. Alle Sätze am oberen Ende geschafft → nächstes Mal mehr Gewicht
   (Schritt je Gerät: Kurzhantel 2 kg, Beinmaschinen/Langhantel 5 kg,
   sonst 2,5 kg), Wiederholungen zurück an den Anfang des Bereichs.
2. Im Bereich → nächstes Mal eine Wiederholung mehr.
3. Zweimal in Folge unter dem Bereich → leichter (Deload, ca. −10 %).
4. Ohne Gewicht: mehr Wiederholungen, am oberen Ende die schwerere Variante
   (z. B. Knie-Liegestütz → Liegestütz); Halteübungen +10 % (mind. 5 s),
   Cardio +1 min.

## Fortschritt und Prognose

- Leistung je Übung: geschätztes 1RM (Epley), sonst Wiederholungen bzw. Zeit.
- Prognose: lineare Regression über die letzten Werte (mind. 3 Punkte über
  mind. 7 Tage, höchstens 120 Tage zurück), gedämpft und auf 3 % pro Woche
  begrenzt — lieber vorsichtig als zu optimistisch.
- Wochenziel (Standard: Zahl der Trainingstage), Serie in Wochen, Bestwerte.

## Widget

„Nächstes Training“, frei skalierbar: 1×1 Plan und Tag, breit mit
Start-Knopf, ab 2×2 die Übungen mit Zielen (↑ = Steigerung). „Heute/Morgen“
berechnet das Widget selbst, damit es nach Mitternacht stimmt.

## Roadmap

- Körperwerte (Gewicht, Umfang) mit Verlauf
- Mehr Übungen, Bilder/Animationen zu den Anleitungen
- Supersätze, Aufwärmsätze
- iOS
