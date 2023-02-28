import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:im/api/data_model/user_info.dart';
import 'package:im/api/entity/role_bean.dart';
import 'package:im/api/guild_api.dart';
import 'package:im/api/role_api.dart';
import 'package:im/db/db.dart';
import 'package:im/global.dart';
import 'package:im/pages/guild_setting/role/role.dart';
import 'package:im/pages/member_list/model/member_list_model.dart';
import 'package:im/utils/show_confirm_dialog.dart';
import 'package:im/widgets/refresh/list_model.dart';

class MemberManageModel extends ListModel<UserInfo> {
  static MemberManageModel _instance;
  final String guildId;
  List<Role> roles = [];

  factory MemberManageModel({String guildId}) {
    if (guildId == null && _instance == null) return null;
    return _instance ??= MemberManageModel._(guildId);
  }

  MemberManageModel._(this.guildId) {
    pageSize = 20;
    fetchData = () async {
      final List<UserInfo> res = await RoleApi.getMemberList(
          guildId: guildId,
          userId: Global.user.id,
          lastId: internalList.isEmpty ? null : internalList.last.userId,
          limit: pageSize);
      return res;
    };
  }

  static Future<void> toggleMemberRole(
      String userId, String guildId, bool isSelected, String roleId) async {
    final member = Db.userInfoBox.get(userId);
    List<String> userRoles;
    if (isSelected) {
      if (!member.roles.contains(roleId)) {
        userRoles = [...member.roles, roleId];
      } else {
        userRoles = member.roles;
      }
    } else {
      userRoles = [...member.roles..remove(roleId)];
    }
    await RoleApi.updateMemberRole(
      guildId: guildId,
      userId: Global.user.id,
      roleIds: userRoles,
      memberId: member.userId,
    );
    member.roles = userRoles;
    RoleBean.update(userId, guildId, userRoles);
    UserInfo.set(member);
  }

  static Future<void> deleteRole(
      {String userId, String guildId, Role deleteRole}) async {
    final user = Db.userInfoBox.get(userId);
    if (user == null) return;
    final roleIds = user.roles..remove(deleteRole.id);
    await RoleApi.updateMemberRole(
      isOriginDataReturn: true,
      guildId: guildId,
      userId: Global.user.id,
      roleIds: roleIds,
      memberId: userId,
    );
    user.roles = roleIds;
    UserInfo.set(user);
  }

  Future<void> removeMember(BuildContext context, UserInfo user) async {
    final res = await showConfirmDialog(
      title: '移出成员'.tr,
      content: '确定移出服务器成员 %s ？移出后，该成员可以通过新的邀请链接再加入。'.trArgs([user.showName()]),
    );
    if (res) {
      await GuildApi.removeUser(
        guildId: guildId,
        userId: Global.user.id,
        userName: user.showName(),
        memberId: user.userId,
        showDefaultErrorToast: false,
        isOriginDataReturn: true,
      );
      await MemberListModel.instance.remove(user.userId);
      internalList.removeWhere((element) => element.userId == user.userId);
      notifyListeners();
    }
  }

  void destroy() {
    dispose();
    _instance = null;
  }
}
