import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/app/controllers/audio_room_controller.dart';
import 'package:im/hybrid/jpush_util.dart';
import 'package:im/pages/home/model/action_processor/av_call.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/pages/video/model/video_room_model.dart';
import 'package:im/pages/video_call/model/video_model.dart';
import 'package:im/pages/video_call/view/video_tips.dart';
import 'package:im/routes.dart';
import 'package:im/utils/universal_platform.dart';
import 'package:pedantic/pedantic.dart';

import '../../app.dart';

class CallInfo {
  final String userId;
  final String roomId;
  final bool isVideo;
  final String messageId;
  final ValueNotifier<bool> cancel = ValueNotifier<bool>(false);

  CallInfo(this.userId, this.roomId, this.isVideo, this.messageId);
}

class VideoControl {
  static final List<CallInfo> list = [];

  static void handleCall(Map data) {
    final String userId = data["user"]["userId"];
    final String name = data["user"]["nickname"];
    final String roomId = data["channelId"];
    final bool isVideo = data["video"] == 1;
    final String messageId = data["message_id"] ?? "";

    if (App.appLifecycleState != AppLifecycleState.resumed || kIsWeb) {
      unawaited(JPushUtil.pushNotification(
          title: name,
          content: "来电，请接听~~".tr,
          sound: UniversalPlatform.isIOS ? "ring1.caf" : "ring1.mp3",
          fireTime: DateTime.now().add(const Duration(milliseconds: 100))));
    }

    AudioRoomController c;
    if (GlobalState.mediaChannel.value != null &&
        GlobalState.mediaChannel.value.item2 != null &&
        GlobalState.mediaChannel.value.item2.type ==
            ChatChannelType.guildVoice) {
      try {
        c = Get.find<AudioRoomController>(
            tag: GlobalState.mediaChannel.value.item2.id);
      } catch (_) {}
    }

    if (VideoModel.instance == null &&
        VideoRoomModel.instance == null &&
        c == null) {
      Routes.pushVideoPage(
        Get.context,
        userId,
        isCaller: false,
        roomId: roomId,
        isVideo: isVideo,
      );
    } else {
      //显示提示
      list.add(CallInfo(userId, roomId, isVideo, messageId));
      _showTips();
    }
  }

  static CallInfo _currentInfo;

  static void _showTips() {
    if (_currentInfo != null) return;
    if (list.isNotEmpty) {
      _currentInfo = list.removeAt(0);
      Get.dialog(VideoTips(_currentInfo));
    }
  }

  static Future<void> handleCancel(String msg, String roomId) async {
    if (VideoModel.instance != null && VideoModel.instance.roomId == roomId) {
      await VideoModel.instance.closeAndDispose(msg);
    } else {
      list.removeWhere((test) {
        return test.roomId == roomId;
      });
      if (_currentInfo != null && _currentInfo.roomId == roomId) {
        _currentInfo.cancel.value = true;
        _currentInfo = null;
      }
      _showTips();
    }
  }

  static void cancel(CallInfo info) {
    print("cancel call ${info.roomId}");
    AVCall.changeVideoCall(info.roomId, 3, info.userId, info.messageId);
    VideoControl.handleCancel("", info.roomId);
  }

  static Future<void> answer(CallInfo info) async {
    if (_currentInfo != null && _currentInfo == info) {
      _currentInfo.cancel.value = true;
      _currentInfo = null;
    }

    if (VideoModel.instance != null) {
      VideoModel.instance.sendCancelMessage();
      await VideoModel.instance.closeAndDispose();
    }

    if (VideoRoomModel.instance != null) {
      await VideoRoomModel.instance.closeAndDispose();
    }

    if (GlobalState.mediaChannel.value != null &&
        GlobalState.mediaChannel.value.item2 != null &&
        GlobalState.mediaChannel.value.item2.type ==
            ChatChannelType.guildVoice) {
      try {
        final AudioRoomController c = Get.find<AudioRoomController>(
            tag: GlobalState.mediaChannel.value.item2.id);
        if (c != null) {
          await c.closeAndDispose();
        }
      } catch (_) {}
    }

    unawaited(Routes.pushVideoPage(
      Get.context,
      info.userId,
      isCaller: false,
      autoAnswer: true,
      roomId: info.roomId,
      isVideo: info.isVideo,
    ));
  }
}
