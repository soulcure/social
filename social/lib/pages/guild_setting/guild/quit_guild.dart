import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:im/api/entity/user_config.dart';
import 'package:im/app/controllers/audio_room_controller.dart';
import 'package:im/app/modules/home/controllers/home_scaffold_controller.dart';
import 'package:im/common/extension/string_extension.dart';
import 'package:im/common/permission/permission_model.dart';
import 'package:im/common/permission/permission_utils.dart';
import 'package:im/db/chat_db.dart';
import 'package:im/db/db.dart';
import 'package:im/db/guild_table.dart';
import 'package:im/pages/home/model/chat_index_model.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/pages/home/model/in_memory_db.dart';
import 'package:im/pages/home/model/live_status_model.dart';
import 'package:im/pages/home/model/text_channel_controller.dart';
import 'package:im/pages/home/view/tab_bar.dart';
import 'package:im/utils/im_utils/last_id_util.dart';
import 'package:im/widgets/segment_list/segment_member_list_service.dart';
import 'package:im/widgets/segment_list/segment_member_list_view_model.dart';
import 'package:pedantic/pedantic.dart';
import 'package:tuple/tuple.dart';

import '../../../routes.dart';
import '../../home/model/live_status_model.dart';

Future<void> _cleanGuild(GuildTarget guild) async {
  guild.channels.forEach((element) {
    InMemoryDb.remove(element.id);

    ///fix 退出服务台再进去服务台，_remoteSynchronized=false,导致无法设置未读计数
    Db.lastMessageIdBox.delete(element.id);
  });
  await ChatTable.batchClearChatHistory(
      null, guild?.channels?.map((e) => e.id) ?? []);
}

void quitGuild(GuildTarget guild,
    {bool backHomeAndSelectDefaultChatTarget = true}) {
  //  清除hash值
  unawaited(Db.userConfigBox.delete(UserConfig.myGuild2Hash));
  AudioRoomController.onQuitGuild(guild.id);
  PermissionModel.removePermission(guild.id);
  Db.guildSelectedChannelBox.delete(guild.id);
  Db.guildTopicSortCategoryBox.delete(guild.id);
  GuildTable.remove(guild.id);

  /// 退出服务器时清除调用过「获取直播红点接口」的标志，当app未关闭且再次加入时可再次获取直播状态
  // LiveStatusManager.instance.netPullStatusCache.remove(guild.id);
  LiveStatusManager.instance.removeNotifier(guild.id);
  if (guild.channels != null && guild.channels.isNotEmpty) {
    //清除频道的lastMessageId
    guild.channels.forEach((c) {
      LastIdUtil.removeLastMessageId(c.id);
      Get.delete<TextChannelController>(tag: c.id);

      ///退出服务台，删除box相关数据
      Db.deleteChannelImBox(c.id);
    });
  }

  // showToast(isDissolve ? "服务器「${guild.name}」已解散" : "已退出服务器「%s」".trArgs([guild.name]),
  //     duration: const Duration(seconds: 3));

  ///修复：只有一个服务器，主动或被动退出后报空
  int length = ChatTargetsModel.instance.chatTargets?.length ?? 0;
  debugPrint('getChat chatTargets.length - $length');
  if (backHomeAndSelectDefaultChatTarget) {
    Routes.backHome();
    HomeScaffoldController.to.gotoWindow(0);
    if (length > 0) {
      final target =
          ChatTargetsModel.instance.chatTargets?.first?.id != guild.id
              ? ChatTargetsModel.instance.chatTargets?.first
              : (length > 2 ? ChatTargetsModel.instance.chatTargets[1] : null);
      ChatTargetsModel.instance.selectChatTarget(target);
    }
  }
  ChatTargetsModel.instance.removeChatTarget(guild);

  // 清除成员列表缓存
  final List<Tuple2<String, String>> delList =
      SegmentMemberListService.to.cleanDataModelCache(guildId: guild.id);
  // 删除viewModel
  delList.forEach((e) {
    final tag = "${e.item1}-${e.item2}";
    Get.delete<SegmentMemberListViewModel>(tag: tag);
    final String saveKey = "${e.item1}-${e.item2}-0";
    Db.segmentMemberListBox.delete(saveKey);
  });

  UserConfig.removeRestrictedGuilds(guild.id);
  unawaited(_cleanGuild(guild));

  length = ChatTargetsModel.instance.chatTargets?.length ?? 0;
  debugPrint('getChat chatTargets.length --- $length');
  if (length == 0) {
    ChatTargetsModel.instance.selectChatTarget(null);
  }
  // SegmentMemberListModel.cleanCache(guildId: guild.id);
}

/// 跳转到已加入过的服务器
Future gotoJoinedGuild({@required String guildId, String channelId}) async {
  /// 已加入
  Routes.backHome();
  if (HomeTabBar.currentIndex != 0) {
    await Future.delayed(const Duration(milliseconds: 200));
    HomeTabBar.gotoIndex(0);
  }
  final gp = PermissionModel.getPermission(guildId);
  final isVisible = PermissionUtils.isChannelVisible(gp, channelId);
  final specificChannel = channelId.hasValue && channelId != "0";
  if (!isVisible && specificChannel) {
    unawaited(ChatTargetsModel.instance.selectChatTargetById(
      guildId,
      channelId: "",
    ));
  } else {
    final alreadyEnteredGuild =
        guildId == ChatTargetsModel.instance.selectedChatTarget.id;

    /// 如果没有指定的频道，需要回到服务器列表
    if (!specificChannel && HomeScaffoldController.to.windowIndex.value != 0)
      unawaited(HomeScaffoldController.to.gotoWindow(0));

    /// 已经在此服务器了，不调用服务器跳转
    if (alreadyEnteredGuild) {
      if (specificChannel) {
        final target = ChatTargetsModel.instance.selectedChatTarget;
        if (channelId == GlobalState.selectedChannel.value?.id) {
          // 如果已在指定频道，不作任何处理
          if (HomeScaffoldController.to.windowIndex.value == 1) return;
          // 如果已在指定频道，但是未进入
          unawaited(HomeScaffoldController.to.gotoWindow(1));
        } else {
          // 如果在目标服务器，但是频道不同
          // target.getChannel(channelId) 有可能为空，需要给个默认值
          unawaited(target.setSelectedChannel(
              target.getChannel(channelId) ?? target.defaultChannel,
              gotoChatView: false));
        }
      } else {
        // 未指定了跳转频道，那么保留当前选中频道，即不作任何处理
        return;
      }
    } else {
      unawaited(ChatTargetsModel.instance.selectChatTargetById(
        guildId,
        channelId: channelId,
        gotoChatView: specificChannel,
      ));
      //如果跳转的频道是语音频道，且不是当前服务端的，消息公屏需要切到该服务器的默认频道
      final channel = Db.channelBox?.get(channelId);
      if (channel?.type == ChatChannelType.guildVoice) {
        final target = ChatTargetsModel.instance.getGuild(guildId);
        unawaited(ChatTargetsModel.instance
            .getGuild(guildId)
            ?.setSelectedChannel(target?.defaultChannel, gotoChatView: false));
      }
    }
  }
}
