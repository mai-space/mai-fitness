import 'dart:convert';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:mai_fitness/data/repositories/routine_repository.dart';
import 'package:mai_fitness/data/settings.dart';
import 'package:mai_fitness/home_widgets/home_widgets.dart';
import 'package:mai_fitness/home_widgets/widget_snapshot.dart';
import 'package:mai_fitness/l10n/l10n.dart';

import 'helpers.dart';

void main() {
  final l10n = lookupAppLocalizations(const Locale('de'));

  test('ohne Plan: leerer, aber gültiger Stand', () async {
    final db = testDb();
    addTearDown(db.close);
    final snap = await WidgetSnapshot.build(db, l10n, now: DateTime(2026, 3, 2));
    final json = jsonDecode(jsonEncode(snap)) as Map<String, dynamic>;
    expect(json['v'], 1);
    expect(json['next'], isNull);
    expect((json['labels'] as Map)['weekdays'], hasLength(7));
  });

  test('nächstes Training mit Übungen, Tag und „weitere“', () async {
    final db = testDb();
    addTearDown(db.close);
    await Settings(db).set(SettingKeys.trainingDays, '1,3,5');
    await RoutineRepository(db).createFromTemplate('Ganzkörper A', [
      for (final id in [
        'leg_press', 'lat_pulldown', 'chest_press_machine', 'seated_row_machine',
        'shoulder_press_machine', 'leg_extension', 'seated_leg_curl',
        'biceps_curl_machine', 'plank', 'treadmill',
      ])
        PlanEntry(id),
    ]);
    // Dienstag → nächster Trainingstag Mittwoch.
    final snap = await WidgetSnapshot.build(db, l10n, now: DateTime(2026, 3, 3, 9));
    final json = jsonDecode(jsonEncode(snap)) as Map<String, dynamic>;
    final next = json['next'] as Map<String, dynamic>;
    expect(next['name'], 'Ganzkörper A');
    expect(next['day'], '2026-03-04');
    expect(next['exercises'], hasLength(WidgetSnapshot.maxExercises));
    expect(next['more'], 2);
    expect((json['labels'] as Map)['more'], contains('2'));
  });

  test('Widget-Links', () {
    expect(WidgetLink.parse('maifit-widget://start'), WidgetLink.start);
    expect(WidgetLink.parse('maifit-widget://open'), WidgetLink.open);
    expect(WidgetLink.parse('maihh-widget://start'), isNull);
    expect(WidgetLink.parse(null), isNull);
  });
}
