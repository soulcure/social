import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:im/api/bot_api.dart';
import 'package:flutter/material.dart';
import 'package:im/api/entity/bot_info.dart';
import 'package:im/common/permission/permission.dart';
import 'package:im/common/permission/permission_model.dart';
import 'package:im/common/permission/permission_utils.dart';
import 'package:im/dlog/dlog_manager.dart';
import 'package:im/pages/bot_market/model/channel_cmds_model.dart';
import 'package:im/pages/home/model/chat_index_model.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/themes/default_theme.dart';
import 'package:im/utils/show_confirm_dialog.dart';
import 'package:im/widgets/app_bar/appbar_action_model.dart';

class MultiChannelCommandShortcutsSettingsPageController
    extends GetxController {
  final String botId;
  final BotCommandItem command;

  MultiChannelCommandShortcutsSettingsPageController(
      {@required this.botId, @required this.command});

  List<ChatChannel> channels = [];
  List<String> selectedChannels = [];
  List<String> _selectedChannelsBak = [];
  final Map<String, CommandOp> changedChannels = {};
  List<AppBarActionModelInterface> actionModels = [];

  AppBarActionModelInterface get actionModel => actionModels.single;

  @override
  void onInit() {
    actionModels.add(AppBarTextPrimaryActionModel(
      "确定".tr,
      isEnable: false,
      actionBlock: onConfirm,
    ));
    _loadChannels();
    super.onInit();
  }

  // 加载可以设置指令的频道
  void _loadChannels() {
    final guildTarget =
        ChatTargetsModel.instance.selectedChatTarget as GuildTarget;
    guildTarget.channels?.forEach((channel) {
      final isTextChannel = channel.type == ChatChannelType.guildText;
      final GuildPermission gp = PermissionModel.getPermission(channel.guildId);
      final isVisible = PermissionUtils.isChannelVisible(
          gp, channel.id); //[dj private channel]
      if (isTextChannel && isVisible) {
        final List<Map<String, String>> botSetting = ChannelCmdsModel.instance
                .getChannelCommands(channel.id, channel.guildId) ??
            [];
        if (botSetting.isNotEmpty) {
          final cmd = botSetting.firstWhereOrNull((element) {
            if (element.isEmpty) return false;
            final kv = element.entries.first;
            return kv.key == botId && kv.value == command.command;
          });
          if (cmd != null) {
            // 添加已经设置过当前指令的频道
            selectedChannels.add(channel.id);
          }
        }
        channels.add(channel);
      }
    });
    _selectedChannelsBak = List.from(selectedChannels);
  }

  void onChange(bool val, ChatChannel channel) {
    if (actionModel.isLoading) return;
    if (val) {
      selectedChannels.addIf(
          !selectedChannels.contains(channel.id), channel.id);

      if (_selectedChannelsBak.contains(channel.id)) {
        changedChannels.remove(channel.id);
      } else {
        changedChannels[channel.id] = CommandOp.add;
      }
    } else {
      selectedChannels.remove(channel.id);
      if (!_selectedChannelsBak.contains(channel.id)) {
        changedChannels.remove(channel.id);
      } else {
        changedChannels[channel.id] = CommandOp.del;
      }
    }
    actionModel.isEnable = changedChannels.isNotEmpty;
    update();
  }

  Future<bool> onWillPop() async {
    if (changedChannels.isEmpty) {
      Get.back();
      return true;
    }
    final res = await showConfirmDialog(
        title: '确定保存并退出？'.tr,
        confirmText: '确定'.tr,
        cancelText: '不保存'.tr,
        confirmStyle: TextStyle(
          color: primaryColor,
          fontSize: 17,
          fontWeight: FontWeight.w500,
        ),
        barrierDismissible: true);
    if (res == true) {
      await onConfirm();
      return true;
    } else if (res == false) {
      Get.back();
      return true;
    } else {
      return false;
    }
  }

  Future<void> onConfirm() async {
    if (changedChannels.isEmpty) {
      Get.back();
      return;
    }
    try {
      _toggleLoading(true);
      await ChannelCmdsModel.instance.multiSetChannelCommands(
        changedChannels,
        guildId,
        botId,
        command.command,
      );
      DLogManager.getInstance().customEvent(
        actionEventId: "guild_bot_card",
        actionEventSubId: "click_function_command_succ",
        actionEventSubParam: command.command,
        extJson: {
          "guild_id": guildId,
          "bot_user_id": botId,
        },
      );
      _toggleLoading(false);
      Get.back();
    } catch (_) {
      _toggleLoading(false);
    }
  }

  void _toggleLoading(bool val) {
    actionModel.isLoading = val;
    update();
  }

  String get guildId => ChatTargetsModel.instance.selectedChatTarget?.id;
}
