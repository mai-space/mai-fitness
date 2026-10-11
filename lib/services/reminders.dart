import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../data/app_database.dart';
import '../data/repositories/routine_repository.dart';
import '../data/settings.dart';
import '../domain/schedule.dart';
import '../l10n/l10n.dart';

/// Trainingserinnerungen — lokal geplant, kein Server, kein Push.
///
/// An jedem Trainingstag zur gewählten Uhrzeit: „Heute: Ganzkörper A“.
/// Geplant werden die nächsten zwei Wochen, neu bei jeder Änderung (Plan,
/// Training abgeschlossen, Einstellungen). Wer heute schon trainiert hat,
/// wird heute nicht mehr erinnert.
class Reminders {
  Reminders(this.db);

  final AppDatabase db;
  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  static const _deviceChannel = MethodChannel('mai/device');
  static const daysAhead = 14;

  static bool get supported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  Future<void> init() async {
    if (_ready || !supported) return;
    tz.initializeTimeZones();
    try {
      final zone = await _deviceChannel.invokeMethod<String>('timeZone');
      tz.setLocalLocation(tz.getLocation(zone ?? 'Europe/Berlin'));
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('Europe/Berlin'));
    }
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );
    await _plugin.initialize(settings: settings);
    _ready = true;
  }

  Future<bool> requestPermission() async {
    if (!supported) return false;
    try {
      return await _requestPermission();
    } catch (e) {
      // Ohne Erlaubnis läuft die App normal weiter (auch in Tests ohne Plugin).
      debugPrint('Benachrichtigungen nicht verfügbar: $e');
      return false;
    }
  }

  Future<bool> _requestPermission() async {
    await init();
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android != null) {
      return await android.requestNotificationsPermission() ?? false;
    }
    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    return await ios?.requestPermissions(alert: true, sound: true) ?? false;
  }

  /// Termine der nächsten [daysAhead] Tage (für Tests ohne Plugin).
  static List<DateTime> plannedTimes({
    required Set<int> weekdays,
    required int minutes,
    required DateTime now,
    required bool trainedToday,
  }) {
    final out = <DateTime>[];
    for (var d = 0; d < daysAhead; d++) {
      final day = DateTime(now.year, now.month, now.day + d);
      if (!weekdays.contains(day.weekday)) continue;
      if (d == 0 && trainedToday) continue;
      final at = DateTime(
        day.year,
        day.month,
        day.day,
        minutes ~/ 60,
        minutes % 60,
      );
      if (at.isAfter(now)) out.add(at);
    }
    return out;
  }

  /// Alles neu planen.
  Future<void> reschedule() async {
    if (!supported) return;
    await init();
    await _plugin.cancelAll();
    final settings = Settings(db);
    if (!await settings.flag(SettingKeys.remindersEnabled)) return;
    final weekdays = Schedule.parseWeekdays(
      await settings.get(SettingKeys.trainingDays),
    );
    if (weekdays.isEmpty) return;
    final minutes = await settings.number(
      SettingKeys.reminderMinutes,
      Settings.defaultReminderMinutes,
    );
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final last = await (db.select(db.workouts)
          ..where((t) => t.finishedAt.isNotNull())
          ..orderBy([
            (t) => OrderingTerm(expression: t.startedAt, mode: OrderingMode.desc),
          ])
          ..limit(1))
        .getSingleOrNull();
    final trainedToday = last != null && !last.startedAt.isBefore(today);
    final routines = await RoutineRepository(db).routines();
    final next = Schedule.next(
      routineIds: [for (final r in routines) r.id],
      weekdays: weekdays,
      now: now,
      lastRoutineId: last?.routineId,
    );
    final names = {for (final r in routines) r.id: r.name};
    final strings = AppLocale.strings;
    final body = next == null
        ? strings.reminderBodyFree
        : strings.reminderBody(names[next.routineId] ?? '');
    var id = 1;
    for (final at in plannedTimes(
      weekdays: weekdays,
      minutes: minutes,
      now: now,
      trainedToday: trainedToday,
    )) {
      await _plugin.zonedSchedule(
        id: id++,
        scheduledDate: tz.TZDateTime.from(at, tz.local),
        title: strings.reminderTitle,
        body: body,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            'training',
            strings.reminderChannel,
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
          ),
          iOS: const DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }
  }
}
