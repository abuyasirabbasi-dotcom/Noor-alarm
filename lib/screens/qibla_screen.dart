import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';

import '../l10n/strings.dart';
import '../services/qibla.dart';
import '../state/app_state.dart';

class QiblaScreen extends StatelessWidget {
  const QiblaScreen({super.key, required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bearing = qiblaBearing(state.place.lat, state.place.lng);
    final stream = FlutterCompass.events;

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('qibla'))),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: stream == null
            ? Center(child: Text(context.tr('compass_unavailable')))
            : StreamBuilder<CompassEvent>(
                stream: stream,
                builder: (context, snapshot) {
                  final heading = snapshot.data?.heading;
                  if (snapshot.hasError || (snapshot.connectionState != ConnectionState.waiting && heading == null)) {
                    return Center(child: Text(context.tr('compass_unavailable')));
                  }
                  if (heading == null) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  var diff = (bearing - heading) % 360;
                  if (diff < 0) diff += 360;
                  final aligned = diff < 5 || diff > 355;
                  final color = aligned ? theme.colorScheme.primary : theme.colorScheme.outline;
                  return Column(
                    children: [
                      Text(
                        context.tr('qibla_bearing', {'d': bearing.toStringAsFixed(0)}),
                        style: theme.textTheme.titleMedium,
                      ),
                      const Spacer(),
                      Container(
                        width: 260,
                        height: 260,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: color, width: 4),
                        ),
                        child: Transform.rotate(
                          angle: diff * pi / 180,
                          child: Icon(Icons.navigation, size: 140, color: color),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        aligned ? context.tr('qibla_aligned') : '',
                        style: theme.textTheme.titleLarge?.copyWith(color: color),
                      ),
                      const Spacer(),
                      Text(
                        context.tr('qibla_hint'),
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  );
                },
              ),
      ),
    );
  }
}
