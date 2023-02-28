import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/app/modules/home/views/guild_detail_view/portrait_guild_detail_view.dart';
import 'package:im/common/permission/permission.dart';
import 'package:im/common/permission/permission_mixin.dart';
import 'package:im/common/permission/permission_model.dart';
import 'package:im/common/permission/permission_utils.dart';
import 'package:im/pages/chat_index/components/channel_item_listener_builder.dart';
import 'package:im/pages/home/model/chat_index_model.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/themes/const.dart';
import 'package:im/utils/show_action_sheet.dart';
import 'package:pedantic/pedantic.dart';

import '../../../../routes.dart';
import '../channel_list_listener_builder.dart';
import '../ui_category_item.dart';
import '../ui_channel_no_permission_alert.dart';
import 'guild_channel_list.dart';

class PortraitGuildChannelList extends StatefulWidget {
  @override
  _PortraitGuildChannelListState createState() =>
      _PortraitGuildChannelListState();
}

class _PortraitGuildChannelListState extends State<PortraitGuildChannelList>
    with GuildPermissionListener
    implements GuildChannelListContent {
  bool hasManagePermission = false;

  /// TODO: 2021/12/20 监听会导致多次被调用，应该采用判断当前路由来处理
  bool isShowPermissionAlert = false;

  @override
  void initState() {
    addPermissionListener();
    // target变化，更新权限监听
    ChatTargetsModel.instance.addListener(addPermissionListener);
    super.initState();
  }

  @override
  void dispose() {
    disposePermissionListener();
    super.dispose();
  }

  @override
  String get guildPermissionMixinId =>
      ChatTargetsModel.instance.selectedChatTarget?.id;

  @override
  Future<void> onPermissionChange() async {
    if (isShowPermissionAlert) return;

    // 如果选中的频道变成了没权限查看，则选择到默认频道
    final guildId = ChatTargetsModel.instance.selectedChatTarget?.id;
    final selectedChannel = GlobalState.selectedChannel.value;
    if (selectedChannel != null &&
        selectedChannel.id != null &&
        selectedChannel.guildId == guildId) {
      final gp = PermissionModel.getPermission(guildId);
      final isVisible =
          PermissionUtils.isChannelVisible(gp, selectedChannel.id);
      if (!isVisible) {
        isShowPermissionAlert = true;
        unawaited(
            UIChannelNoPermissionAlert.showNoPermissionAlert(onConfirm: () {
          /// TODO: 2021/12/21 此处通过变量控制是否已显示，但是实际上是不准确的，因为这是异步调用
          isShowPermissionAlert = false;
          Routes.backHome();
        }));
      }
    }
    // 权限变化，此页面要刷新
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return ChannelListListenerBuilder(
        wrapSliver: true,
        contentBuilder: (context, gt, hasPermission) {
          hasManagePermission = hasPermission;
          return SliverList(
              delegate: SliverChildListDelegate([
            const SizedBox(height: 4),
            ...gt.channels.map(
              (e) => buildChannelItem(
                gt,
                e,
                context,
                hasManagePermission,
              ),
            ),
          ]));
        });
  }

  bool isChannelVisual(
      GuildPermission gp, GuildTarget gt, ChatChannel channel) {
    // 游客模式下的，优先游客可见。再看权限
    if (gt.userPending) {
      return channel.pendingUserAccess ?? false;
    } else {
      return PermissionUtils.isChannelVisible(gp, channel.id);
    }
  }

  @override
  Widget buildChannelItem(GuildTarget gt, ChatChannel channel,
      BuildContext context, bool hasManagePermission) {
    final gp = PermissionModel.getPermission(channel.guildId);
    if (channel.type == ChatChannelType.guildCategory) {
      final bool isEmptyCategory = gt.channels.where((element) {
        //子节点
        return element.parentId == channel.id;
      }).where((element) {
        // 可见的
        return isChannelVisual(gp, gt, element);
      }).isEmpty;
      if (isEmptyCategory && !hasManagePermission) return const SizedBox();
      return GestureDetector(
        onLongPress: () => _showChannelCateActions(context, channel),
        child: UICategoryItem(
          channel: channel,
          model: gt,
          hasManagePermission: hasManagePermission,
          onChange: (value) {
            ChannelCateChangeNotification(value).dispatch(context);
          },
        ),
      );
    }

    // 没有权限的，不绘制
    if (!isChannelVisual(gp, gt, channel)) {
      return sizedBox;
    }

    return ChannelItemListenerBuilder(channel, gt);
  }

  @override
  Widget buildCategoryItem(GuildTarget gt, ChatChannel channel) {
    return GestureDetector(
      onLongPress: () => _showChannelCateActions(context, channel),
      child: UICategoryItem(
        channel: channel,
        model: gt,
        hasManagePermission: hasManagePermission,
        onChange: (value) {
          ChannelCateChangeNotification(value).dispatch(context);
        },
      ),
    );
  }

  Future<void> _showChannelCateActions(
      BuildContext context, ChatChannel channel) async {
    final String guildId = ChatTargetsModel.instance.selectedChatTarget?.id;
    if (guildId == null) return;
    final GuildPermission gp = PermissionModel.getPermission(guildId);
    if (gp == null) return;
    final bool isAllowed =
        PermissionUtils.oneOf(gp, [Permission.MANAGE_CHANNELS]);
    if (!isAllowed) return;
    final res = await showCustomActionSheet([
      Text(
        '频道分类设置'.tr,
        style: Theme.of(context).textTheme.bodyText2,
      ),
    ]);
    if (res == 0) {
      unawaited(Routes.pushUpdateChannelCatePage(context, channel.guildId,
          channelCate: channel));
    }
  }
}
