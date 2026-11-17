import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';

import '../../integration_test/support/frame_timing_summary.dart';

void main() {
  test('reports strict 16 ms misses per stage and preserves raw samples', () {
    FrameTiming frame(int build, int raster) => FrameTiming(
      vsyncStart: 0,
      buildStart: 0,
      buildFinish: build,
      rasterStart: build,
      rasterFinish: build + raster,
      rasterFinishWallTime: build + raster,
    );

    final summary = summarizeFrames([
      frame(16000, 5000),
      frame(17000, 18000),
      frame(4000, 19000),
      frame(3000, 2000),
    ]);
    expect(summary['frame_count'], 4);
    expect(summary['worst_build_ms'], 17);
    expect(summary['worst_raster_ms'], 19);
    expect(summary['build_over_16ms_percent'], 25);
    expect(summary['raster_over_16ms_percent'], 50);
    expect(summary['either_over_16ms_percent'], 50);
    expect(summary['build_us'], [16000, 17000, 4000, 3000]);
    expect(summary['raster_us'], [5000, 18000, 19000, 2000]);
    expect(() => summarizeFrames([]), throwsArgumentError);
  });
}
