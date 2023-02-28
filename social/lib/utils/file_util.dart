import 'dart:io';

import 'package:fb_utils/fb_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:im/app/modules/file/file_manager/file_manager.dart';
import 'package:im/svg_icons.dart';
import 'package:im/utils/universal_platform.dart';
import 'package:im/ws/ws.dart';

import 'cos_file_upload.dart';

/// - 描述：文件工具类
///
/// - author: seven
/// - data: 2021/10/19 4:57 下午

/// - 文件类型，
/// - 1：图片，2：视频，3：音频，4：普通文档（txt、word 、exel、ppt、pdf）5：压缩文档  6:未知类型
enum FileType {
  picture,
  video,
  audio,
  document,
  zip,
  unknown,
}

class FileUtil {
  /// - 根据index获取FileType
  static FileType getFileTypeByIndex(int index) {
    switch (index) {
      case 0:
        return FileType.picture;
      case 1:
        return FileType.video;
      case 2:
        return FileType.audio;
      case 3:
        return FileType.document;
      case 4:
        return FileType.zip;
      case 5:
        return FileType.unknown;
      default:
        return FileType.unknown;
    }
  }

  /// - 获取文件名称
  static String getFileName(String filePath) {
    if (filePath == null || filePath.isEmpty || filePath.length == 1) {
      return "";
    }
    return filePath.contains("/")
        ? filePath.substring(filePath.lastIndexOf("/") + 1, filePath.length)
        : filePath;
  }

  /// - 获取文件是否存在
  static bool isFileExists(String filePath) {
    if (filePath == null || filePath.trim().isEmpty) return false;
    return File(filePath).existsSync();
  }

  /// - 获取文件后缀,不包含 "."
  static String getFileExt(String fileName) {
    if (fileName == null || fileName.isEmpty || fileName.length == 1) {
      return '';
    }
    return fileName.substring(fileName.lastIndexOf(".") + 1, fileName.length);
  }

  /// - 获取文件类型
  static FileType getFileType(String fileName) {
    if (fileName == null || fileName.isEmpty) {
      return FileType.unknown;
    }
    final fileNameTrim = fileName.trim().toLowerCase();
    if (fileNameTrim.endsWith('.jpg') ||
        fileNameTrim.endsWith('.png') ||
        fileNameTrim.endsWith('.bmp') ||
        fileNameTrim.endsWith('.gif') ||
        fileNameTrim.endsWith('.webp') ||
        fileNameTrim.endsWith('.jpeg')) {
      return FileType.picture;
    } else if (fileNameTrim.endsWith('.flv') ||
        fileNameTrim.endsWith('.mkv') ||
        fileNameTrim.endsWith('.mp4') ||
        fileNameTrim.endsWith('.rmvb') ||
        fileNameTrim.endsWith('.avi') ||
        fileNameTrim.endsWith('.wmv') ||
        fileNameTrim.endsWith('.3gp') ||
        fileNameTrim.endsWith('.m3u8') ||
        fileNameTrim.endsWith('.m4v') ||
        fileNameTrim.endsWith('.rm') ||
        fileNameTrim.endsWith('.mov')) {
      return FileType.video;
    } else if (fileNameTrim.endsWith('.mp3') ||
        fileNameTrim.endsWith('.wav') ||
        fileNameTrim.endsWith('.aac') ||
        fileNameTrim.endsWith('.flac') ||
        fileNameTrim.endsWith('.amr') ||
        fileNameTrim.endsWith('.m4a') ||
        fileNameTrim.endsWith('.wma') ||
        fileNameTrim.endsWith('.ogg') ||
        fileNameTrim.endsWith('.ape')) {
      return FileType.audio;
    } else if (fileNameTrim.endsWith('.txt')) {
      return FileType.document;
    } else if (fileNameTrim.endsWith('.doc') ||
        fileNameTrim.endsWith('.dot') ||
        fileNameTrim.endsWith('.wps') ||
        fileNameTrim.endsWith('.wpt') ||
        fileNameTrim.endsWith('.docx') ||
        fileNameTrim.endsWith('.dotx') ||
        fileNameTrim.endsWith('.docm') ||
        fileNameTrim.endsWith('.dotm')) {
      return FileType.document;
    } else if (fileNameTrim.endsWith('.xls') ||
        fileNameTrim.endsWith('.xlt') ||
        fileNameTrim.endsWith('.et') ||
        fileNameTrim.endsWith('.ett') ||
        fileNameTrim.endsWith('.xlsx') ||
        fileNameTrim.endsWith('.xltx') ||
        fileNameTrim.endsWith('.xlsb') ||
        fileNameTrim.endsWith('.xlsm') ||
        fileNameTrim.endsWith('.xltm') ||
        fileNameTrim.endsWith('.ets') ||
        fileNameTrim.endsWith('.exc')) {
      return FileType.document;
    } else if (fileNameTrim.endsWith('.pptx') ||
        fileNameTrim.endsWith('.ppt') ||
        fileNameTrim.endsWith('.pot') ||
        fileNameTrim.endsWith('.potx') ||
        fileNameTrim.endsWith('.pps') ||
        fileNameTrim.endsWith('.ppsx') ||
        fileNameTrim.endsWith('.dps') ||
        fileNameTrim.endsWith('.dpt') ||
        fileNameTrim.endsWith('.pptm') ||
        fileNameTrim.endsWith('.potm') ||
        fileNameTrim.endsWith('.ppsm')) {
      return FileType.document;
    } else if (fileNameTrim.endsWith('.pdf')) {
      return FileType.document;
    } else if (fileNameTrim.endsWith('.jar') ||
        fileNameTrim.endsWith('.rar') ||
        fileNameTrim.endsWith('.zip')) {
      return FileType.zip;
    } else {
      return FileType.unknown;
    }
  }

