import 'package:hijri/hijri_calendar.dart';

class IslamicEvent {
  const IslamicEvent(this.month, this.day, this.key);
  final int month;
  final int day;
  final String key;
}

const List<IslamicEvent> kIslamicEvents = [
  IslamicEvent(1, 1, 'ev_new_year'),
  IslamicEvent(1, 10, 'ev_ashura'),
  IslamicEvent(3, 12, 'ev_mawlid'),
  IslamicEvent(7, 27, 'ev_isra'),
  IslamicEvent(8, 15, 'ev_baraat'),
  IslamicEvent(9, 1, 'ev_ramadan'),
  IslamicEvent(9, 27, 'ev_qadr'),
  IslamicEvent(10, 1, 'ev_eid_fitr'),
  IslamicEvent(12, 9, 'ev_arafah'),
  IslamicEvent(12, 10, 'ev_eid_adha'),
];

class HijriDay {
  const HijriDay(this.year, this.month, this.day);
  final int year;
  final int month;
  final int day;
}

class UpcomingEvent {
  const UpcomingEvent(this.gregorian, this.hijri, this.event);
  final DateTime gregorian;
  final HijriDay hijri;
  final IslamicEvent event;
}

/// Hijri helpers. [offset] shifts the Hijri date by whole days to follow the
/// local moon sighting (the user sets it in Settings).
class HijriService {
  static HijriDay fromGregorian(DateTime date, int offset) {
    final h = HijriCalendar.fromDate(date.add(Duration(days: offset)));
    return HijriDay(h.hYear, h.hMonth, h.hDay);
  }

  static int daysInMonth(int year, int month) {
    return HijriCalendar().getDaysInMonth(year, month);
  }

  /// Gregorian date (midnight) of a given Hijri day.
  static DateTime toGregorian(int year, int month, int day, int offset) {
    final g = HijriCalendar().hijriToGregorian(year, month, day);
    return DateTime(g.year, g.month, g.day).subtract(Duration(days: offset));
  }

  static IslamicEvent? eventOn(int month, int day) {
    for (final e in kIslamicEvents) {
      if (e.month == month && e.day == day) return e;
    }
    return null;
  }

  static List<UpcomingEvent> upcoming(DateTime now, int offset, {int limit = 6}) {
    final result = <UpcomingEvent>[];
    for (var i = 0; i < 400 && result.length < limit; i++) {
      final g = DateTime(now.year, now.month, now.day + i);
      final h = fromGregorian(g, offset);
      final e = eventOn(h.month, h.day);
      if (e != null) result.add(UpcomingEvent(g, h, e));
    }
    return result;
  }
}
