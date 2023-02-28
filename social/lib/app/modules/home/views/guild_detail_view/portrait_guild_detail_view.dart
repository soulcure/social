import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:get/get.dart';
import 'package:im/app/modules/guide/components/task_status_panel.dart';
import 'package:im/app/modules/home/views/components/chat_index/guild_banner/portrait_guild_banner_state.dart';
import 'package:im/app/modules/home/views/components/chat_index/guild_banner/sliver_guild_banner.dart';
import 'package:im/app/modules/manage_guild/models/ban_type.dart';
import 'package:im/app/modules/task/introduction_ceremony/views/task_introduction_tips.dart';
import 'package:im/app/modules/task/task_util.dart';
import 'package:im/app/routes/app_pages.dart' as get_pages;
import 'package:im/app/theme/app_theme.dart';
import 'package:im/common/extension/string_extension.dart';
import 'package:im/common/permission/permission.dart';
import 'package:im/community/community_util.dart';
import 'package:im/core/widgets/button/fade_button.dart';
import 'package:im/icon_font.dart';
import 'package:im/pages/chat_index/components/guild_channel_list/portrait_guild_channel_list.dart';
import 'package:im/pages/guild_setting/circle/entry/cross_platform_circle_entry_view.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/pages/home/view/tab_bar.dart';
import 'package:im/quest/fb_quest_config.dart';
import 'package:im/themes/const.dart';
import 'package:im/utils/check_media_conflict_util.dart';
import 'package:im/widgets/share_link_popup/share_link_popup.dart';
import 'package:im/widgets/super_tooltip.dart';
import 'package:provider/provider.dart';
import 'package:quest_system/quest_system.dart';

import 'frozen_operation_widget.dart';

class PortraitGuildDetailView extends StatefulWidget {
  const PortraitGuildDetailView({
    Key key,
    @required this.target,
  }) : super(key: key);

  final BaseChatTarget target;

  @override
  _PortraitGuildDetailViewState createState() =>
      _PortraitGuildDetailViewState();
}

class _PortraitGuildDetailViewState extends State<PortraitGuildDetailView> {
  // 列表滚动距离是否为0
  bool isAtTop = false;

  // 列表下拉的高度
  double bannerExtraHeight = 0;

  // 当前context最大宽度
  double maxWidth = 0;

  // banner的固定高度
  double get bannerHeight => maxWidth * 0.5;

  // 除去HomeTabBar以外，底部的安全区域高度
  double get safePaddingBottom =>
      HomeTabBar.height + Get.mediaQuery.padding.bottom;

  // 滚动偏移量
  RxDouble rxScrollOffset = RxDouble(0);

  final ScrollController _controller = ScrollController();

