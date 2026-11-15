import 'package:flutter/material.dart';

import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/design_system/app_typography.dart';
import '../../../../core/localization/arabic_numerals.dart';
import '../../../../core/localization/arabic_strings.dart';
import '../../../../core/design_system/widgets/illustrated_avatar.dart';

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({
    super.key,
    required this.displayName,
    this.avatarKey = 'ornament',
    this.memberSince,
  });

  final String displayName;
  final String avatarKey;
  final DateTime? memberSince;

  String _formatDate(DateTime dt) {
    return '${ArabicNumerals.format(dt.year)}/${ArabicNumerals.format(dt.month)}/${ArabicNumerals.format(dt.day)}';
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return Column(
      children: [
        IllustratedAvatar(avatarKey: avatarKey, size: 80),
        const SizedBox(height: AppSpacing.sm),
        Text(
          displayName.isNotEmpty ? displayName : 'قارئ القرآن',
          style: AppTypography.headline,
          textAlign: TextAlign.center,
        ),
        if (memberSince != null) ...[
          const SizedBox(height: AppSpacing.xxs),
          Text(
            ArabicStrings.profileMemberSince(_formatDate(memberSince!)),
            style: AppTypography.caption.copyWith(color: colors.inkMuted),
          ),
        ],
      ],
    );
  }
}
