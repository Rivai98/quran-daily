import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

class QpcFontIntegrityException implements Exception {
  const QpcFontIntegrityException(this.message);
  final String message;
  @override
  String toString() => 'QpcFontIntegrityException: $message';
}

/// App-private verified font bytes. File IO and hashing run outside the UI isolate.
class QpcFontCache {
  QpcFontCache({
    required Directory directory,
    required int page,
    required this._expectedBytes,
    required this._expectedSha256,
  }) : _fontPath = '${directory.path}${Platform.pathSeparator}p$page.ttf',
       _page = page;

  final String _fontPath;
  final int _page;
  final int _expectedBytes;
  final String _expectedSha256;

  File get _font => File(_fontPath);
  File get _marker => File(
    '${_font.parent.path}${Platform.pathSeparator}p$_page-$_expectedSha256.verified',
  );

  Future<Uint8List?> load() => Isolate.run(_load);

  Future<void> store(List<int> bytes) => Isolate.run(() => _store(bytes));

  Uint8List? _load() {
    final before = _font.statSync();
    if (before.type == FileSystemEntityType.notFound) return null;
    final bytes = _font.readAsBytesSync();
    try {
      final matchesMarker = _matchesMarker(before);
      // POSIX ctime detects rewrites even when mtime is restored. Dart reports
      // creation time on Windows, so that platform must always verify the bytes.
      if (Platform.isWindows || !matchesMarker) _verify(bytes);
      if (bytes.length != _expectedBytes ||
          !_sameFileState(before, _font.statSync())) {
        throw QpcFontIntegrityException(
          'Font cache changed during verification',
        );
      }
      if (!matchesMarker) _writeMarker(before);
      return bytes;
    } on QpcFontIntegrityException {
      _discard();
      rethrow;
    }
  }

  void _store(List<int> bytes) {
    _verify(bytes);
    _font.parent.createSync(recursive: true);
    _replaceAtomically(_font, bytes);
    _writeMarker(_font.statSync());
  }

  void _verify(List<int> bytes) {
    if (bytes.length != _expectedBytes ||
        sha256.convert(bytes).toString() != _expectedSha256) {
      throw QpcFontIntegrityException(
        'خط الصفحة $_page غير مطابق للبصمة المعتمدة',
      );
    }
  }

  bool _matchesMarker(FileStat state) {
    if (!_marker.existsSync()) return false;
    try {
      final marker = jsonDecode(_marker.readAsStringSync());
      return marker is Map<String, dynamic> &&
          marker['version'] == 1 &&
          marker['page'] == _page &&
          marker['sha256'] == _expectedSha256 &&
          marker['size'] == state.size &&
          marker['modified'] == state.modified.microsecondsSinceEpoch &&
          marker['changed'] == state.changed.microsecondsSinceEpoch;
    } on FormatException {
      return false;
    }
  }

  void _writeMarker(FileStat state) {
    _replaceAtomically(
      _marker,
      utf8.encode(
        jsonEncode({
          'version': 1,
          'page': _page,
          'sha256': _expectedSha256,
          'size': state.size,
          'modified': state.modified.microsecondsSinceEpoch,
          'changed': state.changed.microsecondsSinceEpoch,
        }),
      ),
    );
  }

  static bool _sameFileState(FileStat before, FileStat after) =>
      before.type == after.type &&
      before.size == after.size &&
      before.modified == after.modified &&
      before.changed == after.changed;

  static void _replaceAtomically(File destination, List<int> bytes) {
    final temporary = File(
      '${destination.path}.${Isolate.current.hashCode}.tmp',
    );
    try {
      temporary.writeAsBytesSync(bytes, flush: true);
      temporary.renameSync(destination.path);
    } finally {
      if (temporary.existsSync()) temporary.deleteSync();
    }
  }

  void _discard() {
    for (final file in [_font, _marker]) {
      if (file.existsSync()) file.deleteSync();
    }
  }
}
