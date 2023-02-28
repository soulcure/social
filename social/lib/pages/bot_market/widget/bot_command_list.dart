import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/api/entity/bot_info.dart';
import 'package:im/app/modules/multi_channel_command_shortcuts_settings_page/bindings/multi_channel_command_shortcuts_settings_page_binding.dart';
import 'package:im/app/routes/app_pages.dart' as app_pages;
import 'package:im/common/extension/string_extension.dart';
import 'package:im/dlog/dlog_manager.dart';
import 'package:im/loggers.dart';
import 'package:im/pages/bot_commands/model/displayed_cmds_model.dart';
import 'package:im/pages/bot_market/model/robot_model.dart';
import 'package:im/pages/bot_market/widget/bot_command_item.dart';
import 'package:im/pages/home/json/text_chat_json.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/pages/home/model/text_channel_controller.dart';
import 'package:im/pages/home/view/components/robot_form_component.dart';
import 'package:im/pages/home/view/components/robot_selection_keyboard.dart';
import 'package:im/themes/const.dart';
import 'package:im/utils/show_bottom_modal.dart';
import 'package:pedantic/pedantic.dart';

import '../../../routes.dart';

typedef BotCommandUseCallback = Future<bool> Function(BotCommandItem);

// 命令列表组件
class BotCommandList extends StatefulWidget {
  final BuildContext context;
  final String botId;
  final String guildId;
  final String channelId;

  ///  是否显示设置快捷指令按钮
  final bool showSetBtn;

  ///  是否显示使用快捷指令按钮
  final bool showUseBtn;

  /// 是否需要判断在服务器内
  /// true，只展示有权限看到的命令（服务器内）
  /// false，展示机器人所有指令（私聊）
  final bool isInGuild;

  /// 机器人指令设置前的逻辑
  final BotCommandUseCallback onBeforeCommandSet;

  /// 机器人指令使用前的逻辑
  final BotCommandUseCallback onBeforeCommandUse;

  const BotCommandList({
    Key key,
    @required this.context,
    @required this.botId,
    @required this.guildId,
    @required this.channelId,
    this.showSetBtn = true,
    this.showUseBtn = true,
    this.onBeforeCommandSet,
    this.onBeforeCommandUse,
    this.isInGuild = true,
  }) : super(key: key);

  @override
  _BotCommandListState createState() => _BotCommandListState();
}

class _BotCommandListState extends State<BotCommandList> {
  Future _future;
  DisplayedCmdsController _model;
  @override
  void initState() {
    if (Get.isRegistered<DisplayedCmdsController>(tag: widget.channelId)) {
      _model = Get.find<DisplayedCmdsController>(tag: widget.channelId);
      final List<Future> futureList = [];

      /// 获取机器人指令列表
      futureList
          .add(_model.getVisibleRobotCmds(widget.botId, !widget.isInGuild));

      /// 在服务器内需要判断该机器人是否已经被添加，因为没被添加的机器人不能在频道内使用指令
      if (widget.showSetBtn)
        futureList
            .add(RobotModel.instance.getAddedRobotsFuture(widget.guildId));
      _future = Future.wait(futureList);
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (_model == null) {
      return sizedBox;
    }
    return FutureBuilder(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.hasError || !snapshot.hasData) {
            if (snapshot.hasError) {
              logger.severe("获取机器人命令失败", snapshot.error);
            }
            return sizedBox;
          }
          final commands = List<BotCommandItem>.from(snapshot.data.first);
          if (commands.isEmpty) return sizedBox;
          final child = Column(
            children: [
              sizeHeight6,
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '机器人功能'.tr,
                  style: Get.textTheme.bodyText1.copyWith(fontSize: 12),
                ),
              ),
              sizeHeight8,
              ...commands
                  .map((e) => BotCommandCardItem(
                        command: e,
                        // 指令设置按钮只能在频道内使用（私聊不行）
                        showSetBtn: widget.showSetBtn,
                        showUseBtn: widget.showUseBtn,
                        onUse: () async {
                          final res = await widget.onBeforeCommandUse?.call(e);
                          if (res == true) await _onCommandUse(e);
                        },
                        onSet: () async {
                          final res = await widget.onBeforeCommandSet?.call(e);
                          if (res == true) _onCommandSet(e);
                        },
                      ))
                  .toList()
            ],
          );
          if (!widget.showSetBtn) {
            return child;
          }
          final isRobotAdded =
              List<String>.from(snapshot.data[1]).contains(widget.botId);
          if (!isRobotAdded) return sizedBox;
          return child;
        });
  }

  void _onCommandSet(BotCommandItem rc) {
    Get.toNamed(app_pages.Routes.MULTI_CHANNEL_COMMAND_SHORTCUT_SETTINGS_PAGE,
        arguments: MultiChannelCommandShortcutsSettingsPageParams(
          command: rc,
        ));
    DLogManager.getInstance().customEvent(
      actionEventId: "guild_bot_card",
      actionEventSubId: "click_function_command",
      actionEventSubParam: rc.command,
      extJson: {
        "guild_id": widget.guildId,
        "bot_user_id": widget.botId,
      },
    );
  }

  Future<void> _onCommandUse(BotCommandItem rc) async {
    DLogManager.getInstance().customEvent(
      actionEventId: "guild_bot_card",
      actionEventSubId: "click_function_use",
      actionEventSubParam: rc.command,
      extJson: {
        "guild_id": widget.guildId,
        "bot_user_id": widget.botId,
      },
    );
    final command = rc;
    if (command.appId.hasValue) {
      // 指令要打开小程序
      await Routes.pushMiniProgram(command.appId);
      return;
    }
    if (command.url.hasValue) {
      unawaited(Routes.pushHtmlPage(context, command.url));
      return;
    }
    final m = TextChannelController.to(channelId: widget.channelId);

    final str = StringBuffer(command.command);
    if (command.formParameters != null) {
      final result = await showBottomModal(
        context,
        backgroundColor: Theme.of(context).backgroundColor,
        builder: (c, s) =>
            RobotFormComponent(command.command, command.formParameters),
      );
      if (result == null) return;
      str.write(" $result");
    } else if (command.selectParameters != null) {
      final result = await showBottomModal(context,
          builder: (c, s) => RobotSelectionKeyboard(command.selectParameters));
      if (result == null) return;
      str.write(" $result");
    }
    String contentString = TextEntity.getCommandString(str.toString());
    if (m.channel.type == ChatChannelType.guildText) {
      contentString =
          "${TextEntity.getAtString(rc.botId, false)}$contentString";
    }
    unawaited(
      m.sendContent(
        TextEntity.fromString(
          contentString,
          isHide: command.hide,
          isClickable: command.clickable,
        ),
      ),
    );
  }
}
