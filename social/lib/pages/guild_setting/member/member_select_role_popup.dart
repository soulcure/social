import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:im/api/data_model/user_info.dart';
import 'package:im/api/entity/role_bean.dart';
import 'package:im/api/role_api.dart';
import 'package:im/api/util_api.dart';
import 'package:im/common/permission/permission.dart';
import 'package:im/common/permission/permission_utils.dart';
import 'package:im/db/db.dart';
import 'package:im/global.dart';
import 'package:im/icon_font.dart';
import 'package:im/pages/guild_setting/role/role.dart';
import 'package:im/themes/const.dart';
import 'package:im/themes/custom_color.dart';
import 'package:im/themes/default_theme.dart';
import 'package:im/utils/show_bottom_modal.dart';
import 'package:im/utils/utils.dart';
import 'package:oktoast/oktoast.dart';

import 'model/member_manage_model.dart';

Future<List<String>> showMemberSelectRolePopup(BuildContext context,
    {@required String guildId,
    @required UserInfo member,
    @required List<String> selectIds}) {
  final RxBool loading = false.obs;
  return showBottomModal(
    context,
    headerBuilder: (c, s) => MemberSelectRoleHeader(
      guildId: guildId,
      selectIds: selectIds,
      member: member,
      loading: loading,
    ),
    builder: (c, s) => MemberSelectRolePopup(
        guildId: guildId,
        selectIds: selectIds,
        member: member,
        loading: loading),
    backgroundColor: CustomColor(context).backgroundColor6,
    resizeToAvoidBottomInset: false,
  );
}

class MemberSelectRoleHeader extends StatefulWidget {
  final String guildId;
  final UserInfo member;
  final List<String> selectIds;
  final RxBool loading;

  const MemberSelectRoleHeader(
      {Key key, this.guildId, this.member, this.selectIds, this.loading})
      : super(key: key);

  @override
  _MemberSelectRoleHeaderState createState() => _MemberSelectRoleHeaderState();
}

class _MemberSelectRoleHeaderState extends State<MemberSelectRoleHeader> {
  List<String> initIds;

  Future<void> _onSave() async {
    if (const ListEquality().equals(initIds ?? [], widget.selectIds)) {
      Navigator.of(context).pop();
      return;
    }
    widget.loading.value = true;

    try {
      final requestData = await RoleApi.updateMemberRole(
        guildId: widget.guildId,
        userId: Global.user.id,
        roleIds: widget.selectIds,
        memberId: widget.member.userId,
        showDefaultErrorToast: false,
        isOriginDataReturn: true,
      );

      widget.loading.value = false;

      if (requestData != null) {
        if (requestData["status"] == false) {
          if (requestData["code"] == 1007) {
            showToast("%s已不存在当前服务器，请退出重试".trArgs([widget.member.showName()]));
          } else if (requestData["code"] == 1035) {
            showToast("该角色已不存在，请退出重试".tr);
          } else {
            showToast(requestData["desc"]);
          }
          return;
        }
      }

      MemberManageModel()?.updateRoles(widget.member, [...widget.selectIds]);
      RoleBean.update(
          widget.member.userId, widget.guildId, [...widget.selectIds]);
      final member = await UserInfo.get(widget.member.userId);
      if (member != null) {
        member.roles = widget.selectIds;
        UserInfo.set(member);
      }
      Navigator.of(context).pop(widget.selectIds);
    } catch (err) {
      UtilApi.catchToastError(err);

      widget.loading.value = false;
    }
  }

  @override
  void initState() {
    initIds = List.from(widget.selectIds);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      primary: false,
      leading: IconButton(
        onPressed: Navigator.of(context).pop,
        icon: Icon(
          IconFont.buffNavBarCloseItem,
          color: Theme.of(context).textTheme.bodyText2.color,
          size: 20,
        ),
      ),
      centerTitle: true,
      title: Text(
        '编辑角色'.tr,
        style: Theme.of(context).textTheme.headline5,
      ),
      elevation: 0,
      actions: [
        ObxValue<RxBool>(
            (loading) => loading.value
                ? Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: DefaultTheme.defaultLoadingIndicator(),
                  )
                : CupertinoButton(
                    onPressed: _onSave,
                    child: Text(
                      '保存'.tr,
                      style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontSize: 17,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
            widget.loading)
      ],
    );
  }
}

class MemberSelectRolePopup extends StatefulWidget {
  final String guildId;
  final UserInfo member;
  final List<String> selectIds;
  final RxBool loading;

  const MemberSelectRolePopup(
      {Key key, this.guildId, this.member, this.selectIds, this.loading})
      : super(key: key);

  @override
  _MemberSelectRolePopupState createState() => _MemberSelectRolePopupState();
}

class _MemberSelectRolePopupState extends State<MemberSelectRolePopup> {
  List<String> _selectIds;

  @override
  void initState() {
    _selectIds = widget.selectIds;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: Global.mediaInfo.size.height / 2),
      child: buildBody(),
    );
  }

  Widget _buildItem(Role role, bool canEdit) {
    final roleColor = role.color == 0
        ? Theme.of(context).textTheme.bodyText2.color
        : Color(role.color);
    final selected = _selectIds.contains(role.id);

    return GestureDetector(
      onTap: canEdit
          ? () {
              if (widget.loading.value) return;
              if (selected)
                _selectIds.removeWhere((element) => element == role.id);
              else
                _selectIds.add(role.id);
              setState(() {});
            }
          : null,
      behavior: HitTestBehavior.translucent,
      child: SizedBox(
        height: 52,
        child: Row(
          children: <Widget>[
            sizeWidth16,
            if (canEdit)
              Icon(
                selected
                    ? IconFont.buffSelectCheck
                    : IconFont.buffSelectUncheck,
                color: selected
                    ? Get.theme.primaryColor
                    : const Color(0xFF8F959E).withOpacity(0.5),
                size: 20,
              )
            else
              Icon(Icons.lock_outline,
                  size: 20, color: Theme.of(context).textTheme.bodyText1.color),
            sizeWidth12,
            Icon(IconFont.buffRoleIconColor, size: 28, color: roleColor),
            sizeWidth16,
            Expanded(
              child: Text(role?.name ?? '',
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context)
                      .textTheme
                      .bodyText2
                      .copyWith(height: 1.25)),
            ),
            sizeWidth16,
          ],
        ),
      ),
    );
  }

  Widget buildBody() {
    return ValueListenableBuilder<Box<GuildPermission>>(
        valueListenable:
            Db.guildPermissionBox.listenable(keys: [widget.guildId]),
        builder: (context, box, _) {
          final gp = box.get(widget.guildId);
          final maxRolePosition =
              PermissionUtils.getMaxRolePosition(guildPermission: gp);
          final roles = gp.roles.getRange(0, gp.roles.length - 1).toList();
          return ListView.builder(
            padding: EdgeInsets.only(bottom: getBottomViewInset()),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemBuilder: (context, index) {
              /// NOTE(jp@jin.dev): 2022/5/25 机器人角色不可操作
              final bool canEdit = (PermissionUtils.isGuildOwner() ||
                      (maxRolePosition > roles[index].position)) &&
                  !roles[index].managed;
              return _buildItem(roles[index], canEdit);
            },
            itemCount: roles.length,
          );
        });
  }
}
