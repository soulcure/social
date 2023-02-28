import 'dart:async';

import 'package:flutter/services.dart';

export 'src/zego_engine_manager.dart';
export 'src/interface/zego_ww_engine.dart';
export 'src/zego_ww_defines.dart';
export 'src/interface/zego_ww_video_view.dart';
export 'src/interface/zego_ww_media_model.dart';
export 'src/zego_ww_defines.dart';
export 'src/zego_ww_web_defines.dart';

class ZegoWw {
  static const MethodChannel _channel = const MethodChannel('zego_ww');

  static Future<String?> get platformVersion async {
    final String? version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }
}
