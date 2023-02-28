import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/api/bot_api.dart';
import 'package:im/loggers.dart';
import 'package:im/pages/bot_commands/model/displayed_cmds_model.dart';
import 'package:im/pages/home/model/chat_index_model.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:pedantic/pedantic.dart';

/// 缓存所有的频道快捷指令
class ChannelCmdsModel {
  static ChannelCmdsModel get instance => _getInstance();
  static ChannelCmdsModel _instance;

  // ignore: prefer_constructors_over_static_methods
  static ChannelCmdsModel _getInstance() {
    return _instance ??= ChannelCmdsModel._();
  }

  ChannelCmdsModel._();

  /// 获取指定频道的快捷指令
  List<Map<String, String>> getChannelCommands(
    String channelId,
    String guildId,
  ) {
    final channel = _getChannel(_getChatTarget(guildId), channelId);
    return channel?.botSettingList;
  }

  /// 添加指定频道，指定机器人的快捷指令
  /// @param channelId: 指定的频道id
  /// @param guildId: 服务器id
  /// @param robotId: 指定的机器人id
  /// @param commands: 要添加或删除的指令（当前机器人的所有指令）
  Future setChannelCommands(
    List<String> channelIds,
    String guildId,
    String robotId,
    List<String> commands,
  ) async {
    await BotApi.channelSetCommands(
      channelIds,
      guildId,
      robotId,
      CommandOp.add,
      command: commands,
    );
    final chatTarget = _getChatTarget(guildId);
    for (final cid in channelIds) {
      final channel = _getChannel(chatTarget, cid);
      final botSettingList = channel?.botSettingList;
      // 添加新增的命令
      commands.forEach((c) {
        final isContain = botSettingList.firstWhereOrNull((element) {
              final kv = element.entries.first;
              return kv.key == robotId && kv.value == c;
            }) !=
            null;
        if (!isContain) botSettingList.add({robotId: c});
      });
      // 删除移除的命令
      for (int i = 0; i < botSettingList.length; i++) {
        final c = botSettingList[i];
        final kv = c.entries.first;
        if (kv.key != robotId) continue;
        final isNotContain = commands.firstWhereOrNull((element) {
              return kv.value == element;
            }) ==
            null;
        if (isNotContain) botSettingList.remove(c);
      }
      await channel.save();
      _rebuildSelectedChannel(chatTarget, cid);
    }
  }

  /// 添加指定频道，指定机器人的快捷指令
  /// @param channelId: 指定的频道id
  /// @param guildId: 服务器id
  /// @param robotId: 指定的机器人id
  /// @param commands: 要添加的指令
  Future multiSetChannelCommands(
    Map<String, CommandOp> channelIds,
    String guildId,
    String robotId,
    String command,
  ) async {
    await BotApi.multiChannelSetCommands(
      channelIds,
      guildId,
      robotId,
      command: command,
    );
    final chatTarget = _getChatTarget(guildId);
    for (final c in channelIds.entries) {
      final channel = _getChannel(chatTarget, c.key);
      channel?.botSettingList ??= [];
      // channel.botSettingList[robotId] ??= [];
      if (c.value == CommandOp.add) {
        channel.botSettingList.add({robotId: command});
      } else if (c.value == CommandOp.del) {
        channel.botSettingList.removeWhere((element) {
          final kv = element.entries.first;
          return kv.key == robotId && kv.value == command;
        });
      }
      await channel.save();
      _rebuildSelectedChannel(chatTarget, channel.id);
    }
  }

  /// 移除指定频道，指定机器人的快捷指令
  /// @param channelId: 指定的频道id
  /// @param guildId: 服务器id
  /// @param robotId: 指定的机器人id
  Future removeChannelCommands(
    String channelId,
    String guildId,
    String robotId,
  ) async {
    try {
      await BotApi.channelSetCommands(
        [channelId],
        guildId,
        robotId,
        CommandOp.del,
      );
    } catch (e, s) {
      print("$e\n$s");
    }
    final chatTarget = _getChatTarget(guildId);
    final channel = _getChannel(chatTarget, channelId);
    // 修改本地数据
    channel?.botSettingList?.removeWhere((element) {
      final kv = element.entries.first;
      return kv.key == robotId;
    });
    // 保存到数据库
    await channel?.save();
    _rebuildSelectedChannel(chatTarget, channelId);
  }

  /// 更新本地缓存
  Future updateLocal({
    @required String channelId,
    @required List<Map<String, String>> cmds,
    String guildId,
    BaseChatTarget chatTarget,
  }) async {
    if (chatTarget == null && guildId != null) {
      chatTarget = _getChatTarget(guildId);
    }
    if (chatTarget == null) {
      print(
          "Invalid params, ChannelCmdsModel updateLocal need to pass guildId or chatTarget");
      return;
    }
    final channel = _getChannel(chatTarget, channelId);
    // 更新快捷指令
    channel?.botSettingList = cmds;
    // 保存到数据库
    await channel?.save();
    _rebuildSelectedChannel(chatTarget, channelId);
  }

  /// 更新服务器下的所有频道快捷指令
  void updateGuildChannelCmds(String guildId) {
    BotApi.getGuildChannelCmds(guildId).then((res) {
      for (final channelId in res.keys) {
        final botSetting = ChatChannel.parseBotSetting(res[channelId]);
        final chatTarget = _getChatTarget(guildId);
        unawaited(updateLocal(
          chatTarget: chatTarget,
          cmds: botSetting,
          channelId: channelId,
        ));
      }
    }).catchError((e, s) {
      logger.info('update Guild Channel Cmds error', e, s);
    });
  }

  BaseChatTarget _getChatTarget(String guildId) {
    return ChatTargetsModel.instance.getChatTarget(guildId);
  }

  // 获取本地频道数据
  ChatChannel _getChannel(BaseChatTarget chatTarget, String channelId) {
    return chatTarget?.getChannel(channelId);
  }

  // 刷新当前选中频道
  void _rebuildSelectedChannel(BaseChatTarget chatTarget, String channelId) {
    if (Get.isRegistered<DisplayedCmdsController>(tag: channelId)) {
      final controller = Get.find<DisplayedCmdsController>(tag: channelId);
      controller.resetCommands();
    }
  }

  // 依次删除当前服务器下所有频道中该机器人的快捷指令
  Future removeAllChannelCmds({String robotId, String guildId}) async {
    final guild = _getChatTarget(guildId) as GuildTarget;
    final channels = guild?.channels ?? [];
    final channelIds = <String>{};
    final commands = <String>{};
    for (final c in channels) {
      for (final s in c.botSettingList) {
        final kvs = s.entries;
        if (kvs.isEmpty) continue;
        if (kvs.first.key == robotId) {
          channelIds.add(c.id);
          commands.add(kvs.first.value);
        }
      }
    }
    if (channelIds.isEmpty || commands.isEmpty) return;
    try {
      await BotApi.channelSetCommands(
        channelIds.toList(),
        guildId,
        robotId,
        CommandOp.del,
        command: commands.toList(),
      );

      for (final c in channels) {
        if (!channelIds.contains(c.id)) continue;
        c.botSettingList?.removeWhere((element) {
          final kv = element.entries.first;
          return kv.key == robotId;
        });
        _rebuildSelectedChannel(guild, c.id);
        // 保存到数据库
        await c.save();
      }
    } catch (e, s) {
      logger.severe("removeAllChannelCmds", e, s);
    }
  }
}
