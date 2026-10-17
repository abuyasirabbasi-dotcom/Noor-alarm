import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../l10n/strings.dart';
import '../models/alarm_model.dart';
import '../state/app_state.dart';

class _Problem {
  const _Problem(this.text, this.answer);
  final String text;
  final int answer;
}

List<_Problem> _makeProblems(int count) {
  final rnd = Random();
  final list = <_Problem>[];
  for (var i = 0; i < count; i++) {
    final kind = rnd.nextInt(3);
    if (kind == 0) {
      final x = 12 + rnd.nextInt(78);
      final y = 12 + rnd.nextInt(78);
      list.add(_Problem('$x + $y', x + y));
    } else if (kind == 1) {
      final x = 50 + rnd.nextInt(50);
      final y = 11 + rnd.nextInt(39);
      list.add(_Problem('$x - $y', x - y));
    } else {
      final x = 3 + rnd.nextInt(10);
      final y = 3 + rnd.nextInt(10);
      list.add(_Problem('$x × $y', x * y));
    }
  }
  return list;
}

/// Full-screen screen shown while an alarm is ringing.
class RingScreen extends StatefulWidget {
  const RingScreen({super.key, required this.state});

  final AppState state;

  @override
  State<RingScreen> createState() => _RingScreenState();
}

class _RingScreenState extends State<RingScreen> {
  static const int _problemCount = 3;
  static const int _shakeTarget = 25;

  late final List<_Problem> _problems = _makeProblems(_problemCount);
  final TextEditingController _answer = TextEditingController();
  int _index = 0;
  bool _wrong = false;
  late DateTime _now = DateTime.now();
  Timer? _ticker;

  StreamSubscription<UserAccelerometerEvent>? _shakeSub;
  int _shakes = 0;
  DateTime _lastShake = DateTime.fromMillisecondsSinceEpoch(0);
  bool _shakeFailed = false;

  @override
  void initState() {
    super.initState();
    if (widget.state.ringingAlarm?.mission == MissionType.shake) {
      _startShake();
    }
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _shakeSub?.cancel();
    _answer.dispose();
    super.dispose();
  }

  void _startShake() {
    try {
      _shakeSub = userAccelerometerEventStream().listen(
        (e) {
          final force = sqrt(e.x * e.x + e.y * e.y + e.z * e.z);
          final now = DateTime.now();
          if (force > 14 &&
              now.difference(_lastShake) > const Duration(milliseconds: 350)) {
            _lastShake = now;
            if (!mounted) return;
            setState(() => _shakes++);
            if (_shakes >= _shakeTarget) {
              _shakeSub?.cancel();
              widget.state.stopRinging();
            }
          }
        },
        onError: (Object _) {
          if (mounted) setState(() => _shakeFailed = true);
        },
        cancelOnError: true,
      );
    } catch (_) {
      _shakeFailed = true;
    }
  }

  Future<void> _check() async {
    final value = int.tryParse(_answer.text.trim());
    if (value == _problems[_index].answer) {
      if (_index == _problemCount - 1) {
        await widget.state.stopRinging();
      } else {
        setState(() {
          _index++;
          _wrong = false;
          _answer.clear();
        });
      }
    } else {
      setState(() {
        _wrong = true;
        _answer.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final alarm = widget.state.ringingAlarm;
    final mission = alarm?.mission ?? MissionType.none;
    final useShake = mission == MissionType.shake && !_shakeFailed;
    final useMath = mission == MissionType.math ||
        (mission == MissionType.shake && _shakeFailed);

    String title = context.tr('wake_up');
    if (alarm != null) {
      if (alarm.label.isNotEmpty) {
        title = alarm.label;
      } else if (alarm.isPrayer) {
        title = context.tr(alarm.prayer!.name);
      }
    }

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: theme.colorScheme.primaryContainer,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight - 48),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                const SizedBox(height: 24),
                Icon(
                  Icons.alarm,
                  size: 56,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
                const SizedBox(height: 12),
                Text(
                  TimeOfDay.fromDateTime(_now).format(context),
                  style: theme.textTheme.displayLarge?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                const Spacer(),
                if (useShake)
                  ..._shakeWidgets(context)
                else if (useMath)
                  ..._missionWidgets(context)
                else
                  ..._buttons(context),
                const Spacer(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _shakeWidgets(BuildContext context) {
    final theme = Theme.of(context);
    return [
      Text(context.tr('shake_to_stop'), style: theme.textTheme.titleLarge),
      const SizedBox(height: 24),
      const Icon(Icons.vibration, size: 96),
      const SizedBox(height: 24),
      LinearProgressIndicator(
        value: (_shakes / _shakeTarget).clamp(0.0, 1.0),
        minHeight: 12,
        borderRadius: BorderRadius.circular(6),
      ),
      const SizedBox(height: 12),
      Text(
        context.tr('shake_count', {'n': '$_shakes', 'total': '$_shakeTarget'}),
        style: theme.textTheme.titleMedium,
      ),
    ];
  }

  List<Widget> _missionWidgets(BuildContext context) {
    final theme = Theme.of(context);
    final p = _problems[_index];
    return [
      Text(context.tr('mission_solve'), style: theme.textTheme.titleMedium),
      const SizedBox(height: 4),
      Text(
        context.tr('problem_n', {'n': '${_index + 1}', 'total': '$_problemCount'}),
        style: theme.textTheme.bodyMedium,
      ),
      const SizedBox(height: 16),
      Directionality(
        textDirection: TextDirection.ltr,
        child: Text(p.text, style: theme.textTheme.displayMedium),
      ),
      const SizedBox(height: 16),
      SizedBox(
        width: 220,
        child: TextField(
          controller: _answer,
          autofocus: true,
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: theme.textTheme.headlineMedium,
          decoration: InputDecoration(
            labelText: context.tr('answer'),
            filled: true,
            border: const OutlineInputBorder(),
            errorText: _wrong ? context.tr('wrong') : null,
          ),
          onSubmitted: (_) => _check(),
        ),
      ),
      const SizedBox(height: 16),
      FilledButton(
        onPressed: _check,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Text(context.tr('check')),
        ),
      ),
    ];
  }

  List<Widget> _buttons(BuildContext context) {
    return [
      SizedBox(
        width: double.infinity,
        height: 64,
        child: FilledButton(
          onPressed: widget.state.stopRinging,
          child: Text(
            context.tr('stop'),
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
      ),
      const SizedBox(height: 16),
      SizedBox(
        width: double.infinity,
        height: 56,
        child: OutlinedButton(
          onPressed: widget.state.snoozeRinging,
          child: Text(context.tr('snooze')),
        ),
      ),
    ];
  }
}
