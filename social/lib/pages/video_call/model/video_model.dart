import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/app/controllers/audio_room_controller.dart';
import 'package:im/global.dart';
import 'package:im/hybrid/webrtc/room/base_room.dart';
import 'package:im/hybrid/webrtc/room/video_room.dart';
import 'package:im/hybrid/webrtc/room_manager.dart';
import 'package:im/loggers.dart';
import 'package:im/pages/home/model/action_processor/av_call.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/pages/home/view/dock.dart';
import 'package:im/pages/video/model/video_room_model.dart';
import 'package:im/utils/utils.dart';
import 'package:oktoast/oktoast.dart';
import 'package:wakelock/wakelock.dart';

enum VideoState {
  calling,
  receiving,
  chatting,
  roomChatting,
}

class VideoModel extends ChangeNotifier {
  static Function(String data) onError;
  static VideoModel instance;
  VideoState state = VideoState.calling;
  Function() onComplete;

  String roomId = "";
  String messageId = "";

  /// 是否开启摄像头
  final ValueNotifier<bool> enableVideo = ValueNotifier<bool>(false);

  /// 是否静音
  final ValueNotifier<bool> muted = ValueNotifier<bool>(false);

  /// 是否已经通知对方，等待响应
  final ValueNotifier<bool> waitingAnswer = ValueNotifier<bool>(false);

  /// 是否已经连接
  final ValueNotifier<DateTime> connectTimer = ValueNotifier<DateTime>(null);

  /// 对方拒绝
  // ValueNotifier<bool> canceled = ValueNotifier<bool>(false);

  /// 成员列表
  List<VideoUser> get users {
    if (_room == null) return [];
    return _room.users.where((test) {
      return test != currentUser;
    }).toList();
  }

  /// 当前显示人的信息
  VideoUser currentUser;

  /// 是否显示工具栏
  final ValueNotifier<bool> showToolBar = ValueNotifier(false);

  VideoRoom _room;
  String callUserId;
  bool disposed = false;
  bool isOwner = false;
  bool isVideo = false;
  bool called = false;
  Timer _timer;

  VideoModel(this.isVideo) {
    instance = this;
  }

  Future<void> init() async {
    // TODO 有没更好的方式
    // 关闭已经打开的音视频房间通话
    if (GlobalState.mediaChannel.value != null &&
        GlobalState.mediaChannel.value.item2 != null &&
        GlobalState.mediaChannel.value.item2.type ==
            ChatChannelType.guildVoice) {
      try {
        final AudioRoomController c = Get.find<AudioRoomController>(
            tag: GlobalState.mediaChannel.value.item2.id);
        if (c != null) {
          await c.closeAndDispose(flag: 3);
        }
      } catch (_) {}
    }

    if (VideoRoomModel.instance != null) {
      await VideoRoomModel.instance.closeAndDispose();
    }
    _room = await RoomManager.create(
      RoomType.video,
      roomId,
      RoomParams(
        userId: Global.user.id,
        nickname: Global.user.nickname,
        avatar: Global.user.avatar,
        isGroupRoom: false,
      ),
    );
    _room.onEvent = _onEvent;
    _room.enableCamera = isVideo;
    enableVideo.value = isVideo;
    currentUser = _room.user;

    ///设置屏幕常亮
    await Wakelock.enable();
  }

  Future<void> call(String userId) async {
    try {
      if (called) return;
      called = true;
      final data = await AVCall.call(userId, isVideo);
      isOwner = true;
      roomId = data["channelId"] ?? "";
      messageId = data["message_id"] ?? "";
      waitingAnswer.value = true;
      _timer = Timer(const Duration(seconds: 30), () {
        if (onComplete != null) closeAndDispose("对方无人接听".tr);
      });
      await _joinRoom();
    } catch (e, s) {
      logger.info(e, s);
      called = false;
      if (onComplete != null) await closeAndDispose("呼叫失败，请检查网络后重试".tr);
    }
  }

  Future<void> answer() async {
    await _joinRoom();
    isOwner = false;
    AVCall.changeVideoCall(roomId, 1, callUserId, messageId);
    state = VideoState.chatting;
    notifyListeners();
  }

  Future<void> answerCancel() async {
    sendCancelMessage();
    notifyListeners();
  }

  Future<void> _joinRoom() async {
    _room.roomId = roomId;
    await _room.join();
  }

  void _onEvent(RoomState roomState, [data]) {
    switch (roomState) {
      case RoomState.joined:
        state = VideoState.chatting;
        if (currentUser == null || currentUser.userId == Global.user.id) {
          users.forEach((f) {
            if (f.userId != Global.user.id) {
              currentUser = f;
            }
          });
        }
        connectTimer.value = DateTime.now();
        _timer?.cancel();
        notifyListeners();
        break;
      case RoomState.changed:
        notifyListeners();
        break;
      case RoomState.leaved:
        if (data == currentUser) {
          currentUser = _room.user;
        }
        if (onComplete != null) {
          closeAndDispose("通话已结束".tr);
        }
        notifyListeners();
        break;
      case RoomState.error:
        if (onError != null) {
          onError('发生错误：%s'.trArgs([data.toString()]));
          onError = null;
        }
        break;
      case RoomState.disconnected:
        if (onError != null) {
          onError('通话被中断，请检查网络后重试'.tr);
          onError = null;
        }
        break;
      default:
        break;
    }
  }

  /// 打开关闭摄像头
  bool toggleCamera() {
    final bool res = !enableVideo.value;
    enableVideo.value = res;
    _room.enableCamera = res;
    notifyListeners();
    return res;
  }

  /// 切换摄像头
  Future<bool> switchCamera() async {
    final result = await _room.switchCamera();
    notifyListeners();
    return result;
  }

  /// 切换静音
  bool toggleMuted() {
    final bool res = !muted.value;
    muted.value = res;
    _room.muted = res;
    return res;
  }

  /// 切换工具栏
  void toggleToolBar() {
    showToolBar.value = !showToolBar.value;
  }

  /// 切换主屏幕
  void switchVideo(VideoUser user) {
    currentUser = user;
    notifyListeners();
  }

  /// 关闭房间
  Future<void> close([String message]) async {
    if (!disposed) {
      await Wakelock.disable();
      disposed = true;
      instance = null;
      _timer?.cancel();
      sendCancelMessage();
      _room = null;
      if (isNotNullAndEmpty(message)) showToast(message);
      Dock.hide();
      Dock.noUpdateDock = false;
      await RoomManager.close();
    }
  }

  /// 关闭房间+销毁页面
  Future<void> closeAndDispose([String msg]) async {
    if (disposed) return;
    await close(msg);
    if (onComplete != null) onComplete();
  }

  void sendCancelMessage() {
    var type = 0;
    if (state == VideoState.calling) {
      type = 4;
    } else if (state == VideoState.receiving) {
      type = 3;
    } else if (users.length < 2) {
      // 最后一个人
      type = 6;
    }
    AVCall.changeVideoCall(roomId, type, callUserId, messageId);
  }

  @override
  void dispose() {
    close();
    super.dispose();
  }
}
