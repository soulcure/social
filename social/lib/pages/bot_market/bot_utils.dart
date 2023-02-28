import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/api/entity/bot_info.dart';
import 'package:im/api/guild_api.dart';
import 'package:im/common/extension/string_extension.dart';
import 'package:im/common/permission/permission_utils.dart';
import 'package:im/dlog/dlog_manager.dart';
import 'package:im/loggers.dart';
import 'package:im/pages/home/json/text_chat_json.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/pages/home/model/text_channel_controller.dart';
import 'package:im/pages/home/view/components/robot_form_component.dart';
import 'package:im/pages/home/view/components/robot_selection_keyboard.dart';
import 'package:im/quest/fb_quest_config.dart';
import 'package:im/utils/show_bottom_action_sheet.dart';
import 'package:im/utils/show_bottom_modal.dart';
import 'package:im/widgets/toast.dart';
import 'package:oktoast/oktoast.dart';
import 'package:pedantic/pedantic.dart';
import 'package:quest_system/quest_system.dart';
import '../../global.dart';
import '../../routes.dart';
import 'model/channel_cmds_model.dart';
import 'model/robot_model.dart';
import 'package:im/pages/home/model/input_model.dart';
import 'package:im/routes.dart';
import 'package:provider/provider.dart';

/// 删除添加机器人四个入口
enum BotRemovePosition {
  // 机器人详情页
  bot_detail,
  // 机器人市场
  bot_market,
  // 机器人卡片
  bot_card,
  // 编辑成员
  edit_member,
}

/// 指令状态
enum AddedStatus {
  /// 已添加
  Added,

  /// 未添加
  UnAdded,

  /// 指令失效
  Invalid,
}

extension BotRemovePositionExtension on BotRemovePosition {
  String get str {
    switch (this) {
      case BotRemovePosition.bot_market:
        return 'bot_list';
      case BotRemovePosition.bot_detail:
        return 'bot_detail';
      case BotRemovePosition.bot_card:
        return 'bot_list_card';
      case BotRemovePosition.edit_member:
        return 'editor_member_page';
      default:
        return null;
    }
  }
}

class BotUtils {
  static Future<void> removeBot(
    String guildId,
    String botId,
  ) async {
    // 移除该机器人下的快捷指令
    await ChannelCmdsModel.instance.removeAllChannelCmds(robotId: botId);
    // 从服务器删除该机器人
    await GuildApi.removeUser(
      guildId: guildId,
      userId: Global.user.id,
      memberId: botId,
      isOriginDataReturn: true,
    );
    Toast.iconToast(icon: ToastIcon.success, label: '移除成功'.tr);
    await RobotModel.instance.removeGuildRobot(guildId, botId);
  }

  static void dLogAddEvent(
    String guildId,
    String botId, {
    bool fromDetail = false,
    bool success = true,
  }) {
    DLogManager.getInstance().customEvent(
      actionEventId: "guild_bot_operate",
      actionEventSubId: "click_guild_bot_add",
      actionEventSubParam: fromDetail ? 'bot_detail' : 'bot_list',
      extJson: {
        "guild_id": guildId,
        "bot_user_id": botId,
        'status': success ? 1 : 0,
      },
    );
  }

  static void dLogDelEvent(
    String guildId,
    String botId, {
    BotRemovePosition botRemovePosition,
    bool success = true,
  }) {
    final removePosition = botRemovePosition.str;
    if (removePosition == null) return;
    DLogManager.getInstance().customEvent(
      actionEventId: "guild_bot_operate",
      actionEventSubId: "click_guild_bot_kickout",
      actionEventSubParam: removePosition,
      extJson: {
        "guild_id": guildId,
        "bot_user_id": botId,
        "status": success ? 1 : 0,
      },
    );
  }

  static List<Object> getNewBotQuestSegments(String guildId, String botId) {
    return [FbQuestId.newBotRedDot, '_', guildId, '_', botId];
  }

  static void restoreQuests(Map<String, dynamic> data) {
    final prefix = const QuestId([FbQuestId.newBotRedDot, '_']).toString();
    data?.keys?.forEach((k) {
      if (k.startsWith(prefix)) {
        final splits = k.split("_");
        if (splits.length > 2) {
          final guildId = splits[1];
          final botId = splits[2];
          addBotRedDotQuest(guildId: guildId, botId: botId);
        }
      }
    });
  }

