import 'package:drift/drift.dart';
import 'package:intl/intl.dart';

import '../data/app_database.dart';
import '../data/repositories/exercise_repository.dart';

/// Trainingsverlauf als CSV (Tabellenkalkulation) — unverschlüsselt, daher
/// nur auf ausdrücklichen Wunsch. Zum Umziehen dient die Sicherung.
///
/// Trennzeichen Semikolon, Dezimalkomma bei Deutsch — so öffnet Excel die
/// Datei ohne Import-Dialog.
abstract final class CsvExport {
  static Future<String> build(
    AppDatabase db,
    String languageCode, {
    required List<String> header,
  }) async {
    final query = db.select(db.workoutSets).join([
      innerJoin(db.workouts, db.workouts.id.equalsExp(db.workoutSets.workoutId)),
    ])
      ..where(
        db.workoutSets.done.equals(true) & db.workouts.finishedAt.isNotNull(),
      )
      ..orderBy([
        OrderingTerm(expression: db.workouts.startedAt),
        OrderingTerm(expression: db.workoutSets.exerciseOrder),
        OrderingTerm(expression: db.workoutSets.setIndex),
      ]);
    final rows = await query.get();
    final ids = {for (final r in rows) r.readTable(db.workoutSets).exerciseId};
    final names = await ExerciseRepository(db).byIds(ids, languageCode);
    final german = languageCode == 'de';
    final sep = german ? ';' : ',';
    final date = DateFormat('yyyy-MM-dd HH:mm');
    String number(num? v) {
      if (v == null) return '';
      final text = v == v.roundToDouble() ? v.round().toString() : v.toString();
      return german ? text.replaceAll('.', ',') : text;
    }

    final out = StringBuffer()..writeln(header.map(_quote).join(sep));
    for (final r in rows) {
      final w = r.readTable(db.workouts);
      final s = r.readTable(db.workoutSets);
      out.writeln(
        [
          date.format(w.startedAt),
          _quote(w.name),
          _quote(names[s.exerciseId]?.name ?? s.exerciseId),
          '${s.setIndex + 1}',
          number(s.weightKg),
          number(s.reps),
          number(s.seconds),
        ].join(sep),
      );
    }
    return out.toString();
  }

  static String _quote(String v) {
    if (!v.contains(RegExp('[";,\n]'))) return v;
    return '"${v.replaceAll('"', '""')}"';
  }
}
