import 'dart:io';

import 'package:flutter/services.dart';

/// Reads the owner-provided Quran metadata fixture without altering or
/// embedding any Quran content in test code.
class QuranMetadataTestAssetBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async =>
      ByteData.sublistView(await File(key).readAsBytes());
}
