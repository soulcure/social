import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/app/controllers/audio_room_controller.dart';
import 'package:im/global.dart';
import 'package:im/live_provider/live_api_provider.dart';
import 'package:im/pages/home/model/chat_target_model.dart';

/// 弹出提示弹窗，让用户选择是否关闭当前使用媒体设备的页面，返回是否关闭此页面
Future<bool> _showAlert(String title) async {
  final context = Global.navigatorKey.currentContext;
  final res = await showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: Text(title),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, 0),
          child: Text("取消".tr),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, 1),
          child: Text("确认".tr),
        ),
      ],
    ),
  );
  return res == 1;
}

/// 拼接对话框提示
String _concatTitle({
  @required String desc,
  String purpose,
  String condition,
  String defaultCondition,
}) {
  if (purpose == null) {
    return "$desc，$defaultCondition";
  }
  return "$desc，$purpose$condition";
}

/// 返回是否退出音视频频道
/// @param onlyVideo: 只检测是否处于视频频道
Future<bool> checkAndExitAVChannel(
    {bool onlyVideo = false, String purpose}) async {
  /// 没有处于音视频频道
  if (GlobalState.mediaChannel.value == null) return true;

  /// 是否处于视频频道
  final isVideo =
      GlobalState.mediaChannel.value.item2.type == ChatChannelType.guildVideo;

  final isInAudio =
      GlobalState.mediaChannel.value.item2.type == ChatChannelType.guildVoice;

  String desc;
  if (onlyVideo) {
    /// 只检测是否处于视频频道
    if (!isVideo) {
      /// 当前没有在视频频道中
      return true;
    }
    desc = "你当前正处在视频 频道中".tr;
  } else {
    desc = "你当前正处在语音/视频 频道中".tr;
  }

  final title = _concatTitle(
    desc: desc,
    purpose: purpose,
    condition: "将会退出该频道".tr,
    defaultCondition: "请先退出该频道".tr,
  );
  final res = await _showAlert(title);
  if (res) {
    if (isInAudio) {
      // 退出音频房间
      try {
        final AudioRoomController c = Get.find<AudioRoomController>(
            tag: GlobalState.mediaChannel.value.item2.id);
        await c.closeAndDispose();
      } catch (_) {}
    } else {
      /// 确认退出音视频频道
      GlobalState.hangUp();
    }
  }
  return res;
}

/// 返回是否退出直播
/// @param onlyStreamer: 只检测主播
Future<bool> checkAndExitLiveRoom(
    {bool onlyStreamer = false, String purpose}) async {
  /// 没有正在观看的直播间
  if (!FBLiveApiProvider.instance.hasLive) return true;

  String desc;

  // if (onlyStreamer) {
  //   /// 只检测是否是当前直播间的主播
  //   if (!FBAPI.isStreamer) {
  //     /// 不是主播
  //     return true;
  //   }
  //   desc = "你当前正在直播".tr;
  // } else {
  //   desc = "你当前正在观看直播".tr;
  // }

  if (FBLiveApiProvider.instance.isStreamer) {
    desc = "你当前正在直播".tr;
  } else {
    if (onlyStreamer) return true;
    desc = "你当前正在观看直播".tr;
  }

  final title = _concatTitle(
    desc: desc,
    purpose: purpose,
    condition: "需要退出直播间".tr,
    defaultCondition: "请先退出直播间".tr,
  );
  final res = await _showAlert(title);
  if (res) {
    /// 确认退出直播间
    await FBLiveApiProvider.instance.closeLive();
  }
  return res;
}
