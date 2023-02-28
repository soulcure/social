import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/api/data_model/user_info.dart';
import 'package:im/app/modules/home/controllers/home_scaffold_controller.dart';
import 'package:im/common/permission/permission.dart';
import 'package:im/icon_font.dart';
import 'package:im/pages/home/home_page.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/pages/member_list/item_renderer/text_chat_member_item_renderer.dart';
import 'package:im/pages/member_list/widgets/channel_notify_switchers.dart';
import 'package:im/pages/member_list/widgets/function_item.dart';
import 'package:im/routes.dart';
import 'package:im/utils/orientation_util.dart';
import 'package:im/widgets/app_bar/appbar_builder.dart';
import 'package:im/widgets/list_physics.dart';
import 'package:im/widgets/segment_list/segment_member_list.dart';
import 'package:im/widgets/top_status_bar.dart';

import '../../../../global.dart';

class GroupMemberList extends StatelessWidget {
  final ChatChannel channel;

  const GroupMemberList({this.channel});

  /// 构建功能组件栏，例如：搜索，Pin，通知等
  Widget _buildFunctionBar(BuildContext context) {
    Widget _buildFunctionBarWidget(ChatChannel channel) {
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
                  // onTap: () => Routes.pushSearchMessagePage(
                  //     channel.guildId, channel.id),
                  onTap: () {
                    ///fix 兼容部落群聊搜索 guildId="0"
                    if (channel.type == ChatChannelType.group_dm) {
                      Routes.pushSearchMessagePage(context, channel.guildId,
                          channelId: channel.id);
                    } else {
                      Routes.pushSearchMessagePage(context, channel.guildId);
                    }
                  },
                ),

                /// 非私聊时才展示消息屏蔽功能组件
                if (channel.type != ChatChannelType.dm)
                  Expanded(child: ChannelNotifySwitchers(channel.id)),

                /// 非私聊时才展示邀请功能组件
                ValidPermission(
                  channelId: channel.id,
                  permissions: [Permission.CREATE_INSTANT_INVITE],
                  builder: (hasPermission, isOwner) {
                    return FunctionItem(
                      label: "邀请".tr,
                      icon: IconFont.buffModuleMenuOpen,
                      enable: false,
                      // onTap: () =>
                      //     showShareLinkPopUp(context, channel: channel),
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
                      enable: false,
                      // onTap: () =>
                      //     Routes.pushModifyChannelPage(context, channel),
                    );
                  },
                ),
              ],
            ),
          ),
          const Divider(),
        ],
      );
    }

    if (channel != null) return _buildFunctionBarWidget(channel);
    return ValueListenableBuilder<ChatChannel>(
      valueListenable: GlobalState.selectedChannel,
      builder: (context, channel, _) => _buildFunctionBarWidget(channel),
    );
  }

  Widget _buildSegmentMemberList(BuildContext context) {
    Widget _buildSegmentMemberListWidget(ChatChannel channel) {
      if (channel?.type == ChatChannelType.dm) {
        return Expanded(
            child: CustomScrollView(physics: const SlowListPhysics(), slivers: [
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
              return TextChatMemberItemRenderer(user);
            }),
          ),
          SliverToBoxAdapter(
            child: UserInfo.consume(channel?.recipientId ?? channel?.guildId,
                builder: (context, user, child) {
              return TextChatMemberItemRenderer(user);
            }),
          ),
        ]));
      } else if (channel?.type == ChatChannelType.guildLive) {
        return const Expanded(child: SizedBox());
      } else if (channel?.type == ChatChannelType.group_dm) {
        return Expanded(
          child: SegmentMemberList(
              channel.guildId, channel.id, ChatChannelType.group_dm),
        );
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
    }

    if (channel != null)
      return _buildSegmentMemberListWidget(channel);
    else

      /// todo 思考有没有更好的方案，在切换私信时更新
      return ValueListenableBuilder(
        valueListenable: GlobalState.selectedChannel,
        builder: (_, channel, c) => _buildSegmentMemberListWidget(channel),
      );
  }

  // Widget _backItem() {
  //   return FadeButton(
  //     onTap: () {
  //       Get.back();
  //     },
  //     child: Container(
  //       alignment: Alignment.centerLeft,
  //       padding: const EdgeInsets.only(left: 4),
  //       width: 60,
  //       child: const Icon(
  //         IconFont.buffNavBarBackItem,
  //         size: 24,
  //       ),
  //     ),
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    final orientation = MediaQuery.of(context).orientation;
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Theme.of(context).backgroundColor,
      appBar: FbAppBar.diyTitleView(
        titleBuilder: (context, style) {
          return Text(
            (channel ?? GlobalState.selectedChannel?.value)?.name,
            style: style,
          );
        },
      ),
      body: ValueListenableBuilder(
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
                //const Divider(),

                /// 展示功能组件按钮栏
                _buildFunctionBar(context),
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
  }
}
