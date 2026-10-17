import 'package:flutter/services.dart';

/// One selectable alarm sound.
/// The audio file must live in assets/audio/ and be named "<basename>.<ext>"
/// (any of mp3, wav, m4a, ogg, aac).
class Ringtone {
  const Ringtone(this.id, this.basename, {this.islamic = false});

  final String id;
  final String basename;
  final bool islamic;

  String get nameKey => 'rt_$id';
}

const List<Ringtone> kRingtones = [
  Ringtone('soft_chime', 'soft_chime'),
  Ringtone('rising_bells', 'rising_bells'),
  Ringtone('classic_beep', 'classic_beep'),
  Ringtone('azan_makkah', 'azan_makkah', islamic: true),
  Ringtone('azan_madinah', 'azan_madinah', islamic: true),
  Ringtone('takbeer', 'takbeer', islamic: true),
  Ringtone('quran_recitation', 'quran_recitation', islamic: true),
  Ringtone('morning_dua', 'morning_dua', islamic: true),
];

class RingtoneCatalog {
  static const _fallbackId = 'soft_chime';
  static Set<String> _assets = {};

  /// Reads which audio files were actually bundled with the app.
  static Future<void> load() async {
    try {
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      _assets = manifest.listAssets().toSet();
    } catch (_) {
      _assets = {};
    }
  }

  static String? _pathFor(Ringtone r) {
    final prefix = 'assets/audio/${r.basename}.';
    for (final a in _assets) {
      if (a.startsWith(prefix)) return a;
    }
    return null;
  }

  static bool isAvailable(Ringtone r) => _pathFor(r) != null;

  static Ringtone byId(String id) {
    for (final r in kRingtones) {
      if (r.id == id) return r;
    }
    return kRingtones.first;
  }

  /// Asset path for [id], falling back to the built-in chime if the file is
  /// not bundled (e.g. an Islamic ringtone that has not been added yet).
  static String assetPathFor(String id) {
    final wanted = _pathFor(byId(id));
    if (wanted != null) return wanted;
    return _pathFor(byId(_fallbackId)) ?? 'assets/audio/soft_chime.wav';
  }
}
