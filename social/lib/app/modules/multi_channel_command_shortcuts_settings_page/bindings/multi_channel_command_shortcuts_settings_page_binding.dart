import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/api/entity/bot_info.dart';

import '../controllers/multi_channel_command_shortcuts_settings_page_controller.dart';

class MultiChannelCommandShortcutsSettingsPageBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<MultiChannelCommandShortcutsSettingsPageController>(
      () {
        final command =
            (Get.arguments as MultiChannelCommandShortcutsSettingsPageParams)
                .command;
        return MultiChannelCommandShortcutsSettingsPageController(
            botId: command.botId, command: command);
      },
    );
  }
}

class MultiChannelCommandShortcutsSettingsPageParams {
  final BotCommandItem command;

  MultiChannelCommandShortcutsSettingsPageParams({@required this.command});
}
