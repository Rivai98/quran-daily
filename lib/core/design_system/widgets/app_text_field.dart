import 'package:flutter/material.dart';

import '../../localization/arabic_strings.dart';
import '../app_colors.dart';
import '../app_spacing.dart';
import '../app_typography.dart';

/// Shared text field. Inherently LTR content (email addresses) uses [ltr];
/// the field then renders LTR inside its own box while the app stays RTL.
class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    required this.label,
    this.controller,
    this.hint,
    this.prefixIcon,
    this.errorText,
    this.helpText,
    this.obscure = false,
    this.ltr = false,
    this.keyboardType,
    this.validator,
    this.onSubmitted,
    this.focusNode,
    this.autofocus = false,
    this.textInputAction,
  });

  final String label;
  final TextEditingController? controller;
  final String? hint;
  final IconData? prefixIcon;
  final String? errorText;
  final String? helpText;
  final bool obscure;
  final bool ltr;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onSubmitted;
  final FocusNode? focusNode;
  final bool autofocus;
  final TextInputAction? textInputAction;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late bool _obscured = widget.obscure;

  @override
  void didUpdateWidget(covariant AppTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A reused State must not keep another field's hidden-text mode.
    if (oldWidget.obscure != widget.obscure) _obscured = widget.obscure;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: AppTypography.label),
        const SizedBox(height: AppSpacing.fieldLabelGap),
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 52),
          child: TextField(
            controller: widget.controller,
            focusNode: widget.focusNode,
            autofocus: widget.autofocus,
            obscureText: _obscured,
            keyboardType: widget.keyboardType,
            textInputAction: widget.textInputAction,
            textDirection: widget.ltr ? TextDirection.ltr : null,
            style: AppTypography.bodyLarge,
            onSubmitted: widget.onSubmitted,
            decoration: InputDecoration(
              hintText: widget.hint,
              errorText: widget.errorText,
              errorStyle: AppTypography.caption.copyWith(color: colors.danger),
              prefixIcon: widget.prefixIcon != null
                  ? Icon(widget.prefixIcon)
                  : null,
              suffixIcon: widget.obscure
                  ? IconButton(
                      tooltip: _obscured
                          ? ArabicStrings.showPassword
                          : ArabicStrings.hidePassword,
                      onPressed: () => setState(() => _obscured = !_obscured),
                      icon: Icon(
                        _obscured ? Icons.visibility : Icons.visibility_off,
                      ),
                    )
                  : null,
            ),
          ),
        ),
        if (widget.helpText != null && widget.errorText == null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              widget.helpText!,
              style: AppTypography.caption.copyWith(color: colors.inkMuted),
            ),
          ),
      ],
    );
  }
}
