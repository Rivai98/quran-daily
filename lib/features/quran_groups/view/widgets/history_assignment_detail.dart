import 'package:flutter/material.dart';

import '../../../../core/localization/arabic_strings.dart';
import '../../../../core/design_system/app_colors.dart';
import 'dense_info_row.dart';

class HistoryAssignmentDetail extends StatelessWidget {
  const HistoryAssignmentDetail({super.key});

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColors>()!;
    return DenseInfoRow(
      icon: Icons.error_outline,
      title: ArabicStrings.oneLatePart,
      subtitle: ArabicStrings.partRange2,
      accentColor: appColors.lateFg,
    );
  }
}
