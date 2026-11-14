import 'package:flutter/material.dart';

/// Transient feedback snackbar (floating, ink background, optional action
/// such as "تراجع"). Shadows are allowed on the floating snackbar.
class AppSnackBar {
  const AppSnackBar._();

  static void show(
    BuildContext context,
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          action: (actionLabel != null && onAction != null)
              ? SnackBarAction(label: actionLabel, onPressed: onAction)
              : null,
        ),
      );
  }
}
