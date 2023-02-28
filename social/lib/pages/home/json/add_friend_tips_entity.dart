import 'dart:convert';

import 'package:get/get.dart';
import 'package:im/global.dart';
import 'package:im/pages/home/json/text_chat_json.dart';

class AddFriendTipsEntity extends MessageContentEntity {
  final Map content;

  AddFriendTipsEntity({
    this.content,
  }) : super(MessageType.friend);

  Map<String, dynamic> toMap() {
    return {
      'type': typeInString,
      'content': jsonEncode(content),
    };
  }

  //发起添加好友请求的userId
  String get apply => content == null ? null : content['apply'];

  //通过好友请求的userId
  String get agree => content == null ? null : content['agree'];

  //获取对方的userId
  String getOtherUserId() {
    if (apply == Global.user.id) return agree;
    return apply;
  }

  factory AddFriendTipsEntity.fromJson(Map<String, dynamic> map) {
    final String content = map['content'];
    return AddFriendTipsEntity(
      content: jsonDecode(content),
    );
  }

  @override
  Map<String, dynamic> toJson() => toMap();

  @override
  String toString() {
    return 'AddFriendTipsEntity{content: $content}';
  }

  String toNotificationString() {
    return '你和对方已经成为好友,现在可以开始聊天了'.tr;
  }
}
