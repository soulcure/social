import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';

// Flutter 旋转
class FlutterRotate {
  static const MethodChannel _channel = MethodChannel('flutter_rotate');

  // 切换竖屏
  static Future<void> changeVertical() async {
    if (!Platform.isIOS) {
      return;
    }
    await _channel.invokeMethod('changeVertical');
  }

  // 切换横屏
  static Future<void> changeHorizontal() async {
    if (!Platform.isIOS) {
      return;
    }
    await _channel.invokeMethod('changeHorizontal');
  }

  // 注册监听
  static Future<void> reg() async {
    if (!Platform.isIOS) {
      return;
    }
    await _channel.invokeMethod('reg');
  }

  // 注销监听
  static Future<void> unreg() async {
    if (!Platform.isIOS) {
      return;
    }
    await _channel.invokeMethod('unreg');
  }
}
