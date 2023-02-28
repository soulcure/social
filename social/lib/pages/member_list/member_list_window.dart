import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/api/data_model/user_info.dart';
import 'package:im/app/modules/home/controllers/home_scaffold_controller.dart';
import 'package:im/app/routes/app_pages.dart' as app_pages;
import 'package:im/common/permission/permission.dart';
import 'package:im/common/permission/permission_model.dart';
import 'package:im/common/permission/permission_utils.dart';
import 'package:im/icon_font.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/pages/member_list/widgets/channel_notify_switchers.dart';
import 'package:im/pages/member_list/widgets/function_item.dart';
import 'package:im/routes.dart';
import 'package:im/themes/const.dart';
import 'package:im/themes/custom_color.dart';
import 'package:im/utils/orientation_util.dart';
import 'package:im/web/pages/member_list/member_window.dart';
import 'package:im/widgets/custom_route_page/custom_route_model.dart';
import 'package:im/widgets/list_physics.dart';
import 'package:im/widgets/realtime_user_info.dart';
import 'package:im/widgets/segment_list/segment_member_list.dart';
import 'package:im/widgets/share_link_popup/share_link_popup.dart';
import 'package:im/widgets/top_status_bar.dart';

import '../../global.dart';
import '../home/home_page.dart';
import 'item_renderer/text_chat_member_item_renderer.dart';
import 'widgets/channel_topic.dart';

class MemberListWindow extends StatelessWidget {
  final CustomRouteModel model;

  const MemberListWindow({this.model});

