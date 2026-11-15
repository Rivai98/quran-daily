import 'package:flutter/material.dart';

import '../../../../core/localization/arabic_strings.dart';
import '../../../../core/design_system/app_colors.dart';
import 'validation_banner.dart';

class OfflineStaleBanner extends StatelessWidget {
  const OfflineStaleBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColors>()!;
    return ValidationBanner(
      icon: Icons.wifi_off,
      message: ArabicStrings.offlineStale,
      color: appColors.pendingFg,
    );
  }
}
