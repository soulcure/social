import 'package:get/get.dart';
import 'package:im/db/message_card_key_table.dart';
import 'package:im/pages/home/json/text_chat_json.dart';

import '../../../global.dart';

class MessageCardKeyModel {
  int count;
  bool me;
  String userId;

  MessageCardKeyModel([this.count = 0, this.me = false, this.userId]);

  void set(String userId) {
    if (userId == Global.user.id) {
      me = true;
    }
    // 只记录第一个 UserId
    if (this.userId == null) this.userId = userId;
    count++;
  }

  void clear(String userId) {
    if (userId == Global.user.id) {
      me = false;
    }
    if (this.userId == userId) this.userId = null;
    count--;
  }
}

class MessageCardEntity extends MessageContentEntity with NotifyManager {
  final double width;
  final double height;
  final String data;
  final String notification;
  final String edition;

  //  来源：图标
  final String comeFromIcon;

  //  来源：名称
  final String comeFromName;

  Map<String, MessageCardKeyModel> keys;

  MessageCardEntity({
    this.width,
    this.height,
    this.data,
    this.notification,
    this.edition,
    this.comeFromIcon,
    this.comeFromName,
  }) : super(MessageType.messageCard);

  /// 从本地数据库读取数据，如果已经读取过，则直接返回
  bool localDataReady = false;

  Future<void> loadKeysFromLocal(String messageId) async {
    if (localDataReady) return;

    keys ??= {};
    await MessageCardKeyTable.load(messageId, keys);
    localDataReady = true;
    subject.add(null);
  }

  /// 从其他消息里面拷贝数据，例如来自 pin 列表的数据
  void resetKeys(Map<String, MessageCardKeyModel> keys) {
    localDataReady = true;
    this.keys = keys;
  }

  void loadKeysFromJson(List<dynamic> json) {
    localDataReady = true;

    keys ??= {};
    for (final data in json) {
      keys[data['key']] ??= MessageCardKeyModel(
        data['count'],
        data['me'],
        data['user_ids'],
      );
    }
  }

  /////

  void setKey(String key, String userId) {
    keys ??= {};
    keys[key] ??= MessageCardKeyModel();
    keys[key].set(userId);
    subject.add(null);
  }

  void clearKey(String key, String userId) {
    if (keys == null) return;
    if (keys[key] == null) return;
    keys[key].clear(userId);
    subject.add(null);
  }

  bool hasKeyMyself(String key) {
    if (keys == null) return false;
    if (!keys.containsKey(key)) return false;
    return keys[key].me;
  }

  /// 获取一个空的 key，最多只查找到值为 [max] 的 key（包含 [max]）
  String getEmptyKey(int max) {
    if (keys == null) return "0";
    for (var i = 0; i <= max; i++) {
      final key = i.toString();
      if (!keys.containsKey(key)) return key;
      if (keys[key].count == 0) return key;
    }
    return null;
  }

  String hasAnyKeyMySelf() {
    if (keys == null) return null;
    for (final entry in keys.entries) {
      if (entry.value.me) {
        return entry.key;
      }
    }
    return null;
  }

  int getKeyCount(String key) {
    if (keys == null) return 0;
    return keys[key]?.count ?? 0;
  }

  String getKeyUser(String key) {
    if (keys == null) return null;
    return keys[key]?.userId;
  }

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
        "width": width,
        "height": height,
        "data": data,
        "notification": notification,
        "come_from_icon": comeFromIcon,
        "come_from_name": comeFromName,
        "edition": edition,
        "type": "messageCard",
      };

  factory MessageCardEntity.fromJson(Map<String, dynamic> json) =>
      MessageCardEntity(
        width: json["width"] == null ? null : (json["width"] as num).toDouble(),
        height:
            json["height"] == null ? null : (json["height"] as num).toDouble(),
        notification: json["notification"],
        data: json["data"],
        comeFromIcon: json["come_from_icon"],
        comeFromName: json["come_from_name"],
        edition: json["edition"],
      );

  String toNotificationString() => notification ?? '[消息卡片]'.tr;
}

class MessageCardKeyPushEntity extends MessageContentEntity {
  MessageCardKeyPushEntity({
    this.key,
    this.count,
    this.id,
    this.action,
  }) : super(MessageType.messageCardKey);

  final String key;
  final int count;

  /// 被操作消息的 id
  final String id;
  final String action;

  factory MessageCardKeyPushEntity.fromJson(Map<String, dynamic> json) =>
      MessageCardKeyPushEntity(
        key: json["key"],
        count: json["count"],
        id: json["id"],
        action: json["action"],
      );

  @override
  Map<String, dynamic> toJson() => {
        "key": key,
        "count": count,
        "id": id,
        "action": action,
      };
}