  /// - 更具文件类型返回不同的iconFont
  /// - fileExt：文件后缀
  /// - isCircle：是否是圆形  false:是方形
  static String getFileSvgIcons(FileType fileType, String fileExt,
      {bool isCircle = false}) {
    switch (fileType) {
      case FileType.picture:
        return isCircle ? SvgIcons.filePicCircle : SvgIcons.filePic;
      case FileType.video:
        return isCircle ? SvgIcons.fileAviCircle : SvgIcons.fileAvi;
      case FileType.audio:
        return isCircle ? SvgIcons.fileAacCircle : SvgIcons.fileAac;
      case FileType.zip:
        return isCircle ? SvgIcons.fileRarCircle : SvgIcons.fileRar;
      case FileType.unknown:
        return isCircle ? SvgIcons.fileUnknownCircle : SvgIcons.fileUnknown;
      case FileType.document:
        return _getFileSvgIcons(fileExt, isCircle: isCircle);
      default:
        return isCircle ? SvgIcons.fileUnknownCircle : SvgIcons.fileUnknown;
    }
  }

  /// - 具体文档类型根据后缀来区分
  static String _getFileSvgIcons(String fileExt, {bool isCircle = false}) {
    if (fileExt == null || fileExt.isEmpty) {
      return isCircle ? SvgIcons.fileUnknownCircle : SvgIcons.fileUnknown;
    }

    if (fileExt == 'doc' ||
        fileExt == 'dot' ||
        fileExt == 'wps' ||
        fileExt == 'wpt' ||
        fileExt == 'docx' ||
        fileExt == 'dotx' ||
        fileExt == 'docm' ||
        fileExt == 'dotm') {
      return isCircle ? SvgIcons.fileDocCircle : SvgIcons.fileDoc;
    } else if (fileExt == 'xls' ||
        fileExt == 'xlt' ||
        fileExt == 'et' ||
        fileExt == 'ett' ||
        fileExt == 'xlsx' ||
        fileExt == 'xltx' ||
        fileExt == 'xlsb' ||
        fileExt == 'xlsm' ||
        fileExt == 'xltm' ||
        fileExt == 'ets' ||
        fileExt == 'exc') {
      return isCircle ? SvgIcons.fileExcCircle : SvgIcons.fileExc;
    } else if (fileExt == 'pptx' ||
        fileExt == 'ppt' ||
        fileExt == 'pot' ||
        fileExt == 'potx' ||
        fileExt == 'pps' ||
        fileExt == 'ppsx' ||
        fileExt == 'dps' ||
        fileExt == 'dpt' ||
        fileExt == 'pptm' ||
        fileExt == 'potm' ||
        fileExt == 'ppsm') {
      return isCircle ? SvgIcons.filePptCircle : SvgIcons.filePpt;
    } else if (fileExt == 'pdf') {
      return isCircle ? SvgIcons.filePdfCircle : SvgIcons.filePdf;
    } else if (fileExt == 'txt') {
      return isCircle ? SvgIcons.fileTxtCircle : SvgIcons.fileTxt;
    } else {
      return isCircle ? SvgIcons.fileUnknownCircle : SvgIcons.fileUnknown;
    }
  }

  /// - 根据大小计算文件的带单位大小
  /// - size.substring(0,size.indexOf(".")+3) 小数点位数
  static String getFileSize(int limit) {
    String size = "";
    if (limit < 0.1 * 1024) {
      //小于0.1KB，则转化成B
      size = limit.toString();
      size = "${size}B";
    } else if (limit < 0.1 * 1024 * 1024) {
      //小于0.1MB，则转化成KB
      size = (limit / 1024).toStringAsFixed(2);
      size = "${size}KB";
    } else if (limit < 0.1 * 1024 * 1024 * 1024) {
      //小于0.1GB，则转化成MB
      size = (limit / (1024 * 1024)).toStringAsFixed(2);
      size = "${size}MB";
    } else {
      //其他转化成GB
      size = (limit / (1024 * 1024 * 1024)).toStringAsFixed(2);
      size = "${size}GB";
    }
    return size;
  }

  /// - 计算文件的Md5
  static Future<String> getFileMd5(String filePath) async {
    if (filePath == null || filePath.isEmpty) return null;

    if (UniversalPlatform.isIOS || UniversalPlatform.isAndroid) {
      return FbUtils.getMD5WithPath(filePath);
    } else if (UniversalPlatform.isWeb) {
      return compute(getWebFileHash, filePath);
    } else {
      return compute(getFileHash, filePath);
    }
  }

  /// - 是否过期，默认30天
  static bool isOverDay(int time) {
    final long = FileManager().fileUploadSetting?.downloadLastDay ?? 30;

    final nowTime = Ws.serverTime != -1
        ? DateTime.fromMillisecondsSinceEpoch(Ws.serverTime * 1000)
        : DateTime.now();
    final timeDate = DateTime.fromMillisecondsSinceEpoch(time);
    final difference = nowTime.difference(timeDate);
    final day = difference.inDays;
    return day >= long;
  }
}
