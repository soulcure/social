import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/common/permission/permission.dart';
import 'package:im/common/permission/permission_model.dart';
import 'package:im/common/permission/permission_utils.dart';
import 'package:im/global.dart';
import 'package:im/icon_font.dart';
import 'package:im/web/pages/service/management_service_emo.dart';
import 'package:im/web/pages/service/management_service_web.dart';
import 'package:im/web/pages/service/manager_welcome_setting_view.dart';
import 'package:im/web/pages/setting/member_manage_page.dart';
import 'package:im/web/pages/setting/role_manage_page.dart';
import 'package:im/web/widgets/web_form_detector/web_form_page_view.dart';
import 'package:im/web/widgets/web_form_detector/web_form_tab_item.dart';
import 'package:im/web/widgets/web_form_detector/web_form_tab_view.dart';

import 'invite_link_page.dart';

class GuildSetupPage extends StatefulWidget {
  final String guildId;

  const GuildSetupPage(this.guildId);

  @override
  _GuildSetupPageState createState() => _GuildSetupPageState();
}

class _GuildSetupPageState extends State<GuildSetupPage> {
  // static const int Manage_service = 0;
  // static const int Manage_Emoji = 0;
  //
  // static const int manage_guide_page = 0;
  // static const int Manage_Role = 0;

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFFF0F1F2);
    return Scaffold(
        backgroundColor: bgColor,
        body: Center(
          child: SizedBox(
            width: 1040,
            child: ValidPermission(
                permissions: const [],
                builder: (context, snapshot) {
                  final gp = PermissionModel.getPermission(widget.guildId);
                  final allowManageGuild =
                      PermissionUtils.oneOf(gp, [Permission.MANAGE_GUILD]);
                  final allowManageEmoji =
                      PermissionUtils.oneOf(gp, [Permission.MANAGE_EMOJIS]);
                  final allowManageRole =
                      PermissionUtils.oneOf(gp, [Permission.MANAGE_ROLES]);
                  return WebFormPage(
                    tabItems: [
                      if (allowManageGuild || allowManageEmoji)
                        WebFormTabItem.title(title: '服务器'.tr),
                      if (allowManageGuild)
                        WebFormTabItem(
                            title: '管理服务器'.tr,
                            icon: IconFont.webGuildSetupManage,
                            index: 0),
                      // const WebFormTabItem(
                      //     title: '服务器数据'.tr, icon: IconFont.webLink, index: 1),
                      if (allowManageEmoji)
                        WebFormTabItem(
                            title: '管理服务器表情'.tr,
                            icon: IconFont.webGuildSetupEmoji,
                            index: 2),
                      if (allowManageGuild)
                        WebFormTabItem(
                            title: '设置欢迎页'.tr,
                            icon: IconFont.webGuideManageGuidePage,
                            index: 6),
                      if (allowManageRole) ...[
                        WebFormTabItem.title(title: '用户'.tr),
                        WebFormTabItem(
                            title: '管理角色'.tr,
                            icon: IconFont.webGuildSetupRole,
                            index: 3),
                        WebFormTabItem(
                            title: '管理成员'.tr,
                            icon: IconFont.webGuildSetupMember,
                            index: 4),
                      ],
                      if (PermissionUtils.isGuildOwner(userId: Global.user.id))
                        WebFormTabItem(
                            title: '管理邀请链接'.tr,
                            icon: IconFont.webGuildSetupLink,
                            index: 5),
                    ],
                    tabViews: [
                      WebFormTabView(
                        title: '服务器基本设置'.tr,
                        index: 0,
                        child: CircleManagementService(),
                      ),
                      WebFormTabView(
                        title: '',
                        desc: '',
                        child: const SizedBox(),
                      ),
                      WebFormTabView(
                        title: '管理服务器表情'.tr,
                        index: 2,
                        child: GuildEmoPage(widget.guildId),
                      ),
                      WebFormTabView(
                        title: '管理角色'.tr,
                        desc: '',
                        index: 3,
                        child: RoleManagePage(widget.guildId),
                      ),
                      WebFormTabView(
                        title: '服务器成员'.tr,
                        desc: '',
                        index: 4,
                        child: MemberManagePage(widget.guildId),
                      ),
                      if (PermissionUtils.isGuildOwner(userId: Global.user.id))
                        WebFormTabView(
                          title: '成员'.tr,
                          desc: '这里是全部可用的邀请链接，您可以随时撤销，撤销后邀请链接将永久失效。'.tr,
                          index: 5,
                          child: InviteLinkPage(
                            guildId: widget.guildId,
                          ),
                        ),
                      WebFormTabView(
                        title: '设置欢迎页'.tr,
                        index: 6,
                        child: ManagerWelcomeSettingView(widget.guildId),
                      ),
                    ],
                  );
                }),
          ),
        ));
  }
}
