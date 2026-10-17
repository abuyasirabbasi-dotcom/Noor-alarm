import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import '../models/alarm_model.dart';
import '../state/app_state.dart';
import 'alarm_edit_screen.dart';

/// "Mon · Wed" / "Every day" / "Once"
String repeatSummary(BuildContext context, AlarmModel a) {
  if (a.repeatDays.isEmpty) return context.tr('once');
  if (a.repeatDays.length == 7) return context.tr('every_day');
  final days = a.repeatDays.toList()..sort();
  return days.map((d) => context.tr('d$d')).join(' · ');
}

String formatClock(BuildContext context, DateTime t) {
  return TimeOfDay.fromDateTime(t).format(context);
}

class AlarmsTab extends StatelessWidget {
  const AlarmsTab({super.key, required this.state});

  final AppState state;

  void _openEditor(BuildContext context, AlarmModel? alarm) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AlarmEditScreen(state: state, alarm: alarm),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        final lang = Localizations.localeOf(context).languageCode;
        final next = state.nextAlarm();
        int minuteOfDay(AlarmModel a) {
          final t = a.enabled ? state.nextFireOf(a) : null;
          return t != null ? t.hour * 60 + t.minute : a.hour * 60 + a.minute;
        }

        final alarms = [...state.alarms]
          ..sort((a, b) => minuteOfDay(a).compareTo(minuteOfDay(b)));

        return Scaffold(
          appBar: AppBar(title: Text(context.tr('tab_alarms'))),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _openEditor(context, null),
            icon: const Icon(Icons.add),
            label: Text(context.tr('add_alarm')),
          ),
          body: alarms.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      context.tr('no_alarms'),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        next == null
                            ? context.tr('no_next')
                            : context.tr('next_alarm', {
                                't': formatDuration(
                                  lang,
                                  next.value.difference(DateTime.now()),
                                ),
                              }),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    for (final a in alarms) _AlarmCard(
                      state: state,
                      alarm: a,
                      onTap: () => _openEditor(context, a),
                    ),
                  ],
                ),
        );
      },
    );
  }
}

class _AlarmCard extends StatelessWidget {
  const _AlarmCard({
    required this.state,
    required this.alarm,
    required this.onTap,
  });

  final AppState state;
  final AlarmModel alarm;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final next = alarm.enabled ? state.nextFireOf(alarm) : null;
    final shown = next ??
        DateTime(2000, 1, 1, alarm.hour, alarm.minute);
    String title;
    if (alarm.isPrayer) {
      title = context.tr(alarm.prayer!.name);
      if (alarm.offsetMinutes != 0) {
        final sign = alarm.offsetMinutes > 0 ? '+' : '';
        title = '$title ($sign${alarm.offsetMinutes})';
      }
    } else {
      title = alarm.label.isEmpty ? context.tr('app_name') : alarm.label;
    }
    final dim = !alarm.enabled;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      alarm.isPrayer && next == null
                          ? '--:--'
                          : formatClock(context, shown),
                      style: theme.textTheme.displaySmall?.copyWith(
                        color: dim ? theme.disabledColor : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(title, style: theme.textTheme.titleMedium),
                    Text(
                      alarm.mission == MissionType.none
                          ? repeatSummary(context, alarm)
                          : '${repeatSummary(context, alarm)}  ·  ${context.tr(alarm.mission == MissionType.math ? 'mission_math' : 'mission_shake')}',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Switch(
                value: alarm.enabled,
                onChanged: (v) => state.setEnabled(alarm, v),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
