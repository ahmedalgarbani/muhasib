import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

/// Copies user-picked images (logo/signature/seal) into the app support
/// directory and returns the stored path for persistence in settings.
class MediaStorageService {
  static final MediaStorageService _instance = MediaStorageService._();
  factory MediaStorageService() => _instance;
  MediaStorageService._();

  Future<String?> pickAndStoreImage({required String fileName}) async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );
      final sourcePath = result?.files.single.path;
      if (sourcePath == null) return null;

      final directory = await getApplicationSupportDirectory();
      final mediaDir = Directory(join(directory.path, 'muhasib_media'));
      if (!await mediaDir.exists()) {
        await mediaDir.create(recursive: true);
      }

      final target = join(mediaDir.path, '$fileName${extension(sourcePath)}');
      await File(sourcePath).copy(target);
      return target;
    } catch (_) {
      return null;
    }
  }

  bool exists(String? path) {
    if (path == null || path.isEmpty) return false;
    try {
      return File(path).existsSync();
    } catch (_) {
      return false;
    }
  }
}
