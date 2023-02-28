import 'dart:async';
import 'dart:io';
import 'package:im/pages/home/view/check_permission.dart';
import 'package:im/utils/cos_file_cache_index.dart';
import 'package:im/utils/storage_util.dart';
import 'package:im/utils/universal_platform.dart';
import 'package:multi_image_picker/multi_image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'gallery.dart';

extension GalleryStateExtension on GalleryState {
  Future<void> saveGalleryImage(GalleryItem item) async {
    final permission = await checkSystemPermissions(
      context: context,
      permissions: [
        if (UniversalPlatform.isIOS) Permission.photos,
        if (UniversalPlatform.isAndroid) Permission.storage
      ],
    );
    if (permission != true) return;

    String localFilePath = "";
    if (item.isImage) {
      localFilePath = item.filePath;
    } else {
      final cachedPath =
          (await MultiImagePicker.cachedVideoPath(item.url)).toString();
      //multi_image_picker缓存缩略视频地址查询
      localFilePath = File(cachedPath).existsSync()
          ? cachedPath
          : (CosUploadFileIndexCache.cachePath(item.url) ?? item.filePath);
    }
    await saveImageToLocal(
        localFilePath: localFilePath, url: item.url, isImage: item.isImage);
  }
}
