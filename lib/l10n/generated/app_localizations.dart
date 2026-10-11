import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In de, this message translates to:
  /// **'Fitness'**
  String get appTitle;

  /// No description provided for @tabToday.
  ///
  /// In de, this message translates to:
  /// **'Heute'**
  String get tabToday;

  /// No description provided for @tabPlans.
  ///
  /// In de, this message translates to:
  /// **'Pläne'**
  String get tabPlans;

  /// No description provided for @tabProgress.
  ///
  /// In de, this message translates to:
  /// **'Fortschritt'**
  String get tabProgress;

  /// No description provided for @tabExercises.
  ///
  /// In de, this message translates to:
  /// **'Übungen'**
  String get tabExercises;

  /// No description provided for @commonBack.
  ///
  /// In de, this message translates to:
  /// **'Zurück'**
  String get commonBack;

  /// No description provided for @commonCancel.
  ///
  /// In de, this message translates to:
  /// **'Abbrechen'**
  String get commonCancel;

  /// No description provided for @commonClear.
  ///
  /// In de, this message translates to:
  /// **'Leeren'**
  String get commonClear;

  /// No description provided for @commonContinue.
  ///
  /// In de, this message translates to:
  /// **'Weiter'**
  String get commonContinue;

  /// No description provided for @commonDelete.
  ///
  /// In de, this message translates to:
  /// **'Löschen'**
  String get commonDelete;

  /// No description provided for @commonDone.
  ///
  /// In de, this message translates to:
  /// **'Fertig'**
  String get commonDone;

  /// No description provided for @commonEdit.
  ///
  /// In de, this message translates to:
  /// **'Bearbeiten'**
  String get commonEdit;

  /// No description provided for @commonMore.
  ///
  /// In de, this message translates to:
  /// **'Mehr'**
  String get commonMore;

  /// No description provided for @commonRemove.
  ///
  /// In de, this message translates to:
  /// **'Entfernen'**
  String get commonRemove;

  /// No description provided for @commonRetry.
  ///
  /// In de, this message translates to:
  /// **'Erneut versuchen'**
  String get commonRetry;

  /// No description provided for @commonSave.
  ///
  /// In de, this message translates to:
  /// **'Speichern'**
  String get commonSave;

  /// No description provided for @commonToday.
  ///
  /// In de, this message translates to:
  /// **'Heute'**
  String get commonToday;

  /// No description provided for @commonTomorrow.
  ///
  /// In de, this message translates to:
  /// **'Morgen'**
  String get commonTomorrow;

  /// No description provided for @commonUnderstood.
  ///
  /// In de, this message translates to:
  /// **'Verstanden'**
  String get commonUnderstood;

  /// No description provided for @unitKg.
  ///
  /// In de, this message translates to:
  /// **'{value} kg'**
  String unitKg(String value);

  /// No description provided for @unitKgShort.
  ///
  /// In de, this message translates to:
  /// **'kg'**
  String get unitKgShort;

  /// No description provided for @unitTons.
  ///
  /// In de, this message translates to:
  /// **'{value} t'**
  String unitTons(String value);

  /// No description provided for @unitMinutes.
  ///
  /// In de, this message translates to:
  /// **'{count} min'**
  String unitMinutes(int count);

  /// No description provided for @unitHoursMinutes.
  ///
  /// In de, this message translates to:
  /// **'{hours} h {minutes} min'**
  String unitHoursMinutes(int hours, String minutes);

  /// No description provided for @unitReps.
  ///
  /// In de, this message translates to:
  /// **'{count, plural, =1{1 Wdh.} other{{count} Wdh.}}'**
  String unitReps(int count);

  /// No description provided for @muscleChest.
  ///
  /// In de, this message translates to:
  /// **'Brust'**
  String get muscleChest;

  /// No description provided for @muscleBack.
  ///
  /// In de, this message translates to:
  /// **'Rücken'**
  String get muscleBack;

  /// No description provided for @muscleShoulders.
  ///
  /// In de, this message translates to:
  /// **'Schultern'**
  String get muscleShoulders;

  /// No description provided for @muscleBiceps.
  ///
  /// In de, this message translates to:
  /// **'Bizeps'**
  String get muscleBiceps;

  /// No description provided for @muscleTriceps.
  ///
  /// In de, this message translates to:
  /// **'Trizeps'**
  String get muscleTriceps;

  /// No description provided for @muscleCore.
  ///
  /// In de, this message translates to:
  /// **'Bauch & Rumpf'**
  String get muscleCore;

  /// No description provided for @muscleQuads.
  ///
  /// In de, this message translates to:
  /// **'Oberschenkel vorne'**
  String get muscleQuads;

  /// No description provided for @muscleHamstrings.
  ///
  /// In de, this message translates to:
  /// **'Oberschenkel hinten'**
  String get muscleHamstrings;

  /// No description provided for @muscleGlutes.
  ///
  /// In de, this message translates to:
  /// **'Po'**
  String get muscleGlutes;

  /// No description provided for @muscleCalves.
  ///
  /// In de, this message translates to:
  /// **'Waden'**
  String get muscleCalves;

  /// No description provided for @muscleFullBody.
  ///
  /// In de, this message translates to:
  /// **'Ganzkörper'**
  String get muscleFullBody;

  /// No description provided for @muscleCardio.
  ///
  /// In de, this message translates to:
  /// **'Ausdauer'**
  String get muscleCardio;

  /// No description provided for @equipmentMachine.
  ///
  /// In de, this message translates to:
  /// **'Gerät'**
  String get equipmentMachine;

  /// No description provided for @equipmentCable.
  ///
  /// In de, this message translates to:
  /// **'Kabelzug'**
  String get equipmentCable;

  /// No description provided for @equipmentBarbell.
  ///
  /// In de, this message translates to:
  /// **'Langhantel'**
  String get equipmentBarbell;

  /// No description provided for @equipmentDumbbell.
  ///
  /// In de, this message translates to:
  /// **'Kurzhanteln'**
  String get equipmentDumbbell;

  /// No description provided for @equipmentBodyweight.
  ///
  /// In de, this message translates to:
  /// **'Ohne Geräte'**
  String get equipmentBodyweight;

  /// No description provided for @equipmentBar.
  ///
  /// In de, this message translates to:
  /// **'Stange / Bank'**
  String get equipmentBar;

  /// No description provided for @equipmentCardio.
  ///
  /// In de, this message translates to:
  /// **'Ausdauergerät'**
  String get equipmentCardio;

  /// No description provided for @trackingWeightReps.
  ///
  /// In de, this message translates to:
  /// **'Gewicht × Wiederholungen'**
  String get trackingWeightReps;

  /// No description provided for @trackingReps.
  ///
  /// In de, this message translates to:
  /// **'Wiederholungen'**
  String get trackingReps;

  /// No description provided for @trackingDuration.
  ///
  /// In de, this message translates to:
  /// **'Haltezeit'**
  String get trackingDuration;

  /// No description provided for @trackingCardio.
  ///
  /// In de, this message translates to:
  /// **'Dauer (Ausdauer)'**
  String get trackingCardio;

  /// No description provided for @exerciseInstructions.
  ///
  /// In de, this message translates to:
  /// **'Anleitung'**
  String get exerciseInstructions;

  /// No description provided for @exercisePick.
  ///
  /// In de, this message translates to:
  /// **'Übung wählen'**
  String get exercisePick;

  /// No description provided for @exerciseSearch.
  ///
  /// In de, this message translates to:
  /// **'Übung suchen'**
  String get exerciseSearch;

  /// No description provided for @exerciseCustomNew.
  ///
  /// In de, this message translates to:
  /// **'Eigene Übung'**
  String get exerciseCustomNew;

  /// No description provided for @exerciseCustomEdit.
  ///
  /// In de, this message translates to:
  /// **'Übung bearbeiten'**
  String get exerciseCustomEdit;

  /// No description provided for @exerciseCustomNoNotes.
  ///
  /// In de, this message translates to:
  /// **'Eigene Übung — ohne Anleitung.'**
  String get exerciseCustomNoNotes;

  /// No description provided for @exerciseAdvanced.
  ///
  /// In de, this message translates to:
  /// **'Fortgeschritten'**
  String get exerciseAdvanced;

  /// No description provided for @exerciseSetup.
  ///
  /// In de, this message translates to:
  /// **'Einstellung & Start'**
  String get exerciseSetup;

  /// No description provided for @exerciseSteps.
  ///
  /// In de, this message translates to:
  /// **'Ablauf'**
  String get exerciseSteps;

  /// No description provided for @exerciseTips.
  ///
  /// In de, this message translates to:
  /// **'Tipps'**
  String get exerciseTips;

  /// No description provided for @exerciseMistakes.
  ///
  /// In de, this message translates to:
  /// **'Häufige Fehler'**
  String get exerciseMistakes;

  /// No description provided for @exerciseYourProgress.
  ///
  /// In de, this message translates to:
  /// **'Dein Fortschritt'**
  String get exerciseYourProgress;

  /// No description provided for @exerciseNoHistory.
  ///
  /// In de, this message translates to:
  /// **'Noch nicht trainiert. Nach dem ersten Training siehst du hier deinen Verlauf.'**
  String get exerciseNoHistory;

  /// No description provided for @exerciseMetricOneRepMax.
  ///
  /// In de, this message translates to:
  /// **'Geschätztes Maximum (1 Wiederholung)'**
  String get exerciseMetricOneRepMax;

  /// No description provided for @exerciseMetricBest.
  ///
  /// In de, this message translates to:
  /// **'Bester Satz'**
  String get exerciseMetricBest;

  /// No description provided for @exerciseNextTime.
  ///
  /// In de, this message translates to:
  /// **'Nächstes Mal: {text}'**
  String exerciseNextTime(String text);

  /// No description provided for @exerciseNoneTitle.
  ///
  /// In de, this message translates to:
  /// **'Nichts gefunden'**
  String get exerciseNoneTitle;

  /// No description provided for @exerciseNoneText.
  ///
  /// In de, this message translates to:
  /// **'Probier einen anderen Filter oder leg eine eigene Übung an.'**
  String get exerciseNoneText;

  /// No description provided for @exerciseName.
  ///
  /// In de, this message translates to:
  /// **'Name'**
  String get exerciseName;

  /// No description provided for @exerciseNameMissing.
  ///
  /// In de, this message translates to:
  /// **'Bitte einen Namen eingeben'**
  String get exerciseNameMissing;

  /// No description provided for @exerciseTracking.
  ///
  /// In de, this message translates to:
  /// **'Gezählt wird'**
  String get exerciseTracking;

  /// No description provided for @exerciseEquipment.
  ///
  /// In de, this message translates to:
  /// **'Ausrüstung'**
  String get exerciseEquipment;

  /// No description provided for @exerciseMuscle.
  ///
  /// In de, this message translates to:
  /// **'Hauptmuskel'**
  String get exerciseMuscle;

  /// No description provided for @exerciseNotes.
  ///
  /// In de, this message translates to:
  /// **'Notizen / Anleitung'**
  String get exerciseNotes;

  /// No description provided for @exerciseNotesHint.
  ///
  /// In de, this message translates to:
  /// **'z. B. Sitzhöhe 4, Griff eng'**
  String get exerciseNotesHint;

  /// No description provided for @exerciseArchiveTitle.
  ///
  /// In de, this message translates to:
  /// **'Übung löschen?'**
  String get exerciseArchiveTitle;

  /// No description provided for @exerciseArchiveText.
  ///
  /// In de, this message translates to:
  /// **'Die Übung verschwindet aus der Liste. Dein bisheriger Verlauf bleibt erhalten.'**
  String get exerciseArchiveText;

  /// No description provided for @filterAll.
  ///
  /// In de, this message translates to:
  /// **'Alle'**
  String get filterAll;

  /// No description provided for @filterMachines.
  ///
  /// In de, this message translates to:
  /// **'Geräte'**
  String get filterMachines;

  /// No description provided for @filterFreeWeights.
  ///
  /// In de, this message translates to:
  /// **'Freie Gewichte'**
  String get filterFreeWeights;

  /// No description provided for @filterBodyweight.
  ///
  /// In de, this message translates to:
  /// **'Ohne Geräte'**
  String get filterBodyweight;

  /// No description provided for @filterCardio.
  ///
  /// In de, this message translates to:
  /// **'Ausdauer'**
  String get filterCardio;

  /// No description provided for @onboardingWelcomeTitle.
  ///
  /// In de, this message translates to:
  /// **'Willkommen!'**
  String get onboardingWelcomeTitle;

  /// No description provided for @onboardingWelcomeText.
  ///
  /// In de, this message translates to:
  /// **'Dein Trainingsbegleiter fürs Studio und für zu Hause.'**
  String get onboardingWelcomeText;

  /// No description provided for @onboardingPointGuide.
  ///
  /// In de, this message translates to:
  /// **'Anleitungen für gängige Geräte und Übungen ohne Geräte'**
  String get onboardingPointGuide;

  /// No description provided for @onboardingPointProgress.
  ///
  /// In de, this message translates to:
  /// **'Sätze abhaken — die App steigert Gewicht und Wiederholungen automatisch'**
  String get onboardingPointProgress;

  /// No description provided for @onboardingPointAchievements.
  ///
  /// In de, this message translates to:
  /// **'Erfolge, Wochenziel und Erinnerungen halten dich am Ball'**
  String get onboardingPointAchievements;

  /// No description provided for @onboardingPointPrivacy.
  ///
  /// In de, this message translates to:
  /// **'Alles bleibt verschlüsselt auf deinem Gerät — ohne Konto'**
  String get onboardingPointPrivacy;

  /// No description provided for @onboardingPlaceTitle.
  ///
  /// In de, this message translates to:
  /// **'Wo trainierst du?'**
  String get onboardingPlaceTitle;

  /// No description provided for @onboardingPlaceText.
  ///
  /// In de, this message translates to:
  /// **'Wir legen dir passende Einsteigerpläne an. Du kannst sie jederzeit ändern.'**
  String get onboardingPlaceText;

  /// No description provided for @placeGym.
  ///
  /// In de, this message translates to:
  /// **'Im Studio'**
  String get placeGym;

  /// No description provided for @placeGymText.
  ///
  /// In de, this message translates to:
  /// **'Zwei Ganzkörperpläne an Geräten (A/B im Wechsel)'**
  String get placeGymText;

  /// No description provided for @placeHome.
  ///
  /// In de, this message translates to:
  /// **'Zu Hause'**
  String get placeHome;

  /// No description provided for @placeHomeText.
  ///
  /// In de, this message translates to:
  /// **'Zwei Ganzkörperpläne ohne Geräte'**
  String get placeHomeText;

  /// No description provided for @placeBoth.
  ///
  /// In de, this message translates to:
  /// **'Beides'**
  String get placeBoth;

  /// No description provided for @placeBothText.
  ///
  /// In de, this message translates to:
  /// **'Studio-Pläne plus ein Plan für zu Hause'**
  String get placeBothText;

  /// No description provided for @placeOwn.
  ///
  /// In de, this message translates to:
  /// **'Selbst zusammenstellen'**
  String get placeOwn;

  /// No description provided for @placeOwnText.
  ///
  /// In de, this message translates to:
  /// **'Ohne Vorlage starten'**
  String get placeOwnText;

  /// No description provided for @onboardingDaysTitle.
  ///
  /// In de, this message translates to:
  /// **'Wann trainierst du?'**
  String get onboardingDaysTitle;

  /// No description provided for @onboardingDaysText.
  ///
  /// In de, this message translates to:
  /// **'Für Anfänger sind 2–3 Tage pro Woche ideal, mit einem Ruhetag dazwischen.'**
  String get onboardingDaysText;

  /// No description provided for @onboardingRemindText.
  ///
  /// In de, this message translates to:
  /// **'Erinnerung an deinen Trainingstagen'**
  String get onboardingRemindText;

  /// No description provided for @onboardingStart.
  ///
  /// In de, this message translates to:
  /// **'Loslegen'**
  String get onboardingStart;

  /// No description provided for @onboardingRestore.
  ///
  /// In de, this message translates to:
  /// **'Ich habe eine Sicherung'**
  String get onboardingRestore;

  /// No description provided for @achievementsTitle.
  ///
  /// In de, this message translates to:
  /// **'Erfolge'**
  String get achievementsTitle;

  /// No description provided for @achievementsCount.
  ///
  /// In de, this message translates to:
  /// **'{done} von {total} Erfolgen'**
  String achievementsCount(int done, int total);

  /// No description provided for @achievementsUnlockedAt.
  ///
  /// In de, this message translates to:
  /// **'Erreicht am {date}'**
  String achievementsUnlockedAt(String date);

  /// No description provided for @progressEmptyTitle.
  ///
  /// In de, this message translates to:
  /// **'Noch kein Training'**
  String get progressEmptyTitle;

  /// No description provided for @progressEmptyText.
  ///
  /// In de, this message translates to:
  /// **'Nach deinem ersten Training siehst du hier deinen Fortschritt, Prognosen und Erfolge.'**
  String get progressEmptyText;

  /// No description provided for @progressWeeks.
  ///
  /// In de, this message translates to:
  /// **'Trainings pro Woche (Ziel: {goal})'**
  String progressWeeks(int goal);

  /// No description provided for @progressExercises.
  ///
  /// In de, this message translates to:
  /// **'Deine Übungen'**
  String get progressExercises;

  /// No description provided for @progressHistory.
  ///
  /// In de, this message translates to:
  /// **'Verlauf'**
  String get progressHistory;

  /// No description provided for @progressNeedMore.
  ///
  /// In de, this message translates to:
  /// **'Prognose nach ein paar Trainings'**
  String get progressNeedMore;

  /// No description provided for @progressForecast.
  ///
  /// In de, this message translates to:
  /// **'In 8 Wochen ≈ {value}'**
  String progressForecast(String value);

  /// No description provided for @prognosisTitle.
  ///
  /// In de, this message translates to:
  /// **'Prognose'**
  String get prognosisTitle;

  /// No description provided for @prognosisRising.
  ///
  /// In de, this message translates to:
  /// **'Wenn du so weitermachst: in 4 Wochen ≈ {in4}, in 8 Wochen ≈ {in8}.'**
  String prognosisRising(String in4, String in8);

  /// No description provided for @prognosisFlat.
  ///
  /// In de, this message translates to:
  /// **'Gerade ein Plateau — die automatische Steigerung hilft dir darüber.'**
  String get prognosisFlat;

  /// No description provided for @prognosisFalling.
  ///
  /// In de, this message translates to:
  /// **'Zuletzt etwas weniger — gönn dir Erholung, dann geht’s wieder aufwärts.'**
  String get prognosisFalling;

  /// No description provided for @routineNew.
  ///
  /// In de, this message translates to:
  /// **'Neuer Plan'**
  String get routineNew;

  /// No description provided for @routineEdit.
  ///
  /// In de, this message translates to:
  /// **'Plan bearbeiten'**
  String get routineEdit;

  /// No description provided for @routineTemplates.
  ///
  /// In de, this message translates to:
  /// **'Vorlagen'**
  String get routineTemplates;

  /// No description provided for @routineExerciseCount.
  ///
  /// In de, this message translates to:
  /// **'{count, plural, =1{1 Übung} other{{count} Übungen}}'**
  String routineExerciseCount(int count);

  /// No description provided for @routineEmptyTitle.
  ///
  /// In de, this message translates to:
  /// **'Noch kein Plan'**
  String get routineEmptyTitle;

  /// No description provided for @routineEmptyText.
  ///
  /// In de, this message translates to:
  /// **'Ein Plan ist eine Liste von Übungen mit Zielen. Starte mit einer Vorlage oder stell dir selbst einen zusammen.'**
  String get routineEmptyText;

  /// No description provided for @routineRotationHint.
  ///
  /// In de, this message translates to:
  /// **'Deine Pläne kommen reihum dran (A → B → A …). Zum Umsortieren gedrückt halten und ziehen.'**
  String get routineRotationHint;

  /// No description provided for @routineName.
  ///
  /// In de, this message translates to:
  /// **'Name des Plans'**
  String get routineName;

  /// No description provided for @routineNameHint.
  ///
  /// In de, this message translates to:
  /// **'z. B. Ganzkörper A'**
  String get routineNameHint;

  /// No description provided for @routineNameMissing.
  ///
  /// In de, this message translates to:
  /// **'Bitte gib dem Plan einen Namen.'**
  String get routineNameMissing;

  /// No description provided for @routineSets.
  ///
  /// In de, this message translates to:
  /// **'Sätze'**
  String get routineSets;

  /// No description provided for @routineRepMin.
  ///
  /// In de, this message translates to:
  /// **'Wdh. von'**
  String get routineRepMin;

  /// No description provided for @routineRepMax.
  ///
  /// In de, this message translates to:
  /// **'Wdh. bis'**
  String get routineRepMax;

  /// No description provided for @routineRest.
  ///
  /// In de, this message translates to:
  /// **'Pause'**
  String get routineRest;

  /// No description provided for @routineDeleteTitle.
  ///
  /// In de, this message translates to:
  /// **'Plan löschen?'**
  String get routineDeleteTitle;

  /// No description provided for @routineDeleteText.
  ///
  /// In de, this message translates to:
  /// **'Der Plan verschwindet. Deine bisherigen Trainings bleiben erhalten.'**
  String get routineDeleteText;

  /// No description provided for @routineLeaveTitle.
  ///
  /// In de, this message translates to:
  /// **'Änderungen verwerfen?'**
  String get routineLeaveTitle;

  /// No description provided for @routineLeaveText.
  ///
  /// In de, this message translates to:
  /// **'Deine Änderungen am Plan sind noch nicht gespeichert.'**
  String get routineLeaveText;

  /// No description provided for @routineLeaveDiscard.
  ///
  /// In de, this message translates to:
  /// **'Verwerfen'**
  String get routineLeaveDiscard;

  /// No description provided for @keyUnavailableTitle.
  ///
  /// In de, this message translates to:
  /// **'Daten gerade nicht lesbar'**
  String get keyUnavailableTitle;

  /// No description provided for @keyUnavailableText.
  ///
  /// In de, this message translates to:
  /// **'Der Schlüssel deiner verschlüsselten Daten ist gerade nicht erreichbar. Deine Daten sind sicher — versuch es gleich noch einmal oder starte das Gerät neu.'**
  String get keyUnavailableText;

  /// No description provided for @unreadableTitle.
  ///
  /// In de, this message translates to:
  /// **'Alte Daten nicht lesbar'**
  String get unreadableTitle;

  /// No description provided for @unreadableText.
  ///
  /// In de, this message translates to:
  /// **'Deine bisherigen Daten ließen sich auf diesem Gerät nicht mehr entschlüsseln und wurden beiseitegelegt. Stell sie über eine Sicherung wieder her (Einstellungen → Daten).'**
  String get unreadableText;

  /// No description provided for @backupIntro.
  ///
  /// In de, this message translates to:
  /// **'Sicherung: alle Daten verschlüsselt in einer Datei — für ein neues Handy oder zur Vorsorge. Ohne Passwort ist sie nicht lesbar.'**
  String get backupIntro;

  /// No description provided for @backupCreate.
  ///
  /// In de, this message translates to:
  /// **'Sichern'**
  String get backupCreate;

  /// No description provided for @backupRestore.
  ///
  /// In de, this message translates to:
  /// **'Wiederherstellen'**
  String get backupRestore;

  /// No description provided for @backupCreated.
  ///
  /// In de, this message translates to:
  /// **'Sicherung erstellt'**
  String get backupCreated;

  /// No description provided for @backupFailed.
  ///
  /// In de, this message translates to:
  /// **'Das hat leider nicht geklappt.'**
  String get backupFailed;

  /// No description provided for @backupPassphrase.
  ///
  /// In de, this message translates to:
  /// **'Passwort'**
  String get backupPassphrase;

  /// No description provided for @backupPassphraseCreateHint.
  ///
  /// In de, this message translates to:
  /// **'Wähle ein Passwort für die Sicherung. Ohne dieses Passwort lässt sie sich nicht wiederherstellen — gut merken!'**
  String get backupPassphraseCreateHint;

  /// No description provided for @backupPassphraseRestoreHint.
  ///
  /// In de, this message translates to:
  /// **'Passwort der Sicherung'**
  String get backupPassphraseRestoreHint;

  /// No description provided for @backupPassphraseRepeat.
  ///
  /// In de, this message translates to:
  /// **'Passwort wiederholen'**
  String get backupPassphraseRepeat;

  /// No description provided for @backupPassphraseMismatch.
  ///
  /// In de, this message translates to:
  /// **'Die Passwörter stimmen nicht überein'**
  String get backupPassphraseMismatch;

  /// No description provided for @backupPassphraseTooShort.
  ///
  /// In de, this message translates to:
  /// **'Mindestens 8 Zeichen'**
  String get backupPassphraseTooShort;

  /// No description provided for @backupPick.
  ///
  /// In de, this message translates to:
  /// **'Sicherung auswählen'**
  String get backupPick;

  /// No description provided for @backupReplace.
  ///
  /// In de, this message translates to:
  /// **'Ersetzen'**
  String get backupReplace;

  /// No description provided for @backupRestoreConfirmTitle.
  ///
  /// In de, this message translates to:
  /// **'Alle Daten ersetzen?'**
  String get backupRestoreConfirmTitle;

  /// No description provided for @backupRestoreConfirmText.
  ///
  /// In de, this message translates to:
  /// **'Alle Pläne, Trainings und Einstellungen auf diesem Gerät werden durch die Sicherung ersetzt.'**
  String get backupRestoreConfirmText;

  /// No description provided for @backupRestored.
  ///
  /// In de, this message translates to:
  /// **'Sicherung vom {date} wiederhergestellt'**
  String backupRestored(String date);

  /// No description provided for @backupShareSubject.
  ///
  /// In de, this message translates to:
  /// **'Fitness-Sicherung'**
  String get backupShareSubject;

  /// No description provided for @backupTooNew.
  ///
  /// In de, this message translates to:
  /// **'Diese Sicherung stammt aus einer neueren App-Version. Bitte aktualisiere die App.'**
  String get backupTooNew;

  /// No description provided for @backupUnsupported.
  ///
  /// In de, this message translates to:
  /// **'Sicherungen sind hier nicht verfügbar.'**
  String get backupUnsupported;

  /// No description provided for @backupWrongApp.
  ///
  /// In de, this message translates to:
  /// **'Das ist keine Sicherung der Fitness-App.'**
  String get backupWrongApp;

  /// No description provided for @csvExport.
  ///
  /// In de, this message translates to:
  /// **'Verlauf als Tabelle teilen (CSV)'**
  String get csvExport;

  /// No description provided for @csvShareSubject.
  ///
  /// In de, this message translates to:
  /// **'Trainingsverlauf'**
  String get csvShareSubject;

  /// No description provided for @csvDate.
  ///
  /// In de, this message translates to:
  /// **'Datum'**
  String get csvDate;

  /// No description provided for @csvWorkout.
  ///
  /// In de, this message translates to:
  /// **'Training'**
  String get csvWorkout;

  /// No description provided for @csvExercise.
  ///
  /// In de, this message translates to:
  /// **'Übung'**
  String get csvExercise;

  /// No description provided for @csvSet.
  ///
  /// In de, this message translates to:
  /// **'Satz'**
  String get csvSet;

  /// No description provided for @csvWeight.
  ///
  /// In de, this message translates to:
  /// **'Gewicht (kg)'**
  String get csvWeight;

  /// No description provided for @csvReps.
  ///
  /// In de, this message translates to:
  /// **'Wiederholungen'**
  String get csvReps;

  /// No description provided for @csvSeconds.
  ///
  /// In de, this message translates to:
  /// **'Sekunden'**
  String get csvSeconds;

  /// No description provided for @reminderTitle.
  ///
  /// In de, this message translates to:
  /// **'Zeit fürs Training 💪'**
  String get reminderTitle;

  /// No description provided for @reminderBody.
  ///
  /// In de, this message translates to:
  /// **'Heute dran: {name}'**
  String reminderBody(String name);

  /// No description provided for @reminderBodyFree.
  ///
  /// In de, this message translates to:
  /// **'Heute ist Trainingstag.'**
  String get reminderBodyFree;

  /// No description provided for @reminderChannel.
  ///
  /// In de, this message translates to:
  /// **'Trainingserinnerungen'**
  String get reminderChannel;

  /// No description provided for @nextTitle.
  ///
  /// In de, this message translates to:
  /// **'Nächstes Training'**
  String get nextTitle;

  /// No description provided for @nextAnyDay.
  ///
  /// In de, this message translates to:
  /// **'wann du willst'**
  String get nextAnyDay;

  /// No description provided for @nextNoPlanTitle.
  ///
  /// In de, this message translates to:
  /// **'Los geht’s'**
  String get nextNoPlanTitle;

  /// No description provided for @nextNoPlanText.
  ///
  /// In de, this message translates to:
  /// **'Leg einen Trainingsplan an oder starte ein freies Training.'**
  String get nextNoPlanText;

  /// No description provided for @nextExercises.
  ///
  /// In de, this message translates to:
  /// **'{count, plural, =1{1 Übung: {names}} other{{count} Übungen: {names}}}'**
  String nextExercises(int count, String names);

  /// No description provided for @weekTitle.
  ///
  /// In de, this message translates to:
  /// **'Diese Woche'**
  String get weekTitle;

  /// No description provided for @weekStreak.
  ///
  /// In de, this message translates to:
  /// **'{count, plural, =1{1 Woche in Folge} other{{count} Wochen in Folge}}'**
  String weekStreak(int count);

  /// No description provided for @weekGoalReached.
  ///
  /// In de, this message translates to:
  /// **'Wochenziel geschafft — {count} Trainings!'**
  String weekGoalReached(int count);

  /// No description provided for @weekProgress.
  ///
  /// In de, this message translates to:
  /// **'{done} von {goal} Trainings'**
  String weekProgress(int done, int goal);

  /// No description provided for @achievementsNew.
  ///
  /// In de, this message translates to:
  /// **'{count, plural, =1{Neuer Erfolg!} other{{count} neue Erfolge!}}'**
  String achievementsNew(int count);

  /// No description provided for @recentTitle.
  ///
  /// In de, this message translates to:
  /// **'Letzte Trainings'**
  String get recentTitle;

  /// No description provided for @recentAll.
  ///
  /// In de, this message translates to:
  /// **'Alle'**
  String get recentAll;

  /// No description provided for @widgetNextTitle.
  ///
  /// In de, this message translates to:
  /// **'Nächstes Training'**
  String get widgetNextTitle;

  /// No description provided for @widgetAnyDay.
  ///
  /// In de, this message translates to:
  /// **'Bereit, wenn du es bist'**
  String get widgetAnyDay;

  /// No description provided for @widgetEmpty.
  ///
  /// In de, this message translates to:
  /// **'Leg in der App einen Plan an'**
  String get widgetEmpty;

  /// No description provided for @widgetWeek.
  ///
  /// In de, this message translates to:
  /// **'{done}/{goal} diese Woche'**
  String widgetWeek(int done, int goal);

  /// No description provided for @widgetMore.
  ///
  /// In de, this message translates to:
  /// **'+{count} weitere'**
  String widgetMore(int count);

  /// No description provided for @setsCount.
  ///
  /// In de, this message translates to:
  /// **'{count, plural, =1{1 Satz} other{{count} Sätze}}'**
  String setsCount(int count);

  /// No description provided for @setsProgress.
  ///
  /// In de, this message translates to:
  /// **'{done}/{total} Sätze'**
  String setsProgress(int done, int total);

  /// No description provided for @workoutRunning.
  ///
  /// In de, this message translates to:
  /// **'Training läuft'**
  String get workoutRunning;

  /// No description provided for @workoutResume.
  ///
  /// In de, this message translates to:
  /// **'Fortsetzen'**
  String get workoutResume;

  /// No description provided for @workoutStart.
  ///
  /// In de, this message translates to:
  /// **'Training starten'**
  String get workoutStart;

  /// No description provided for @workoutFree.
  ///
  /// In de, this message translates to:
  /// **'Freies Training'**
  String get workoutFree;

  /// No description provided for @workoutFreeName.
  ///
  /// In de, this message translates to:
  /// **'Freies Training'**
  String get workoutFreeName;

  /// No description provided for @workoutFinish.
  ///
  /// In de, this message translates to:
  /// **'Fertig'**
  String get workoutFinish;

  /// No description provided for @workoutFinishTitle.
  ///
  /// In de, this message translates to:
  /// **'Training beenden?'**
  String get workoutFinishTitle;

  /// No description provided for @workoutFinishOpenSets.
  ///
  /// In de, this message translates to:
  /// **'{count, plural, =1{1 Satz ist nicht abgehakt und wird nicht gezählt.} other{{count} Sätze sind nicht abgehakt und werden nicht gezählt.}}'**
  String workoutFinishOpenSets(int count);

  /// No description provided for @workoutNothingDone.
  ///
  /// In de, this message translates to:
  /// **'Du hast noch keinen Satz abgehakt. Training verwerfen?'**
  String get workoutNothingDone;

  /// No description provided for @workoutDiscard.
  ///
  /// In de, this message translates to:
  /// **'Training verwerfen'**
  String get workoutDiscard;

  /// No description provided for @workoutDiscardTitle.
  ///
  /// In de, this message translates to:
  /// **'Training verwerfen?'**
  String get workoutDiscardTitle;

  /// No description provided for @workoutDiscardText.
  ///
  /// In de, this message translates to:
  /// **'Alle Sätze dieses Trainings werden gelöscht.'**
  String get workoutDiscardText;

  /// No description provided for @workoutRestTimer.
  ///
  /// In de, this message translates to:
  /// **'Pausen-Timer'**
  String get workoutRestTimer;

  /// No description provided for @workoutRest.
  ///
  /// In de, this message translates to:
  /// **'Pause {time}'**
  String workoutRest(String time);

  /// No description provided for @workoutRestSkip.
  ///
  /// In de, this message translates to:
  /// **'Weiter'**
  String get workoutRestSkip;

  /// No description provided for @workoutEmptyTitle.
  ///
  /// In de, this message translates to:
  /// **'Noch keine Übung'**
  String get workoutEmptyTitle;

  /// No description provided for @workoutEmptyText.
  ///
  /// In de, this message translates to:
  /// **'Füge eine Übung hinzu, um loszulegen.'**
  String get workoutEmptyText;

  /// No description provided for @workoutAddExercise.
  ///
  /// In de, this message translates to:
  /// **'Übung hinzufügen'**
  String get workoutAddExercise;

  /// No description provided for @workoutAddSet.
  ///
  /// In de, this message translates to:
  /// **'Satz'**
  String get workoutAddSet;

  /// No description provided for @workoutRemoveSet.
  ///
  /// In de, this message translates to:
  /// **'Satz'**
  String get workoutRemoveSet;

  /// No description provided for @workoutRemoveExercise.
  ///
  /// In de, this message translates to:
  /// **'Übung entfernen'**
  String get workoutRemoveExercise;

  /// No description provided for @workoutSwap.
  ///
  /// In de, this message translates to:
  /// **'Wechseln'**
  String get workoutSwap;

  /// No description provided for @workoutSwapEasier.
  ///
  /// In de, this message translates to:
  /// **'Leichter: {name}'**
  String workoutSwapEasier(String name);

  /// No description provided for @workoutSwapHarder.
  ///
  /// In de, this message translates to:
  /// **'Schwerer: {name}'**
  String workoutSwapHarder(String name);

  /// No description provided for @targetReps.
  ///
  /// In de, this message translates to:
  /// **'{sets} × {range} Wdh.'**
  String targetReps(int sets, String range);

  /// No description provided for @targetSets.
  ///
  /// In de, this message translates to:
  /// **'{count, plural, =1{1 Satz} other{{count} Sätze}}'**
  String targetSets(int count);

  /// No description provided for @setLabel.
  ///
  /// In de, this message translates to:
  /// **'Satz'**
  String get setLabel;

  /// No description provided for @repsLabel.
  ///
  /// In de, this message translates to:
  /// **'Wdh.'**
  String get repsLabel;

  /// No description provided for @secondsLabel.
  ///
  /// In de, this message translates to:
  /// **'Sekunden'**
  String get secondsLabel;

  /// No description provided for @minutesLabel.
  ///
  /// In de, this message translates to:
  /// **'Minuten'**
  String get minutesLabel;

  /// No description provided for @setDone.
  ///
  /// In de, this message translates to:
  /// **'Satz abhaken'**
  String get setDone;

  /// No description provided for @setUndo.
  ///
  /// In de, this message translates to:
  /// **'Haken entfernen'**
  String get setUndo;

  /// No description provided for @suggestFirst.
  ///
  /// In de, this message translates to:
  /// **'Erstes Mal: Wähl ein Gewicht, mit dem du alle Wiederholungen sauber schaffst.'**
  String get suggestFirst;

  /// No description provided for @suggestIncrease.
  ///
  /// In de, this message translates to:
  /// **'Stark! Alle Sätze geschafft — heute {delta} mehr.'**
  String suggestIncrease(String delta);

  /// No description provided for @suggestReps.
  ///
  /// In de, this message translates to:
  /// **'Ziel heute: {count} Wiederholungen je Satz.'**
  String suggestReps(int count);

  /// No description provided for @suggestTime.
  ///
  /// In de, this message translates to:
  /// **'Etwas länger als zuletzt: {delta} mehr.'**
  String suggestTime(String delta);

  /// No description provided for @suggestHarder.
  ///
  /// In de, this message translates to:
  /// **'Bereit für mehr: probier {name}.'**
  String suggestHarder(String name);

  /// No description provided for @suggestEasier.
  ///
  /// In de, this message translates to:
  /// **'Tipp: Mit {name} sauber aufbauen.'**
  String suggestEasier(String name);

  /// No description provided for @suggestDeload.
  ///
  /// In de, this message translates to:
  /// **'Zweimal knapp verfehlt — heute mit {weight} sauber neu aufbauen.'**
  String suggestDeload(String weight);

  /// No description provided for @holdStart.
  ///
  /// In de, this message translates to:
  /// **'Timer starten'**
  String get holdStart;

  /// No description provided for @holdGetReady.
  ///
  /// In de, this message translates to:
  /// **'In Position …'**
  String get holdGetReady;

  /// No description provided for @holdHold.
  ///
  /// In de, this message translates to:
  /// **'Halten!'**
  String get holdHold;

  /// No description provided for @holdReached.
  ///
  /// In de, this message translates to:
  /// **'Ziel erreicht — halte weiter oder stopp.'**
  String get holdReached;

  /// No description provided for @holdTarget.
  ///
  /// In de, this message translates to:
  /// **'Ziel: {seconds} Sekunden'**
  String holdTarget(int seconds);

  /// No description provided for @holdStop.
  ///
  /// In de, this message translates to:
  /// **'Stopp'**
  String get holdStop;

  /// No description provided for @finishTitle.
  ///
  /// In de, this message translates to:
  /// **'Stark gemacht!'**
  String get finishTitle;

  /// No description provided for @finishRecords.
  ///
  /// In de, this message translates to:
  /// **'Neue Rekorde'**
  String get finishRecords;

  /// No description provided for @finishAchievements.
  ///
  /// In de, this message translates to:
  /// **'Neue Erfolge'**
  String get finishAchievements;

  /// No description provided for @statDuration.
  ///
  /// In de, this message translates to:
  /// **'Dauer'**
  String get statDuration;

  /// No description provided for @statSets.
  ///
  /// In de, this message translates to:
  /// **'Sätze'**
  String get statSets;

  /// No description provided for @statVolume.
  ///
  /// In de, this message translates to:
  /// **'Bewegt'**
  String get statVolume;

  /// No description provided for @statWorkouts.
  ///
  /// In de, this message translates to:
  /// **'Trainings'**
  String get statWorkouts;

  /// No description provided for @statStreak.
  ///
  /// In de, this message translates to:
  /// **'Wochen in Folge'**
  String get statStreak;

  /// No description provided for @statLast.
  ///
  /// In de, this message translates to:
  /// **'Zuletzt'**
  String get statLast;

  /// No description provided for @statBest.
  ///
  /// In de, this message translates to:
  /// **'Bestwert'**
  String get statBest;

  /// No description provided for @statSessions.
  ///
  /// In de, this message translates to:
  /// **'Trainings'**
  String get statSessions;

  /// No description provided for @recordOneRepMax.
  ///
  /// In de, this message translates to:
  /// **'geschätztes Maximum {value}'**
  String recordOneRepMax(String value);

  /// No description provided for @recordPrevious.
  ///
  /// In de, this message translates to:
  /// **'{now} (vorher {before})'**
  String recordPrevious(String now, String before);

  /// No description provided for @historyDeleteTitle.
  ///
  /// In de, this message translates to:
  /// **'Training löschen?'**
  String get historyDeleteTitle;

  /// No description provided for @historyDeleteText.
  ///
  /// In de, this message translates to:
  /// **'Das Training wird mit allen Sätzen und Rekorden gelöscht.'**
  String get historyDeleteText;

  /// No description provided for @settingsTitle.
  ///
  /// In de, this message translates to:
  /// **'Einstellungen'**
  String get settingsTitle;

  /// No description provided for @settingsTraining.
  ///
  /// In de, this message translates to:
  /// **'Training'**
  String get settingsTraining;

  /// No description provided for @settingsDays.
  ///
  /// In de, this message translates to:
  /// **'Trainingstage'**
  String get settingsDays;

  /// No description provided for @settingsWeeklyGoal.
  ///
  /// In de, this message translates to:
  /// **'Wochenziel'**
  String get settingsWeeklyGoal;

  /// No description provided for @settingsPerWeek.
  ///
  /// In de, this message translates to:
  /// **'{count} × pro Woche'**
  String settingsPerWeek(int count);

  /// No description provided for @settingsReminders.
  ///
  /// In de, this message translates to:
  /// **'Erinnerungen'**
  String get settingsReminders;

  /// No description provided for @settingsRemindersText.
  ///
  /// In de, this message translates to:
  /// **'An Trainingstagen zur gewählten Uhrzeit'**
  String get settingsRemindersText;

  /// No description provided for @settingsRemindersNoDays.
  ///
  /// In de, this message translates to:
  /// **'Wähle zuerst Trainingstage'**
  String get settingsRemindersNoDays;

  /// No description provided for @settingsReminderTime.
  ///
  /// In de, this message translates to:
  /// **'Uhrzeit'**
  String get settingsReminderTime;

  /// No description provided for @settingsRestTimerText.
  ///
  /// In de, this message translates to:
  /// **'Startet nach jedem abgehakten Satz'**
  String get settingsRestTimerText;

  /// No description provided for @settingsData.
  ///
  /// In de, this message translates to:
  /// **'Daten'**
  String get settingsData;

  /// No description provided for @settingsPrivacy.
  ///
  /// In de, this message translates to:
  /// **'Datenschutz'**
  String get settingsPrivacy;

  /// No description provided for @settingsPrivacyText.
  ///
  /// In de, this message translates to:
  /// **'Alles bleibt auf deinem Gerät: kein Konto, keine Cloud, keine Werbung, keine Analyse. Die Datenbank ist verschlüsselt; die App hat keinen Internetzugriff. Daten verlassen das Gerät nur, wenn du selbst eine Sicherung oder Tabelle teilst.'**
  String get settingsPrivacyText;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['de', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
