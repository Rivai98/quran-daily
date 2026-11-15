import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

enum QpcLineType { surahName, basmallah, ayah, blank }

class QpcWord {
  const QpcWord({
    required this.id,
    required this.location,
    required this.surah,
    required this.ayah,
    required this.word,
    required this.text,
  });

  final int id;
  final String location;
  final int surah;
  final int ayah;
  final int word;
  final String text;
}

class QpcLine {
  const QpcLine({
    required this.pageNumber,
    required this.lineNumber,
    required this.lineType,
    required this.isCentered,
    required this.firstWordId,
    required this.lastWordId,
    required this.surahNumber,
    required this.words,
  });

  final int pageNumber;
  final int lineNumber;
  final QpcLineType lineType;
  final bool isCentered;
  final int? firstWordId;
  final int? lastWordId;
  final int? surahNumber;
  final List<QpcWord> words;
}

class QpcFontIntegrityException implements Exception {
  const QpcFontIntegrityException(this.message);
  final String message;
  @override
  String toString() => 'QpcFontIntegrityException: $message';
}

/// Reads the owner supplied QPC V2 SQLite sources without transforming their text.
class QpcV2Repository {
  QpcV2Repository({AssetBundle? bundle, Directory? storageDirectory})
    : _bundle = bundle ?? rootBundle,
      _storageDirectory = storageDirectory;

  static const layoutAsset = 'assets/quran/qpc_v2/qpc-v2-15-lines.db';
  static const wordsAsset = 'assets/quran/qpc_v2/qpc-v2.db';
  static const manifestAsset = 'assets/quran/qpc_v2/qpc_v2_fonts_manifest.json';
  final AssetBundle _bundle;
  final Directory? _storageDirectory;
  final Map<int, List<QpcLine>> _pages = {};
  Database? _layoutDb;
  Database? _wordsDb;
  Map<String, dynamic>? _fontManifest;
  int _totalWords = 0;
  int _wordLineAssignments = 0;

  int get pageCount => _pages.length;
  int get totalWords => _totalWords;
  int get wordLineAssignments => _wordLineAssignments;
  List<QpcWord> get basmallahWords => [
    for (var id = 1; id <= 4; id++)
      for (final line in _pages.values)
        for (final row in line)
          for (final word in row.words)
            if (word.id == id) word,
  ];

  Future<void> close() async {
    await _layoutDb?.close();
    await _wordsDb?.close();
    _layoutDb = null;
    _wordsDb = null;
  }

  Future<void> load() async {
    if (_pages.isNotEmpty) return;
    await _verifyBundled(layoutAsset);
    await _verifyBundled(wordsAsset);
    await _verifyBundled(manifestAsset);
    final dir = _storageDirectory ?? await getApplicationDocumentsDirectory();
    final sourceDir = Directory('${dir.path}${Platform.pathSeparator}qpc_v2');
    await sourceDir.create(recursive: true);
    final layoutFile = await _materialize(layoutAsset, sourceDir);
    final wordsFile = await _materialize(wordsAsset, sourceDir);
    _layoutDb = await openDatabase(layoutFile.path, readOnly: true);
    _wordsDb = await openDatabase(wordsFile.path, readOnly: true);
    _fontManifest =
        jsonDecode(await _bundle.loadString(manifestAsset))
            as Map<String, dynamic>;
    _totalWords =
        Sqflite.firstIntValue(
          await _wordsDb!.rawQuery('SELECT COUNT(*) FROM words'),
        ) ??
        0;
    final wordCache = <int, QpcWord>{};
    for (final row in await _wordsDb!.query('words', orderBy: 'id')) {
      final word = QpcWord(
        id: row['id']! as int,
        location: row['location']! as String,
        surah: row['surah']! as int,
        ayah: row['ayah']! as int,
        word: row['word']! as int,
        text: row['text']! as String,
      );
      wordCache[word.id] = word;
    }
    final rows = await _layoutDb!.query(
      'pages',
      orderBy: 'page_number, line_number',
    );
    final wordLines = <int, List<Map<String, Object?>>>{};
    for (final row in rows) {
      if (row['line_type'] != 'ayah') continue;
      final first = row['first_word_id']! as int;
      final last = row['last_word_id']! as int;
      for (var id = first; id <= last; id++) {
        wordLines.putIfAbsent(id, () => []).add(row);
      }
    }
    _wordLineAssignments = wordLines.values.fold(
      0,
      (sum, entries) => sum + entries.length,
    );
    if (rows.length != 9046 ||
        _totalWords != 83668 ||
        wordLines.length != _totalWords ||
        wordLines.values.any((entries) => entries.length != 1)) {
      throw const QpcFontIntegrityException('مصدر تخطيط المصحف غير مكتمل');
    }
    for (var page = 1; page <= 604; page++) {
      final pageRows = rows.where((row) => row['page_number'] == page).toList();
      final lines = <QpcLine>[];
      for (final row in pageRows) {
        final type = switch (row['line_type']) {
          'surah_name' => QpcLineType.surahName,
          'basmallah' => QpcLineType.basmallah,
          'ayah' => QpcLineType.ayah,
          _ => throw const QpcFontIntegrityException('نوع سطر غير معروف'),
        };
        final firstWordId = type == QpcLineType.ayah
            ? row['first_word_id']! as int
            : null;
        final lastWordId = type == QpcLineType.ayah
            ? row['last_word_id']! as int
            : null;
        final words = <QpcWord>[];
        if (firstWordId != null && lastWordId != null) {
          for (var id = firstWordId; id <= lastWordId; id++) {
            final word = wordCache[id];
            if (word == null) {
              throw QpcFontIntegrityException('الكلمة $id غير موجودة');
            }
            words.add(word);
          }
        }
        lines.add(
          QpcLine(
            pageNumber: page,
            lineNumber: row['line_number']! as int,
            lineType: type,
            isCentered: row['is_centered'] == 1,
            firstWordId: firstWordId,
            lastWordId: lastWordId,
            surahNumber: row['surah_number'] is int
                ? row['surah_number']! as int
                : null,
            words: List.unmodifiable(words),
          ),
        );
      }
      while (lines.length < 15) {
        lines.add(
          QpcLine(
            pageNumber: page,
            lineNumber: lines.length + 1,
            lineType: QpcLineType.blank,
            isCentered: false,
            firstWordId: null,
            lastWordId: null,
            surahNumber: null,
            words: const [],
          ),
        );
      }
      _pages[page] = List.unmodifiable(lines);
    }
    if (_pages.length != 604 ||
        _pages.values.any((lines) => lines.length != 15)) {
      throw const QpcFontIntegrityException(
        'يجب أن يحتوي كل وجه على خمسة عشر سطراً',
      );
    }
  }

