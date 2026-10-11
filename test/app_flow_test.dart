import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mai_fitness/app/services.dart';
import 'package:mai_fitness/data/settings.dart';
import 'package:mai_fitness/main.dart';

import 'helpers.dart';

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Tippt und lässt echte DB-Arbeit laufen (drift arbeitet außerhalb der
/// Fake-Zeit).
Future<void> _tap(WidgetTester tester, Finder f) async {
  await tester.ensureVisible(f);
  await tester.pump();
  await tester.runAsync(() async {
    await tester.tap(f);
    await Future<void>.delayed(const Duration(milliseconds: 300));
  });
  await _settle(tester);
}

/// Echte Zeit für DB-Arbeit, dann Frames.
Future<void> _wait(WidgetTester tester, [int ms = 300]) async {
  await tester.runAsync(() => Future<void>.delayed(Duration(milliseconds: ms)));
  await _settle(tester);
}

void main() {
  testWidgets('Einrichtung → Training → Sätze abhaken → Fertig', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.reset);

    final services = AppServices(testDb());
    await tester.pumpWidget(FitnessApp(services: services));
    await _wait(tester);

    // Einrichtung: drei Schritte.
    expect(find.text('Willkommen!'), findsOneWidget);
    await _tap(tester, find.text('Weiter'));
    expect(find.text('Wo trainierst du?'), findsOneWidget);
    await _tap(tester, find.text('Weiter'));
    expect(find.text('Wann trainierst du?'), findsOneWidget);
    await _tap(tester, find.text('Loslegen'));
    // Zeitzonen laden + Vorlagen anlegen braucht echte Zeit.
    for (var i = 0; i < 20 && find.text('Loslegen').evaluate().isNotEmpty; i++) {
      await _wait(tester, 300);
    }
    await _wait(tester, 600);

    // Heute: nächster Plan aus der Vorlage.
    expect(find.text('Ganzkörper A'), findsOneWidget);
    expect(await services.settings.get(SettingKeys.trainingDays), '1,3,5');
    await _tap(tester, find.text('Training starten'));
    await _wait(tester, 600);

    // Training: erste Übung, erstes Mal → Hinweis.
    expect(find.text('Beinpresse'), findsOneWidget);
    expect(find.textContaining('Erstes Mal'), findsWidgets);
    final weight = find.byType(TextField).first;
    await tester.enterText(weight, '60');
    await _wait(tester);
    await _tap(tester, find.byTooltip('Satz abhaken').first);
    await _wait(tester);
    expect(find.textContaining('Pause'), findsOneWidget);

    await _tap(tester, find.text('Fertig'));
    // Offene Sätze → Rückfrage.
    expect(find.text('Training beenden?'), findsOneWidget);
    await _tap(tester, find.widgetWithText(FilledButton, 'Fertig').last);
    for (var i = 0; i < 20 && find.text('Stark gemacht!').evaluate().isEmpty; i++) {
      await _wait(tester, 300);
    }

    expect(find.text('Stark gemacht!'), findsOneWidget);
    expect(find.text('Der erste Schritt'), findsOneWidget);
    await _tap(tester, find.text('Fertig'));
    await _wait(tester, 600);

    // Zurück auf Heute: nächster Plan ist B (reihum), Woche 1 Training.
    expect(find.text('Ganzkörper B'), findsOneWidget);
    expect(find.text('Letzte Trainings'), findsOneWidget);

    // Fortschritt und Übungen öffnen sich.
    await _tap(tester, find.text('Fortschritt'));
    await _wait(tester, 600);
    expect(find.text('Deine Übungen'), findsOneWidget);
    await _tap(tester, find.text('Übungen').last);
    await _wait(tester);
    await tester.enterText(find.byType(TextField).first, 'Latzug');
    await _settle(tester);
    await _tap(tester, find.text('Latzug').last);
    await _wait(tester);
    expect(find.text('Häufige Fehler'), findsOneWidget);

    await tester.runAsync(services.dispose);
  });
}
