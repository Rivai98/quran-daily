import 'dart:ui';

/// Raw engine timings are retained so results can be rechecked at other budgets.
Map<String, Object> summarizeFrames(List<FrameTiming> frames) {
  if (frames.isEmpty) throw ArgumentError('No engine FrameTiming samples');
  final build = [
    for (final frame in frames) frame.buildDuration.inMicroseconds,
  ];
  final raster = [
    for (final frame in frames) frame.rasterDuration.inMicroseconds,
  ];
  double percent(int count) => count * 100 / frames.length;
  int worst(List<int> values) => values.reduce((a, b) => a > b ? a : b);
  return {
    'frame_count': frames.length,
    'budget_ms': 16,
    'worst_build_ms': worst(build) / 1000,
    'worst_raster_ms': worst(raster) / 1000,
    'build_over_16ms_percent': percent(build.where((us) => us > 16000).length),
    'raster_over_16ms_percent': percent(
      raster.where((us) => us > 16000).length,
    ),
    'either_over_16ms_percent': percent(
      frames
          .where(
            (frame) =>
                frame.buildDuration.inMicroseconds > 16000 ||
                frame.rasterDuration.inMicroseconds > 16000,
          )
          .length,
    ),
    'build_us': build,
    'raster_us': raster,
    'total_span_us': [
      for (final frame in frames) frame.totalSpan.inMicroseconds,
    ],
    'vsync_overhead_us': [
      for (final frame in frames) frame.vsyncOverhead.inMicroseconds,
    ],
  };
}
