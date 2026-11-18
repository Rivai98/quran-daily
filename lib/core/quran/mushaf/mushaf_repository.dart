import 'package:flutter/services.dart' show AssetBundle, rootBundle;

import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart' show compute;
import 'package:xml/xml.dart';

import '../portion_unit.dart';
import '../quran_metadata_repository.dart';
import 'mushaf_models.dart';

abstract interface class MushafRepository {
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

class MushafRepositoryImpl implements MushafRepository {
  MushafRepositoryImpl({QuranMetadataRepository? metadata, AssetBundle? bundle})
    : _metadata = metadata ?? QuranMetadataRepository(),
      _bundle = bundle ?? rootBundle;

  static const textAsset = 'assets/quran/hafs/qpc-hafs.json';
  static const fontAsset = 'assets/fonts/kfgqpc_hafs/UthmanicHafs_V22.ttf';
  static const _quranChecksums = 'assets/quran/checksums.sha256';
  static const _fontChecksums = 'assets/fonts/checksums.sha256';

  final QuranMetadataRepository _metadata;
  final AssetBundle _bundle;
  List<MushafPage>? _pages;
  Map<AyahRef, int>? _pageByAyah;
  List<({int surah, String name, int ayahs, int startPage})>? _suras;
  List<({int juz, int startPage})>? _juzs;
  List<({int hizb, int startPage})>? _hizbs;

  @override
  Future<void> load() async {
    if (_pages != null) return;
    try {
      final textBytes = (await _bundle.load(textAsset)).buffer.asUint8List();
      final fontBytes = (await _bundle.load(fontAsset)).buffer.asUint8List();
      await _verify(textBytes, _quranChecksums, 'hafs/qpc-hafs.json');
      await _verify(
        fontBytes,
        _fontChecksums,
        'kfgqpc_hafs/UthmanicHafs_V22.ttf',
      );
      await _metadata.load();
      final xml = await _bundle.loadString(QuranMetadataRepository.assetPath);
      final parsed = await _parseInIsolate(textBytes);
      _build(parsed, xml);
    } on MushafIntegrityException {
      rethrow;
    } catch (error) {
      throw MushafIntegrityException(
        'Mushaf source unavailable or invalid: $error',
      );
    }
  }

  Future<void> _verify(
    List<int> bytes,
    String checksumAsset,
    String path,
  ) async {
    final checksums = await _bundle.loadString(checksumAsset);
    final match = RegExp(
      r'^([0-9a-f]{64})\s+\*?' + RegExp.escape(path) + r'\s*$',
      multiLine: true,
    ).firstMatch(checksums);
    if (match == null || _sha256(bytes) != match.group(1)) {
      throw MushafIntegrityException('Checksum mismatch for $path');
    }
  }

  @override
  int get pageCount => _ready(_pages).length;

  @override
  MushafPage page(int number) {
    final pages = _ready(_pages);
    if (number < 1 || number > pages.length) {
      throw RangeError.range(number, 1, pages.length, 'page number');
    }
    return pages[number - 1];
  }

  @override
  int pageOf(AyahRef ref) {
    final page = _ready(_pageByAyah)[ref];
    if (page == null) throw RangeError('Unknown ayah reference: $ref');
    return page;
  }

  ({AyahRef start, AyahRef end, int startPage, int endPage}) portionPages(
    PortionUnit unit,
    int index,
  ) => portionRange(unit, index);

  @override
  ({AyahRef start, AyahRef end, int startPage, int endPage}) portionRange(
    PortionUnit unit,
    int index,
  ) {
    final p = _metadata.portion(unit, index);
    final start = AyahRef(surah: p.startSura, ayah: p.startAya);
    final end = AyahRef(surah: p.endSura, ayah: p.endAya);
    return (
      start: start,
      end: end,
      startPage: pageOf(start),
      endPage: pageOf(end),
    );
  }

  @override
  List<({int surah, String name, int ayahs, int startPage})> surahIndex() =>
      List.unmodifiable(_ready(_suras));

  @override
  List<({int juz, int startPage})> juzIndex() =>
      List.unmodifiable(_ready(_juzs));

  @override
  List<({int hizb, int startPage})> hizbIndex() =>
      List.unmodifiable(_ready(_hizbs));

