import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'screens/home_screen.dart';
import 'screens/ring_screen.dart';
import 'state/app_state.dart';

class NoorAlarmApp extends StatefulWidget {
  const NoorAlarmApp({super.key, required this.state});

  final AppState state;

  @override
  State<NoorAlarmApp> createState() => _NoorAlarmAppState();
}

class _NoorAlarmAppState extends State<NoorAlarmApp> with WidgetsBindingObserver {
  final GlobalKey<NavigatorState> _navKey = GlobalKey<NavigatorState>();
  Route<void>? _ringRoute;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.state.addListener(_syncRingScreen);
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncRingScreen());
  }

  @override
  void dispose() {
    widget.state.removeListener(_syncRingScreen);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState lifecycle) {
    if (lifecycle == AppLifecycleState.resumed) {
      widget.state.rescheduleAll();
    }
  }

  /// Shows the full-screen ring screen on top of everything while an alarm
  /// is ringing, and removes it afterwards.
  void _syncRingScreen() {
    final nav = _navKey.currentState;
    if (nav == null) return;
    final ringing = widget.state.ringingId != null;
    if (ringing && _ringRoute == null) {
      final route = MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => RingScreen(state: widget.state),
      );
      _ringRoute = route;
      nav.push(route);
    } else if (!ringing && _ringRoute != null) {
      final route = _ringRoute!;
      _ringRoute = null;
      if (route.isActive) nav.removeRoute(route);
    }
  }

  ThemeData _theme(Brightness brightness) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF0B6B4F),
        brightness: brightness,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.state,
      builder: (context, _) {
        return MaterialApp(
          navigatorKey: _navKey,
          debugShowCheckedModeBanner: false,
          title: 'Noor Alarm',
          locale: Locale(widget.state.languageCode),
          supportedLocales: const [Locale('en'), Locale('ur'), Locale('ar')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: _theme(Brightness.light),
          darkTheme: _theme(Brightness.dark),
          home: HomeScreen(state: widget.state),
        );
      },
    );
  }
}
