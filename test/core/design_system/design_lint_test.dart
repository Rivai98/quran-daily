import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Constitution Principle VI: feature code MUST use only design-system
/// tokens and shared widgets. This test scans `lib/features/**.dart` for
/// raw color literals, raw font sizes, and ad-hoc border radii.
void main() {
  test('lib/features contains no raw colors, font sizes, or radii', () {
    final violations = <String>[];
    final featuresDir = Directory('lib/features');

    expect(featuresDir.existsSync(), isTrue, reason: 'lib/features must exist');

    for (final file
        in featuresDir
            .listSync(recursive: true)
            .whereType<File>()
            .where((f) => f.path.endsWith('.dart'))) {
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        if (line.trim().startsWith('//')) {
          continue;
        }
        if (line.contains('Color(0x')) {
          violations.add('${file.path}:${i + 1}: Color(0x...');
        }
        if (line.contains('fontSize:')) {
          violations.add('${file.path}:${i + 1}: fontSize:');
        }
        if (line.contains('BorderRadius.circular(')) {
          violations.add('${file.path}:${i + 1}: BorderRadius.circular(');
        }
      }
    }

    expect(
      violations,
      isEmpty,
      reason:
          'Raw colors/sizes/radii are forbidden under lib/features; use '
          'lib/core/design_system tokens and shared widgets instead.\n'
          '${violations.join('\n')}',
    );
  });
}
