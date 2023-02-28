import 'dart:io';

import 'package:fb_live_flutter/live/api/fblive_provider.dart';
import 'package:flutter/services.dart';

class MediaPlugin {
  static String channelName = "media_projection_plugin";
  static MethodChannel methodChannel = MethodChannel(channelName);

  /*
  * 是否可以使用本插件的方法
  *
  * 只有Android系统可以使用
  * */
  static bool get isCanUse {
    return Platform.isAndroid;
  }

  static void setToken() {
    if (!isCanUse) {
      return;
    }
    methodChannel.invokeMethod("setToken", {"token": fbApi.getToken()});
  }

  static void setRoomId(String? roomId) {
    if (!isCanUse) {
      return;
    }
    methodChannel.invokeMethod("setRoomId", {"roomId": roomId});
  }

  static void setLiveHost(String liveHost) {
    if (!isCanUse) {
      return;
    }
    methodChannel.invokeMethod("setLiveHost", {"liveHost": liveHost});
  }

  static void setPullModeStr(String? pullModeStr) {
    if (!isCanUse) {
      return;
    }
    methodChannel.invokeMethod("setPullModeStr", {"pullModeStr": pullModeStr});
  }
}
