import 'package:flutter/material.dart';

import '../../app/services.dart';
import '../../data/settings.dart';
import '../../domain/schedule.dart';
import '../../l10n/l10n.dart';
import '../../services/reminders.dart';
import '../../widgets/common.dart';
import '../../widgets/labels.dart';
import 'backup_section.dart';

/// Einstellungen: Trainingstage, Erinnerung, Pausen-Timer, Daten.
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final s = context.services;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: StreamBuilder<Map<String, String>>(
        stream: s.settings.watchAll(),
        builder: (context, snapshot) {
          final map = snapshot.data;
          if (map == null) return const SizedBox.shrink();
          final days = Schedule.parseWeekdays(map[SettingKeys.trainingDays]);
          final goal = map.number(
            SettingKeys.weeklyGoal,
            days.isEmpty ? 2 : days.length,
          );
          final reminders = map.flag(SettingKeys.remindersEnabled);
          final minutes = map.number(
            SettingKeys.reminderMinutes,
            Settings.defaultReminderMinutes,
          );
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
            children: [
              SectionTitle(l10n.settingsTraining),
              PaddedCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.settingsDays,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    WeekdayPicker(
                      selected: days,
                      onChanged: (d) => s.settings.set(
                        SettingKeys.trainingDays,
                        Schedule.formatWeekdays(d),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            l10n.settingsWeeklyGoal,
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                        ),
                        IconButton(
                          tooltip: '−',
                          icon: const Icon(Icons.remove),
                          onPressed: goal > 1
                              ? () => s.settings.set(
                                  SettingKeys.weeklyGoal,
                                  '${goal - 1}',
                                )
                              : null,
                        ),
                        Text(
                          l10n.settingsPerWeek(goal),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        IconButton(
                          tooltip: '+',
                          icon: const Icon(Icons.add),
                          onPressed: goal < 7
                              ? () => s.settings.set(
                                  SettingKeys.weeklyGoal,
                                  '${goal + 1}',
                                )
                              : null,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Column(
                  children: [
                    SwitchListTile(
                      secondary: const Icon(Icons.notifications_outlined),
                      title: Text(l10n.settingsReminders),
                      subtitle: Text(
                        days.isEmpty
                            ? l10n.settingsRemindersNoDays
                            : l10n.settingsRemindersText,
                      ),
                      value: reminders,
                      onChanged: !Reminders.supported
                          ? null
                          : (v) async {
                              if (v) await s.reminders.requestPermission();
                              await s.settings.setFlag(
                                SettingKeys.remindersEnabled,
                                v,
                              );
                            },
                    ),
                    ListTile(
                      enabled: reminders,
                      leading: const Icon(Icons.schedule),
                      title: Text(l10n.settingsReminderTime),
                      trailing: Text(
                        MaterialLocalizations.of(context).formatTimeOfDay(
                          TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60),
                          alwaysUse24HourFormat: MediaQuery.of(
                            context,
                          ).alwaysUse24HourFormat,
                        ),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      onTap: () async {
                        final t = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay(
                            hour: minutes ~/ 60,
                            minute: minutes % 60,
                          ),
                        );
                        if (t == null) return;
                        await s.settings.set(
                          SettingKeys.reminderMinutes,
                          '${t.hour * 60 + t.minute}',
                        );
                      },
                    ),
                    SwitchListTile(
                      secondary: const Icon(Icons.timer_outlined),
                      title: Text(l10n.workoutRestTimer),
                      subtitle: Text(l10n.settingsRestTimerText),
                      value: map.flag(SettingKeys.restTimer, fallback: true),
                      onChanged: (v) =>
                          s.settings.setFlag(SettingKeys.restTimer, v),
                    ),
                  ],
                ),
              ),
              SectionTitle(l10n.settingsData),
              const PaddedCard(child: BackupSection()),
              SectionTitle(l10n.settingsPrivacy),
              PaddedCard(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.lock_outline,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Text(l10n.settingsPrivacyText)),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Wochentage Mo … So zum An-/Abwählen.
class WeekdayPicker extends StatelessWidget {
  const WeekdayPicker({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final Set<int> selected;
  final ValueChanged<Set<int>> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (var d = 1; d <= 7; d++)
          FilterChip(
            showCheckmark: false,
            label: Text(l10n.weekdayShort(d)),
            selected: selected.contains(d),
            onSelected: (v) {
              final next = {...selected};
              v ? next.add(d) : next.remove(d);
              onChanged(next);
            },
          ),
      ],
    );
  }
}
