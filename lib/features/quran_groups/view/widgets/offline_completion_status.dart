import 'package:flutter/material.dart';

import '../../../../core/localization/arabic_strings.dart';
import '../../../../core/design_system/app_colors.dart';
import 'validation_banner.dart';

class OfflineCompletionStatus extends StatelessWidget {
  const OfflineCompletionStatus({super.key});

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColors>()!;
    return ValidationBanner(
      icon: Icons.sync,
      message: ArabicStrings.syncQueued,
      color: appColors.pendingFg,
    );
  }
}
