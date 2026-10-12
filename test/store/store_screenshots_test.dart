// Erzeugt die Screenshots und die Vorstellungsgrafik für den Play Store
// (`store/android/`). Läuft nur auf Wunsch, nicht im normalen Testlauf:
//
//   STORE_SCREENSHOTS=1 flutter test test/store/store_screenshots_test.dart
//
// Alle Daten sind frei erfunden (Beispieltrainings in einer
// In-Memory-Datenbank) — keine echten Trainings- oder Körperdaten.
@TestOn('vm')
library;

import 'dart:io';
import 'dart:ui' as ui;

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mai_fitness/app/services.dart';
import 'package:mai_fitness/data/settings.dart';
import 'package:mai_fitness/data/starter_plans.dart';
import 'package:mai_fitness/domain/exercises/catalog.dart';
import 'package:mai_fitness/domain/exercises/exercise.dart';
import 'package:mai_fitness/features/exercises/exercise_detail_page.dart';
import 'package:mai_fitness/features/progress/achievements_page.dart';
import 'package:mai_fitness/features/workout/workout_page.dart';
import 'package:mai_fitness/l10n/l10n.dart';
import 'package:mai_fitness/main.dart';
import 'package:mai_fitness/theme/app_theme.dart';

import '../helpers.dart';

final _enabled = Platform.environment['STORE_SCREENSHOTS'] == '1';

/// 1080 × 1920 Pixel (9:16), typische Telefon-Dichte.
const _size = Size(1080, 1920);
const _dpr = 2.625;

/// Startgewichte der Beispielperson (kg) beim ersten Training.
const _startKg = {
  'leg_press': 60.0,
  'chest_press_machine': 25.0,
  'lat_pulldown': 30.0,
  'shoulder_press_machine': 15.0,
  'seated_leg_curl': 20.0,
  'leg_extension': 25.0,
  'seated_row_machine': 30.0,
  'pec_deck': 20.0,
  'lateral_raise_machine': 10.0,
  'back_extension': 0.0,
  'ab_crunch_machine': 15.0,
};

void main() {
  for (final (locale, folder) in [
    (AppLocale.german, 'de-DE'),
    (AppLocale.english, 'en-US'),
  ]) {
    testWidgets('Store-Screenshots $folder', (tester) async {
      await _loadFonts();
      _setLocale(tester, locale);
      addTearDown(() => _setLocale(tester, AppLocale.german));
      tester.view.physicalSize = _size;
      tester.view.devicePixelRatio = _dpr;
      addTearDown(tester.view.reset);
      final out = Directory('store/android/$folder');
      out.createSync(recursive: true);
      await _shoot(tester, out, locale.languageCode);
    }, skip: !_enabled);

    testWidgets('Vorstellungsgrafik $folder', (tester) async {
      await _loadFonts();
      addTearDown(tester.view.reset);
      final out = Directory('store/android/$folder')..createSync(recursive: true);
      await _featureGraphic(tester, out, locale.languageCode);
    }, skip: !_enabled);
  }
}

final _boundary = GlobalKey();

Future<void> _shoot(WidgetTester tester, Directory out, String lang) async {
  Future<void> capture(String name) async {
    await _wait(tester, 400);
    final render =
        _boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    await tester.runAsync(() async {
      final image = await render.toImage(pixelRatio: _dpr);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      File('${out.path}/$name.png').writeAsBytesSync(bytes!.buffer.asUint8List());
    });
  }

  // Echte Schatten (Tests zeichnen sonst schwarze Umrisse); vor Testende
  // zurücksetzen (Invarianten-Prüfung).
  debugDisableShadows = false;
  try {
    await _screens(tester, capture, lang);
  } finally {
    debugDisableShadows = true;
  }
}

