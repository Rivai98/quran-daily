import 'package:flutter/material.dart';

import '../app_colors.dart';

/// Transient feedback snackbar (floating, ink background, optional action
/// such as "تراجع" or "إعادة المحاولة"). Shadows are allowed on the floating snackbar (Constitution Principle VI).
class AppSnackBar {
  const AppSnackBar._();

  /// Shows a standard feedback snackbar with optional icon, action, or error styling.
  static void show(
    BuildContext context,
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
    IconData? icon,
    bool isError = false,
    Duration duration = const Duration(seconds: 4),
  }) {
    final messenger = ScaffoldMessenger.of(context);
    final colors = Theme.of(context).extension<AppColors>();
    final iconColor = isError ? colors?.danger : colors?.primaryContainer;

    Widget content = Text(message);

    if (icon != null || isError) {
      final effectiveIcon = icon ?? Icons.error_outline_rounded;
      content = Row(
        children: [
          Icon(effectiveIcon, size: 20, color: iconColor),
          const SizedBox(width: 10),
          Expanded(child: Text(message)),
        ],
      );
    }

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: duration,
          content: content,
          action: (actionLabel != null && onAction != null)
              ? SnackBarAction(
                  label: actionLabel,
                  onPressed: onAction,
                  textColor: isError ? colors?.danger : null,
                )
              : null,
        ),
      );
  }

  /// Convenience helper to display a calm error snackbar with the real Arabic reason.
  static void showError(
    BuildContext context,
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 5),
  }) {
    show(
      context,
      message,
      actionLabel: actionLabel,
      onAction: onAction,
      isError: true,
      icon: Icons.error_outline_rounded,
      duration: duration,
    );
  }

  /// Convenience helper to display a success snackbar (e.g. after undo, bookmark, or action).
  static void showSuccess(
    BuildContext context,
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 4),
  }) {
    show(
      context,
      message,
      actionLabel: actionLabel,
      onAction: onAction,
      icon: Icons.check_circle_outline_rounded,
      duration: duration,
    );
  }
}
