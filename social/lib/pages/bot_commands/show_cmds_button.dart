import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/api/data_model/user_info.dart';
import 'package:im/icon_font.dart';
import 'package:im/loggers.dart';
import 'package:im/pages/bot_commands/model/displayed_cmds_model.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/themes/default_theme.dart';

typedef ShowCmdsCallback = void Function(bool isShow);

class ShowCmdsButton extends StatelessWidget {
  /// 当前的聊天对象
  final ChatChannel channel;
  final double width;
  final double height;
  final ShowCmdsCallback showCallback;

  const ShowCmdsButton(
    this.channel, {
    Key key,
    this.width = 30,
    this.height = 40,
    this.showCallback,
  }) : super(key: key);

  Future _init(BuildContext context) async {
    if (channel == null) {
      return null;
    }
    DisplayedCmdsController model;

    if (Get.isRegistered<DisplayedCmdsController>(tag: channel.id)) {
      model = Get.find<DisplayedCmdsController>(tag: channel.id);
    }

    if (model == null) return null;

    /// 是否为私聊窗口
    final isPrivateChat = channel.type == ChatChannelType.dm;
    if (isPrivateChat) {
      /// 在机器人私聊窗口中，拉取该机器人指令
      final user = await UserInfo.get(channel.recipientId);
      if (user.isBot) {
        return model.getRobotCmds(user.userId, isPrivateChat);
      }
      return null;
    }

    /// 在频道聊天窗口中
    if (channel.type == ChatChannelType.guildText) {
      return model.getChannelCmds(channel.id, channel.guildId);
    }
  }

  /// 点击按钮的行为
  Future _action(BuildContext context) async {
    final model = Get.find<DisplayedCmdsController>(tag: channel.id);
    if (!model.hasCmds || model.hasInput.value) {
      /// 展示指令按钮不可见
      return;
    }
    if (model.isShow) {
      /// 指令列表处于展开状态，点击按钮隐藏
      if (showCallback != null) {
        showCallback(false);
      }
      model.hideCmds();
    } else {
      /// 指令列表处于收起状态，点击按钮展开
      if (showCallback != null) {
        showCallback(true);
      }
      model.showCmds();
    }
  }

  Widget _buildBtn(BuildContext context) {
    if (!Get.isRegistered<DisplayedCmdsController>(tag: channel.id)) {
      return const SizedBox();
    }
    final DisplayedCmdsController cmdsModel =
        Get.find<DisplayedCmdsController>(tag: channel.id);
    return FutureBuilder(
      future: _init(context),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !cmdsModel.hasCmds) {
          if (snapshot.hasError) {
            logger.severe('指令按钮初始化失败', snapshot.error);
          }
          // 当正在请求中，请求失败，没有要展示的指令时不显示按钮
          return const SizedBox();
        }

        return ValueListenableBuilder(
          valueListenable: cmdsModel.hasInput,
          builder: (context, isInputting, child) {
            // 当没有输入时才显示按钮
            if (!isInputting) {
              return child;
            }
            return const SizedBox();
          },
          child: GetBuilder<DisplayedCmdsController>(
            tag: channel.id,
            builder: (c) {
              return SizedBox(
                width: width,
                height: height,
                child: GestureDetector(
                  onTap: () => _action(context),
                  child: Icon(
                    IconFont.buffCmdButton,
                    size: 24,
                    color: c.isShow ? primaryColor : const Color(0xFF8F959E),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // 是否为私聊窗口
    final isPrivateChat = channel.type == ChatChannelType.dm;
    if (isPrivateChat) {
      return _buildBtn(context);
    }

    // 频道聊天窗口，当频道配置发生变化时需要刷新快捷指令列表
    return ValueListenableBuilder(
      valueListenable: GlobalState.selectedChannel,
      builder: (context, channel, _) {
        return _buildBtn(context);
      },
    );
  }
}
