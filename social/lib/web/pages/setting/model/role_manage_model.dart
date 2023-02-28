import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/api/role_api.dart';
import 'package:im/common/permission/permission.dart';
import 'package:im/common/permission/permission_mixin.dart';
import 'package:im/common/permission/permission_model.dart';
import 'package:im/common/permission/permission_utils.dart';
import 'package:im/global.dart';
import 'package:im/pages/guild_setting/role/role.dart';
import 'package:im/utils/show_confirm_dialog.dart';
import 'package:im/web/widgets/web_form_detector/web_form_detector_model.dart';
import 'package:oktoast/oktoast.dart';
import 'package:provider/provider.dart';

class RoleManageModel extends ChangeNotifier with GuildPermissionListener {
  final String guildId;
  final BuildContext context;
  TextEditingController _nameController;

  TextEditingController get nameController => _nameController;

  bool orderChanged = false;
  int maxRolePosition = 0;
  bool createLoading = false;
  bool deleteLoading = false;
  bool saveLoading = false;

  List<Role> _originList = [];

  List<Role> _cacheList = [];

  List<Role> get cacheList => _cacheList;

  List<Role> _unchangedList = [];

  List<Role> get unchangedList => _unchangedList;

  List<Role> _orderList = [];

  List<Role> get orderList => _orderList;

  Role _editingRole;

  Role get editingRole => _editingRole;

  List<Permission> _generalPermissions;

  List<Permission> get generalPermissions => _generalPermissions;

  List<Permission> _textPermissions;

  List<Permission> get textPermissions => _textPermissions;

  List<Permission> _audioPermissions;

  List<Permission> get audioPermissions => _audioPermissions;

  /// 圈子权限
  List<Permission> _circlePermissions;

  List<Permission> get circlePermissions => _circlePermissions;

  GuildPermission get gp => guildPermission;

  RoleManageModel(this.context, this.guildId) {
    addPermissionListener();
    reset();
    _nameController = TextEditingController(text: _editingRole?.name ?? '');
  }

  void reset() {
    syncRoleList();
    _editingRole = _cacheList.firstWhere(
        (element) => element.id == _editingRole?.id,
        orElse: () => _cacheList.last);
    _nameController = TextEditingController(text: _editingRole?.name ?? '');
    generatePermissionItems();
    notifyListeners();
  }

  void syncRoleList() {
    maxRolePosition = PermissionUtils.getMaxRolePosition();
    _originList = guildPermission.roles.map((e) => e.clone()).toList();
    _cacheList = guildPermission.roles.map((e) => e.clone()).toList();
    _unchangedList =
        _cacheList.where((e) => e.position >= maxRolePosition).toList();
    _orderList = _cacheList
        .where((e) => e.position < maxRolePosition && e.id != guildId)
        .toList();
  }

  @override
  void dispose() {
    disposePermissionListener();
    super.dispose();
  }

  Future<void> createRole() async {
    final Role role = await RoleApi.create(
        guildId: guildPermission.guildId, userId: Global.user.id);
    final int roleIdx =
        _cacheList.indexWhere((element) => element.id == role.id);
    if (roleIdx < 0) {
      _cacheList.insert(_cacheList.length - 1, role);
      resetPosition(_cacheList);
      await PermissionModel.updateRoles(guildPermission.guildId, _cacheList);
      syncRoleList();
    }
    _editingRole = _cacheList.firstWhere((element) => element.id == role.id);
    _nameController
      ..text = role.name.trim()
      ..selection = TextSelection.collapsed(offset: role.name.trim().length);
    notifyListeners();
  }

  void onReorder(int oldIndex, int newIndex) {
    final Role role = _orderList.removeAt(oldIndex);
    _orderList.insert(newIndex, role);
    resetPosition(_orderList);
    checkFormChanged();
    notifyListeners();
  }

  /// 移除 role
  Future removeRole(Role role) async {
    await RoleApi.delete(
        guildId: guildPermission.guildId,
        userId: Global.user.id,
        roleId: role.id);
    _cacheList.removeWhere((e) => e.id == role.id);
    resetPosition(_cacheList);
    _editingRole = _cacheList.firstWhere(
        (element) => element.id == _editingRole?.id,
        orElse: () => _cacheList.last);
    _nameController
      ..text = _editingRole.name.trim()
      ..selection =
          TextSelection.collapsed(offset: _editingRole.name.trim().length);
    notifyListeners();
    await PermissionModel.updateRoles(guildPermission.guildId, _cacheList);
  }

  Future<void> onDelete(Role role) async {
    final res = await showConfirmDialog(
        title: '删除角色'.tr,
        content:
            '确定将 %s 删除？删除后，该角色下的成员权限配置将重新计算，一旦删除不可撤销。'.trArgs([role.name]));
    if (res == true) {
      await removeRole(role);
      _cacheList.remove(role);
      resetPosition(_cacheList);
      await PermissionModel.updateRoles(guildId, _cacheList);
      syncRoleList();
      checkFormChanged();
      notifyListeners();
    }
  }

  /// 重新排序 role list
  void resetPosition(List<Role> list) {
    final includeEveryone = list.any((element) => element.id == guildId);
    for (var i = 0; i < list.length; i++) {
      list[i]
          .setPosition(includeEveryone ? list.length - i - 1 : list.length - i);
    }
  }

