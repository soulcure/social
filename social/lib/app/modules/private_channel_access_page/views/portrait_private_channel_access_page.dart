import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/api/data_model/user_info.dart';
import 'package:im/app/modules/private_channel_access_page/controllers/private_channel_access_page_controller.dart';
import 'package:im/app/theme/app_theme.dart';
import 'package:im/common/permission/permission.dart';
import 'package:im/common/permission/permission_utils.dart';
import 'package:im/core/widgets/button/fade_background_button.dart';
import 'package:im/icon_font.dart';
import 'package:im/pages/guild_setting/role/role.dart';
import 'package:im/svg_icons.dart';
import 'package:im/themes/const.dart';
import 'package:im/widgets/app_bar/appbar_builder.dart';
import 'package:im/widgets/avatar.dart';
import 'package:im/widgets/shape/row_bottom_border.dart';
import 'package:im/widgets/svg_tip_widget.dart';

import 'append_role_user_page.dart';

class PortraitPrivateChannelAccessPage extends StatefulWidget {
  const PortraitPrivateChannelAccessPage({Key key}) : super(key: key);

  @override
  _PortraitPrivateChannelAccessPageState createState() =>
      _PortraitPrivateChannelAccessPageState();
}

class _PortraitPrivateChannelAccessPageState
    extends State<PortraitPrivateChannelAccessPage> {
  PrivateChannelAccessPageController get controller => GetInstance().find();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: FbAppBar.custom('管理频道访问'.tr),
      body: GetBuilder<PrivateChannelAccessPageController>(builder: (c) {
        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                children: [
                  sizeHeight16,
                  _buildAddButton(),
                ],
              ),
            ),
            SliverToBoxAdapter(
              child: Visibility(
                visible: controller.roleList.isNotEmpty,
                child: _buildSubtitle('角色-${controller.roleList.length}'.tr),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (c, i) => _buildRoleItem(controller.roleList[i]),
                childCount: controller.roleList.length,
              ),
            ),
            SliverToBoxAdapter(
              child: Visibility(
                visible: controller.memberList.isNotEmpty,
                child: _buildSubtitle('成员-${controller.memberList.length}'.tr),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (c, i) => _buildMemberItem(controller.memberList[i]),
                childCount: controller.memberList.length,
              ),
            ),
            SliverToBoxAdapter(
              child: _buildNullWidget(),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildSubtitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 26, 16, 10),
      child: Text(
        title,
        style: appThemeData.textTheme.caption,
      ),
    );
  }

  Widget _buildAddButton() {
    return FadeBackgroundButton(
      backgroundColor: Theme.of(context).backgroundColor,
      tapDownBackgroundColor:
          Theme.of(context).backgroundColor.withOpacity(0.5),
      onTap: () {
        Get.to(AppendRoleUserPage(
          guildId: controller.channel.guildId,
        ));
      },
      padding: const EdgeInsets.all(16),
      child: Row(
        children: <Widget>[
          Icon(
            IconFont.buffAdd,
            color: appThemeData.iconTheme.color,
            size: 20,
          ),
          sizeWidth12,
          Text(
            '添加角色或成员'.tr,
            style: appThemeData.textTheme.bodyText2.copyWith(height: 1.25),
          ),
        ],
      ),
    );
  }

  /// 空页面
  Widget _buildNullWidget() {
    return Visibility(
      visible: controller.memberList.isEmpty && controller.roleList.isEmpty,
      child: Container(
        height: MediaQuery.of(context).size.height - 200,
        alignment: Alignment.center,
        child: const SvgTipWidget(
          svgName: SvgIcons.nullState,
          text: '暂无角色或成员',
        ),
      ),
    );
  }

  Widget _buildRoleItem(PermissionOverwrite overwrite) {
    final bool isEveryone = overwrite.id == controller.gp.guildId;
    Color roleColor = Theme.of(context).textTheme.bodyText2.color;
    final Role role = controller.gp.roles.firstWhere(
        (element) => element.id == overwrite.id,
        orElse: () => null);
    final int roleColorValue = role?.color;
    if (roleColorValue != 0 && roleColorValue != null)
      roleColor = Color(roleColorValue);
    final bool isHigherRole = controller.canChangePermission(role);
    final roleIcon =
        role.managed ? IconFont.buffBotIconColor : IconFont.buffRoleIconColor;
    return Container(
      color: Theme.of(context).backgroundColor,
      child: Container(
        alignment: Alignment.centerLeft,
        height: 64,
        padding: const EdgeInsets.fromLTRB(16, 0, 4, 0),
        decoration: const ShapeDecoration(
          shape: RowBottomBorder(),
        ),
        child: Row(
          children: <Widget>[
            Icon(roleIcon, size: 28, color: roleColor),
            sizeWidth16,
            Expanded(
                child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                sizeHeight12,
                Text(role?.name ?? '',
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context)
                        .textTheme
                        .bodyText2
                        .copyWith(height: 1.25)),
                sizeHeight4,
                Row(
                  children: [
                    if (isEveryone) ...[
                      sizeHeight4,
                      Text(
                        '服务器所有成员的默认角色。'.tr,
                        style: Theme.of(context)
                            .textTheme
                            .bodyText1
                            .copyWith(fontSize: 12),
                      ),
                    ] else ...[
                      const Icon(IconFont.buffMembersNum,
                          size: 12, color: Color(0xFF747F8D)),
                      sizeWidth4,
                      Text(
                        '${role?.memberCount?.toString() ?? 0} 位成员',
                        style: Theme.of(context)
                            .textTheme
                            .bodyText1
                            .copyWith(fontSize: 12, height: 1.25),
                      ),
                    ]
                  ],
                ),
              ],
            )),
            IconButton(
                icon: Icon(
                  IconFont.buffInputClearIcon,
                  color: isHigherRole
                      ? const Color(0xFF8D93A6)
                      : const Color(0x598D93A6),
                  size: 20,
                ),
                onPressed: isHigherRole
                    ? () => controller.deleteViewChannelPermission(
                        overwrite, role?.name ?? '')
                    : null),
          ],
        ),
      ),
    );
  }

  Widget _buildMemberItem(PermissionOverwrite overwrite) {
    return UserInfo.consume(
      overwrite.id,
      guildId: controller.channel.guildId,
      builder: (context, user, widget) {
        final bool isHigherRole =
            PermissionUtils.comparePosition(roleIds: user.roles ?? []) == 1 &&
                controller.guildPermission.ownerId != overwrite.id;
        return Container(
          color: Theme.of(context).backgroundColor,
          child: Container(
            alignment: Alignment.centerLeft,
            height: 56,
            padding: const EdgeInsets.fromLTRB(16, 0, 4, 0),
            decoration: const ShapeDecoration(
              shape: RowBottomBorder(),
            ),
            child: Row(
              children: <Widget>[
                Avatar(url: user.avatar, radius: 16),
                sizeWidth12,
                Expanded(
                  child: Text(
                    user.nickname,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyText2,
                  ),
                ),
                IconButton(
                  icon: Icon(
                    IconFont.buffInputClearIcon,
                    color: isHigherRole
                        ? const Color(0xFF8D93A6)
                        : const Color(0x598D93A6),
                    size: 20,
                  ),
                  onPressed: isHigherRole
                      ? () => controller.deleteViewChannelPermission(
                          overwrite, user.nickname)
                      : null,
                )
              ],
            ),
          ),
        );
      },
    );
  }
}
