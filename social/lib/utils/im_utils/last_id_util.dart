import 'dart:collection';

import 'package:flutter/cupertino.dart';
import 'package:im/common/permission/permission.dart';
import 'package:im/common/permission/permission_model.dart';
import 'package:im/common/permission/permission_utils.dart';
import 'package:im/db/db.dart';
import 'package:im/pages/home/model/chat_index_model.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/pages/home/model/text_channel_util.dart';

///LastId 工具类
class LastIdUtil {
  ///获取频道的最后一条消息ID
  static Future<Map<String, String>> getLastMessageIds(
      Iterable<ChatChannel> channelList) async {
    final LinkedHashMap<String, String> ids = LinkedHashMap<String, String>();
    for (final c in channelList) {
      /// Skip fetch unread messages if you don't have permission to view the history
      if (c.type == ChatChannelType.guildText) {
        if (!PermissionUtils.oneOf(PermissionModel.getPermission(c.guildId),
            [Permission.READ_MESSAGE_HISTORY],
            channelId: c.id)) {
          continue;
        }
      }
      // debugPrint('getChat - getLastMessageIds cid:${c.id} cname:${c.name} '
      //     '- ${ids[c.id]} - ${c.type}');
      ids[c.id] = Db.lastMessageIdBox.get(c.id);
      // debugPrint('getChat - 1 getLastMessageIds cid:${c.id} cname:${c.name} '
      //     '- ${ids[c.id]} - ${c.type}');
      // if (hasLastIdInBox) {
      //   ids[c.id] = Db.lastMessageIdBox.get(c.id);
      //
      //   debugPrint("colin LastIdUtil channelId=${c.id}  lastId=${ids[c.id]}");
      //   // debugPrint(
      //   //     'getChat - 1 getLastMessageIds cid:${c.id} cname:${c.name} '
      //   //         '- ${ids[c.id]} - ${c.type}');
      // } else {
      //   debugPrint("colin web not here");
      //   //兼容1.5.0以前的版本: 后续可以去掉这行
      //   ids[c.id] = (await ChatTable.getLastMessageId(c.id))?.toString();
      //   // debugPrint(
      //   //     'getChatHistory - 2 getLastMessageIds cid:${c.id} cname:${c.name} '
      //   //         '- ${ids[c.id]} ${ids[c.id] == null}  - ${c.type}');
      // }
    }
    return ids;
  }

  ///获取并排序 所有服务器的文字频道:
  static List<ChatChannel> getSortGuildChannels() {
    final List<ChatChannel> result = [];
    try {
      //先获取box中的服务器点击记录
      List<TempSortObj> clickGuildIdList;
      if (Db.clickGuildIdBox.isNotEmpty) {
        clickGuildIdList = Db.clickGuildIdBox
            .toMap()
            .map((key, value) {
              return MapEntry(
                  key.toString(), TempSortObj(key.toString(), value));
            })
            .values
            .toList();
        clickGuildIdList.sort((a, b) => b.time.compareTo(a.time));
      }
      //本地服务器数据
      final Iterable<GuildTarget> guildList =
          ChatTargetsModel.instance.chatTargets.whereType<GuildTarget>();
      final LinkedHashMap<String, GuildTarget> guildMap =
          LinkedHashMap<String, GuildTarget>();
      guildList.forEach((g) {
        guildMap[g.id] = g;
      });

      if (clickGuildIdList != null) {
        //按照服务器的点击顺序，添加服务器的频道列表
        clickGuildIdList.forEach((g) {
          final Iterable<ChatChannel> iterable = guildMap[g.guild]
              ?.channels
              ?.where((e) => [
                    ChatChannelType.guildText,
                    ChatChannelType.guildCircleTopic
                  ].contains(e.type));
          if (iterable != null) result.addAll(iterable);
          guildMap.remove(g.guild);
        });
      }
      //添加剩余或所有的频道列表
      final Iterable<ChatChannel> iterable = guildMap.values
          ?.expand((g) => g.channels)
          ?.where((e) => [
                ChatChannelType.guildText,
                ChatChannelType.guildCircleTopic
              ].contains(e.type));
      if (iterable != null) result.addAll(iterable);
      // result.forEach((c) {
      //   debugPrint('getChatHistory - getSortChannel cid:${c.id} cname:${c.name}');
      // });
    } catch (e) {
      debugPrint('getChatHistory -- getSortChannel e:$e');
    }
    return result;
  }

  ///判断: 频道是否有 lastMessageId
  static bool hasLastMessageId(String channelId) {
    if (TextChannelUtil.instance.lastMessageIds != null) {
      String lastId;
      if (TextChannelUtil.instance.lastMessageIds.item2 != null) {
        lastId = TextChannelUtil.instance.lastMessageIds.item2[channelId];
        if (lastId != null) return true;
      }
      if (TextChannelUtil.instance.lastMessageIds.item1 != null) {
        lastId = TextChannelUtil.instance.lastMessageIds.item1[channelId];
        if (lastId != null) return true;
      }
    }
    return false;
  }

  ///判断: 频道是否有 lastMessageId
  static void removeLastMessageId(String channelId) {
    if (TextChannelUtil.instance.lastMessageIds != null) {
      TextChannelUtil.instance.lastMessageIds.item2.remove(channelId);
    }
  }

  ///频道的lastMessageId 置空 (清除缓存时使用)
  static void clearLastMessageIds() {
    TextChannelUtil.instance.lastMessageIds?.item1?.keys?.forEach((key) {
      TextChannelUtil.instance.lastMessageIds.item1[key] = null;
    });
    TextChannelUtil.instance.lastMessageIds?.item2?.keys?.forEach((key) {
      TextChannelUtil.instance.lastMessageIds.item2[key] = null;
    });
  }
}

class TempSortObj {
  String guild;
  DateTime time;

  TempSortObj(this.guild, this.time);
}
