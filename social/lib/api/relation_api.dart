import 'package:im/core/config.dart';
import 'package:im/core/http_middleware/http.dart';
import 'package:im/pages/friend/relation.dart';
import 'package:json_annotation/json_annotation.dart';

class RelationApi {
  static Future<List<String>> getFriendList(
      String userId, String relationId, int size) async {
    final res = await Http.request("/api/relation/list", data: {
      "user_id": userId,
      "relation_id": relationId,
      "size": size,
      'type': 1
    });
    return (res as List).map((v) => v['user_id'] as String).toList();
  }

  static Future<List<FriendApply>> getPendingList(String userId) async {
    final res = await Http.request("/api/relation/pendingList", data: {
      "user_id": userId,
      "page": 1,
      "size": 1000,
    });
    return (res as List)
        .map(
          (v) => FriendApply(
            time: v['timestamp'],
            relationType: RelationTypeExtension.fromInt(v['type']),
            userId: v['user_id'],
          ),
        )
        .toList();
  }

  static Future apply(String userId, String relationId) async {
    final res = await Http.request("/api/relation/apply",
        showDefaultErrorToast: true,
        data: {
          "user_id": userId,
          "relation_id": relationId,
        });
    return res;
  }

  static Future agree(String userId, String relationId) async {
    final res = await Http.request("/api/relation/agree",
        showDefaultErrorToast: true,
        data: {
          "user_id": userId,
          "relation_id": relationId,
        });
    return res;
  }

  static Future refuse(String userId, String relationId) async {
    final res = await Http.request("/api/relation/refuse",
        showDefaultErrorToast: true,
        data: {
          "user_id": userId,
          "relation_id": relationId,
        });
    return res;
  }

  static Future cancel(String userId, String relationId) async {
    final res = await Http.request("/api/relation/cancel",
        showDefaultErrorToast: true,
        data: {
          "user_id": userId,
          "relation_id": relationId,
        });
    return res;
  }

  static Future remove(String userId, String relationId) async {
    final res = await Http.request("/api/relation/remove",
        showDefaultErrorToast: true,
        data: {
          "user_id": userId,
          "relation_id": relationId,
        });
    return res;
  }

  static Future<Map<String, dynamic>> getRelation(
      String userId, String relationId,
      {String guildId}) async {
    final res = await Http.request("/api/user/getRelation", data: {
      "user_id": userId,
      "relation_id": relationId,
      if (guildId != null) "guild_id": guildId,
    });
    return res;
  }

  static Future<List> getCredits(String guildId, List<Map> userCards,
      {String channelId, int channelType, bool onlyTitle = true}) async {
    final res =
        await Http.request("${Config.memberListUri}/api/user/credits", data: {
      "user_cards": userCards,
      "guild_id": guildId,
      if (onlyTitle) "only_title": true,
      if (channelId != null) "channel_id": channelId,
      if (channelType != null) "channel_type": channelType,
    });
    return res;
  }
}

class FriendApply {
  String userId;
  int time;

  @JsonKey(
      fromJson: RelationTypeExtension.fromInt,
      toJson: RelationTypeExtension.toInt)
  RelationType relationType;

  FriendApply({this.userId, this.time, this.relationType});
// toJson() => _$FriendApplyToJson(this);
// static FriendApply fromJson(Map json) => _$FriendApplyFromJson(json);
}