  /// 构建频道名称，描述的区域
  Widget _buildTitleBar(BuildContext context) {
    final _theme = Theme.of(context);
    return Container(
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
          color: CustomColor(context).backgroundColor5,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(8))),
      child: ValueListenableBuilder<ChatChannel>(
          valueListenable: GlobalState.selectedChannel,
          builder: (context, channel, child) {
            if (channel == null) return const SizedBox();
            Widget firstLine;
            if (channel.type == ChatChannelType.dm)

              /// 私聊时，标题为聊天对象的用户名
              firstLine = Row(
                children: <Widget>[
                  const Icon(IconFont.buffTabAt, size: 20),
                  sizeWidth8,
                  Expanded(
                    child: RealtimeNickname(
                      userId: channel.guildId,
                      style: Theme.of(context)
                          .textTheme
                          .bodyText2
                          .copyWith(fontSize: 20),
                      showNameRule: ShowNameRule.remarkAndGuild,
                    ),
                  ),
                  const SizedBox(height: 48)
                ],
              );
            else

              /// 频道内，标题为频道名称
              firstLine = Container(
                alignment: Alignment.centerLeft,
                height: 48,
                child: RealtimeChannelName(
                  channel.id,
                  style: _theme.textTheme.bodyText2.copyWith(
                    fontSize: 17,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                firstLine,
                ChannelTopic(channel),
              ],
            );
          }),
    );
  }

  /// 构建功能组件栏，例如：搜索，Pin，通知等
  Widget _buildFunctionBar(BuildContext context) {
    return ValueListenableBuilder<ChatChannel>(
      valueListenable: GlobalState.selectedChannel,
      builder: (context, channel, _) {
        /// 私聊时不展示功能组件栏
        if (channel == null || channel.type == ChatChannelType.dm) {
          return const SizedBox();
        }
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 66,
              child: Row(
                children: [
                  /// 搜索功能组件
                  FunctionItem(
                    label: "搜索".tr,
                    icon: IconFont.buffCommonSearch,
                    onTap: () =>
                        Routes.pushSearchMessagePage(context, channel.guildId),
                  ),

                  /// 非私聊时才展示消息屏蔽功能组件
                  if (channel.type != ChatChannelType.dm)
                    Expanded(child: ChannelNotifySwitchers(channel.id)),

                  /// 非私聊时才展示邀请功能组件
                  if (channel.type != ChatChannelType.dm)
                    ValidPermission(
                      channelId: channel.id,
                      permissions: [Permission.CREATE_INSTANT_INVITE],
                      builder: (hasPermission, isOwner) {
                        return FunctionItem(
                          label: "邀请".tr,
                          icon: IconFont.buffModuleMenuOpen,
                          enable: hasPermission,
                          onTap: () =>
                              showShareLinkPopUp(context, channel: channel),
                        );
                      },
                    ),

                  /// 设置功能组件
                  ValidPermission(
                    channelId: channel.id,
                    permissions: [
                      Permission.MANAGE_CHANNELS,
                      Permission.MANAGE_ROLES,
                    ],
                    builder: (hasPermission, isOwner) {
                      /// 有设置权限，展示设置按钮
                      return FunctionItem(
                        label: "设置".tr,
                        icon: IconFont.buffSetting,
                        enable: hasPermission,
                        onTap: () =>
                            Routes.pushModifyChannelPage(context, channel),
                      );
                    },
                  ),
                ],
              ),
            ),
            const Divider(),
          ],
        );
      },
    );
  }

  Widget _buildChannelManager(BuildContext context) {
    return ValueListenableBuilder<ChatChannel>(
      valueListenable: GlobalState.selectedChannel,
      builder: (context, channel, _) {
        if (channel == null || channel.type == ChatChannelType.dm) {
          return const SizedBox();
        }
        final gp = PermissionModel.getPermission(channel.guildId);
        final bool isPrivate = PermissionUtils.isPrivateChannel(gp, channel.id);
        if (!isPrivate) {
          return const SizedBox();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            sizeHeight4,
            ValidPermission(
              channelId: channel.id,
              permissions: [Permission.MANAGE_ROLES],
              builder: (hasPermission, isOwner) {
                if (!hasPermission) return const SizedBox();
                return GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: () => Get.toNamed(
                      app_pages.Routes.PRIVATE_CHANNEL_ACCESS_PAGE,
                      arguments: channel),
                  child: Container(
                    height: 58,
                    margin: const EdgeInsets.only(left: 16),
                    child: Row(
                      children: [
                        Container(
                            decoration: BoxDecoration(
                                color: const Color(0xFF8F959E).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(16)),
                            alignment: Alignment.center,
                            height: 32,
                            width: 32,
                            child: const Icon(
                              IconFont.buffRoleIconChannelSetting,
                              size: 20,
                            )),
                        sizeWidth16,
                        Text(
                          '管理频道访问'.tr,
                          style: const TextStyle(
                            color: Color(0xFF1F2126),
                            fontSize: 16,
                            height: 1.25,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildSegmentMemberList(BuildContext context) {
    /// todo 思考有没有更好的方案，在切换私信时更新
    return ValueListenableBuilder(
      valueListenable: GlobalState.selectedChannel,
      builder: (_, channel, c) {
        if (channel?.type == ChatChannelType.dm) {
          return Expanded(
              child:
                  CustomScrollView(physics: const SlowListPhysics(), slivers: [
            SliverToBoxAdapter(
              child: Container(
                color: Colors.white,
                height: 50,
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.fromLTRB(16, 21, 16, 12),
                child: Text(
                  "成员-2".tr,
                  style: Theme.of(context)
                      .textTheme
                      .bodyText1
                      .copyWith(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: UserInfo.consume(Global.user.id,
                  builder: (context, user, child) {
                return TextChatMemberItemRenderer(
                  user,
                  channelId: channel.id,
                );
              }),
            ),
            SliverToBoxAdapter(
              child: UserInfo.consume(channel?.recipientId ?? channel?.guildId,
                  builder: (context, user, child) {
                return TextChatMemberItemRenderer(
                  user,
                  channelId: channel.id,
                );
              }),
            ),
          ]));
        } else if (channel?.type == ChatChannelType.guildLive) {
          return const Expanded(child: SizedBox());
        } else {
          final guildId = GlobalState.selectedChannel.value?.guildId;
          final channelId = GlobalState.selectedChannel.value?.id;
          final channelType = GlobalState.selectedChannel.value?.type;
          return Expanded(
            // child: SegmentMemberList(GlobalState.selectedChannel.value != null
            //     ? TextChannelController.to()?.segmentMemberListViewModel
            //     : null),
            child: (guildId == null || channelId == null || channelType == null)
                ? const SizedBox()
                : SegmentMemberList(guildId, channelId, channelType),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final orientation = MediaQuery.of(context).orientation;
    final child = Container(
      padding: OrientationUtil.portrait
          ? const EdgeInsets.only(left: 8)
          : const EdgeInsets.all(0),
      color: Colors.transparent,
      child: ValueListenableBuilder(
        valueListenable: TopStatusController.to().showStatusUI,
        builder: (context, errorVisible, child) => AnimatedContainer(
          duration: kThemeAnimationDuration,
          margin: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top +
                  ((errorVisible && OrientationUtil.portrait)
                      ? TopStatusBar.height
                      : orientation == Orientation.portrait
                          ? HomeScaffoldController.to.windowPadding
                          : 0)),
          decoration: OrientationUtil.portrait
              ? HomePage.getWindowDecorator(context)
              : BoxDecoration(color: Theme.of(context).backgroundColor),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              /// 竖屏模式时显示标题栏，展示频道名称和描述
              if (OrientationUtil.portrait) ...[
                _buildTitleBar(context),
                const Divider(),

                /// 展示功能组件按钮栏
                _buildFunctionBar(context),
                _buildChannelManager(context),
              ] else
                const Divider(),

              /// 展示成员列表
              // _buildMemberList(),
              _buildSegmentMemberList(context),
            ],
          ),
        ),
      ),
    );
    if (OrientationUtil.portrait)
      return SizedBox(
        width: 250,
        child: child,
      );
    else
      return MemberWindow(
        defaultChild: SizedBox(
          width: 220,
          child: child,
        ),
      );
  }
}
