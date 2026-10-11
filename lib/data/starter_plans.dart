import '../domain/exercises/exercise.dart';
import 'repositories/routine_repository.dart';

/// Wo trainiert wird (Einrichtung beim ersten Start).
enum TrainingPlace { gym, home, both }

/// Vorlage für einen Trainingsplan.
class StarterPlan {
  const StarterPlan(this.name, this.entries);

  final L name;
  final List<PlanEntry> entries;
}

/// Einsteigerpläne: zwei Ganzkörper-Einheiten im Wechsel (A/B) — bewährt für
/// Anfänger, 2–3 Trainings pro Woche.
abstract final class StarterPlans {
  static const _hold = 30;

  static const gymA = StarterPlan(L('Ganzkörper A', 'Full body A'), [
    PlanEntry('leg_press'),
    PlanEntry('chest_press_machine'),
    PlanEntry('lat_pulldown'),
    PlanEntry('shoulder_press_machine'),
    PlanEntry('seated_leg_curl'),
    PlanEntry('plank', targetSeconds: _hold, restSeconds: 60),
  ]);

  static const gymB = StarterPlan(L('Ganzkörper B', 'Full body B'), [
    PlanEntry('leg_extension'),
    PlanEntry('seated_row_machine'),
    PlanEntry('pec_deck'),
    PlanEntry('lateral_raise_machine', repMin: 10, repMax: 15),
    PlanEntry('back_extension', repMin: 10, repMax: 15, restSeconds: 60),
    PlanEntry('ab_crunch_machine', repMin: 10, repMax: 15),
  ]);

  static const homeA = StarterPlan(L('Zuhause A', 'Home A'), [
    PlanEntry('bodyweight_squat', repMin: 10, repMax: 20, restSeconds: 60),
    PlanEntry('knee_push_up', repMin: 6, repMax: 15, restSeconds: 60),
    PlanEntry('glute_bridge', repMin: 10, repMax: 20, restSeconds: 60),
    PlanEntry('superman', repMin: 8, repMax: 15, restSeconds: 60),
    PlanEntry('plank', targetSeconds: _hold, restSeconds: 60),
  ]);

  static const homeB = StarterPlan(L('Zuhause B', 'Home B'), [
    PlanEntry('reverse_lunge', repMin: 8, repMax: 15, restSeconds: 60),
    PlanEntry('incline_push_up', repMin: 8, repMax: 15, restSeconds: 60),
    PlanEntry('bird_dog', repMin: 8, repMax: 12, restSeconds: 45),
    PlanEntry('wall_sit', targetSeconds: _hold, restSeconds: 60),
    PlanEntry('crunch', repMin: 10, repMax: 20, restSeconds: 45),
    PlanEntry('side_plank', sets: 2, targetSeconds: 20, restSeconds: 45),
  ]);

  static List<StarterPlan> forPlace(TrainingPlace place) => switch (place) {
    TrainingPlace.gym => const [gymA, gymB],
    TrainingPlace.home => const [homeA, homeB],
    TrainingPlace.both => const [gymA, gymB, homeA],
  };
}
