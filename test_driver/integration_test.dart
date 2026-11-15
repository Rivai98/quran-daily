// Driver for integration tests that take screenshots (screenshot tour).
//
//   flutter drive --driver=test_driver/integration_test.dart \
//     --target=integration_test/screenshot_tour_test.dart \
//     -d <device-id> --dart-define-from-file=.env
//
// Every `binding.takeScreenshot(name)` lands in build/screenshots/<name>.png.

import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

Future<void> main() async {
  final directory = Directory('build/screenshots');
  await directory.create(recursive: true);
  await integrationDriver(
    onScreenshot: (name, bytes, [args]) async {
      final file = File('${directory.path}/$name.png');
      await file.writeAsBytes(bytes);
      // ignore: avoid_print
      print('screenshot: ${file.absolute.path}');
      return true;
    },
  );
}
