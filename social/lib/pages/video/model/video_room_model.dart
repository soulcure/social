import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/global.dart';
import 'package:im/hybrid/webrtc/room/base_room.dart';
import 'package:im/hybrid/webrtc/room/video_room.dart';
import 'package:im/hybrid/webrtc/room_manager.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/pages/home/view/dock.dart';
import 'package:im/pages/member_list/model/member_list_model.dart';
import 'package:im/utils/universal_platform.dart';
import 'package:im/utils/utils.dart';
import 'package:oktoast/oktoast.dart';
import 'package:wakelock/wakelock.dart';

class VideoRoomModel extends ChangeNotifier {
  static VideoRoomModel instance;
  static Function(String data) onError;

  /// 房间id
  int roomId;

  /// 是否开启摄像头
  ValueNotifier<bool> enableVideo = ValueNotifier<bool>(false);

  /// 是否静音
  ValueNotifier<bool> muted = ValueNotifier<bool>(false);

  /// 成员列表
  List<VideoUser> get users {
    return _videoRoom.users?.where((test) {
      return test != currentUser;
    })?.toList();
  }

  /// 当前显示人的信息
  VideoUser currentUser;

  /// 自己
  VideoUser me;

  /// 是否隐藏工具栏
  ValueNotifier<bool> hideToolbar = ValueNotifier<bool>(false);

  /// videoRoom controller
  VideoRoom _videoRoom;

  Timer _timer;

  bool isNotifyListener = true;

  bool _isScreenShareOpen = false;

  /// 文本聊天model
  // TextRoomModel textRoomModel;

  /// 判断主屏幕是否展示用户本人
  bool get isSelf => currentUser.id == me.id;

  bool get hasScreenShared {
    if (screenShareUser != null && screenShareUser.video != null) {
      return true;
    }
    return false;
  }

  VideoUser get screenShareUser {
    if (_videoRoom != null) {
      return _videoRoom.screenShareUser;
    }
    return null;
  }

  /// 本人开启视频或者其他人开启视频不显示video
  bool get currentShowVideo => currentUser != null && currentUser.enableCamera;

  /// 是否网络错误
  static ValueNotifier<bool> networkError = ValueNotifier(false);

  static Future<VideoRoomModel> create(String roomId) async {
    final VideoRoom room = await RoomManager.create(
      RoomType.video,
      roomId,
      RoomParams(
        userId: Global.user.id,
        nickname: Global.user.nickname,
        avatar: Global.user.avatar,
        deviceId: Global.deviceInfo.identifier,
      ),
    );
    await room.join();

    ///设置屏幕常亮
    await Wakelock.enable();
    VideoRoomModel.instance = VideoRoomModel(room);
    return instance;
  }

  VideoRoomModel(VideoRoom room) : assert(room != null) {
    _videoRoom = room;
    // textRoomModel = TextRoomModel(_videoRoom.textRoom);
    room.onEvent = _onEvent;
    currentUser = _videoRoom.user;
    me = _videoRoom.user;
  }

  void notifyListener({bool nowNotify = false}) {
    if (nowNotify == true) {
      notifyListeners();
      return;
    }

    if (isNotifyListener == true) {
      notifyListeners();
    }
  }

  void _onEvent(RoomState state, [data]) {
    if (instance == null) return;
    switch (state) {
      case RoomState.joined:
      case RoomState.changed:
        MemberListModel.instance.mediaUsers = _videoRoom.users;
        notifyListener();
        break;
      case RoomState.leaved:
        if (data == currentUser) {
          currentUser = _videoRoom.user;
        }
        notifyListener();
        // MemberListModel.instance.setMemberList(
        //     GlobalState.selectedChannel.value?.guildId,
        //     ChatChannelType.guildVideo,
        //     _videoRoom.users.map((e) => e.userId));
        break;
      case RoomState.error:
        if (onError != null) {
          onError('发生错误：%s'.trArgs([data.toString()]));
          onError = null;
        }
        break;
      case RoomState.disconnected:
        if (onError != null) {
          onError('视频被中断，请检查网络后重试'.tr);
          onError = null;
        }
        break;
      default:
        break;
    }
  }

  /// 打开屏幕共享
  void toggleScreenShare() {
    if (!_isScreenShareOpen) {
      _videoRoom.publishSharedScreenInRoom(
          "screenShare", _videoRoom.roomId, "test");
    } else {
      _videoRoom.closeSharedScreenInRoom();
    }
    _isScreenShareOpen = !_isScreenShareOpen;
  }

  /// 打开关闭摄像头
  void toggleCamera() {
    final bool res = !enableVideo.value;
    enableVideo.value = res;
    _videoRoom.enableCamera = res;
    notifyListener(nowNotify: true);
  }

  /// 切换摄像头
  Future<void> switchCamera() async {
    isNotifyListener = false;
    _videoRoom.enabledLocalVideoTrack(false);
    await _videoRoom.switchCamera();

    if (UniversalPlatform.isAndroid) {
      _timer?.cancel();
      _timer = Timer(const Duration(milliseconds: 400), () {
        isNotifyListener = true;
        notifyListener();
        _videoRoom.enabledLocalVideoTrack(true);
        _timer?.cancel();
      });
    } else {
      isNotifyListener = true;
      notifyListener();
      _videoRoom.enabledLocalVideoTrack(true);
    }
  }

  /// 切换静音
  void toggleMuted() {
    final bool res = !muted.value;
    muted.value = res;
    _videoRoom.muted = res;
  }

  /// 切换主屏幕
  void switchVideo(VideoUser user) {
    currentUser = user;
    notifyListener();
  }

  /// 工具栏显示隐藏
  void toggleToolbar() {
    hideToolbar.value = !hideToolbar.value;
  }

  /// 关闭房间
  Future<void> _close([String msg]) async {
    _timer?.cancel();
    if (instance != null) {
      instance = null;
      _videoRoom = null;
      if (isNotNullAndEmpty(msg)) showToast(msg);
      await RoomManager.close();
    }
  }

  /// 关闭+页面销毁
  Future<void> closeAndDispose([String msg]) async {
    _timer?.cancel();
    await Wakelock.disable();
    if (instance == null) return;
    await _close(msg);
    GlobalState.hangUp();
    Dock.noUpdateDock = false;
  }

  int getAudioLevel() {
    return 0;
  }
}
