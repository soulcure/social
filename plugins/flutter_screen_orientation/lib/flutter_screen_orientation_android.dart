import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_screen_orientation/flutter_screen_orientation_interface.dart';

class FlutterScreenOrientationAndroidService
    extends FlutterScreenOrientationService {
  MethodChannel _channel = const MethodChannel('flutter_screen_orientation');
  int lastOrientation = -1;

  @override
  Future<void> init() async {
    _channel.setMethodCallHandler((MethodCall call) async {
      if (call.method == "orientationCallback" && orientationCallback != null) {
        int orientation = int.parse(call.arguments);
        if (lastOrientation == orientation) {
          return;
        }
        lastOrientation = orientation;
        orientationCallback(orientation);
      }
    });
    _channel.invokeMethod("init");
  }

  @override
  void setOrientationCallback(Function orientationCallback) {
    this.lastOrientation = -1;
    super.setOrientationCallback(orientationCallback);
  }
}
