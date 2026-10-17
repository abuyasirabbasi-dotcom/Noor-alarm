import 'dart:convert';
import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/strings.dart';
import '../models/alarm_model.dart';
import '../models/prayer.dart';
import '../models/ringtone.dart';
import '../services/alarm_service.dart';
import '../services/prayer_service.dart';

class AppState extends ChangeNotifier {
  late final SharedPreferences _prefs;
  late final AlarmService _service = AlarmService(
    prayerTimes: prayerTimesFor,
    language: () => languageCode,
  );

  List<AlarmModel> alarms = [];
  String languageCode = 'en';
  int hijriOffset = 0;
  CalcMethod method = CalcMethod.karachi;
  AsrMadhab madhab = AsrMadhab.hanafi;
  Place place = kPresetPlaces.first;

  /// Plugin id of the alarm that is ringing right now (null if none).
  int? ringingId;

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();

    final deviceLang = PlatformDispatcher.instance.locale.languageCode;
    languageCode = _prefs.getString('lang') ??
        (Strings.supported.contains(deviceLang) ? deviceLang : 'en');
    hijriOffset = _prefs.getInt('hijriOffset') ?? 0;
    method = enumByName(CalcMethod.values, _prefs.getString('method'), CalcMethod.karachi);
    madhab = enumByName(AsrMadhab.values, _prefs.getString('madhab'), AsrMadhab.hanafi);

    final placeJson = _prefs.getString('place');
    if (placeJson != null) {
      try {
        place = Place.fromJson(jsonDecode(placeJson) as Map<String, dynamic>);
      } catch (_) {}
    }

    final alarmsJson = _prefs.getString('alarms');
    if (alarmsJson != null) {
      try {
        alarms = (jsonDecode(alarmsJson) as List)
            .map((e) => AlarmModel.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (_) {
        alarms = [];
      }
    }

    await RingtoneCatalog.load();
    await _service.init();
  }

  Future<void> _save() async {
    await _prefs.setString('alarms', jsonEncode(alarms.map((a) => a.toJson()).toList()));
  }

  // ---------------------------------------------------------------- settings

  Future<void> setLanguage(String code) async {
    languageCode = code;
    await _prefs.setString('lang', code);
    notifyListeners();
    await rescheduleAll(); // notification texts use the language
  }

  Future<void> setHijriOffset(int v) async {
    hijriOffset = v.clamp(-2, 2);
    await _prefs.setInt('hijriOffset', hijriOffset);
    notifyListeners();
  }

  Future<void> setMethod(CalcMethod m) async {
    method = m;
    await _prefs.setString('method', m.name);
    notifyListeners();
    await rescheduleAll();
  }

  Future<void> setMadhab(AsrMadhab m) async {
    madhab = m;
    await _prefs.setString('madhab', m.name);
    notifyListeners();
    await rescheduleAll();
  }

  Future<void> setPlace(Place p) async {
    place = p;
    await _prefs.setString('place', jsonEncode(p.toJson()));
    notifyListeners();
    await rescheduleAll();
  }

  /// Returns null on success, or a translation key describing the problem.
  Future<String?> useMyLocation() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return 'location_denied';
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        return 'location_denied';
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 20),
        ),
      );
      await setPlace(Place(nameKey: '', lat: pos.latitude, lng: pos.longitude));
      return null;
    } catch (_) {
      return 'location_denied';
    }
  }

  Future<void> requestPermissions() async {
    try {
      await Permission.notification.request();
      await Permission.scheduleExactAlarm.request();
    } catch (_) {}
  }

  // ------------------------------------------------------------- prayer times

  Map<PrayerName, DateTime> prayerTimesFor(DateTime day) {
    return PrayerService.timesFor(
      day: day,
      place: place,
      method: method,
      madhab: madhab,
    );
  }

  // ------------------------------------------------------------------- alarms

  int newAlarmId() {
    var id = 1;
    for (final a in alarms) {
      if (a.id >= id) id = a.id + 1;
    }
    return id;
  }

  AlarmModel? _byId(int id) {
    for (final a in alarms) {
      if (a.id == id) return a;
    }
    return null;
  }

  DateTime? nextFireOf(AlarmModel a) => _service.nextFire(a, DateTime.now());

  /// The enabled alarm that rings soonest, with its time.
  MapEntry<AlarmModel, DateTime>? nextAlarm() {
    MapEntry<AlarmModel, DateTime>? best;
    for (final a in alarms) {
      if (!a.enabled) continue;
      final t = nextFireOf(a);
      if (t == null) continue;
      if (best == null || t.isBefore(best.value)) best = MapEntry(a, t);
    }
    return best;
  }

  Future<void> upsertAlarm(AlarmModel alarm) async {
    final i = alarms.indexWhere((a) => a.id == alarm.id);
    if (i >= 0) {
      alarms[i] = alarm;
    } else {
      alarms.add(alarm);
    }
    await _service.schedule(alarm);
    await _save();
    notifyListeners();
  }

  Future<void> setEnabled(AlarmModel alarm, bool value) async {
    alarm.enabled = value;
    await _service.schedule(alarm);
    await _save();
    notifyListeners();
  }

  Future<void> deleteAlarm(AlarmModel alarm) async {
    alarms.removeWhere((a) => a.id == alarm.id);
    await _service.cancel(alarm);
    await _save();
    notifyListeners();
  }

  /// Re-computes the next ring of every enabled alarm (prayer times change
  /// daily). Alarms that just fired are left alone so a ringing alarm is not
  /// interrupted.
  Future<void> rescheduleAll() async {
    final now = DateTime.now();
    for (final a in alarms) {
      if (!a.enabled) continue;
      if (ringingId == a.id || ringingId == kSnoozeBase + a.id) continue;
      final sched = a.scheduledMs;
      if (sched != null) {
        final t = DateTime.fromMillisecondsSinceEpoch(sched);
        final justFired = t.isBefore(now) && now.difference(t) < const Duration(minutes: 10);
        if (justFired) continue;
      }
      await _service.schedule(a);
    }
    await _save();
    notifyListeners();
  }

  // ------------------------------------------------------------------ ringing

  /// Called with the ids of the alarms the plugin reports as ringing.
  void handleRinging(List<int> ids) {
    if (ids.isNotEmpty) {
      if (ringingId != ids.first) {
        ringingId = ids.first;
        notifyListeners();
      }
    } else if (ringingId != null) {
      _finishRing(ringingId!);
    }
  }

  AlarmModel? get ringingAlarm {
    final id = ringingId;
    if (id == null) return null;
    return _byId(id >= kSnoozeBase ? id - kSnoozeBase : id);
  }

  Future<void> _finishRing(int pluginId) async {
    ringingId = null;
    notifyListeners();
    final isSnooze = pluginId >= kSnoozeBase;
    final a = _byId(isSnooze ? pluginId - kSnoozeBase : pluginId);
    if (a == null) return;
    if (a.repeats) {
      await _service.schedule(a); // next occurrence
    } else if (!isSnooze) {
      a.enabled = false; // one-time alarm is done
      a.scheduledMs = null;
    }
    await _save();
    notifyListeners();
  }

  Future<void> stopRinging() async {
    final id = ringingId;
    if (id == null) return;
    await _service.stop(id);
    await _finishRing(id);
  }

  Future<void> snoozeRinging() async {
    final id = ringingId;
    if (id == null) return;
    final a = ringingAlarm;
    await _service.stop(id);
    if (a != null) {
      await _service.scheduleSnooze(a, const Duration(minutes: 9));
    }
    await _finishRing(id);
  }
}
