import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:im/common/permission/permission_utils.dart';
import 'package:im/core/widgets/button/fade_background_button.dart';
import 'package:im/icon_font.dart';
import 'package:im/pages/guild_setting/role/role_icon.dart';
import 'package:im/routes.dart';
import 'package:im/themes/const.dart';
import 'package:im/themes/default_theme.dart';
import 'package:im/widgets/app_bar/appbar_button.dart';
import 'package:im/widgets/app_bar/custom_appbar.dart';
import 'package:im/widgets/button/more_icon.dart';
import 'package:oktoast/oktoast.dart';
import 'package:provider/provider.dart';

import 'role.dart';
import 'role_manage_model.dart';

class RoleManagePage extends StatefulWidget {
  const RoleManagePage();

  @override
  _RoleManagePageState createState() => _RoleManagePageState();
}

class _RoleManagePageState extends State<RoleManagePage> {
  final String guildId = Get.arguments;
  ThemeData _theme;
  RoleManageModel _model;

  Divider get _divider => Divider(
        thickness: 0.5,
        indent: 44,
        color: const Color(0xFF8F959E).withOpacity(0.15),
      );

  @override
  void initState() {
    _model = RoleManageModel(context, guildId);
    super.initState();
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _theme = Theme.of(context);
    return Scaffold(
        backgroundColor: const Color(0xFFF5F5F8),
        appBar: CustomAppbar(
          title: '管理角色'.tr,
          leadingBuilder: (icon) {
            return AppbarCustomButton(
              child: ChangeNotifierProvider.value(
                value: _model,
                builder: (context, widget) {
                  return Consumer<RoleManageModel>(
                      builder: (context, model, widget) {
                    return _model.editing
                        ? AppbarCancelButton(onTap: _model.cancelEdit)
                        : AppbarIconButton(
                            icon: IconFont.buffNavBarBackItem,
                            onTap: () {
                              Get.back();
                            },
                          );
                  });
                },
              ),
            );
          },
          actions: [
            AppbarCustomButton(
              child: ChangeNotifierProvider.value(
                value: _model,
                builder: (context, widget) {
                  return Consumer<RoleManageModel>(
                      builder: (context, model, widget) {
                    return _model.editing
                        ? AppbarTextButton(
                            loading: _model.saveLoading,
                            onTap: _model.toggleEdit,
                            text: '保存'.tr,
                          )
                        : const SizedBox();
                  });
                },
              ),
            )
          ],
        ),
        body: ChangeNotifierProvider.value(
          value: _model,
          builder: (context, widget) {
            return Consumer<RoleManageModel>(builder: (context, model, widget) {
              return _buildList();
            });
          },
        ));
  }

