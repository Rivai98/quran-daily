import 'package:flutter/material.dart';

import '../../localization/arabic_strings.dart';
import '../app_button.dart';
import '../app_spacing.dart';
import '../app_typography.dart';

/// Confirmation bottom sheet for destructive or irreversible actions
/// (undo completion, reject request, remove member, sign out, …).
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
      builder: (sheetContext) {
        return Padding(
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
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      label: confirmLabel,
                      variant: destructive
                          ? AppButtonVariant.destructive
                          : AppButtonVariant.primary,
                      expanded: true,
                      onPressed: () {
                        Navigator.of(sheetContext).pop(true);
                        onConfirm();
                      },
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: AppButton(
                      label: ArabicStrings.cancel,
                      variant: AppButtonVariant.secondary,
                      expanded: true,
                      onPressed: () => Navigator.of(sheetContext).pop(false),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
