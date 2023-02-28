class RoomInfon {
  late String roomId;
  String? anchorId;
  String? nickName;
  String? avatarUrl;
  String? serverName;
  String? channelName;
  String? roomTitle;
  late String roomLogo;
  String? liveTime;
  String? closeTime;
  late int status;
  int? openType;
  late int liveType;
  int? shareType;
  late String serverId;
  late String channelId;
  List<String>? tags;
  String? tips;

  RoomInfon(
      {required this.roomId,
      this.anchorId,
      this.nickName,
      this.avatarUrl,
      this.serverName,
      this.channelName,
      this.roomTitle,
      required this.roomLogo,
      this.liveTime,
      this.closeTime,
      required this.status,
      this.openType,
      required this.liveType,
      this.shareType,
      required this.serverId,
      required this.channelId,
      this.tags,
      this.tips});

  RoomInfon.fromJson(Map<String, dynamic> json) {
    roomId = json['roomId'];
    anchorId = json['anchorId'];
    nickName = json['nickName'];
    avatarUrl = json['avatarUrl'];
    serverName = json['serverName'];
    channelName = json['channelName'];
    roomTitle = json['roomTitle'];
    roomLogo = json['roomLogo'];
    liveTime = json['liveTime'];
    closeTime = json['closeTime'];
    status = json['status'];
    openType = json['openType'];
    liveType = json['liveType'];
    shareType = json["shareType"];
    serverId = json["serverId"];
    channelId = json["channelId"];
    tags = json['tags'].cast<String>();
    tips = json['tips'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['roomId'] = roomId;
    data['anchorId'] = anchorId;
    data['nickName'] = nickName;
    data['avatarUrl'] = avatarUrl;
    data['serverName'] = serverName;
    data['channelName'] = channelName;
    data['roomTitle'] = roomTitle;
    data['roomLogo'] = roomLogo;
    data['liveTime'] = liveTime;
    data['closeTime'] = closeTime;
    data['status'] = status;
    data['openType'] = openType;
    data['liveType'] = liveType;
    data['shareType'] = shareType;
    data['serverId'] = serverId;
    data['channelId'] = channelId;
    data['tags'] = tags;
    data['tips'] = tips;
    return data;
  }
}
