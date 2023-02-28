import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/api/role_api.dart';
import 'package:im/common/permission/permission.dart';
import 'package:im/common/permission/permission_mixin.dart';
import 'package:im/common/permission/permission_model.dart';
import 'package:im/common/permission/permission_utils.dart';
import 'package:im/global.dart';
import 'package:im/icon_font.dart';
import 'package:im/routes.dart';
import 'package:im/themes/const.dart';
import 'package:im/themes/default_theme.dart';
import 'package:im/utils/show_confirm_dialog.dart';
import 'package:oktoast/oktoast.dart';
import 'package:pedantic/pedantic.dart';

import 'role.dart';

class RoleManageModel extends ChangeNotifier with GuildPermissionListener {
  final String guildId;
  final BuildContext context;

//  ValueNotifier<GuildPermission> gp;
  bool editing = false;
  bool orderChanged = false;
  int maxRolePosition = 0;
  bool createLoading = false;
  bool deleteLoading = false;
  bool saveLoading = false;

  List<Role> _list = [];

  List<Role> get list => _list;

  List<Role> _tempList = [];

  List<Role> get tempList => _tempList;

  GuildPermission get gp => guildPermission;

  RoleManageModel(this.context, this.guildId) {
    addPermissionListener();
    reset();
    refresh();
  }

  Future<void> refresh() async {
    final _roleMemberNumList = await RoleApi.getList(
        guildId: guildId, showDefaultErrorToast: false, size: 999);
    _roleMemberNumList.forEach((element) {
      for (final role in _list) {
        if (role.id == element.id) {
          role.memberCount = element.memberCount;
          role.hoist = element.hoist;
          role.managed = element.managed;
        }
      }
    });

    notifyListeners();
  }

  Future<void> reset() async {
    maxRolePosition = PermissionUtils.getMaxRolePosition();
    // 判断ui刷新条件，不处于编辑状态可以刷新
    if (!editing) {
      _list = [...guildPermission.roles];
    } else {
      final Function eq = const ListEquality().equals;
      final List<String> oldIds =
          guildPermission.roles.map((e) => e.id).toList();
      final List<String> newIds = _list.map((e) => e.id).toList();
      // 顺序未改变不需要重置编辑状态
      if (eq(oldIds, newIds)) {
        _list = [...guildPermission.roles];
        maxRolePosition = PermissionUtils.getMaxRolePosition();
      } else {
        showToast('当前页面有修改，请重新编辑'.tr);
        _list = [...guildPermission.roles];
        editing = false;
        orderChanged = false;
      }
    }
    notifyListeners();
  }

  @override
  void dispose() {
    disposePermissionListener();
    super.dispose();
  }

  Future<void> createRole() async {
    return Routes.pushRoleSettingPage(context, guildPermission.guildId,
        isCreateRole: true);
    //
    // if (createLoading) return;
    // createLoading = true;
    // try {
    //   final Role role = await RoleApi.create(
    //       guildId: guildPermission.guildId, userId: Global.user.id);
    //   final int roleIdx = _list.indexWhere((element) => element.id == role.id);
    //   if (roleIdx < 0) {
    //     _list.insert(_list.length - 1, role);
    //     resetPosition();
    //   }
    //   createLoading = false;
    //   unawaited(Routes.pushRoleSettingPage(
    //       context, guildPermission.guildId, role,
    //       isCreateRole: true));
    // } catch (e) {
    //   createLoading = false;
    // }
  }

  /// 更新整个role list
  Future saveRoleList(List<Role> roles) async {
    _list = roles;
    resetPosition();
  }

  void onReorder(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    orderChanged = true;
    final Role role = _tempList.removeAt(oldIndex);
    _tempList.insert(newIndex, role);
    for (var i = 0; i < _tempList.length; i++) {
      _tempList[i].setPosition(_tempList.length - i);
    }
    notifyListeners();
  }

  /// 移除 role
  Future removeRole(Role role) async {
    await RoleApi.delete(
        guildId: guildPermission.guildId,
        userId: Global.user.id,
        roleId: role.id);
    _tempList.removeWhere((e) => e.id == role.id);
    _list.removeWhere((e) => e.id == role.id);
    for (var i = 0; i < _tempList.length; i++) {
      _tempList[i].setPosition(_tempList.length - i - 1);
    }
    resetPosition();
  }

  Future<void> toggleEdit() async {
    if (editing) {
      if (tempList.isNotEmpty && orderChanged) {
        try {
          _toggleSaveLoading(true);
          final data = tempList
              .map((e) => {'id': e.id, 'position': e.position})
              .toList();
          await RoleApi.order(
              guildId: guildId, userId: Global.user.id, roles: data);
          unawaited(
              saveRoleList([...getUnchangeList(), ...tempList, _list.last]));
          orderChanged = false;
          _toggleSaveLoading(false);
          editing = false;
          notifyListeners();
        } catch (e) {
          _toggleSaveLoading(false);
        }
      } else {
        editing = false;
        notifyListeners();
      }
    } else {
      editing = true;
      notifyListeners();
      cacheOrderList();
    }
  }

  void cancelEdit() {
    editing = false;
    notifyListeners();
  }

  void _toggleSaveLoading(bool value) {
    saveLoading = value;
    notifyListeners();
  }

  Future<void> onDelete(Role role) async {
    if (deleteLoading) return;
    final res = await showConfirmDialog(
        title: '删除角色'.tr,
        content: '确定将 %s 删除？一旦删除不可撤销。'.trArgs([role.name]),
        confirmStyle: Theme.of(context)
            .textTheme
            .bodyText2
            .copyWith(fontSize: 16, color: primaryColor),
        barrierDismissible: true);
    if (res == true) {
      try {
        deleteLoading = true;
        await removeRole(role);
        if (_list.length == 1) {
          editing = false;
        }
        deleteLoading = false;
        notifyListeners();
        showToastWidget(
            UnconstrainedBox(
                child: Container(
              alignment: Alignment.center,
              height: 40,
              width: 125,
              decoration: BoxDecoration(
                  color: const Color(0xFF363940).withOpacity(0.98),
                  borderRadius: BorderRadius.circular(20)),
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(IconFont.buffToastOk,
                        size: 20, color: Colors.white),
                    sizeWidth8,
                    Text(
                      '移除成功'.tr,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                          height: 1),
                    )
                  ],
                ),
              ),
            )),
            duration: const Duration(milliseconds: 2000));
      } catch (e) {
        deleteLoading = false;
      }
    }
  }

  /// 重新排序 role list
  void resetPosition() {
    for (var i = 0; i < _list.length; i++) {
      _list[i].setPosition(_list.length - i - 1);
    }
    // 通知修改服务器权限
    PermissionModel.updateRoles(guildPermission.guildId, _list);
    notifyListeners();
  }

  /// 获取可编辑列表
  List<Role> getOrderList() {
    return editing
        ? _tempList
        : _list
            .where((element) =>
                element.position < maxRolePosition && !isEveryone(element))
            .toList();
  }

  void cacheOrderList() {
    _tempList = _list
        .where((element) =>
            element.position < maxRolePosition && !isEveryone(element))
        .map((e) => e.clone())
        .toList();
  }

  List<Role> getUnchangeList() {
    return _list
        .where((element) =>
            element.position >= maxRolePosition && !isEveryone(element))
        .toList();
  }

  bool isEveryone(Role role) => role.id == guildId;

  @override
  String get guildPermissionMixinId => guildId;

  @override
  void onPermissionChange() {
    if (hasListeners) reset();
  }
}
