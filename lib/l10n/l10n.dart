import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import 'generated/app_localizations.dart';

export 'generated/app_localizations.dart';

/// Sprache der App: Deutsch, wenn das System Deutsch bevorzugt, sonst
/// Englisch. Weitere Sprachen: ARB-Datei ergänzen und hier aufnehmen.
abstract final class AppLocale {
  static const german = Locale('de');
  static const english = Locale('en');
  static const supported = [german, english];

  static Locale _current = resolve(PlatformDispatcher.instance.locales);

  static Locale get current => _current;

  /// Meldet einen Sprachwechsel zur Laufzeit (Systemeinstellung geändert):
  /// bereits geplante Benachrichtigungen und exportierte Kalendertermine
  /// tragen Texte und müssen neu erzeugt werden.
  static final changes = ValueNotifier<Locale>(_current);

  /// Texte außerhalb von Widgets (Benachrichtigungen, Kalender, PDF …).
  static AppLocalizations get strings => lookupAppLocalizations(_current);

  /// Erste unterstützte Sprache aus der Systemliste, sonst Englisch.
  static Locale resolve(Iterable<Locale> preferred) {
    for (final locale in preferred) {
      for (final candidate in supported) {
        if (candidate.languageCode == locale.languageCode) return candidate;
      }
    }
    return english;
  }

  /// Setzt die Sprache (auch für `DateFormat`); `true`, wenn sie wechselt.
  static bool update(Locale locale) {
    final changed = locale != _current;
    _current = locale;
    Intl.defaultLocale = locale.languageCode;
    changes.value = locale;
    return changed;
  }
}

extension AppLocalizationsContext on BuildContext {
  /// Texte im Widget-Baum; ohne Lokalisierungs-Delegates (z. B. in Tests
  /// mit nacktem MaterialApp) die Systemsprache.
  AppLocalizations get l10n =>
      Localizations.of<AppLocalizations>(this, AppLocalizations) ??
      AppLocale.strings;
}
