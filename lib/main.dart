import 'package:drift/drift.dart' show DriftWrappedException;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app/services.dart';
import 'data/app_database.dart';
import 'data/connection/connection.dart';
import 'data/connection/database_key.dart';
import 'data/settings.dart';
import 'features/onboarding/onboarding_page.dart';
import 'l10n/l10n.dart';
import 'shell/app_shell.dart';
import 'theme/app_theme.dart';

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting();
  AppLocale.update(
    AppLocale.resolve(WidgetsBinding.instance.platformDispatcher.locales),
  );
  await _start();
}

Future<void> _start() async {
  final database = AppDatabase();
  // Schlüssel vorübergehend nicht lesbar (Keystore hakt): nichts verwerfen,
  // sondern erneut versuchen lassen.
  try {
    await database.customSelect('SELECT 1').get();
  } catch (e) {
    if (!_isKeyUnavailable(e)) rethrow;
    await database.close().catchError((Object _) {});
    runApp(_KeyUnavailableApp(onRetry: _start));
    return;
  }
  runApp(FitnessApp(services: AppServices(database)));
  if (databaseOpenStatus.value?.unreadableCopy != null) {
    WidgetsBinding.instance.addPostFrameCallback((_) => _showUnreadableData());
  }
}

bool _isKeyUnavailable(Object e) =>
    e is DatabaseKeyUnavailable ||
    (e is DriftWrappedException && e.cause is DatabaseKeyUnavailable);

class _KeyUnavailableApp extends StatelessWidget {
  const _KeyUnavailableApp({required this.onRetry});

  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      supportedLocales: AppLocale.supported,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      home: Builder(
        builder: (context) => Scaffold(
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.lock_clock_outlined, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    context.l10n.keyUnavailableTitle,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    context.l10n.keyUnavailableText,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: onRetry,
                    child: Text(context.l10n.commonRetry),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Die gespeicherte Datenbank ließ sich nicht entschlüsseln und wurde
/// beiseitegelegt — Wiederherstellung über eine Sicherung.
void _showUnreadableData() {
  final context = appNavigatorKey.currentContext;
  if (context == null) return;
  showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      icon: const Icon(Icons.lock_reset),
      title: Text(context.l10n.unreadableTitle),
      content: Text(context.l10n.unreadableText),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: Text(context.l10n.commonUnderstood),
        ),
      ],
    ),
  );
}

class FitnessApp extends StatefulWidget {
  const FitnessApp({super.key, required this.services});

  final AppServices services;

  @override
  State<FitnessApp> createState() => _FitnessAppState();
}

class _FitnessAppState extends State<FitnessApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeLocales(List<Locale>? locales) {
    if (locales == null) return;
    if (AppLocale.update(AppLocale.resolve(locales))) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      services: widget.services,
      child: MaterialApp(
        navigatorKey: appNavigatorKey,
        onGenerateTitle: (context) => context.l10n.appTitle,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        locale: AppLocale.current,
        supportedLocales: AppLocale.supported,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: const _Home(),
      ),
    );
  }
}

/// Einrichtung beim ersten Start, danach die App.
class _Home extends StatelessWidget {
  const _Home();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<String?>(
      stream: context.services.settings.watch(SettingKeys.onboarded),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: SizedBox.shrink());
        }
        return snapshot.data == '1' ? const AppShell() : const OnboardingPage();
      },
    );
  }
}
