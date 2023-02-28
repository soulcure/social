class StickerBean {
  String avatar;
  int position;
  String name;
  double width;
  double height;

  StickerBean(this.avatar, this.name, {this.width, this.height});

  StickerBean.fromMap(Map map) {
    avatar = map['avatar'];
    position = map['position'];
    name = map['name'];
    width = map['w']?.toDouble();
    height = map['h']?.toDouble();
  }

  Map toJson() => {
        "avatar": avatar,
        "position": position,
        "name": name,
        "w": width,
        "h": height
      };

  static List<StickerBean> fromMapList(List<dynamic> map) {
    final List<StickerBean> result = [];
    map?.forEach((element) {
      result.add(StickerBean.fromMap(element));
    });
    return result;
  }

  static List<StickerBean> copyFromList(List<StickerBean> otherList) =>
      otherList.map((e) => e.clone(e)).toList();

  StickerBean clone(StickerBean other) => StickerBean(other.avatar, other.name,
      width: other.width, height: other.height);
}

class UserBean {
  dynamic username;
  dynamic nickname;
  String avatar;
  String userId;

  UserBean({this.username, this.nickname, this.avatar, this.userId});

  UserBean.fromMap(Map<String, dynamic> map) {
    if (map?.isEmpty ?? true) return;
    username = map['username'];
    nickname = map['nickname'];
    avatar = map['avatar'];
    userId = map['user_id'];
  }

  Map toJson() => {
        "username": username,
        "nickname": nickname,
        "avatar": avatar,
        "user_id": userId,
      };
}
