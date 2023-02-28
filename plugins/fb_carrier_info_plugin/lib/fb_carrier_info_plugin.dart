import 'dart:async';

import 'package:flutter/services.dart';

class FbCarrierInfoPlugin {
  static const MethodChannel _channel =
  const MethodChannel('fb_carrier_info_plugin');

  /// 获取网络类型,用数字代表,具体含义需要查看插件源码(比如: 4G)
  static Future<String?> get netWorkType async {
    final String? type = await _channel.invokeMethod('getNetWorkType');
    return type;
  }

  /// 获取运营商类型,用数字代表,具体含义需要查看插件源码(比如: 中国移动)
  static Future<String?> get operatorType async {
    final String? type = await _channel.invokeMethod('getOperatorType');
    return type;
  }
}
