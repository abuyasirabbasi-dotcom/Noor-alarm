import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import '../state/app_state.dart';
import 'alarms_tab.dart';
import 'calendar_tab.dart';
import 'prayer_tab.dart';
import 'settings_tab.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.state});

  final AppState state;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    // Ask for notification / exact-alarm permission once the app is open.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.state.requestPermissions();
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.state;
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          AlarmsTab(state: s),
          PrayerTab(state: s),
          CalendarTab(state: s),
          SettingsTab(state: s),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.alarm),
            label: context.tr('tab_alarms'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.mosque_outlined),
            selectedIcon: const Icon(Icons.mosque),
            label: context.tr('tab_prayer'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.calendar_month_outlined),
            selectedIcon: const Icon(Icons.calendar_month),
            label: context.tr('tab_calendar'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings),
            label: context.tr('tab_settings'),
          ),
        ],
      ),
    );
  }
}
