import 'dart:ui' show FrameTiming;

import 'package:flutter/foundation.dart' show kProfileMode;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sqflite/sqflite.dart' show getDatabasesPath;
import 'package:quran_daily/core/design_system/app_theme.dart';
import 'package:quran_daily/core/di/service_locator.dart';
import 'package:quran_daily/core/quran/mushaf/mushaf_repository.dart';
import 'package:quran_daily/core/quran/mushaf/qpc_v2_repository.dart';
import 'package:quran_daily/core/quran/quran_metadata_repository.dart';
import 'package:quran_daily/core/storage/local_database.dart';
import 'package:quran_daily/features/mushaf/cubit/reader_cubit.dart';
import 'package:quran_daily/features/mushaf/data/reader_storage.dart';
import 'package:quran_daily/features/mushaf/view/reader_screen.dart';

import 'support/frame_timing_summary.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized()
    ..framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets('profile real Mushaf cold-registration and repeat page turns', (
    tester,
  ) async {
    expect(kProfileMode, isTrue, reason: 'Run flutter drive --profile');
    const first = 100;
    const turns = 20;
    final metadata = QuranMetadataRepository();
    final repository = MushafRepositoryImpl(metadata: metadata);
    final layout = QpcV2Repository();
    final database = LocalDatabase(
      databasePath: '${await getDatabasesPath()}/mushaf_perf.db',
    );
    final storage = SqfliteReaderStorage(
      database: database,
      userId: 'local-mushaf-performance-benchmark',
    );
    await repository.load();
    await layout.load();

    // Populate only the disk cache before measuring. Never register fonts or
    // create page widgets here: the first route must pay their first-use costs.
    final downloader = QpcFontManager(
      layout: layout,
      registerFont: (_, _) async {},
    );
    for (final page in [
      1,
      for (var p = first - 2; p <= first + turns + 3; p++) p,
    ]) {
      await downloader.ensureLoaded(page);
    }
    final fonts = QpcFontManager(layout: layout);
    serviceLocator.registerSingleton<QpcFontManager>(fonts);
    final cubit = ReaderCubit(
      repository: repository,
      storage: storage,
      qpcLayout: layout,
      qpcFonts: fonts,
    );
    addTearDown(() async {
      fonts.cancelDownload();
      await cubit.close();
      await layout.close();
      await database.close();
      serviceLocator.unregister<QpcFontManager>();
    });
    await cubit.openPage(first);
    await tester.pumpWidget(
      BlocProvider.value(
        value: cubit,
        child: MaterialApp(
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: ThemeMode.dark,
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: ReaderScreen(
              repository: repository,
              storage: storage,
              metadata: metadata,
              qpcLayout: layout,
            ),
          ),
        ),
      ),
    );
    await Future<void>.delayed(const Duration(seconds: 2));
    expect(cubit.state.isFontFallback, isFalse);
    binding.reportData = {
      'stage': const String.fromEnvironment(
        'PERF_STAGE',
        defaultValue: 'baseline',
      ),
      'renderer': const String.fromEnvironment(
        'PERF_RENDERER',
        defaultValue: 'default',
      ),
      'mode': 'profile',
      'theme': 'dark',
      'first_page': first,
      'turns_per_route': turns,
      'settle_ms': 800,
      'view_physical_pixels': [
        tester.view.physicalSize.width,
        tester.view.physicalSize.height,
      ],
      'device_pixel_ratio': tester.view.devicePixelRatio,
    };

    Future<void> route(String name, int direction) async {
      // The engine batches timings. Flush preceding frames and leave the
      // listener installed two seconds after the route to receive its tail.
      await Future<void>.delayed(const Duration(seconds: 2));
      final frames = <FrameTiming>[];
      binding.addTimingsCallback(frames.addAll);
      try {
        for (var turn = 1; turn <= turns; turn++) {
          final before = cubit.state.page!.number;
          final rect = tester.getRect(
            find.byKey(const ValueKey('mushaf-page-view')),
          );
          await tester.tapAt(
            Offset(
              direction > 0 ? rect.left + 8 : rect.right - 8,
              rect.center.dy,
            ),
          );
          await Future<void>.delayed(const Duration(milliseconds: 800));
          expect(cubit.state.page!.number, before + direction);
          expect(fonts.isLoaded(before + direction), isTrue);
          expect(tester.takeException(), isNull);
        }
        await Future<void>.delayed(const Duration(seconds: 2));
      } finally {
        binding.removeTimingsCallback(frames.addAll);
      }
      binding.reportData![name] = summarizeFrames(frames);
    }

    await route('cold_registration_forward', 1);
    await route('repeat_reverse', -1);
    expect(cubit.state.page!.number, first);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
