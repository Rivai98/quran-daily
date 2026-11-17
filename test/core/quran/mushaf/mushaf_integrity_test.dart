
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:xml/xml.dart';
import 'package:quran_daily/core/quran/mushaf/mushaf_models.dart';
import 'package:quran_daily/core/quran/mushaf/mushaf_repository.dart';
import 'package:quran_daily/core/quran/portion_unit.dart';
import 'package:quran_daily/core/quran/quran_metadata_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MushafRepositoryImpl repository;

  setUp(() {
    repository = MushafRepositoryImpl(metadata: QuranMetadataRepository());
  });

  test(
    'concurrent hydration shares initialization and retries failure (#5)',
    () async {
      final bundle = _CountingBundle();
      final source = MushafRepositoryImpl(bundle: bundle);
      final first = source.load();
      final second = source.load();
      expect(identical(first, second), isTrue);
      await expectLater(first, throwsA(isA<MushafIntegrityException>()));
      expect(bundle.loads, 1);
      await expectLater(
        source.load(),
        throwsA(isA<MushafIntegrityException>()),
      );
      expect(bundle.loads, 2);
    },
  );

  test(
    'verified source creates all pages and every source ayah exactly once',
    () async {
      await repository.load();
      expect(repository.pageCount, 604);
      expect(repository.surahIndex(), hasLength(114));
      expect(repository.page(1).ayahs, isNotEmpty);
      expect(repository.page(604).ayahs, isNotEmpty);
      final refs = <AyahRef>[];
      for (var page = 1; page <= repository.pageCount; page++) {
        refs.addAll(repository.page(page).ayahs.map((ayah) => ayah.ref));
      }
      expect(refs, hasLength(6236));
      expect(refs.toSet(), hasLength(6236));
      expect(repository.juzIndex(), hasLength(30));
      expect(repository.hizbIndex(), hasLength(60));
      final metadata = XmlDocument.parse(
        await rootBundle.loadString('assets/quran/quran-data.xml'),
      );
      final starts = metadata
          .findAllElements('page')
          .map(
            (element) => AyahRef(
              surah: int.parse(element.getAttribute('sura')!),
              ayah: int.parse(element.getAttribute('aya')!),
            ),
          );
      expect([
        for (var page = 1; page <= 604; page++)
          repository.page(page).ayahs.first.ref,
      ], starts);
    },
  );

  test('portionRange uses all metadata units and maps both ends', () async {
    await repository.load();
    for (final unit in PortionUnit.values) {
      final portions = QuranMetadataRepository()..load();
      await portions.load();
      for (final portion in portions.portions(unit)) {
        final range = repository.portionRange(unit, portion.index);
        expect(range.startPage, repository.pageOf(range.start));
        expect(range.endPage, repository.pageOf(range.end));
        expect(range.start.surah, portion.startSura);
        expect(range.start.ayah, portion.startAya);
        expect(range.end.surah, portion.endSura);
        expect(range.end.ayah, portion.endAya);
      }
    }
  });
}

class _CountingBundle extends CachingAssetBundle {
  int loads = 0;
  @override
  Future<ByteData> load(String key) async {
    loads++;
    throw StateError('missing source');
  }
}
