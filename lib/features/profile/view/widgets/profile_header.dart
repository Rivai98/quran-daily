import 'package:flutter/material.dart';

import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/design_system/app_typography.dart';
import '../../../../core/localization/arabic_numerals.dart';
import '../../../../core/localization/arabic_strings.dart';

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({
    super.key,
    required this.displayName,
    this.memberSince,
  });

  final String displayName;
  final DateTime? memberSince;

  String _initials(String name) {
    final parts =
        name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '؟';
    if (parts.length == 1) {
      return parts[0].characters.first;
    }
    return '${parts[0].characters.first}${parts[1].characters.first}';
  }

  String _formatDate(DateTime dt) {
    return '${ArabicNumerals.format(dt.year)}/${ArabicNumerals.format(dt.month)}/${ArabicNumerals.format(dt.day)}';
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final initials = _initials(displayName);

    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: colors.primaryContainer,
            shape: BoxShape.circle,
            border: Border.all(color: colors.border),
          ),
          alignment: Alignment.center,
          child: Text(
            initials,
            style: AppTypography.headline.copyWith(
              color: colors.onPrimaryContainer,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          displayName.isNotEmpty ? displayName : 'قارئ القرآن',
          style: AppTypography.headline,
          textAlign: TextAlign.center,
        ),
        if (memberSince != null) ...[
          const SizedBox(height: AppSpacing.xxs),
          Text(
            ArabicStrings.memberSince(_formatDate(memberSince!)),
            style: AppTypography.caption.copyWith(color: colors.inkMuted),
          ),
        ],
      ],
    );
  }
}
