# Mushaf page-turn performance

Target: no dropped frames while turning pages on a mid-range Android phone
(Samsung A53 class), measured in **profile** mode. A debug run or host widget
test cannot establish this target.

## Reproducible benchmark

`integration_test/mushaf_page_turn_perf_test.dart` boots the production reader,
repositories and SQLite position store directly, without authentication or
Supabase. It uses the verified bundled Quran sources and manifest-matching QPC
fonts. Before measuring, it downloads any missing fonts to disk with a no-op
font registrar; it then creates a fresh production font manager. Download time
is excluded, while disk reads, verification and first registration remain in
the measured route.

The dark RTL reader opens page 100. The test taps the forward page edge 20 times
(100 → 120), then the backward edge 20 times (120 → 100). Each turn gets 800 ms
to settle. The first route encounters page fonts and widgets for the first time;
the reverse route revisits them. Existing production prefetch still runs. The
first route is therefore called **cold registration**, not a network-cold run.

The binding uses `fullyLive`, so animation frames run on the device's real
clock. An engine `FrameTiming` listener records build, raster, total-span and
vsync-overhead microseconds. It waits two seconds before and after each route
to flush batched engine timing reports. Summary columns use strict **>16 ms**
per stage; the combined percentage counts each frame once if either build or
raster exceeds that budget. Build and raster are pipelined, so their durations
are not added to infer dropped frames. Raw total-span and vsync-overhead samples
are retained to investigate stalls outside build/raster.

Run from the repository root in PowerShell:

```powershell
flutter devices
$env:MUSHAF_PERF_OUTPUT = 'baseline-default'
flutter drive --profile --driver=test_driver/mushaf_perf.dart --target=integration_test/mushaf_page_turn_perf_test.dart -d <device-id> --dart-define=PERF_STAGE=baseline --dart-define=PERF_RENDERER=default
```

The driver writes `build/mushaf-perf/baseline-default.json` (including raw samples).
Change `MUSHAF_PERF_OUTPUT` and `PERF_STAGE` for each optimization stage. Keep
the device, resolution, refresh rate, temperature and background load comparable.
Do not run builds or host tests while collecting timings. Reinstall/relaunch
the benchmark process for each cold-registration sample. Record physical-device
results separately from emulator results.

For step G, run the same profile command with `--no-enable-impeller`, set
`PERF_RENDERER=skia`, and use a distinct output name. Keep the platform default
unless comparable physical-device measurements clearly favor Skia.

## Baseline environment (2026-11-17)

- Worktree `mushaf-perf`, Windows host; Flutter 3.50.0 (`ab2912035e`),
  Dart 3.14.0, stable SDK verified current.
- No physical Android phone is connected. Available AVD `quran_daily_pixel`
  reports `sdk_gphone64_x86_64`, Android 15 / API 35, 1080 × 2400 pixels,
  density 420, 60 Hz, 4 virtual CPUs and 2 GB RAM. The AVD configuration has
  `hw.gpu.enabled=no` (software graphics); host CPU is Intel Core i5-13500.
  Emulator results cannot verify the Samsung A53 target or physical GPU costs.
- Constitution rule 7 required updating compatible locked patches before the
  baseline: material_ui 1.11.1 and cupertino_ui 1.1.7. No rendering changes or
  performance fixes were applied for the baseline.
- Metrics arithmetic has a host test covering the strict threshold, overlapping
  build/raster misses, worst values, raw-sample retention and empty captures.
- Host gates: `flutter analyze` reports zero issues; `flutter test` passes all
  615 tests. The preexisting two-group Home goldens depended on today's date;
  their fixtures now use the date already present in the images (2026-11-16).
  No golden images changed. These checks finished before runtime capture.

## Results

Baseline captured successfully in profile mode on the emulator above. The
engine logged `Using the Impeller rendering backend (OpenGLES)`. The initial
Android build took 492.6 seconds; the benchmark test took 67 seconds, including
setup and font-cache preparation. Host tests finished before runtime capture.

| Stage / route | Frames | Worst build (ms) | Worst raster (ms) | Build >16 ms | Raster >16 ms | Either >16 ms |
|---|---:|---:|---:|---:|---:|---:|
| Baseline / cold registration 100 → 120 | 367 | 570.424 | 225.057 | 14.99% | 39.78% | 39.78% |
| Baseline / repeat 120 → 100 | 707 | 670.206 | 193.696 | 5.80% | 28.85% | 28.85% |

Raw capture: [baseline-android-emulator-impeller.json](baseline-android-emulator-impeller.json).
Its renderer field is `default`; the engine log above identifies the backend
actually selected. Runtime output is retained locally in
`build-baseline-profile.log`. These are one-run diagnostic emulator results,
with software graphics and normal uncontrolled host background load. They
demonstrate substantial over-budget work in this setup; they do not predict
physical-phone timings or establish the no-dropped-frames target. Before/after
and Skia comparisons must use this same harness, plus a separate profile run on
the target physical phone for acceptance.