  @override
  void dispose() {
    rxScrollOffset?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      maxWidth = constraints.maxWidth;
      return ChangeNotifierProvider.value(
        value: widget.target,
        child: Stack(
          children: [
            NotificationListener<Notification>(
              onNotification: _onNotification,
              child: ClipRRect(
                borderRadius: PortraitGuildBannerState.borderRadius,
                child: CustomScrollView(
                    controller: _controller,
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverGuildBanner(
                        height: bannerHeight,
                        target: widget.target,
                        rxScrollOffset: rxScrollOffset,
                      ),
                      SliverToBoxAdapter(
                        child: QuestBuilder<QuestGroup>.id(
                            QuestId([
                              QIDSegGroup.quickStart,
                              "-",
                              widget.target.id
                            ]), builder: (quest) {
                          if (quest == null ||
                              quest.status == QuestStatus.completed)
                            return ValidPermission(
                              permissions: [
                                Permission.CREATE_INSTANT_INVITE,
                              ],
                              builder: (value, isOwner) {
                                if (value)
                                  return _inviteWidget(context);
                                else
                                  return const SizedBox();
                              },
                            );

                          return TaskStatusPanel(questGroup: quest);
                        }),
                      ),
                      if (widget.target is GuildTarget &&
                          ((widget.target as GuildTarget).virtualDisplay ??
                              false))
                        SliverToBoxAdapter(child: _communityWidget(context)),
                      if (widget.target != null)
                        SliverToBoxAdapter(
                            child: CrossPlatformCircleEntryView(
                                key: ValueKey(widget.target.id))),
                      SliverToBoxAdapter(
                        child: Divider(
                          color: appThemeData.dividerColor.withOpacity(0.1),
                          height: .5,
                        ),
                      ),
                      PortraitGuildChannelList(),
                      SliverToBoxAdapter(
                        child: ObxValue<RxBool>((rxIsShow) {
                          final height = safePaddingBottom +
                              (rxIsShow.value
                                  ? (kTaskIntroductionHeight + 30)
                                  : 0);
                          return SizedBox(
                            height: height,
                          );
                        }, TaskUtil.instance.isNewGuy),
                      ),
                    ]),
              ),
            ),
            ObxValue<RxBool>((rxIsShow) {
              if (!rxIsShow.value) return sizedBox;
              return Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: EdgeInsets.only(bottom: safePaddingBottom),
                  child: ObxValue<RxString>((title) {
                    return TaskIntroductionTips(
                      taskStyle: TaskStyle.Channel,
                      content: title?.value?.hasValue ?? false
                          ? title?.value
                          : '完成新成员验证，开始畅聊'.tr,
                    );
                  }, TaskUtil.instance.taskEntityTitle),
                ),
              );
            }, TaskUtil.instance.isNewGuy),
            _buildBanGuild(context),
          ],
        ),
      );
    });
  }

  // 封控ui
  Widget _buildBanGuild(BuildContext context) {
    return ObxValue<Rx<BanType>>((_) {
      final isBan = (widget.target as GuildTarget).isBan;
      if (!isBan) return const SizedBox();
      return Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(8), topRight: Radius.circular(8)),
          color: Colors.white,
        ),
        child: Column(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
            alignment: Alignment.centerLeft,
            child: Text(widget?.target?.name ?? '',
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: Theme.of(context).textTheme.bodyText2),
          ),
          const Spacer(),
          const Icon(IconFont.buffRoundExclamations,
              size: 44, color: Colors.red),
          const SizedBox(height: 26),
          Text(
            '本服务器已被封禁，暂时无法浏览'.tr,
            style: TextStyle(color: appThemeData.iconTheme.color, fontSize: 15),
          ),
          const SizedBox(height: 48),
          FrozenOperationWidget(),
          const Spacer(flex: 2),
        ]),
      );
    }, (widget.target as GuildTarget).bannedLevel);
  }

  Padding _communityWidget(BuildContext context) {
    final displayName =
        CommunityUtil.getVirtualParameter('name', defaultValue: '虚拟社区'.tr);
    return Padding(
      padding: const EdgeInsets.only(top: 10, left: 12, right: 12, bottom: 2),
      child: FadeButton(
        throttleDuration: const Duration(seconds: 1),
        onTap: () async {
          var flag = await CommunityUtil.checkAppVersionSuitable(context);
          if (!flag) return;

          flag = await checkAndExitAVChannel(purpose: "进入".tr + displayName);
          if (!flag) return;

          flag = await checkAndExitLiveRoom(purpose: "进入".tr + displayName);
          if (!flag) return;

          await Get.toNamed(get_pages.Routes.UNITY_VIEW_PAGE);
        },
        padding: const EdgeInsets.symmetric(vertical: 7.5),
        decoration: BoxDecoration(
          color: appThemeData.primaryColor.withOpacity(.1),
          borderRadius: BorderRadius.circular(5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              IconFont.buffIconCommunity,
              size: 16,
              color: appThemeData.primaryColor,
            ),
            sizeWidth6,
            Text(
              displayName,
              style: TextStyle(
                color: appThemeData.primaryColor,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
    // return Padding(
    //   padding: const EdgeInsets.only(top: 10, left: 12, right: 12, bottom: 2),
    //   child: GestureDetector(
    //     onTap: () => Get.toNamed(get_pages.Routes.UNITY_VIEW_PAGE),
    //     child: Image.asset("assets/images/btn_community_idreamsky.png"),
    //   ),
    // );
  }

  Padding _inviteWidget(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, left: 12, right: 12, bottom: 2),
      child: FadeButton(
        throttleDuration: const Duration(seconds: 1),
        onTap: () => showShareLinkPopUp(
          context,
          direction: TooltipDirection.right,
          margin: const EdgeInsets.only(left: 204),
        ),
        padding: const EdgeInsets.symmetric(vertical: 7.5),
        decoration: BoxDecoration(
          color: appThemeData.primaryColor.withOpacity(.1),
          borderRadius: BorderRadius.circular(5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              IconFont.buffModuleMenuOpen,
              size: 16,
              color: appThemeData.primaryColor,
            ),
            sizeWidth6,
            Text(
              '邀请成员'.tr,
              style: TextStyle(
                color: appThemeData.primaryColor,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 由于点击折叠频道分类不触发频道分类折叠时需判断滚动距离
  bool _onChannelCateChange(ChannelCateChangeNotification notification) {
    if (!notification.isExpanded) {
      _controller.position.correctBy(0.1);
    }
    return false;
  }

  // 监听滚动通知和频道分类折叠通知
  bool _onNotification(Notification notification) {
    if (notification is ScrollUpdateNotification) {
      rxScrollOffset.value = notification.metrics.pixels;
      return false;
    } else if (notification is ChannelCateChangeNotification) {
      _onChannelCateChange(notification);
      return false;
    } else {
      return true;
    }
  }
}

// 竖屏模式下频道分类折叠拉伸的通知
class ChannelCateChangeNotification extends Notification {
  final bool isExpanded;

  ChannelCateChangeNotification(this.isExpanded);
}
