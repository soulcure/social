import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/common/permission/permission.dart';
import 'package:im/common/permission/permission_mixin.dart';
import 'package:im/common/permission/permission_model.dart';
import 'package:im/common/permission/permission_utils.dart';
import 'package:im/pages/home/model/chat_index_model.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/utils/show_confirm_dialog.dart';
import 'package:oktoast/oktoast.dart';
import 'package:pedantic/pedantic.dart';

class OverwriteModel extends ChangeNotifier with GuildPermissionListener {
  String get channelId => channel.id;
  final ChatChannel channel;
  final String overwriteId;
  final BuildContext context;

  /// 具体覆盖的权限
  PermissionOverwrite _overwrite;

  PermissionOverwrite get overwrite => _overwrite;
  bool _isEveryone;

  bool get isEveryone => _isEveryone;

  GuildPermission get gp => guildPermission;

  /// 是否是圈子权限
  bool get isCirclePermission =>
      channel != null && channel.type == ChatChannelType.guildCircleTopic;

  OverwriteModel(this.context, {this.channel, this.overwriteId}) {
    addPermissionListener();
    _overwrite = PermissionOverwrite(
        guildId: '0',
        channelId: '0',
        deny: 0,
        allows: 0,
        id: '0',
        actionType: 'user',
        name: '');
    _isEveryone = overwriteId == guildPermission.guildId;
    reset();
  }

  void reset() {
    final ChannelPermission channelPermission = guildPermission
        .channelPermission
        .firstWhere((element) => element.channelId == channelId,
            orElse: () => null);
    _overwrite = channelPermission?.overwrites?.firstWhere(
      (element) => element.id == overwriteId,
      orElse: () => null,
    );
    notifyListeners();
  }

  void destroy() {
    disposePermissionListener();
    dispose();
  }

  Future<void> onChange(int val, Permission p, bool hasPermission) async {
    if (!hasPermission) {
      showToast('无法操作当前自己没有的权限'.tr);
      return;
    }

    // 拦截修改everyOne的频道可见性权限修改
    if (_isEveryone && ((p.value & Permission.VIEW_CHANNEL.value) > 0)) {
      if (_overwrite.deny & p.value & Permission.VIEW_CHANNEL.value > 0) {
        // 如果私密频道切公开，则需要展示二次确认
        final bool isConfirm = await showConfirmDialog(
          title: "确认将私密频道设为公开频道？".tr,
          content: "打开“查看频道”权限会将此频道转为公开频道，频道的消息将会对所有成员可见".tr,
        );
        if (isConfirm == null || !isConfirm) return;
      } else if (val == 0) {
        // 如果公开转私，则需要展示二次确认
        final bool isConfirm = await showConfirmDialog(
          title: "确认将公开频道设为私密频道？".tr,
          content: "关闭“查看频道”权限会将此频道转为私密频道，未赋予权限的角色和成员将无法查看".tr,
        );
        if (isConfirm == null || !isConfirm) return;
      }
    }

    int newAllows = _overwrite.allows;
    int newDeny = _overwrite.deny;
    final int oldAllows = _overwrite.allows;
    final int oldDeny = _overwrite.deny;
    switch (val) {
      case 0:
        if (_overwrite.deny & p.value > 0) return;
        if (_overwrite.allows & p.value > 0) {
          newAllows = _overwrite.allows & ~p.value;
          newDeny = _overwrite.deny | p.value;
        } else {
          newDeny = _overwrite.deny | p.value;
        }
        _overwrite.allows = newAllows;
        _overwrite.deny = newDeny;
        final res =
            PermissionUtils.oneOf(guildPermission, [p], channelId: channelId);
        if (!res) {
          unawaited(showConfirmDialog(
            title: '不能修改此权限'.tr,
            confirmText: '我知道了'.tr,
            content: '一旦修改当前角色的该权限，可能将导致自己失去该权限。'.tr,
            showCancelButton: false,
          ));
          _overwrite.allows = oldAllows;
          _overwrite.deny = oldDeny;
          return;
        }

        break;
      case -1:
        if ((_overwrite.deny & p.value) > 0) {
          newDeny = _overwrite.deny & ~p.value;
        } else if (_overwrite.allows & p.value > 0) {
          newAllows = _overwrite.allows & ~p.value;
        }
        break;
      case 1:
        if (_overwrite.allows & p.value > 0) return;
        if ((_overwrite.deny & p.value) > 0) {
          newDeny = _overwrite.deny & ~p.value;
          newAllows = _overwrite.allows | p.value;
        } else {
          newAllows = _overwrite.allows | p.value;
        }
        break;
      default:
    }
    final newOverwrite = _overwrite.copyWith(allows: newAllows, deny: newDeny);

    try {
      await PermissionModel.updateOverwrite(newOverwrite,
          isCirclePermission: isCirclePermission);
    } catch (e) {
      _overwrite.allows = oldAllows;
      _overwrite.deny = oldDeny;
    }
  }

  @override
  String get guildPermissionMixinId =>
      ChatTargetsModel.instance.selectedChatTarget.id;

  @override
  void onPermissionChange() {
    reset();
  }
}
