/// forbid_user_id : 275505168861102080
/// user_nickname : "了解了"
/// forbid_user_avatar : "https://fb-cdn.fanbook.mobi/fanbook/app/files/service/headImage/47515b9b54544c424a1e09763ef576c8"
/// forbid_id : 12
/// create_user_nickname : "seven"
/// forbid_roles : [273730814796103680]
/// endtime : 590

class MuteListBean {
  MuteListBean({
    int forbidUserId,
    String userNickname,
    String forbidUserAvatar,
    int forbidId,
    String createUserNickname,
    List<int> forbidRoles,
    int endtime,
  }) {
    _forbidUserId = forbidUserId;
    _userNickname = userNickname;
    _forbidUserAvatar = forbidUserAvatar;
    _forbidId = forbidId;
    _createUserNickname = createUserNickname;
    _forbidRoles = forbidRoles;
    _endtime = endtime;
  }

  MuteListBean.fromJson(Map<String, dynamic> json) {
    _forbidUserId = json['forbid_user_id'];
    _userNickname = json['user_nickname'];
    _forbidUserAvatar = json['forbid_user_avatar'];
    _forbidId = json['forbid_id'];
    _createUserNickname = json['create_user_nickname'];
    _forbidRoles =
        json['forbid_roles'] != null ? json['forbid_roles'].cast<int>() : [];
    _endtime = json['endtime'];
  }
  int _forbidUserId;
  String _userNickname;
  String _forbidUserAvatar;
  int _forbidId;
  String _createUserNickname;
  List<int> _forbidRoles;
  int _endtime;

  int get forbidUserId => _forbidUserId;
  String get userNickname => _userNickname;
  String get forbidUserAvatar => _forbidUserAvatar;
  int get forbidId => _forbidId;
  String get createUserNickname => _createUserNickname;
  List<int> get forbidRoles => _forbidRoles;
  int get endtime => _endtime;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['forbid_user_id'] = _forbidUserId;
    map['user_nickname'] = _userNickname;
    map['forbid_user_avatar'] = _forbidUserAvatar;
    map['forbid_id'] = _forbidId;
    map['create_user_nickname'] = _createUserNickname;
    map['forbid_roles'] = _forbidRoles;
    map['endtime'] = _endtime;
    return map;
  }
}
