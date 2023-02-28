import 'package:flutter/rendering.dart';

class AsyDevLog {
  //调试log的开关
  static bool isNeedLog = false;

  static void asyPrint(String str) {
    if (AsyDevLog.isNeedLog) {
      // logger.info(str);
      debugPrint("$str--- yzh===${DateTime.now()}");
    }
  }
}
