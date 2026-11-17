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
| B / cold registration 100 → 120 | 270 | 822.540 | 264.326 | 18.52% | 43.70% | 43.70% |
| B / repeat 120 → 100 | 540 | 823.871 | 475.137 | 7.41% | 30.56% | 30.56% |
| C / cold registration 100 → 120 | 346 | 825.496 | 226.307 | 15.61% | 36.13% | 36.42% |
| C / repeat 120 → 100 | 695 | 619.777 | 217.647 | 5.90% | 26.33% | 26.33% |

Raw capture: [baseline-android-emulator-impeller.json](baseline-android-emulator-impeller.json).
Its renderer field is `default`; the engine log above identifies the backend
actually selected. Runtime output is retained locally in
`build-baseline-profile.log`. These are one-run diagnostic emulator results,
with software graphics and normal uncontrolled host background load. They
demonstrate substantial over-budget work in this setup; they do not predict
physical-phone timings or establish the no-dropped-frames target. Before/after
and Skia comparisons must use this same harness, plus a separate profile run on
the target physical phone for acceptance.

## Step B: font verification and persistent cache markers

`QpcFontCache` runs font reads, SHA-256, cache writes and marker writes inside
`Isolate.run`. Only paths, manifest expectations and byte buffers cross that
boundary; font registration stays on Flutter's root isolate. Downloads must
match both the approved manifest's byte count and SHA-256 before an atomic
font replacement and marker write. A failed FontLoader registration no longer
marks the page as loaded, so a later attempt can retry.

Markers are keyed by page and manifest SHA (`p<page>-<sha>.verified`) and record
the verified file size, modification time and POSIX change time. An unchanged
app-private file reuses verification across process restarts. Missing/malformed
markers, changed file state or a new manifest digest require a fresh hash.
The reader checks file state before and after reading; invalid bytes remove the
font and its marker before the existing download recovery runs. Reads still
check byte count even when the marker matches. Marker and font writes use
temporary files and atomic renames, so a partial write cannot certify a font.

