import 'catalog_data.dart';
import 'exercise.dart';

export 'catalog_data.dart' show builtinExercises;

/// Zugriff auf die eingebaute Übungsbibliothek.
abstract final class Catalog {
  static final Map<String, ExerciseInfo> _byId = {
    for (final e in builtinExercises) e.id: e,
  };

  static ExerciseInfo? byId(String id) => _byId[id];

  static bool isBuiltin(String id) => _byId.containsKey(id);
}
