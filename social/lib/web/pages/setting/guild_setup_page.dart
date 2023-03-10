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
                        WebFormTabItem.title(title: '?????????'.tr),
                      if (allowManageGuild)
                        WebFormTabItem(
                            title: '???????????????'.tr,
                            icon: IconFont.webGuildSetupManage,
                            index: 0),
                      // const WebFormTabItem(
                      //     title: '???????????????'.tr, icon: IconFont.webLink, index: 1),
                      if (allowManageEmoji)
                        WebFormTabItem(
                            title: '?????????????????????'.tr,
                            icon: IconFont.webGuildSetupEmoji,
                            index: 2),
                      if (allowManageGuild)
                        WebFormTabItem(
                            title: '???????????????'.tr,
                            icon: IconFont.webGuideManageGuidePage,
                            index: 6),
                      if (allowManageRole) ...[
                        WebFormTabItem.title(title: '??????'.tr),
                        WebFormTabItem(
                            title: '????????????'.tr,
                            icon: IconFont.webGuildSetupRole,
                            index: 3),
                        WebFormTabItem(
                            title: '????????????'.tr,
                            icon: IconFont.webGuildSetupMember,
                            index: 4),
                      ],
                      if (PermissionUtils.isGuildOwner(userId: Global.user.id))
                        WebFormTabItem(
                            title: '??????????????????'.tr,
                            icon: IconFont.webGuildSetupLink,
                            index: 5),
                    ],
                    tabViews: [
                      WebFormTabView(
                        title: '?????????????????????'.tr,
                        index: 0,
                        child: CircleManagementService(),
                      ),
                      WebFormTabView(
                        title: '',
                        desc: '',
                        child: const SizedBox(),
                      ),
                      WebFormTabView(
                        title: '?????????????????????'.tr,
                        index: 2,
                        child: GuildEmoPage(widget.guildId),
                      ),
                      WebFormTabView(
                        title: '????????????'.tr,
                        desc: '',
                        index: 3,
                        child: RoleManagePage(widget.guildId),
                      ),
                      WebFormTabView(
                        title: '???????????????'.tr,
                        desc: '',
                        index: 4,
                        child: MemberManagePage(widget.guildId),
                      ),
                      if (PermissionUtils.isGuildOwner(userId: Global.user.id))
                        WebFormTabView(
                          title: '??????'.tr,
                          desc: '??????????????????????????????????????????????????????????????????????????????????????????????????????'.tr,
                          index: 5,
                          child: InviteLinkPage(
                            guildId: widget.guildId,
                          ),
                        ),
                      WebFormTabView(
                        title: '???????????????'.tr,
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
