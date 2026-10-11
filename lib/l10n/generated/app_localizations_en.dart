// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Fitness';

  @override
  String get tabToday => 'Today';

  @override
  String get tabPlans => 'Plans';

  @override
  String get tabProgress => 'Progress';

  @override
  String get tabExercises => 'Exercises';

  @override
  String get commonBack => 'Back';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonClear => 'Clear';

  @override
  String get commonContinue => 'Continue';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonDone => 'Done';

  @override
  String get commonEdit => 'Edit';

  @override
  String get commonMore => 'More';

  @override
  String get commonRemove => 'Remove';

  @override
  String get commonRetry => 'Try again';

  @override
  String get commonSave => 'Save';

  @override
  String get commonToday => 'Today';

  @override
  String get commonTomorrow => 'Tomorrow';

  @override
  String get commonUnderstood => 'Got it';

  @override
  String unitKg(String value) {
    return '$value kg';
  }

  @override
  String get unitKgShort => 'kg';

  @override
  String unitTons(String value) {
    return '$value t';
  }

  @override
  String unitMinutes(int count) {
    return '$count min';
  }

  @override
  String unitHoursMinutes(int hours, String minutes) {
    return '$hours h $minutes min';
  }

  @override
  String unitReps(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count reps',
      one: '1 rep',
    );
    return '$_temp0';
  }

  @override
  String get muscleChest => 'Chest';

  @override
  String get muscleBack => 'Back';

  @override
  String get muscleShoulders => 'Shoulders';

  @override
  String get muscleBiceps => 'Biceps';

  @override
  String get muscleTriceps => 'Triceps';

  @override
  String get muscleCore => 'Core';

  @override
  String get muscleQuads => 'Quads';

  @override
  String get muscleHamstrings => 'Hamstrings';

  @override
  String get muscleGlutes => 'Glutes';

  @override
  String get muscleCalves => 'Calves';

  @override
  String get muscleFullBody => 'Full body';

  @override
  String get muscleCardio => 'Cardio';

  @override
  String get equipmentMachine => 'Machine';

  @override
  String get equipmentCable => 'Cable';

  @override
  String get equipmentBarbell => 'Barbell';

  @override
  String get equipmentDumbbell => 'Dumbbells';

  @override
  String get equipmentBodyweight => 'Bodyweight';

  @override
  String get equipmentBar => 'Bar / bench';

  @override
  String get equipmentCardio => 'Cardio machine';

  @override
  String get trackingWeightReps => 'Weight × reps';

  @override
  String get trackingReps => 'Reps';

  @override
  String get trackingDuration => 'Hold time';

  @override
  String get trackingCardio => 'Duration (cardio)';

  @override
  String get exerciseInstructions => 'Instructions';

  @override
  String get exercisePick => 'Choose exercise';

  @override
  String get exerciseSearch => 'Search exercises';

  @override
  String get exerciseCustomNew => 'Own exercise';

  @override
  String get exerciseCustomEdit => 'Edit exercise';

  @override
  String get exerciseCustomNoNotes => 'Your own exercise — no instructions.';

  @override
  String get exerciseAdvanced => 'Advanced';

  @override
  String get exerciseSetup => 'Setup & start';

  @override
  String get exerciseSteps => 'How to';

  @override
  String get exerciseTips => 'Tips';

  @override
  String get exerciseMistakes => 'Common mistakes';

  @override
  String get exerciseYourProgress => 'Your progress';

  @override
  String get exerciseNoHistory =>
      'Not trained yet. After your first workout you’ll see your history here.';

  @override
  String get exerciseMetricOneRepMax => 'Estimated one-rep max';

  @override
  String get exerciseMetricBest => 'Best set';

  @override
  String exerciseNextTime(String text) {
    return 'Next time: $text';
  }

  @override
  String get exerciseNoneTitle => 'Nothing found';

  @override
  String get exerciseNoneText =>
      'Try another filter or create your own exercise.';

  @override
  String get exerciseName => 'Name';

  @override
  String get exerciseNameMissing => 'Please enter a name';

  @override
  String get exerciseTracking => 'Tracked as';

  @override
  String get exerciseEquipment => 'Equipment';

  @override
  String get exerciseMuscle => 'Main muscle';

  @override
  String get exerciseNotes => 'Notes / instructions';

  @override
  String get exerciseNotesHint => 'e.g. seat height 4, narrow grip';

  @override
  String get exerciseArchiveTitle => 'Delete exercise?';

  @override
  String get exerciseArchiveText =>
      'The exercise disappears from the list. Your history is kept.';

  @override
  String get filterAll => 'All';

  @override
  String get filterMachines => 'Machines';

  @override
  String get filterFreeWeights => 'Free weights';

  @override
  String get filterBodyweight => 'Bodyweight';

  @override
  String get filterCardio => 'Cardio';

  @override
  String get onboardingWelcomeTitle => 'Welcome!';

  @override
  String get onboardingWelcomeText =>
      'Your training companion for the gym and at home.';

  @override
  String get onboardingPointGuide =>
      'Instructions for common machines and bodyweight exercises';

  @override
  String get onboardingPointProgress =>
      'Tick off sets — the app increases weight and reps automatically';

  @override
  String get onboardingPointAchievements =>
      'Achievements, a weekly goal and reminders keep you going';

  @override
  String get onboardingPointPrivacy =>
      'Everything stays encrypted on your device — no account';

  @override
  String get onboardingPlaceTitle => 'Where do you train?';

  @override
  String get onboardingPlaceText =>
      'We’ll set up matching beginner plans. You can change them anytime.';

  @override
  String get placeGym => 'At the gym';

  @override
  String get placeGymText => 'Two full-body machine plans (alternating A/B)';

  @override
  String get placeHome => 'At home';

  @override
  String get placeHomeText => 'Two full-body plans without equipment';

  @override
  String get placeBoth => 'Both';

  @override
  String get placeBothText => 'Gym plans plus one plan for home';

  @override
  String get placeOwn => 'Build my own';

  @override
  String get placeOwnText => 'Start without a template';

  @override
  String get onboardingDaysTitle => 'When do you train?';

  @override
  String get onboardingDaysText =>
      'For beginners 2–3 days a week is ideal, with a rest day in between.';

  @override
  String get onboardingRemindText => 'A reminder on your training days';

  @override
  String get onboardingStart => 'Let’s go';

  @override
  String get onboardingRestore => 'I have a backup';

  @override
  String get achievementsTitle => 'Achievements';

  @override
  String achievementsCount(int done, int total) {
    return '$done of $total achievements';
  }

  @override
  String achievementsUnlockedAt(String date) {
    return 'Unlocked on $date';
  }

  @override
  String get progressEmptyTitle => 'No workouts yet';

  @override
  String get progressEmptyText =>
      'After your first workout you’ll see your progress, forecasts and achievements here.';

  @override
  String progressWeeks(int goal) {
    return 'Workouts per week (goal: $goal)';
  }

  @override
  String get progressExercises => 'Your exercises';

  @override
  String get progressHistory => 'History';

  @override
  String get progressNeedMore => 'Forecast after a few workouts';

  @override
  String progressForecast(String value) {
    return 'In 8 weeks ≈ $value';
  }

  @override
  String get prognosisTitle => 'Forecast';

  @override
  String prognosisRising(String in4, String in8) {
    return 'If you keep this up: ≈ $in4 in 4 weeks, ≈ $in8 in 8 weeks.';
  }

  @override
  String get prognosisFlat =>
      'A plateau right now — the automatic progression will help you past it.';

  @override
  String get prognosisFalling =>
      'A bit less lately — allow some recovery, then it goes up again.';

  @override
  String get routineNew => 'New plan';

  @override
  String get routineEdit => 'Edit plan';

  @override
  String get routineTemplates => 'Templates';

  @override
  String routineExerciseCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count exercises',
      one: '1 exercise',
    );
    return '$_temp0';
  }

  @override
  String get routineEmptyTitle => 'No plan yet';

  @override
  String get routineEmptyText =>
      'A plan is a list of exercises with goals. Start with a template or build your own.';

  @override
  String get routineRotationHint =>
      'Your plans take turns (A → B → A …). Long-press and drag to reorder.';

  @override
  String get routineName => 'Plan name';

  @override
  String get routineNameHint => 'e.g. Full body A';

  @override
  String get routineNameMissing => 'Please give the plan a name.';

  @override
  String get routineSets => 'Sets';

  @override
  String get routineRepMin => 'Reps from';

  @override
  String get routineRepMax => 'Reps to';

  @override
  String get routineRest => 'Rest';

  @override
  String get routineDeleteTitle => 'Delete plan?';

  @override
  String get routineDeleteText =>
      'The plan disappears. Your past workouts are kept.';

  @override
  String get routineLeaveTitle => 'Discard changes?';

  @override
  String get routineLeaveText => 'Your changes to the plan are not saved yet.';

  @override
  String get routineLeaveDiscard => 'Discard';

  @override
  String get keyUnavailableTitle => 'Data not readable right now';

  @override
  String get keyUnavailableText =>
      'The key for your encrypted data is not available right now. Your data is safe — try again in a moment or restart your device.';

  @override
  String get unreadableTitle => 'Old data could not be read';

  @override
  String get unreadableText =>
      'Your previous data could no longer be decrypted on this device and was set aside. Restore it from a backup (Settings → Data).';

  @override
  String get backupIntro =>
      'Backup: all your data, encrypted in one file — for a new phone or just in case. It cannot be read without the password.';

  @override
  String get backupCreate => 'Back up';

  @override
  String get backupRestore => 'Restore';

  @override
  String get backupCreated => 'Backup created';

  @override
  String get backupFailed => 'Sorry, that did not work.';

  @override
  String get backupPassphrase => 'Password';

  @override
  String get backupPassphraseCreateHint =>
      'Choose a password for the backup. It cannot be restored without it — keep it safe!';

  @override
  String get backupPassphraseRestoreHint => 'Backup password';

  @override
  String get backupPassphraseRepeat => 'Repeat password';

  @override
  String get backupPassphraseMismatch => 'Passwords do not match';

  @override
  String get backupPassphraseTooShort => 'At least 8 characters';

  @override
  String get backupPick => 'Choose backup';

  @override
  String get backupReplace => 'Replace';

  @override
  String get backupRestoreConfirmTitle => 'Replace all data?';

  @override
  String get backupRestoreConfirmText =>
      'All plans, workouts and settings on this device will be replaced by the backup.';

  @override
  String backupRestored(String date) {
    return 'Backup from $date restored';
  }

  @override
  String get backupShareSubject => 'Fitness backup';

  @override
  String get backupTooNew =>
      'This backup is from a newer app version. Please update the app.';

  @override
  String get backupUnsupported => 'Backups are not available here.';

  @override
  String get backupWrongApp => 'This is not a Fitness backup.';

  @override
  String get csvExport => 'Share history as table (CSV)';

  @override
  String get csvShareSubject => 'Workout history';

  @override
  String get csvDate => 'Date';

  @override
  String get csvWorkout => 'Workout';

  @override
  String get csvExercise => 'Exercise';

  @override
  String get csvSet => 'Set';

  @override
  String get csvWeight => 'Weight (kg)';

  @override
  String get csvReps => 'Reps';

  @override
  String get csvSeconds => 'Seconds';

  @override
  String get reminderTitle => 'Time to train 💪';

  @override
  String reminderBody(String name) {
    return 'Up today: $name';
  }

  @override
  String get reminderBodyFree => 'Today is a training day.';

  @override
  String get reminderChannel => 'Workout reminders';

  @override
  String get nextTitle => 'Next workout';

  @override
  String get nextAnyDay => 'whenever you like';

  @override
  String get nextNoPlanTitle => 'Let’s get started';

  @override
  String get nextNoPlanText => 'Create a workout plan or start a free workout.';

  @override
  String nextExercises(int count, String names) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count exercises: $names',
      one: '1 exercise: $names',
    );
    return '$_temp0';
  }

  @override
  String get weekTitle => 'This week';

  @override
  String weekStreak(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count weeks in a row',
      one: '1 week in a row',
    );
    return '$_temp0';
  }

  @override
  String weekGoalReached(int count) {
    return 'Weekly goal reached — $count workouts!';
  }

  @override
  String weekProgress(int done, int goal) {
    return '$done of $goal workouts';
  }

  @override
  String achievementsNew(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count new achievements!',
      one: 'New achievement!',
    );
    return '$_temp0';
  }

  @override
  String get recentTitle => 'Recent workouts';

  @override
  String get recentAll => 'All';

  @override
  String get widgetNextTitle => 'Next workout';

  @override
  String get widgetAnyDay => 'Ready when you are';

  @override
  String get widgetEmpty => 'Create a plan in the app';

  @override
  String widgetWeek(int done, int goal) {
    return '$done/$goal this week';
  }

  @override
  String widgetMore(int count) {
    return '+$count more';
  }

  @override
  String setsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sets',
      one: '1 set',
    );
    return '$_temp0';
  }

  @override
  String setsProgress(int done, int total) {
    return '$done/$total sets';
  }

  @override
  String get workoutRunning => 'Workout in progress';

  @override
  String get workoutResume => 'Resume';

  @override
  String get workoutStart => 'Start workout';

  @override
  String get workoutFree => 'Free workout';

  @override
  String get workoutFreeName => 'Free workout';

  @override
  String get workoutFinish => 'Finish';

  @override
  String get workoutFinishTitle => 'Finish workout?';

  @override
  String workoutFinishOpenSets(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sets are not ticked off and will not count.',
      one: '1 set is not ticked off and will not count.',
    );
    return '$_temp0';
  }

  @override
  String get workoutNothingDone =>
      'You haven’t ticked off any sets yet. Discard this workout?';

  @override
  String get workoutDiscard => 'Discard workout';

  @override
  String get workoutDiscardTitle => 'Discard workout?';

  @override
  String get workoutDiscardText => 'All sets of this workout will be deleted.';

  @override
  String get workoutRestTimer => 'Rest timer';

  @override
  String workoutRest(String time) {
    return 'Rest $time';
  }

  @override
  String get workoutRestSkip => 'Skip';

  @override
  String get workoutEmptyTitle => 'No exercise yet';

  @override
  String get workoutEmptyText => 'Add an exercise to get started.';

  @override
  String get workoutAddExercise => 'Add exercise';

  @override
  String get workoutAddSet => 'Set';

  @override
  String get workoutRemoveSet => 'Set';

  @override
  String get workoutRemoveExercise => 'Remove exercise';

  @override
  String get workoutSwap => 'Switch';

  @override
  String workoutSwapEasier(String name) {
    return 'Easier: $name';
  }

  @override
  String workoutSwapHarder(String name) {
    return 'Harder: $name';
  }

  @override
  String targetReps(int sets, String range) {
    return '$sets × $range reps';
  }

  @override
  String targetSets(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sets',
      one: '1 set',
    );
    return '$_temp0';
  }

  @override
  String get setLabel => 'Set';

  @override
  String get repsLabel => 'Reps';

  @override
  String get secondsLabel => 'Seconds';

  @override
  String get minutesLabel => 'Minutes';

  @override
  String get setDone => 'Tick off set';

  @override
  String get setUndo => 'Untick set';

  @override
  String get suggestFirst =>
      'First time: pick a weight you can do all reps with good form.';

  @override
  String suggestIncrease(String delta) {
    return 'Great! All sets done — $delta more today.';
  }

  @override
  String suggestReps(int count) {
    return 'Today’s goal: $count reps per set.';
  }

  @override
  String suggestTime(String delta) {
    return 'A bit longer than last time: $delta more.';
  }

  @override
  String suggestHarder(String name) {
    return 'Ready for more: try $name.';
  }

  @override
  String suggestEasier(String name) {
    return 'Tip: build up cleanly with $name.';
  }

  @override
  String suggestDeload(String weight) {
    return 'Missed twice — rebuild cleanly with $weight today.';
  }

  @override
  String get holdStart => 'Start timer';

  @override
  String get holdGetReady => 'Get into position …';

  @override
  String get holdHold => 'Hold!';

  @override
  String get holdReached => 'Goal reached — keep holding or stop.';

  @override
  String holdTarget(int seconds) {
    return 'Goal: $seconds seconds';
  }

  @override
  String get holdStop => 'Stop';

  @override
  String get finishTitle => 'Well done!';

  @override
  String get finishRecords => 'New records';

  @override
  String get finishAchievements => 'New achievements';

  @override
  String get statDuration => 'Duration';

  @override
  String get statSets => 'Sets';

  @override
  String get statVolume => 'Lifted';

  @override
  String get statWorkouts => 'Workouts';

  @override
  String get statStreak => 'Weeks in a row';

  @override
  String get statLast => 'Last';

  @override
  String get statBest => 'Best';

  @override
  String get statSessions => 'Sessions';

  @override
  String recordOneRepMax(String value) {
    return 'estimated max $value';
  }

  @override
  String recordPrevious(String now, String before) {
    return '$now (before $before)';
  }

  @override
  String get historyDeleteTitle => 'Delete workout?';

  @override
  String get historyDeleteText =>
      'The workout will be deleted with all its sets and records.';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsTraining => 'Training';

  @override
  String get settingsDays => 'Training days';

  @override
  String get settingsWeeklyGoal => 'Weekly goal';

  @override
  String settingsPerWeek(int count) {
    return '$count × per week';
  }

  @override
  String get settingsReminders => 'Reminders';

  @override
  String get settingsRemindersText => 'On training days at the chosen time';

  @override
  String get settingsRemindersNoDays => 'Choose training days first';

  @override
  String get settingsReminderTime => 'Time';

  @override
  String get settingsRestTimerText => 'Starts after every completed set';

  @override
  String get settingsData => 'Data';

  @override
  String get settingsPrivacy => 'Privacy';

  @override
  String get settingsPrivacyText =>
      'Everything stays on your device: no account, no cloud, no ads, no analytics. The database is encrypted and the app has no internet access. Data only leaves the device when you share a backup or table yourself.';
}
