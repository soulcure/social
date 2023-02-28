import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:im/api/data_model/user_info.dart';
import 'package:im/api/entity/role_bean.dart';
import 'package:im/common/permission/permission.dart';
import 'package:im/common/permission/permission_model.dart';
import 'package:im/common/permission/permission_utils.dart';
import 'package:im/db/db.dart';
import 'package:im/global.dart';
import 'package:im/icon_font.dart';
import 'package:im/pages/guild_setting/role/role.dart';
import 'package:im/themes/const.dart';
import 'package:im/themes/custom_color.dart';
import 'package:im/themes/default_theme.dart';
import 'package:im/web/extension/widget_extension.dart';
import 'package:im/web/utils/show_web_tooltip.dart';
import 'package:im/web/widgets/button/web_hover_button.dart';
import 'package:im/widgets/avatar.dart';
import 'package:im/widgets/mouse_hover_builder.dart';
import 'package:im/widgets/realtime_user_info.dart';
import 'package:im/widgets/refresh/refresh.dart';
import 'package:im/widgets/super_tooltip.dart';
import 'package:pedantic/pedantic.dart';

import '../../../routes.dart';
import 'model/member_manage_model.dart';

const double _rolePadding = 6;
const double _roleMarginRight = 8;
const double _edgeWidth = 12;

class MemberManagePage extends StatefulWidget {
  final String guildId;

  const MemberManagePage(this.guildId);

  @override
  _MemberManagePageState createState() => _MemberManagePageState();

  static Widget addRoleButton(
      {@required String userId,
      @required BuildContext context,
      @required String guildId,
      bool hasPermission,
      Function addCb}) {
    return Builder(builder: (context) {
      if (!hasPermission) return const SizedBox();
      return GestureDetector(
          onTap: () => distributeGuildRole(
              offsetY: 4, context: context, guildId: guildId, userId: userId),
          child: Icon(
            Icons.add_circle_outline,
            size: 24,
            color: Theme.of(context).textTheme.bodyText1.color,
          )).clickable();
    });
  }

