import 'dart:convert';

import 'package:im/api/data_model/user_info.dart';
import 'package:im/api/entity/bot_info.dart';
import 'package:im/core/http_middleware/http.dart';
import 'package:im/pages/home/json/text_chat_json.dart';
import 'package:im/pages/home/model/chat_target_model.dart';

class BotApi {
  static Future<Map> getArticles(Map params) async {
    final res = await Http.request('/api/bot/sendInlineQuery',
        showDefaultErrorToast: true, data: params);
    return res;
  }

  static Future<void> invokeRemoteCallback({
    String userId,
    String data,
    MessageEntity message,
  }) async {
    await Http.request("/api/bot/sendCallbackQuery",
        showDefaultErrorToast: true,
        data: {
          "user_id": userId,
          "data": data,
          if (message != null) "message": message.toJson(),
        });
  }

  static Future<List<BotCommandItem>> getCommands(String botId) async {
    final res = await Http.request("/api/bot/getBot", data: {"bot_id": botId});
    if (res == null) return null;

    return (res["commands"] as List)
        .map((command) => BotCommandItem.fromJson(command))
        .toList(growable: false);
  }

  static Future<List<BotInfo>> getBots(
      {int page, int pageSize, String guildId}) async {
    final List res = await Http.request("/api/bot/discoveryBots", data: {
      "guild_id": guildId,
      "keyword": "",
      "page_start": page,
      "page_size": pageSize,
    });
    return List<BotInfo>.from(res.map((e) => BotInfo.fromJson(e)));
  }

  static Future<BotInfo> getBot(String botId) async {
    final res = await Http.request("/api/bot/getBot", data: {"bot_id": botId});
    return BotInfo.fromJson(res);
  }

  static Future joinGuild(
    String guildId,
    String botId,
    int permissions,
    String color,
  ) async {
    final res = await Http.request(
      "/api/robot/joinGuild",
      data: {
        'guild_id': guildId,
        'bot_id': botId,
        'permissions': permissions,
        'color': color,
      },
      showDefaultErrorToast: true,
    );
    return res;
  }

  // 频道添加或删除指令
  static Future channelSetCommands(
    List<String> channelIds,
    String guildId,
    String botId,
    CommandOp op, {
    List<String> command,
  }) {
    final opStr = op == CommandOp.add ? 'add' : 'del';
    final res = Http.request('/api/robot/channelSet',
        data: {
          'channel_id': channelIds,
          'guild_id': guildId,
          'bot_id': botId,
          'command': json.encode(command),
          'operation': opStr,
        },
        showDefaultErrorToast: true);
    return res;
  }

  static Future<List<Map<String, String>>> getChannelCommands(
    String channelId,
  ) async {
    final res = await Http.request(
      '/api/robot/getChannelBot',
      data: {"channel_id": channelId},
    );
    return ChatChannel.parseBotSetting(res);
  }

  static Future<Map> getGuildChannelCmds(String guildId) async {
    try {
      final res = await Http.request(
        '/api/robot/getGuildBot',
        data: {"guild_id": guildId},
      );
      return res;
    } catch (e) {
      return {};
    }
  }

  static Future<Map> botReceive(
      String guildId, String botId, int action) async {
    final res = await Http.request(
      '/api/robot/botReceive',
      data: {"guild_id": guildId, "bot_id": botId, "action": action},
    );
    return res;
  }

  static Future<void> setBotGuildNickname(
      String guildId, String botId, String nick) async {
    final res = await Http.request(
      '/api/robot/setGuildNick',
      showDefaultErrorToast: true,
      data: {"guild_id": guildId, "bot_id": botId, "nickname": nick},
    );
    return res;
  }

  static Future<List<UserInfo>> getAddedBots(
      {String guildId, int limit, String after}) async {
    final res = await Http.request(
      '/api/search/qbot',
      data: {"guild_id": guildId, "limit": limit, "after": after},
    );
    return List<Map>.from(res['lists'] ?? [])
        .map((e) => UserInfo.fromJson(e))
        .toList();
  }

  // 多频道设置指令
  static Future multiChannelSetCommands(
    Map<String, CommandOp> channelIds,
    String guildId,
    String botId, {
    String command,
  }) {
    String _getCommandOpStr(CommandOp op) {
      if (op == CommandOp.add) {
        return 'add';
      } else if (op == CommandOp.del) {
        return 'del';
      } else
        return '';
    }

    final channelIdsMap =
        channelIds.map((key, value) => MapEntry(key, _getCommandOpStr(value)));
    final res = Http.request('/api/robot/multiChannelSet',
        data: {
          'channel_id': channelIdsMap,
          'guild_id': guildId,
          'bot_id': botId,
          'command': [command],
        },
        showDefaultErrorToast: true);
    return res;
  }
}

enum CommandOp { add, del }
