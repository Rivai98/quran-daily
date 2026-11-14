import 'package:flutter/material.dart';

import '../../../../core/localization/arabic_strings.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/design_system/app_typography.dart';
import '../widgets/state_panel.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  double textSize = 1.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(ArabicStrings.settingsTitle)),
      body: ListView(
        padding: AppSpacing.screen,
        children: [
          Card(
            child: Padding(
              padding: AppSpacing.card,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ArabicStrings.textSizeLabel,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Slider(
                    value: textSize,
                    min: 0.85,
                    max: 1.4,
                    divisions: 5,
                    label: '${(textSize * 100).round()}%',
                    onChanged: (value) => setState(() => textSize = value),
                  ),
                  Text(
                    '${ArabicStrings.part2} - ${ArabicStrings.partRange2}',
                    style: AppTypography.quranLabel,
                    textScaler: TextScaler.linear(textSize),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          const StatePanel(
            icon: Icons.storage,
            title: ArabicStrings.cacheStatusTitle,
            message: ArabicStrings.selectedGroupCache,
          ),
          const SizedBox(height: AppSpacing.sm),
          const StatePanel(
            icon: Icons.format_textdirection_r_to_l,
            title: ArabicStrings.settingsTitle,
            message: ArabicStrings.rtlStatus,
          ),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.logout),
            label: const Text(ArabicStrings.signOut),
          ),
        ],
      ),
    );
  }
}