  static void distributeGuildRole(
      {@required BuildContext context,
      @required String guildId,
      @required String userId,
      double offsetX = 0,
      double offsetY = 0,
      TooltipDirection popupDirection = TooltipDirection.auto,
      bool pr}) {
    showWebTooltip(context,
        offsetY: offsetY,
        offsetX: offsetX,
        preferenceTop: false,
        popupDirection: popupDirection,
        maxWidth: 190, builder: (context, done) {
      return ValueListenableBuilder<Box<GuildPermission>>(
          valueListenable: Db.guildPermissionBox.listenable(keys: [guildId]),
          builder: (context, box, _) {
            final gp = box.get(guildId);
            final roles = gp?.roles ?? [];
            if (roles.length <= 1)
              return Container(
                width: 190,
                height: 50,
                alignment: Alignment.center,
                child: Text(
                  '暂无角色'.tr,
                  style: Theme.of(context)
                      .textTheme
                      .bodyText1
                      .copyWith(fontSize: 12),
                ),
              );
            return Container(
              constraints: const BoxConstraints(maxHeight: 400),
              child:
                  UserInfo.withRoles(userId, builder: (context, userRoles, _) {
                return ListView(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  physics: const ClampingScrollPhysics(),
                  shrinkWrap: true,
                  children: roles.getRange(0, roles.length - 1).map((e) {
                    final color = _getRoleColor(context, e);
                    final bool hasPermission = PermissionUtils.isGuildOwner() ||
                        (PermissionUtils.getMaxRolePosition() > e.position);
                    final isSelected =
                        userRoles.indexWhere((element) => element.id == e.id) >=
                            0;
                    return WebHoverButton(
                      height: 32,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 2),
                      hoverColor: const Color(0xFFDEE0E3).withOpacity(0.5),
                      cursor: hasPermission
                          ? SystemMouseCursors.click
                          : SystemMouseCursors.basic,
                      child: Row(
                        children: [
                          if (hasPermission)
                            Transform.scale(
                              scale: 0.8,
                              child: Checkbox(
                                value: isSelected,
                                activeColor: primaryColor,
                                onChanged: (val) async {
                                  unawaited(MemberManageModel.toggleMemberRole(
                                      userId, guildId, val, e.id));
                                  // done(null);
                                  // addCb?.call();
                                },
                              ),
                            )
                          else
                            Padding(
                              padding: const EdgeInsets.only(left: 7, right: 5),
                              child: Icon(
                                IconFont.buffChannelLock,
                                size: 18,
                                color: CustomColor(context).disableColor,
                              ),
                            ),
                          sizeWidth8,
                          Expanded(
                            child: GestureDetector(
                              onTap: !hasPermission
                                  ? null
                                  : () {
                                      unawaited(
                                          MemberManageModel.toggleMemberRole(
                                              userId,
                                              guildId,
                                              !isSelected,
                                              e.id));
                                      // addCb?.call();
                                    },
                              child: Text(
                                e.name ?? '',
                                style: TextStyle(color: color),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                        ],
                      ),
                    );
                  }).toList(),
                );
              }),
            );
          });
    });
  }

  static Color _getRoleColor(BuildContext context, Role role) {
    return role.color == 0
        ? Theme.of(context).textTheme.bodyText2.color
        : Color(role.color);
  }

  static Widget roleChipItem(
      {@required String userId,
      @required Role role,
      @required String guildId,
      bool hasPermission,
      Function deleteCb}) {
    return MouseHoverBuilder(builder: (context, isHover) {
      final color = _getRoleColor(context, role);
      return Container(
        padding:
            const EdgeInsets.symmetric(vertical: 2, horizontal: _rolePadding),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(40),
          border: Border.all(color: color),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            GestureDetector(
              onTap: isHover && hasPermission
                  ? () async {
                      unawaited(MemberManageModel.deleteRole(
                          userId: userId, guildId: guildId, deleteRole: role));
                      deleteCb?.call();
                    }
                  : null,
              child: Container(
                width: _edgeWidth,
                height: _edgeWidth,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                padding: const EdgeInsets.all(2),
                child: isHover && hasPermission
                    ? const FittedBox(
                        child: Icon(
                          IconFont.buffNavBarCloseItem,
                          color: Colors.white,
                        ),
                      )
                    : null,
              ),
            ),
            sizeWidth5,
            Flexible(
              child: Text(
                role.name,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, color: color),
              ),
            ),
          ],
        ),
      );
    });
  }

  static Widget userRoles({
    @required BuildContext context,
    @required String userId,
    @required String guildId,
    Function deleteCb,
  }) {
    return RoleBean.consume(
        context: context,
        userId: userId,
        guildId: guildId,
        builder: (context, role, _) {
          final roles = PermissionModel.getPermission(guildId)
              .roles
              .where((e) => role.roleIds.contains(e.id))
              .toList(growable: false);
          bool hasPermission;
          if (!PermissionUtils.isGuildOwner(userId: userId)) {
            hasPermission =
                PermissionUtils.comparePosition(roleIds: role?.roleIds ?? []) ==
                    1;
          } else {
            hasPermission =
                PermissionUtils.isGuildOwner(userId: Global.user.id);
          }
          return Container(
            constraints: const BoxConstraints(maxHeight: 400),
            child: UserInfo.withRoles(userId, builder: (context, userRoles, _) {
              return Wrap(spacing: 4, runSpacing: 4, children: [
                ...roles
                    .where((e) {
                      final isSelected =
                          userRoles.indexWhere((r) => r.id == e.id) >= 0;
                      return isSelected;
                    })
                    .map(
                      (e) => MemberManagePage.roleChipItem(
                          userId: userId,
                          role: e,
                          guildId: guildId,
                          hasPermission: hasPermission,
                          deleteCb: () => deleteCb?.call(null)),
                    )
                    .toList(),
                addRoleButton(
                  context: context,
                  userId: userId,
                  guildId: guildId,
                  hasPermission: hasPermission,
                )
              ]);
            }),
          );
        });
  }
}

