class OnlineRankModel {
  bool? isGuest;
  String? userId;
  String? nickName;
  String? avatarUrl;
  int? coin;
  int? rank;

  OnlineRankModel(
      {this.isGuest,
      this.userId,
      this.nickName,
      this.avatarUrl,
      this.coin,
      this.rank});

  OnlineRankModel.fromJson(Map<String, dynamic> json) {
    isGuest = json['isGuest'];
    userId = json['userId'];
    nickName = json['nickName'];
    avatarUrl = json['avatarUrl'];
    coin = json['coin'];
    rank = json['rank'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['isGuest'] = isGuest;
    data['userId'] = userId;
    data['nickName'] = nickName;
    data['avatarUrl'] = avatarUrl;
    data['coin'] = coin;
    data['rank'] = rank;
    return data;
  }
}