  Widget _proxyDecorator(Widget child, int index, Animation<double> animation) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final double animValue = Curves.easeInOut.transform(animation.value);
        final double elevation = lerpDouble(0, 6, animValue);
        return Material(
          elevation: elevation,
          child: child,
        );
      },
      child: child,
    );
  }

  Widget _buildList() {
    final List<Role> orderList = _model.getOrderList();
    final List<Role> unChangeList = _model.getUnchangeList();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Expanded(
            child: _wrapper(editing: _model.editing, children: <Widget>[
          CustomScrollView(
            physics: _model.editing
                ? const ClampingScrollPhysics()
                : const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            slivers: <Widget>[
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    _buildAddButton(),
                    if (!_model.editing)
                      ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemBuilder: (context, index) =>
                              _buildItem(unChangeList[index]),
                          itemCount: unChangeList.length),
                  ],
                ),
              ),
              SliverReorderableList(
                proxyDecorator: _proxyDecorator,
                onReorder: _model.onReorder,
                itemBuilder: (context, index) {
                  final child = _buildItem(orderList[index], index: index);

                  if (_model.editing) {
                    return ReorderableDelayedDragStartListener(
                      key: Key('$index'),
                      index: index,
                      child: child,
                    );
                  }

                  return SizedBox(key: Key('$index'), child: child);
                },
                itemCount: orderList.length,
              ),
              // SliverToBoxAdapter(
              //   child: ReorderableListView(
              //     onReorder: _model.onReorder,
              //     buildDefaultDragHandles: false,
              //     children: [
              //       for (int i = 0; i < orderList.length; i++)
              //         ReorderableDragStartListener(
              //             index: i, child: _buildItem(orderList[i])),
              //     ],
              //   ),
              // ),
//                 ReorderableSliverList(
//                   enabled: _model.editing,
//                   delegate: ReorderableSliverChildListDelegate([
//                     for (int i = 0; i < orderList.length; i++)
//                       ReorderableDragStartListener(
//                           index: i, child: _buildItem(orderList[i])),
//                   ]
// //                     orderList.map((e) {
// // //                      final int index = orderList.indexOf(e);
// //                       const bool needDivider = false;
// // //                      if (index != orderList.length - 1) {
// // //                        needDivider = true;
// // //                      } else {
// // //                        needDivider = !_model.editing;
// // //                      }
// //
// //                       return _buildItem(e, needDivider: needDivider);
// //                     }).toList(),
//                       ),
//                   onReorder: _model.onReorder,
//                 )
            ],
          ),
          if (!_model.editing) _buildEveryone(),
        ]))
      ],
    );
  }

  Widget _wrapper({bool editing, List<Widget> children}) {
    return ListView(
      children: children,
    );
  }

  // Widget _wrapper1({bool editing, Widget child}) {
  //   return !editing
  //       ? Expanded(
  //           child: child,
  //         )
  //       : child;
  // }

  Widget _buildAddButton() {
    return _buildToggleWidget(
      firstChild: ListView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            const SizedBox(height: 26),
            FadeBackgroundButton(
              height: 52,
              backgroundColor: _theme.backgroundColor,
              tapDownBackgroundColor: _theme.backgroundColor.withOpacity(0.5),
              onTap: () async {
                await _model.createRole();
                await _model.refresh();
              },
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      const UnconstrainedBox(
                          child: Icon(
                        IconFont.buffTianjia,
                        size: 20,
                        color: Color(0xFF8F959E),
                      )),
                      sizeWidth12,
                      Text('创建角色'.tr),
                      const Expanded(child: SizedBox()),
                    ],
                  ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
              child: Text(
                '成员的昵称将显示为列表中最靠前的角色颜色，角色的先后顺序代表权限的优先级。'.tr,
                style: Theme.of(context)
                    .textTheme
                    .bodyText1
                    .copyWith(fontSize: 14),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(
                left: 16,
                right: 16,
                bottom: 6,
              ),
              child: Row(
                children: [
                  Container(
                    height: 23,
                    alignment: Alignment.bottomLeft,
                    child: Text(
                      '全部角色-${_model.list.length}',
                      style: _theme.textTheme.bodyText1.copyWith(fontSize: 14),
                    ),
                  ),
                  const Expanded(
                    child: SizedBox(),
                  ),
                  GestureDetector(
                    onTap: _model.toggleEdit,
                    child: Container(
                      height: 23,
                      alignment: Alignment.bottomRight,
                      child: Row(
                        children: [
                          Text(
                            '编辑排序',
                            style: _theme.textTheme.bodyText1
                                .copyWith(fontSize: 14)
                                .copyWith(
                                  color: primaryColor,
                                ),
                          ),
                          sizeWidth4,
                          Icon(
                            IconFont.buffSortIcon,
                            size: 16,
                            color: primaryColor,
                          )
                        ],
                      ),
                    ),
                  )
                ],
              ),
            ),
          ]),
      secondChild: Column(
        children: [
          Divider(
            color: const Color(0xFF8F959E).withOpacity(0.15),
            height: 0.5,
          ),
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
            child: Text(
              '成员的昵称将显示为列表中最靠前的角色颜色，角色的先后顺序代表权限的优先级。'.tr,
              style:
                  Theme.of(context).textTheme.bodyText1.copyWith(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEveryone() {
    return _buildToggleWidget(
      firstChild: _buildItem(_model.list.last, needDivider: false),
      secondChild: const SizedBox(),
    );
  }

  Widget _buildToggleWidget(
      {@required Widget firstChild,
      @required Widget secondChild,
      Duration duration = const Duration(milliseconds: 300)}) {
    return AnimatedCrossFade(
      duration: duration,
      firstChild: firstChild,
      secondChild: secondChild,
      crossFadeState: !_model.editing
          ? CrossFadeState.showFirst
          : CrossFadeState.showSecond,
      layoutBuilder: (topChild, topChildKey, bottomChild, bottomChildKey) {
        return SizedBox(
          width: double.infinity,
          child: Stack(
            clipBehavior: Clip.none,
            children: <Widget>[
              Positioned(
                key: bottomChildKey,
                left: 0,
                top: 0,
                right: 0,
                bottom: 0,
                child: bottomChild,
              ),
              Positioned(
                key: topChildKey,
                child: topChild,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildItem(Role role, {bool needDivider = true, int index}) {
    if (_model.editing && _model.isEveryone(role)) {
      return const SizedBox();
    }
    final bool canEdit = PermissionUtils.isGuildOwner() ||
        (_model.maxRolePosition > role.position);
    final Color color1 = _theme.backgroundColor;
    Color color2 = _theme.backgroundColor.withOpacity(0.5);
    if (_model.editing) {
      color2 = _theme.backgroundColor;
    }

    return Column(
      children: <Widget>[
        FadeBackgroundButton(
          backgroundColor: color1,
          tapDownBackgroundColor: color2,
          onTap: () async {
            if (_model.editing) return;
            if (!canEdit) {
              showToast('只能设置比自己当前角色等级低的角色'.tr);
              return;
            }
            await Routes.pushRoleSettingPage(context, guildId, role: role);
            await _model.refresh();
          },
          child: Container(
            alignment: Alignment.centerLeft,
            padding:
                const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 12),
            child: _buildToggleWidget(
              firstChild: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      // mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            RoleIcon(role),
                            sizeWidth12,
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildRoleName(role, canEdit),
                                  sizeHeight6,
                                  Row(
                                    children: [
                                      if (_model.isEveryone(role)) ...[
                                        sizeHeight4,
                                        Text(
                                          '服务器所有成员的默认角色。'.tr,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyText1
                                              .copyWith(fontSize: 14),
                                        ),
                                      ] else ...[
                                        const Icon(IconFont.buffMembersNum,
                                            size: 12, color: Color(0xFF747F8D)),
                                        sizeWidth4,
                                        Text(
                                          '${role?.memberCount?.toString() ?? 0} 位成员',
                                          style: _theme.textTheme.bodyText1
                                              .copyWith(fontSize: 12),
                                        ),
                                      ]
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            // _buildRoleName(role, canEdit),
                            if (!canEdit) ...[
                              sizeWidth12,
                              Icon(Icons.lock_outline,
                                  size: 22,
                                  color: _theme.textTheme.bodyText1.color),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  sizeWidth8,
                  if (canEdit) const MoreIcon(),
                ],
              ),
              secondChild: Row(
                children: <Widget>[
                  if (canEdit && !role.managed)
                    GestureDetector(
                      onTap: () => _model.onDelete(role),
                      child: const Icon(IconFont.buffRemoveUser,
                          size: 22, color: Color(0xFFF24848)),
                    ),
                  if (canEdit && role.managed) const SizedBox(width: 22),
                  sizeWidth12,
                  RoleIcon(role),
                  sizeWidth12,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildRoleName(role, canEdit),
                        sizeHeight6,
                        Row(
                          children: [
                            const Icon(IconFont.buffMembersNum,
                                size: 12, color: Color(0xFF747F8D)),
                            sizeWidth4,
                            Text(
                              '${role?.memberCount?.toString() ?? 0} 位成员',
                              style: _theme.textTheme.bodyText1
                                  .copyWith(fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (!canEdit) ...[
                    sizeWidth12,
                    Icon(Icons.lock_outline,
                        size: 22, color: _theme.textTheme.bodyText1.color),
                  ],
                  if (canEdit)
                    _model.editing == true
                        ? Listener(
                            onPointerDown: (e) {
                              HapticFeedback.heavyImpact();
                            },
                            child: ReorderableDragStartListener(
                              index: index,
                              child: Container(
                                alignment: Alignment.centerRight,
                                color: Colors.transparent,
                                width: 60,
                                child: Icon(
                                  IconFont.buffChannelMoveEditLarge,
                                  size: 22,
                                  color:
                                      const Color(0xFF747F8D).withOpacity(0.5),
                                ),
                              ),
                            ),
                          )
                        : Icon(
                            IconFont.buffChannelMoveEditLarge,
                            size: 22,
                            color: const Color(0xFF747F8D).withOpacity(0.5),
                          ),
                ],
              ),
            ),
          ),
        ),
        _divider,
      ],
    );
  }

  Widget _buildRoleName(Role role, bool canEdit) {
    return Text(
      role.name,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: _theme.textTheme.bodyText2.copyWith(fontSize: 16, height: 1.25),
    );
  }
}
