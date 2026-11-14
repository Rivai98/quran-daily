import 'package:flutter/material.dart';

import '../../../../core/localization/arabic_strings.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../widgets/public_group_profile_card.dart';
import '../widgets/state_panel.dart';

class PublicGroupDiscoveryScreen extends StatelessWidget {
  const PublicGroupDiscoveryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(ArabicStrings.discoverGroups)),
      body: ListView(
        padding: AppSpacing.screen,
        children: const [
          TextField(
            decoration: InputDecoration(
              labelText: ArabicStrings.searchGroupLabel,
              prefixIcon: Icon(Icons.search),
            ),
          ),
          SizedBox(height: AppSpacing.md),
          PublicGroupProfileCard(),
          SizedBox(height: AppSpacing.md),
          StatePanel(
            icon: Icons.search_off,
            title: ArabicStrings.noPublicGroups,
            message: ArabicStrings.publicDiscoveryHint,
          ),
        ],
      ),
    );
  }
}
