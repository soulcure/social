class CloseRoomModel {
  String? roomId;
  String? liveTime;
  String? closeTime;
  int? audience;
  int? thumbCount;
  String? coin;
  bool? hasPlayback;

  CloseRoomModel(
      {this.roomId,
      this.liveTime,
      this.closeTime,
      this.audience,
      this.thumbCount,
      this.coin,
      this.hasPlayback});

  CloseRoomModel.fromJson(Map<String, dynamic> json) {
    roomId = json['roomId'];
    liveTime = json['liveTime'];
    closeTime = json['closeTime'];
    audience = json['audience'];
    thumbCount = json['thumbCount'];
    coin = json['coin'];
    hasPlayback = json['hasPlayback'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['roomId'] = roomId;
    data['liveTime'] = liveTime;
    data['closeTime'] = closeTime;
    data['audience'] = audience;
    data['thumbCount'] = thumbCount;
    data['coin'] = coin;
    data['hasPlayback'] = hasPlayback;
    return data;
  }
}
