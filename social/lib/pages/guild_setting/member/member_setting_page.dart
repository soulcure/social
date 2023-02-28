import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:im/api/data_model/user_info.dart';
import 'package:im/app/theme/app_theme.dart';
import 'package:im/common/permission/permission.dart';
import 'package:im/common/permission/permission_utils.dart';
import 'package:im/core/widgets/button/fade_background_button.dart';
import 'package:im/db/db.dart';
import 'package:im/global.dart';
import 'package:im/icon_font.dart';
import 'package:im/pages/guild_setting/member/model/member_manage_model.dart';
import 'package:im/pages/guild_setting/role/role.dart';
import 'package:im/pages/member_list/model/member_list_model.dart';
import 'package:im/themes/const.dart';
import 'package:im/themes/default_theme.dart';
import 'package:im/widgets/app_bar/appbar_builder.dart';
import 'package:im/widgets/realtime_user_info.dart';
import 'package:im/widgets/remove_member_widget.dart';

import 'member_select_role_popup.dart';

class MemberSettingPage extends StatefulWidget {
  final String guildId;
  final UserInfo member;

  const MemberSettingPage({@required this.guildId, @required this.member});

  @override
  _MemberSettingPageState createState() => _MemberSettingPageState();
}

class _MemberSettingPageState extends State<MemberSettingPage>
    with TickerProviderStateMixin {
  TextEditingController _otherNameController;
  List<Role> _roles;
  ValueNotifier<List<String>> _currentRoleIds;

  @override
  void initState() {
    //  220506 whiskee.chen 出现了roles为null的情况，安全处理为[]
    _currentRoleIds = ValueNotifier(widget.member.roles ?? []);
    _otherNameController = TextEditingController(text: widget.member.nickname)
      ..addListener(() {
        setState(() {});
      });
    super.initState();
  }

  @override
  void dispose() {
    _otherNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        appBar: FbAppBar.custom(
          '管理成员'.tr,
          backgroundColor: theme.scaffoldBackgroundColor,
        ),
        body: ListView(
          children: <Widget>[
            sizeHeight16,
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                  color: theme.backgroundColor,
                  borderRadius: BorderRadius.circular(8)),
              height: 64,
              child: Row(
                children: <Widget>[
                  RealtimeAvatar(
                    userId: widget.member.userId,
                    size: 40,
                  ),
                  sizeWidth12,
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      RealtimeNickname(
                        userId: widget.member.userId,
                        showNameRule: ShowNameRule.remark,
                      ),
                      sizeHeight4,
                      Text(
                        '#${widget.member.username}',
                        style: theme.textTheme.bodyText1.copyWith(
                          fontSize: 14,
                          height: 1,
                          color: theme.disabledColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            buildGuildNickname(widget.guildId, context),
            _buildRoles(),
            const SizedBox(
              height: 26,
            ),
            // 移出成员
            ValidPermission(
              permissions: [
                Permission.KICK_MEMBERS,
              ],
              builder: (value, isOwner) {
                final bool isLocalUser = widget.member.userId == Global.user.id;
                final hasPermission = PermissionUtils.comparePosition(
                        roleIds: widget.member.roles) ==
                    1;

                if (!value ||
                    PermissionUtils.isGuildOwner(
                        userId: widget.member.userId) ||
                    isLocalUser ||
                    !hasPermission) return const SizedBox();
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                  child: FadeBackgroundButton(
                    backgroundColor: Theme.of(context).backgroundColor,
                    tapDownBackgroundColor:
                        Theme.of(context).backgroundColor.withOpacity(0.5),
                    onTap: _removeMember,
                    height: 52,
                    borderRadius: 8,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        '移出成员'.tr,
                        style: const TextStyle(color: DefaultTheme.dangerColor),
                      ),
                    ),
                  ),
                );
              },
            )
          ],
        ),
      ),
    );
  }

  Widget buildGuildNickname(String guildId, BuildContext context) {
    final theme = Theme.of(context);
    final user = Db.userInfoBox.get(widget.member.userId);
    final guildName = user?.guildNickname(guildId) ?? '';
    if (guildName.isEmpty) return sizedBox;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 16, left: 32, bottom: 10),
          child: Text(
            '服务器昵称'.tr,
            style: theme.textTheme.bodyText1.copyWith(fontSize: 13),
          ),
        ),
        Container(
          alignment: Alignment.centerLeft,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: Theme.of(context).backgroundColor,
              borderRadius: BorderRadius.circular(8)),
          child: Text(guildName),
        )
      ],
    );
  }

  Widget _buildRoles() {
    Widget _buildItem(Role role, bool isFirst, bool isLast) {
      final roleColor = role.color == 0
          ? Theme.of(context).textTheme.bodyText2.color
          : Color(role.color);
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).backgroundColor,
          borderRadius: BorderRadius.vertical(
              top: Radius.circular(isFirst ? 8 : 0),
              bottom: Radius.circular(isLast ? 8 : 0)),
        ),
        height: 52,
        child: Row(
          children: <Widget>[
            sizeWidth16,
            Icon(IconFont.buffRoleIconColor, size: 24, color: roleColor),
            sizeWidth16,
            Expanded(
              child: Text(role?.name ?? '',
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context)
                      .textTheme
                      .bodyText2
                      .copyWith(height: 1.25)),
            ),
          ],
        ),
      );
    }

    return ValueListenableBuilder<Box<GuildPermission>>(
        valueListenable:
            Db.guildPermissionBox.listenable(keys: [widget.guildId]),
        builder: (context, box, _) {
          final gp = box.get(widget.guildId);
          // 去掉所有人角色
          _roles = gp.roles.getRange(0, gp.roles.length - 1).toList();

          // 获取当前选中的数据源
          final currentSelectIds = [..._currentRoleIds.value];
          // 便利所有角色,移除选中数据源在 角色列表不存在的数据

          for (final String roleId in _currentRoleIds.value) {
            // 标识当前选中的某一个角色id是否存在角色列表
            bool isExist = false;
            for (final Role role in _roles) {
              if (role.id == roleId) {
                isExist = true;
                break;
              }
            }
            // 当前角色id不存在角色列表中时,进行移除
            if (!isExist) {
              currentSelectIds.remove(roleId);
            }
          }
          _currentRoleIds.value = [...currentSelectIds];
          return ValueListenableBuilder(
              valueListenable: _currentRoleIds,
              builder: (context, selectIds, widget) {
                final currentRoles =
                    _roles.where((e) => selectIds.contains(e.id)).toList();
                return Column(
                  children: [
                    Padding(
                        padding: const EdgeInsets.fromLTRB(32, 26, 32, 6),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '角色'.tr,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyText1
                                  .copyWith(fontSize: 14),
                            ),
                            if (currentRoles.isNotEmpty)
                              GestureDetector(
                                onTap: _editRole,
                                child: Text(
                                  '编辑'.tr,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyText1
                                      .copyWith(
                                          fontSize: 14,
                                          color:
                                              Theme.of(context).primaryColor),
                                ),
                              )
                          ],
                        )),
                    if (currentRoles.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: FadeBackgroundButton(
                          onTap: _editRole,
                          tapDownBackgroundColor:
                              Theme.of(context).disabledColor,
                          backgroundColor: Theme.of(context).backgroundColor,
                          height: 52,
                          borderRadius: 8,
                          child: Text(
                            '编辑角色列表'.tr,
                            style: appThemeData.textTheme.bodyText2,
                          ),
                        ),
                      )
                    else
                      ListView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        itemBuilder: (context, index) {
                          final role = currentRoles[index];
                          final isFirst = index == 0;
                          final isLast = index == currentRoles.length - 1;
                          return _buildItem(role, isFirst, isLast);
                        },
                        itemCount: currentRoles.length,
                      ),
                  ],
                );
              });
        });
  }

  Future<void> _editRole() async {
    final newSelectIds = await showMemberSelectRolePopup(context,
        guildId: widget.guildId,
        member: widget.member,
        selectIds: List.from(_currentRoleIds.value));
    if (newSelectIds != null) {
      _currentRoleIds.value = newSelectIds;
    }
  }

  Future<void> _removeMember() async {
    final String guildId = widget.guildId;
    final String memberId = widget.member.userId;
    final String memberName = widget.member.showName();

    final removeMemberWidget = RemoveMemberWidget(guildId, memberId, memberName,
        widget.member.isBot, RemoveMemberWidgetFrom.edit_member);

    await Get.bottomSheet<bool>(removeMemberWidget).then((value) async {
      if (value == true) {
        await MemberListModel.instance.remove(memberId);
        MemberManageModel()?.removeMember(widget.member.userId);
        Get.close(2);
      }
    });
  }
}
