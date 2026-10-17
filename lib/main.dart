import 'package:alarm/alarm.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'state/app_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final state = AppState();
  await state.load(); // also initialises the alarm plugin

  Alarm.ringing.listen((alarmSet) {
    state.handleRinging(alarmSet.alarms.map((a) => a.id).toList());
  });

  runApp(NoorAlarmApp(state: state));

  // Give a ringing alarm (app opened by the alarm itself) time to be detected
  // before alarms are re-scheduled.
  Future.delayed(const Duration(milliseconds: 1500), state.rescheduleAll);
}
