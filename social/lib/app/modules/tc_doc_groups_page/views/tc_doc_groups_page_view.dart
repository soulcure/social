import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/app/modules/tc_doc_add_group_page/entities/tc_doc_group.dart';
import 'package:im/app/theme/app_theme.dart';
import 'package:im/common/permission/permission_utils.dart';
import 'package:im/icon_font.dart';
import 'package:im/pages/guild_setting/role/role_icon.dart';
import 'package:im/themes/const.dart';
import 'package:im/themes/default_theme.dart';
import 'package:im/utils/show_action_sheet.dart';
import 'package:im/utils/tc_doc_utils.dart';
import 'package:im/widgets/app_bar/appbar_action_model.dart';
import 'package:im/widgets/app_bar/appbar_builder.dart';
import 'package:im/widgets/realtime_user_info.dart';
import 'package:im/widgets/refresh/common_error_widget.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

import '../controllers/tc_doc_groups_page_controller.dart';

class TcDocGroupsPageView extends GetView<TcDocGroupsPageController> {
  @override
  Widget build(BuildContext context) {
    return GetBuilder<TcDocGroupsPageController>(builder: (c) {
      return WillPopScope(
        onWillPop: () async {
          Get.back(result: c.groups);
          return true;
        },
        child: Scaffold(
          backgroundColor: appThemeData.backgroundColor,
          appBar: FbAppBar.custom(
            '协作者 (%s)'.trArgs(
              [controller.total.toString()],
            ),
            leadingBlock: () {
              Get.back(result: c.groups);
              return true;
            },
            actions: [
              AppBarIconActionModel(IconFont.buffJoinGuild,
                  actionBlock: () async {
                final res = await TcDocUtils.toAddGroupPage(c.guildId, c.fileId)
                    as bool;
                if (res == true) {
                  await c.initPage();
                }
              })
            ],
          ),
          body: controller.obx(
            (state) {
              return SmartRefresher(
                  enablePullDown: false,
                  controller: controller.refreshController,
                  onLoading: controller.onLoading,
                  footer: ClassicFooter(
                    idleText: '上拉加载更多'.tr,
                    loadingText: '加载中'.tr,
                    canLoadingText: '上拉加载更多'.tr,
                    failedText: '加载失败'.tr,
                    noDataText: '-腾讯文档提供技术支持-'.tr,
                  ),
                  child: ListView.separated(
                      itemBuilder: (c, i) =>
                          _buildItem(controller.groups[i], i),
                      separatorBuilder: (c, i) => const Divider(
                            indent: 60,
                            thickness: 0.5,
                          ),
                      itemCount: controller.groups.length));
            },
            onLoading: DefaultTheme.defaultLoadingIndicator(),
            onError: (e) {
              return CommonErrorMsgWidget(
                errorMsg: e,
                onRetry: controller.initPage,
              );
            },
          ),
        ),
      );
    });
  }

  Widget _buildItem(TcDocGroup group, int index) {
    return Container(
      height: 56,
      color: Get.theme.backgroundColor,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          SizedBox(width: 32, child: _buildIcon(group)),
          sizeWidth12,
          Expanded(child: _buildName(group)),
          sizeWidth12,
          _buildDocAction(group, index),
        ],
      ),
    );
  }

  Widget _buildIcon(TcDocGroup group) {
    switch (group.type) {
      case TcDocGroupType.user:
        return RealtimeAvatar(userId: group.targetId);
      case TcDocGroupType.role:
        final role =
            PermissionUtils.getRole(controller.guildId, group.targetId);
        if (role != null) return RoleIcon(role);
        return sizedBox;
      case TcDocGroupType.channel:
        return Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: Get.theme.primaryColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            IconFont.buffWenzipindaotubiao,
            size: 20,
            color: Get.theme.primaryColor,
          ),
        );
      default:
        return sizedBox;
    }
  }

  Widget _buildName(TcDocGroup group) {
    switch (group.type) {
      case TcDocGroupType.user:
        return RealtimeNickname(userId: group.targetId);
      case TcDocGroupType.role:
        final roleName =
            PermissionUtils.getRole(controller.guildId, group.targetId)?.name ??
                '';
        return Text(roleName);
      case TcDocGroupType.channel:
        return RealtimeChannelName(group.targetId);
      default:
        return sizedBox;
    }
  }

  Widget _buildDocAction(TcDocGroup group, int index) {
    String text;
    final textStyle =
        TextStyle(fontSize: 15, color: appThemeData.iconTheme.color);
    if (index == 0) {
      text = '所有权限'.tr;
    } else {
      text = group.role.toText();
    }
    final child = Text(
      text,
      style: textStyle,
    );
    if (index == 0) return child;
    return GestureDetector(
      onTap: () => _showActions(group),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(text, style: textStyle),
          sizeWidth4,
          SizedBox(
            width: 16,
            child: Icon(
              IconFont.buffFilePullDown,
              size: 20,
              color: appThemeData.iconTheme.color,
            ),
          ),
        ],
      ),
    );
  }

  Future _showActions(TcDocGroup group) async {
    final actions = [
      Text(TcDocGroupRole.view.toText().tr, style: Get.textTheme.bodyText2),
      Text(TcDocGroupRole.edit.toText().tr, style: Get.textTheme.bodyText2),
      Text('删除'.tr,
          style: Get.textTheme.bodyText2
              .copyWith(color: DefaultTheme.dangerColor)),
    ];
    final res = await showCustomActionSheet<int>(actions);
    switch (res) {
      case 0:
        if (group.role == TcDocGroupRole.view) return;
        await controller.updateGroup(group, TcDocGroupRole.view);
        break;
      case 1:
        if (group.role == TcDocGroupRole.edit) return;
        await controller.updateGroup(group, TcDocGroupRole.edit);
        break;
      case 2:
        await controller.deleteGroup(group);
        break;
      default:
    }
    return res;
  }
}
