/// The one shared Arabic-Indic numeral formatter (constitution Principle II).
///
/// Numerals in user-facing copy MUST go through this class; never format
/// numbers with raw string interpolation.
class ArabicNumerals {
  const ArabicNumerals._();

  static const String _digits = '٠١٢٣٤٥٦٧٨٩';

  /// Converts every Western digit in [value] (`num` or `String`) to its
  /// Arabic-Indic counterpart; all other characters pass through.
  static String format(Object value) {
    return value.toString().replaceAllMapped(
      RegExp('[0-9]'),
      (match) => _digits[int.parse(match.group(0)!)],
    );
  }

  /// `40` → `٤٠٪` (Arabic percent sign U+066A).
  static String percent(num value) => '${format(value)}٪';

  /// `12, 30` → `١٢ / ٣٠`.
  static String ratio(num completed, num total) =>
      '${format(completed)} / ${format(total)}';
}
