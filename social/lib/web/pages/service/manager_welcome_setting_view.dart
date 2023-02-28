import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/app/modules/welcome_setting/controllers/welcome_setting_controller.dart';
import 'package:im/app/modules/welcome_setting_select_channel/views/welcome_setting_select_channel_view.dart';
import 'package:im/app/routes/app_pages.dart' as app_pages;
import 'package:im/common/extension/string_extension.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/themes/const.dart';
import 'package:im/utils/orientation_util.dart';
import 'package:im/utils/show_confirm_dialog.dart';
import 'package:im/web/widgets/slider_sheet/show_slider_sheet.dart';
import 'package:im/widgets/channel_icon.dart';
import 'package:im/widgets/link_tile.dart';

class ManagerWelcomeSettingView extends GetView<WelcomeSettingController> {
  final String guildId;

  const ManagerWelcomeSettingView(this.guildId);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<WelcomeSettingController>(
        init: WelcomeSettingController(guildId),
        id: WelcomeSettingController.welcomePage,
        builder: (c) {
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: LinkTile(
                  context,
                  Text(
                    '欢迎界面'.tr,
                    textAlign: TextAlign.start,
                  ),
                  height: 52,
                  showTrailingIcon: false,
                  trailing: Transform.scale(
                      scale: 0.9,
                      alignment: Alignment.centerRight,
                      child: CupertinoSwitch(
                          activeColor: Theme.of(context).primaryColor,
                          value: c.isOpen,
                          onChanged: (v) async {
                            // 当未选择任何频道时，弹出框，确定后进入频道选择页面
                            if (controller.serverSelectedChannels.isEmpty &&
                                v == true) {
                              final res = await showConfirmDialog(
                                  title: '请选择至少一个频道'.tr,
                                  confirmText: '确定'.tr,
                                  barrierDismissible: true);
                              if (res == true) {
                                _gotoSelectChannelPage(context);
                              }
                            } else {
                              await controller.onSwitch(v);
                            }
                          })),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 26),
                  child: Text(
                    '开启后，新用户进入服务器后会展示欢迎界面。'.tr,
                    style: Theme.of(context)
                        .textTheme
                        .bodyText1
                        .copyWith(fontSize: 13),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                  child: LinkTile(
                context,
                Text(
                  '选择频道'.tr,
                ),
                height: 52,
                onTap: () {
                  _gotoSelectChannelPage(context);
                },
              )),
              SliverToBoxAdapter(
                  child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                child: Text(
                  '选中的频道将会在欢迎界面中展示频道介绍。'.tr,
                  style: Theme.of(context)
                      .textTheme
                      .bodyText1
                      .copyWith(fontSize: 13),
                ),
              )),
              if (c.serverSelectedChannels.isNotEmpty)
                const SliverToBoxAdapter(child: sizeHeight20),
              if (c.serverSelectedChannels.isNotEmpty)
                SliverToBoxAdapter(
                    child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                  child: Text(
                    '已选择频道'.tr,
                    style: Theme.of(context)
                        .textTheme
                        .bodyText1
                        .copyWith(fontSize: 13),
                  ),
                )),
              if (c.serverSelectedChannels.isNotEmpty)
                _buildSelectedChannels(context),
            ],
          );
        });
  }

  Widget _buildSelectedChannels(BuildContext context) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(_buildChannelItem,
          childCount: controller.serverSelectedChannels.length),
    );
  }

  Widget _buildChannelItem(context, index) {
    final channel = controller.serverSelectedChannels[index];
    return Container(
        color: Colors.white,
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              color: Colors.white,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      //图标
                      const ChannelIcon(ChatChannelType.guildText,
                          size: 16, color: Color(0xFF363940)),
                      sizeWidth8,
                      // 标题
                      Expanded(
                        child: Text(
                          channel.name,
                          softWrap: false,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 16,
                              height: 1.25,
                              color: Color(0xFF1F2125)),
                        ),
                      ),
                    ],
                  ),
                  if (channel.topic.hasValue) sizeHeight12,
                  if (channel.topic.hasValue)
                    Text(channel.topic,
                        style: const TextStyle(
                            fontSize: 13,
                            height: 1.23,
                            color: Color(0xFF646A73))),
                ],
              ),
            ),
            sizeHeight16,
            Divider(
              indent: 16,
              thickness: 0.5,
              color: const Color(0xFF8F959E).withOpacity(0.2),
            ),
          ],
        ));
  }

  void _gotoSelectChannelPage(BuildContext _context) {
    controller.toggleSelectChannel();
    if (OrientationUtil.landscape) {
      Get.lazyPut<WelcomeSettingController>(() {
        return WelcomeSettingController(controller.guildId);
      });
      showSliderModal(_context, body: WelcomeSettingSelectChannelView());
      return;
    }
    Get.toNamed(app_pages.Routes.WELCOME_SETTING_SELECT_CHANNEL,
        parameters: {"guild_id": controller.guildId ?? ''});
  }
}
