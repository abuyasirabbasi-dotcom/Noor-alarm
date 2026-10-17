import 'package:alarm/alarm.dart';

import '../l10n/strings.dart';
import '../models/alarm_model.dart';
import '../models/prayer.dart';
import '../models/ringtone.dart';

/// Plugin ids at or above this value are "snooze" copies of alarm (id - base).
const int kSnoozeBase = 1000000;

typedef PrayerTimesProvider = Map<PrayerName, DateTime> Function(DateTime day);

/// Talks to the `alarm` plugin and works out when each alarm should ring.
class AlarmService {
  AlarmService({required this.prayerTimes, required this.language});

  final PrayerTimesProvider prayerTimes;
  final String Function() language;

  Future<void> init() => Alarm.init();

  DateTime? _timeOn(AlarmModel a, DateTime day) {
    if (a.prayer == null) {
      return DateTime(day.year, day.month, day.day, a.hour, a.minute);
    }
    final t = prayerTimes(day)[a.prayer];
    return t?.add(Duration(minutes: a.offsetMinutes));
  }

  /// Next moment this alarm should ring after [now], or null.
  DateTime? nextFire(AlarmModel a, DateTime now) {
    for (var d = 0; d < 9; d++) {
      final day = DateTime(now.year, now.month, now.day + d);
      if (a.repeats && !a.repeatDays.contains(day.weekday)) continue;
      final t = _timeOn(a, day);
      if (t != null && t.isAfter(now)) return t;
    }
    return null;
  }

  AlarmSettings _settings(int pluginId, AlarmModel a, DateTime when) {
    final lang = language();
    final body = a.label.isNotEmpty
        ? a.label
        : (a.prayer != null
            ? Strings.of(lang, a.prayer!.name)
            : Strings.of(lang, 'app_name'));
    return AlarmSettings(
      id: pluginId,
      dateTime: when,
      assetAudioPath: RingtoneCatalog.assetPathFor(a.ringtoneId),
      loopAudio: true,
      vibrate: a.vibrate,
      androidFullScreenIntent: true,
      volumeSettings: VolumeSettings.fade(
        volume: a.volume,
        fadeDuration: const Duration(seconds: 6),
        volumeEnforced: a.mission != MissionType.none,
      ),
      notificationSettings: NotificationSettings(
        title: Strings.of(lang, 'wake_up'),
        body: body,
        // With a mission there is no "Stop" button, so it cannot be skipped.
        stopButton:
            a.mission == MissionType.none ? Strings.of(lang, 'stop') : null,
      ),
    );
  }

  /// Schedules (or cancels) the next ring of [a] and remembers the time.
  Future<void> schedule(AlarmModel a) async {
    if (!a.enabled) {
      await Alarm.stop(a.id);
      a.scheduledMs = null;
      return;
    }
    final when = nextFire(a, DateTime.now());
    if (when == null) {
      a.scheduledMs = null;
      return;
    }
    await Alarm.set(alarmSettings: _settings(a.id, a, when));
    a.scheduledMs = when.millisecondsSinceEpoch;
  }

  Future<void> scheduleSnooze(AlarmModel a, Duration after) async {
    final when = DateTime.now().add(after);
    await Alarm.set(alarmSettings: _settings(kSnoozeBase + a.id, a, when));
  }

  Future<void> stop(int pluginId) => Alarm.stop(pluginId);

  Future<void> cancel(AlarmModel a) async {
    await Alarm.stop(a.id);
    await Alarm.stop(kSnoozeBase + a.id);
  }
}
