import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:im/api/role_api.dart';
import 'package:im/app/routes/app_pages.dart';
import 'package:im/common/extension/string_extension.dart';
import 'package:im/common/permission/permission.dart';
import 'package:im/common/permission/permission_model.dart';
import 'package:im/common/permission/permission_state.dart';
import 'package:im/common/permission/permission_utils.dart';
import 'package:im/const.dart';
import 'package:im/core/widgets/button/fade_background_button.dart';
import 'package:im/global.dart';
import 'package:im/pages/guild_setting/role/color_picker.dart';
import 'package:im/themes/const.dart';
import 'package:im/themes/custom_color.dart';
import 'package:im/themes/default_theme.dart';
import 'package:im/utils/content_checker.dart';
import 'package:im/utils/orientation_util.dart';
import 'package:im/utils/show_bottom_modal.dart';
import 'package:im/utils/show_confirm_dialog.dart';
import 'package:im/utils/universal_platform.dart';
import 'package:im/widgets/app_bar/appbar_button.dart';
import 'package:im/widgets/app_bar/custom_appbar.dart';
import 'package:im/widgets/link_tile.dart';
import 'package:im/widgets/text_field/native_input.dart';
import 'package:oktoast/oktoast.dart';

import '../../../icon_font.dart';
import 'role.dart';

/// - 角色设置页面
class RoleSettingPage extends StatefulWidget {
  final String guildId;
  final String roleId;
  final bool isCreateRole;

  const RoleSettingPage(this.guildId, this.roleId, {this.isCreateRole = false});

  @override
  _RoleSettingPageState createState() => _RoleSettingPageState();
}

class _RoleSettingPageState extends PermissionState<RoleSettingPage> {
  TextEditingController _roleNameController;
  FocusNode _focusNode;
  bool _isEveryone = false;
  bool _canEdit = true;
  Role _newRole;
  Role _originalRole;
  bool isFirstBack = true;
  bool isShowRoleUser = true;
  bool _loading = false;
  bool _saveButtonEnable = true;

  GuildPermission originGuildPermission;
  int originValue;
  int newValue;
  List<Permission> _generalPermissions;
  List<Permission> _textPermissions;

  List<Permission> _audioPermissions;
  List<Permission> _circlePermissions;
  List<Permission> _advancePermissions;

  ThemeData _theme;

  @override
  String get guildId => widget.guildId;

  @override
  void initPermissionState() {
    _isEveryone = widget.guildId == widget.roleId;
    _roleNameController = TextEditingController();
    if (_canEdit)
      _focusNode = FocusNode()
        ..addListener(() async {
          final String roleName = _roleNameController.text.trim();
          if (!_focusNode.hasFocus && roleName != '' && roleName.length > 1) {
            //检测角色名称
            final textRes = await CheckUtil.startCheck(
                TextCheckItem(roleName, TextChannelType.CHANNEL_NAME),
                toastError: false);
            if (!textRes) {
              showToast('此内容包含违规信息,请修改后重试'.tr);
              return;
            }

            await PermissionModel.updateRole(widget.guildId, widget.roleId,
                name: roleName);
          }
        });

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
    _advancePermissions = classifyPermissions[PermissionType.advance]
        .where((element) => !(_isEveryone &
            PermissionUtils.isEveryoneDisablePermission(element)))
        .toList();

    addPermissionListener();
    onRoleChange(firstLoad: true);
    init();
  }

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

