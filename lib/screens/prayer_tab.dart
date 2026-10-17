import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import '../models/alarm_model.dart';
import '../models/prayer.dart';
import '../models/ringtone.dart';
import '../services/prayer_service.dart';
import '../state/app_state.dart';
import 'qibla_screen.dart';

class PrayerTab extends StatefulWidget {
  const PrayerTab({super.key, required this.state});

  final AppState state;

  @override
  State<PrayerTab> createState() => _PrayerTabState();
}

class _PrayerTabState extends State<PrayerTab> {
  Timer? _timer;
  DateTime _now = DateTime.now();
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _placeName(BuildContext context) {
    final p = widget.state.place;
    if (p.nameKey.isNotEmpty) return context.tr(p.nameKey);
    return '${context.tr('gps_location')} '
        '(${p.lat.toStringAsFixed(2)}, ${p.lng.toStringAsFixed(2)})';
  }

  Future<void> _useGps() async {
    setState(() => _busy = true);
    final error = await widget.state.useMyLocation();
    if (!mounted) return;
    setState(() => _busy = false);
    if (error != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(context.tr(error))));
    }
  }

  Future<void> _chooseCity() async {
    final chosen = await showModalBottomSheet<Place>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final p in kPresetPlaces)
              ListTile(
                leading: const Icon(Icons.location_city),
                title: Text(ctx.tr(p.nameKey)),
                trailing: widget.state.place.nameKey == p.nameKey
                    ? const Icon(Icons.check)
                    : null,
                onTap: () => Navigator.of(ctx).pop(p),
              ),
          ],
        ),
      ),
    );
    if (chosen != null) await widget.state.setPlace(chosen);
  }

  Future<void> _addAlarmFor(PrayerName prayer) async {
    final s = widget.state;
    final azan = RingtoneCatalog.byId('azan_makkah');
    final alarm = AlarmModel(
      id: s.newAlarmId(),
      prayer: prayer,
      repeatDays: {1, 2, 3, 4, 5, 6, 7},
      ringtoneId: RingtoneCatalog.isAvailable(azan) ? azan.id : 'soft_chime',
    );
    await s.upsertAlarm(alarm);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(context.tr('alarm_added'))));
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.state,
      builder: (context, _) {
        final lang = Localizations.localeOf(context).languageCode;
        final theme = Theme.of(context);
        final s = widget.state;
        final today = s.prayerTimesFor(_now);

        // Next prayer (the sunrise is shown but is not a prayer).
        const prayers = [
          PrayerName.fajr,
          PrayerName.dhuhr,
          PrayerName.asr,
          PrayerName.maghrib,
          PrayerName.isha,
        ];
        PrayerName? next;
        DateTime? nextTime;
        for (final p in prayers) {
          if (today[p]!.isAfter(_now)) {
            next = p;
            nextTime = today[p];
            break;
          }
        }
        if (next == null) {
          final tomorrow = s.prayerTimesFor(_now.add(const Duration(days: 1)));
          next = PrayerName.fajr;
          nextTime = tomorrow[PrayerName.fajr];
        }

        String clock(DateTime t) =>
            TimeOfDay.fromDateTime(PrayerService.wallClock(t, s.place))
                .format(context);

        return Scaffold(
          appBar: AppBar(title: Text(context.tr('tab_prayer'))),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                color: theme.colorScheme.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Text(context.tr('next_prayer'),
                          style: theme.textTheme.titleSmall),
                      const SizedBox(height: 4),
                      Text(context.tr(next.name),
                          style: theme.textTheme.headlineMedium),
                      Text(clock(nextTime!),
                          style: theme.textTheme.displaySmall),
                      const SizedBox(height: 4),
                      Text(
                        formatDuration(lang, nextTime.difference(_now)),
                        style: theme.textTheme.titleMedium,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Column(
                  children: [
                    for (final p in PrayerName.values)
                      ListTile(
                        selected: p == next,
                        title: Text(context.tr(p.name)),
                        subtitle: Text(clock(today[p]!)),
                        trailing: IconButton(
                          tooltip: context.tr('add_alarm'),
                          icon: const Icon(Icons.alarm_add),
                          onPressed: () => _addAlarmFor(p),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.explore),
                  title: Text(context.tr('qibla')),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => QiblaScreen(state: widget.state),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.place_outlined),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${context.tr('location')}: ${_placeName(context)}',
                              style: theme.textTheme.titleMedium,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          FilledButton.icon(
                            onPressed: _busy ? null : _useGps,
                            icon: const Icon(Icons.my_location),
                            label: Text(context.tr('use_my_location')),
                          ),
                          OutlinedButton.icon(
                            onPressed: _chooseCity,
                            icon: const Icon(Icons.location_city),
                            label: Text(context.tr('choose_city')),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
