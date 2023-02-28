import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/api/data_model/user_info.dart';
import 'package:im/app/modules/private_channel_access_page/controllers/private_channel_access_page_controller.dart';
import 'package:im/common/permission/permission_utils.dart';
import 'package:im/pages/channel/select_role_user_page.dart';
import 'package:im/pages/guild_setting/role/role.dart';
import 'package:im/widgets/app_bar/appbar_action_model.dart';
import 'package:im/widgets/app_bar/appbar_builder.dart';
import 'package:oktoast/oktoast.dart';

class AppendRoleUserPage extends SelectRoleUserPage {
  const AppendRoleUserPage({Key key, String guildId})
      : super(key: key, guildId: guildId);

  @override
  _AppendRoleUserPageState createState() => _AppendRoleUserPageState();
}

class _AppendRoleUserPageState
    extends SelectRoleUserPageState<AppendRoleUserPage> {
  PrivateChannelAccessPageController get controller => GetInstance().find();
  List<String> _membersAppended = [];
  List<String> _rolesAppended = [];

  bool _loading = false;
  bool get canAppend =>
      selectedRoleIds.isNotEmpty || selectedUserIds.isNotEmpty;

  @override
  void initState() {
    _membersAppended = controller.memberList.map((e) => e.id).toList();
    _rolesAppended = controller.roleList.map((e) => e.id).toList();
    super.initState();
  }

  @override
  Widget appBar() {
    return FbAppBar.custom(
      '添加角色或成员',
      actions: [
        AppBarTextPrimaryActionModel('确定',
            isEnable: canAppend, isLoading: _loading, actionBlock: () async {
          _loading = true;
          refreshState();
          await controller.addViewChannelPermission(
              selectedRoleIds, selectedUserIds);
          _loading = false;
          refreshState();
        })
      ],
    );
  }

  void refreshState() {
    if (mounted) setState(() {});
  }

  @override
  List<Role> guildRoles() {
    final roles = super.guildRoles();
    return roles.where((e) => !_rolesAppended.contains(e.id)).toList();
  }

  @override
  List<UserInfo> filterUser(List<UserInfo> users) {
    return users.where((e) => !_membersAppended.contains(e.userId)).toList();
  }

  @override
  Widget buildRoleItem(BuildContext context, Role r) {
    final bool isHigherRole =
        PermissionUtils.comparePosition(roleIds: [r.id]) == 1;
    if (isHigherRole)
      return super.buildRoleItem(context, r);
    else
      return GestureDetector(
        onTap: () {
          showToast('只能设置比自己当前角色等级低的角色'.tr);
        },
        child: Opacity(
            opacity: 0.65,
            child: AbsorbPointer(child: super.buildRoleItem(context, r))),
      );
  }

  @override
  Widget buildUserItem(BuildContext context, UserInfo userInfo) {
    final bool isHigherRole =
        PermissionUtils.comparePosition(roleIds: userInfo.roles ?? []) == 1;
    if (isHigherRole)
      return super.buildUserItem(context, userInfo);
    else
      return GestureDetector(
        onTap: () {
          showToast('只能设置比自己当前角色等级低的成员'.tr);
        },
        child: Opacity(
            opacity: 0.65,
            child:
                AbsorbPointer(child: super.buildUserItem(context, userInfo))),
      );
  }
}