  void toggleRole(Role role) {
    _editingRole = _cacheList.firstWhere((element) => element.id == role.id,
        orElse: () => null);
    _nameController.text = role.name;
    if (!isEveryone) {
      _nameController.selection =
          TextSelection.collapsed(offset: role.name.trim().length);
    }
    generatePermissionItems();
    notifyListeners();
  }

  void changePermission(bool v, Permission p, bool hasPermission) {
    if (!hasPermission) {
      showToast('无法操作当前自己没有的权限'.tr);
      return;
    }
    final permissionRole = guildPermission.roles.firstWhere(
        (element) => element.id == _editingRole.id,
        orElse: () => null);
    final permissionRoleValue = permissionRole.permissions;
    int newValue = _editingRole.permissions;
    if (v) {
      newValue = newValue | p.value;
    } else {
      newValue = newValue & ~p.value;
      permissionRole.permissions = newValue;
      final res = PermissionUtils.oneOf(guildPermission, [p]);
      if (!res) {
        showConfirmDialog(
          title: '注意'.tr,
          confirmText: '我知道了'.tr,
          content:
              '一旦关闭当前角色的该权限，将导致自己失去该权限。建议：先对自己或自己的其他角色打开该权限，再关闭当前角色的该权限。'.tr,
          showCancelButton: false,
        );
        permissionRole.permissions = permissionRoleValue;
        return;
      }
      permissionRole.permissions = permissionRoleValue;
    }
    _editingRole.permissions = newValue;
    checkFormChanged();
    notifyListeners();
  }

  void generatePermissionItems() {
    _generalPermissions = classifyPermissions[PermissionType.general]
        .where((element) =>
            !(isEveryone &&
                PermissionUtils.isEveryoneDisablePermission(element)) &&
            element != Permission.VIEW_CHANNEL)
        .toList();

    _textPermissions = classifyPermissions[PermissionType.text]
        .where((element) => !(isEveryone &&
            PermissionUtils.isEveryoneDisablePermission(element)))
        .toList();

    _audioPermissions = classifyPermissions[PermissionType.voice]
        .where((element) => !(isEveryone &&
            PermissionUtils.isEveryoneDisablePermission(element)))
        .toList();

    _circlePermissions = classifyPermissions[PermissionType.topic]
        .where((element) => !(isEveryone &&
            PermissionUtils.isEveryoneDisablePermission(element)))
        .toList();
  }

  void changeColor(Color color) {
    _editingRole.color = color.value;
    checkFormChanged();
    notifyListeners();
  }

  void changeName(String name) {
    _editingRole.name = name.trim();
    checkFormChanged();
    notifyListeners();
  }

  bool get isEveryone => editingRole?.id == guildId;

  bool get formChanged {
    bool changeFlag = false;
    if (_originList.length != _cacheList.length) {
      return true;
    }
    for (int i = 0; i < _cacheList.length; i++) {
      final cache = _cacheList[i];
      final origin = _originList[i];
      if (cache.name != origin.name ||
          cache.position != origin.position ||
          cache.permissions != origin.permissions ||
          cache.color != origin.color) {
        changeFlag = true;
        break;
      }
    }
    return changeFlag;
  }

  void checkFormChanged() {
    Provider.of<WebFormDetectorModel>(context, listen: false)
        .toggleChanged(formChanged);
  }

  Future<void> onConfirm() async {
    bool positionChanged = false;
    final List<Future> requests = [];
    // 先批量请求更改角色字段，再请求角色排序
    for (final cache in [..._orderList, _cacheList.last]) {
      final origin = _originList.firstWhere((element) => element.id == cache.id,
          orElse: () => null);
      if (origin != null) {
        final nameChanged = origin.name != cache.name && cache.name.isNotEmpty;
        // 角色为空的时候需还原
        if (cache.name.isEmpty) cache.name = origin.name;
        final colorChanged = origin.color != cache.color;
        final permissionChanged = origin.permissions != cache.permissions;
        if (nameChanged || colorChanged || permissionChanged) {
          // 不需要改的字段不传
          requests.add(RoleApi.save(
            guildId,
            Global.user.id,
            origin.id,
            name: nameChanged ? cache.name : null,
            color: colorChanged ? cache.color : null,
            permissions: permissionChanged ? cache.permissions : null,
          ));
        }
        // 角色位置改变
        if (!positionChanged && origin.position != cache.position) {
          positionChanged = true;
          final List<Map<String, dynamic>> roles = _orderList
              .map((e) => {'id': e.id, 'position': e.position})
              .toList();
          requests.add(RoleApi.order(
            guildId: guildId,
            userId: Global.user.id,
            roles: roles,
          ));
        }
      }
    }
    await Future.wait(requests);
    _cacheList.sort((a, b) => b.position.compareTo(a.position));
    await PermissionModel.updateRoles(guildId, _cacheList);
    syncRoleList();
    _editingRole = _cacheList.firstWhere(
        (element) => element.id == _editingRole?.id,
        orElse: () => _cacheList.last);
    checkFormChanged();
  }

  void onReset() {
    syncRoleList();
    _editingRole = _cacheList.firstWhere(
        (element) => element.id == _editingRole?.id,
        orElse: () => null);
    _nameController
      ..text = _editingRole.name
      ..selection =
          TextSelection.collapsed(offset: _editingRole.name.trim().length);
    checkFormChanged();
    notifyListeners();
  }

  @override
  String get guildPermissionMixinId => guildId;

  @override
  void onPermissionChange() {
    if (hasListeners) reset();
  }
}
