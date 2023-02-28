class OnlineUserCount {
  int? thumbCount;
  int? total;
  List<Users>? users;

  OnlineUserCount({this.thumbCount, this.total, this.users});

  OnlineUserCount.fromJson(Map<String, dynamic> json) {
    thumbCount = json['thumbCount'];
    total = json['total'];
    if (json['users'] != null) {
      users = <Users>[];
      json['users'].forEach((v) {
        users!.add(Users.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['thumbCount'] = thumbCount;
    data['total'] = total;
    if (users != null) {
      data['users'] = users!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Users {
  bool? isGuest;
  String? userId;
  String? nickName;
  String? avatarUrl;
  int? coin;

  Users({this.isGuest, this.userId, this.nickName, this.avatarUrl, this.coin});

  Users.fromJson(Map<String, dynamic> json) {
    isGuest = json['isGuest'];
    userId = json['userId'];
    nickName = json['nickName'];
    avatarUrl = json['avatarUrl'];
    coin = json['coin'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['isGuest'] = isGuest;
    data['userId'] = userId;
    data['nickName'] = nickName;
    data['avatarUrl'] = avatarUrl;
    data['coin'] = coin;
    return data;
  }
}
