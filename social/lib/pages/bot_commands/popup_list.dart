import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/api/entity/bot_info.dart';
import 'package:im/common/extension/string_extension.dart';
import 'package:im/core/widgets/button/fade_button.dart';
import 'package:im/pages/bot_commands/model/displayed_cmds_model.dart';
import 'package:im/pages/bot_market/bot_utils.dart';
import 'package:im/pages/bot_market/widget/robot_icon.dart';
import 'package:im/themes/const.dart';
import 'package:im/widgets/avatar.dart';
import 'package:sliding_sheet/sliding_sheet.dart';

/// 展示指令列表，可拖拽至全屏
class RobotCmdsPopupList extends StatelessWidget {
  static double itemHeight = 56;
  static double headerHeight = 20;
  static double maxHeightRatio = 0.95;
  final String channelId;
  final SheetController controller;

  const RobotCmdsPopupList(
      {@required this.channelId, @required this.controller});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<DisplayedCmdsController>(
      tag: channelId,
      builder: (c) {
        final items = c.displayedCmds;

        if (items == null || items.isEmpty) {
          /// 指令列表为空
          return const SizedBox();
        }
        final theme = Theme.of(context);
        return LayoutBuilder(
          builder: (context, constraint) {
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {},
              child: SlidingSheet(
                closeOnBackdropTap: true,
                backdropColor: Colors.black.withOpacity(0.6),
                duration: const Duration(milliseconds: 300),
                controller: controller,
                cornerRadius: 10,
                cornerRadiusOnFullscreen: 0,
                scrollSpec: const ScrollSpec(physics: ClampingScrollPhysics()),
                snapSpec: SnapSpec(
                  initialSnap: 0,
                  snappings: [0, maxHeightRatio],
                  // positioning: SnapPositioning.relativeToSheetHeight,
                ),
                listener: (state) {
                  if (state.isHidden) {
                    if (Get.isRegistered<DisplayedCmdsController>(
                        tag: channelId)) {
                      Get.find<DisplayedCmdsController>(tag: channelId)
                          .hideCmds();
                    }
                  }
                },
                headerBuilder: (context, state) {
                  return SizedBox(
                    height: headerHeight,
                    child: Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color:
                              theme.textTheme.bodyText1.color.withOpacity(0.2),
                          borderRadius:
                              const BorderRadius.all(Radius.circular(4)),
                        ),
                      ),
                    ),
                  );
                },
                builder: (context, state) {
                  return ListView.separated(
                    padding: const EdgeInsets.all(0),
                    itemCount: items?.length ?? 0,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    separatorBuilder: (context, i) => const Padding(
                      padding: EdgeInsets.only(left: 54),
                      child: Divider(),
                    ),
                    itemBuilder: (context, i) {
                      final itemData = items[i];
                      return GestureDetector(
                        onTap: () {},
                        child: _buildCmdItem(context, itemData),
                      );
                    },
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  /// 构建列表的item项
  Widget _buildCmdItem(BuildContext context, BotCommandItem item) {
    final theme = Theme.of(context);
    final tailTextStyle = TextStyle(
        color: const Color(0xFF5C6273).withOpacity(0.75), fontSize: 10);
    var titleStyle = theme.textTheme.bodyText2.copyWith(fontSize: 16);
    if (!item.isValid) {
      titleStyle = titleStyle.copyWith(color: theme.disabledColor);
    }

    return FadeButton(
      // 失效的指令无法点击
      onTap: () => _sendCommand(context, item),
      child: Container(
        height: itemHeight,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            if (item.botAvatar.hasValue)
              Avatar(url: item.botAvatar, radius: 16)
            else
              RobotAvatar(url: item.botAvatar, radius: 16),
            sizeWidth10,
            Expanded(
              child: Text(
                item.command,
                style: titleStyle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // 该指令仅管理员可见
            if (item.isAdminVisible)
              _commandTag(child: Text("管理员可见".tr, style: tailTextStyle)),
            // 该指令已失效
            if (!item.isValid)
              _commandTag(
                  needMarginLeft: true,
                  child: Text(
                    "指令已失效".tr,
                    style: tailTextStyle,
                  )),
          ],
        ),
      ),
    );
  }

  /// 隐藏命令列表
  Future _dismiss(BuildContext context) async {
    await controller.hide();
    _removeDisplayCmds(context);
  }

  void _removeDisplayCmds(BuildContext context) {
    Get.find<DisplayedCmdsController>(tag: channelId).hideCmds();
  }

  /// 发送命令到聊天窗口
  Future<void> _sendCommand(BuildContext context, BotCommandItem robotCmd) {
    return BotUtils.sendCommand(
        context: context,
        channelId: channelId,
        cmd: robotCmd,
        callback: () => _dismiss(context));
  }

  Widget _commandTag({@required Widget child, bool needMarginLeft = false}) {
    return Container(
      margin: needMarginLeft ? const EdgeInsets.only(left: 4) : EdgeInsets.zero,
      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
      decoration: BoxDecoration(
          color: const Color(0xFFF5F6FA),
          borderRadius: BorderRadius.circular(3)),
      child: child,
    );
  }
}
