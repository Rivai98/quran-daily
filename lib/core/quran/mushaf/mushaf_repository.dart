import '../portion_unit.dart';
import 'mushaf_models.dart';

/// Read-only interface over the bundled, checksum-verified Mushaf data.
abstract class MushafRepository {
  Future<void> load();

  int get pageCount;

  MushafPage page(int number);

  int pageOf(AyahRef ref);

  ({AyahRef start, AyahRef end, int startPage, int endPage}) portionRange(
    PortionUnit unit,
    int index,
  );

  List<({int surah, String name, int ayahs, int startPage})> surahIndex();

  List<({int juz, int startPage})> juzIndex();

  List<({int hizb, int startPage})> hizbIndex();
}