  List<QpcLine> linesForPage(int page) {
    final result = _pages[page];
    if (result == null) {
      throw RangeError.range(page, 1, pageCount, 'page');
    }
    return result;
  }

  Map<String, Object> fontInfo(int page) {
    final entry =
        (_fontManifest?['files'] as Map<String, dynamic>?)?['p$page.ttf'];
    if (entry is! Map<String, dynamic>) {
      throw RangeError.range(page, 1, 604, 'page');
    }
    return {
      'sha256': entry['sha256'] as String,
      'bytes': entry['bytes'] as int,
    };
  }

  static void verifyFontBytes({
    required int page,
    required List<int> bytes,
    required String expectedSha256,
    required int expectedBytes,
  }) {
    if (bytes.length != expectedBytes ||
        sha256.convert(bytes).toString() != expectedSha256) {
      throw QpcFontIntegrityException(
        'خط الصفحة $page غير مطابق للبصمة المعتمدة',
      );
    }
  }

  Future<File> _materialize(String asset, Directory directory) async {
    final file = File(
      '${directory.path}${Platform.pathSeparator}${asset.split('/').last}',
    );
    if (!await file.exists()) {
      final data = await _bundle.load(asset);
      await file.writeAsBytes(
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
        flush: true,
      );
    }
    return file;
  }

  Future<void> _verifyBundled(String asset) async {
    final data = await _bundle.load(asset);
    final bytes = data.buffer.asUint8List(
      data.offsetInBytes,
      data.lengthInBytes,
    );
    final checksums = await _bundle.loadString('assets/quran/checksums.sha256');
    final relative = asset.substring('assets/quran/'.length);
    final match = RegExp(
      r'^([0-9a-f]{64})\s+\*?' + RegExp.escape(relative) + r'\s*$',
      multiLine: true,
    ).firstMatch(checksums);
    if (match == null || sha256.convert(bytes).toString() != match.group(1)) {
      throw const QpcFontIntegrityException(
        'ملف مصدر المصحف غير مطابق للبصمة المعتمدة',
      );
    }
  }
}

typedef QpcFontRegistrar =
    Future<void> Function(String family, List<int> bytes);

/// Downloads, verifies, and caches only manifest-matching page fonts.
class QpcFontManager {
  QpcFontManager({
    required this.layout,
    Directory? storageDirectory,
    HttpClient Function()? httpClientFactory,
    QpcFontRegistrar? registerFont,
  }) : _storageDirectory = storageDirectory,
       _httpClientFactory = httpClientFactory ?? HttpClient.new,
       _registerFont = registerFont ?? _registerFlutterFont;

