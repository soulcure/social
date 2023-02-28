import 'dart:collection';

import 'package:im/core/http_middleware/http.dart';
import 'package:im/pages/home/model/chat_target_model.dart';

class ChannelApi {
  static Future<LinkedHashMap> getChannels(String guildId, int userId) async {
    final LinkedHashMap<String, dynamic> res =
        await Http.request('/api/channel/get', data: {
      'user_id': userId,
      'guild_id': guildId,
    });
    res.removeWhere((key, value) => key == 'none');
    return res;
  }

  static Future createChannel(String guildId, String userId, String name,
      ChatChannelType type, String parentId,
      {List<Map<String, dynamic>> permissionOverwrites,
      String link,
      bool showDefaultErrorToast = true}) async {
    final res = await Http.request('/api/channel/create',
        showDefaultErrorToast: showDefaultErrorToast,
        data: {
          'user_id': userId,
          'guild_id': guildId,
          'name': name,
          'type': chatChannelTypeToJson(type),
          'parent_id': parentId,
          'permission_overwrites': permissionOverwrites ?? [],
          if (link != null && link.isNotEmpty) 'link': link,
        });
    return res;
  }

  static Future removeChannel(String guildId, String userId, String channelId,
      List<String> channelOrder) async {
    final res = await Http.request('/api/channel/del',
        showDefaultErrorToast: true,
        data: {
          'user_id': userId,
          'guild_id': guildId,
          'channel_id': channelId,
          'channel_lists': channelOrder
        });
    return res;
  }

  static Future removeDirectMessageChannel(String userId, String channelId) {
    return Http.request('/api/dm/del', showDefaultErrorToast: true, data: {
      'user_id': userId,
      'channel_id': channelId,
    });
  }

  static Future createDirectMessageChannel(
    //    String guildId,
    String userId,
    String recipient,
  ) async {
    final res = await Http.request('/api/dm/create', data: {
//      'guild_id': guildId,
      'user_id': userId,
      'recipient_id': recipient,
    });
    return res['channel_id'];
  }

  static Future orderChannel(String guildId, String userId,
      Map<String, String> groupChangedChannel, List<String> positions) async {
    final res = await Http.request('/api/guild/channels',
        showDefaultErrorToast: true,
        data: {
          'user_id': userId,
          'guild_id': guildId,
          'categroup': groupChangedChannel,
          'positions': positions
        });
    return res;
  }

  static Future updateChannel(String userId, String guildId, String channelId,
      {String name,
      String topic,
      String parentId,
      String link,
      int userLimit,
      List<String> channelOrder,
      bool pendingUserAccess}) async {
    final Map<String, dynamic> data = {
      'user_id': userId,
      'guild_id': guildId,
      'channel_id': channelId,
      'parent_id': parentId,
      'name': name,
      'topic': topic,
      'channel_lists': channelOrder,
      'pending_user_access': pendingUserAccess,
      if (userLimit != null) 'user_limit': userLimit,
      if (link?.isNotEmpty ?? false) 'link': link,
    };
    data.removeWhere((key, value) => value == null);
    final res = await Http.request(
      '/api/channel/up',
      data: data,
      showDefaultErrorToast: true,
    );
    return res;
  }
}
