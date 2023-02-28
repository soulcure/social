import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class WindowUtil {
  /*
  * 状态栏字体颜色设置为黑色
  *
  * 场景：回放页面退出、直播页面退出，设置房间列表页面
  * */
  static void setStatusTextColorBlack() {
    const SystemUiOverlayStyle systemUiOverlayStyle = SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light);
    SystemChrome.setSystemUIOverlayStyle(systemUiOverlayStyle);
  }
}
