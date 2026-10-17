import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import '../models/alarm_model.dart';
import '../models/prayer.dart';
import '../models/ringtone.dart';
import '../state/app_state.dart';

class AlarmEditScreen extends StatefulWidget {
  const AlarmEditScreen({super.key, required this.state, this.alarm});

  final AppState state;

  /// null = create a new alarm.
  final AlarmModel? alarm;

  @override
  State<AlarmEditScreen> createState() => _AlarmEditScreenState();
}

class _AlarmEditScreenState extends State<AlarmEditScreen> {
  late final AlarmModel _a;
  late final TextEditingController _label;
  late final bool _isNew;

  @override
  void initState() {
    super.initState();
    _isNew = widget.alarm == null;
    _a = widget.alarm?.copy() ??
        AlarmModel(id: widget.state.newAlarmId(), enabled: true);
    _label = TextEditingController(text: _a.label);
  }

  @override
  void dispose() {
    _label.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _a.hour, minute: _a.minute),
    );
    if (picked != null) {
      setState(() {
        _a.hour = picked.hour;
        _a.minute = picked.minute;
      });
    }
  }

  Future<void> _pickRingtone() async {
    final chosen = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              for (final r in kRingtones)
                ListTile(
                  enabled: RingtoneCatalog.isAvailable(r),
                  leading: Icon(r.islamic ? Icons.mosque : Icons.music_note),
                  title: Text(ctx.tr(r.nameKey)),
                  subtitle: RingtoneCatalog.isAvailable(r)
                      ? null
                      : Text(ctx.tr('ringtone_missing')),
                  trailing: r.id == _a.ringtoneId ? const Icon(Icons.check) : null,
                  onTap: () => Navigator.of(ctx).pop(r.id),
                ),
            ],
          ),
        );
      },
    );
    if (chosen != null) setState(() => _a.ringtoneId = chosen);
  }

  Future<void> _save() async {
    _a.label = _label.text.trim();
    _a.enabled = true;
    await widget.state.upsertAlarm(_a);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    await widget.state.deleteAlarm(_a);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ringtone = RingtoneCatalog.byId(_a.ringtoneId);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr(_isNew ? 'add_alarm' : 'edit_alarm')),
        actions: [
          if (!_isNew)
            IconButton(
              tooltip: context.tr('delete'),
              icon: const Icon(Icons.delete_outline),
              onPressed: _delete,
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SegmentedButton<bool>(
            segments: [
              ButtonSegment<bool>(
                value: false,
                icon: const Icon(Icons.access_time),
                label: Text(context.tr('fixed_time')),
              ),
              ButtonSegment<bool>(
                value: true,
                icon: const Icon(Icons.mosque),
                label: Text(context.tr('prayer_alarm')),
              ),
            ],
            selected: {_a.isPrayer},
            onSelectionChanged: (sel) {
              setState(() {
                if (sel.first) {
                  _a.prayer ??= PrayerName.fajr;
                  if (_a.repeatDays.isEmpty) {
                    _a.repeatDays = {1, 2, 3, 4, 5, 6, 7};
                  }
                } else {
                  _a.prayer = null;
                }
              });
            },
          ),
          const SizedBox(height: 16),
          if (!_a.isPrayer)
            Center(
              child: TextButton(
                onPressed: _pickTime,
                child: Text(
                  TimeOfDay(hour: _a.hour, minute: _a.minute).format(context),
                  style: theme.textTheme.displayMedium,
                ),
              ),
            )
          else ...[
            Text(context.tr('prayer'), style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final p in PrayerName.values)
                  ChoiceChip(
                    label: Text(context.tr(p.name)),
                    selected: _a.prayer == p,
                    onSelected: (_) => setState(() => _a.prayer = p),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(context.tr('offset'), style: theme.textTheme.titleSmall),
            Row(
              children: [
                IconButton.filledTonal(
                  icon: const Icon(Icons.remove),
                  onPressed: () => setState(() {
                    _a.offsetMinutes = (_a.offsetMinutes - 5).clamp(-120, 120);
                  }),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    '${_a.offsetMinutes > 0 ? '+' : ''}${_a.offsetMinutes}',
                    style: theme.textTheme.headlineSmall,
                  ),
                ),
                IconButton.filledTonal(
                  icon: const Icon(Icons.add),
                  onPressed: () => setState(() {
                    _a.offsetMinutes = (_a.offsetMinutes + 5).clamp(-120, 120);
                  }),
                ),
              ],
            ),
            Text(context.tr('offset_hint'), style: theme.textTheme.bodySmall),
          ],
          const SizedBox(height: 20),
          TextField(
            controller: _label,
            decoration: InputDecoration(
              labelText: context.tr('label'),
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          Text(context.tr('repeat'), style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (var d = 1; d <= 7; d++)
                FilterChip(
                  label: Text(context.tr('d$d')),
                  selected: _a.repeatDays.contains(d),
                  onSelected: (on) => setState(() {
                    if (on) {
                      _a.repeatDays.add(d);
                    } else {
                      _a.repeatDays.remove(d);
                    }
                  }),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(context.tr('once'), style: theme.textTheme.bodySmall),
          const Divider(height: 32),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(ringtone.islamic ? Icons.mosque : Icons.music_note),
            title: Text(context.tr('ringtone')),
            subtitle: Text(context.tr(ringtone.nameKey)),
            trailing: const Icon(Icons.chevron_right),
            onTap: _pickRingtone,
          ),
          const SizedBox(height: 8),
          Text(context.tr('mission'), style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          SegmentedButton<MissionType>(
            segments: [
              ButtonSegment<MissionType>(
                value: MissionType.none,
                label: Text(context.tr('mission_none')),
              ),
              ButtonSegment<MissionType>(
                value: MissionType.math,
                icon: const Icon(Icons.calculate),
                label: Text(context.tr('mission_math')),
              ),
              ButtonSegment<MissionType>(
                value: MissionType.shake,
                icon: const Icon(Icons.vibration),
                label: Text(context.tr('mission_shake')),
              ),
            ],
            selected: {_a.mission},
            onSelectionChanged: (sel) => setState(() => _a.mission = sel.first),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(context.tr('vibrate')),
            value: _a.vibrate,
            onChanged: (v) => setState(() => _a.vibrate = v),
          ),
          Text(context.tr('volume'), style: theme.textTheme.titleSmall),
          Slider(
            value: _a.volume,
            min: 0.2,
            max: 1.0,
            divisions: 8,
            onChanged: (v) => setState(() => _a.volume = v),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.check),
            label: Text(context.tr('save')),
          ),
        ],
      ),
    );
  }
}
