import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/api/entity/bot_info.dart';
import 'package:im/app/modules/bot_detail_page/bindings/bot_detail_page_binding.dart';
import 'package:im/common/extension/string_extension.dart';
import 'package:im/pages/bot_market/bot_utils.dart';
import 'package:im/pages/bot_market/model/bot_market_controller.dart';
import 'package:im/pages/bot_market/widget/add_button.dart';
import 'package:im/pages/bot_market/widget/bot_command_item.dart';
import 'package:im/pages/bot_market/widget/bot_description.dart';
import 'package:im/pages/bot_market/widget/guild_nickname_setting.dart';
import 'package:im/pages/bot_market/widget/robot_icon.dart';
import 'package:im/themes/const.dart';
import 'package:im/widgets/app_bar/appbar_action_model.dart';
import 'package:im/widgets/app_bar/appbar_builder.dart';
import 'package:im/widgets/fb_ui_kit/button/button_builder.dart';
import 'package:im/widgets/id_with_copy.dart';
import 'package:im/widgets/link_tile.dart';
import 'package:im/widgets/refresh/net_checker.dart';

import '../controllers/bot_detail_page_controller.dart';

/// - 机器人详情页面
// ignore: must_be_immutable
class BotDetailPageView extends GetView<BotDetailPageController> {
  static String botId;

  @override
  BotDetailPageController get controller =>
      Get.find<BotDetailPageController>(tag: botId);

  @override
  Widget build(BuildContext context) {
    if (Get.arguments is BotDetailPageParams) {
      botId = (Get.arguments as BotDetailPageParams).botId;
    }
    return Scaffold(
      backgroundColor: Get.theme.scaffoldBackgroundColor,
      appBar: PreferredSize(
          preferredSize: const Size(double.infinity, kFbAppBarHeight),
          child: GetBuilder<BotDetailPageController>(
              tag: botId, builder: (_) => _assembleAppBarView())),
      body: GetBuilder<BotDetailPageController>(
        tag: botId,
        builder: (c) => NetChecker(
          futureGenerator: c.fetchBotInfo,
          retry: c.update,
          errorBuilder: _buildErrorView,
          builder: (_) => _assembleBodyView(context),
        ),
      ),
    );
  }

  Widget _buildTitle(String title, {Color color, double paddingBottom = 10}) {
    return Container(
      color: color,
      padding: EdgeInsets.fromLTRB(16, 16, 16, paddingBottom),
      child: Text(
        title,
        style: const TextStyle(fontSize: 14, color: Color(0xFF5C6273)),
      ),
    );
  }

  Widget _buildErrorView() {
    // 机器人被开发者删除
    return TextButton(
      onPressed: controller.removeBot,
      child: Text("该机器人已被开发者删除，点击移除".tr),
    );
  }

