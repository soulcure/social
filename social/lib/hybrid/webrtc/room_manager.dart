import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:im/dlog/dlog_manager.dart';
import 'package:im/hybrid/webrtc/room/audio_room.dart';
import 'package:im/hybrid/webrtc/room/base_room.dart';
import 'package:im/hybrid/webrtc/room/multi_video_room.dart';
import 'package:im/hybrid/webrtc/room/video_room.dart';
import 'package:im/hybrid/webrtc/tools/rtc_log.dart';
import 'package:im/pages/home/model/chat_target_model.dart';

enum RoomType { audio, video }

/// 音视频房间管理设计
/// 1. RoomManager 作为房间DataModel对象（VideoRoom,AudioRoom）的管理者,负责创建数据模型。

class RoomManager {
  static String premissError = "获取音视频设备失败".tr;
  static BaseRoom _room;
  static DateTime entryTime;
  static RoomParams roomParams;

  static const platform = MethodChannel('buff.com/rtc');

  static void init() {
    platform.setMethodCallHandler(rtcMethodCallHandel);
  }

  static Future rtcMethodCallHandel(MethodCall methodCall) async {
    if (methodCall.method == "mediaStreamState") {
      if (GlobalState.mediaChannel.value != null &&
          GlobalState.mediaChannel.value.item2 != null) {
        if (GlobalState.mediaChannel.value.item2.type ==
            ChatChannelType.guildVoice) {
          return Future.value({"type": "voice", "state": "open"});
        } else if (GlobalState.mediaChannel.value.item2.type ==
            ChatChannelType.guildVideo) {
          return Future.value({"type": "video", "state": "open"});
        } else {
          return Future.value({"type": "unknown", "state": "open"});
        }
      } else {
        return Future.value({"type": "noMedia", "state": "close"});
      }
    } else if (methodCall.method == 'QiAudioPlayerState') {
      final isPlay = methodCall.arguments['isPlay'];
      final mediaType = methodCall.arguments['mediaState']['type'];
      final mediaState = methodCall.arguments['mediaState']['state'];
      RtcLog.log(
          '无声音乐播放状态==$isPlay mediaType==$mediaType mediaState==$mediaState');
      return Future.value({});
    }
    return Future.value({"type": "other", "state": "close"});
  }

  /// 创建房间
  static Future<BaseRoom> create(
    RoomType type,
    String roomId,
    RoomParams params, {
    bool isMultiRoom = false,
  }) async {
    await close();
    _room = type == RoomType.audio
        ? AudioRoom()
        : (isMultiRoom ? MultiVideoRoom() : VideoRoom());
    roomParams = params;
    entryTime = DateTime.now();
    if (type == RoomType.audio)
      dLogAppAudioUserJoinFb(null, roomParams.guildId, '1', '1',
          roomParams.channelId, roomParams.roomId, 1);
    await _room.init(roomId, params);
    return _room;
  }

  /// 关闭房间
  static Future<void> close() async {
    if (_room != null) {
      if (_room is AudioRoom)
        dLogAppAudioUserJoinFb(entryTime, roomParams.guildId, '1', '2',
            roomParams.channelId, roomParams.roomId, 1);
      try {
        await _room.leave();
      } catch (e) {
        throw "leave room error:$e";
      }
      _room = null;
      entryTime = null;
      roomParams = null;
    }
  }

  /// 音视频直播用户参与
  /// audio_log_type: 枚举值：1=语音频道日志， 2=视频频道日志
  /// opt_type: 1、joined=进入房间；2、left=退出房间;
  /// user_type: 1=fanbook app 用户，0= 游客用户
  static void dLogAppAudioUserJoinFb(
    DateTime entryTime,
    String guildId,
    String audioLogType,
    String optType,
    String channelId,
    String roomId,
    int userType,
  ) {
    int joinDuration = -1;
    if (entryTime != null)
      joinDuration = DateTime.now().difference(entryTime).inSeconds;
    DLogManager.getInstance()
        .extensionEvent(logType: 'dlog_app_audio_user_join_fb', extJson: {
      'guild_id': guildId,
      'audio_log_type': audioLogType,
      'opt_type': optType == '1' ? 'joined' : 'left',
      'channel_id': channelId,
      'room_id': roomId,
      if (joinDuration >= 0) 'join_duration': joinDuration,
      'user_type': userType,
    });
  }
}
