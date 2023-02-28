import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/app/modules/welcome_setting/controllers/welcome_setting_controller.dart';
import 'package:im/common/extension/string_extension.dart';
import 'package:im/common/permission/permission.dart';
import 'package:im/common/permission/permission_model.dart';
import 'package:im/common/permission/permission_utils.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/themes/const.dart';
import 'package:im/widgets/app_bar/appbar_button.dart';
import 'package:im/widgets/app_bar/custom_appbar.dart';
import 'package:im/widgets/button/more_icon.dart';
import 'package:im/widgets/channel_icon.dart';
import 'package:im/widgets/fb_check_box.dart';
import 'package:oktoast/oktoast.dart';

import '../../../../routes.dart';

class WelcomeSettingSelectChannelView
    extends GetView<WelcomeSettingController> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppbar(
        title: '选择频道'.tr,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        actions: [
          AppbarTextButton(
            onTap: () async {
              final String errMsg = await controller.onSaved();
              if (errMsg.hasValue) showToast(errMsg);
            },
            text: '保存'.tr,
          ),
        ],
      ),
      body: GetBuilder<WelcomeSettingController>(
        id: WelcomeSettingController.toSelectedChannelList,
        builder: (c) {
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                  child: Text(
                    '请选择最多5个频道'.tr,
                    style: Theme.of(context)
                        .textTheme
                        .bodyText1
                        .copyWith(fontSize: 13),
                  ),
                ),
              ),
              SliverFixedExtentList(
                delegate: SliverChildBuilderDelegate(_buildChannelItem,
                    childCount: controller.allChannels.length),
                itemExtent: 66,
              )
            ],
          );
        },
      ),
    );
  }

  Widget _buildChannelItem(BuildContext context, int index) {
    final ChatChannel channel = controller.allChannels[index];
    final GuildPermission gp = PermissionModel.getPermission(channel.guildId);
    final bool isPrivateChannel =
        PermissionUtils.isPrivateChannel(gp, channel.id);
    return Container(
      padding: const EdgeInsets.fromLTRB(0, 0, 16, 0),
      color: Colors.white,
      child: Row(
        children: [
          const SizedBox(width: 16),
          FBCheckBox(
            value: controller.isChannelSelected(channel),
            onChanged: (v) {
              final String errMsg = controller.selectChannel(channel, v);
              if (errMsg.hasValue) {
                showToast(errMsg);
              }
            },
          ),
          const SizedBox(width: 16),
          Expanded(
              child: GestureDetector(
            onTap: () {
              Routes.pushModifyChannelPage(context, channel);
            },
            child: Container(
                decoration: BoxDecoration(
                    border: Border(
                        bottom: BorderSide(
                            width: 0.5,
                            color: const Color(0xFF8F959E).withOpacity(0.2)))),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              //图标
                              ChannelIcon(channel.type,
                                  private: isPrivateChannel,
                                  size: 16,
                                  color: const Color(0xFF1F2125)),
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
                          sizeHeight8,
                          Text(
                              channel.topic.hasValue
                                  ? channel.topic
                                  : '未设置频道介绍'.tr,
                              softWrap: false,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 13,
                                  height: 1.23,
                                  color: Color(0xFF646A73))),
                        ],
                      ),
                    ),
                    MoreIcon(
                      color: const Color(0xFF363940).withOpacity(0.35),
                    ),
                  ],
                )),
          ))
        ],
      ),
    );
  }
}
