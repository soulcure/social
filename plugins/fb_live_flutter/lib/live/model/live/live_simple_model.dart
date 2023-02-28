/// **************************************************************************
/// 来自Q1Json转Dart工具
/// ignore_for_file: non_constant_identifier_names,library_prefixes
/// **************************************************************************

/*
* 参数名 类型 必填 描述
* @param roomId
* @param string 是 直播间ID
* @param serverId
* @param string 是 服务器Id
* @param channelId
* @param string 是 频道Id
* @param anchorId
* @param int64 是 主播Id
* @param nickName
* @param string 是 主播昵称
* @param avatarUrl
* @param string 是 主播头像
* @param roomTitle
* @param string 是 直播间标题
* @param roomLogo
* @param string 是 直播间封面URL
* @param closeTime
* @param datetime 否 直播结束时间
* @param status
* @param int 是 直播状态：1-等待直播、2-正在直播、3-直播结束、4-直播回放
* @param replayUrl
* @param string 否 回放地址
* @param liveType 直播类型：0-默认、1-APP、2-WEB、3-OBS、4-MIX
*
1. 直播中    就是状态【正在直播】
2. 直播结束，生成回放中      状态是【直播结束】的时间+10分钟内显示回放生成中的页面
3. 直播结束，无回放     状态是【直播结束】的时间+10分钟后，显示无回放
4. 直播回放    状态【直播回放】
*
* 时间：closeTime
*
* */
class LiveSimpleModel {
  final String? roomId;
  final String? serverId;
  final String? channelId;
  final String? anchorId;
  final String? nickName;
  final String? avatarUrl;
  final String? roomTitle;
  final String? roomLogo;
  final String? closeTime;
  final int? status;
  final int? liveType;
  final String? replayUrl;

  LiveSimpleModel({
    this.roomId,
    this.serverId,
    this.liveType,
    this.channelId,
    this.anchorId,
    this.nickName,
    this.avatarUrl,
    this.roomTitle,
    this.roomLogo,
    this.closeTime,
    this.status,
    this.replayUrl,
  });

  factory LiveSimpleModel.fromJson(Map<String, dynamic> json) =>
      _$LiveSimpleModelFromJson(json);

  LiveSimpleModel from(Map<String, dynamic> json) =>
      _$LiveSimpleModelFromJson(json);

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['roomId'] = roomId;
    data['serverId'] = serverId;
    data['channelId'] = channelId;
    data['anchorId'] = anchorId;
    data['nickName'] = nickName;
    data['avatarUrl'] = avatarUrl;
    data['roomTitle'] = roomTitle;
    data['roomLogo'] = roomLogo;
    data['closeTime'] = closeTime;
    data['status'] = status;
    data['liveType'] = liveType;
    data['replayUrl'] = replayUrl;
    return data;
  }
}

LiveSimpleModel _$LiveSimpleModelFromJson(Map<String, dynamic> json) {
  return LiveSimpleModel(
    roomId: json['roomId'],
    serverId: json['serverId'],
    channelId: json['channelId'],
    anchorId: json['anchorId'],
    nickName: json['nickName'],
    avatarUrl: json['avatarUrl'],
    roomTitle: json['roomTitle'],
    roomLogo: json['roomLogo'],
    closeTime: json['closeTime'],
    status: json['status'],
    replayUrl: json['replayUrl'],
    liveType: json['liveType'],
  );
}
