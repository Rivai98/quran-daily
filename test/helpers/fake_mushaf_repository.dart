import 'package:quran_daily/core/quran/mushaf/mushaf_models.dart';
import 'package:quran_daily/core/quran/mushaf/mushaf_repository.dart';
import 'package:quran_daily/core/quran/portion_unit.dart';

/// Source-backed fake for reader widget tests; it never authors Quran text.
class FakeMushafRepository implements MushafRepository {
  FakeMushafRepository() : _source = MushafRepositoryImpl();

  final MushafRepositoryImpl _source;

  @override
  Future<void> load() => _source.load();

  @override
  int get pageCount => _source.pageCount;

  @override
  MushafPage page(int number) => _source.page(number);

  @override
  int pageOf(AyahRef ref) => _source.pageOf(ref);

  @override
  ({AyahRef start, AyahRef end, int startPage, int endPage}) portionRange(
    PortionUnit unit,
    int index,
  ) => _source.portionRange(unit, index);

  @override
  List<({int surah, String name, int ayahs, int startPage})> surahIndex() =>
      _source.surahIndex();

  @override
  List<({int juz, int startPage})> juzIndex() => _source.juzIndex();

  @override
  List<({int hizb, int startPage})> hizbIndex() => _source.hizbIndex();
}
