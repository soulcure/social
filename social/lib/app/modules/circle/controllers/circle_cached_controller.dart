import 'dart:convert';

import 'package:im/db/db.dart';

class CircleCachedController {
  static Future<void> putCircleInfo(String guildId, Map data) async {
    await Db.circleInfoCachedBox.put(guildId, json.encode(data));
  }

  static Map<String, dynamic> getCircleInfo(String guildId) {
    final data = Db.circleInfoCachedBox.get(guildId);
    if (data != null) return json.decode(data);
    return null;
  }

  static Future<void> putCirclePost(
      String guildId, String topicId, Map data) async {
    await Db.circlePostCachedBox.put('${guildId}_$topicId', json.encode(data));
  }

  static Map<String, dynamic> getCirclePost(String guildId, String topicId) {
    final data = Db.circlePostCachedBox.get('${guildId}_$topicId');
    if (data != null) return json.decode(data);
    return null;
  }
}