  /// Byte-identical mirrors of the KFGQPC QPC V2 page fonts (verified against the
  /// bundled manifest before use; any mismatch is rejected).
  static const fontBaseUrls = [
    'https://static.qurancdn.com/fonts/quran/hafs/v2/ttf',
    'https://verses.quran.foundation/fonts/quran/hafs/v2/ttf',
  ];
  static const _userAgent = 'Mozilla/5.0 (Linux; Android) HalaqaApp/1.0';
  final QpcV2Repository layout;
  final Directory? _storageDirectory;
  final HttpClient Function() _httpClientFactory;
  final QpcFontRegistrar _registerFont;
  final Set<int> _loaded = {};
  HttpClient? _activeClient;
  bool _cancelRequested = false;
  bool get isCancelled => _cancelRequested;

  Future<int> totalBytes() async {
    await layout.load();
    var total = 0;
    for (var page = 1; page <= 604; page++) {
      total += layout.fontInfo(page)['bytes']! as int;
    }
    return total;
  }

  Future<String> ensureLoaded(int page) async {
    final info = layout.fontInfo(page);
    final dir = await _fontDirectory();
    final file = File('${dir.path}${Platform.pathSeparator}p$page.ttf');
    List<int> bytes;
    if (await file.exists()) {
      bytes = await file.readAsBytes();
      try {
        QpcV2Repository.verifyFontBytes(
          page: page,
          bytes: bytes,
          expectedSha256: info['sha256']! as String,
          expectedBytes: info['bytes']! as int,
        );
      } on QpcFontIntegrityException {
        await file.delete();
        bytes = await _download(page, info, file);
      }
    } else {
      bytes = await _download(page, info, file);
    }
    final family = 'qpcv2_p$page';
    if (_loaded.add(page)) await _registerFont(family, bytes);
    return family;
  }

  Future<void> downloadAll({
    required void Function(int completed, int total) onProgress,
  }) async {
    _cancelRequested = false;
    for (var page = 1; page <= 604; page++) {
      if (_cancelRequested) break;
      await ensureLoaded(page);
      onProgress(page, 604);
    }
  }

  void cancelDownload() {
    _cancelRequested = true;
    _activeClient?.close(force: true);
    _activeClient = null;
  }

  Future<int> cachedBytes() async {
    final dir = await _fontDirectory();
    var sum = 0;
    await for (final entry in dir.list()) {
      if (entry is File && entry.path.toLowerCase().endsWith('.ttf')) {
        sum += await entry.length();
      }
    }
    return sum;
  }

  Future<void> deleteCache() async {
    cancelDownload();
    _loaded.clear();
    final dir = await _fontDirectory();
    if (await dir.exists()) await dir.delete(recursive: true);
  }

  Future<List<int>> _download(
    int page,
    Map<String, Object> info,
    File destination,
  ) async {
    Object? lastError;
    for (final base in fontBaseUrls) {
      if (_cancelRequested) throw const HttpException('download cancelled');
      final client = _httpClientFactory();
      _activeClient = client;
      try {
        final request = await client.getUrl(Uri.parse('$base/p$page.ttf'));
        request.headers.set(HttpHeaders.userAgentHeader, _userAgent);
        final response = await request.close();
        if (_cancelRequested) throw const HttpException('download cancelled');
        if (response.statusCode != HttpStatus.ok) {
          lastError = HttpException('HTTP ${response.statusCode}');
          await response.drain<void>();
          continue;
        }
        final bytes = await response.fold<List<int>>(
          <int>[],
          (data, chunk) => data..addAll(chunk),
        );
        try {
          QpcV2Repository.verifyFontBytes(
            page: page,
            bytes: bytes,
            expectedSha256: info['sha256']! as String,
            expectedBytes: info['bytes']! as int,
          );
        } on QpcFontIntegrityException catch (error) {
          lastError = error;
          continue;
        }
        await destination.parent.create(recursive: true);
        await destination.writeAsBytes(bytes, flush: true);
        return bytes;
      } on SocketException catch (error) {
        lastError = error;
      } finally {
        client.close(force: true);
        if (identical(_activeClient, client)) _activeClient = null;
      }
    }
    throw lastError ?? const HttpException('font unavailable');
  }

  Future<Directory> _fontDirectory() async {
    final base = _storageDirectory ?? await getApplicationDocumentsDirectory();
    return Directory('${base.path}${Platform.pathSeparator}mushaf_fonts');
  }

  static Future<void> _registerFlutterFont(
    String family,
    List<int> bytes,
  ) async {
    final loader = FontLoader(family)
      ..addFont(Future.value(ByteData.sublistView(Uint8List.fromList(bytes))));
    await loader.load();
  }
}
