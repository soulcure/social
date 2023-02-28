import 'dart:async';
import 'dart:io';

import 'package:fb_live_flutter/live/bloc/with/live_mix.dart';
import 'package:fb_live_flutter/live/event_bus_model/live_status_model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:zego_express_engine/zego_express_engine.dart';

import '../func/check.dart';
import 'float_util.dart';

class FloatPlugin {
  static String channelName = "float_plugin";
  static final MethodChannel _channel = MethodChannel(channelName);

  static Future<void> requestPermission() async {
    if (Platform.isIOS) {
      return;
    }

    return _channel.invokeMethod('requestPermission');
  }

  static void initiativeCloseLive() {
    if (Platform.isIOS) return;
    _channel.invokeMethod('initiativeCloseLive');
  }

  /*
  * 【Android】初始化悬浮窗流事件监听
  * */
  static void initStreamOnAndroid() {
    // android悬浮窗
    if (!kIsWeb && Platform.isAndroid) {
      FloatPlugin.clickStream
          .receiveBroadcastStream()
          .listen(FloatUtil.clickFloat);

      /// 需要把直播间消息传给Android原生
      eventBus.on<LiveStatusEvent>().listen((event) {
        FloatPlugin.liveStatusChange(event.status.index);
      });
    }
  }

  static Future<void> open(
    String? roomId,
    final bool isScreenSharing,
    final bool isObs,
    final bool? isShowClose,
    final ZegoViewMode zegoViewMode,
    LiveValueModel liveValueModel,
  ) async {
    if (Platform.isIOS) {
      return;
    }

    /// 如果是主播的话roomId要为null，否则小窗口的内容会为本地预览画面
    return _channel.invokeMethod('open', {
      "roomId": roomId,
      "isObs": isObs,
      "isScreenSharing": isScreenSharing,
      "viewMode": zegoViewMode == ZegoViewMode.AspectFit ? 0 : 1,
      "isShowClose": isShowClose ?? true,
      "screenDirection": liveValueModel.screenDirection,
    });
  }

  static Future<void> changeViewMode(
    final double playerVideoWidth,
    final double playerVideoHeight,
    final ZegoViewMode zegoViewMode,
  ) async {
    if (Platform.isIOS) {
      return;
    }

    /// 防多次触发
    if (isTemporaryTapProcessing) {
      return;
    }
    isTemporaryTapProcessing = true;
    restoreTemporaryProcess();

    await Future.delayed(const Duration(milliseconds: 500));

    /// 如果是主播的话roomId要为null，否则小窗口的内容会为本地预览画面
    unawaited(_channel.invokeMethod('changeViewMode', {
      "viewMode": zegoViewMode == ZegoViewMode.AspectFit ? 0 : 1,
      "playerVideoWidth": playerVideoWidth,
      "playerVideoHeight": playerVideoHeight,
    }));
    return;
  }

  static Future<void> screenDirectionChange(String screenDirection) async {
    if (Platform.isIOS) {
      return;
    }

    /// 如果是主播的话roomId要为null，否则小窗口的内容会为本地预览画面
    unawaited(_channel.invokeMethod('screenDirectionChange', {
      "screenDirection": screenDirection,
    }));
    return;
  }

  /// 预览悬浮窗
  static Future<void> openPreview() async {
    if (Platform.isIOS) {
      return;
    }

    return _channel.invokeMethod('openPreview');
  }

  /// 直播状态变更
  ///
  /// 打开小窗口后调用，
  /// 解决：
  /// 观众先看一个直播，滑到小窗后，主播关播。然后这个观众看其他的直播，切小窗口就会弹直播结束了
  static Future<void> liveStatusChange(int status) async {
    if (Platform.isIOS) {
      return;
    }

    /// 如果是主播的话roomId要为null，否则小窗口的内容会为本地预览画面
    return _channel.invokeMethod('liveStatusChange', {"status": status});
  }

  static Future<void> dismiss() async {
    if (Platform.isIOS) {
      return;
    }
    return _channel.invokeMethod('dismiss');
  }

  static Future<bool?> get isRequestFloatPermission async {
    final bool? isHav = await _channel.invokeMethod('isRequestFloatPermission');
    return isHav;
  }

  static Future<bool?> get isShowFloat async {
    final bool? value = await _channel.invokeMethod('isShowFloat');
    return value;
  }

  static Future<bool?> get isRunningForeground async {
    final bool? value = await _channel.invokeMethod('isRunningForeground');
    return value;
  }

  static const clickStream = EventChannel('com.float.click/stream');
}
