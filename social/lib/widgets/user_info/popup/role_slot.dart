import 'package:flutter/material.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';
import 'package:im/api/data_model/user_info.dart';
import 'package:im/api/entity/role_bean.dart';
import 'package:im/app/theme/app_theme.dart';
import 'package:im/common/permission/permission.dart';
import 'package:im/common/permission/permission_utils.dart';
import 'package:im/core/widgets/button/fade_background_button.dart';
import 'package:im/routes.dart';
import 'package:im/themes/const.dart';
import 'package:im/widgets/button/more_icon.dart';
import 'package:oktoast/oktoast.dart';

// 角色管理卡槽
class RoleSlot extends StatelessWidget {
  final String guildId;
  final String userId;
  const RoleSlot({
    @required this.guildId,
    @required this.userId,
  });
  @override
  Widget build(BuildContext context) {
    return UserInfo.withRoles(userId, builder: (context, roles, _) {
      return ValidPermission(
          permissions: [Permission.MANAGE_ROLES],
          builder: (value, isOwner) {
            bool hasPermission;
            if (PermissionUtils.isManager()) {
              if (!PermissionUtils.isGuildOwner(userId: userId)) {
                hasPermission = PermissionUtils.comparePosition(
                        roleIds: roles.map((e) => e.id).toList()) ==
                    1;
              } else {
                hasPermission = isOwner;
              }
            } else {
              hasPermission = false;
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                if (roles.isNotEmpty) ...[
                  sizeHeight6,
                  Text(
                    '在本服务器的角色'.tr,
                    style:
                        appThemeData.textTheme.caption.copyWith(fontSize: 12),
                  ),
                  sizeHeight4,
                  sizeHeight6,
                  Container(
                    decoration: BoxDecoration(
                        color: appThemeData.backgroundColor,
                        borderRadius: BorderRadius.vertical(
                            top: const Radius.circular(6),
                            bottom: Radius.circular(hasPermission ? 0 : 6))),
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: roles
                          .map((e) => Container(
                                height: 28,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  color: appThemeData.scaffoldBackgroundColor,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                          color: e.color == 0
                                              ? appThemeData
                                                  .textTheme.bodyText2.color
                                              : Color(e.color),
                                          shape: BoxShape.circle),
                                    ),
                                    sizeWidth5,
                                    Flexible(
                                      child: Text(
                                        e.name,
                                        overflow: TextOverflow.ellipsis,
                                        style: appThemeData.textTheme.bodyText2
                                            .copyWith(fontSize: 12),
                                      ),
                                    ),
                                  ],
                                ),
                              ))
                          .toList(),
                    ),
                  ),
                ],
                if (hasPermission)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      const Divider(
                        thickness: 0.5,
                      ),
                      ClipRRect(
                          borderRadius: BorderRadius.vertical(
                              top: Radius.circular(roles.isNotEmpty ? 0 : 6),
                              bottom: const Radius.circular(6)),
                          child: Column(
                            children: <Widget>[
                              UserInfo.consume(userId, guildId: guildId,
                                  builder: (context, user, _) {
                                if (!RoleBean.isInGuild(user.userId, guildId))
                                  return sizedBox;
                                return FadeBackgroundButton(
                                  onTap: () {
                                    if (!hasPermission) {
                                      showToast('只能管理比自己角色等级低的其他成员╮(╯▽╰)╭'.tr);
                                      return;
                                    }
                                    // 跳转成员角色管理界面
                                    Routes.pushMemberSettingPage(
                                        context, guildId, user);
                                  },
                                  backgroundColor: appThemeData.backgroundColor,
                                  tapDownBackgroundColor: appThemeData
                                      .backgroundColor
                                      .withOpacity(0.5),
                                  height: 52,
                                  child: ListTile(
                                    title: Row(
                                      children: [
                                        Text(
                                          '管理成员'.tr,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w500,
                                              fontSize: 16),
                                        )
                                      ],
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: const [
                                        MoreIcon(),
                                      ],
                                    ),
                                  ),
                                );
                              }),
                            ],
                          )),
                    ],
                  ),
                sizeHeight12,
              ],
            );
          });
    });
  }
}
