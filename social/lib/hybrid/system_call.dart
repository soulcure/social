import 'package:flutter/services.dart';

class SystemCall {
  static const platform = MethodChannel('buff.com/social');

  static Future<void> acquireWakeLock() async {
    await platform.invokeMethod("acquireWakeLock");
  }

  static Future<void> releaseWakeLock() async {
    await platform.invokeMethod("releaseWakeLock");
  }
}
