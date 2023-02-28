import 'package:im/app/modules/direct_message/controllers/direct_message_controller.dart';
import 'package:im/app/modules/home/controllers/home_scaffold_controller.dart';
import 'package:im/common/permission/permission.dart';
import 'package:im/db/db.dart';
import 'package:im/global.dart';

import '../chat_index_model.dart';
import '../chat_target_model.dart';

enum listDisplay { invisible, visible }

// ignore: type_annotate_public_apis
void onChannelStatus(data) {
  final method = data["method"];
  final guildId = data["guild_id"];
  final channelId = data["channel_id"];
  final ct = ChatTargetsModel.instance.getChatTarget(guildId) as GuildTarget;

  switch (method) {
    case "create":
    case "createPrivate":
      final type = data["type"] as int;
      final name = data["name"] as String;
      final link = data["link"] as String;
      final parentId = data["parent_id"] as String;
      final permissionOverwrites = data['permission_overwrites'] as List;
      // 如果有overwrite，则更新
      final overwrites = permissionOverwrites?.map((e) {
        return PermissionOverwrite.fromJson(e);
      })?.toList();

      /// 如果是自己创建的频道，不需要再执行服务器的推送逻辑
      if (ct.channelOrder.contains(channelId)) return;

      final channel = ChatChannel(
          id: channelId,
          guildId: guildId,
          name: name,
          type: chatChannelTypeFromJson(type),
          link: link,
          parentId: parentId);

      ct
        ..channelOrder.add(channelId)
        ..addChannel(
          channel,
          initPermissions: overwrites,
          notify: true,
        );
      ct.sortChannels();
      Db.channelBox.put(channelId, channel);

      break;
    case "circle_update":
      _updateCircleChannel(ct, channelId, data);
      break;
    case "update":
      final int type = int.tryParse(data["type"].toString());
      if (type == ChatChannelType.group_dm.index) {
        //更新部落名称
        _updateGroupChannel(channelId, data);
      } else {
        //更新服务台频道名称
        _updateChannel(ct, channelId, data);
      }
      break;
    case "delete":

      /// 退出服务器后，如果其他用户删除了频道，这里也会收到推送，但是这个时候 ct = null
      ct?.removeChannelById(channelId,
          operateId: data['operate_id'], fromWs: true);
      Db.channelBox.delete(channelId);
      break;
    case "positions":
      ChatTargetsModel.instance.onUpdateChannelsPosition(guildId,
          (data['positions'] as List).cast<String>(), data['categroup']);
      break;
  }
}

// ignore: type_annotate_public_apis
void onChannelNotice(data) {
  final method = data["method"];
  final guildId = data["guild_id"];
  final channelId = data["channel_id"];
  final String userId = data["user_id"];
  final int type = data["type"];
  final String name = data["name"];
  final String icon = data["icon"];
  if (userId == null) return;

  switch (method) {
    case "userJoin":

      ///部落群聊新用户加入
      if (userId == Global.user.id) {
        DirectMessageController.to
            .joinGroup(guildId, channelId, type, name, icon);
      }
      break;
    case "userQuit":

      ///部落群聊用户退出
      if (userId == Global.user.id) {
        DirectMessageController.to.removeChannelById(channelId);
      }
      break;
  }
}

void _updateChannel(GuildTarget ct, String channelId, data) {
  final ChatChannel channel = ct.channels
      .firstWhere((element) => element.id == channelId, orElse: () => null);
  if (channel == null) return;

  channel
    ..name = data['name']
    ..topic = data['topic']
    ..parentId = data['parent_id']
    ..link = data['link']
    ..userLimit = data['user_limit'] ?? channel.userLimit
    ..pendingUserAccess =
        data['pending_user_access'] ?? channel.pendingUserAccess ?? false;
  if (channel.isInBox) {
    channel.save();
  }
  ct
    ..channelOrder =
        ((data['positions'] ?? ct.channelOrder) as List).cast<String>()
    ..sortChannels();
  try {
    final selectedChatTarget =
        ChatTargetsModel.instance.selectedChatTarget as GuildTarget;
    if (GlobalState.selectedChannel?.value?.id == channel.id) {
      GlobalState.selectedChannel.value = null;
      HomeScaffoldController.to.gotoWindow(0);
    }

    selectedChatTarget.traverseChannelsTask();
    // ignore: invalid_use_of_visible_for_testing_member, invalid_use_of_protected_member
    selectedChatTarget.notifyListeners();
  } catch (_) {}
}

void _updateGroupChannel(String channelId, data) {
  final ChatChannel channel = Db.channelBox.get(channelId);
  if (channel == null) return;
  channel
    ..name = data['name']
    ..icon = data['icon']
    ..id = channelId
    ..guildId = '0'
    ..type = ChatChannelType.group_dm
    ..pendingUserAccess = false;
  if (channel.isInBox) {
    channel.save();
  }
}

void _updateCircleChannel(GuildTarget ct, String channelId, data) {
  final ChatChannel channel = ct.channels
      .firstWhere((element) => element.id == channelId, orElse: () => null);
  if (data['list_display'] == listDisplay.visible.index && channel == null) {
    // 添加频道
    final channel = ChatChannel(
        id: channelId,
        guildId: data['guild_id'],
        name: data['name'],
        type: ChatChannelType.guildCircleTopic,
        pendingUserAccess: false);

    ct
      ..channelOrder.insert(0, channelId)
      ..addChannel(
        channel,
        notify: true,
      );
    Db.channelBox.put(channelId, channel);
  } else if (data['list_display'] == listDisplay.invisible.index &&
      channel != null) {
    // 删除频道
    ct.removeChannel(channel, fromWs: true);
  } else {
    //update
    ///更新圈子topic频道，只更新name，其他字段不用更新
    if (channel != null) {
      channel.name = data['name'] ?? channel.name;
      Db.channelBox.put(channelId, channel);
    }
  }
}

// ignore: type_annotate_public_apis
void onVoiceStateUpdate(data) {
  final d = data["data"];
  final guildId = data["guild_id"];
  final channelId = data["channel_id"];
  final ct = ChatTargetsModel.instance.getChatTarget(guildId) as GuildTarget;
  final ChatChannel channel = ct.channels
      .firstWhere((element) => element.id == channelId, orElse: () => null);
  if (channel == null) return;
  if (d != null) {
    channel.active = d["active"] ?? channel.active;
    if (channel.isInBox) {
      channel.save();
    }
  }
}
