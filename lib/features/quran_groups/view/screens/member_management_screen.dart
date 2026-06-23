import 'package:flutter/material.dart';

import '../../../../core/localization/arabic_strings.dart';
import '../../../../core/theme/app_spacing.dart';
import '../widgets/app_section_header.dart';
import '../widgets/dense_info_row.dart';
import '../widgets/member_slot_readiness.dart';

class MemberManagementScreen extends StatelessWidget {
  const MemberManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(ArabicStrings.memberManagementTitle)),
      body: ListView(
        padding: AppSpacing.screen,
        children: [
          const MemberSlotReadiness(),
          const AppSectionHeader(title: ArabicStrings.activeMembersLabel),
          for (var index = 1; index <= 8; index++) ...[
            DenseInfoRow(
              icon: index == 1 ? Icons.admin_panel_settings : Icons.person,
              title: index == 1
                  ? ArabicStrings.groupOwner
                  : '${ArabicStrings.memberRole} $index',
              subtitle: index == 1
                  ? ArabicStrings.groupOwner
                  : ArabicStrings.memberRole,
              trailing: const Icon(Icons.verified_user_outlined),
            ),
            const SizedBox(height: AppSpacing.xs),
          ],
        ],
      ),
    );
  }
}
