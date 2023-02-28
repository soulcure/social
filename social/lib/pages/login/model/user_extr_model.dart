import 'dart:convert';

class UserPreData {
  String avatar;
  int gender;
  String nickname;

  UserPreData({this.avatar, this.gender, this.nickname});

  UserPreData.fromMap(Map<String, dynamic> map) {
    avatar = map['avatar'];
    gender = map['gender'];
    nickname = map['nickname'];
  }

  Map toJson() => {'avatar': avatar, 'gender': gender, 'nickname': nickname};

  @override
  String toString() {
    return json.encode(toJson());
  }

  bool isNotEmpty() {
    return avatar != null && nickname != null;
  }
}

class UserBoundData {
  String oldName;
  String newName;

  UserBoundData({this.oldName, this.newName});

  UserBoundData.fromMap(Map<String, dynamic> map) {
    oldName = map['old'];
    newName = map['new'];
  }

  Map toJson() => {'old': oldName, 'new': newName};
}
