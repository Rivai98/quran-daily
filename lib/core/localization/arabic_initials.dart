import 'package:flutter/widgets.dart';

/// Computes Arabic initials following the project specification:
/// - Single word -> 1 letter ("عمر" -> "ع")
/// - Compound prefixes ("عبد الله", "أبو بكر") -> keep compound together
/// - Multiple words ("محمد عبد الله") -> first of first and first of last significant ("م ع")
String displayInitials(String? name) {
  if (name == null) return '';
  final trimmed = name.trim();
  if (trimmed.isEmpty) return '';
  final words = trimmed.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
  if (words.isEmpty) return '';
  if (words.length == 1) return words[0].characters.first;
  var last = words.last;
  final prev = words[words.length - 2];
  if (const ['عبد', 'أبو', 'ابو', 'أبي', 'ابي'].contains(prev)) {
    if (words.length == 2) {
      return words[0].characters.first;
    }
    last = prev;
  }
  return '${words[0].characters.first} ${last.characters.first}';
}
