import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' as get_x;
import 'package:im/utils/custom_cache_manager.dart';
import 'package:image/image.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:image_save/image_save.dart';
import 'package:oktoast/oktoast.dart';

final Map<String, Completer<bool>> _futures = {};

/// 保存图片或视频 android/ios
Future saveImageToLocal({
  String localFilePath,
  @required String url,
  bool isImage = true,
  bool isShowToast = true,
}) async {
  if (url == null) return;

  if (_futures.containsKey(url)) {
    return _futures[url]
        .future
        .timeout(const Duration(seconds: 15))
        .catchError((e) => null);
  }

  final c = _futures[url] = Completer<bool>();

  File file =
      (localFilePath?.isNotEmpty ?? false) ? File(localFilePath ?? '') : null;

  if (!(file?.existsSync() ?? false)) {
    file = await CustomCacheManager.instance.getSingleFile(url);
    if (file != null && file.path.contains('.file')) {
      // 文件保存错误类型，会导致视频图片无法保存到本地
      await CustomCacheManager.instance.removeFile(url);
    }
  }

  Uint8List data;
  if (file == null || !file.existsSync()) {
    //本地不存在，则下载
    final response = await Dio()
        .get(url, options: Options(responseType: ResponseType.bytes));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      if (isShowToast) showToast('保存失败'.tr);
      return;
    }
    data = response.data;
    try {
      file = await CustomCacheManager.instance.putFile(url, response.data,
          fileExtension: url.substring(url.lastIndexOf('.') + 1));
    } catch (e, s) {
      print(s);
    }
  }

  // 开始保存
  bool result;
  if (isImage) {
    final bytes = data ?? file.readAsBytesSync();
    final fileName =
        appendFileType(url.substring(url.lastIndexOf('/') + 1), bytes);
    result = await ImageSave.saveImage(bytes, fileName);
  } else {
    final res = await ImageGallerySaver.saveFile(file.path);
    result = res.runtimeType != bool ? res != null : res;
  }
  if (isShowToast) showToast(result ? '已保存到相册'.tr : '保存失败'.tr);
  if (_futures.containsKey(url)) {
    c.complete(Future.value(result));
    _futures.remove(url);
  }
  return c.future.timeout(const Duration(seconds: 15)).catchError((e) => null);
}

String appendFileType(String fileName, List<int> data) {
  if (fileName.indexOf('.') > 0) {
    return fileName;
  }
  final Decoder res = findDecoderForData(data);
  switch (res.runtimeType) {
    case JpegDecoder:
      return '$fileName.jpg';
    case PngDecoder:
      return '$fileName.png';
    case GifDecoder:
      return '$fileName.gif';
    case WebPDecoder:
      return '$fileName.webp';
    case TiffDecoder:
      return '$fileName.tiff';
    case PsdDecoder:
      return '$fileName.psd';
    case ExrDecoder:
      return '$fileName.exr';
    case BmpDecoder:
      return '$fileName.bmp';
    case TgaDecoder:
      return '$fileName.tga';
    default:
      return fileName;
  }
}
