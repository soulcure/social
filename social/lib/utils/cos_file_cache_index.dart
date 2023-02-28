import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:hive/hive.dart';
import 'package:im/db/db.dart';
import 'package:im/utils/universal_platform.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pedantic/pedantic.dart';
import 'package:video_player/video_player.dart';

class CosUploadFileIndexCache {
  static String docPath;

  static Future<void> _getDocPath() async {
    if (UniversalPlatform.isIOS) {
      final dir = await getApplicationDocumentsDirectory();
      docPath = dir.path;
    }
    if (UniversalPlatform.isAndroid) {
      final dir = await getTemporaryDirectory();
      docPath = dir.path;
    }
  }

  static Future<void> _openCosFileDirIndexBoxIfNeed() async {
    if (!(Db.cosFileDirIndexBox?.isOpen ?? false))
      Db.cosFileDirIndexBox = await Hive.openBox<String>("cosFileDirIndexBox");
  }

  static Future<void> cache(String cdnUrl, String filePath) async {
    if (!UniversalPlatform.isMobileDevice) return;
    if (filePath == null || filePath.isEmpty) return;
    if (cdnUrl == null || cdnUrl.isEmpty) return;

    if (docPath == null) {
      await _getDocPath();
    }
    final hash = md5.convert(utf8.encode(cdnUrl)).toString();
    String relPath;
    if (filePath.contains(filePath)) {
      relPath = filePath.replaceAll(docPath, "");
    }
    await _openCosFileDirIndexBoxIfNeed();
    await Db.cosFileDirIndexBox.put(hash, relPath);
  }

  static String cachePath(String cdnUrl) {
    if (cdnUrl == null) return null;
    if (!UniversalPlatform.isMobileDevice) return null;
    if (docPath == null) {
      unawaited(_getDocPath());
      return null;
    }
    final hash = md5.convert(utf8.encode(cdnUrl)).toString();
    if (!(Db.cosFileDirIndexBox?.isOpen ?? false)) {
      unawaited(_openCosFileDirIndexBoxIfNeed());
      return null;
    }
    final path = Db.cosFileDirIndexBox.get(hash);
    if (path == null) return null;
    if (File("$docPath$path").existsSync()) {
      return "$docPath$path";
    }
    Db.cosFileDirIndexBox.delete(hash);
    return null;
  }

  static VideoPlayerController videoControllerDispatch(String videoUrl,
      {bool isCache = true}) {
    final filePath = CosUploadFileIndexCache.cachePath(videoUrl);
    return filePath != null
        ? VideoPlayerController.file(File(filePath))
        : VideoPlayerController.network(
            isCache ? "$videoUrl.cachevideo" : videoUrl);
  }
}
