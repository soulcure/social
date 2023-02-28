import 'dart:async';

import 'package:flutter/services.dart';

class IosScreenPlugin {
  static const MethodChannel channel = MethodChannel('com.nativeToFlutter');

  static Future stopGetData() async {
    /// 【APP】ios屏幕共享停止共享，停止后再开播灰屏
    unawaited(channel.invokeMethod("stopGetData"));
    return;
  }

  static Future startGetData() async {
    unawaited(channel.invokeMethod("startGetData"));
    return;
  }
}
