import 'dart:io';

import 'package:fb_live_flutter/live/bloc/with/live_mix.dart';
import 'package:fb_live_flutter/live/event_bus_model/live/ios_screen_direction_model.dart';
import 'package:fb_live_flutter/live/utils/config/steam_info_config.dart';
import 'package:fb_live_flutter/live/utils/func/router.dart';
import 'package:fb_live_flutter/live/utils/other/float/float_mode.dart';
import 'package:fb_live_flutter/live/utils/other/ios_screen_plugin.dart';
import 'package:flutter/services.dart';
import 'package:zego_express_engine/zego_express_engine.dart';

class IosScreenUtil {
  static String statusType = "V";

  /// 是否发送流附加消息
  static bool isSendStreamInfo(LiveValueModel? liveValueModel) {
    final bool isHasLive = RouteUtil.routeHasLive || floatWindow.isHaveFloat;
    return isHasLive &&
        liveValueModel!.isAnchor &&
        liveValueModel.isScreenSharing &&
        Platform.isIOS;
  }

  /*
  * 直播注册时调用【仅普通直播】
  *
  * 1。live_room_bloc :: init;
  * 1。小窗 :: initState;
  * */
  static void init() {
    /// 只开放给iOS使用
    if (!Platform.isIOS) {
      return;
    }
    IosScreenPlugin.channel.setMethodCallHandler(callHandle);
  }

  static Future<void> callHandle(MethodCall call) async {
    if (call.method == 'GroupDataFlutter') {
      // 1:竖屏[V]   6：右横屏[RH]    8：左横屏[LH]
      String statusTypeOld;
      if (call.arguments == "1") {
        statusTypeOld = "V";
      } else if (call.arguments == "6") {
        statusTypeOld = "RH";
      } else {
        statusTypeOld = "LH";
      }

      if (statusType == statusTypeOld) {
        return;
      }

      statusType = statusTypeOld;

      // 发送给【直播间/小窗】进行处理，因为此处没有[liveValueModel]
      iosScreenDirectionBus.fire(IosScreenDirectionModel(statusType));
    }
  }

  /*
  * 直播的eventBus监听到改变后会调用此方法且传
  * */
  static Future changeHandle(
      IosScreenDirectionModel event, LiveValueModel? liveValueModel) async {
    /// 只开放给iOS使用
    if (!Platform.isIOS) {
      return;
    }

    if (isSendStreamInfo(liveValueModel)) {
      await ZegoExpressEngine.instance.setStreamExtraInfo(sendSteamInfo(
          screenShare: true,
          mirror: false,
          screenDirection: statusType,
          liveValueModel: liveValueModel));
    }
  }
}
