import 'package:material_ui/material_ui.dart';

/// Radius tokens from constitution Principle VI.
///
/// sm 8 (chips, small tiles) · md 12 (buttons, inputs) · lg 16 (cards) ·
/// xl 24 (bottom sheets, dialogs) · pill (status chips).
@immutable
class AppRadius {
  const AppRadius._();

  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double pill = 999;

  static const BorderRadius smBR = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius mdBR = BorderRadius.all(Radius.circular(md));
  static const BorderRadius lgBR = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius xlBR = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius pillBR = BorderRadius.all(Radius.circular(pill));

  static final RoundedRectangleBorder smShape = RoundedRectangleBorder(
    borderRadius: smBR,
  );
  static final RoundedRectangleBorder mdShape = RoundedRectangleBorder(
    borderRadius: mdBR,
  );
  static final RoundedRectangleBorder lgShape = RoundedRectangleBorder(
    borderRadius: lgBR,
  );
  static final RoundedRectangleBorder xlShape = RoundedRectangleBorder(
    borderRadius: xlBR,
  );
}
