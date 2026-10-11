import 'package:flutter_test/flutter_test.dart';
import 'package:mai_fitness/data/starter_plans.dart';
import 'package:mai_fitness/domain/exercises/catalog.dart';
import 'package:mai_fitness/domain/exercises/exercise.dart';

void main() {
  test('IDs eindeutig, Anleitung vollständig', () {
    final ids = builtinExercises.map((e) => e.id).toList();
    expect(ids.toSet(), hasLength(ids.length));
    for (final e in builtinExercises) {
      expect(e.id, matches(RegExp(r'^[a-z0-9_]+$')), reason: e.id);
      expect(e.name.de, isNotEmpty, reason: e.id);
      expect(e.name.en, isNotEmpty, reason: e.id);
      expect(e.setup.de, isNotEmpty, reason: e.id);
      expect(e.steps, isNotEmpty, reason: e.id);
      expect(e.tips, isNotEmpty, reason: e.id);
      expect(e.mistakes, isNotEmpty, reason: e.id);
    }
  });

  test('Varianten verweisen gegenseitig aufeinander', () {
    for (final e in builtinExercises) {
      if (e.harder != null) {
        expect(Catalog.byId(e.harder!)?.easier, e.id, reason: e.id);
      }
      if (e.easier != null) {
        expect(Catalog.byId(e.easier!)?.harder, e.id, reason: e.id);
      }
    }
  });

  test('Bibliothek deckt Geräte, Körpergewicht und Ausdauer ab', () {
    int count(Equipment eq) =>
        builtinExercises.where((e) => e.equipment == eq).length;
    expect(count(Equipment.machine), greaterThanOrEqualTo(15));
    expect(count(Equipment.bodyweight), greaterThanOrEqualTo(15));
    expect(count(Equipment.cardioMachine), greaterThanOrEqualTo(3));
  });

  test('Einsteigerpläne nutzen nur vorhandene Übungen', () {
    for (final plan in [
      StarterPlans.gymA,
      StarterPlans.gymB,
      StarterPlans.homeA,
      StarterPlans.homeB,
    ]) {
      for (final e in plan.entries) {
        expect(Catalog.isBuiltin(e.exerciseId), isTrue, reason: e.exerciseId);
      }
    }
  });

  test('Halte-Übungen in Plänen haben eine Zielzeit', () {
    for (final plan in [StarterPlans.gymA, StarterPlans.homeA, StarterPlans.homeB]) {
      for (final e in plan.entries) {
        if (Catalog.byId(e.exerciseId)!.tracking == Tracking.duration) {
          expect(e.targetSeconds, isNotNull, reason: e.exerciseId);
        }
      }
    }
  });
}