Future<void> _screens(
  WidgetTester tester,
  Future<void> Function(String name) capture,
  String lang,
) async {
  // Beispielperson mit acht Wochen Verlauf; zuerst noch die Einrichtung
  // (Datenschutz-Punkte), danach wechselt die App von selbst zu „Heute“.
  final s = AppServices(testDb());
  await _db(tester, () => _seed(s, lang));
  await tester.pumpWidget(
    RepaintBoundary(key: _boundary, child: FitnessApp(services: s)),
  );
  await _wait(tester);
  await capture('phone_06_welcome');
  await _db(tester, () => s.settings.setFlag(SettingKeys.onboarded, true));
  await _wait(tester, 800);
  await capture('phone_01_today');

  final nav = appNavigatorKey.currentState!;

  // Laufendes Training mit ersten erledigten Sätzen.
  final workoutId = await _db(tester, () => _startToday(s));
  nav.push(MaterialPageRoute<void>(
    builder: (_) => WorkoutPage(workoutId: workoutId),
  ));
  await _wait(tester, 800);
  await capture('phone_02_workout');
  nav.pop();
  await _wait(tester);

  // Übung mit Verlauf und Prognose.
  nav.push(MaterialPageRoute<void>(
    builder: (_) => const ExerciseDetailPage(exerciseId: 'leg_press'),
  ));
  await _wait(tester, 800);
  await capture('phone_03_guide');
  // Weiter unten: typische Fehler und Verlauf mit Prognose.
  final mistakes = find.text(lang == 'de' ? 'Häufige Fehler' : 'Common mistakes');
  await tester.runAsync(
    () => Scrollable.ensureVisible(tester.element(mistakes), alignment: 0.02),
  );
  await _wait(tester);
  await capture('phone_04_exercise_progress');
  nav.pop();
  await _wait(tester);

  // Reiter „Fortschritt“.
  await tester.tap(find.byType(NavigationDestination).at(2));
  await _wait(tester, 800);
  await capture('phone_05_progress');

  nav.push(MaterialPageRoute<void>(builder: (_) => const AchievementsPage()));
  await _wait(tester, 800);
  await capture('phone_07_achievements');
  nav.pop();
  await _wait(tester);

  // Reiter „Übungen“ (Bibliothek).
  await tester.tap(find.byType(NavigationDestination).at(3));
  await _wait(tester, 600);
  await capture('phone_08_library');

  await tester.runAsync(s.dispose);
}

/// Vorstellungsgrafik 1024 × 500.
Future<void> _featureGraphic(WidgetTester tester, Directory out, String lang)
    async {
  tester.view.physicalSize = const Size(1024, 500);
  tester.view.devicePixelRatio = 1;
  final key = GlobalKey();
  await tester.pumpWidget(
    RepaintBoundary(key: key, child: _FeatureGraphic(lang: lang)),
  );
  await tester.pump();
  final render = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  await tester.runAsync(() async {
    final image = await render.toImage();
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    File('${out.path}/feature_graphic.png')
        .writeAsBytesSync(bytes!.buffer.asUint8List());
  });
}

/// Acht Wochen Training Mo/Mi/Fr (mit ein paar Lücken), jeweils mit den
/// Vorschlägen der App — so entsteht die echte automatische Steigerung.
Future<void> _seed(AppServices s, String lang) async {
  for (final plan in StarterPlans.forPlace(TrainingPlace.gym)) {
    await s.routines.createFromTemplate(plan.name.of(lang), plan.entries);
  }
  await s.settings.set(SettingKeys.trainingDays, '1,3,5');
  final routines = await s.routines.routines();

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  var day = today.subtract(const Duration(days: 56));
  var n = 0;
  while (day.isBefore(today)) {
    final skip = n == 4 || n == 13; // zweimal ausgefallen
    if ({1, 3, 5}.contains(day.weekday)) {
      if (!skip) {
        final routine = routines[n % routines.length];
        final at = day.add(const Duration(hours: 18));
        final id = await s.workouts.start(
          routineId: routine.id,
          name: routine.name,
          now: at,
        );
        await _doAllSets(s, id, at);
        await s.workouts.finish(
          id,
          now: at.add(const Duration(minutes: 52)),
        );
        await s.progress.unlockNew(now: at);
      }
      n++;
    }
    day = day.add(const Duration(days: 1));
  }
  await s.progress.markSeen();
}

/// Alle Sätze mit den vorgeschlagenen Werten erledigen; beim ersten Mal
/// das Startgewicht eintragen.
Future<void> _doAllSets(AppServices s, String id, DateTime at) async {
  final view = (await s.workouts.session(id))!;
  for (final e in view.exercises) {
    final tracking = Catalog.byId(e.exerciseId)?.tracking;
    for (final set in e.sets) {
      if (tracking == Tracking.weightReps && set.weightKg == null) {
        await s.workouts.updateSet(
          set.id,
          weightKg: Value(_startKg[e.exerciseId] ?? 20),
        );
      }
      await s.workouts.setDone(set.id, true, at: at);
    }
  }
}

/// Heutiges Training: erste Übung mit zwei erledigten Sätzen.
Future<String> _startToday(AppServices s) async {
  final routines = await s.routines.routines();
  final history = await s.workouts.watchHistory(limit: 1).first;
  final last = history.first.workout.routineId;
  final next = routines.firstWhere((r) => r.id != last);
  final id = await s.workouts.start(routineId: next.id, name: next.name);
  final view = (await s.workouts.session(id))!;
  for (final set in view.exercises.first.sets.take(2)) {
    await s.workouts.setDone(set.id, true);
  }
  return id;
}

