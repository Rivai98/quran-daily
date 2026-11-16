import 'package:material_ui/material_ui.dart';

import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/app_radius.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/design_system/app_typography.dart';
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
      constraints: const BoxConstraints(minHeight: AppSpacing.xl),
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.xs,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: AppRadius.pillBR,
        border: Border.all(color: foreground.withValues(alpha: 0.32)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            pending ? Icons.schedule_rounded : Icons.check_circle_rounded,
            color: foreground,
            size: AppSpacing.md,
          ),
          const SizedBox(width: AppSpacing.xxs),
          Text(
            pending
                ? ArabicStrings.pendingApproval
                : ArabicStrings.joinedSuccessfully,
            style: AppTypography.caption.copyWith(color: foreground),
          ),
        ],
      ),
    );
  }
}
