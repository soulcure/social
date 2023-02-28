import 'dart:io';

import 'package:fb_live_flutter/live/api/fblive_provider.dart';
import 'package:fb_live_flutter/live/bloc/with/live_mix.dart';
import 'package:flutter/foundation.dart';

export 'package:fb_live_flutter/live/model/live/steam_info_model.dart';

/// 流附加消息：
/// app=[pause, resume]&mirror=[positive, negative]&platform=[android,ios,web]&screenShare=[open,close]
///
/// 例子:
/// "mirror=positive&platform=android&screenShare=open&iosRotationType=6"
class LiveParamKey {
  static const screenShare = "screenShare";
  static const platform = "platform";
  static const mirror = "mirror";
  static const app = "app";
  static const screenDirection = "screenDirection";
}

class SteamInfoStore {
  bool screenShare = false;
  bool mirror = false;
  bool appIsResume = true;
  String screenDirection = "V";
}

/*
* 发送流附加消息
* */
String sendSteamInfo({
  bool? screenShare,
  bool? mirror,
  bool? appIsResume,
  String? screenDirection,

  /// 后期准备只接受一个[steamInfoStore]
  required LiveValueModel? liveValueModel,
}) {
  screenShare ??= liveValueModel!.steamInfoStore.screenShare;
  mirror ??= liveValueModel!.steamInfoStore.mirror;
  appIsResume ??= liveValueModel!.steamInfoStore.appIsResume;
  screenDirection ??= liveValueModel!.steamInfoStore.screenDirection;

  liveValueModel!.steamInfoStore.screenShare = screenShare;
  liveValueModel.steamInfoStore.mirror = mirror;
  liveValueModel.steamInfoStore.appIsResume = appIsResume;
  liveValueModel.steamInfoStore.screenDirection = screenDirection;

  /// 平台处理
  String platformStr;
  if (kIsWeb) {
    platformStr = 'web';
  } else if (Platform.isIOS) {
    platformStr = 'ios';
  } else if (Platform.isAndroid) {
    platformStr = 'android';
  } else {
    platformStr = "other";
  }

  /// 镜像处理
  final String mirrorStr = mirror ? "positive" : "negative";

  /// 屏幕共享处理
  final String screenShareStr = screenShare ? "open" : "close";

  /// app状态处理
  final String appStr = appIsResume ? "resume" : "pause";

  final String result =
      "${LiveParamKey.mirror}=$mirrorStr&${LiveParamKey.platform}"
      "=$platformStr&${LiveParamKey.screenShare}=$screenShareStr&${LiveParamKey.app}"
      "=$appStr&${LiveParamKey.screenDirection}=$screenDirection";
  fbApi.fbLogger.info('send stream info: $result');
  return result;
}
