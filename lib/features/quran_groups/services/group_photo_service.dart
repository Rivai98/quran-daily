import 'dart:typed_data';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/localization/arabic_strings.dart';

abstract class GroupPhotoService {
  Future<Uint8List?> pickCropAndCompress({required ImageSource source});
}

class DefaultGroupPhotoService implements GroupPhotoService {
  const DefaultGroupPhotoService({
    ImagePicker? picker,
    ImageCropper? cropper,
  })  : _picker = picker,
        _cropper = cropper;

  final ImagePicker? _picker;
  final ImageCropper? _cropper;

  @override
  Future<Uint8List?> pickCropAndCompress({required ImageSource source}) async {
    final picker = _picker ?? ImagePicker();
    final file = await picker.pickImage(source: source);
    if (file == null) return null;

    final cropper = _cropper ?? ImageCropper();
    final cropped = await cropper.cropImage(
      sourcePath: file.path,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: ArabicStrings.changeGroupPhoto,
          initAspectRatio: CropAspectRatioPreset.square,
          lockAspectRatio: true,
        ),
        IOSUiSettings(
          title: ArabicStrings.changeGroupPhoto,
          aspectRatioLockEnabled: true,
          resetAspectRatioEnabled: false,
        ),
      ],
    );
    if (cropped == null) return null;

    final bytes = await FlutterImageCompress.compressWithFile(
      cropped.path,
      minWidth: 512,
      minHeight: 512,
      quality: 80,
      format: CompressFormat.jpeg,
    );
    return bytes;
  }
}
