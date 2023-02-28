import 'dart:collection';

import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:im/api/role_api.dart';
import 'package:im/common/permission/permission.dart';
import 'package:im/common/permission/permission_mixin.dart';
import 'package:im/common/permission/permission_model.dart';
import 'package:im/common/permission/permission_utils.dart';
import 'package:im/pages/guild_setting/role/role.dart';
import 'package:im/pages/home/model/chat_index_model.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/utils/show_confirm_dialog.dart';

class PrivateChannelAccessPageController extends GetxController
    with GuildPermissionListener {
  String get channelId => channel.id;
  ChatChannel channel;

  /// dataSource
  List<PermissionOverwrite> _list = [];
  List<PermissionOverwrite> _roleList = [];
  List<PermissionOverwrite> _memberList = [];

  UnmodifiableListView<PermissionOverwrite> get list =>
      UnmodifiableListView(_list);
  UnmodifiableListView<PermissionOverwrite> get roleList =>
      UnmodifiableListView(_roleList);
  UnmodifiableListView<PermissionOverwrite> get memberList =>
      UnmodifiableListView(_memberList);

  /// 权限
  GuildPermission get gp => guildPermission;

  PrivateChannelAccessPageController() {
    channel = Get.arguments;
    addPermissionListener();
    reset();
    getRoleNum();
  }

  /// 获取角色成员数
  Future<void> getRoleNum() async {
    final _roleMemberNumList = await RoleApi.getList(
        guildId: channel.guildId, showDefaultErrorToast: false, size: 999);
    guildPermission.roles.forEach((e) {
      final index =
          _roleMemberNumList.indexWhere((element) => element.id == e.id);
      if (index >= 0) {
        e.memberCount = _roleMemberNumList[index].memberCount;
        e.hoist = _roleMemberNumList[index].hoist;
        e.managed = _roleMemberNumList[index].managed;
      }
    });
    update();
  }

  void reset() {
    // 频道权限
    _list = guildPermission.channelPermission
            .firstWhere((element) => element.channelId == channelId,
                orElse: () => null)
            ?.overwrites ??
        [];
    _sortByRolePosition();
    update();
  }

  void destroy() {
    disposePermissionListener();
    dispose();
  }

  /// 对获取到的列表根据 role position排序
  void _sortByRolePosition() {
    _memberList = _list
        .where((e) =>
            e.actionType == 'user' &&
            PermissionUtils.contains(e.allows, Permission.VIEW_CHANNEL.value))
        .toList();
    _roleList = _list
        .where((element) =>
            element.actionType == 'role' &&
            (guildPermission.roles.indexWhere((e) => e.id == element.id) >=
                0) &&
            PermissionUtils.contains(
                element.allows, Permission.VIEW_CHANNEL.value))
        .toList();
    // 添加创立者和超管
    final ownerId = guildPermission.ownerId;
    // 如果没有创建者，就需要添加
    if (_memberList.indexWhere((e) => e.id == ownerId) == -1) {
      _memberList.insert(
          0,
          PermissionOverwrite(
            id: ownerId,
            guildId: channel.guildId,
            channelId: channelId,
            allows: 0,
            deny: 0,
            name: '',
            actionType: 'user',
          ));
    }
    guildPermission.roles.forEach((e) {
      // 如果是超管，并且列表没有也需要添加进来
      if (PermissionUtils.contains(e.permissions, Permission.ADMIN.value) &&
          _roleList.indexWhere((element) => element.id == e.id) == -1) {
        _roleList.add(PermissionOverwrite(
          id: e.id,
          guildId: channel.guildId,
          channelId: channelId,
          allows: 0,
          deny: 0,
          name: '',
          actionType: 'role',
        ));
      }
    });

    // 整理角色位置
    final roles = guildPermission.roles;
    _roleList.sort((a, b) {
      final aPosition = roles.indexWhere((element) => element.id == a.id);
      final bPosition = roles.indexWhere((element) => element.id == b.id);
      return (aPosition >= 0 ? aPosition : 0)
          .compareTo(bPosition >= 0 ? bPosition : 0);
    });
    update();
  }

  Future addViewChannelPermission(
      Set<String> selectedRoleIds, Set<String> selectedUserIds) async {
    final channelPermission = guildPermission.channelPermission
        .firstWhere((e) => e.channelId == channelId, orElse: () => null);
    // 该频道的所有权限
    final channelOverwrites = channelPermission?.overwrites ?? [];

    final List<PermissionOverwrite> res = [];

    // 处理被改动或新增的数据，进行合并
    for (final roleId in selectedRoleIds) {
      var overwrite = channelOverwrites.firstWhere(
        (element) => element.id == roleId,
        orElse: () => PermissionOverwrite(
          id: roleId,
          guildId: channel.guildId,
          channelId: channelId,
          allows: 0,
          deny: 0,
          name: '',
          actionType: 'role',
        ),
      );
      overwrite = overwrite.copyWith(
          allows: overwrite.allows | Permission.VIEW_CHANNEL.value,
          deny: overwrite.deny & ~Permission.VIEW_CHANNEL.value);
      res.add(overwrite);
    }

    for (final userId in selectedUserIds) {
      var overwrite = channelOverwrites.firstWhere(
        (element) => element.id == userId,
        orElse: () => PermissionOverwrite(
          id: userId,
          guildId: channel.guildId,
          channelId: channelId,
          allows: 0,
          deny: 0,
          name: '',
          actionType: 'user',
        ),
      );
      overwrite = overwrite.copyWith(
          allows: overwrite.allows | Permission.VIEW_CHANNEL.value,
          deny: overwrite.deny & ~Permission.VIEW_CHANNEL.value);
      res.add(overwrite);
    }
    await PermissionModel.updateOverwrites(res);
    Get.back();
    update();
  }

  /// 移除用户/角色的查看频道权限
  void deleteViewChannelPermission(PermissionOverwrite overwrite, String name) {
    showConfirmDialog(
        title: '确定删除“$name”吗？删除后该用户将无法查看频道内容',
        confirmText: '确定删除',
        confirmStyle:
            Get.textTheme.bodyText2.copyWith(color: const Color(0xFFF24848)),
        onConfirm: () async {
          overwrite.allows &= ~Permission.VIEW_CHANNEL.value;
          await PermissionModel.updateOverwrite(overwrite);
          update();
          Get.back();
        });
  }

  bool canChangePermission(Role role) {
    // 不能修改超管角色
    if (PermissionUtils.contains(role.permissions, Permission.ADMIN.value))
      return false;
    // 如果本人是超管，那就可以操作
    if (PermissionUtils.oneOf(gp, [Permission.ADMIN])) return true;
    // 最后判断角色等级
    return PermissionUtils.comparePosition(roleIds: [role.id]) == 1;
  }

  @override
  String get guildPermissionMixinId =>
      ChatTargetsModel.instance.selectedChatTarget.id;

  @override
  void onPermissionChange() {
    reset();
  }
}
