import 'package:flutter/material.dart';

import '../../../../core/localization/arabic_strings.dart';
import '../../../../core/theme/app_theme.dart';
import 'validation_banner.dart';

class OfflineStaleBanner extends StatelessWidget {
  const OfflineStaleBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return const ValidationBanner(
      icon: Icons.wifi_off,
      message: ArabicStrings.offlineStale,
      color: AppTheme.pendingColor,
    );
  }
}
