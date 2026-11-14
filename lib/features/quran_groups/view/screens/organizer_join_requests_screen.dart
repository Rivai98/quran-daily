import 'package:flutter/material.dart';

import '../../../../core/localization/arabic_strings.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/design_system/app_colors.dart';
import '../widgets/join_request_tile.dart';
import '../widgets/state_panel.dart';
import '../widgets/validation_banner.dart';

class OrganizerJoinRequestsScreen extends StatelessWidget {
  const OrganizerJoinRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColors>()!;
    return Scaffold(
      appBar: AppBar(title: const Text(ArabicStrings.joinRequestsTitle)),
      body: ListView(
        padding: AppSpacing.screen,
        children: [
          StatePanel(
            icon: Icons.inbox_outlined,
            title: ArabicStrings.noJoinRequests,
            message: ArabicStrings.noJoinRequests,
          ),
          SizedBox(height: AppSpacing.sm),
          JoinRequestTile(),
          SizedBox(height: AppSpacing.sm),
          ValidationBanner(
            icon: Icons.block,
            message: ArabicStrings.groupFull,
            color: appColors.missedFg,
          ),
        ],
      ),
    );
  }
}
