import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:im/web/utils/web_util/web_util.dart';
import 'package:im/ws/text_convert_js_io.dart'
    if (dart.library.html) 'package:im/ws/text_convert_js.dart';

final gzipDecoder = GZipDecoder();
const utf8Decoder = Utf8Decoder();

// ignore: avoid_annotating_with_dynamic
String decodeWsData(dynamic origin) {
  //ws数据 首先判断是否string
  if (origin is String) {
    return origin;
  }

  if (kIsWeb) {
    try {
      return webUtil.gzip(origin);
    } catch (e) {
      return TextDecoder().decode(Uint8List.fromList(origin));
    }
  }

  //不是string, 再用Gzip解析
  try {
    final decodedBytes = gzipDecoder.decodeBytes(origin);
    return utf8Decoder.convert(decodedBytes);
  } catch (e) {
    //有异常，则改用二进制解析
    return utf8Decoder.convert(origin);
  }
}
