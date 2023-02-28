import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/widgets/app_bar/appbar_builder.dart';
import 'package:im/widgets/channel_icon.dart';
import 'package:im/widgets/check_square_box.dart';
import '../controllers/multi_channel_command_shortcuts_settings_page_controller.dart';
import 'package:im/themes/const.dart';

class MultiChannelCommandShortcutsSettingsPageView
    extends GetView<MultiChannelCommandShortcutsSettingsPageController> {
  @override
  Widget build(BuildContext context) {
    return GetBuilder<MultiChannelCommandShortcutsSettingsPageController>(
        builder: (c) {
      return WillPopScope(
        onWillPop: c.changedChannels.isEmpty ? null : c.onWillPop,
        child: Scaffold(
          appBar: FbAppBar.custom(
            '设置频道快捷指令'.tr,
            actions: controller.actionModels,
          ),
          body: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Container(
                  color: Get.theme.backgroundColor,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                        child: Text(
                          '效果示例'.tr,
                          style: Get.textTheme.bodyText1.copyWith(
                              color: const Color(0xFF5C6273), fontSize: 14),
                        ),
                      ),
                      Center(
                        child: Image.asset(
                          'assets/images/command_shortcut_screen.png',
                          width: 251,
                          height: 128,
                        ),
                      )
                    ],
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: sizeHeight8),
              SliverToBoxAdapter(
                child: Container(
                  color: Get.theme.backgroundColor,
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                  child: Text(
                    '请选择频道'.tr,
                    style: Get.textTheme.bodyText1
                        .copyWith(color: const Color(0xFF5C6273), fontSize: 14),
                  ),
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    return _channelItem(controller.channels[index]);
                  },
                  childCount: controller.channels.length,
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(height: Get.mediaQuery.viewPadding.bottom),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _channelItem(ChatChannel channel) {
    return GestureDetector(
      onTap: () {
        final val = controller.selectedChannels.contains(channel.id);
        controller.onChange(!val, channel);
      },
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(color: Get.theme.backgroundColor),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                SizedBox(
                  height: 20,
                  width: 20,
                  child: CheckSquareBox(
                    value: controller.selectedChannels.contains(channel.id),
                    onChanged: (val) => controller.onChange(val, channel),
                  ),
                ),
                sizeWidth12,
                ChannelIcon(
                  ChatChannelType.guildText,
                  private: channel.isPrivate,
                  size: 20,
                  color: Get.textTheme.bodyText2.color,
                ),
                sizeWidth12,
                Expanded(
                  child: Text(
                    channel.name,
                    style: TextStyle(
                        fontSize: 16, color: Get.textTheme.bodyText2.color),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const Divider(indent: 36)
        ],
      ),
    );
  }
}
