import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/api/entity/bot_info.dart';
import 'package:im/common/extension/future_extension.dart';
import 'package:im/common/extension/string_extension.dart';
import 'package:im/core/widgets/button/fade_button.dart';
import 'package:im/pages/bot_commands/model/displayed_cmds_model.dart';
import 'package:im/pages/bot_market/widget/robot_icon.dart';
import 'package:im/pages/home/json/text_chat_json.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/pages/home/model/input_model.dart';
import 'package:im/pages/home/model/text_channel_controller.dart';
import 'package:im/pages/home/view/components/robot_form_component.dart';
import 'package:im/pages/home/view/components/robot_selection_keyboard.dart';
import 'package:im/routes.dart';
import 'package:im/themes/const.dart';
import 'package:im/utils/orientation_util.dart';
import 'package:im/utils/show_bottom_modal.dart';
import 'package:im/widgets/avatar.dart';
import 'package:im/widgets/mouse_hover_builder.dart';
import 'package:pedantic/pedantic.dart';
import 'package:provider/provider.dart';
import 'package:sliding_sheet/sliding_sheet.dart';

/// 展示指令列表，可拖拽至全屏
class LandscapeRobotCmdsPopupList extends StatelessWidget {
  final double itemHeight = 44;
  final double headerHeight = 20;
  final _controller = SheetController();
  final String channelId;

  LandscapeRobotCmdsPopupList(this.channelId);

  Widget landscapeWrapper(BuildContext context, {Widget child}) {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 0),
      decoration: BoxDecoration(
          color: Theme.of(context).backgroundColor,
          borderRadius: BorderRadius.circular(8),
          boxShadow: const [
            BoxShadow(
                blurRadius: 26,
                spreadRadius: 4,
                offset: Offset(0, 7),
                color: Color(0x1F717D8D))
          ]),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 8),
      child: GetBuilder<DisplayedCmdsController>(
        tag: channelId,
        builder: (c) {
          final items = c.displayedCmds;
          if (items == null || items.isEmpty) {
            /// 指令列表为空
            return const SizedBox();
          }
          final minExtent =
              items.length <= 3 ? items.length * itemHeight : itemHeight * 3.5;
          return Container(
            constraints: BoxConstraints(
              minHeight: minExtent,
              maxHeight: 400,
            ),
            child: landscapeWrapper(
              context,
              child: MediaQuery.removePadding(
                context: context,
                removeTop: true,
                child: ListView.separated(
                  itemCount: items.length,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  separatorBuilder: (context, i) => OrientationUtil.portrait
                      ? const Padding(
                          padding: EdgeInsets.only(left: 54),
                          child: Divider(),
                        )
                      : const SizedBox(),
                  itemBuilder: (context, i) {
                    final itemData = items[i];
                    return GestureDetector(
                      onTap: () {},
                      child: _buildCmdItem(context, itemData),
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// 构建列表的item项
  Widget _buildCmdItem(BuildContext context, BotCommandItem item) {
    final theme = Theme.of(context);
    const tailTextStyle = TextStyle(color: Color(0xFF8F959E), fontSize: 14);
    return MouseHoverBuilder(builder: (context, hover) {
      return FadeButton(
        // 失效的指令无法点击
        onTap: () => _sendCommand(context, item),
        backgroundColor:
            hover ? Theme.of(context).primaryColor : Colors.transparent,
        child: Container(
          height: itemHeight,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              if (item.botAvatar.hasValue)
                Avatar(
                    url: item.botAvatar,
                    radius: OrientationUtil.portrait ? 16 : 12)
              else
                RobotAvatar(
                    url: item.botAvatar,
                    radius: OrientationUtil.portrait ? 16 : 12),
              sizeWidth10,
              Expanded(
                child: Text(
                  item.command,
                  style: theme.textTheme.bodyText2.copyWith(
                      color: !item.isValid
                          ? theme.disabledColor
                          : (hover
                              ? Colors.white
                              : theme.textTheme.bodyText2.color)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // 该指令仅管理员可见
              if (item.isAdminVisible) Text("管理员可见".tr, style: tailTextStyle),
              // 该指令已失效
              if (!item.isValid) Text("指令已失效".tr, style: tailTextStyle),
            ],
          ),
        ),
      );
    });
  }

  /// 隐藏命令列表
  Future _dismiss(BuildContext context) async {
    await _controller.hide();
    _removeDisplayCmds(context);
  }

  void _removeDisplayCmds(BuildContext context) {
    Get.find<DisplayedCmdsController>(tag: channelId).hideCmds();
  }

  /// 发送命令到聊天窗口
  Future _sendCommand(BuildContext context, BotCommandItem robotCmd) async {
    // 指令已失效
    if (!robotCmd.isValid) return;

    if (robotCmd.appId.hasValue) {
      // 指令要打开小程序
      Routes.pushMiniProgram(robotCmd.appId).unawaited;
      await _dismiss(context);
      return;
    }
    _removeDisplayCmds(context);
    final command = robotCmd;
    final m = TextChannelController.to(channelId: channelId);
    if (m.channel.type == ChatChannelType.guildText) {
      context.read<InputModel>().inputController.clear();
    }
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
          "${TextEntity.getAtString(robotCmd.botId, false)}$contentString";
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
