import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/api/data_model/user_info.dart';
import 'package:im/api/role_api.dart';
import 'package:im/common/permission/permission.dart';
import 'package:im/common/permission/permission_mixin.dart';
import 'package:im/common/permission/permission_model.dart';
import 'package:im/common/permission/permission_utils.dart';
import 'package:im/global.dart';
import 'package:im/pages/home/model/chat_index_model.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/pages/member_list/model/member_list_model.dart';
import 'package:im/utils/show_confirm_dialog.dart';
import 'package:im/web/widgets/web_form_detector/web_form_detector_model.dart';
import 'package:oktoast/oktoast.dart';
import 'package:pedantic/pedantic.dart';
import 'package:provider/provider.dart';

class ChannelPermissionModel extends ChangeNotifier
    with GuildPermissionListener {
  String get channelId => channel.id;
  final ChatChannel channel;
  final BuildContext context;
  List<PermissionOverwrite> _originList = [];
  List<PermissionOverwrite> _cacheList = [];
  List<PermissionOverwrite> _roleList = [];
  List<PermissionOverwrite> _memberList = [];

  UnmodifiableListView<PermissionOverwrite> get roleList =>
      UnmodifiableListView(_roleList);
  UnmodifiableListView<PermissionOverwrite> get memberList =>
      UnmodifiableListView(_memberList);

  PermissionOverwrite _editingOverwrite;
  PermissionOverwrite get editingOverwrite => _editingOverwrite;

  GuildPermission get gp => guildPermission;
  ChannelPermissionModel(this.context, this.channel) {
    addPermissionListener();
    reset();
  }
  void reset() {
    _originList = guildPermission.channelPermission
            .firstWhere((element) => element.channelId == channelId,
                orElse: () => null)
            ?.overwrites ??
        [];
    syncOverwriteCache();
    _sortByRolePosition();
    _editingOverwrite = _cacheList.firstWhere(
        (element) => element.id == _editingOverwrite?.id,
        orElse: () => _roleList.last);
    notifyListeners();
  }

  // ???????????????overwrite???????????????overwrite?????????????????????????????????????????????????????????
  void syncOverwriteCache() {
    _cacheList = _originList.map((e) => e.copyWith()).toList();
  }

  void destroy() {
    disposePermissionListener();
    dispose();
  }

  /// ??????????????????????????? role position??????
  void _sortByRolePosition() {
    _memberList = _cacheList
        .where((element) =>
            element.actionType == 'user' &&
            MemberListModel.instance.fullList.contains(element.id))
        .toList();
    _roleList = _cacheList
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

  Future removeOverwrite(PermissionOverwrite overwrite) async {
    await RoleApi.deleteOverwrite(
      id: overwrite.id,
      guildId: overwrite.guildId,
      userId: Global.user.id,
      channelId: overwrite.channelId,
    );
    if (_editingOverwrite == overwrite) {
      _editingOverwrite = _roleList.last;
    }
    _originList.removeWhere((e) => e.id == overwrite.id);
    _cacheList.removeWhere((e) => e.id == overwrite.id);
    _sortByRolePosition();
    checkFormChanged();
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

  void toggleOverwrite(String overwriteId) {
    _editingOverwrite = _cacheList
        .firstWhere((element) => element.id == overwriteId, orElse: () => null);
    notifyListeners();
  }

  bool get isEveryone => editingOverwrite?.id == guildPermission.guildId;

  Future<void> onChange(int val, Permission p, bool hasPermission) async {
    if (!hasPermission) {
      showToast('???????????????????????????????????????'.tr);
      return;
    }

    // ????????????everyOne??????????????????????????????
    if (isEveryone && ((p.value & Permission.VIEW_CHANNEL.value) > 0)) {
      if (_editingOverwrite.deny & p.value & Permission.VIEW_CHANNEL.value >
          0) {
        // ?????????????????????????????????????????????????????????
        final bool isConfirm = await showConfirmDialog(
          title: "??????????????????????????????????????????".tr,
          content: "????????????????????????????????????????????????????????????????????????????????????????????????????????????".tr,
        );
        if (isConfirm == null || !isConfirm) return;
      } else if (val == 0) {
        // ????????????????????????????????????????????????
        final bool isConfirm = await showConfirmDialog(
          title: "??????????????????????????????????????????".tr,
          content: "??????????????????????????????????????????????????????????????????????????????????????????????????????????????????".tr,
        );
        if (isConfirm == null || !isConfirm) return;
      }
    }

    int newAllows = _editingOverwrite.allows;
    int newDeny = _editingOverwrite.deny;
    final int oldAllows = _editingOverwrite.allows;
    final int oldDeny = _editingOverwrite.deny;
    switch (val) {
      case 0:
        if (_editingOverwrite.deny & p.value > 0) return;
        if (_editingOverwrite.allows & p.value > 0) {
          newAllows = _editingOverwrite.allows & ~p.value;
          newDeny = _editingOverwrite.deny | p.value;
        } else {
          newDeny = _editingOverwrite.deny | p.value;
        }
        _editingOverwrite.allows = newAllows;
        _editingOverwrite.deny = newDeny;
        final res =
            PermissionUtils.oneOf(guildPermission, [p], channelId: channelId);
        if (!res) {
          unawaited(showConfirmDialog(
            title: '?????????????????????'.tr,
            confirmText: '????????????'.tr,
            content: '??????????????????????????????????????????????????????????????????????????????'.tr,
            showCancelButton: false,
          ));
          _editingOverwrite.allows = oldAllows;
          _editingOverwrite.deny = oldDeny;
          return;
        }

        break;
      case -1:
        if ((_editingOverwrite.deny & p.value) > 0) {
          _editingOverwrite.deny = _editingOverwrite.deny & ~p.value;
        } else if (_editingOverwrite.allows & p.value > 0) {
          _editingOverwrite.allows = _editingOverwrite.allows & ~p.value;
        }
        break;
      case 1:
        if (_editingOverwrite.allows & p.value > 0) return;
        if ((_editingOverwrite.deny & p.value) > 0) {
          _editingOverwrite.deny = _editingOverwrite.deny & ~p.value;
          _editingOverwrite.allows = _editingOverwrite.allows | p.value;
        } else {
          _editingOverwrite.allows = _editingOverwrite.allows | p.value;
        }
        break;
      default:
    }
    checkFormChanged();
    notifyListeners();
  }

  bool get formChanged {
    bool changeFlag = false;
    for (int i = 0; i < _cacheList.length; i++) {
      final cache = _cacheList[i];
      final origin = _originList.firstWhere((element) => element.id == cache.id,
          orElse: () => null);
      if (origin == null) continue;
      changeFlag = cache.allows != origin.allows || cache.deny != origin.deny;
      if (changeFlag) break;
    }
    return changeFlag;
  }

  void checkFormChanged() {
    Provider.of<WebFormDetectorModel>(context, listen: false)
        .toggleChanged(formChanged);
  }

  Future<void> onConfirm() async {
    final List<Future> futures = [];
    for (int i = 0; i < _cacheList.length; i++) {
      final cache = _cacheList[i];
      final origin = _originList.firstWhere((element) => element.id == cache.id,
          orElse: () => null);
      if (origin == null) continue;
      if (cache.allows != origin.allows || cache.deny != origin.deny) {
        futures.add(PermissionModel.updateOverwrite(cache));
      }
    }
    await Future.wait(futures);
    syncOverwriteCache();
    _editingOverwrite = _cacheList.firstWhere(
        (element) => element.id == _editingOverwrite.id,
        orElse: () => null);
    checkFormChanged();
  }

  void onReset() {
    syncOverwriteCache();
    _editingOverwrite = _cacheList.firstWhere(
        (element) => element.id == _editingOverwrite.id,
        orElse: () => null);
    notifyListeners();
    checkFormChanged();
  }
}
