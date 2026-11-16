import 'package:material_ui/material_ui.dart';

/// 4-point spacing scale from constitution Principle VI.
///
/// Only these values are permitted; feature code must reference the tokens,
/// never raw numbers. Screen horizontal gutter is [md] (16), the vertical
/// gap between sections is [lg] (24), and the gap inside a card is [sm] (12).
@immutable
class AppSpacing {
  const AppSpacing._();

  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;

  /// Screen horizontal gutter ([md] on both sides).
  static const EdgeInsets screenH = EdgeInsets.symmetric(horizontal: md);

  /// Default screen padding: [md] horizontal, [md] bottom.
  static const EdgeInsets screen = EdgeInsets.fromLTRB(md, md, md, md);

  /// Padding inside a card ([md]).
  static const EdgeInsets card = EdgeInsets.all(md);

  /// Comfortable page gutter for long-form screens.
  static const EdgeInsets screenContent = EdgeInsets.fromLTRB(md, lg, md, xl);

  /// Compact card/list-row padding ([sm]).
  static const EdgeInsets compactCard = EdgeInsets.all(sm);

  /// Vertical gap between a screen's sections ([lg]).
  static const double sectionGap = lg;

  /// Gap between elements inside a card ([sm]).
  static const double cardGap = sm;

  /// Small gap between a field label and its control.
  static const double fieldLabelGap = xxs;
}
