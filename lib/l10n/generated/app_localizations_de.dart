// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'Fitness';

  @override
  String get tabToday => 'Heute';

  @override
  String get tabPlans => 'Pläne';

  @override
  String get tabProgress => 'Fortschritt';

  @override
  String get tabExercises => 'Übungen';

  @override
  String get commonBack => 'Zurück';

  @override
  String get commonCancel => 'Abbrechen';

  @override
  String get commonClear => 'Leeren';

  @override
  String get commonContinue => 'Weiter';

  @override
  String get commonDelete => 'Löschen';

  @override
  String get commonDone => 'Fertig';

  @override
  String get commonEdit => 'Bearbeiten';

  @override
  String get commonMore => 'Mehr';

  @override
  String get commonRemove => 'Entfernen';

  @override
  String get commonRetry => 'Erneut versuchen';

  @override
  String get commonSave => 'Speichern';

  @override
  String get commonToday => 'Heute';

  @override
  String get commonTomorrow => 'Morgen';

  @override
  String get commonUnderstood => 'Verstanden';

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
      other: '$count Wdh.',
      one: '1 Wdh.',
    );
    return '$_temp0';
  }

  @override
  String get muscleChest => 'Brust';

  @override
  String get muscleBack => 'Rücken';

  @override
  String get muscleShoulders => 'Schultern';

  @override
  String get muscleBiceps => 'Bizeps';

  @override
  String get muscleTriceps => 'Trizeps';

  @override
  String get muscleCore => 'Bauch & Rumpf';

  @override
  String get muscleQuads => 'Oberschenkel vorne';

  @override
  String get muscleHamstrings => 'Oberschenkel hinten';

  @override
  String get muscleGlutes => 'Po';

  @override
  String get muscleCalves => 'Waden';

  @override
  String get muscleFullBody => 'Ganzkörper';

  @override
  String get muscleCardio => 'Ausdauer';

  @override
  String get equipmentMachine => 'Gerät';

  @override
  String get equipmentCable => 'Kabelzug';

  @override
  String get equipmentBarbell => 'Langhantel';

  @override
  String get equipmentDumbbell => 'Kurzhanteln';

  @override
  String get equipmentBodyweight => 'Ohne Geräte';

  @override
  String get equipmentBar => 'Stange / Bank';

  @override
  String get equipmentCardio => 'Ausdauergerät';

  @override
  String get trackingWeightReps => 'Gewicht × Wiederholungen';

  @override
  String get trackingReps => 'Wiederholungen';

  @override
  String get trackingDuration => 'Haltezeit';

  @override
  String get trackingCardio => 'Dauer (Ausdauer)';

  @override
  String get exerciseInstructions => 'Anleitung';

  @override
  String get exercisePick => 'Übung wählen';

  @override
  String get exerciseSearch => 'Übung suchen';

  @override
  String get exerciseCustomNew => 'Eigene Übung';

  @override
  String get exerciseCustomEdit => 'Übung bearbeiten';

  @override
  String get exerciseCustomNoNotes => 'Eigene Übung — ohne Anleitung.';

  @override
  String get exerciseAdvanced => 'Fortgeschritten';

  @override
  String get exerciseSetup => 'Einstellung & Start';

  @override
  String get exerciseSteps => 'Ablauf';

  @override
  String get exerciseTips => 'Tipps';

  @override
  String get exerciseMistakes => 'Häufige Fehler';

  @override
  String get exerciseYourProgress => 'Dein Fortschritt';

  @override
  String get exerciseNoHistory =>
      'Noch nicht trainiert. Nach dem ersten Training siehst du hier deinen Verlauf.';

  @override
  String get exerciseMetricOneRepMax => 'Geschätztes Maximum (1 Wiederholung)';

  @override
  String get exerciseMetricBest => 'Bester Satz';

  @override
  String exerciseNextTime(String text) {
    return 'Nächstes Mal: $text';
  }

  @override
  String get exerciseNoneTitle => 'Nichts gefunden';

  @override
  String get exerciseNoneText =>
      'Probier einen anderen Filter oder leg eine eigene Übung an.';

  @override
  String get exerciseName => 'Name';

  @override
  String get exerciseNameMissing => 'Bitte einen Namen eingeben';

  @override
  String get exerciseTracking => 'Gezählt wird';

  @override
  String get exerciseEquipment => 'Ausrüstung';

  @override
  String get exerciseMuscle => 'Hauptmuskel';

  @override
  String get exerciseNotes => 'Notizen / Anleitung';

  @override
  String get exerciseNotesHint => 'z. B. Sitzhöhe 4, Griff eng';

  @override
  String get exerciseArchiveTitle => 'Übung löschen?';

  @override
  String get exerciseArchiveText =>
      'Die Übung verschwindet aus der Liste. Dein bisheriger Verlauf bleibt erhalten.';

  @override
  String get filterAll => 'Alle';

  @override
  String get filterMachines => 'Geräte';

  @override
  String get filterFreeWeights => 'Freie Gewichte';

  @override
  String get filterBodyweight => 'Ohne Geräte';

  @override
  String get filterCardio => 'Ausdauer';

  @override
  String get onboardingWelcomeTitle => 'Willkommen!';

  @override
  String get onboardingWelcomeText =>
      'Dein Trainingsbegleiter fürs Studio und für zu Hause.';

  @override
  String get onboardingPointGuide =>
      'Anleitungen für gängige Geräte und Übungen ohne Geräte';

  @override
  String get onboardingPointProgress =>
      'Sätze abhaken — die App steigert Gewicht und Wiederholungen automatisch';

  @override
  String get onboardingPointAchievements =>
      'Erfolge, Wochenziel und Erinnerungen halten dich am Ball';

  @override
  String get onboardingPointPrivacy =>
      'Alles bleibt verschlüsselt auf deinem Gerät — ohne Konto';

  @override
  String get onboardingPlaceTitle => 'Wo trainierst du?';

  @override
  String get onboardingPlaceText =>
      'Wir legen dir passende Einsteigerpläne an. Du kannst sie jederzeit ändern.';

  @override
  String get placeGym => 'Im Studio';

  @override
  String get placeGymText => 'Zwei Ganzkörperpläne an Geräten (A/B im Wechsel)';

  @override
  String get placeHome => 'Zu Hause';

  @override
  String get placeHomeText => 'Zwei Ganzkörperpläne ohne Geräte';

  @override
  String get placeBoth => 'Beides';

  @override
  String get placeBothText => 'Studio-Pläne plus ein Plan für zu Hause';

  @override
  String get placeOwn => 'Selbst zusammenstellen';

  @override
  String get placeOwnText => 'Ohne Vorlage starten';

  @override
  String get onboardingDaysTitle => 'Wann trainierst du?';

  @override
  String get onboardingDaysText =>
      'Für Anfänger sind 2–3 Tage pro Woche ideal, mit einem Ruhetag dazwischen.';

  @override
  String get onboardingRemindText => 'Erinnerung an deinen Trainingstagen';

  @override
  String get onboardingStart => 'Loslegen';

  @override
  String get onboardingRestore => 'Ich habe eine Sicherung';

  @override
  String get achievementsTitle => 'Erfolge';

  @override
  String achievementsCount(int done, int total) {
    return '$done von $total Erfolgen';
  }

  @override
  String achievementsUnlockedAt(String date) {
    return 'Erreicht am $date';
  }

  @override
  String get progressEmptyTitle => 'Noch kein Training';

  @override
  String get progressEmptyText =>
      'Nach deinem ersten Training siehst du hier deinen Fortschritt, Prognosen und Erfolge.';

  @override
  String progressWeeks(int goal) {
    return 'Trainings pro Woche (Ziel: $goal)';
  }

  @override
  String get progressExercises => 'Deine Übungen';

  @override
  String get progressHistory => 'Verlauf';

  @override
  String get progressNeedMore => 'Prognose nach ein paar Trainings';

  @override
  String progressForecast(String value) {
    return 'In 8 Wochen ≈ $value';
  }

  @override
  String get prognosisTitle => 'Prognose';

  @override
  String prognosisRising(String in4, String in8) {
    return 'Wenn du so weitermachst: in 4 Wochen ≈ $in4, in 8 Wochen ≈ $in8.';
  }

  @override
  String get prognosisFlat =>
      'Gerade ein Plateau — die automatische Steigerung hilft dir darüber.';

  @override
  String get prognosisFalling =>
      'Zuletzt etwas weniger — gönn dir Erholung, dann geht’s wieder aufwärts.';

  @override
  String get routineNew => 'Neuer Plan';

  @override
  String get routineEdit => 'Plan bearbeiten';

  @override
  String get routineTemplates => 'Vorlagen';

  @override
  String routineExerciseCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Übungen',
      one: '1 Übung',
    );
    return '$_temp0';
  }

  @override
  String get routineEmptyTitle => 'Noch kein Plan';

  @override
  String get routineEmptyText =>
      'Ein Plan ist eine Liste von Übungen mit Zielen. Starte mit einer Vorlage oder stell dir selbst einen zusammen.';

  @override
  String get routineRotationHint =>
      'Deine Pläne kommen reihum dran (A → B → A …). Zum Umsortieren gedrückt halten und ziehen.';

  @override
  String get routineName => 'Name des Plans';

  @override
  String get routineNameHint => 'z. B. Ganzkörper A';

  @override
  String get routineNameMissing => 'Bitte gib dem Plan einen Namen.';

  @override
  String get routineSets => 'Sätze';

  @override
  String get routineRepMin => 'Wdh. von';

  @override
  String get routineRepMax => 'Wdh. bis';

  @override
  String get routineRest => 'Pause';

  @override
  String get routineDeleteTitle => 'Plan löschen?';

  @override
  String get routineDeleteText =>
      'Der Plan verschwindet. Deine bisherigen Trainings bleiben erhalten.';

  @override
  String get routineLeaveTitle => 'Änderungen verwerfen?';

  @override
  String get routineLeaveText =>
      'Deine Änderungen am Plan sind noch nicht gespeichert.';

  @override
  String get routineLeaveDiscard => 'Verwerfen';

  @override
  String get keyUnavailableTitle => 'Daten gerade nicht lesbar';

  @override
  String get keyUnavailableText =>
      'Der Schlüssel deiner verschlüsselten Daten ist gerade nicht erreichbar. Deine Daten sind sicher — versuch es gleich noch einmal oder starte das Gerät neu.';

  @override
  String get unreadableTitle => 'Alte Daten nicht lesbar';

  @override
  String get unreadableText =>
      'Deine bisherigen Daten ließen sich auf diesem Gerät nicht mehr entschlüsseln und wurden beiseitegelegt. Stell sie über eine Sicherung wieder her (Einstellungen → Daten).';

  @override
  String get backupIntro =>
      'Sicherung: alle Daten verschlüsselt in einer Datei — für ein neues Handy oder zur Vorsorge. Ohne Passwort ist sie nicht lesbar.';

  @override
  String get backupCreate => 'Sichern';

  @override
  String get backupRestore => 'Wiederherstellen';

  @override
  String get backupCreated => 'Sicherung erstellt';

  @override
  String get backupFailed => 'Das hat leider nicht geklappt.';

  @override
  String get backupPassphrase => 'Passwort';

  @override
  String get backupPassphraseCreateHint =>
      'Wähle ein Passwort für die Sicherung. Ohne dieses Passwort lässt sie sich nicht wiederherstellen — gut merken!';

  @override
  String get backupPassphraseRestoreHint => 'Passwort der Sicherung';

  @override
  String get backupPassphraseRepeat => 'Passwort wiederholen';

  @override
  String get backupPassphraseMismatch => 'Die Passwörter stimmen nicht überein';

  @override
  String get backupPassphraseTooShort => 'Mindestens 8 Zeichen';

  @override
  String get backupPick => 'Sicherung auswählen';

  @override
  String get backupReplace => 'Ersetzen';

  @override
  String get backupRestoreConfirmTitle => 'Alle Daten ersetzen?';

  @override
  String get backupRestoreConfirmText =>
      'Alle Pläne, Trainings und Einstellungen auf diesem Gerät werden durch die Sicherung ersetzt.';

  @override
  String backupRestored(String date) {
    return 'Sicherung vom $date wiederhergestellt';
  }

  @override
  String get backupShareSubject => 'Fitness-Sicherung';

  @override
  String get backupTooNew =>
      'Diese Sicherung stammt aus einer neueren App-Version. Bitte aktualisiere die App.';

  @override
  String get backupUnsupported => 'Sicherungen sind hier nicht verfügbar.';

  @override
  String get backupWrongApp => 'Das ist keine Sicherung der Fitness-App.';

  @override
  String get csvExport => 'Verlauf als Tabelle teilen (CSV)';

  @override
  String get csvShareSubject => 'Trainingsverlauf';

  @override
  String get csvDate => 'Datum';

  @override
  String get csvWorkout => 'Training';

  @override
  String get csvExercise => 'Übung';

  @override
  String get csvSet => 'Satz';

  @override
  String get csvWeight => 'Gewicht (kg)';

  @override
  String get csvReps => 'Wiederholungen';

  @override
  String get csvSeconds => 'Sekunden';

  @override
  String get reminderTitle => 'Zeit fürs Training 💪';

  @override
  String reminderBody(String name) {
    return 'Heute dran: $name';
  }

  @override
  String get reminderBodyFree => 'Heute ist Trainingstag.';

  @override
  String get reminderChannel => 'Trainingserinnerungen';

  @override
  String get nextTitle => 'Nächstes Training';

  @override
  String get nextAnyDay => 'wann du willst';

  @override
  String get nextNoPlanTitle => 'Los geht’s';

  @override
  String get nextNoPlanText =>
      'Leg einen Trainingsplan an oder starte ein freies Training.';

  @override
  String nextExercises(int count, String names) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Übungen: $names',
      one: '1 Übung: $names',
    );
    return '$_temp0';
  }

  @override
  String get weekTitle => 'Diese Woche';

  @override
  String weekStreak(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Wochen in Folge',
      one: '1 Woche in Folge',
    );
    return '$_temp0';
  }

  @override
  String weekGoalReached(int count) {
    return 'Wochenziel geschafft — $count Trainings!';
  }

  @override
  String weekProgress(int done, int goal) {
    return '$done von $goal Trainings';
  }

  @override
  String achievementsNew(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count neue Erfolge!',
      one: 'Neuer Erfolg!',
    );
    return '$_temp0';
  }

  @override
  String get recentTitle => 'Letzte Trainings';

  @override
  String get recentAll => 'Alle';

  @override
  String get widgetNextTitle => 'Nächstes Training';

  @override
  String get widgetAnyDay => 'Bereit, wenn du es bist';

  @override
  String get widgetEmpty => 'Leg in der App einen Plan an';

  @override
  String widgetWeek(int done, int goal) {
    return '$done/$goal diese Woche';
  }

  @override
  String widgetMore(int count) {
    return '+$count weitere';
  }

  @override
  String setsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Sätze',
      one: '1 Satz',
    );
    return '$_temp0';
  }

  @override
  String setsProgress(int done, int total) {
    return '$done/$total Sätze';
  }

  @override
  String get workoutRunning => 'Training läuft';

  @override
  String get workoutResume => 'Fortsetzen';

  @override
  String get workoutStart => 'Training starten';

  @override
  String get workoutFree => 'Freies Training';

  @override
  String get workoutFreeName => 'Freies Training';

  @override
  String get workoutFinish => 'Fertig';

  @override
  String get workoutFinishTitle => 'Training beenden?';

  @override
  String workoutFinishOpenSets(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Sätze sind nicht abgehakt und werden nicht gezählt.',
      one: '1 Satz ist nicht abgehakt und wird nicht gezählt.',
    );
    return '$_temp0';
  }

  @override
  String get workoutNothingDone =>
      'Du hast noch keinen Satz abgehakt. Training verwerfen?';

  @override
  String get workoutDiscard => 'Training verwerfen';

  @override
  String get workoutDiscardTitle => 'Training verwerfen?';

  @override
  String get workoutDiscardText =>
      'Alle Sätze dieses Trainings werden gelöscht.';

  @override
  String get workoutRestTimer => 'Pausen-Timer';

  @override
  String workoutRest(String time) {
    return 'Pause $time';
  }

  @override
  String get workoutRestSkip => 'Weiter';

  @override
  String get workoutEmptyTitle => 'Noch keine Übung';

  @override
  String get workoutEmptyText => 'Füge eine Übung hinzu, um loszulegen.';

  @override
  String get workoutAddExercise => 'Übung hinzufügen';

  @override
  String get workoutAddSet => 'Satz';

  @override
  String get workoutRemoveSet => 'Satz';

  @override
  String get workoutRemoveExercise => 'Übung entfernen';

  @override
  String get workoutSwap => 'Wechseln';

  @override
  String workoutSwapEasier(String name) {
    return 'Leichter: $name';
  }

  @override
  String workoutSwapHarder(String name) {
    return 'Schwerer: $name';
  }

  @override
  String targetReps(int sets, String range) {
    return '$sets × $range Wdh.';
  }

  @override
  String targetSets(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Sätze',
      one: '1 Satz',
    );
    return '$_temp0';
  }

  @override
  String get setLabel => 'Satz';

  @override
  String get repsLabel => 'Wdh.';

  @override
  String get secondsLabel => 'Sekunden';

  @override
  String get minutesLabel => 'Minuten';

  @override
  String get setDone => 'Satz abhaken';

  @override
  String get setUndo => 'Haken entfernen';

  @override
  String get suggestFirst =>
      'Erstes Mal: Wähl ein Gewicht, mit dem du alle Wiederholungen sauber schaffst.';

  @override
  String suggestIncrease(String delta) {
    return 'Stark! Alle Sätze geschafft — heute $delta mehr.';
  }

  @override
  String suggestReps(int count) {
    return 'Ziel heute: $count Wiederholungen je Satz.';
  }

  @override
  String suggestTime(String delta) {
    return 'Etwas länger als zuletzt: $delta mehr.';
  }

  @override
  String suggestHarder(String name) {
    return 'Bereit für mehr: probier $name.';
  }

  @override
  String suggestEasier(String name) {
    return 'Tipp: Mit $name sauber aufbauen.';
  }

  @override
  String suggestDeload(String weight) {
    return 'Zweimal knapp verfehlt — heute mit $weight sauber neu aufbauen.';
  }

  @override
  String get holdStart => 'Timer starten';

  @override
  String get holdGetReady => 'In Position …';

  @override
  String get holdHold => 'Halten!';

  @override
  String get holdReached => 'Ziel erreicht — halte weiter oder stopp.';

  @override
  String holdTarget(int seconds) {
    return 'Ziel: $seconds Sekunden';
  }

  @override
  String get holdStop => 'Stopp';

  @override
  String get finishTitle => 'Stark gemacht!';

  @override
  String get finishRecords => 'Neue Rekorde';

  @override
  String get finishAchievements => 'Neue Erfolge';

  @override
  String get statDuration => 'Dauer';

  @override
  String get statSets => 'Sätze';

  @override
  String get statVolume => 'Bewegt';

  @override
  String get statWorkouts => 'Trainings';

  @override
  String get statStreak => 'Wochen in Folge';

  @override
  String get statLast => 'Zuletzt';

  @override
  String get statBest => 'Bestwert';

  @override
  String get statSessions => 'Trainings';

  @override
  String recordOneRepMax(String value) {
    return 'geschätztes Maximum $value';
  }

  @override
  String recordPrevious(String now, String before) {
    return '$now (vorher $before)';
  }

  @override
  String get historyDeleteTitle => 'Training löschen?';

  @override
  String get historyDeleteText =>
      'Das Training wird mit allen Sätzen und Rekorden gelöscht.';

  @override
  String get settingsTitle => 'Einstellungen';

  @override
  String get settingsTraining => 'Training';

  @override
  String get settingsDays => 'Trainingstage';

  @override
  String get settingsWeeklyGoal => 'Wochenziel';

  @override
  String settingsPerWeek(int count) {
    return '$count × pro Woche';
  }

  @override
  String get settingsReminders => 'Erinnerungen';

  @override
  String get settingsRemindersText => 'An Trainingstagen zur gewählten Uhrzeit';

  @override
  String get settingsRemindersNoDays => 'Wähle zuerst Trainingstage';

  @override
  String get settingsReminderTime => 'Uhrzeit';

  @override
  String get settingsRestTimerText => 'Startet nach jedem abgehakten Satz';

  @override
  String get settingsData => 'Daten';

  @override
  String get settingsPrivacy => 'Datenschutz';

  @override
  String get settingsPrivacyText =>
      'Alles bleibt auf deinem Gerät: kein Konto, keine Cloud, keine Werbung, keine Analyse. Die Datenbank ist verschlüsselt; die App hat keinen Internetzugriff. Daten verlassen das Gerät nur, wenn du selbst eine Sicherung oder Tabelle teilst.';
}
