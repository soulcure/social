import 'package:flutter/cupertino.dart';

abstract class FlutterScreenOrientationService {
  //方向回调
  Function orientationCallback;

  void setOrientationCallback(Function orientationCallback) {
    this.orientationCallback = orientationCallback;
  }

  //初始化
  @protected
  Future<void> init();
}
