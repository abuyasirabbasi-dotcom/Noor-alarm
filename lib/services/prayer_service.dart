import 'package:adhan_dart/adhan_dart.dart' as adhan;

import '../models/prayer.dart';

class PrayerService {
  static adhan.CalculationParameters _params(CalcMethod m) {
    switch (m) {
      case CalcMethod.karachi:
        return adhan.CalculationMethodParameters.karachi();
      case CalcMethod.mwl:
        return adhan.CalculationMethodParameters.muslimWorldLeague();
      case CalcMethod.egyptian:
        return adhan.CalculationMethodParameters.egyptian();
      case CalcMethod.ummAlQura:
        return adhan.CalculationMethodParameters.ummAlQura();
      case CalcMethod.isna:
        return adhan.CalculationMethodParameters.northAmerica();
    }
  }

  /// Prayer times for the calendar day of [day], as real instants converted
  /// to the phone's local time zone.
  static Map<PrayerName, DateTime> timesFor({
    required DateTime day,
    required Place place,
    required CalcMethod method,
    required AsrMadhab madhab,
  }) {
    final params = _params(method);
    params.madhab =
        madhab == AsrMadhab.hanafi ? adhan.Madhab.hanafi : adhan.Madhab.shafi;
    final pt = adhan.PrayerTimes(
      coordinates: adhan.Coordinates(place.lat, place.lng),
      date: DateTime(day.year, day.month, day.day),
      calculationParameters: params,
      precision: true,
    );
    return {
      PrayerName.fajr: pt.fajr.toLocal(),
      PrayerName.sunrise: pt.sunrise.toLocal(),
      PrayerName.dhuhr: pt.dhuhr.toLocal(),
      PrayerName.asr: pt.asr.toLocal(),
      PrayerName.maghrib: pt.maghrib.toLocal(),
      PrayerName.isha: pt.isha.toLocal(),
    };
  }

  /// The clock time to show for [instant] at [place]. Preset cities show their
  /// own local clock; a GPS position uses the phone's time zone.
  static DateTime wallClock(DateTime instant, Place place) {
    final off = place.utcOffsetMinutes;
    if (off == null) return instant.toLocal();
    return instant.toUtc().add(Duration(minutes: off));
  }
}
