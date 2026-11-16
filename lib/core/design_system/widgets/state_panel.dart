import 'package:material_ui/material_ui.dart';

import '../app_button.dart';
import '../app_colors.dart';
import '../app_spacing.dart';
import '../app_typography.dart';
import 'halaqa_logo.dart';

/// Empty, error, and no-permission states: icon/illustration, title, one sentence of
/// explanation, and next action buttons (constitution Principle VI & ui-craft.md).
class StatePanel extends StatelessWidget {
  const StatePanel({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.actionVariant = AppButtonVariant.tonal,
    this.actionIcon,
    this.secondaryActionLabel,
    this.onSecondaryAction,
    this.secondaryActionVariant = AppButtonVariant.secondary,
    this.secondaryActionIcon,
    this.isError = false,
    this.illustration,
  });

  /// Factory constructor for empty states: uses the official حلقة logo
  /// or refined ornament, calm title, subtitle, and primary action (G4 & ui-craft).
  factory StatePanel.empty({
    Key? key,
    required String title,
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
    AppButtonVariant actionVariant = AppButtonVariant.primary,
    Icon? actionIcon,
    String? secondaryActionLabel,
    VoidCallback? onSecondaryAction,
    AppButtonVariant secondaryActionVariant = AppButtonVariant.secondary,
    Icon? secondaryActionIcon,
    Widget? illustration,
    IconData icon = Icons.auto_stories_rounded,
  }) {
    return StatePanel(
      key: key,
      icon: icon,
      illustration: illustration ?? const HalaqaLogo(size: 56),
      title: title,
      message: message,
      actionLabel: actionLabel,
      onAction: onAction,
      actionVariant: actionVariant,
      actionIcon: actionIcon,
      secondaryActionLabel: secondaryActionLabel,
      onSecondaryAction: onSecondaryAction,
      secondaryActionVariant: secondaryActionVariant,
      secondaryActionIcon: secondaryActionIcon,
      isError: false,
    );
  }

  /// Factory constructor for error states: clear Arabic explanation
  /// and a retry / recovery action (ui-craft.md).
  factory StatePanel.error({
    Key? key,
    required String title,
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
    AppButtonVariant actionVariant = AppButtonVariant.secondary,
    Icon? actionIcon,
    IconData icon = Icons.error_outline_rounded,
  }) {
    return StatePanel(
      key: key,
      icon: icon,
      title: title,
      message: message,
      actionLabel: actionLabel,
      onAction: onAction,
      actionVariant: actionVariant,
      actionIcon: actionIcon,
      isError: true,
    );
  }

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final AppButtonVariant actionVariant;
  final Icon? actionIcon;
  final String? secondaryActionLabel;
  final VoidCallback? onSecondaryAction;
  final AppButtonVariant secondaryActionVariant;
  final Icon? secondaryActionIcon;
  final bool isError;
  final Widget? illustration;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final hasPrimaryAction = actionLabel != null && onAction != null;
    final hasSecondaryAction =
        secondaryActionLabel != null && onSecondaryAction != null;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              illustration ??
                  Icon(
                    icon,
                    size: 40,
                    color: isError ? colors.danger : colors.inkMuted,
                  ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                title,
                style: AppTypography.title,
                textAlign: TextAlign.center,
              ),
              if (message.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  message,
                  style: AppTypography.body.copyWith(color: colors.inkMuted),
                  textAlign: TextAlign.center,
                ),
              ],
              if (hasPrimaryAction || hasSecondaryAction) ...[
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    if (hasPrimaryAction)
                      AppButton(
                        label: actionLabel!,
                        variant: actionVariant,
                        icon: actionIcon,
                        onPressed: onAction,
                      ),
                    if (hasSecondaryAction)
                      AppButton(
                        label: secondaryActionLabel!,
                        variant: secondaryActionVariant,
                        icon: secondaryActionIcon,
                        onPressed: onSecondaryAction,
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
