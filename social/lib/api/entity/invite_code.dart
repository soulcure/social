import 'package:im/common/extension/string_extension.dart';
import 'package:im/db/db.dart';

/// 生成的邀请码信息
class EntityInviteUrl {
  String url;
  String expire;
  String time;
  String number;
  String numberLess;
  String remark;

  String get code {
    final uri = Uri.parse(url);
    return uri.pathSegments.isEmpty ? null : uri.pathSegments.first;
  }

  EntityInviteUrl.fromJson(Map<String, dynamic> json) {
    url = json["url"];
    expire = json["expire"];
    time = json["time"];
    number = json["number"];
    numberLess = json["number_less"];
    remark = json['remark'];
  }
}

/// 邀请码列表的item
class EntityInviteCode {
  String code;
  String inviterName;
  String channelName;
  String expireTime;
  String numberLess;
  int created;
  String hasInvited;
  String avatar;
  String inviterId;
  String url;
  String remark;
  String channelId;
  String number;
  String time;
  int channelType;

  EntityInviteCode({
    this.code,
    this.inviterName,
    this.channelName,
    this.expireTime,
    this.numberLess,
    this.created,
    this.hasInvited,
    this.avatar,
    this.inviterId,
    this.url,
    this.remark,
    this.channelId,
    this.number,
    this.time,
    this.channelType,
  });

  EntityInviteCode copyWith(
      {String code,
      String inviterName,
      String channelName,
      String expireTime,
      String numberLess,
      int created,
      String hasInvited,
      String avatar,
      String inviterId,
      String url,
      String remark,
      String channelId,
      String number,
      String time,
      int channelType}) {
    return EntityInviteCode(
      code: code ?? this.code,
      inviterName: inviterName ?? this.inviterName,
      channelName: channelName ?? this.channelName,
      expireTime: expireTime ?? this.expireTime,
      numberLess: numberLess ?? this.numberLess,
      created: created ?? this.created,
      hasInvited: hasInvited ?? this.hasInvited,
      avatar: avatar ?? this.avatar,
      inviterId: inviterId ?? this.inviterId,
      url: url ?? this.url,
      remark: remark ?? this.remark,
      channelId: channelId ?? this.channelId,
      number: number ?? this.number,
      time: time ?? this.time,
      channelType: channelType ?? this.channelType,
    );
  }

  EntityInviteCode.fromJson(Map<String, dynamic> json) {
    code = json["code"];
    inviterName = json["inviter_name"];
    channelName = json["channel_name"];
    expireTime = json["expire_time"];
    created = json["created"];
    hasInvited = json["has_invited"];
    avatar = json["avatar"];
    numberLess = json["number_less"];
    inviterId = json["inviter_id"];
    url = json["url"];
    remark = json["remark"];
    channelId = json["channel_id"];
    number = json["number"];
    time = json["time"];
    channelType = json["channel_type"];
  }

  String getNickName() {
    final userInfo = Db.userInfoBox.get(inviterId);
    String nickName = userInfo?.showName();
    if (nickName.noValue) {
      nickName = inviterName;
    }
    return nickName;
  }
}

class EntityInviteCodeList {
  List<EntityInviteCode> records = [];
  int size;
  String listId;
  String next;

  EntityInviteCodeList({
    this.records,
    this.size,
    this.listId,
    this.next,
  });

  EntityInviteCodeList.fromJson(Map<String, dynamic> json) {
    final List<dynamic> list = json['records'];
    if (list != null && list.isNotEmpty) {
      records = list.map((e) => EntityInviteCode.fromJson(e)).toList();
    }
    size = json["size"];
    listId = json["list_id"];
    next = json["next"];
  }
}

/// 邀请码列表的item
class EntityInviteUserInfo {
  String nickname;
  String username;
  String userId;
  String avatar;
  int created;

  EntityInviteUserInfo.fromJson(Map<String, dynamic> json) {
    nickname = json["nickname"];
    username = json["username"];
    userId = json["user_id"];
    avatar = json["avatar"];
    created = json["created"];
  }
  String getNickName() {
    final userInfo = Db.userInfoBox.get(userId);
    String nickName = userInfo?.showName();
    if (nickName.noValue) {
      nickName = nickname;
    }
    return nickName;
  }
}

class EntityInviteUserInfoList {
  List<EntityInviteUserInfo> records = [];
  int size;
  String listId;
  String next;
  String hasInvited;

  EntityInviteUserInfoList({
    this.records,
    this.size,
    this.listId,
    this.next,
    this.hasInvited,
  });

  EntityInviteUserInfoList.fromJson(Map<String, dynamic> json) {
    final List<dynamic> list = json['records'];
    if (list != null && list.isNotEmpty) {
      records = list.map((e) => EntityInviteUserInfo.fromJson(e)).toList();
    }
    size = json["size"];
    listId = json["list_id"];
    next = json["next"];
    hasInvited = json["has_invited"];
  }
}
