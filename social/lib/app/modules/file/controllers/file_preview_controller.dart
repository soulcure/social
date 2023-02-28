import 'dart:io';

import 'package:fast_gbk/fast_gbk.dart';
import 'package:get/get.dart';
import 'package:get/get_state_manager/src/simple/get_controllers.dart';
import 'package:im/pages/home/json/file_entity.dart';
import 'package:im/utils/file_util.dart';
import 'package:im/utils/universal_platform.dart';

/// - 描述：
///
/// - author: seven
/// - data: 2021/11/15 10:46 上午
class FilePreviewController extends GetxController {
  FileEntity fileEntity;

  /// 文件路径
  String get filePath => fileEntity?.filePath ?? '';

  /// 视频网络路径
  String get fileUrl => fileEntity?.fileUrl ?? '';

  /// 是否是图片类型
  bool get fileIsImage => fileEntity?.fileType == FileType.picture.index + 1;

  /// 是否是视频类型
  bool get fileIsVideo => fileEntity?.fileType == FileType.video.index + 1;

  /// 是否是文档类型
  bool get fileIsDocument =>
      fileEntity?.fileType == FileType.document.index + 1 &&
      fileEntity?.fileExt != 'txt';

  /// 是否是txt类型
  bool get fileIsTxt =>
      fileEntity?.fileType == FileType.document.index + 1 &&
      fileEntity?.fileExt == 'txt';

  /// 是否是文件类型 目前是true，后续可以扩展
  bool get fileIsFile => true;

  /// 文件名称
  String get fileName => fileEntity?.fileName ?? '文件'.tr;

  /// ios版本txt是否转码成功
  bool _isTxtToGbk = false;

  /// ios版本txt是否转码成功,大于20m不能预览
  bool get iosTxtToGbkSuccess =>
      _isTxtToGbk &&
      UniversalPlatform.isIOS &&
      fileEntity.fileSize <= 20 * 1024 * 1024;

  FilePreviewController(this.fileEntity);

  @override
  void onInit() {
    super.onInit();

    _iosTxtFile();
  }

  /// - ios
  void _iosTxtFile() {
    if (!UniversalPlatform.isIOS) return;
    // '_temp.txt'的文件是转码过的文件，就不用再转码了
    if (fileEntity.fileExt.toLowerCase() == 'txt' &&
        !fileEntity.filePath.endsWith('_temp.txt') &&
        fileEntity.fileSize <= 20 * 1024 * 1024) {
      try {
        // txt文件在ios上显示乱码
        final contents = File(fileEntity.filePath).readAsStringSync();
        fileEntity.filePath =
            fileEntity.filePath.replaceAll('.txt', '_temp.txt');
        File(fileEntity.filePath)
            .writeAsStringSync(contents.trim(), encoding: gbk, flush: true);
        _isTxtToGbk = true;
      } catch (e) {
        // 转码失败后，恢复旧的文件
        fileEntity.filePath =
            fileEntity.filePath.replaceAll('_temp.txt', '.txt');
        _isTxtToGbk = false;
      }
    } else if (fileEntity.filePath.endsWith('_temp.txt')) {
      _isTxtToGbk = true;
    } else if (File(fileEntity.filePath.replaceAll('.txt', '_temp.txt'))
        .existsSync()) {
      // 如果本地转码文件已经有了，更改路径为转码后的文件
      fileEntity.filePath = fileEntity.filePath.replaceAll('.txt', '_temp.txt');
      _isTxtToGbk = true;
    }
  }

  /// - 支持预览的文件
  /// - 图片不超过50mb，
  /// - 视频android都可以，苹果不支持rm、rmvb等
  bool isSupportPreview() {
    return fileIsImage && fileEntity.fileSize <= 50 * 1024 * 1024 ||
        fileIsVideo && _supportVideo() ||
        fileIsDocument ||
        fileIsTxt;
  }

  /// - 视频支持格式
  /// - 视频android都可以，苹果不支持rm、rmvb等
  bool _supportVideo() {
    return UniversalPlatform.isAndroid || _iosSupportVideo();
  }

  /// - 目前ios支持的格式
  bool _iosSupportVideo() =>
      UniversalPlatform.isIOS &&
      (fileEntity.fileExt.toLowerCase().contains('mp4') ||
          fileEntity.fileExt.toLowerCase().contains('mov') ||
          fileEntity.fileExt.toLowerCase().contains('3gp') ||
          fileEntity.fileExt.toLowerCase().contains('m4v'));

  /// - txt文件在ios上不能超过20m
  bool iosNotSupportTxt() =>
      UniversalPlatform.isIOS && fileEntity.fileSize > 20 * 1024 * 1024;
}