    originValue = _newRole.permissions;
    newValue = _newRole.permissions;
  }

  @override
  void onPermissionStateChange() {
    disposePermissionListener();
    onRoleChange();
  }

  void onRoleChange({bool firstLoad = false}) {
    if (!widget.isCreateRole) {
      _newRole = guildPermission.roles
          .firstWhere((element) => element.id == widget.roleId,
              orElse: () => null)
          ?.clone();

      if (_newRole == null) {
        Get.until((route) => route.settings.name == Routes.GUILD_ROLE_MANAGER);
        return;
      }
    } else {
      _newRole ??= Role(id: '', name: '新角色', position: 0);
      _newRole.permissions = guildPermission.permissions;
    }

    _originalRole = _newRole?.clone();
    if (_newRole == null) {
      /// onRoleChange由于会进多次,导致界面back多次,所以加了isFirstBack变量
      if (isFirstBack) Get.back();
      isFirstBack = false;
      return;
    }
    _canEdit = PermissionUtils.getMaxRolePosition() > _newRole.position &&
        !_isEveryone;
    _roleNameController.value =
        TextEditingValue(text: _newRole?.name?.tr ?? '');

    originValue = _newRole.permissions;
    newValue = _newRole.permissions;

    if (_newRole.permissions != newValue) {
      showToast('当前页面有修改，请重新编辑'.tr);
      setState(() {
        originValue = _newRole.permissions;
        newValue = _newRole.permissions;
      });
    }

    if (!firstLoad && mounted) setState(() {});
  }

  @override
  void dispose() {
    _roleNameController?.dispose();
    _focusNode?.dispose();
    disposePermissionListener();
    super.dispose();
  }

  Future<bool> back() async {
    bool hasModify = false;
    if (!_newRole.equal(_originalRole)) hasModify = true;
    if (hasModify && !widget.isCreateRole) {
      final res = await showConfirmDialog(
          title: '确定保存并退出？'.tr,
          confirmText: '确定'.tr,
          cancelText: '取消'.tr,
          confirmStyle: Theme.of(context)
              .textTheme
              .bodyText2
              .copyWith(fontSize: 16, color: primaryColor),
          barrierDismissible: true);
      if (res == null) return false;
      if (res == true) {
        await _onSave();
      } else {
        Get.back();
      }
    } else {
      Get.back();
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    if (_newRole == null) return const SizedBox();
    // final permissionNum = _computePermissionNum();
    _theme = Theme.of(context);
    Color roleColor;
    if (_newRole.color != 0) {
      roleColor = Color(_newRole.color);
    } else {
      roleColor = _theme.textTheme.bodyText1.color;
    }

    return WillPopScope(
      onWillPop: UniversalPlatform.isAndroid ? back : null,
      child: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: Scaffold(
          backgroundColor: const Color(0xFFF5F5F8),
          appBar: CustomAppbar(
            title:
                widget.isCreateRole ? '创建角色'.tr : _originalRole.name.breakWord,
            leadingCallback: () {
              back();
            },
            actions: [
              // if (newOverwrite.allows != originOverwrite.allows ||
              //     newOverwrite.deny != originOverwrite.deny)
              AppbarTextButton(
                loading: _loading,
                enable: _saveButtonEnable,
                onTap: _onSave,
                text: '保存'.tr,
              )
            ],
          ),
          body: ListView(
            children: <Widget>[
              Padding(
                padding: EdgeInsets.only(
                    top: widget.isCreateRole ? 16 : 26, left: 16, bottom: 8),
                child: Text(
                  widget.isCreateRole ? '角色名称'.tr : '基础信息'.tr,
                  style: Theme.of(context)
                      .textTheme
                      .bodyText1
                      .copyWith(fontSize: 14),
                ),
              ),
              if (widget.isCreateRole)
                Container(
                  height: 52,
                  color: Theme.of(context).backgroundColor,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: NativeInput(
                          decoration: InputDecoration.collapsed(
                            hintText: '请输入角色名称'.tr,
                            hintStyle: const TextStyle(
                                fontSize: 16, color: Color(0xff8F959E)),
                          ),
                          maxLengthEnforcement: MaxLengthEnforcement.none,
                          controller: _roleNameController,
                          onChanged: (val) {
                            setState(() {
                              _newRole.name = val;
                              _saveButtonEnable = val.isNotEmpty;
                            });
                          },
                        ),
                      ),
                      if (_roleNameController.text.trim().isNotEmpty)
                        GestureDetector(
                          onTap: () {
                            _roleNameController.clear();
                            setState(() {
                              _saveButtonEnable =
                                  _roleNameController.text.trim().isNotEmpty;
                            });
                          },
                          child: Icon(
                            IconFont.buffClose,
                            size: OrientationUtil.portrait ? 16 : 18,
                            color: const Color(0x7F8F959E),
                          ),
                        )
                      else
                        const SizedBox(),
                      sizeWidth6,
                      RichText(
                        text: TextSpan(
                            text:
                                '${_roleNameController.text.trim().characters.length}',
                            style: TextStyle(
                              fontSize: 14,
                              color: _roleNameController.text
                                          .trim()
                                          .characters
                                          .length >
                                      maxRoleNameLength
                                  ? Theme.of(context).errorColor
                                  : const Color(0xFF8F959E),
                            ),
                            children: const [
                              TextSpan(
                                text: '/$maxRoleNameLength',
                                style: TextStyle(
                                    fontSize: 14, color: Color(0xFF8F959E)),
                              )
                            ]),
                      ),
                    ],
                  ),
                )
              else
                LinkTile(
                    context,
                    Text(
                      '角色名称'.tr,
                      maxLines: 1,
                    ),
                    height: 52,
                    showTrailingIcon: !_isEveryone,
                    trailing: Expanded(
                      child: Text(
                        _newRole.name.breakWord,
                        textAlign: TextAlign.right,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ), onTap: () async {
                  if (_isEveryone) return;

                  await Get.bottomSheet(InputToastBody(
                    defaultTextValue: _roleNameController.text,
                    onSave: (v) {
                      Get.back();
                      setState(() {
                        _newRole.name = v;
                        _roleNameController.text = v;
                      });
                    },
                  ));
                }),
              if (!_isEveryone && widget.isCreateRole)
                const SizedBox(height: 26)
              else
                Container(
                  color: Colors.white,
                  child: Divider(
                    indent: 16,
                    height: 0.5,
                    color: const Color(0x4D8F959E).withOpacity(0.15),
                  ),
                ),
              if (!_isEveryone)
                LinkTile(context, Text('角色颜色'.tr),
                    height: 52,
                    trailing: Row(
                      children: <Widget>[
                        Container(
                          decoration: BoxDecoration(
                              color: roleColor,
                              borderRadius: BorderRadius.circular(3)),
                          width: 24,
                          height: 24,
                        )
                      ],
                    ), onTap: () async {
                  FocusScope.of(context).unfocus();

                  await showBottomModal(
                    context,
                    backgroundColor: CustomColor(context).backgroundColor6,
                    useOriginal: OrientationUtil.landscape,
                    headerBuilder: (c, s) => Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.only(top: 12),
                          alignment: Alignment.center,
                          child: Text(
                            '选取角色颜色'.tr,
                            style: _theme.textTheme.bodyText2
                                .copyWith(fontSize: 16)
                                .copyWith(fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                    builder: (c, s) => Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.only(top: 12, bottom: 10),
                          alignment: Alignment.center,
                          child: Text(
                            '为角色选择一个独特的颜色，更便于与其他\n角色进行区分。'.tr,
                            textAlign: TextAlign.center,
                            style: _theme.textTheme.bodyText1
                                .copyWith(fontSize: 14),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.only(
                              left: 20, right: 20, top: 20, bottom: 40),
                          child: ColorPicker(
                            crossAxisCount: 6,
                            value: _newRole.color,
                            onPickColor: (color) async {
                              Get.back();
                              if (!_canEdit) return;
                              if (_focusNode.hasFocus) {
                                _focusNode.unfocus();
                                return;
                              }

                              setState(() {
                                _newRole.color = color.value;
                              });

                              // if (widget.isCreateRole) {
                              //   setState(() {
                              //     _newRole.color = color.value;
                              //   });
                              // } else {
                              //   await PermissionModel.updateRole(
                              //     widget.guildId,
                              //     widget.roleId,
                              //     color: color.value,
                              //   );
                              // }

                              // setState(() {});
                              // _role.color = color.value;
                            },
                          ),
                        ),
                      ],
                    ),
                  );
                }),

              if (!widget.isCreateRole && !_isEveryone) ...[
                const SizedBox(height: 26),
                ValidPermission(
                  permissions: [
                    Permission.MANAGE_ROLES,
                  ],
                  builder: (value, isOwner) {
                    if (!value || _isEveryone) return const SizedBox();
                    return LinkTile(
                        context,
                        Text(
                          '允许该角色在成员列表中显示'.tr,
                          style: TextStyle(
                              color:
                                  Theme.of(context).textTheme.bodyText2.color),
                        ),
                        height: 52,
                        showTrailingIcon: false,
                        trailing: Row(
                          children: <Widget>[
                            Transform.scale(
                              scale: 0.9,
                              alignment: Alignment.centerRight,
                              child: CupertinoSwitch(
                                  activeColor: Theme.of(context).primaryColor,
                                  value: (_newRole?.hoist ?? false) == false,
                                  onChanged: (v) {
                                    /// 因为后台此字段 false或者是空值是显示  true是不显示
                                    /// 所以此代码这样写
                                    _newRole?.hoist = !v;
                                    setState(() {});
                                  }),
                            )
                          ],
                        ));
                  },
                ),
                sizeHeight10,
              ],

//             const SizedBox(height: 26),
//             LinkTile(context, Text('服务器权限管理'.tr),
//                 height: 56,
//                 trailing: Row(
//                   children: <Widget>[
//                     Text(
//                       '允许%s，禁止%s'.trArgs([
//                         permissionNum[0].toString(),
//                         permissionNum[1].toString()
//                       ]),
//                     )
//                   ],
//                 ), onTap: () async {
//               FocusScope.of(context).unfocus();
//               unawaited(Routes.pushClassifyPermissionPage(
//                 context,
//                 widget.guildId,
//                 _newRole,
//               ));
// //              if (permissionsValue != null)
// //                setState(() {
// //                  widget.role.setPermissions(permissionsValue);
// //                });
//             }),
//             Padding(
//               padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
//               child: Text(
//                 '可按角色分配权限，再对成员覆盖设置，覆盖关系：成员>角色>全体成员；当同个成员属于多个角色，则只有一个角色允许这项权限，则结果是允许。'
//                     .tr,
//                 style: Theme.of(context)
//                     .textTheme
//                     .bodyText1
//                     .copyWith(fontSize: 13),
//               ),
//             ),
              ListView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: <Widget>[
                  // _buildRoleName(),
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
                  Visibility(
                    visible: _advancePermissions.isNotEmpty,
                    child: _buildSubtitle('高级权限'.tr),
                  ),
                  ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemBuilder: (context, index) {
                        return _buildItem(_advancePermissions[index], index);
                      },
                      itemCount: _advancePermissions.length),
                ],
              ),
              const SizedBox(height: 26),
              ValidPermission(
                permissions: [
                  Permission.MANAGE_ROLES,
                ],
                builder: (value, isOwner) {
                  if (!value ||
                      _isEveryone ||
                      widget.isCreateRole ||
                      _originalRole.managed) return const SizedBox();
                  return Padding(
                    padding: EdgeInsets.only(
                        bottom: 30 + Get.mediaQuery.padding.bottom),
                    child: FadeBackgroundButton(
                      backgroundColor: Theme.of(context).backgroundColor,
                      tapDownBackgroundColor:
                          Theme.of(context).backgroundColor.withOpacity(0.5),
                      onTap: _onDelete,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          '删除角色'.tr,
                          style:
                              const TextStyle(color: DefaultTheme.dangerColor),
                        ),
                      ),
                    ),
                  );
                },
              )

              // _buildTile(context, '语音权限', onTap: () {}),
            ],
          ),
        ),
      ),
    );
  }

  // List<int> _computePermissionNum() {
  //   final List<Permission> permissions = [
  //     ...classifyPermissions[PermissionType.general].where((e) =>
  //         !(_isEveryone && PermissionUtils.isEveryoneDisablePermission(e))),
  //     // .where((element) => element.value != Permission.VIEW_CHANNEL.value), // 查看频道权限在服务器权限管理中不可见
  //     ...classifyPermissions[PermissionType.text].where((e) =>
  //         !(_isEveryone && PermissionUtils.isEveryoneDisablePermission(e))),
  //     ...classifyPermissions[PermissionType.voice].where((e) =>
  //         !(_isEveryone && PermissionUtils.isEveryoneDisablePermission(e))),
  //     ...classifyPermissions[PermissionType.topic].where((e) =>
  //         !(_isEveryone && PermissionUtils.isEveryoneDisablePermission(e))),
  //   ];
  //
  //   ///支付入口开关，决定是否显示直播权限
  //   // if (ServerSideConfiguration.to.payIsOpen) {
  //   //   permissions.addAll(classifyPermissions[PermissionType.live].where((e) =>
  //   //       !(_isEveryone && PermissionUtils.isEveryoneDisablePermission(e))));
  //   // }
  //
  //   final int allowNum = permissions.where((element) {
  //     return element.value & _newRole.permissions > 0;
  //   }).length;
  //   final int denyNum = permissions.length - allowNum;
  //   return [allowNum, denyNum];
  // }

