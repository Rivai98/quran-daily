import 'package:material_ui/material_ui.dart';

import '../../localization/arabic_strings.dart';
import '../app_button.dart';
import '../app_spacing.dart';
import '../app_typography.dart';

/// Confirmation bottom sheet for destructive or irreversible actions
/// (undo completion, reject request, remove member, sign out, …)
/// following Constitution Principle VI & ui-craft.md.
///
/// The confirm button states the consequence; pairs of actions place the
/// confirming action at the start (right in RTL) and cancel at the end.
class ConfirmSheet {
  const ConfirmSheet._();

  /// Returns `true` when the user confirmed, `false`/`null` otherwise.
  static Future<bool?> show(
    BuildContext context, {
    required String title,
    required String message,
    required String confirmLabel,
    required VoidCallback onConfirm,
    bool destructive = false,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        final mediaQuery = MediaQuery.of(sheetContext);
        final isCompact =
            mediaQuery.size.width < 340 ||
            mediaQuery.textScaler.scale(1) > 1.25;

        final confirmButton = AppButton(
          label: confirmLabel,
          variant: destructive
              ? AppButtonVariant.destructive
              : AppButtonVariant.primary,
          expanded: true,
          onPressed: () {
            Navigator.of(sheetContext).pop(true);
            onConfirm();
          },
        );

        final cancelButton = AppButton(
          label: ArabicStrings.cancel,
          variant: AppButtonVariant.secondary,
          expanded: true,
          onPressed: () => Navigator.of(sheetContext).pop(false),
        );

        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              0,
              AppSpacing.md,
              AppSpacing.lg,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(title, style: AppTypography.title),
                const SizedBox(height: AppSpacing.xs),
                Text(message, style: AppTypography.body),
                const SizedBox(height: AppSpacing.md),
                if (isCompact) ...[
                  confirmButton,
                  const SizedBox(height: AppSpacing.sm),
                  cancelButton,
                ] else ...[
                  Row(
                    children: [
                      Expanded(child: confirmButton),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(child: cancelButton),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
