import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/app/modules/scan_qr_code/views/scan_qr_code_view.dart';
import 'package:im/app/routes/app_pages.dart';

class ScannerNavigatorObserver extends NavigatorObserver {
  @override
  void didPop(Route route, Route previousRoute) {
    super.didPop(route, previousRoute);
    //监听扫描二维码界面的跳转情况
    if (Get.currentRoute == Routes.SCAN_QR_CODE) {
      ScanQrCodeView.scannerPopEvenBus?.fire("");
    }
  }
}
