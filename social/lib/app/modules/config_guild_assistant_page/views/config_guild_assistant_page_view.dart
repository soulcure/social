import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:get/get.dart';
import 'package:im/pages/bot_market/widget/robot_icon.dart';
import 'package:im/themes/const.dart';

import '../controllers/config_guild_assistant_page_controller.dart';

class ConfigGuildAssistantPageView
    extends GetView<ConfigGuildAssistantPageController> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: GetBuilder<ConfigGuildAssistantPageController>(
                id: ConfigGuildAssistantPageController.listUpdated,
                builder: (ctr) {
                  return CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(
                        child: _buildHead(),
                      ),
                      SliverList(
                        delegate: SliverChildBuilderDelegate(_buildItem,
                            childCount: controller.bots.length),
                      ),
                    ],
                  );
                }),
          ),
          _buildBottom(context),
        ],
      ),
    );
  }

  Widget _buildItem(BuildContext context, int idx) {
    final botInfo = controller.bots[idx];
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Get.theme.backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              RobotAvatar(url: botInfo.botAvatar, radius: 24),
              sizeWidth16,
              Text(
                botInfo.botName,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: Get.textTheme.bodyText2.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          sizeHeight12,
          Text(
            botInfo.botDescription,
            style: Get.textTheme.bodyText1.copyWith(fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildHead() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(36, 0, 36, 32),
        // color: Colors.yellow,
        child: Column(
          children: [
            const SizedBox(height: 76),
            Text(
              "配置服务器助手".tr,
              style: Get.textTheme.bodyText2.copyWith(
                fontSize: 22,
                fontWeight: FontWeight.w500,
              ),
            ),
            sizeHeight24,
            Text(
              "我们为你的服务器配备了以下机器人助手，你还可以在机器人市场中添加更多机器人。".tr,
              textAlign: TextAlign.center,
              style: Get.textTheme.bodyText1.copyWith(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottom(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(0, 0, 0, 24),
        child: TextButton(
          style: TextButton.styleFrom(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            minimumSize: const Size(240, 40),
            backgroundColor: Theme.of(context).primaryColor,
          ),
          onPressed: controller.onNext,
          child: Text(
            "我知道了".tr,
            style: TextStyle(fontSize: 16, color: Get.theme.backgroundColor),
          ),
        ),
      ),
    );
  }
}