  static void addBotRedDotQuest({String guildId, String botId}) {
    final qg = QuestSystem.getQuest<QuestGroup>(QIDSegGroup.newBotRedDot);
    Quest quest;
    quest = Quest.autoTrigger(
      id: QuestId(BotUtils.getNewBotQuestSegments(guildId, botId)),
      onComplete: () {
        qg.remove(quest);
      },
      completeChecker: QuestChecker.condition(
          QuestCondition(BotUtils.getNewBotQuestSegments(guildId, botId))),
    );
    qg.add(quest);
  }

  // 发送指令对应的操作
  static Future<void> sendCommand(
      {@required BuildContext context,
      @required String channelId,
      @required BotCommandItem cmd,
      VoidFutureCallBack callback}) async {
    // 指令已失效
    if (!cmd.isValid) {
      showToast('该指令已失效，请联系管理员'.tr);
      return;
    }
    if (cmd.appId.hasValue) {
      // 指令要打开小程序
      unawaited(Routes.pushMiniProgram(cmd.appId));
      await callback?.call();
      return;
    }
    if (cmd.url.hasValue) {
      unawaited(Routes.pushHtmlPage(context, cmd.url));
      await callback?.call();
      return;
    }
    await callback?.call();
    final m = TextChannelController.to(channelId: channelId);
    if (m.channel.type == ChatChannelType.guildText) {
      context.read<InputModel>().inputController.clear();
    }
    final str = StringBuffer(cmd.command);
    if (cmd.formParameters != null) {
      final result = await showBottomModal(
        context,
        backgroundColor: Theme.of(context).backgroundColor,
        builder: (c, s) => RobotFormComponent(cmd.command, cmd.formParameters),
      );
      if (result == null) return;
      str.write(" $result");
    } else if (cmd.selectParameters != null) {
      final result = await showBottomModal(context,
          builder: (c, s) => RobotSelectionKeyboard(cmd.selectParameters));
      if (result == null) return;
      str.write(" $result");
    }
    String contentString = TextEntity.getCommandString(str.toString());
    if (m.channel.type == ChatChannelType.guildText) {
      contentString =
          "${TextEntity.getAtString(cmd.botId, false)}$contentString";
    }
    unawaited(
      m.sendContent(
        TextEntity.fromString(
          contentString,
          isHide: cmd.hide,
          isClickable: cmd.clickable,
        ),
      ),
    );
  }

  static Future<List<BotCommandItem>> getChannelCmds(
      String guildId, String channelId) async {
    // 获取频道快捷指令快照
    final botSetting =
        ChannelCmdsModel.instance.getChannelCommands(channelId, guildId);
    if (botSetting == null) {
      return [];
    }
    final List<BotCommandItem> itemCmds = [];

    final isAdmin = PermissionUtils.isGuildOwner();
    // 根据快照拉取完整的指令信息
    for (final item in botSetting) {
      BotInfo robot;
      final kv = item.entries.first;
      final robotId = kv.key;
      try {
        robot = await RobotModel.instance.getRobot(robotId);
        final cmd =
            robot.commands?.firstWhereOrNull((cmd) => kv.value == cmd.command);
        if (cmd != null) {
          if (isCmdVisible(cmd, false)) {
            itemCmds.add(cmd);
          }
        } else if (isAdmin) {
          // 只有服务器管理者能看到失效的指令
          itemCmds.add(
            BotCommandItem(
              botId: robotId,
              botAvatar: robot?.botAvatar,
              command: kv.value,
              isValid: false,
            ),
          );
        }
      } on InvalidRobotError catch (e) {
        // 机器人被删除
        logger.info('机器人被删除 $robotId', e);
      }
    }
    return itemCmds;
  }

  /// 判断指令是否可见，遵循如下规则：
  /// 1. 公开指令（visibleLevel = 0）所有情况下都可见
  /// 2. 私聊指令（visibleLevel = 1）只在私聊窗口可见
  /// 3. 所有者指令（visibleLevel = 2），对当前服务器的所有者可见（因为私聊窗口中不存在所有者的概念，因此无法看见此级别的指令）
  ///
  /// cmd: 机器人指令
  /// isPrivateChat: 是否为私聊界面
  static bool isCmdVisible(BotCommandItem cmd, bool isPrivateChat) {
    // 是否为公开可见
    final isPublic = cmd.visibleLevel == 0;
    // 是否为私聊可见
    final isPrivate = isPrivateChat && cmd.visibleLevel == 1;
    // 是否为管理员可见
    final isAdmin = PermissionUtils.isGuildOwner() && cmd.isAdminVisible;
    return isPublic || isPrivate || isAdmin;
  }
}
