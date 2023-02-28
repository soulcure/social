import 'package:im/core/http_middleware/http.dart';

/// - 禁言相关api
class MuteListApi {
  /// - 添加禁言
  static Future addToMuteList(
    String userId,
    String guildId,
    String cycle,
  ) async {
    final res = await Http.request(
      "/api/Blacklist/AddNoSay",
      data: {
        "forbid_user_id": userId,
        "guild_id": guildId,
        "cycle": cycle,
      },
      showDefaultErrorToast: true,
    );
    return res;
  }

  /// - 移除禁言
  static Future removeFromMuteList(
    String userId,
    String guildId,
  ) async {
    final res = await Http.request(
      "/api/Blacklist/CancelNoSay",
      data: {
        "forbid_user_id": userId,
        "guild_id": guildId,
      },
      showDefaultErrorToast: true,
    );
    return res;
  }

  /// - 获取禁言列表
  /// - lastId: 默认为0，翻页时将接口返回的last_id带上
  static Future getMuteList(String guildId, {String lastId = '0'}) async {
    final res = await Http.request("/api/Blacklist/GetNoSaylist", data: {
      "guild_id": guildId,
      "last_id": lastId,
    });
    return res;
  }

  /// - 获取某人的是否被禁言
  static Future checkIsMuted(
    String userId,
    String guildId,
  ) async {
    final res = await Http.request("/api/Blacklist/CheckNoSay", data: {
      "forbid_user_id": userId,
      "guild_id": guildId,
    });
    return res;
  }
}
