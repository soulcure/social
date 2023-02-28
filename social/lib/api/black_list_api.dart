import 'package:im/core/http_middleware/http.dart';

class BlackListApi {
  static Future addToBlackList(String userId, String blackId) async {
    final res = await Http.request("/api/blacklist/addToBlacklist", data: {
      "user_id": userId,
      "black_id": blackId,
    });
    return res;
  }

  static Future removeFromBlackList(String userId, String relationId) async {
    final res = await Http.request("/api/blacklist/removeFromBlacklist", data: {
      "user_id": userId,
      "black_id": relationId,
    });
    return res;
  }

  static Future getBlackList(String userId) async {
    final res = await Http.request("/api/blacklist/getBlacklist", data: {
      "user_id": userId,
    });
    return res;
  }

  static Future getBlackIdInfo(String userId, String blackId) async {
    final res = await Http.request("/api/blacklist/getBlackId", data: {
      "user_id": userId,
      "black_id": blackId,
    });
    return res;
  }
}
