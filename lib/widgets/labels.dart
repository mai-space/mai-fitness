import 'package:intl/intl.dart';

import '../domain/exercises/exercise.dart';
import '../l10n/l10n.dart';

/// „42,5 kg“ (ohne unnötige Nachkommastellen).
String formatKg(double kg, AppLocalizations l10n) =>
    l10n.unitKg(formatNumber(kg, l10n));

String formatNumber(num v, AppLocalizations l10n) =>
    NumberFormat('#,##0.##', l10n.localeName).format(v);

/// „45 s“ bzw. „1:30 min“.
String formatSeconds(int seconds) {
  if (seconds < 60) return '$seconds s';
  final m = seconds ~/ 60;
  final s = seconds % 60;
  return s == 0 ? '$m min' : '$m:${s.toString().padLeft(2, '0')} min';
}

String formatMinutes(int minutes, AppLocalizations l10n) =>
    l10n.unitMinutes(minutes);

/// Tonnen ab 1000 kg („1,2 t“), sonst kg.
String formatVolume(double kg, AppLocalizations l10n) => kg >= 1000
    ? l10n.unitTons(NumberFormat('#,##0.#', l10n.localeName).format(kg / 1000))
    : formatKg(kg.roundToDouble(), l10n);

/// Dauer eines Trainings („52 min“, „1 h 05 min“).
String formatDuration(Duration d, AppLocalizations l10n) {
  final m = d.inMinutes;
  if (m < 60) return l10n.unitMinutes(m);
  return l10n.unitHoursMinutes(m ~/ 60, (m % 60).toString().padLeft(2, '0'));
}

extension Names on AppLocalizations {
  String muscleName(Muscle m) => switch (m) {
    Muscle.chest => muscleChest,
    Muscle.back => muscleBack,
    Muscle.shoulders => muscleShoulders,
    Muscle.biceps => muscleBiceps,
    Muscle.triceps => muscleTriceps,
    Muscle.core => muscleCore,
    Muscle.quads => muscleQuads,
    Muscle.hamstrings => muscleHamstrings,
    Muscle.glutes => muscleGlutes,
    Muscle.calves => muscleCalves,
    Muscle.fullBody => muscleFullBody,
    Muscle.cardio => muscleCardio,
  };

  String equipmentName(Equipment e) => switch (e) {
    Equipment.machine => equipmentMachine,
    Equipment.cable => equipmentCable,
    Equipment.barbell => equipmentBarbell,
    Equipment.dumbbell => equipmentDumbbell,
    Equipment.bodyweight => equipmentBodyweight,
    Equipment.bar => equipmentBar,
    Equipment.cardioMachine => equipmentCardio,
  };

  String trackingName(Tracking t) => switch (t) {
    Tracking.weightReps => trackingWeightReps,
    Tracking.reps => trackingReps,
    Tracking.duration => trackingDuration,
    Tracking.cardio => trackingCardio,
  };

  /// Mo … So (1 = Montag).
  String weekdayShort(int weekday) =>
      DateFormat.E(localeName).format(DateTime(2024, 1, weekday));
}
