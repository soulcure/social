import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:fb_live_flutter/live/pages/live_room/live_room.dart';
import 'package:fb_live_flutter/live/utils/func/utils_class.dart';
import 'package:fb_live_flutter/live/widget_common/flutter/click_event.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:zego_express_engine/zego_express_engine.dart';

/// 防止同时多个事件
/// 关键字：防多次点击、防点击
/// 目前临时使用，只限非组件点击时
///
/// 组件触发全部使用[ClickEvent]
bool isTemporaryTapProcessing = false;

void restoreTemporaryProcess([int milliseconds = 500]) {
  Future.delayed(Duration(milliseconds: milliseconds)).then((value) {
    isTemporaryTapProcessing = false;
  });
}

///去除小数点
String removeDot(String v) {
  final String vStr = v.toString().replaceAll('.', '');

  return vStr;
}

///补齐数字两位
String doubleNum(String v) {
  final int _v = int.parse(removeDot(v));
  if (_v <= 0) {
    return '00';
  } else if (_v.toString().length < 2) {
    return '0$_v';
  } else {
    return '$_v';
  }
}

/// 数字千分位方法及其价格保留两位小数
String formatNum(String? num, {int point = 2, bool isMark = true}) {
  /// 【APP】添加购物车异常
  if (strNoEmpty(num)) {
    final String str = double.parse(num.toString()).toString();
    final List<String> sub = str.split('.');
    final List val = List.from(sub[0].split(''));
    List<String> points = List.from(sub[1].split(''));
    if (isMark) {
      for (int index = 0, i = val.length - 1; i >= 0; index++, i--) {
        //  && i != 1
        if (index % 3 == 0 && index != 0) val[i] = '${val[i]},';
      }
    }
    for (int i = 0; i <= point - points.length; i++) {
      points.add('0');
    }
    if (points.length > point) {
      points = points.sublist(0, point);
    }
    final String joinPoints = points.join();
    if (points.isNotEmpty) {
      return '${val.join()}${joinPoints == "00" ? "" : ".$joinPoints"}';
    } else {
      return val.join();
    }
  } else {
    return "0";
  }
}

/// 是否主流id
bool isMainSteamId(String streamID, State<LiveRoom>? statePage) {
  return streamID.contains("_camera") ||
      streamID == statePage!.widget.liveValueModel!.roomInfoObject!.roomId ||
      statePage.widget.liveValueModel!.getIsObs;
}

/// 如果直播类型为obs/房间id/摄像头直接拉流，
bool isPlayStream(List<ZegoStream> streamList, State<LiveRoom>? statePage) {
  for (final ZegoStream stream1 in streamList) {
    final String streamID = stream1.streamID;
    // 只有摄像头流变动和普通直播流变动才执行
    if (isMainSteamId(streamID, statePage)) {
      return true;
    }
  }
  return false;
}

/*
* 获取设备信息
* */
Future<String?> getDeviceInfo() async {
  if (kIsWeb) {
    return "web";
  }
  final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
  if (Platform.isAndroid) {
    final AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
    return androidInfo.androidId;
  } else if (Platform.isIOS) {
    final IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
    return iosInfo.identifierForVendor;
  } else {
    return 'unknown';
  }
}

/*
* 获取版本信息
* 直播开始接口api变更【需要用到】
* */
Future<String> getVersionInfo() async {
  if (kIsWeb) {
    return "webVersion";
  }
  final packageInfo = await PackageInfo.fromPlatform();
  return packageInfo.version;
}
