import 'dart:io';

import 'package:flutter_image_compress/flutter_image_compress.dart';

class FileUtil {
  static Future<List<int>?> compressFile(File file) async {
    if (Platform.isIOS) {
      return file.readAsBytesSync();
    }
    try {
      final result = await FlutterImageCompress.compressWithFile(
        file.absolute.path,
        minWidth: 800,
        quality: 88,
      );
      return result;
    } catch (e) {
      return null;
    }
  }
}
