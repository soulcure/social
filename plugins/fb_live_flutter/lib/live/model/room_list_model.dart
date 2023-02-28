/*
直播列表对象模型
 */

import 'package:fb_live_flutter/live/utils/func/utils_class.dart';

class RoomListModel {
  String? roomId;
  String? anchorId;

  String? okNickName;

  String? avatarUrl; //头像类
  String? serverId;
  String? channelId;
  String? roomTitle;
  String? roomLogo;

  // 直播时间
  String? liveTime;
  String? closeTime;

  // 回放Url
  String? replayUrl;
  int? status; //2=正常；3=涉嫌违规;4=申诉中;5=违规
  int? openType; // 2=直播；3=专辑回放;4=回放
  int? audience;
  int? watchNum;
  int? audienceCount;

  //模拟
  int? replayCount; //专辑回放条数
  int? isPrivate; //1=隐私；2=不隐私
  int? isDelete; //1=已删除；2=正常
  // 回放状态
  int? playbackStatus; //1=正常；2=生成中；3=违规回放
  int? liveType; //直播类型：0-默认、1-APP、2-WEB、3-OBS

  /// 是否为回放生成中
  bool? isCreating;

  RoomListModel({
    this.roomId,
    this.anchorId,
    this.okNickName,
    this.avatarUrl,
    this.serverId,
    this.audience,
    this.watchNum,
    this.isCreating,
    this.channelId,
    this.roomTitle,
    this.roomLogo,
    this.liveTime,
    this.closeTime,
    this.status,
    this.openType,
    this.replayUrl,
    this.audienceCount,
    this.replayCount,
    this.isPrivate,
    this.liveType,
    this.playbackStatus = 1,
  });

  RoomListModel.fromJson(Map<String, dynamic> json, {int openTypeContent = 2}) {
    roomId = json['roomId'];
    liveType = json['liveType'];
    anchorId = json['anchorId'];
    okNickName =
        json['nickName'] ?? json['anchorNickName'] ?? json['anchorName'];
    avatarUrl =
        json['avatarUrl'] ?? json['anchorAvatar'] ?? json['anchorAvatarUrl'];
    serverId = json['serverId'];
    channelId = json['channelId'];
    audience = int.parse('${json['audience'] ?? 0}');
    watchNum = int.parse('${json['watchNum'] ?? 0}');
    roomTitle = json['roomTitle'];
    roomLogo = json['roomLogo'] ?? json['latestRoomLogo'];
    liveTime = json['liveTime'];
    closeTime = json['closeTime'];
    openType = openTypeContent;
    if (openType == 4) {
      if (json['status'] == 2) {
        status = 3;
      } else if (json['status'] == 3) {
        status = 5;
      } else {
        status = json['status'];
      }
    } else if (openType == 2) {
      if (json['status'] == 2) {
        status = 2;
      }
    }
    audienceCount = json['audience'];
    replayCount = json['num'];
    if (json['visibleScope'] == 2) {
      isPrivate = 1;
    } else {
      isPrivate = json['isPrivate'] ?? 2;
    }
    if (json['visibleScope'] == 3) {
      isDelete = 1;
    } else {
      isDelete = 2;
    }
    if (strNoEmpty(json['replayUrl'])) {
      playbackStatus = 1;
    } else if (json['status'] == 3) {
      playbackStatus = 3;
    } else {
      playbackStatus = 2;
    }
    playbackStatus = json['playbackStatus'] ?? 2;
    replayUrl = json['replayUrl'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['roomId'] = roomId;
    data['anchorId'] = anchorId;
    data['nickName'] = okNickName;
    data['avatarUrl'] = avatarUrl;
    data['serverId'] = serverId;
    data['channelId'] = channelId;
    data['roomTitle'] = roomTitle;
    data['roomLogo'] = roomLogo;
    data['liveTime'] = liveTime;
    data['closeTime'] = closeTime;
    data['status'] = status;
    data['openType'] = openType;
    data['audience'] = audienceCount;
    data['replayCount'] = replayCount;
    data['liveType'] = liveType;
    data['isPrivate'] = isPrivate;
    data['playbackStatus'] = playbackStatus;
    return data;
  }
}
