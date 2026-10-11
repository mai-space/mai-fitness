import 'package:flutter/material.dart';

import '../../app/services.dart';
import '../../data/settings.dart';
import '../../data/starter_plans.dart';
import '../../domain/schedule.dart';
import '../../l10n/l10n.dart';
import '../../services/reminders.dart';
import '../settings/backup_section.dart';
import '../settings/settings_page.dart' show WeekdayPicker;

/// Einrichtung beim ersten Start: Datenschutz, wo trainiert wird
/// (Einsteigerpläne), Trainingstage und Erinnerung.
class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _pages = PageController();
  int _page = 0;
  TrainingPlace? _place = TrainingPlace.gym;
  Set<int> _days = {1, 3, 5};
  bool _remind = true;
  bool _saving = false;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _next() {
    _pages.nextPage(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  Future<void> _finish() async {
    setState(() => _saving = true);
    final s = context.services;
    final lang = context.lang;
    final place = _place;
    if (place != null && (await s.routines.routines()).isEmpty) {
      for (final plan in StarterPlans.forPlace(place)) {
        await s.routines.createFromTemplate(plan.name.of(lang), plan.entries);
      }
    }
    await s.settings.set(
      SettingKeys.trainingDays,
      Schedule.formatWeekdays(_days),
    );
    var remind = _remind && _days.isNotEmpty && Reminders.supported;
    if (remind) remind = await s.reminders.requestPermission();
    await s.settings.setFlag(SettingKeys.remindersEnabled, remind);
    // Zuletzt: schaltet auf die App um.
    await s.settings.setFlag(SettingKeys.onboarded, true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final pages = [
      _Step(
        icon: Icons.fitness_center,
        title: l10n.onboardingWelcomeTitle,
        children: [
          Text(l10n.onboardingWelcomeText, style: theme.textTheme.bodyLarge),
          const SizedBox(height: 20),
          for (final (icon, text) in [
            (Icons.menu_book_outlined, l10n.onboardingPointGuide),
            (Icons.trending_up, l10n.onboardingPointProgress),
            (Icons.emoji_events_outlined, l10n.onboardingPointAchievements),
            (Icons.lock_outline, l10n.onboardingPointPrivacy),
          ])
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, color: theme.colorScheme.primary),
                  const SizedBox(width: 12),
                  Expanded(child: Text(text, style: theme.textTheme.bodyLarge)),
                ],
              ),
            ),
        ],
      ),
      _Step(
        icon: Icons.place_outlined,
        title: l10n.onboardingPlaceTitle,
        children: [
          Text(l10n.onboardingPlaceText, style: theme.textTheme.bodyLarge),
          const SizedBox(height: 16),
          for (final (place, icon, title, text) in [
            (
              TrainingPlace.gym,
              Icons.fitness_center,
              l10n.placeGym,
              l10n.placeGymText,
            ),
            (TrainingPlace.home, Icons.home_outlined, l10n.placeHome, l10n.placeHomeText),
            (
              TrainingPlace.both,
              Icons.swap_horiz,
              l10n.placeBoth,
              l10n.placeBothText,
            ),
            (null, Icons.edit_note, l10n.placeOwn, l10n.placeOwnText),
          ])
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Card(
                color: _place == place
                    ? theme.colorScheme.primaryContainer
                    : null,
                child: ListTile(
                  leading: Icon(icon),
                  title: Text(title),
                  subtitle: Text(text),
                  trailing: _place == place
                      ? const Icon(Icons.check_circle)
                      : null,
                  onTap: () => setState(() => _place = place),
                ),
              ),
            ),
        ],
      ),
      _Step(
        icon: Icons.event_available_outlined,
        title: l10n.onboardingDaysTitle,
        children: [
          Text(l10n.onboardingDaysText, style: theme.textTheme.bodyLarge),
          const SizedBox(height: 16),
          WeekdayPicker(
            selected: _days,
            onChanged: (d) => setState(() => _days = d),
          ),
          const SizedBox(height: 16),
          if (Reminders.supported)
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.settingsReminders),
              subtitle: Text(l10n.onboardingRemindText),
              value: _remind && _days.isNotEmpty,
              onChanged: _days.isEmpty
                  ? null
                  : (v) => setState(() => _remind = v),
            ),
        ],
      ),
    ];
    final last = _page == pages.length - 1;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pages,
                onPageChanged: (i) => setState(() => _page = i),
                children: pages,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var i = 0; i < pages.length; i++)
                        Container(
                          width: i == _page ? 20 : 8,
                          height: 8,
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          decoration: BoxDecoration(
                            color: i == _page
                                ? theme.colorScheme.primary
                                : theme.colorScheme.outlineVariant,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                    ),
                    onPressed: _saving ? null : (last ? _finish : _next),
                    child: Text(last ? l10n.onboardingStart : l10n.commonContinue),
                  ),
                  if (_page == 0)
                    TextButton(
                      onPressed: () => restoreBackup(context),
                      child: Text(l10n.onboardingRestore),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({
    required this.icon,
    required this.title,
    required this.children,
  });

  final IconData icon;
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
      children: [
        Icon(icon, size: 56, color: theme.colorScheme.primary),
        const SizedBox(height: 16),
        Text(title, style: theme.textTheme.headlineMedium),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }
}
