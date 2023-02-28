import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class ScanQrCodeArgs {
  bool autoProcess;

  ScanQrCodeArgs({this.autoProcess = true});
}

class ScanQrCodeController extends GetxController {
  ScanQrCodeArgs _args;

  /// 生成二维码组件
  static Widget genQRCode({
    @required String data,
    double size = 100,
    ImageProvider embeddedImg,
    double embeddedImageSize,
    QrErrorBuilder errorStateBuilder,
    EdgeInsets padding = const EdgeInsets.all(10),
    bool embeddedImageEmitsError = false,
  }) {
    Size embeddedSize;
    if (embeddedImageSize != null) {
      embeddedSize = Size(embeddedImageSize, embeddedImageSize);
    }

    return QrImage(
      data: data,
      size: size,
      embeddedImage: embeddedImg,
      embeddedImageStyle: QrEmbeddedImageStyle(size: embeddedSize),
      errorStateBuilder: errorStateBuilder,
      padding: padding,
      embeddedImageEmitsError: embeddedImageEmitsError,
    );
  }

  @override
  void onInit() {
    _args = Get.arguments as ScanQrCodeArgs ?? ScanQrCodeArgs();
    super.onInit();
  }

  bool get autoProcess => _args.autoProcess;
}
