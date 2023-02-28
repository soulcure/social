import 'package:flutter/material.dart';

import 'package:get/get.dart';
import 'package:im/pages/bot_market/widget/robot_icon.dart';
import 'package:im/themes/const.dart';
import 'package:im/utils/utils.dart';
import 'package:im/widgets/land_pop_app_bar.dart';

import '../controllers/config_guild_assistant_page_controller.dart';

class LandConfigGuildAssistantPageView extends StatelessWidget {
  final RobotConfigInfo robotConfigInfo;

  const LandConfigGuildAssistantPageView(this.robotConfigInfo);

  @override
  Widget build(BuildContext context) {
    return popWrap(
      height: 498,
      child: GetBuilder<ConfigGuildAssistantPageController>(
          init: ConfigGuildAssistantPageController(robotConfigInfo),
          id: ConfigGuildAssistantPageController.listUpdated,
          builder: (ctr) {
            return Column(
              children: [
                LandPopAppBar(title: '配置服务器助手'.tr, isBackVisible: false),
                Expanded(
                  child: CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(
                        child: _buildHead(),
                      ),
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                            (_, index) => _buildItem(ctr, index),
                            childCount: ctr.bots.length),
                      ),
                    ],
                  ),
                ),
                _buildBottom(ctr, context),
              ],
            );
          }),
    );
  }

  Widget _buildItem(controller, int idx) {
    final botInfo = controller.bots[idx];
    return Container(
      margin: const EdgeInsets.fromLTRB(0, 4, 0, 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Get.theme.backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Get.theme.dividerTheme.color),
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
          padding: const EdgeInsets.fromLTRB(36, 20, 36, 12),
          // color: Colors.yellow,
          child: Text(
            "我们为你的服务器配备了以下机器人助手，你还可以在机器人市场中添加更多机器人。".tr,
            textAlign: TextAlign.center,
            style: Get.textTheme.bodyText1.copyWith(fontSize: 14),
          )),
    );
  }

  Widget _buildBottom(controller, BuildContext context) {
    return Container(
      alignment: Alignment.bottomRight,
      margin: const EdgeInsets.only(top: 16, bottom: 16),
      child: TextButton(
        style: TextButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          minimumSize: const Size(88, 32),
          padding: const EdgeInsets.all(16),
          backgroundColor: Theme.of(context).primaryColor,
        ),
        onPressed: () => controller.onNextDialog(),
        child: Text(
          "我知道了".tr,
          style: TextStyle(fontSize: 14, color: Get.theme.backgroundColor),
        ),
      ),
    );
  }
}
