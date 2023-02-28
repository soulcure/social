import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/api/data_model/user_info.dart';
import 'package:im/api/entity/bot_info.dart';
import 'package:im/app/modules/home/controllers/home_scaffold_controller.dart';
import 'package:im/app/routes/app_pages.dart' as app_pages;
import 'package:im/common/permission/permission.dart';
import 'package:im/common/permission/permission_model.dart';
import 'package:im/common/permission/permission_utils.dart';
import 'package:im/pages/bot_market/widget/bot_command_list.dart';
import 'package:im/pages/home/model/chat_target_model.dart';

// 机器人卡槽
class BotSlot extends StatelessWidget {
  final BuildContext parentContext;
  final UserInfo user;
  final String guildId;
  final String channelId;

  const BotSlot({
    this.parentContext,
    this.user,
    this.guildId,
    this.channelId,
  });

  @override
  Widget build(BuildContext context) {
    bool showSetBtn;
    bool showUseBtn;
    bool inInGuild;
    if (GlobalState.isDmChannel) {
      inInGuild = false;
      showSetBtn = false;
      showUseBtn = true;
    } else {
      inInGuild = true;
      showSetBtn = PermissionUtils.isGuildOwner(guildId: guildId);
      final gp = PermissionModel.getPermission(guildId);
      showUseBtn = PermissionUtils.oneOf(gp, [Permission.SEND_MESSAGES],
          channelId: channelId);
    }
    return BotCommandList(
      context: parentContext,
      botId: user.userId,
      guildId: guildId,
      channelId: channelId,
      showSetBtn: showSetBtn,
      showUseBtn: showUseBtn,
      isInGuild: inInGuild,
      onBeforeCommandSet: _onBeforeCommandSet,
      onBeforeCommandUse: _onBeforeCommandUse,
    );
  }

  // 机器人指令设置前的逻辑
  Future<bool> _onBeforeCommandSet(BotCommandItem command) async {
    Get.back();
    await Future.delayed(const Duration(milliseconds: 200));
    return true;
  }

  // 机器人指令使用前的逻辑
  Future<bool> _onBeforeCommandUse(BotCommandItem rc) async {
    // 先跳回之前弹出卡片的页面
    Get.until((route) => route.settings.name == Get.previousRoute);
    // 假如是首页弹的用户卡片需要切到聊天公屏
    if (Get.previousRoute == app_pages.Routes.HOME)
      await HomeScaffoldController.to.gotoIndex(1);
    await Future.delayed(const Duration(milliseconds: 100));
    return true;
  }
}
