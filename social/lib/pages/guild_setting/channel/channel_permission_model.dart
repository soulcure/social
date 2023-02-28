import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:im/api/data_model/user_info.dart';
import 'package:im/api/role_api.dart';
import 'package:im/common/permission/permission.dart';
import 'package:im/common/permission/permission_mixin.dart';
import 'package:im/global.dart';
import 'package:im/pages/home/model/chat_index_model.dart';
import 'package:im/pages/home/model/chat_target_model.dart';

class ChannelPermissionModel extends ChangeNotifier
    with GuildPermissionListener {
  String get channelId => channel.id;
  final ChatChannel channel;

  final BuildContext context;
  bool editing = false;
  List<PermissionOverwrite> _list = [];
  List<PermissionOverwrite> _roleList = [];
  List<PermissionOverwrite> _memberList = [];

  UnmodifiableListView<PermissionOverwrite> get list =>
      UnmodifiableListView(_list);

  UnmodifiableListView<PermissionOverwrite> get roleList =>
      UnmodifiableListView(_roleList);

  UnmodifiableListView<PermissionOverwrite> get memberList =>
      UnmodifiableListView(_memberList);

  GuildPermission get gp => guildPermission;

  ChannelPermissionModel(this.context, this.channel) {
    addPermissionListener();
    reset();
  }

  void reset() {
    if (!editing) {
      // 频道权限
      _list = guildPermission.channelPermission
              .firstWhere((element) => element.channelId == channelId,
                  orElse: () => null)
              ?.overwrites ??
          [];
      _sortByRolePosition();
      notifyListeners();
    }
  }

  void destroy() {
    disposePermissionListener();
    dispose();
  }

  /// 对获取到的列表根据 role position排序
  void _sortByRolePosition() {
    _memberList = _list
        .where((element) => element.actionType == 'user'
            // && MemberListModel.instance.fullList.contains(element.id)
            )
        .toList();
    _roleList = _list
        .where((element) =>
            element.actionType == 'role' &&
            (guildPermission.roles
                .map((e) => e.id)
                .toList()
                .contains(element.id)))
        .toList();
    final roles = guildPermission.roles;
    _roleList.sort((a, b) {
      final aPosition = roles.indexWhere((element) => element.id == a.id);
      final bPosition = roles.indexWhere((element) => element.id == b.id);
      return (aPosition >= 0 ? aPosition : 0)
          .compareTo(bPosition >= 0 ? bPosition : 0);
    });
    notifyListeners();
  }

  void toggleEdit() {
    editing = !editing;
    notifyListeners();
  }

  Future updateOverwrite(String roleId,
      {int permissions,
      int color,
      String name,
      int position,
      bool mentionable,
      bool hoist}) async {
    await RoleApi.save(guildPermission.guildId, Global.user.id, roleId,
        permissions: permissions,
        color: color,
        name: name,
        mentionable: mentionable,
        hoist: hoist);
    final int index = _list.indexWhere((element) => element.id == roleId);
    if (index >= 0) {
//      final overwrite = _list[index];
//      Role newer = Role(
//        id: role.id,
//        name: name ?? role.name,
//        position: position ?? role.position,
//        permissions: permissions ?? role.permissions,
//        color: color ?? role.color,
//        mentionable: mentionable ?? role.mentionable,
//        hoist: hoist ?? role.hoist,
//      );
//      _list.replaceRange(index, index + 1, [newer]);
      notifyListeners();
    }
  }

  Future updateOverwriteList(List<PermissionOverwrite> list) async {
    _list = list;
    notifyListeners();
  }

  Future removeOverwrite(PermissionOverwrite overwrite) async {
    await RoleApi.deleteOverwrite(
      id: overwrite.id,
      guildId: overwrite.guildId,
      userId: Global.user.id,
      channelId: overwrite.channelId,
    );
    _list.removeWhere((e) => e.id == overwrite.id);
    _sortByRolePosition();
    notifyListeners();
  }

  Future createOverwrite(PermissionOverwrite overwrite) async {
    await RoleApi.updateOverwrite(
      id: overwrite.id,
      userId: Global.user.id,
      channelId: overwrite.channelId,
      guildId: overwrite.guildId,
      actionType: overwrite.actionType,
      allows: overwrite.allows,
      deny: overwrite.deny,
    );
    final int overwriteIdx =
        _list.indexWhere((element) => element.id == overwrite.id);
    if (overwriteIdx >= 0) return;
    _list.add(overwrite);
    _sortByRolePosition();
    notifyListeners();
  }

  Future<String> getOverwriteName(String overwriteId) async {
    final role = guildPermission.roles
        .firstWhere((element) => element.id == overwriteId, orElse: () => null);
    if (role == null) {
      final res = await UserInfo.get(overwriteId);
      return res?.nickname ?? '';
    }
    return role.name;
  }

  @override
  String get guildPermissionMixinId =>
      ChatTargetsModel.instance.selectedChatTarget.id;

  @override
  void onPermissionChange() {
    reset();
  }
}
