import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mai_fitness/l10n/l10n.dart';

/// Alle Tests laufen auf einem „deutschen Gerät“; Englisch testen einzelne
/// Tests gezielt (siehe l10n_test.dart).
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  binding.platformDispatcher.localesTestValue = const [Locale('de', 'DE')];
  binding.platformDispatcher.localeTestValue = const Locale('de', 'DE');
  await initializeDateFormatting();
  AppLocale.update(AppLocale.german);
  await testMain();
}
