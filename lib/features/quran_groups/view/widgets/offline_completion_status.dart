import 'package:flutter/material.dart';

import '../../../../core/localization/arabic_strings.dart';
import '../../../../core/theme/app_theme.dart';
import 'validation_banner.dart';

class OfflineCompletionStatus extends StatelessWidget {
  const OfflineCompletionStatus({super.key});

  @override
  Widget build(BuildContext context) {
    return const ValidationBanner(
      icon: Icons.sync,
      message: ArabicStrings.syncQueued,
      color: AppTheme.pendingColor,
    );
  }
}
