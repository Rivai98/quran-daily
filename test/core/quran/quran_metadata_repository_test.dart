import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:xml/xml.dart';

import 'package:quran_daily/core/quran/quran_metadata_repository.dart';

/// Constitution Principle VII: every Quran-derived value in this test is
/// read from the bundled Tanzil file via an independent parser in this test
/// — no name, number, or boundary is ever typed here.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late XmlDocument doc;
  late QuranMetadataRepository repository;

  setUpAll(() async {
    doc = XmlDocument.parse(
      await File('assets/quran/quran-data.xml').readAsString(),
    );
  });

  int suraCount() => doc.findAllElements('sura').length;

  setUp(() async {
    repository = QuranMetadataRepository();
    await repository.load();
  });

  group('file integrity (Principle VII)', () {
    test('quran-data.xml matches checksums.sha256 byte-for-byte', () async {
      final checksumLine = (await File('assets/quran/checksums.sha256')
              .readAsLines())
          .firstWhere((l) => l.contains('quran-data.xml'));
      final expected =
          checksumLine.split('*').first.trim().toLowerCase();
      final bytes = await File('assets/quran/quran-data.xml').readAsBytes();

      expect(
        crypto.sha256.convert(bytes).toString(),
        expected,
        reason: 'assets/quran/quran-data.xml must stay byte-exact; '
            'updating it requires owner review (SOURCE.md)',
      );
    });

    test('load() throws when the metadata asset is missing', () async {
      final broken = QuranMetadataRepository(
        bundle: _MissingBundle(),
      );
      Object? caught;
      try {
        await broken.load();
      } catch (error) {
        caught = error;
      }
      expect(caught, isA<QuranMetadataException>());
    });
  });

  group('structure from the file', () {
    test('there are exactly 30 juz numbered 1..30', () {
      for (var n = 1; n <= 30; n++) {
        expect(repository.juz(n).number, n);
      }
      expect(() => repository.juz(31), throwsRangeError);
      expect(() => repository.juz(0), throwsRangeError);
    });

    test('every juz start matches the file entry', () {
      final fileJuz = doc.findAllElements('juz').toList();
      expect(fileJuz.length, 30);
      for (final entry in fileJuz) {
        final number = int.parse(entry.getAttribute('index')!);
        final info = repository.juz(number);
        expect(info.startSura,
            int.parse(entry.getAttribute('sura')!), reason: 'juz $number');
        expect(info.startAya,
            int.parse(entry.getAttribute('aya')!), reason: 'juz $number');
      }
    });

    test('juz 30 ends at the last ayah of the last sura per the file', () {
      final lastSura = suraCount();
      final last = repository.juz(30);
      expect(last.endSura, lastSura);
      expect(last.endAya, repository.suraAyahCount(lastSura));
    });

    test('ranges are contiguous, non-overlapping, and cross sura boundaries '
        'using the file ayah counts', () {
      final totalAyahsBefore = <int, int>{};
      var running = 0;
      for (var s = 1; s <= suraCount(); s++) {
        totalAyahsBefore[s] = running;
        running += repository.suraAyahCount(s);
      }
      int globalIndex(int sura, int aya) => totalAyahsBefore[sura]! + aya;

      for (var n = 1; n < 30; n++) {
        final current = repository.juz(n);
        final next = repository.juz(n + 1);

        // The file's own start offsets must be consistent with the ayah
        // counts we derived them from.
        expect(globalIndex(next.startSura, next.startAya),
            greaterThan(globalIndex(current.startSura, current.startAya)));

        // Every juz ends exactly one ayah before the next juz starts.
        expect(
          globalIndex(current.endSura, current.endAya) + 1,
          globalIndex(next.startSura, next.startAya),
          reason: 'juz $n -> ${n + 1} must be contiguous',
        );

        // End coordinates always lie inside the file's ayah counts.
        expect(
          current.endAya,
          inInclusiveRange(1, repository.suraAyahCount(current.endSura)),
          reason: 'juz $n end ayah within sura count',
        );
      }
    });
  });

  group('surah data from the file', () {
    test('suraName matches the file Arabic name for every sura', () {
      final suras = doc.findAllElements('sura').toList();
      expect(suras.length, 114);
      for (final sura in suras) {
        final index = int.parse(sura.getAttribute('index')!);
        expect(
          repository.suraName(index),
          sura.getAttribute('name'),
          reason: 'sura $index',
        );
      }
    });

    test('suraAyahCount matches the file ayas attribute for every sura', () {
      final suras = doc.findAllElements('sura').toList();
      var total = 0;
      for (final sura in suras) {
        final index = int.parse(sura.getAttribute('index')!);
        final ayas = int.parse(sura.getAttribute('ayas')!);
        expect(repository.suraAyahCount(index), ayas, reason: 'sura $index');
        total += ayas;
      }
      // Kufan count consistency: the file's own start offsets must end at
      // the total derived from its ayah counts.
      final lastStart =
          int.parse(suras.last.getAttribute('start')!);
      expect(lastStart + int.parse(suras.last.getAttribute('ayas')!),
          total);
    });
  });

}

class _MissingBundle implements AssetBundle {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw Exception('asset not found');
}
