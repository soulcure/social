


import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:im/web/utils/image_picker/image_picker.dart';
import 'package:multi_image_picker/multi_image_picker.dart';
import 'send_image_dialog_for_web.dart' if (dart.library.io) 'send_image_dialog_for_window.dart';

Map<String, Uint8List> webSendImageCache = {};
Map<String, Uint8List> checkImageCache = {};
Set<String> pickFileCache = {};

Future<Asset> showImageDialog(BuildContext context, FileInfo fileInfo) async {
  return showSendImageDialog(context, fileInfo);
}