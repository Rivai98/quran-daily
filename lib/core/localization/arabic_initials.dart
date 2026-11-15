import 'package:flutter/widgets.dart';

/// Computes Arabic initials following the project specification:
/// - Single word -> 1 letter ("عمر" -> "ع")
/// - Compound prefixes ("عبد الله", "أبو بكر") -> keep compound together
/// - Multiple words ("محمد عبد الله") -> first of first and first of last significant ("م ع")
String displayInitials(String? name) {
  if (name == null) return '';
  final trimmed = name.trim();
  if (trimmed.isEmpty) return '';
  final words = trimmed
      .split(RegExp(r'\s+'))
      .where((w) => w.isNotEmpty)
      .toList();
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

/// Group initials use the group's first and last meaningful words, ignoring
/// generic prefixes commonly used in group names.
String groupInitials(String? name) {
  if (name == null) return '';
  final words = name
      .trim()
      .split(RegExp(r'\s+'))
      .where(
        (word) =>
            word.isNotEmpty && !RegExp(r'^[0-9٠-٩]+$').hasMatch(word),
      )
      .toList();
  if (words.isEmpty) return '';
  if (const ['حلقة', 'مجموعة'].contains(words.first) && words.length > 1) {
    words.removeAt(0);
  }
  String initial(String word) =>
      word.startsWith('ال') && word.characters.length > 2
      ? word.characters.elementAt(2)
      : word.characters.first;
  if (words.length == 1) return initial(words.first);
  return '${initial(words.first)} ${initial(words.last)}';
}
