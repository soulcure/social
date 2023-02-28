import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:im/core/http_middleware/http.dart';

import '../upload.dart';

class ImageUtil {
  final List<String> _errorUrlList = [];

  static final ImageUtil _singleton = ImageUtil._internal();

  factory ImageUtil() {
    return _singleton;
  }

  ImageUtil._internal();

  ///图片内存控制
  ImageProvider buildResizeProvider(
      BuildContext context, ImageProvider provider,
      {int imageWidth, int imageHeight}) {
    if (kIsWeb) return provider;
    final size = MediaQuery.of(context).size;
    final devicePixel = MediaQuery.of(context).devicePixelRatio;
    int height = size.height.toInt();
    int width = size.width.toInt();
    if (imageWidth != null || imageHeight != null) {
      int h = imageHeight ?? height;
      int w = imageWidth ?? width;
      if (h == 0) h = height;
      if (w == 0) w = width;
      height = h;
      width = w;
    }
    final isHeightBigger = height > width;

    final result = isHeightBigger
        ? ResizeImage(provider,
            width: (size.width * devicePixel).toInt(), allowUpscaling: true)
        : ResizeImage(provider,
            height: (size.height * devicePixel).toInt(), allowUpscaling: true);
    return result;
  }

  @Deprecated('等待完善中...')
  Future uploadImage(
    List<Uint8List> bytesList, {
    VoidCallback onSuccess,
    ProgressCallback onSendProgress,
  }) async {
    final cosAuth = await getCosAuth();
    return Http.dio.post(cosAuth.host);
  }

  void addErrorUrl(String url) {
    _errorUrlList.add(url);
  }

  bool hasError(String url) {
    return _errorUrlList.contains(url);
  }
}