This trusts the app-private cache directory and OS metadata. POSIX change time
detects same-size rewrites even when modification time is restored. Privileged
tampering that rewrites both the font and its marker/OS metadata is outside
that trust boundary. Dart exposes creation time for `FileStat.changed` on
Windows, so Windows conservatively hashes every load off-isolate; the mobile
optimization does not weaken that platform's integrity check. See the SDK
contracts for [FileStat.changed](https://api.dart.dev/stable/latest/dart-io/FileStat/changed.html)
and [Isolate.run](https://api.dart.dev/stable/latest/dart-isolate/Isolate/run.html).

Five real-filesystem tests cover restart persistence, same-size tampering with
restored mtime, manifest digest changes, malformed markers, rejected corrupt
downloads and concurrent reads. A concurrent-read test exposed an unnecessary
Windows marker rewrite race; unchanged markers are now left in place even when
Windows rehashes. Step B gates: analyze zero issues, all 620 host tests pass.

The same profile benchmark passed after B with Impeller OpenGLES; its
incremental Android build took 70.2 seconds and the test took 84 seconds.
Raw capture: [step-b-android-emulator-impeller.json](step-b-android-emulator-impeller.json);
local runtime log: `build-step-b-profile.log`. Setup creates valid markers before
timing, modeling page turns after the fonts have been downloaded and verified.

This single software-graphics emulator run demonstrates **no speedup**: the
captured-frame over-budget fraction increased by 3.92 percentage points on the
forward route and 1.70 points on the reverse route. Hashing/file work now runs
off-isolate, but this change alone does not resolve page-turn jank. Host-load
variance and the unchanged widget/layout/paint work prevent attributing those
deltas to one cause. The target remains unmet; subsequent steps must be measured.

## Step C: directional prefetch after settling

The reader observes only the top-level horizontal `ScrollStartNotification`
and `ScrollEndNotification`. A new scroll invalidates queued post-frame/idle
callbacks and background requests. After scroll-end (or the initial content
frame), it waits through any remaining transient animation callbacks, then
schedules the preparation task at `Priority.idle`. Waiting on painted frames
first avoids polling idle tasks while a route animation is active. A widget
regression verifies no prefetch starts during the page animation and that the
next target starts after settling.

`ReaderCubit` prepares only the adjacent page in the last page-number direction
(in RTL, increasing numbers still mean the next page on the left), respecting
both portion boundaries. It serializes speculative work: a reversal clears the
old queued target and waits for the active operation to finish/cancel before
starting the latest settled target. Obsolete settle callbacks and reader
closure cannot start new work. The five-page turn-time fanout and automatic
portion-wide font warmup are removed; the explicit offline font-download flow
is unchanged.

The font manager distinguishes speculative and foreground consumers. A visible
page promotes an existing shared font request so background cancellation cannot
interrupt it. Stale background HTTP clients are closed; cancellation checks
after cache IO/verification prevent stale results entering FontLoader. Work
already inside `Isolate.run` or FontLoader cannot be forcibly canceled; verified
cache bytes remain valid, and a registration already entered may complete.
Such completion does not publish obsolete reader state. Foreground page loading
and its ordinary error/fallback behavior remain immediate.

Tests cover settle-only requests, one active background operation, rapid
reversal, portion boundaries, closure, background network cancellation and
foreground promotion. Step C gates: analyze zero issues, all 627 host tests pass;
no golden images changed.

The same Impeller OpenGLES profile benchmark passed after C (122.1 seconds to
build, 75 seconds for the test). Raw capture:
[step-c-android-emulator-impeller.json](step-c-android-emulator-impeller.json);
local runtime log: `build-step-c-profile.log`. Compared with B, the captured-frame
over-budget fraction fell by 7.29 percentage points forward and 4.22 points in
reverse. Large worst-frame times remain; this emulator result does not establish
the physical-device target or isolate every remaining source of jank.

## Step D: cached page painting and word hit testing

`QpcPageLayout` shapes each word once per page size, inherited text style,
locale and system text scale. It retains the `TextPainter` paragraphs, measured
widths and final word rectangles. `QpcPagePainter` uses those paragraphs for all
Quran lines, basmala and start/end ayah highlights. One page-level gesture
detector hit-tests the same rectangles for long press; ordinary repaints and
highlight changes do not reshape the words. Native paragraphs are disposed when
their page body is disposed or its layout inputs change.

Each page has a `RepaintBoundary`. The former per-word `Text`/`GestureDetector`
and per-line row/FittedBox tree is removed. The existing `SurahTitleBand` remains
as a rare positioned overlay inside that boundary to preserve its ornament and
UI typography exactly. Thus the Quran content has one painted render object;
a page with titles also has the existing title widgets. The band is not
reimplemented in the painter.

The painter provides word long-press semantics and source-ordered header
semantics. Repeated basmala words have occurrence-specific keys; a page 604
regression reproduced duplicate-key failure before that fix. Integer source
ordinals prevent floating-point placement differences from reordering words
within one line. The visible title overlay is excluded from semantics to avoid
duplicate announcements.

There were no existing printed-QPC page goldens. Before replacing the widgets,
six references were captured from the old implementation: pages 1, 100 and 106
in light and dark themes, with start/end highlights. The painter matches all
six **pixel for pixel**. Four offline test fonts are byte-verified against the
approved manifest, including page 604 for repeated-basmala semantics. Quran
glyphs, text, fonts and source line breaks are unchanged.

The new 320 dp / 200% tests exposed an existing justified-row overflow of
264–278 pixels: the old natural-width calculation ignored system text scaling.
The painter uniformly fits those same source words into their existing line
area. Two scaled-page goldens intentionally record this correction rather than
the old overflow stripes; the six 100% references were not updated. Tests also
exercise word and semantic long press, blank-space rejection, complete source
reading order, and hit testing after resize/text-scale changes.


Step D gates: `flutter analyze` reports zero issues and all 630 host tests pass.
The profile integration harness reports all tests passed and retained both
complete routes after a 60.4-second build and 78-second test. Current-process
Android logcat confirms Impeller OpenGLES. Raw capture:
[step-d-android-emulator-impeller.json](step-d-android-emulator-impeller.json);
local runtime log: `build-step-d-profile.log`.

Compared with C, captured-frame over-budget fractions fell by 10.07 percentage
points forward and 2.05 points in reverse. Worst build time fell from 825.496 to
140.935 ms forward and 619.777 to 108.525 ms in reverse. Raster work remains over
budget, including a 556.613 ms cold-route outlier. This remains a single
software-graphics emulator run, not physical-phone acceptance.

The outer PowerShell launch returned exit code 1 despite the harness reporting
success and writing complete data, with no failed test assertion in the log.
The cause of that launcher discrepancy is unresolved; the raw timing data and
harness result are reported separately from the process status.
