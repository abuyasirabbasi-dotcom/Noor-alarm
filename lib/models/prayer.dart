enum PrayerName { fajr, sunrise, dhuhr, asr, maghrib, isha }

enum CalcMethod { karachi, mwl, egyptian, ummAlQura, isna }

enum AsrMadhab { shafi, hanafi }

T enumByName<T extends Enum>(List<T> values, String? name, T fallback) {
  for (final v in values) {
    if (v.name == name) return v;
  }
  return fallback;
}

/// A place used to calculate prayer times.
/// [nameKey] is a translation key (empty for a GPS position).
/// [utcOffsetMinutes] is used only to display the clock of a preset city;
/// null means "use the phone's own time zone".
class Place {
  const Place({
    required this.nameKey,
    required this.lat,
    required this.lng,
    this.utcOffsetMinutes,
  });

  final String nameKey;
  final double lat;
  final double lng;
  final int? utcOffsetMinutes;

  Map<String, dynamic> toJson() => {
        'k': nameKey,
        'lat': lat,
        'lng': lng,
        'off': utcOffsetMinutes,
      };

  factory Place.fromJson(Map<String, dynamic> j) => Place(
        nameKey: (j['k'] as String?) ?? '',
        lat: (j['lat'] as num).toDouble(),
        lng: (j['lng'] as num).toDouble(),
        utcOffsetMinutes: (j['off'] as num?)?.toInt(),
      );
}

const List<Place> kPresetPlaces = [
  Place(nameKey: 'c_karachi', lat: 24.8607, lng: 67.0011, utcOffsetMinutes: 300),
  Place(nameKey: 'c_lahore', lat: 31.5497, lng: 74.3436, utcOffsetMinutes: 300),
  Place(nameKey: 'c_islamabad', lat: 33.6844, lng: 73.0479, utcOffsetMinutes: 300),
  Place(nameKey: 'c_peshawar', lat: 34.0151, lng: 71.5249, utcOffsetMinutes: 300),
  Place(nameKey: 'c_quetta', lat: 30.1798, lng: 66.9750, utcOffsetMinutes: 300),
  Place(nameKey: 'c_makkah', lat: 21.3891, lng: 39.8579, utcOffsetMinutes: 180),
  Place(nameKey: 'c_madinah', lat: 24.4686, lng: 39.6142, utcOffsetMinutes: 180),
  Place(nameKey: 'c_riyadh', lat: 24.7136, lng: 46.6753, utcOffsetMinutes: 180),
  Place(nameKey: 'c_dubai', lat: 25.2048, lng: 55.2708, utcOffsetMinutes: 240),
];
