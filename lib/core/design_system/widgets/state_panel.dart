import 'package:flutter/material.dart';

import '../app_button.dart';
import '../app_colors.dart';
import '../app_spacing.dart';
import '../app_typography.dart';

/// Empty, error, and no-permission states: icon, title, one sentence of
/// explanation, and the next action as a button (constitution Principle VI).
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
    this.isError = false,
    this.illustration,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final AppButtonVariant actionVariant;
  final Icon? actionIcon;
  final bool isError;
  final Widget? illustration;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
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
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: AppSpacing.md),
                AppButton(
                  label: actionLabel!,
                  variant: actionVariant,
                  icon: actionIcon,
                  onPressed: onAction,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
