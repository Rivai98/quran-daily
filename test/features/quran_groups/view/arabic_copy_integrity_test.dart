import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:quran_daily/core/localization/arabic_strings.dart';

void main() {
  test('critical Arabic constants do not contain mojibake markers', () {
    final values = [
      ArabicStrings.appName,
      ArabicStrings.dashboardTitle,
      ArabicStrings.pending,
      ArabicStrings.completed,
      ArabicStrings.missed,
      ArabicStrings.late,
      ArabicStrings.pendingApproval,
      ArabicStrings.noQuranReader,
    ];

    for (final value in values) {
      expect(value, isNot(contains(RegExp('[\\u00D8\\u00D9]'))));
    }
  });

  test('view source no longer contains mojibake placeholder text', () {
    final roots = [
      Directory('lib/core/localization'),
      Directory('lib/features/quran_groups/view'),
    ];

    for (final root in roots) {
      for (final file in root.listSync(recursive: true).whereType<File>()) {
        if (!file.path.endsWith('.dart')) {
          continue;
        }

        final source = file.readAsStringSync();
        expect(
          source,
          isNot(contains(RegExp('[\\u00D8\\u00D9]'))),
          reason: file.path,
        );
      }
    }
  });
}
