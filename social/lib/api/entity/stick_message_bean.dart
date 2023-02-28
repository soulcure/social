import 'dart:convert';

import 'package:im/pages/home/json/text_chat_json.dart';

class StickMessageBean {
  final String stickId;
  final String stickTime;
  bool isStickRead;
  final MessageEntity message;
  final String stickUserId;

  StickMessageBean(this.stickId, this.stickTime, this.message, this.isStickRead,
      this.stickUserId);

  Map<String, dynamic> toMap() {
    final Map<String, dynamic> map = <String, dynamic>{};
    map["stickId"] = stickId;
    map["stickTime"] = stickTime;
    map["isStickRead"] = isStickRead;
    map["messageId"] = message.messageId;
    map["stickUserId"] = stickUserId;
    return map;
  }

  /// TODO 名为 toJSONString 更合适
  String toJson() {
    return jsonEncode(toMap());
  }
}
