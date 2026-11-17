import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:xml/xml.dart';

import 'package:quran_daily/core/quran/quran_metadata_repository.dart';
import 'package:quran_daily/core/quran/portion_unit.dart';
import 'package:quran_daily/core/localization/arabic_strings.dart';
import 'package:quran_daily/core/localization/arabic_numerals.dart';

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

  test('derived portions reuse immutable objects per unit (#17)', () {
    for (final unit in PortionUnit.values) {
      final portions = repository.portions(unit);
      expect(identical(repository.portions(unit), portions), isTrue);
      expect(identical(repository.portion(unit, 1), portions.first), isTrue);
      expect(() => portions.clear(), throwsUnsupportedError);
      expect(() => repository.portion(unit, 0), throwsRangeError);
      expect(
        () => repository.portion(unit, portions.length + 1),
        throwsRangeError,
      );
    }
  });

  group('file integrity (Principle VII)', () {
    test('quran-data.xml matches checksums.sha256 byte-for-byte', () async {
      final checksumLine = (await File(
        'assets/quran/checksums.sha256',
      ).readAsLines()).firstWhere((l) => l.contains('quran-data.xml'));
      final expected = checksumLine.split('*').first.trim().toLowerCase();
      final bytes = await File('assets/quran/quran-data.xml').readAsBytes();

      expect(
        crypto.sha256.convert(bytes).toString(),
        expected,
        reason:
            'assets/quran/quran-data.xml must stay byte-exact; '
            'updating it requires owner review (SOURCE.md)',
      );
    });

    test('load() throws when the metadata asset is missing', () async {
      final broken = QuranMetadataRepository(bundle: _MissingBundle());
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
        expect(
          info.startSura,
          int.parse(entry.getAttribute('sura')!),
          reason: 'juz $number',
        );
        expect(
          info.startAya,
          int.parse(entry.getAttribute('aya')!),
          reason: 'juz $number',
        );
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
        expect(
          globalIndex(next.startSura, next.startAya),
          greaterThan(globalIndex(current.startSura, current.startAya)),
        );

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
      final lastStart = int.parse(suras.last.getAttribute('start')!);
      expect(lastStart + int.parse(suras.last.getAttribute('ayas')!), total);
    });
  });

  group('portion boundaries from the file', () {
    test('portion counts match source boundary element counts', () {
      final quarters = doc.findAllElements('quarter').length;
      final juzs = doc.findAllElements('juz').length;
      final pages = doc.findAllElements('page').length;
      expect(juzs, 30);
      expect(quarters, 240);
      expect(pages, 604);
      expect(repository.portions(PortionUnit.juz), hasLength(juzs));
      expect(
        repository.portions(PortionUnit.halfJuz),
        hasLength(quarters ~/ 8),
      );
      expect(repository.portions(PortionUnit.hizb), hasLength(quarters ~/ 4));
      expect(repository.portions(PortionUnit.quarter), hasLength(quarters));
      expect(repository.portions(PortionUnit.page), hasLength(pages));
    });

    test('quarter and page starts match their source elements', () {
      for (final (unit, elementName) in [
        (PortionUnit.quarter, 'quarter'),
        (PortionUnit.page, 'page'),
      ]) {
        final portions = repository.portions(unit);
        final entries = doc.findAllElements(elementName).toList();
        for (var i = 0; i < entries.length; i++) {
          expect(
            portions[i].startSura,
            int.parse(entries[i].getAttribute('sura')!),
            reason: '${unit.name} ${i + 1}',
          );
          expect(
            portions[i].startAya,
            int.parse(entries[i].getAttribute('aya')!),
            reason: '${unit.name} ${i + 1}',
          );
        }
      }
    });

    test('all portions are contiguous and cover source ayah counts', () {
      for (final unit in PortionUnit.values) {
        final portions = repository.portions(unit);
        expect(portions, isNotEmpty);
        expect(portions.first.startSura, 1);
        expect(portions.first.startAya, 1);
        for (var i = 0; i < portions.length - 1; i++) {
          final current = portions[i];
          final next = portions[i + 1];
          final nextAya =
              current.endAya < repository.suraAyahCount(current.endSura)
              ? current.endAya + 1
              : 1;
          final nextSura = nextAya == 1 ? current.endSura + 1 : current.endSura;
          expect(next.startSura, nextSura, reason: '${unit.name} ${i + 1}');
          expect(next.startAya, nextAya, reason: '${unit.name} ${i + 1}');
        }
        expect(portions.last.endSura, suraCount());
        expect(
          portions.last.endAya,
          repository.suraAyahCount(portions.last.endSura),
        );
        for (final portion in portions) {
          expect(portion.index, inInclusiveRange(1, portions.length));
          expect(
            portion.endAya,
            inInclusiveRange(1, repository.suraAyahCount(portion.endSura)),
          );
        }
      }
    });

    test('hizb and half juz compose the specified quarter ranges', () {
      final quarters = repository.portions(PortionUnit.quarter);
      final hizbs = repository.portions(PortionUnit.hizb);
      final halfJuzs = repository.portions(PortionUnit.halfJuz);
      for (var i = 0; i < hizbs.length; i++) {
        expect(hizbs[i].startSura, quarters[i * 4].startSura);
        expect(hizbs[i].startAya, quarters[i * 4].startAya);
        expect(hizbs[i].endSura, quarters[i * 4 + 3].endSura);
        expect(hizbs[i].endAya, quarters[i * 4 + 3].endAya);
      }
      for (var i = 0; i < halfJuzs.length; i++) {
        expect(halfJuzs[i].startSura, hizbs[i * 2].startSura);
        expect(halfJuzs[i].startAya, hizbs[i * 2].startAya);
        expect(halfJuzs[i].endSura, hizbs[i * 2 + 1].endSura);
        expect(halfJuzs[i].endAya, hizbs[i * 2 + 1].endAya);
      }
    });

    test(
      'juz portions match the existing juz ranges and indexing is checked',
      () {
        final portions = repository.portions(PortionUnit.juz);
        for (var i = 0; i < portions.length; i++) {
          final juz = repository.juz(i + 1);
          expect(portions[i].startSura, juz.startSura);
          expect(portions[i].startAya, juz.startAya);
          expect(portions[i].endSura, juz.endSura);
          expect(portions[i].endAya, juz.endAya);
          expect(repository.portion(PortionUnit.juz, i + 1), portions[i]);
        }
        expect(() => repository.portion(PortionUnit.juz, 0), throwsRangeError);
        expect(
          () => repository.portion(PortionUnit.page, 99999),
          throwsRangeError,
        );
      },
    );

    test('unit labels and ordinal names format indices with shared digits', () {
      expect(ArabicStrings.portionUnitName(PortionUnit.hizb), isNotEmpty);
      expect(
        ArabicStrings.portionName(PortionUnit.hizb, 12),
        '${ArabicStrings.portionUnitHizb} ${ArabicNumerals.format(12)}',
      );
    });
  });
}

class _MissingBundle implements AssetBundle {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw Exception('asset not found');
}
