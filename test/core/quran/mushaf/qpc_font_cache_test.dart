import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_daily/core/quran/mushaf/qpc_font_cache.dart';

void main() {
  late Directory directory;
  const bytes = [1, 2, 3];
  late String digest;
  late QpcFontCache cache;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('qpc_font_cache_');
    digest = sha256.convert(bytes).toString();
    cache = QpcFontCache(
      directory: directory,
      page: 100,
      expectedBytes: bytes.length,
      expectedSha256: digest,
    );
  });
  tearDown(() => directory.delete(recursive: true));

  test('a verified disk cache survives a fresh cache instance', () async {
    expect(await cache.load(), isNull);
    await cache.store(bytes);
    final marker = File('${directory.path}/p100-$digest.verified');
    expect(await marker.exists(), isTrue);
    final restarted = QpcFontCache(
      directory: directory,
      page: 100,
      expectedBytes: bytes.length,
      expectedSha256: digest,
    );
    expect(await restarted.load(), bytes);
  });

  test(
    'same-size mutation with restored mtime cannot reuse verification',
    () async {
      await cache.store(bytes);
      final font = File('${directory.path}/p100.ttf');
      final modified = await font.lastModified();
      await font.writeAsBytes([1, 2, 4], flush: true);
      await font.setLastModified(modified);

      await expectLater(
        cache.load(),
        throwsA(isA<QpcFontIntegrityException>()),
      );
      expect(await font.exists(), isFalse);
      expect(
        await File('${directory.path}/p100-$digest.verified').exists(),
        isFalse,
      );
    },
  );

  test(
    'a changed manifest digest cannot reuse an older verification',
    () async {
      await cache.store(bytes);
      final changed = QpcFontCache(
        directory: directory,
        page: 100,
        expectedBytes: bytes.length,
        expectedSha256: sha256.convert([1, 2, 4]).toString(),
      );
      await expectLater(
        changed.load(),
        throwsA(isA<QpcFontIntegrityException>()),
      );
      expect(await cache.load(), isNull);
    },
  );

  test(
    'malformed markers are replaced only after verifying cached bytes',
    () async {
      await cache.store(bytes);
      final marker = File('${directory.path}/p100-$digest.verified');
      await marker.writeAsString('{broken');
      expect(await cache.load(), bytes);
      expect(await marker.readAsString(), isNot('{broken'));

      await marker.writeAsString('{broken');
      await File('${directory.path}/p100.ttf').writeAsBytes([1, 2, 4]);
      await expectLater(
        cache.load(),
        throwsA(isA<QpcFontIntegrityException>()),
      );
      expect(await marker.exists(), isFalse);
    },
  );

  test(
    'failed downloads leave no marker and concurrent verified reads agree',
    () async {
      await expectLater(
        cache.store([1, 2, 4]),
        throwsA(isA<QpcFontIntegrityException>()),
      );
      expect(await directory.list().toList(), isEmpty);
      await cache.store(bytes);
      final reads = await Future.wait([
        for (var i = 0; i < 4; i++) cache.load(),
      ]);
      expect(reads, everyElement(bytes));
      expect(
        await directory
            .list()
            .where((file) => file.path.endsWith('.tmp'))
            .toList(),
        isEmpty,
      );
    },
  );
}
