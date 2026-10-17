import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import '../services/hijri_service.dart';
import '../state/app_state.dart';

class CalendarTab extends StatefulWidget {
  const CalendarTab({super.key, required this.state});

  final AppState state;

  @override
  State<CalendarTab> createState() => _CalendarTabState();
}

class _CalendarTabState extends State<CalendarTab> {
  late int _year;
  late int _month;
  bool _initialised = false;

  void _ensureInit() {
    if (_initialised) return;
    final today = HijriService.fromGregorian(DateTime.now(), widget.state.hijriOffset);
    _year = today.year;
    _month = today.month;
    _initialised = true;
  }

  void _shift(int delta) {
    setState(() {
      _month += delta;
      if (_month > 12) {
        _month = 1;
        _year++;
      } else if (_month < 1) {
        _month = 12;
        _year--;
      }
    });
  }

  void _showDay(BuildContext context, int day, DateTime greg, IslamicEvent? event) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('$day ${ctx.tr('m$_month')} $_year'),
        content: Text(
          MaterialLocalizations.of(ctx).formatFullDate(greg) +
              (event != null ? '\n\n${ctx.tr(event.key)}' : ''),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(ctx.tr('cancel')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.state,
      builder: (context, _) {
        _ensureInit();
        final theme = Theme.of(context);
        final lang = Localizations.localeOf(context).languageCode;
        final offset = widget.state.hijriOffset;
        final now = DateTime.now();
        final todayH = HijriService.fromGregorian(now, offset);
        final rtl = Directionality.of(context) == TextDirection.rtl;

        final daysInMonth = HijriService.daysInMonth(_year, _month);
        final first = HijriService.toGregorian(_year, _month, 1, offset);
        final leading = first.weekday % 7; // Sunday = 0
        final todayDate = DateTime(now.year, now.month, now.day);

        final cells = <Widget>[];
        for (var i = 0; i < leading; i++) {
          cells.add(const SizedBox.shrink());
        }
        for (var d = 1; d <= daysInMonth; d++) {
          final greg = DateTime(first.year, first.month, first.day + d - 1);
          final event = HijriService.eventOn(_month, d);
          final isToday = greg == todayDate;
          cells.add(
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => _showDay(context, d, greg, event),
              child: Container(
                margin: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: isToday ? theme.colorScheme.primary : null,
                  borderRadius: BorderRadius.circular(8),
                  border: event != null
                      ? Border.all(color: theme.colorScheme.tertiary, width: 2)
                      : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$d',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: isToday ? theme.colorScheme.onPrimary : null,
                      ),
                    ),
                    Text(
                      '${greg.day}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: isToday
                            ? theme.colorScheme.onPrimary
                            : theme.colorScheme.outline,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final upcoming = HijriService.upcoming(now, offset);

        return Scaffold(
          appBar: AppBar(title: Text(context.tr('tab_calendar'))),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                color: theme.colorScheme.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Text(context.tr('today'), style: theme.textTheme.titleSmall),
                      const SizedBox(height: 4),
                      Text(
                        '${todayH.day} ${context.tr('m${todayH.month}')} ${todayH.year}',
                        style: theme.textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(MaterialLocalizations.of(context).formatFullDate(now)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  IconButton(
                    icon: Icon(rtl ? Icons.chevron_right : Icons.chevron_left),
                    onPressed: () => _shift(-1),
                  ),
                  Expanded(
                    child: Text(
                      '${context.tr('m$_month')} $_year',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    icon: Icon(rtl ? Icons.chevron_left : Icons.chevron_right),
                    onPressed: () => _shift(1),
                  ),
                ],
              ),
              Row(children: _headerCells(context, theme)),
              GridView.count(
                crossAxisCount: 7,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 0.9,
                children: cells,
              ),
              const SizedBox(height: 16),
              Text(
                context.tr('upcoming_events'),
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              for (final e in upcoming)
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.star_outline),
                    title: Text(context.tr(e.event.key)),
                    subtitle: Text(
                      '${e.hijri.day} ${context.tr('m${e.hijri.month}')} ${e.hijri.year}'
                      '  ·  ${MaterialLocalizations.of(context).formatMediumDate(e.gregorian)}',
                    ),
                    trailing: Text(_daysUntil(lang, now, e.gregorian)),
                  ),
                ),
              const SizedBox(height: 8),
              Text(
                context.tr('hijri_adjust_hint'),
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        );
      },
    );
  }

  String _daysUntil(String lang, DateTime now, DateTime target) {
    final today = DateTime(now.year, now.month, now.day);
    final n = target.difference(today).inDays;
    if (n <= 0) return Strings.of(lang, 'today');
    return Strings.of(lang, 'in_days', {'n': '$n'});
  }

  String _weekdayHeader(BuildContext context, int weekday) {
    return context.tr('d$weekday');
  }

  List<Widget> _headerCells(BuildContext context, ThemeData theme) {
    // Sunday first (weekday 7), then Monday (1) .. Saturday (6).
    const order = [7, 1, 2, 3, 4, 5, 6];
    return [
      for (final d in order)
        Expanded(
          child: Center(
            child: Text(
              _weekdayHeader(context, d),
              style: theme.textTheme.labelSmall,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
    ];
  }
}
