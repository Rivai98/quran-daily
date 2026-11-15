import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Button variants from constitution Principle VI.
///
/// Primary 52 (the single main action of a screen), tonal/secondary/text 48,
/// destructive 48 — only inside a confirmation dialog/sheet.
enum AppButtonVariant { primary, tonal, secondary, text, destructive }

/// The one shared button. At most ONE primary button is visible per screen;
/// on action screens it is full width ([expanded]) and pinned above the
/// keyboard.
///
/// * The optional [icon] sits at the start (right in RTL), 20dp.
/// * While [loading] the button is disabled, keeps its width, shows a 20dp
///   progress indicator in place of the icon, and repeated taps are ignored.
/// * Disabled buttons render at 38% opacity; the screen must show the reason.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.loading = false,
    this.expanded = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final Icon? icon;
  final bool loading;
  final bool expanded;

  static const double _primaryHeight = 52;
  static const double _defaultHeight = 48;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final height = variant == AppButtonVariant.primary
        ? _primaryHeight
        : _defaultHeight;
    final disabled = onPressed == null;
    final effectiveOnPressed = loading ? null : onPressed;

    final leading = loading
        ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          )
        : icon;

    Widget button;
    switch (variant) {
      case AppButtonVariant.primary:
        button = FilledButton(
          onPressed: effectiveOnPressed,
          style: FilledButton.styleFrom(
            minimumSize: Size(expanded ? double.infinity : 64, height),
            backgroundColor: colors.primary,
            foregroundColor: colors.onPrimary,
          ),
          child: _content(leading),
        );
      case AppButtonVariant.tonal:
        button = FilledButton.tonal(
          onPressed: effectiveOnPressed,
          style: FilledButton.styleFrom(
            minimumSize: Size(expanded ? double.infinity : 64, height),
            backgroundColor: colors.primaryContainer,
            foregroundColor: colors.onPrimaryContainer,
          ),
          child: _content(leading),
        );
      case AppButtonVariant.secondary:
        button = OutlinedButton(
          onPressed: effectiveOnPressed,
          style: OutlinedButton.styleFrom(
            minimumSize: Size(expanded ? double.infinity : 64, height),
          ),
          child: _content(leading),
        );
      case AppButtonVariant.text:
        button = TextButton(
          onPressed: effectiveOnPressed,
          style: TextButton.styleFrom(
            minimumSize: Size(expanded ? double.infinity : 64, height),
          ),
          child: _content(leading),
        );
      case AppButtonVariant.destructive:
        button = FilledButton(
          onPressed: effectiveOnPressed,
          style: FilledButton.styleFrom(
            minimumSize: Size(expanded ? double.infinity : 64, height),
            backgroundColor: colors.danger,
            foregroundColor: Theme.of(context).brightness == Brightness.light
                ? const Color(0xFFFFFFFF)
                : const Color(0xFF3D1A18),
          ),
          child: _content(leading),
        );
    }

    if (disabled && !loading) {
      return Opacity(opacity: 0.38, child: button);
    }
    return button;
  }

  Widget _content(Widget? leading) {
    if (leading == null) {
      return Text(label);
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        IconTheme(data: const IconThemeData(size: 20), child: leading),
        const SizedBox(width: 8),
        Flexible(child: Text(label, textAlign: TextAlign.center)),
      ],
    );
  }
}

/// Toolbar icon button: 48×48 with a tooltip and Arabic semantic label.
class AppIconButton extends StatelessWidget {
  const AppIconButton({
    super.key,
    required this.icon,
    required this.semanticLabel,
    this.onPressed,
  });

  final IconData icon;
  final String semanticLabel;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: semanticLabel,
      onPressed: onPressed,
      icon: Icon(icon),
      constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
      padding: EdgeInsets.zero,
    );
  }
}
