import 'dart:io';

import 'package:integration_test/integration_test_driver.dart';

Future<void> main() => integrationDriver(
  responseDataCallback: (data) => writeResponseData(
    data,
    destinationDirectory: 'build/mushaf-perf',
    testOutputFilename:
        Platform.environment['MUSHAF_PERF_OUTPUT'] ?? 'baseline',
  ),
  writeResponseOnFailure: true,
);