class _MemberManagePageState extends State<MemberManagePage> {
  ThemeData _theme;
  MemberManageModel _model;
  final _controller = ScrollController();

  @override
  void initState() {
    _model = MemberManageModel(guildId: widget.guildId);
    super.initState();
  }

  @override
  void dispose() {
    _model.destroy();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _theme = Theme.of(context);
    return ValidPermission(
        permissions: const [],
        builder: (value, _) {
          return Refresher(
                model: _model,
                enableRefresh: false,
                scrollController: _controller,
                builder: (context) {
                  final GuildPermission gp =
                      PermissionModel.getPermission(widget.guildId);
                  return _buildMemberList(_model.list, gp.roles);
                });
        });
  }

  Widget _buildMemberList(List<UserInfo> users, List<Role> roles) {
    return ListView.separated(
      controller: _controller,
      physics: const ClampingScrollPhysics(),
      padding: EdgeInsets.zero,
      itemBuilder: (context, index) {
        // 服务器所有者排第一位，后面出现需去重
        if (index != 0 &&
            _model.list[index].userId == _model.list.first.userId) {
          return const SizedBox();
        }
        return _buildItem(users[index], roles);
      },
      separatorBuilder: (context, index) => divider,
      itemCount: users.length,
    );
  }

  Widget _buildItem(UserInfo member, List<Role> roles) {
    return UserInfo.consume(member.userId, builder: (context, user, child) {
      bool hasPermission;
      if (!PermissionUtils.isGuildOwner(userId: member.userId)) {
        hasPermission =
            PermissionUtils.comparePosition(roleIds: member.roles) == 1;
      } else {
        hasPermission = PermissionUtils.isGuildOwner(userId: Global.user.id);
      }
      final isFirst = _model.list.first == member;
      Border border;
      final dividerColor = const Color(0xFFDEE0E3).withOpacity(0.5);
      if (isFirst) {
        border = Border(
            top: BorderSide(color: dividerColor),
            bottom: BorderSide(color: dividerColor));
      } else {
        border = Border(bottom: BorderSide(color: dividerColor));
      }
      return WebHoverButton(
        padding: EdgeInsets.zero,
        color: Colors.transparent,
        hoverColor: dividerColor,
        border: border,
        onTap: () async {},
        child: Container(
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.all(16),
          child: UserInfo.consume(user.userId,
              builder: (context, userInfo, widget) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Avatar(
                  url: userInfo.avatar,
                  radius: 20,
                ),
                sizeWidth8,
                Expanded(
                  child: Row(
                    children: <Widget>[
                      SizedBox(
                        width: 200,
                        child: Row(
                          children: [
                            Flexible(
                              child: RealtimeNickname(
                                userId: userInfo.userId,
                                style: const TextStyle(fontSize: 16),
                                showNameRule: ShowNameRule.remarkAndGuild,
                              ),
                            ),
                            sizeWidth8,
                            if (PermissionUtils.isGuildOwner(
                                userId: member.userId))
                              const Icon(
                                IconFont.buffOtherStars,
                                color: Color(0xffFAA61A),
                                size: 18,
                              ),
                            sizeWidth24,
                          ],
                        ),
                      ),
                      Expanded(
                        child: _buildMemberRoles(user, hasPermission),
                      ),
                      Opacity(
                        opacity: 1,
                        child: Builder(builder: (context) {
                          return IconButton(
                            onPressed: () =>
                                _showMoreAction(context, member, hasPermission),
                            iconSize: 20,
                            icon: const Icon(IconFont.buffMoreHorizontal),
                          );
                        }),
                      )
                    ],
                  ),
                ),
              ],
            );
          }),
        ),
      );
    });
  }

  Widget _buildMemberRoles(UserInfo member, bool hasPermission) {
    return UserInfo.withRoles(member.userId, builder: (context, roles, widget) {
      return LayoutBuilder(builder: (context, constraints) {
        int cutRoleIndex;
        double totalWidth = 0;
        for (int i = 0; i < roles.length; i++) {
          if (totalWidth +
                  measureRoleChipWidth(roles[i].name) +
                  _roleMarginRight +
                  30 <
              constraints.maxWidth) {
            totalWidth +=
                measureRoleChipWidth(roles[i].name) + _roleMarginRight;
          } else {
            cutRoleIndex = i - 1;
            break;
          }
        }
        return Row(children: [
          ...roles.sublist(0, cutRoleIndex).map((e) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                MemberManagePage.roleChipItem(
                    guildId: _model.guildId,
                    userId: member.userId,
                    role: e,
                    hasPermission: hasPermission),
                const SizedBox(width: _roleMarginRight),
              ],
            );
          }).toList(),
          _buildExtraButton(member.userId, roles, cutRoleIndex, hasPermission),
        ]);
      });
    });
  }

  Widget _buildExtraButton(
      String member, List<Role> roles, int cutRoleIndex, bool hasPermission) {
    return Builder(builder: (context) {
      if (cutRoleIndex == null)
        return MemberManagePage.addRoleButton(
            context: context,
            userId: member,
            guildId: widget.guildId,
            hasPermission: hasPermission);
      return GestureDetector(
        onTap: () {
          showWebTooltip(context,
              offsetY: 5,
              popupDirection: TooltipDirection.auto,
              preferenceTop: false,
              maxWidth: 240, builder: (context, done) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              child: MemberManagePage.userRoles(
                  context: context,
                  userId: member,
                  guildId: widget.guildId,
                  deleteCb: done),
            );
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
              border: Border.all(color: _theme.textTheme.bodyText1.color),
              borderRadius: BorderRadius.circular(20)),
          child: Text(
            '+${roles.length - cutRoleIndex}',
            style: TextStyle(
                color: _theme.textTheme.bodyText1.color, fontSize: 12),
          ),
        ),
      ).clickable();
    });
  }

  Future<void> _showMoreAction(
      BuildContext context, UserInfo member, bool hasPermission) async {
    Widget _item(IconData icon, String title, int index, Function done) {
      return WebHoverButton(
        hoverColor: const Color(0xFFDEE0E3).withOpacity(0.5),
        height: 32,
        borderRadius: 4,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        onTap: () => done(index),
        child: Row(
          children: [
            Icon(icon, size: 15),
            sizeWidth8,
            Text(title ?? "",
                style: _theme.textTheme.bodyText2.copyWith(fontSize: 12))
          ],
        ),
      );
    }

    final res = await showWebTooltip<int>(context,
        popupDirection: TooltipDirection.rightTop,
        maxWidth: 118, builder: (context, done) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hasPermission &&
              !PermissionUtils.isGuildOwner(userId: member.userId))
            _item(IconFont.buffChatDelete, '删除'.tr, 0, done),
          _item(IconFont.webAccusation, '举报'.tr, 1, done),
        ],
      );
    });

    if (res == 0) {
      unawaited(_model.removeMember(context, member));
    } else if (res == 1) {
      unawaited(Routes.pushToTipOffPage(
        context,
        accusedUserId: member.userId,
        accusedName: member.nickname,
      ));
    }
  }

  double measureRoleChipWidth(String roleName) {
    double width = 0;
    width += _rolePadding * 2 + _edgeWidth;
    final TextPainter painter = TextPainter(
        textDirection: TextDirection.ltr,
        text: TextSpan(children: [
          TextSpan(text: roleName, style: const TextStyle(fontSize: 12)),
        ]));
    painter.layout();
    return painter.width + width;
  }
}
