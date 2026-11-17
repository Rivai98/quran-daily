import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quran_daily/core/quran/mushaf/qpc_v2_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory sources;
  late Directory cache;
  late QpcV2Repository layout;

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    sources = await Directory.systemTemp.createTemp('qpc_prefetch_sources_');
    layout = QpcV2Repository(storageDirectory: sources);
    await layout.load();
    registerFallbackValue(Uri());
  });
  tearDownAll(() async {
    await layout.close();
    await sources.delete(recursive: true);
  });
  setUp(() async {
    cache = await Directory.systemTemp.createTemp('qpc_prefetch_cache_');
  });
  tearDown(() => cache.delete(recursive: true));

  test('canceling background preparation closes its network request without registering', () async {
    final client = _Client();
    final started = Completer<void>();
    final response = Completer<HttpClientRequest>();
    var registered = false;
    when(() => client.getUrl(any())).thenAnswer((_) {
      started.complete();
      return response.future;
    });
    when(() => client.close(force: true)).thenAnswer((_) {
      if (!response.isCompleted) {
        response.completeError(const SocketException('cancelled'));
      }
    });
    final fonts = QpcFontManager(
      layout: layout,
      storageDirectory: cache,
      httpClientFactory: () => client,
      registerFont: (_, _) async => registered = true,
    );
    final preparation = fonts.prefetch(100);
    await started.future;
    fonts.cancelPrefetch();
    await preparation;
    expect(fonts.isLoaded(100), isFalse);
    expect(registered, isFalse);
  });

  test('a foreground join survives background cancellation and retains normal errors', () async {
    final client = _Client();
    final started = Completer<void>();
    final response = Completer<HttpClientRequest>();
    var closed = false;
    when(() => client.getUrl(any())).thenAnswer((_) {
      if (!started.isCompleted) started.complete();
      return response.future;
    });
    when(() => client.close(force: true)).thenAnswer((_) => closed = true);
    final fonts = QpcFontManager(
      layout: layout,
      storageDirectory: cache,
      httpClientFactory: () => client,
      registerFont: (_, _) async {},
    );
    final preparation = fonts.prefetch(100);
    final foreground = fonts.ensureLoaded(100);
    final prepared = expectLater(preparation, throwsA(isA<SocketException>()));
    final visible = expectLater(foreground, throwsA(isA<SocketException>()));
    await started.future;
    fonts.cancelPrefetch();
    expect(closed, isFalse, reason: 'the visible page owns the shared request');
    response.completeError(const SocketException('offline'));
    await Future.wait([prepared, visible]);
    expect(fonts.isLoaded(100), isFalse);
  });
}

class _Client extends Mock implements HttpClient {}