/// Datenbankarbeit in der Test-Zone: drift arbeitet hier synchron, braucht
/// aber Frames (Microtasks/Timer), damit Abfragen der App nicht blockieren.
Future<T> _db<T>(WidgetTester tester, Future<T> Function() work) async {
  late T result;
  Object? error;
  var done = false;
  work().then(
    (v) {
      result = v;
      done = true;
    },
    onError: (Object e) {
      error = e;
      done = true;
    },
  );
  while (!done) {
    await tester.pump(const Duration(milliseconds: 20));
  }
  if (error != null) throw error!;
  return result;
}

void _setLocale(WidgetTester tester, Locale locale) {
  final full = locale == AppLocale.german
      ? const Locale('de', 'DE')
      : const Locale('en', 'US');
  tester.platformDispatcher.localesTestValue = [full];
  tester.platformDispatcher.localeTestValue = full;
  AppLocale.update(locale);
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Echte Zeit für DB-Arbeit, dann Frames.
Future<void> _wait(WidgetTester tester, [int ms = 300]) async {
  await tester.runAsync(() => Future<void>.delayed(Duration(milliseconds: ms)));
  await _settle(tester);
}

/// Echte Schriften statt der Test-Schrift (Roboto und Material-Icons aus
/// dem Flutter-SDK).
Future<void> _loadFonts() async {
  final root =
      Platform.environment['FLUTTER_ROOT'] ??
      File(Platform.resolvedExecutable).parent.parent.parent.parent.parent
          .parent.parent.path;
  final fonts = Directory('$root/bin/cache/artifacts/material_fonts');
  Future<void> load(String family, List<String> files) async {
    final loader = FontLoader(family);
    for (final f in files) {
      final bytes = File('${fonts.path}/$f').readAsBytesSync();
      loader.addFont(Future.value(ByteData.sublistView(bytes)));
    }
    await loader.load();
  }

  await load('Roboto', [
    'Roboto-Regular.ttf',
    'Roboto-Medium.ttf',
    'Roboto-Bold.ttf',
    'Roboto-Light.ttf',
  ]);
  await load('MaterialIcons', ['MaterialIcons-Regular.otf']);
}

/// Vorstellungsgrafik: Markenverlauf, Hantel, Name und Kernaussage.
class _FeatureGraphic extends StatelessWidget {
  const _FeatureGraphic({required this.lang});

  final String lang;

  @override
  Widget build(BuildContext context) {
    final de = lang == 'de';
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFEE8A4F), AppColors.seed],
          ),
        ),
        padding: const EdgeInsets.only(left: 48, right: 64),
        child: Row(
          children: [
            const CustomPaint(
              size: Size.square(300),
              painter: _DumbbellPainter(),
            ),
            const SizedBox(width: 32),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Fitness',
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontWeight: FontWeight.bold,
                      fontSize: 84,
                      color: Colors.white,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    de
                        ? 'Plan, Anleitung und automatische Steigerung.'
                        : 'Plans, how-tos and automatic progression.',
                    style: const TextStyle(
                      fontFamily: 'Roboto',
                      fontWeight: FontWeight.w500,
                      fontSize: 34,
                      color: Colors.white,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    de
                        ? 'Ohne Konto. Verschlüsselt auf deinem Gerät.'
                        : 'No account. Encrypted on your device.',
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 26,
                      color: Colors.white.withValues(alpha: 0.9),
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Hantel wie im App-Icon (`tool/generate_icons.py`, Raster 108 × 108).
class _DumbbellPainter extends CustomPainter {
  const _DumbbellPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 108 * 1.5;
    canvas
      ..translate(size.width / 2, size.height / 2)
      ..rotate(-35 * 3.141592653589793 / 180)
      ..scale(scale)
      ..translate(-54, -54);
    final paint = Paint()..color = Colors.white;
    for (final (x, y, w, h, r) in const [
      (34.0, 50.5, 40.0, 7.0, 3.5),
      (30.0, 37.0, 10.0, 34.0, 4.0),
      (68.0, 37.0, 10.0, 34.0, 4.0),
      (23.0, 43.0, 8.0, 22.0, 3.5),
      (77.0, 43.0, 8.0, 22.0, 3.5),
    ]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, w, h),
          Radius.circular(r),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_DumbbellPainter oldDelegate) => false;
}
