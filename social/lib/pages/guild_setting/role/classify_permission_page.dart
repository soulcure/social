import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/app/routes/app_pages.dart';
import 'package:im/common/permission/permission.dart';
import 'package:im/common/permission/permission_model.dart';
import 'package:im/common/permission/permission_state.dart';
import 'package:im/common/permission/permission_utils.dart';
import 'package:im/pages/guild_setting/role/role.dart';
import 'package:im/themes/const.dart';
import 'package:im/themes/default_theme.dart';
import 'package:im/utils/show_confirm_dialog.dart';
import 'package:im/widgets/app_bar/appbar_button.dart';
import 'package:im/widgets/app_bar/custom_appbar.dart';
import 'package:im/widgets/link_tile.dart';
import 'package:oktoast/oktoast.dart';

/// 服务器权限管理 设置界面
class ClassifyPermissionPage extends StatefulWidget {
  /// 服务器ID
  final String guildId;

  /// 角色ID
  final String roleId;

  final Role role;

  const ClassifyPermissionPage({
    this.roleId,
    @required this.guildId,
    this.role,
  });

  @override
  _ClassifyPermissionPageState createState() => _ClassifyPermissionPageState();
}

class _ClassifyPermissionPageState
    extends PermissionState<ClassifyPermissionPage> {
  GuildPermission originGuildPermission;
  int originValue;
  int newValue;
  List<Permission> _generalPermissions;
  List<Permission> _textPermissions;

  // List<Permission> _livePermissions;
  List<Permission> _audioPermissions;
  List<Permission> _circlePermissions;
  ThemeData _theme;
  bool _loading = false;
  bool _isEveryone;

  // Role _originRole;

  Role get _role => widget.role;

  @override
  void initPermissionState() {
    _isEveryone = widget.guildId == widget.roleId;
    _generalPermissions = classifyPermissions[PermissionType.general]
        .where((element) => !(_isEveryone &
            PermissionUtils.isEveryoneDisablePermission(element)))
        // .where((element) => element.value != Permission.VIEW_CHANNEL.value) // 查看频道权限在服务器权限管理中不可见
        .toList();

    _textPermissions = classifyPermissions[PermissionType.text]
        .where((element) => !(_isEveryone &
            PermissionUtils.isEveryoneDisablePermission(element)))
        .toList();

    ///支付入口开关，决定是否显示直播权限
    // if (ServerSideConfiguration.to.payIsOpen) {
    //   _livePermissions = classifyPermissions[PermissionType.live]
    //       .where((element) => !(_isEveryone &
    //           PermissionUtils.isEveryoneDisablePermission(element)))
    //       .toList();
    // } else {
    //   _livePermissions = [];
    // }

    _audioPermissions = classifyPermissions[PermissionType.voice]
        .where((element) => !(_isEveryone &
            PermissionUtils.isEveryoneDisablePermission(element)))
        .toList();

    // 圈子权限
    _circlePermissions = classifyPermissions[PermissionType.topic]
        .where((element) => !(_isEveryone &
            PermissionUtils.isEveryoneDisablePermission(element)))
        .toList();

    addPermissionListener();
    init();
  }

  @override
  String get guildId => widget.guildId;

  void init() {
    // _role = guildPermission.roles.firstWhere(
    //     (element) => element.id == widget.roleId,
    //     orElse: () => null);

    /// 此处做用户角色深拷贝
    final copyList = guildPermission.roles
        .map((e) => Role(
            id: e.id,
            name: e.name,
            position: e.position,
            hoist: e.hoist,
            permissions: e.permissions,
            color: e.color,
            managed: e.managed,
            mentionable: e.mentionable))
        .toList();
    originGuildPermission = GuildPermission(
        roles: copyList,
        permissions: guildPermission.permissions,
        ownerId: guildPermission.ownerId,
        guildId: guildPermission.guildId);
    // _originRole = originGuildPermission.roles.firstWhere(
    //     (element) => element.id == widget.roleId,
    //     orElse: () => null);

    originValue = _role.permissions;
    newValue = _role.permissions;
  }

  @override
  void dispose() {
    disposePermissionListener();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_role == null) return const SizedBox();
    _theme = Theme.of(context);
    return Scaffold(
      appBar: CustomAppbar(
        title: '服务器权限管理'.tr,
        leadingCallback: () async {
          if (newValue != originValue) {
            final res = await showConfirmDialog(
                title: '退出后将撤销本次设置，确定退出吗？'.tr,
                confirmText: '确定'.tr,
                confirmStyle: Theme.of(context)
                    .textTheme
                    .bodyText2
                    .copyWith(fontSize: 16, color: primaryColor),
                barrierDismissible: true);
            if (res == true) {
              Get.back();
            }
          } else {
            Get.back();
          }
        },
        actions: [
          if (newValue != originValue)
            AppbarTextButton(
              loading: _loading,
              onTap: _onSave,
              text: '保存'.tr,
            )
        ],
      ),
      body: ListView(
        children: <Widget>[
          sizeHeight20,
          _buildRoleName(),
          _buildSubtitle('通用权限'.tr),
          ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                return _buildItem(_generalPermissions[index], index);
              },
              itemCount: _generalPermissions.length),
          _buildSubtitle('文字频道权限'.tr),
          ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                return _buildItem(_textPermissions[index], index);
              },
              itemCount: _textPermissions.length),
          // if (ServerSideConfiguration.to.payIsOpen) _buildSubtitle('直播频道权限'.tr),
          // ListView.builder(
          //     shrinkWrap: true,
          //     physics: const NeverScrollableScrollPhysics(),
          //     itemBuilder: (context, index) {
          //       return _buildItem(_livePermissions[index], index);
          //     },
          //     itemCount: _livePermissions.length),
          _buildSubtitle('语音频道权限'.tr),
          ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                return _buildItem(_audioPermissions[index], index);
              },
              itemCount: _audioPermissions.length),
          _buildSubtitle('圈子权限'.tr),
          ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                return _buildItem(_circlePermissions[index], index);
              },
              itemCount: _circlePermissions.length),
        ],
      ),
    );
  }

  Widget _buildRoleName() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: _theme.backgroundColor,
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              _role.name.tr,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  color: _role.color == 0
                      ? Theme.of(context).textTheme.bodyText2.color
                      : Color(
                          _role.color,
                        )),
            ),
          ),
          sizeWidth10,
          Text(
            '范围：服务器'.tr,
            style: _theme.textTheme.bodyText1.copyWith(fontSize: 15),
          ),
        ],
      ),
    );
  }

  Widget _buildSubtitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.bodyText1.copyWith(fontSize: 14),
      ),
    );
  }

  Widget _buildItem(Permission p, int index) {
//        PermissionUtils.hasPermissionInOtherRole(gp.value, p, widget.roleId);
    final bool hasPermission = PermissionUtils.oneOf(guildPermission, [p]);
    final bool disabled = !hasPermission;

    return LinkTile(
        context,
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              p.name1.tr,
              style: TextStyle(
                  color: disabled
                      ? _theme.textTheme.bodyText2.color.withOpacity(0.4)
                      : _theme.textTheme.bodyText2.color),
            ),
            if (p.desc1.isNotEmpty) sizeHeight5,
            if (p.desc1.isNotEmpty)
              Text(
                p.desc1,
                style: Theme.of(context)
                    .textTheme
                    .bodyText1
                    .copyWith(fontSize: 14),
              )
          ],
        ),
        showTrailingIcon: false,
        trailing: Row(
          children: <Widget>[
            Opacity(
              opacity: disabled ? 0.4 : 1,
              child: Transform.scale(
                scale: 0.9,
                alignment: Alignment.centerRight,
                child: CupertinoSwitch(
                    activeColor: Theme.of(context).primaryColor,
                    value: newValue & p.value != 0,
                    onChanged: (v) => _toggle(v, p, hasPermission)),
              ),
            )
          ],
        ));
  }

  void _toggle(bool select, Permission permission, bool hasPermission) {
    if (_loading) return;
    if (!hasPermission) {
      showToast('无法操作当前自己没有的权限'.tr);
      return;
    }

    setState(() {
      if (select) {
        newValue = newValue | permission.value;
      } else {
        newValue = newValue & ~permission.value;
        _role.permissions = newValue;

        final res = PermissionUtils.oneOf(originGuildPermission, [permission]);
        if (!res) {
          showConfirmDialog(
            title: '注意'.tr,
            confirmText: '我知道了'.tr,
            content:
                '一旦关闭当前角色的该权限，将导致自己失去该权限。建议：先对自己或自己的其他角色打开该权限，再关闭当前角色的该权限。'.tr,
            showCancelButton: false,
          );
          return;
        }
      }
    });
  }

  Future<void> _onSave() async {
    try {
      _toggleLoading(true);
      await PermissionModel.updateRole(widget.guildId, _role.id,
          permissions: newValue);
      _toggleLoading(false);
      Navigator.of(context).pop(newValue);
      _role.permissions = newValue;
    } catch (e) {
      _toggleLoading(false);
    }
  }

  void _toggleLoading(bool value) {
    setState(() {
      _loading = value;
    });
  }

  @override
  void onPermissionStateChange() {
    final newRole = guildPermission.roles.firstWhere(
        (element) => element.id == widget.roleId,
        orElse: () => null);
    if (newRole == null) {
      Get.until((route) => route.settings.name == Routes.GUILD_ROLE_MANAGER);
      return;
    }
    if (newRole.permissions != newValue) {
      showToast('当前页面有修改，请重新编辑'.tr);
      setState(() {
        originValue = _role.permissions;
        newValue = _role.permissions;
      });
    }
  }
}
