import 'dart:convert';

import 'package:im/api/data_model/user_info.dart';

abstract class BaseRoom {
  /// 初始化房间
  Future<void> init(String roomId, RoomParams params);

  /// 离开房间
  Future<void> leave();
}

enum RoomState {
  inited, // 初始化完毕
  joined, // 参与者加入
  leaved, // 参与者离开
  ready, // 房间装载完成
  changed, // 参与者的静音、说话状态刷新
  messaged, // 有消息
  disconnected, // 断网
  error, // 错误
  quited,
  kickOut, //被移出房间
  muted, // 被禁麦
  reconnect, //重连中
  reconnectFail, //重连失败
  inRoomStatus, //自己加入房间状态，true与false
  roomFull,
  screenUserAdd, //有屏幕分享的用户被订阅了
}

class RoomParams {
  bool muted;
  bool enableCamera;
  bool useFrontCamera;
  bool enableTextRoom;

  String userId;
  String nickname;
  String avatar;
  String deviceId;

  String guildId;
  int maxParticipants;
  String channelId;
  String roomId;
  bool isGroupRoom;
  int publishers;

  RoomParams({
    this.muted = true,
    this.enableCamera = false,
    this.useFrontCamera = true,
    this.enableTextRoom = false,
    this.isGroupRoom = true,
    this.userId,
    this.nickname = "",
    this.avatar = "",
    this.deviceId,
    this.guildId,
    this.maxParticipants,
    this.channelId,
    this.roomId,
    this.publishers = 8,
  });

  String get display {
    final List<String> arr = [userId, nickname, avatar];
    return json.encode(arr);
  }
}

class RoomUser extends RoomParams implements UserInfo {
  RoomUser({String userId, String nickname, String avatar})
      : super(userId: userId) {
    super.avatar = avatar;
    super.nickname = nickname;
  }

  String id = "";

  bool talking = false;

  Map<String, dynamic> toJson() {
    return null;
  }

  @override
  int gender;

  @override
  String phoneNumber;

  @override
  String username;

  @override
  bool isEqual(UserInfo userInfo) {
    return false;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
