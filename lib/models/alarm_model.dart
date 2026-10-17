import 'prayer.dart';

enum MissionType { none, math, shake }

class AlarmModel {
  AlarmModel({
    required this.id,
    this.hour = 6,
    this.minute = 0,
    this.label = '',
    this.enabled = true,
    Set<int>? repeatDays,
    this.ringtoneId = 'soft_chime',
    this.mission = MissionType.none,
    this.vibrate = true,
    this.volume = 0.8,
    this.prayer,
    this.offsetMinutes = 0,
    this.scheduledMs,
  }) : repeatDays = repeatDays ?? <int>{};

  final int id;
  int hour;
  int minute;
  String label;
  bool enabled;

  /// DateTime.monday (1) .. DateTime.sunday (7). Empty means "ring once".
  Set<int> repeatDays;
  String ringtoneId;
  MissionType mission;
  bool vibrate;
  double volume;

  /// When set, the alarm follows this prayer time instead of [hour]:[minute].
  PrayerName? prayer;

  /// Minutes added to the prayer time (negative = before the prayer).
  int offsetMinutes;

  /// Epoch milliseconds of the next time this alarm was scheduled to ring.
  int? scheduledMs;

  bool get isPrayer => prayer != null;
  bool get repeats => repeatDays.isNotEmpty;

  AlarmModel copy() => AlarmModel(
        id: id,
        hour: hour,
        minute: minute,
        label: label,
        enabled: enabled,
        repeatDays: {...repeatDays},
        ringtoneId: ringtoneId,
        mission: mission,
        vibrate: vibrate,
        volume: volume,
        prayer: prayer,
        offsetMinutes: offsetMinutes,
        scheduledMs: scheduledMs,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'hour': hour,
        'minute': minute,
        'label': label,
        'enabled': enabled,
        'days': repeatDays.toList(),
        'ringtone': ringtoneId,
        'mission': mission.name,
        'vibrate': vibrate,
        'volume': volume,
        'prayer': prayer?.name,
        'offset': offsetMinutes,
        'scheduled': scheduledMs,
      };

  factory AlarmModel.fromJson(Map<String, dynamic> j) {
    final prayerName = j['prayer'] as String?;
    return AlarmModel(
      id: (j['id'] as num).toInt(),
      hour: (j['hour'] as num?)?.toInt() ?? 6,
      minute: (j['minute'] as num?)?.toInt() ?? 0,
      label: (j['label'] as String?) ?? '',
      enabled: (j['enabled'] as bool?) ?? true,
      repeatDays: ((j['days'] as List?) ?? const [])
          .map((e) => (e as num).toInt())
          .toSet(),
      ringtoneId: (j['ringtone'] as String?) ?? 'soft_chime',
      mission: enumByName(MissionType.values, j['mission'] as String?, MissionType.none),
      vibrate: (j['vibrate'] as bool?) ?? true,
      volume: (j['volume'] as num?)?.toDouble() ?? 0.8,
      prayer: prayerName == null
          ? null
          : enumByName(PrayerName.values, prayerName, PrayerName.fajr),
      offsetMinutes: (j['offset'] as num?)?.toInt() ?? 0,
      scheduledMs: (j['scheduled'] as num?)?.toInt(),
    );
  }
}
