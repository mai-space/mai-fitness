/// Wann ist das nächste Training, und welches? — reine Logik.
///
/// Trainingspläne werden reihum trainiert (A → B → C → A …). Trainingstage
/// sind feste Wochentage (1 = Montag … 7 = Sonntag); ohne Trainingstage gibt
/// es kein Datum, nur den nächsten Plan.
class NextWorkout {
  const NextWorkout({required this.routineId, this.day});

  final String routineId;

  /// Tag (00:00) des nächsten Trainings; `null` = kein fester Tag.
  final DateTime? day;
}

abstract final class Schedule {
  /// [routineIds] in Reihenfolge; [lastRoutineId] = Plan des letzten
  /// abgeschlossenen Trainings; [trainedToday] = heute schon trainiert.
  static NextWorkout? next({
    required List<String> routineIds,
    required Set<int> weekdays,
    required DateTime now,
    String? lastRoutineId,
    bool trainedToday = false,
  }) {
    if (routineIds.isEmpty) return null;
    final last = lastRoutineId == null ? -1 : routineIds.indexOf(lastRoutineId);
    final routineId = routineIds[(last + 1) % routineIds.length];
    return NextWorkout(
      routineId: routineId,
      day: nextDay(weekdays, now, skipToday: trainedToday),
    );
  }

  /// Nächster Trainingstag ab heute (bzw. ab morgen mit [skipToday]).
  static DateTime? nextDay(
    Set<int> weekdays,
    DateTime now, {
    bool skipToday = false,
  }) {
    final valid = weekdays.where((d) => d >= 1 && d <= 7).toSet();
    if (valid.isEmpty) return null;
    final today = DateTime(now.year, now.month, now.day);
    for (var i = skipToday ? 1 : 0; i <= 7; i++) {
      final day = DateTime(today.year, today.month, today.day + i);
      if (valid.contains(day.weekday)) return day;
    }
    return null;
  }

  /// Wochentage als Text speichern („1,3,5“) — tolerant lesen.
  static Set<int> parseWeekdays(String? raw) => {
    for (final part in (raw ?? '').split(','))
      if (int.tryParse(part.trim()) case final d? when d >= 1 && d <= 7) d,
  };

  static String formatWeekdays(Set<int> days) =>
      (days.toList()..sort()).join(',');
}
