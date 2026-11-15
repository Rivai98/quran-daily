import 'package:flutter/material.dart';

import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/localization/arabic_strings.dart';

class JoinStatusBadge extends StatelessWidget {
  const JoinStatusBadge({super.key, required this.pending});

  final bool pending;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final foreground = pending ? colors.infoFg : colors.primary;
    final background = pending ? colors.infoBg : colors.primaryContainer;
    return Container(
      constraints: const BoxConstraints(minHeight: 48),
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: ShapeDecoration(
        color: background,
        shape: StadiumBorder(
          side: BorderSide(color: foreground.withValues(alpha: 0.32)),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            pending ? Icons.schedule : Icons.check_circle,
            color: foreground,
            size: 20,
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            pending
                ? ArabicStrings.pendingApproval
                : ArabicStrings.joinedSuccessfully,
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(color: foreground),
          ),
        ],
      ),
    );
  }
}
