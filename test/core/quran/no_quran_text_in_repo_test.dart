import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('lib and test contain no Quranic diacritized text', () {
    final violations = <String>[];
    for (final root in ['lib', 'test']) {
      for (final entity in Directory(root).listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        final source = entity.readAsStringSync();
        if (RegExp(r'[\u06D6-\u06ED\u08F0-\u08FF]').hasMatch(source)) {
          violations.add(entity.path);
        }
      }
    }
    expect(violations, isEmpty, reason: 'Quranic marks found in: $violations');
  });
}
