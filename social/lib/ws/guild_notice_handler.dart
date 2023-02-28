import 'package:get/get.dart';
import 'package:im/api/data_model/user_info.dart';
import 'package:im/api/entity/role_bean.dart';
import 'package:im/api/entity/sticker_bean.dart';
import 'package:im/common/extension/future_extension.dart';
import 'package:im/common/permission/permission_model.dart';
import 'package:im/db/db.dart';
import 'package:im/hybrid/webrtc/room_manager.dart';
import 'package:im/pages/guild_setting/guild/quit_guild.dart';
import 'package:im/pages/guild_setting/member/model/member_manage_model.dart';
import 'package:im/pages/home/json/text_chat_json.dart';
import 'package:im/pages/home/model/chat_index_model.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/pages/home/model/text_channel_event.dart';
import 'package:im/pages/member_list/model/member_list_model.dart';
import 'package:im/utils/show_confirm_dialog.dart';
import 'package:im/utils/sticker_util.dart';
import 'package:im/utils/utils.dart';
import 'package:im/ws/ws.dart';
import 'package:pedantic/pedantic.dart';

import '../global.dart';

// ignore: avoid_annotating_with_dynamic
void guildNoticeHandler(dynamic data) {
  final guildId = data["guild_id"] as String;
  final userId = data["user_id"] as String;
  final operateId = data['operate_id'] as String;
  switch (data["method"]) {
    case MessageAction.userQuit:
      if (userId == Global.user.id) {
        quitGuild(ChatTargetsModel.instance.getChatTarget(guildId));
      } else {
        _removeUser(guildId, userId, operateId);
        // 当用户有退出时,移除相关服务器权限数据
        PermissionModel.onRemoveUser(guildId, userId);
      }
      break;
    case MessageAction.userRem:
      _removeUser(guildId, userId, operateId);
      if (userId == Global.user.id) {
        // 发送被移出服务器事件，直播模块需要接受此事件
        // 只有被移出用户收到此事件通知
        Ws.instance.fire(WsMessage(MessageAction.kickOutOfGuild, null));
      } else {
        Ws.instance.fire(
            WsMessage(MessageAction.userRem, UserRemoveEvent(guildId, userId)));
      }
      break;
    case MessageAction.joinSet:
      _onJoinSet(
          guildId, data['system_channel_id'], data['system_channel_flags']);
      break;
    case MessageAction.upEmoji:
      final emo = data['emojis'];
      StickerUtil.instance
          .setStickerById(guildId, StickerBean.fromMapList(emo));
      break;
    case MessageAction.update:
      _onGuildInfoChanged(data ?? {});
      break;
    case MessageAction.userJoin:
      Ws.instance.fire(
          WsMessage(MessageAction.userJoin, UserJoinEvent(guildId, userId)));
      break;
  }
}

void _onGuildInfoChanged(Map data) {
  final name = data['name'];
  // final des = data['description'];
  final banner = data['banner'];
  final icon = data['icon'];
  final guildId = data['guild_id'];
  final receiveBots = List<String>.from(data['bot_receive'] ?? []);
  final isWelcomeOn = data['welcome_switch'] == null
      ? null
      : safeBoolFromJson(data['welcome_switch'], false);
  final welcome = data['welcome'] == null
      ? null
      : safeStringListFromJson(data['welcome'], <String>[]);
  final chatTarget = ChatTargetsModel.instance.getChatTarget(guildId);
  if (chatTarget != null && chatTarget is GuildTarget) {
    chatTarget.updateInfo(
      name: name,
      banner: banner,
      icon: icon,
      isWelcomeOn: isWelcomeOn,
      welcome: welcome,
      receiveBots: receiveBots,
    );
  }
}

void _onJoinSet(
    String guildId, String systemChannelId, int systemChannelFlags) {
  final t = ChatTargetsModel.instance.getChatTarget(guildId) as GuildTarget;
  if (t == null) return;
  t.update(
      systemChannelId: systemChannelId, systemChannelFlags: systemChannelFlags);
}

Future<void> _removeUser(
    String guildId, String userId, String operateId) async {
  MemberManageModel()?.removeMember(userId);
  final gt = ChatTargetsModel.instance.getChatTarget(guildId);
  if (gt == null) return;
  if (Global.user.id == userId) {
    final String showName = (await UserInfo.get(operateId))?.showName();
    GlobalState.updateBadge();
    if (gt.id == ChatTargetsModel.instance.selectedChatTarget?.id) {
      unawaited(RoomManager.close());
      quitGuild(gt);
    } else {
      quitGuild(gt, backHomeAndSelectDefaultChatTarget: false);
    }
    showConfirmDialog(
        title: '通知'.tr,
        showCancelButton: false,
        confirmText: '我知道了'.tr,
        content: '你已被 %s 的管理员 %s 移出该服务器，可通过新的邀请链接再次加入。'
            .trArgs([gt.name, showName])).unawaited;
  }
  final target = ChatTargetsModel.instance.selectedChatTarget;
  if (target is GuildTarget && target.id == guildId) {
    await MemberListModel.instance.remove(userId);
    MemberManageModel()?.removeMember(userId);
  }
  // 用户退出服务器清空角色
  RoleBean.update(userId, guildId, null);
  // 移除用户的服务器昵称
  final user = Db.userInfoBox.get(userId);
  if (user != null) {
    user.removeGuildNickName(guildId);
  }
}