  Widget _buildCommandInfo(BotInfo bot) {
    final shouldShowGuildNickname = controller.guildNickname.hasValue;
    final mediumStyle = Get.textTheme.bodyText2
        .copyWith(fontSize: 20, fontWeight: FontWeight.w500);
    final commonStyle = Get.textTheme.bodyText2
        .copyWith(fontSize: 14, color: const Color(0xFF5C6273));
    final botNameText =
        '${shouldShowGuildNickname ? '昵称: '.tr : ''}${bot.botName}';
    final botNameStyle = shouldShowGuildNickname ? commonStyle : mediumStyle;
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          sizeHeight12,
          Row(
            children: [
              RobotAvatar(
                url: bot.botAvatar,
                radius: 32,
              ),
              spacer,
              AddButton(
                addedText: '移除'.tr,
                width: 68,
                buttonType: controller.isAdded
                    ? FbButtonType.subElevated
                    : FbButtonType.elevated,
                status: controller.isAdded
                    ? AddedStatus.Added
                    : AddedStatus.UnAdded,
                onAdd: () => controller.onAdd(bot),
                unAddInterceptor:
                    Get.find<BotMarketPageController>().showRemoveRobotDialog,
                onUnAdded: () => controller.onUnAdded(bot),
                keepNormal: true,
              )
            ],
          ),
          sizeHeight16,
          if (shouldShowGuildNickname) ...[
            Text(
              controller.guildNickname,
              style: mediumStyle,
            ),
            sizeHeight6,
          ],
          Text(
            botNameText,
            style: botNameStyle,
          ),
          if (bot.username.hasValue) ...[
            sizeHeight8,
            IdWithCopy(bot.username),
          ],
          sizeHeight14,
          BotDescription(
            description: bot.botDescription,
          ),
        ],
      ),
    );
  }

  Widget _buildCommandList(BotInfo robot) {
    final commands = robot.commands ?? [];
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
        final command = robot.commands[index];
        return BotCommandCardItem(command: command);
      }, childCount: commands.length)),
    );
  }

  Widget _buildGuildSettings(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Column(
          children: [
            LinkTile(
              context,
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '机器人在本服务器的昵称'.tr,
                    style: Get.textTheme.bodyText2
                        .copyWith(fontWeight: FontWeight.w500),
                  ),
                  if (controller.guildNickname.hasValue) ...[
                    sizeHeight5,
                    Text(
                      controller.guildNickname,
                      style: Theme.of(context)
                          .textTheme
                          .bodyText1
                          .copyWith(fontSize: 14),
                    ),
                  ]
                ],
              ),
              onTap: () {
                showGuildNicknameSettingPopup(context,
                    guildId: controller.guildId, botId: controller.botId);
              },
            ),
            Container(
              color: Colors.white,
              padding: const EdgeInsets.only(left: 16),
              child: const Divider(
                height: 0.5,
              ),
            ),
            LinkTile(
                context,
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      "接收所有频道消息".tr,
                      style: Get.textTheme.bodyText2
                          .copyWith(fontWeight: FontWeight.w500),
                    ),
                    sizeHeight5,
                    Text(
                      "打开后，将授权此机器人接收所有频道的消息用于统计，包括私密频道".tr,
                      style: Theme.of(context).textTheme.bodyText1.copyWith(
                            fontSize: 14,
                            color: Get.theme.disabledColor,
                          ),
                    )
                  ],
                ),
                showTrailingIcon: false,
                trailing: Row(
                  children: <Widget>[
                    Transform.scale(
                      scale: 0.85,
                      alignment: Alignment.centerRight,
                      child: CupertinoSwitch(
                        trackColor: const Color(0xFF8D93A6).withOpacity(0.2),
                        activeColor: Theme.of(context).primaryColor,
                        value: controller.addedValue,
                        onChanged: controller.toggleAdd,
                      ),
                    )
                  ],
                ))
          ],
        ),
      ),
    );
  }

  /// 组装视图：AppBar
  FbAppBar _assembleAppBarView() {
    final robot = controller.bot;
    if (robot == null) return const FbAppBar.custom("");

    /// 如果标题栏右侧按钮数据为空则创建，不为空则跳过，避免重复刷新
    if (controller.actionModels.isEmpty) {
      controller.actionModels.add(AppBarTextPrimaryActionModel(
        "添加",
        alpha: controller.appBarElementAlpha,
        actionBlock: () => controller.onAdd(robot),
      ));
      controller.actionModels.add(AppBarTextLightActionModel("移除",
          alpha: controller.appBarElementAlpha,
          actionBlock: () => Get.find<BotMarketPageController>()
                  .showRemoveRobotDialog()
                  .then((value) {
                if (!value) return;
                controller.onUnAdded(robot);
              })));
    }
    return FbAppBar.diyTitleView(
      titleBuilder: (context, style) => Opacity(
        opacity: controller.appBarElementAlpha,
        child: RobotAvatar(
          url: robot.botAvatar,
          radius: 14,
        ),
      ),
      actions: [
        if (controller.isAdded)
          controller.actionModels.last
        else
          controller.actionModels.first
      ],
    );
  }

  /// 组装视图：body视图
  Widget _assembleBodyView(BuildContext context) {
    final robot = controller.bot;
    return CustomScrollView(
      controller: controller.scrollCtl,
      slivers: [
        SliverToBoxAdapter(
          child: _buildCommandInfo(robot),
        ),
        if (controller.isAdded)
          SliverToBoxAdapter(
            child: _buildGuildSettings(context),
          ),
        if ((robot.commands ?? []).isNotEmpty) ...[
          SliverToBoxAdapter(
            child: _buildTitle('机器人功能'.tr),
          ),
          _buildCommandList(robot),
        ],
        if (robot.permissions > 0) ...[
          SliverToBoxAdapter(
            child: _buildTitle('机器人权限'.tr),
          ),
          const SliverToBoxAdapter(
            child: sizeHeight6,
          ),
          SliverToBoxAdapter(
            child: LinkTile(
              context,
              Text('机器人所需权限'.tr),
              height: 52,
              borderRadius: 6,
              onTap: () => controller.showRequiredPermissions(robot),
            ).marginOnly(top: 0, bottom: 12, left: 16, right: 16),
          ),
        ],
        SliverToBoxAdapter(
          child: SizedBox(
            height: MediaQuery.of(context).viewPadding.bottom,
          ),
        ),
      ],
    );
  }
}
