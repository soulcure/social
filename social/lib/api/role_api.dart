import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:im/common/permission/permission.dart';
import 'package:im/core/http_middleware/http.dart';
import 'package:im/pages/guild_setting/role/role.dart';

import 'data_model/user_info.dart';

class RoleApi {
  static Future<List<Role>> getList({
    String guildId,
    String channelId,
    String userId,
    String lastId,
    int limit,
    int size,
    bool showDefaultErrorToast = true,
  }) async {
    final Map<String, dynamic> data = {
      "guild_id": guildId,
      "channel_id": channelId,
      "user_id": userId,
      "last_id": lastId,
      "limit": limit,
      "size": size,
    };
    data.removeWhere((key, value) => value == null);
    final res = await Http.request(
      "/api/role/lists",
      showDefaultErrorToast: showDefaultErrorToast,
      data: data,
    );
    return (res as List).map((e) => Role.fromJson(e)).toList();
  }

  static Future<Role> create({String guildId, String userId}) async {
    final res = await Http.request("/api/role/role",
        showDefaultErrorToast: true,
        data: {
          "guild_id": guildId,
          "user_id": userId,
        });
    return Role.fromJson(res);
  }

  static Future save(String guildId, String userId, String roleId,
      {int permissions,
      int color,
      String name,
      bool mentionable,
      bool hoist}) async {
    final Map<String, dynamic> data = {
      'guild_id': guildId,
      'user_id': userId,
      'role_id': roleId,
      'permissions': permissions,
      'color': color,
      'name': name,
      'mentionable': mentionable,
      'hoist': hoist
    };
    // 不更新的字段不传，不能为null
    data.removeWhere((key, value) => value == null);
    final res = await Http.request("/api/role/save",
        showDefaultErrorToast: true, data: data);
    return res;
  }

  static Future order(
      {String guildId, String userId, List<Map<String, dynamic>> roles}) async {
    final res = await Http.request("/api/role/position",
        showDefaultErrorToast: true,
        data: {
          "guild_id": guildId,
          "user_id": userId,
          "roles": jsonEncode(roles),
        });
    return res;
  }

  static Future delete({String guildId, String userId, String roleId}) async {
    final res = await Http.request("/api/role/delRole",
        showDefaultErrorToast: true,
        data: {
          "guild_id": guildId,
          "user_id": userId,
          "role_id": roleId,
        });
    return res;
  }

  static Future<List<UserInfo>> getMemberList(
      {String guildId,
      String channelId,
      String userId,
      String lastId,
      int limit,
      bool showDefaultErrorToast = false}) async {
    final Map<String, dynamic> data = {
      "guild_id": guildId,
      "channel_id": channelId,
      "user_id": userId,
      "last_id": lastId,
      "limit": limit,
    };
    data.removeWhere((key, value) => value == null);
    final res = await Http.request("/api/role/memberLists",
        showDefaultErrorToast: showDefaultErrorToast, data: data);
    return (res as List)
        .map(
          (e) => UserInfo(
              userId: e['user_id'],
              avatar: e['avatar'],
              username: e['username'],
              nickname: e['name'],
              isBot: e['bot'],
              roles: ((e['roles'] ?? []) as List).cast<String>()),
        )
        .toList();
  }

  static Future updateMemberRole({
    String guildId,
    String userId,
    List<String> roleIds,
    String memberId,
    bool showDefaultErrorToast = true,
    bool isOriginDataReturn = false,
  }) async {
    final res = await Http.request("/api/role/memberRole",
        showDefaultErrorToast: showDefaultErrorToast,
        isOriginDataReturn: isOriginDataReturn,
        data: {
          "guild_id": guildId,
          "user_id": userId,
          "roles": jsonEncode(roleIds),
          "member_id": memberId,
        });
    return res;
  }

  static Future<List<PermissionOverwrite>> getOverwriteList(
      {String guildId, String userId, String channelId}) async {
    final res = await Http.request("/api/channelPermiss/lists",
        showDefaultErrorToast: true,
        data: {
          "guild_id": guildId,
          "user_id": userId,
          "channel_id": channelId,
        });
    return (res as List)
        .map((e) => PermissionOverwrite(
            id: e['id'].toString(),
            channelId: e['channel_id'].toString(),
            guildId: e['guild_id']?.toString() ?? "0",
            actionType: e['action_type'],
            allows: e['allows'],
            deny: e['deny'],
            name: e['name']))
        .toList();
  }

  // 新增和编辑权限覆盖
  static Future updateOverwrite(
      {String guildId,
      String channelId,
      String userId,
      String id,
      int allows,
      int deny,
      String actionType}) async {
    final res = await Http.request("/api/channelPermiss/permission",
        showDefaultErrorToast: true,
        data: {
          "guild_id": guildId,
          "channel_id": channelId,
          "user_id": userId,
          "id": id,
          "allows": allows,
          "deny": deny,
          "action_type": actionType,
        });
    return res;
  }

  static Future updateOverwrites(
      {@required String guildId,
      @required String channelId,
      @required List<Map> permissionOverwrites}) async {
    final res = await Http.request("/api/channelPermiss/batch",
        showDefaultErrorToast: true,
        data: {
          "guild_id": guildId,
          "channel_id": channelId,
          "permission_overwrites": permissionOverwrites
        });
    return res;
  }

  static Future deleteOverwrite({
    String guildId,
    String channelId,
    String userId,
    String id,
  }) async {
    final res = await Http.request("/api/channelPermiss/del",
        showDefaultErrorToast: true,
        data: {
          "guild_id": guildId,
          "channel_id": channelId,
          "user_id": userId,
          "id": id,
        });
    return res;
  }
}
