# Dependency status (constitution: Toolchain & Dependency Currency)

Checked 2026-11-16 on Flutter 3.50.0 / Dart 3.14.0, Gradle 9.5.0, AGP 9.3.1, compileSdk 37.

All direct dependencies are on their latest versions. The packages below are
behind only because the Flutter SDK pins them:
cross_file, material_color_utilities, test, test_api, test_core, cli_util, coverage.

## Open items

| Package | Issue | Action | Retry |
|---|---|---|---|
| flutter_image_compress_common | Still applies the Kotlin Gradle Plugin; Flutter warns that a future release will refuse to build plugins that do this. | Watch for a release with Built-in Kotlin support; replace the package if none arrives. | Next Flutter upgrade |
