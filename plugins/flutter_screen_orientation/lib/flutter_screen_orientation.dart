import 'dart:async';
import 'dart:io';

import 'package:flutter_screen_orientation/flutter_screen_orientation_android.dart';
import 'package:flutter_screen_orientation/flutter_screen_orientation_interface.dart';
import 'package:flutter_screen_orientation/flutter_screen_orientation_ios.dart';

class FlutterScreenOrientation {
  FlutterScreenOrientationService screenOrientationService;
  static FlutterScreenOrientation self;
  static int portraitUp = 1;
  static int portraitDown = 2;
  static int landscapeLeft = 3;
  static int landscapeRight = 4;

  static FlutterScreenOrientation instance() {
    if (self == null) {
      self = FlutterScreenOrientation();
    }
    return self;
  }

  //初始化
  Future<void> init() async {
    if (Platform.isIOS) {
      self.screenOrientationService = FlutterScreenOrientationIosService();
    } else if (Platform.isAndroid) {
      self.screenOrientationService = FlutterScreenOrientationAndroidService();
    }
    await self.screenOrientationService.init();
  }

  //方向监听
  void listenerOrientation(Function orientationCallback) async {
    self.screenOrientationService.setOrientationCallback(orientationCallback);
  }
}
