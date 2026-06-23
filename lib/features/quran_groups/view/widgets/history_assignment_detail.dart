import 'package:flutter/material.dart';

import '../../../../core/localization/arabic_strings.dart';
import '../../../../core/theme/app_theme.dart';
import 'dense_info_row.dart';

class HistoryAssignmentDetail extends StatelessWidget {
  const HistoryAssignmentDetail({super.key});

  @override
  Widget build(BuildContext context) {
    return const DenseInfoRow(
      icon: Icons.error_outline,
      title: ArabicStrings.oneLatePart,
      subtitle: ArabicStrings.partRange2,
      accentColor: AppTheme.lateColor,
    );
  }
}
