import 'dart:io';

import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_daily/core/quran/mushaf/qpc_v2_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory temp;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });
  setUp(() async {
    temp = await Directory.systemTemp.createTemp('qpc_v2_test_');
  });
  tearDown(() async {
    await temp.delete(recursive: true);
  });

  test(
    'QPC V2 bundled layout has 604 pages of exactly 15 ordered lines',
    () async {
      final repository = QpcV2Repository(storageDirectory: temp);
      addTearDown(repository.close);
      await repository.load();

      expect(repository.pageCount, 604);
      for (var page = 1; page <= repository.pageCount; page++) {
        final lines = repository.linesForPage(page);
        expect(lines, hasLength(15), reason: 'page $page');
        for (var i = 0; i < lines.length; i++) {
          expect(lines[i].lineNumber, i + 1, reason: 'page $page');
          if (lines[i].lineType == QpcLineType.ayah) {
            expect(
              lines[i].words,
              isNotEmpty,
              reason: 'page $page line ${i + 1}',
            );
            expect(lines[i].words.first.id, lines[i].firstWordId);
            expect(lines[i].words.last.id, lines[i].lastWordId);
          }
        }
      }
      expect(repository.totalWords, 83668);
      expect(repository.wordLineAssignments, 83668);
      final ids = [
        for (var page = 1; page <= repository.pageCount; page++)
          for (final line in repository.linesForPage(page))
            for (final word in line.words) word.id,
      ];
      expect(ids, List<int>.generate(83668, (index) => index + 1));
    },
  );

  test('font manifest verifier accepts bytes with the expected digest', () {
    expect(
      () => QpcV2Repository.verifyFontBytes(
        page: 1,
        bytes: [1, 2, 3],
        expectedSha256:
            '039058c6f2c0cb492c533b0a4d14ef77cc0f78abccced5287d84a1a2011cfb81',
        expectedBytes: 3,
      ),
      returnsNormally,
    );
  });

  test('font manifest verifier rejects an invalid digest', () async {
    expect(
      () => QpcV2Repository.verifyFontBytes(
        page: 1,
        bytes: [1, 2, 3],
        expectedSha256:
            '1686695486474b88a24a05cd4578f5295961bc9516885309ec95be574f213c27',
        expectedBytes: 3,
      ),
      throwsA(isA<QpcFontIntegrityException>()),
    );
  });
}
