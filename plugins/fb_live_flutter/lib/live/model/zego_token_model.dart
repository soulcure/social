class ZegoTokenModel {
  String? token;
  String? roomId;
  String? userId;
  String? userName;
  String? anchorId;
  String? userToken;

  ZegoTokenModel(
      {this.token,
      this.roomId,
      this.userId,
      this.userName,
      this.anchorId,
      this.userToken});

  ZegoTokenModel.fromJson(Map<String, dynamic> json) {
    token = json['token'];
    roomId = json['roomId'];
    userId = json['userId'];
    userName = json['userName'];
    anchorId = json['anchorId'];
    userToken = json['userToken'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['token'] = token;
    data['roomId'] = roomId;
    data['userId'] = userId;
    data['userName'] = userName;
    data['anchorId'] = anchorId;
    data['userToken'] = userToken;
    return data;
  }
}
