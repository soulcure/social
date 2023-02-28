import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/api/data_model/user_info.dart';
import 'package:im/api/entity/bot_info.dart';
import 'package:im/app/modules/bot_detail_page/bindings/bot_detail_page_binding.dart';
import 'package:im/app/routes/app_pages.dart' as app_pages;
import 'package:im/common/extension/string_extension.dart';
import 'package:im/pages/bot_market/bot_utils.dart';
import 'package:im/pages/bot_market/model/bot_market_controller.dart';
import 'package:im/pages/bot_market/widget/add_button.dart';
import 'package:im/pages/bot_market/widget/robot_icon.dart';
import 'package:im/pages/home/components/red_dot.dart';
import 'package:im/themes/default_theme.dart';
import 'package:im/utils/orientation_util.dart';
import 'package:im/widgets/app_bar/custom_appbar.dart';
import 'package:im/widgets/avatar.dart';
import 'package:im/widgets/refresh/common_error_widget.dart';
import 'package:im/widgets/svg_tip_widget.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:quest_system/quest_system.dart';

import '../../svg_icons.dart';

class BotMarketPageView extends GetView<BotMarketPageController> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppbar(
        title: '机器人市场'.tr,
      ),
      body: controller.obx(
        (state) {
          return SmartRefresher(
            enablePullDown: false,
            // enablePullUp: false,
            controller: controller.refreshController,
            onLoading: controller.onLoading,
            footer: ClassicFooter(
              idleText: OrientationUtil.portrait ? '上拉加载更多'.tr : '滑动到底部加载更多'.tr,
              loadingText: '加载中'.tr,
              canLoadingText: '上拉加载更多'.tr,
              failedText: '加载失败'.tr,
              noDataText: '没有更多了'.tr,
            ),
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child:
                      _buildTitle("已添加".tr, color: Get.theme.backgroundColor),
                ),
                SliverToBoxAdapter(
                  child: _buildAddedRobotsRow(),
                ),
                SliverToBoxAdapter(
                  child: _buildTitle("全部机器人".tr),
                ),
                _AllRobotsList(),
                SliverToBoxAdapter(
                  child: SizedBox(height: Get.mediaQuery.viewPadding.bottom),
                )
              ],
            ),
          );
        },
        onLoading: DefaultTheme.defaultLoadingIndicator(),
        onError: (e) {
          return CommonErrorMsgWidget(
            errorMsg: e,
            onRetry: Get.find<BotMarketPageController>().initPage,
          );
        },
      ),
    );
  }

  Widget _buildAddedRobotsRow() {
    final bgColor = Theme.of(Get.context).backgroundColor;
    return GetBuilder<BotMarketPageController>(
        id: controller.updateIdAddedBot,
        builder: (c) {
          final robots = c.addedBots;
          if (robots.isEmpty)
            return Container(
              height: 106,
              alignment: Alignment.center,
              color: bgColor,
              child: Text(
                "未添加任何机器人，点击下方添加".tr,
                style: TextStyle(fontSize: 14, color: Get.theme.disabledColor),
              ),
            );
          final int crossNum = ((Get.width - 32) / 68).floor();
          final double rowSpacing = (Get.width - 32) % 68;
          final eachSpacing = rowSpacing / (crossNum - 1);
          return Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              decoration: BoxDecoration(color: bgColor),
              child: Wrap(
                spacing: eachSpacing,
                children: robots.map(_addedItem).toList(),
              ));
        });
  }

  Widget _addedItem(UserInfo bot) {
    return GestureDetector(
        onTap: () async {
          await Get.toNamed(app_pages.Routes.BOT_DETAIL_PAGE,
              arguments: BotDetailPageParams(
                  guildId: controller.guildId, botId: bot.userId));
          controller.update();
        },
        child: Container(
          width: 68,
          height: 82,
          alignment: Alignment.topCenter,
          child: Column(
            children: [
              const SizedBox(height: 4),
              QuestBuilder<Quest>.id(
                  QuestId(BotUtils.getNewBotQuestSegments(
                      controller.guildId, bot.userId)), builder: (quest) {
                final avatar = FlutterAvatar(url: bot.avatar, radius: 24);
                if (quest?.status != QuestStatus.activated) return avatar;
                return RedDotFill(3,
                    radius: 5,
                    borderColor: Get.theme.backgroundColor,
                    offset: const Offset(2, -2),
                    child: FlutterAvatar(url: bot.avatar, radius: 24));
              }),
              const SizedBox(height: 8),
              Text(
                bot.nickname,
                style: const TextStyle(
                    fontSize: 11, height: 1.27, color: Color(0xFF1F2126)),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ));
  }

  Widget _buildTitle(String title, {Color color, double paddingBottom = 4}) {
    return Container(
      color: color,
      padding: EdgeInsets.fromLTRB(16, 16, 16, paddingBottom),
      child: Text(
        title,
        style: const TextStyle(fontSize: 14, color: Color(0xFF5C6273)),
      ),
    );
  }
}

class _AllRobotsList extends GetView<BotMarketPageController> {
  @override
  Widget build(BuildContext context) {
    return GetBuilder<BotMarketPageController>(
        id: controller.updateIdBotList,
        builder: (c) {
          final robots = c.allRobots;
          if (robots.isEmpty) {
            return SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 100),
                child: SvgTipWidget(
                  svgName: SvgIcons.nullState,
                  desc: '暂无机器人'.tr,
                ),
              ),
            );
          }
          return SliverPadding(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
            sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
              (context, index) {
                return _buildItem(robots, index, context);
              },
              childCount: robots.length,
            )),
          );
        });
  }

  GestureDetector _buildItem(
      List<BotInfo> robots, int index, BuildContext context) {
    final model = controller;
    final bot = robots[index];
    final color = Theme.of(Get.context).backgroundColor;
    BoxDecoration decoration;
    if (index == 0) {
      decoration = BoxDecoration(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(8),
            topRight: Radius.circular(8),
          ),
          color: color);
    } else if (index == robots.length - 1) {
      decoration = BoxDecoration(
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(8),
            bottomRight: Radius.circular(8),
          ),
          color: color);
    } else {
      decoration = BoxDecoration(color: color);
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () async {
        await Get.toNamed(app_pages.Routes.BOT_DETAIL_PAGE,
            arguments: BotDetailPageParams(
                guildId: controller.guildId, botId: bot.botId));
        controller.update();
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: decoration,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RobotAvatar(url: bot.botAvatar, radius: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    bot.botName,
                    style: Get.textTheme.bodyText2
                        .copyWith(fontSize: 16, fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  RepaintBoundary(
                    child: Text(
                        bot.botDescription.hasValue
                            ? bot.botDescription
                            : "没有描述信息~".tr,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context).disabledColor)),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            AddButton(
              status: model.isRobotAdded(bot.botId)
                  ? AddedStatus.Added
                  : AddedStatus.UnAdded,
              onAdd: () => model.addRobot(
                UserInfo(
                    userId: bot.botId,
                    avatar: bot.botAvatar,
                    nickname: bot.botName,
                    isBot: true),
                permissions: bot.permissions,
              ),
              unAddInterceptor: model.showRemoveRobotDialog,
              onUnAdded: () => model.removeRobot(bot.botId),
            ),
          ],
        ),
      ),
    );
  }
}
