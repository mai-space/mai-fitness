import 'dart:async';

import 'package:flutter/material.dart';

import '../app/services.dart';
import '../features/exercises/library_page.dart';
import '../features/progress/progress_page.dart';
import '../features/routines/routines_page.dart';
import '../features/today/today_page.dart';
import '../features/workout/start.dart';
import '../home_widgets/home_widgets.dart';
import '../l10n/l10n.dart';

/// Vier Bereiche: Heute · Pläne · Fortschritt · Übungen.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> with WidgetsBindingObserver {
  int _index = 0;
  StreamSubscription<WidgetLink>? _links;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final s = context.services;
      _links = s.widgets.links.stream.listen(_openLink);
      s.widgets.start().catchError((_) {});
      s.watchForReminders();
      s.scheduleReminders();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _links?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      // „Heute/Morgen“ und Wochenstand aktuell halten.
      context.services.widgets.publish().catchError((_) {});
    }
  }

  void _openLink(WidgetLink link) {
    if (!mounted) return;
    Navigator.of(context).popUntil((r) => r.isFirst);
    setState(() => _index = 0);
    if (link == WidgetLink.start) startNext(context);
  }

  void _open(int i) => setState(() => _index = i);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          TodayPage(onOpenTab: _open),
          const RoutinesPage(),
          const ProgressPage(),
          const LibraryPage(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _open,
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.today_outlined),
            selectedIcon: const Icon(Icons.today),
            label: l10n.tabToday,
          ),
          NavigationDestination(
            icon: const Icon(Icons.list_alt_outlined),
            selectedIcon: const Icon(Icons.list_alt),
            label: l10n.tabPlans,
          ),
          NavigationDestination(
            icon: const Icon(Icons.insights_outlined),
            selectedIcon: const Icon(Icons.insights),
            label: l10n.tabProgress,
          ),
          NavigationDestination(
            icon: const Icon(Icons.fitness_center_outlined),
            selectedIcon: const Icon(Icons.fitness_center),
            label: l10n.tabExercises,
          ),
        ],
      ),
    );
  }
}