//  _toggleMention(bool v) async {
//    FocusScope.of(context).unfocus();
//    await RoleApi.save(widget.guildId, Global.user.id, widget.role.id,
//        mentionable: v);
//    setState(() {
//      _mentionable = v;
//    });
//
//    RoleManageModel().updateRole(widget.role.id, mentionable: v);
//  }

  // Widget _buildRoleName() {
  //   return Container(
  //     padding: const EdgeInsets.all(16),
  //     color: _theme.backgroundColor,
  //     child: Row(
  //       children: <Widget>[
  //         Expanded(
  //           child: Text(
  //             _newRole.name.tr,
  //             overflow: TextOverflow.ellipsis,
  //             style: TextStyle(
  //                 color: _newRole.color == 0
  //                     ? Theme.of(context).textTheme.bodyText2.color
  //                     : Color(
  //                         _newRole.color,
  //                       )),
  //           ),
  //         ),
  //         sizeWidth10,
  //         Text(
  //           '范围：服务器'.tr,
  //           style: _theme.textTheme.bodyText1.copyWith(fontSize: 15),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  Widget _buildSubtitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
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
        _newRole.permissions = newValue;
      } else {
        newValue = newValue & ~permission.value;
        _newRole.permissions = newValue;

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

  // Future<void> _onSave() async {
  //   try {
  //     _toggleLoading(true);
  //     await PermissionModel.updateRole(widget.guildId, _role.id,
  //         permissions: newValue);
  //     _toggleLoading(false);
  //     Navigator.of(context).pop(newValue);
  //     _role.permissions = newValue;
  //   } catch (e) {
  //     _toggleLoading(false);
  //   }
  // }

  // void _toggleLoading(bool value) {
  //   setState(() {
  //     _loading = value;
  //   });
  // }

  Future<void> _onSave() async {
    try {
      if (_newRole.name.trim().characters.length > 30) {
        showToast('角色名称限制30个字'.tr);
        return;
      }

      /// fix 2022.3.10 将按钮加载中状态切换前置，解决弱网环境下多次点击创建角色按钮会导致接口多次调用问题
      _toggleLoading(true);

      //检测角色名称
      final textRes = await CheckUtil.startCheck(
          TextCheckItem(_newRole.name, TextChannelType.CHANNEL_NAME),
          toastError: false);
      if (!textRes) {
        showToast('此内容包含违规信息,请修改后重试'.tr);
        return;
      }

      _newRole.permissions = newValue;
      await PermissionModel.updateRole(
        widget.guildId,
        widget.roleId,
        name: _newRole.name,
        color: _newRole.color,
        position: _newRole.position,
        permissions: _newRole.permissions,
        hoist: _newRole.hoist,
        mentionable: _newRole.mentionable,
      );

      _toggleLoading(false);
      if (widget.isCreateRole) showToastState('角色创建成功'.tr);
      Get.back();
    } catch (e) {
      _newRole = _originalRole.clone();
      _toggleLoading(false);
    }
  }

  void _toggleLoading(bool value) {
    setState(() {
      _loading = value;
    });
  }

  Future<void> _onDelete() async {
    final res = await showConfirmDialog(
        title: '确定将 %s 删除？一旦删除不可撤销。'.trArgs([_newRole.name]),
        confirmStyle: Theme.of(context)
            .textTheme
            .bodyText2
            .copyWith(fontSize: 16, color: primaryColor),
        barrierDismissible: true);
    if (res == true) {
      await RoleApi.delete(
          guildId: widget.guildId,
          userId: Global.user.id,
          roleId: widget.roleId);
      PermissionModel.removeRole(widget.guildId, _newRole);
      showToastState('移除成功'.tr);
    }
  }

  void showToastState(String title) {
    showToastWidget(
        UnconstrainedBox(
            child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 21, vertical: 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
              color: const Color(0xFF363940).withOpacity(0.98),
              borderRadius: BorderRadius.circular(20)),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(IconFont.buffToastOk, size: 20, color: Colors.white),
                sizeWidth8,
                Text(
                  title.tr,
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
  }
}

class InputToastBody extends StatefulWidget {
  final void Function(String textValue) onSave;
  final String defaultTextValue;

  const InputToastBody({Key key, this.onSave, this.defaultTextValue})
      : super(key: key);

  @override
  _InputToastBodyState createState() => _InputToastBodyState();
}

class _InputToastBodyState extends State<InputToastBody> {
  TextEditingController _inputToastBodyController;

  bool isSave = true;

  @override
  void initState() {
    super.initState();
    _inputToastBodyController = TextEditingController();
    _inputToastBodyController.text = widget.defaultTextValue;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_inputToastBodyController.text.trim().isEmpty) {
      isSave = false;
    } else {
      isSave = true;
    }

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
            topLeft: Radius.circular(10), topRight: Radius.circular(10)),
      ),
      height: 174,
      child: Column(
        children: [
          sizeHeight8,
          _buildDropTag(context),
          sizeHeight8,
          IntrinsicHeight(
            child: SizedBox(
              height: 44,
              child: Stack(
                children: [
                  Align(
                    child: Center(
                      child: Text(
                        '角色名称'.tr,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyText2
                            .copyWith(fontSize: 16)
                            .copyWith(fontWeight: FontWeight.w500),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 12,
                    right: 0,
                    child: FadeBackgroundButton(
                      backgroundColor: Colors.white,
                      onTap: isSave
                          ? () {
                              if (_inputToastBodyController.text
                                      .trim()
                                      .characters
                                      .length >
                                  30) {
                                showToast('角色名称限制30个字'.tr);
                                return;
                              }
                              widget.onSave(
                                  _inputToastBodyController.text.trim());
                            }
                          : null,
                      tapDownBackgroundColor:
                          Theme.of(context).backgroundColor.withOpacity(0.5),
                      child: Padding(
                        padding: const EdgeInsets.only(right: 16),
                        child: Text(
                          '确定'.tr,
                          style: TextStyle(
                              color: isSave
                                  ? primaryColor
                                  : const Color(0xFF8F959E),
                              fontSize: 16,
                              fontWeight: FontWeight.w500),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
            ),
            child: Container(
              decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F8),
                  borderRadius: BorderRadius.circular(6)),
              height: 52,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: NativeInput(
                      autofocus: true,
                      decoration: InputDecoration.collapsed(
                        hintText: '请输入角色名称'.tr,
                        hintStyle: const TextStyle(
                            fontSize: 16, color: Color(0xff8F959E)),
                      ),
                      maxLengthEnforcement: MaxLengthEnforcement.none,
                      controller: _inputToastBodyController,
                      onChanged: (val) {
                        setState(() {});
                      },
                    ),
                  ),
                  if (_inputToastBodyController.text.trim().isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        _inputToastBodyController.clear();
                        setState(() {});
                      },
                      child: Icon(
                        IconFont.buffInputClearIcon,
                        size: 17,
                        color: const Color(0xFF8F959E).withOpacity(0.75),
                      ),
                    )
                  else
                    const SizedBox(),
                  sizeWidth8,
                  RichText(
                    text: TextSpan(
                        text:
                            '${_inputToastBodyController.text.trim().characters.length}',
                        style: TextStyle(
                          fontSize: 14,
                          color: _inputToastBodyController.text
                                      .trim()
                                      .characters
                                      .length >
                                  maxRoleNameLength
                              ? Theme.of(context).errorColor
                              : const Color(0xFF8F959E).withOpacity(0.75),
                        ),
                        children: const [
                          TextSpan(
                            text: '/$maxRoleNameLength',
                            style: TextStyle(
                                fontSize: 14, color: Color(0xFF8F959E)),
                          )
                        ]),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropTag(BuildContext context) {
    if (OrientationUtil.landscape)
      return const SizedBox();
    else
      return Center(
        child: Container(
          margin: const EdgeInsets.only(top: 8),
          width: 36,
          height: 4,
          decoration: BoxDecoration(
              color:
                  Theme.of(context).textTheme.bodyText1.color.withOpacity(0.2),
              borderRadius: const BorderRadius.all(Radius.circular(4))),
        ),
      );
  }
}
