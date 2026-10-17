import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import '../models/prayer.dart';
import '../state/app_state.dart';

class SettingsTab extends StatelessWidget {
  const SettingsTab({super.key, required this.state});

  final AppState state;

  static const Map<CalcMethod, String> _methodKeys = {
    CalcMethod.karachi: 'm_karachi',
    CalcMethod.mwl: 'm_mwl',
    CalcMethod.egyptian: 'm_egypt',
    CalcMethod.ummAlQura: 'm_umm',
    CalcMethod.isna: 'm_isna',
  };

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        final theme = Theme.of(context);
        return Scaffold(
          appBar: AppBar(title: Text(context.tr('tab_settings'))),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(context.tr('language'), style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment<String>(value: 'en', label: Text('English')),
                  ButtonSegment<String>(value: 'ur', label: Text('اردو')),
                  ButtonSegment<String>(value: 'ar', label: Text('العربية')),
                ],
                selected: {state.languageCode},
                onSelectionChanged: (sel) => state.setLanguage(sel.first),
              ),
              const Divider(height: 32),
              Text(context.tr('calc_method'), style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (final m in CalcMethod.values)
                    ChoiceChip(
                      label: Text(context.tr(_methodKeys[m]!)),
                      selected: state.method == m,
                      onSelected: (_) => state.setMethod(m),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Text(context.tr('madhab'), style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              SegmentedButton<AsrMadhab>(
                segments: [
                  ButtonSegment<AsrMadhab>(
                    value: AsrMadhab.hanafi,
                    label: Text(context.tr('hanafi')),
                  ),
                  ButtonSegment<AsrMadhab>(
                    value: AsrMadhab.shafi,
                    label: Text(context.tr('shafi')),
                  ),
                ],
                selected: {state.madhab},
                onSelectionChanged: (sel) => state.setMadhab(sel.first),
              ),
              const Divider(height: 32),
              Text(context.tr('hijri_adjust'), style: theme.textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(context.tr('hijri_adjust_hint'), style: theme.textTheme.bodySmall),
              const SizedBox(height: 8),
              Row(
                children: [
                  IconButton.filledTonal(
                    icon: const Icon(Icons.remove),
                    onPressed: () => state.setHijriOffset(state.hijriOffset - 1),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      '${state.hijriOffset > 0 ? '+' : ''}${state.hijriOffset}',
                      style: theme.textTheme.headlineSmall,
                    ),
                  ),
                  IconButton.filledTonal(
                    icon: const Icon(Icons.add),
                    onPressed: () => state.setHijriOffset(state.hijriOffset + 1),
                  ),
                ],
              ),
              const Divider(height: 32),
              Text(context.tr('permissions'), style: theme.textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(context.tr('permissions_hint'), style: theme.textTheme.bodySmall),
              const SizedBox(height: 8),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: FilledButton.tonal(
                  onPressed: state.requestPermissions,
                  child: Text(context.tr('grant')),
                ),
              ),
              const Divider(height: 32),
              Text(context.tr('about'), style: theme.textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(context.tr('about_text'), style: theme.textTheme.bodyMedium),
            ],
          ),
        );
      },
    );
  }
}
