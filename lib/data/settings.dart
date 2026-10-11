import 'app_database.dart';

/// Schlüssel der Einstellungen (Werte als Text, tolerant gelesen).
abstract final class SettingKeys {
  static const onboarded = 'onboarded';

  /// Trainingstage „1,3,5“ (1 = Montag).
  static const trainingDays = 'training_days';

  /// Wochenziel (Trainings pro Woche); Standard = Anzahl Trainingstage.
  static const weeklyGoal = 'weekly_goal';
  static const remindersEnabled = 'reminders_enabled';

  /// Uhrzeit der Erinnerung, Minuten nach Mitternacht.
  static const reminderMinutes = 'reminder_minutes';

  /// Pausen-Timer nach jedem Satz.
  static const restTimer = 'rest_timer';

  /// Vibration am Ende der Pause.
  static const restVibrate = 'rest_vibrate';
}

/// Lesen/Schreiben der Einstellungen.
class Settings {
  Settings(this.db);

  final AppDatabase db;

  static const defaultReminderMinutes = 17 * 60 + 30;

  Future<String?> get(String key) async {
    final row = await (db.select(
      db.localSettings,
    )..where((t) => t.key.equals(key))).getSingleOrNull();
    return row?.value;
  }

  Future<void> set(String key, String value) => db
      .into(db.localSettings)
      .insertOnConflictUpdate(LocalSetting(key: key, value: value));

  Stream<String?> watch(String key) =>
      (db.select(db.localSettings)..where((t) => t.key.equals(key)))
          .watchSingleOrNull()
          .map((r) => r?.value);

  Future<bool> flag(String key, {bool fallback = false}) async {
    final v = await get(key);
    return v == null ? fallback : v == '1';
  }

  Future<void> setFlag(String key, bool value) => set(key, value ? '1' : '0');

  Future<int> number(String key, int fallback) async =>
      int.tryParse(await get(key) ?? '') ?? fallback;

  /// Alle Einstellungen auf einmal (für Seiten, die mehrere brauchen).
  Stream<Map<String, String>> watchAll() => db
      .select(db.localSettings)
      .watch()
      .map((rows) => {for (final r in rows) r.key: r.value});
}

extension SettingsMap on Map<String, String> {
  bool flag(String key, {bool fallback = false}) {
    final v = this[key];
    return v == null ? fallback : v == '1';
  }

  int number(String key, int fallback) => int.tryParse(this[key] ?? '') ?? fallback;
}

