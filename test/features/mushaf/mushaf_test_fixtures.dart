import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_daily/core/quran/mushaf/mushaf_models.dart';

/// Reads fixture verses from the approved source asset; never authors text.
Future<List<MushafAyah>> readMushafFixtureAyahs({int count = 3}) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  final source = await rootBundle.loadString('assets/quran/hafs/qpc-hafs.json');
  final json = jsonDecode(source) as Map<String, dynamic>;
  return json.values
      .take(count)
      .map((value) {
        final row = (value as Map).cast<String, Object?>();
        return MushafAyah(
          ref: AyahRef(surah: row['surah']! as int, ayah: row['ayah']! as int),
          text: row['text']! as String,
        );
      })
      .toList(growable: false);
}
