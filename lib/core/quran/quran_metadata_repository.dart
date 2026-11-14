import 'package:flutter/services.dart' show AssetBundle, rootBundle;
import 'package:xml/xml.dart';

import 'juz_info.dart';

/// Reads juz boundaries, surah names, and surah ayah counts from the
/// verified Tanzil metadata file `assets/quran/quran-data.xml`
/// (constitution Principle VII — no Quranic value is ever authored).
///
/// End boundaries are DERIVED: every juz ends one ayah before the next
/// juz starts, crossing sura boundaries via the file's ayah counts; juz 30
/// ends at the last ayah of the last sura.
class QuranMetadataRepository {
  QuranMetadataRepository({AssetBundle? bundle}) : _bundle = bundle;

  static const String assetPath = 'assets/quran/quran-data.xml';

  final AssetBundle? _bundle;

  List<Map<String, String>>? _suras;
  List<Map<String, String>>? _juzs;

  /// Parses the bundled metadata; throws when the asset is missing or
  /// malformed. Safe to call repeatedly (parses once).
  Future<void> load() async {
    if (_suras != null && _juzs != null) return;

    final String xmlText;
    try {
      final data =
          await (_bundle ?? rootBundle).loadString(assetPath, cache: false);
      xmlText = data;
    } catch (error) {
      throw QuranMetadataException('Quran metadata asset unavailable', error);
    }

    try {
      final doc = XmlDocument.parse(xmlText);
      _suras = doc
          .findAllElements('sura')
          .map((e) => {
                'index': e.getAttribute('index')!,
                'ayas': e.getAttribute('ayas')!,
                'name': e.getAttribute('name')!,
              })
          .toList();
      _juzs = doc
          .findAllElements('juz')
          .map((e) => {
                'index': e.getAttribute('index')!,
                'sura': e.getAttribute('sura')!,
                'aya': e.getAttribute('aya')!,
              })
          .toList();
    } catch (error) {
      throw QuranMetadataException('Quran metadata parse failure', error);
    }

    if (_suras!.length != 114 || _juzs!.length != 30) {
      throw QuranMetadataException(
        'unexpected metadata shape: '
        '${_suras!.length} suras, ${_juzs!.length} juz',
        null,
      );
    }
  }

  /// Juz [number] (1..30) with derived end boundary.
  JuzInfo juz(int number) {
    _ensureLoaded();
    if (number < 1 || number > 30) {
      throw RangeError.range(number, 1, 30, 'juz number');
    }

    final start = _juzs![number - 1];
    final startSura = int.parse(start['sura']!);
    final startAya = int.parse(start['aya']!);

    if (number < 30) {
      final next = _juzs![number];
      final nextSura = int.parse(next['sura']!);
      final nextAya = int.parse(next['aya']!);
      // One ayah before the next juz start; a next start at aya 1 means
      // this juz ends at the previous sura's last ayah (from the file).
      if (nextAya == 1) {
        final prevSura = nextSura - 1;
        return JuzInfo(
          number: number,
          startSura: startSura,
          startAya: startAya,
          endSura: prevSura,
          endAya: suraAyahCount(prevSura),
        );
      }
      return JuzInfo(
        number: number,
        startSura: startSura,
        startAya: startAya,
        endSura: nextSura,
        endAya: nextAya - 1,
      );
    }

    // Juz 30 ends at the last ayah of the last sura, per the file.
    final lastSura = _suras!.length;
    return JuzInfo(
      number: 30,
      startSura: startSura,
      startAya: startAya,
      endSura: lastSura,
      endAya: suraAyahCount(lastSura),
    );
  }

  /// Arabic surah name straight from the file.
  String suraName(int sura) {
    _ensureLoaded();
    _checkSura(sura);
    return _suras![sura - 1]['name']!;
  }

  /// Number of ayat of [sura] straight from the file.
  int suraAyahCount(int sura) {
    _ensureLoaded();
    _checkSura(sura);
    return int.parse(_suras![sura - 1]['ayas']!);
  }

  void _ensureLoaded() {
    if (_suras == null || _juzs == null) {
      throw StateError('QuranMetadataRepository.load() must complete first');
    }
  }

  void _checkSura(int sura) {
    if (sura < 1 || sura > 114) {
      throw RangeError.range(sura, 1, 114, 'sura number');
    }
  }
}

class QuranMetadataException implements Exception {
  const QuranMetadataException(this.message, this.cause);

  final String message;
  final Object? cause;

  @override
  String toString() =>
      'QuranMetadataException: $message${cause == null ? '' : ' ($cause)'}';
}