  void _build(Map<String, Map<String, Object?>> rows, String xmlText) {
    final doc = _parseXml(xmlText);
    final pageStarts = doc
        .findAllElements('page')
        .map(
          (e) => AyahRef(
            surah: int.parse(e.getAttribute('sura')!),
            ayah: int.parse(e.getAttribute('aya')!),
          ),
        )
        .toList();
    final juzStarts = doc
        .findAllElements('juz')
        .map(
          (e) => AyahRef(
            surah: int.parse(e.getAttribute('sura')!),
            ayah: int.parse(e.getAttribute('aya')!),
          ),
        )
        .toList();
    final suraRows = doc.findAllElements('sura').toList();
    if (rows.length != 6236 ||
        pageStarts.length != 604 ||
        suraRows.length != 114) {
      throw const MushafIntegrityException('Unexpected Mushaf source counts');
    }
    final ordered = rows.values.toList()
      ..sort((a, b) => (a['id']! as int).compareTo(b['id']! as int));
    final builtPages = <MushafPage>[];
    final lookup = <AyahRef, int>{};
    var cursor = 0;
    var juzNumber = 1;
    for (var i = 0; i < pageStarts.length; i++) {
      final start = pageStarts[i];
      final end = i + 1 < pageStarts.length
          ? pageStarts[i + 1]
          : const AyahRef(surah: 115, ayah: 1);
      while (juzNumber < juzStarts.length &&
          _beforeOrEqual(juzStarts[juzNumber], start)) {
        juzNumber++;
      }
      final ayahs = <MushafAyah>[];
      while (cursor < ordered.length) {
        final row = ordered[cursor++];
        final ref = AyahRef(
          surah: row['surah']! as int,
          ayah: row['ayah']! as int,
        );
        if (!_before(ref, end)) {
          cursor--;
          break;
        }
        if (_before(ref, start)) continue;
        lookup[ref] = i + 1;
        ayahs.add(MushafAyah(ref: ref, text: row['text']! as String));
      }
      if (ayahs.isEmpty || ayahs.first.ref != start) {
        throw const MushafIntegrityException(
          'Page start does not match source ayahs',
        );
      }
      builtPages.add(
        MushafPage(
          number: i + 1,
          ayahs: List.unmodifiable(ayahs),
          juz: juzNumber,
          firstSurah: start.surah,
        ),
      );
    }
    if (lookup.length != 6236) {
      throw const MushafIntegrityException('Ayah page mapping incomplete');
    }
    final suras = [
      for (var i = 0; i < suraRows.length; i++)
        (
          surah: i + 1,
          name: suraRows[i].getAttribute('name')!,
          ayahs: int.parse(suraRows[i].getAttribute('ayas')!),
          startPage: lookup[AyahRef(surah: i + 1, ayah: 1)]!,
        ),
    ];
    final juzs = [
      for (var i = 0; i < juzStarts.length; i++)
        (juz: i + 1, startPage: lookup[juzStarts[i]]!),
    ];
    final hizbs = [
      for (var i = 0; i < 60; i++)
        (
          hizb: i + 1,
          startPage:
              lookup[AyahRef(
                surah: _metadata.portion(PortionUnit.hizb, i + 1).startSura,
                ayah: _metadata.portion(PortionUnit.hizb, i + 1).startAya,
              )]!,
        ),
    ];
    _pages = List.unmodifiable(builtPages);
    _pageByAyah = Map.unmodifiable(lookup);
    _suras = List.unmodifiable(suras);
    _juzs = List.unmodifiable(juzs);
    _hizbs = List.unmodifiable(hizbs);
  }

  T _ready<T>(T? value) =>
      value ??
      (throw StateError('MushafRepository.load() must complete first'));
}

bool _before(AyahRef a, AyahRef b) =>
    a.surah < b.surah || a.surah == b.surah && a.ayah < b.ayah;
bool _beforeOrEqual(AyahRef a, AyahRef b) => a == b || _before(a, b);

// Helpers are top-level to keep this library's model contract compact.
String _sha256(List<int> bytes) => sha256.convert(bytes).toString();
XmlDocument _parseXml(String source) => XmlDocument.parse(source);
Future<Map<String, Map<String, Object?>>> _parseInIsolate(List<int> bytes) =>
    compute(_decodeJson, utf8.decode(bytes));

Map<String, Map<String, Object?>> _decodeJson(String source) {
  final decoded = jsonDecode(source) as Map<String, dynamic>;
  return decoded.map(
    (key, value) => MapEntry(key, Map<String, Object?>.from(value as Map)),
  );
}
