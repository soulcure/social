import 'dart:async';
import 'dart:io';

import 'package:fb_live_flutter/live/utils/config/steam_info_config.dart';
import 'package:fb_live_flutter/live/utils/func/check.dart';
import 'package:flutter/cupertino.dart';
import 'package:replay_kit_launcher/replay_kit_launcher.dart';
import 'package:zego_express_engine/zego_express_engine.dart';

import '../live_room_bloc.dart';
import 'live_mix.dart';

abstract class ScreenWithAbs {
  // 是否为主播
  @protected
  late bool isAnchor;

  /*
  * 是否屏幕共享进程中
  * */
  bool isScreenProcess = false;

  // 获取房间状态
  Future<int?> getRoomStatus();
}

mixin ScreenWith on ScreenWithAbs {
  AppLifecycleState? appState;

  int count = 0;

  Timer? timer;

  // 清除定时器
  void _cancelTimer() {
    timer?.cancel();
  }

  void _startTimer(LiveRoomBloc? liveBloc, LiveValueModel? liveValueModel) {
    // 创建定时器
    timer = Timer.periodic(const Duration(milliseconds: 600), (timer) {
      count = 0;
      handle(liveBloc, liveValueModel);
      _cancelTimer();
    });
  }

  /*
  * 检测是否开启了屏幕共享
  * */
  Future checkScreen(AppLifecycleState appLifecycleState,
      LiveRoomBloc? liveBloc, LiveValueModel? liveValueModel) async {
    if (!isAnchor) {
      return;
    }

    /// Android使用全局悬浮窗，离开app依然推流
    if (Platform.isAndroid) {
      return;
    }
    if (isTemporaryTapProcessing) {
      // 每被拦截一次就++
      count++;
      appState = appLifecycleState;
      _cancelTimer();
      _startTimer(liveBloc, liveValueModel);
      return;
    }
    _cancelTimer();
    isTemporaryTapProcessing = true;
    restoreTemporaryProcess(1000);
    if (!isAnchor || appState == appLifecycleState) {
      return;
    }
    appState = appLifecycleState;
    await handle(liveBloc, liveValueModel);
  }

  /*
  * 处理事件
  * */
  Future handle(LiveRoomBloc? liveBloc, LiveValueModel? liveValueModel) async {
    if (appState == AppLifecycleState.resumed) {
      if (!liveValueModel!.isScreenSharing && !isScreenProcess) {
        await ZegoExpressEngine.instance.enableCamera(true);
        await ZegoExpressEngine.instance.muteMicrophone(false);

        final roomStatus = await getRoomStatus();
        // 房间状态直播中
        if (roomStatus == 2) {
          /// 【2021 11.20】发送流附加消息来通知观众端，而不是重新推流
          await ZegoExpressEngine.instance.setStreamExtraInfo(
              sendSteamInfo(appIsResume: true, liveValueModel: liveValueModel));

          if (liveBloc?.showImageFilterBlocModel != null) {
            if (Platform.isAndroid && liveBloc != null ||
                !liveBloc!.showImageFilterBlocModel!.state) {
              liveBloc.showImageFilterBlocModel!.add(true);
            }
          }
        } else if (roomStatus == -1) {
          // todo 状态不满足预期，需要给出提示
        }
      }

      if (Platform.isIOS) {
        await Future.delayed(Duration.zero).then((value) {
          ReplayKitLauncher().isScrren();
        });
      }
    } else if (appState == AppLifecycleState.inactive) {
      if (!liveValueModel!.isScreenSharing) {
        /// 【2021 11.20】使用关闭摄像头和麦克风方式，而不是停止推流方式
        await ZegoExpressEngine.instance.enableCamera(false);
        await ZegoExpressEngine.instance.muteMicrophone(true);

        // 停止推流-让观众显示主播离开状态[2021 11.18]
        // 【new】格式化后流附加消息
        await ZegoExpressEngine.instance.setStreamExtraInfo(
            sendSteamInfo(appIsResume: false, liveValueModel: liveValueModel));
      }
    }
    if (isScreenProcess) {
      isScreenProcess = false;
    }
  }
}
