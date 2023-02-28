import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:im/common/permission/permission.dart';
import 'package:im/common/permission/permission_model.dart';
import 'package:im/common/permission/permission_utils.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/pages/home/view/tab_bar.dart';
import 'package:im/themes/default_theme.dart';
import 'package:im/widgets/default_tip_widget.dart';
import 'package:provider/provider.dart';

import '../../../icon_font.dart';

class ChannelListListenerBuilder extends StatelessWidget {
  // 当频道列表为空时空频道的ui是否嵌套sliver返回
  final bool wrapSliver;
  final Widget Function(
      BuildContext context, GuildTarget gt, bool hasPermission) contentBuilder;

  const ChannelListListenerBuilder(
      {this.contentBuilder, this.wrapSliver = false});

  @override
  Widget build(BuildContext context) {
    return Consumer<BaseChatTarget>(builder: (context, model, _) {
      final m = model as GuildTarget;
      if (model == null)
        return wrapSliver
            ? SliverToBoxAdapter(child: DefaultTheme.defaultLoadingIndicator())
            : DefaultTheme.defaultLoadingIndicator();
      final channelMap = <String, ChatChannel>{};
      for (final c in m.channels) {
        channelMap[c.id] = c;
      }
      return ValidPermission(
          permissions: [Permission.MANAGE_CHANNELS],
          builder: (hasPermission, isOwner) {
            /// todo if 判断太多
            bool showEmptyUi = false;
            final hasManagePermission = hasPermission;
            if (!showEmptyUi && hasManagePermission) {
              // 有管理权限，展示空分类。除非没有任何频道。
              showEmptyUi = m.channels.isEmpty;
            }
            if (!showEmptyUi && !hasManagePermission) {
              //所有channel都是分类的话，也显示"暂无频道".tr
              showEmptyUi = m.channels.every(
                  (element) => element.type == ChatChannelType.guildCategory);
            }
            if (!showEmptyUi && !hasManagePermission) {
              //所有频道都为自己不可见的频道，也显示"暂无频道".tr
              final gp = PermissionModel.getPermission(m.id);
              showEmptyUi = m.channels
                  .where((element) =>
                      element.type != ChatChannelType.guildCategory)
                  .every((e) {
                return !PermissionUtils.isChannelVisible(gp, e.id);
              });
            }
            if (!showEmptyUi && hasPermission) {
              //所有频道都为自己不可见的频道，也显示"暂无频道".tr
              final gp = PermissionModel.getPermission(m.id);
              final bool allChannelNotVisible = m.channels
                  .where((element) =>
                      element.type != ChatChannelType.guildCategory)
                  .every((e) {
                return !PermissionUtils.isChannelVisible(gp, e.id);
              });
              final bool hasCategory = m.channels
                  .where((element) =>
                      element.type == ChatChannelType.guildCategory)
                  .toList()
                  .isNotEmpty;
              if (allChannelNotVisible && !hasCategory) {
                showEmptyUi = true;
              }
            }
            final emptyUi = Container(
              alignment: Alignment.center,
              padding: EdgeInsets.symmetric(
                vertical:
                    HomeTabBar.height + MediaQuery.of(context).padding.bottom,
              ),
              child: DefaultTipWidget(
                icon: IconFont.buffWenzipindaotubiao,
                iconSize: 34,
                text: '暂无频道'.tr,
              ),
            );
            if (showEmptyUi)
              return wrapSliver ? SliverToBoxAdapter(child: emptyUi) : emptyUi;
            else
              return contentBuilder?.call(context, model, hasPermission);
          });
    });
  }
}
