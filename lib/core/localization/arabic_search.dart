/// Arabic-aware text matching for local search fields.
///
/// Mirrors the backend `arabic_search_normalize` so a query matches common
/// spelling variants: ة/ه, أ/إ/آ/ٱ → ا, ى → ي, with diacritics, Quranic
/// annotation marks and tatweel removed.
abstract final class ArabicSearch {
  static final _marks = RegExp('[ً-ٰٟـۖ-ۭ]');

  static const _folds = {
    'أ': 'ا',
    'إ': 'ا',
    'آ': 'ا',
    'ٱ': 'ا',
    'ة': 'ه',
    'ى': 'ي',
  };

  /// The comparable form of [text].
  static String normalize(String text) {
    final stripped = text.replaceAll(_marks, '').trim().toLowerCase();
    final buffer = StringBuffer();
    for (final rune in stripped.runes) {
      final char = String.fromCharCode(rune);
      buffer.write(_folds[char] ?? char);
    }
    return buffer.toString();
  }

  /// Whether [text] contains [query] once both are normalized. An empty
  /// query matches everything.
  static bool matches(String text, String query) {
    final needle = normalize(query);
    return needle.isEmpty || normalize(text).contains(needle);
  }
}
