import 'package:dio/dio.dart';
import 'package:im/core/http_middleware/http.dart';

import 'entity/topic_avatar.dart';

class TopicAvatarApi {
  static const String topicAvatarUrl = '/api/message/quoteTotal';

  static Future<TopicAvatar> getAvatarData(String messageId, String channelId,
      {CancelToken token}) async {
    Map<String, dynamic> res;
    try {
      res = await Http.request(topicAvatarUrl,
          data: {'message_id': messageId, 'channel_id': channelId, 'user': 1},
          cancelToken: token);
    } catch (e) {
      res = null;
    }
    if (res == null) return null;
    return TopicAvatar.fromMap(res);
  }
}
