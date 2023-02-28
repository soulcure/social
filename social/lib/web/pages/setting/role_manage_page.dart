import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:im/common/permission/permission_utils.dart';
import 'package:im/pages/guild_setting/role/role.dart';
import 'package:im/themes/const.dart';
import 'package:im/themes/custom_color.dart';
import 'package:im/themes/default_theme.dart';
import 'package:im/web/extension/state_extension.dart';
import 'package:im/web/extension/widget_extension.dart';
import 'package:im/web/widgets/button/web_hover_button.dart';
import 'package:oktoast/oktoast.dart';
import 'package:provider/provider.dart';
import 'package:reorderables/reorderables.dart';

import '../../../icon_font.dart';
import 'classify_permission_page.dart';
import 'model/role_manage_model.dart';

class RoleManagePage extends StatefulWidget {
  final String guildId;
  const RoleManagePage(this.guildId);
  @override
  _RoleManagePageState createState() => _RoleManagePageState();
}

class _RoleManagePageState extends State<RoleManagePage> {
  ThemeData _theme;
  RoleManageModel _model;
  ScrollController _scrollController;

  @override
  void initState() {
    _scrollController = ScrollController();
    _model = RoleManageModel(context, widget.guildId);
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      formDetectorModel.setCallback(
          onConfirm: _model.onConfirm, onReset: _model.onReset);
    });
    super.initState();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _theme = Theme.of(context);
    return ChangeNotifierProvider.value(
      value: _model,
      builder: (context, child) {
        return Consumer<RoleManageModel>(builder: (context, model, child) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 180,
                child: Scrollbar(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: CustomScrollView(
                      physics: const ClampingScrollPhysics(),
                      slivers: <Widget>[
                        SliverToBoxAdapter(
                          child: Row(
                            children: [
                              Text(
                                '角色'.tr,
                                style: _theme.textTheme.bodyText2.copyWith(
                                    fontSize: 14, fontWeight: FontWeight.w600),
                              ),
                              spacer,
                              Builder(
                                builder: (context) {
                                  return GestureDetector(
                                    onTap: _model.createRole,
                                    child: Icon(
                                      Icons.add_circle_outline,
                                      color: CustomColor(context).disableColor,
                                      size: 18,
                                    ),
                                  ).clickable();
                                },
                              )
                            ],
                          ),
                        ),
                        const SliverToBoxAdapter(
                          child: sizeHeight16,
                        ),

                        SliverList(
                          delegate:
                              SliverChildBuilderDelegate((context, index) {
                            return _buildItem(_model.unchangedList[index]);
                          }, childCount: _model.unchangedList.length),
                        ),
                        SliverToBoxAdapter(
                          child: ReorderableColumn(
                            scrollController: _scrollController,
                            onReorder: _model.onReorder,
                            needsLongPressDraggable: false,
                            children: [
                              ..._model.orderList.map(_buildItem).toList()
                            ],
                          ),
                        ),
                        SliverToBoxAdapter(
                            child: _buildItem(_model.cacheList.last)),
                        const SliverToBoxAdapter(child: sizeHeight16),
                        const SliverToBoxAdapter(
                            child: Divider(
                          height: 1,
                          color: Color(0xFFDEE0E3),
                        )),
                        const SliverToBoxAdapter(child: sizeHeight8),
                        SliverToBoxAdapter(
                            child: Text(
                          '直接拖拽角色可对角色排序，自上而下的顺序不仅关联其他位置的排序，也会与权限优先级从高到低对应。'.tr,
                          style:
                              _theme.textTheme.bodyText1.copyWith(fontSize: 12),
                        )),
                        // _buildRoleOrMemberList(_model.memberList),
                      ],
                    ).addWebPaddingBottom(),
                  ),
                ),
              ),
              Expanded(
                  child: ClassifyPermissionPage(
                guildId: widget.guildId,
                role: _model.editingRole,
              ))
            ],
          );
        });
      },
    );
  }

  // List<Widget> _buildList() {
  //   final List<Role> orderList = _model.getOrderList();
  //   final List<Role> unChangeList = _model.getUnchangeList();
  //   Column(
  //     mainAxisSize: MainAxisSize.min,
  //     children: <Widget>[
  //       Expanded(
  //           child: _wrapper(editing: _model.editing, children: <Widget>[
  //         if (!_model.editing)
  //           ListView.builder(
  //               shrinkWrap: true,
  //               physics: const NeverScrollableScrollPhysics(),
  //               itemBuilder: (context, index) =>
  //                   _buildItem(unChangeList[index]),
  //               itemCount: unChangeList.length),
  //         _wrapper1(
  //           editing: _model.editing,
  //           child: CustomScrollView(
  //             physics: _model.editing
  //                 ? const ClampingScrollPhysics()
  //                 : const NeverScrollableScrollPhysics(),
  //             shrinkWrap: true,
  //             slivers: <Widget>[
  //               ReorderableSliverList(
  //                 enabled: _model.editing,
  //                 delegate: ReorderableSliverChildListDelegate(
  //                   orderList.map((e) {
  //                     const bool needDivider = false;
  //                     return _buildItem(e, needDivider: needDivider);
  //                   }).toList(),
  //                 ),
  //                 onReorder: _model.onReorder,
  //               )
  //             ],
  //           ),
  //         ),
  //         if (!_model.editing) _buildEveryone(),
  //       ]))
  //     ],
  //   );
  // }
  Color getRoleColor(Role role, bool isSelected) {
    // if (isSelected) {
    //   return (role.color == 0 || role.color == null)
    //       ? _theme.textTheme.bodyText2.color
    //       : Colors.white;
    // }
    return (role.color == 0 || role.color == null)
        ? _theme.textTheme.bodyText2.color
        : Color(role.color);
  }

  Color getRoleBgColor(Role role) {
    return const Color(0xFFDEE0E3);
  }

  Widget _buildItem(Role role, {bool needDivider = true}) {
    final bool canEdit = PermissionUtils.isGuildOwner() ||
        (_model.maxRolePosition > role.position);
    Color color;
    Color hoverColor;
    Color textColor;
    final isSelected = _model.editingRole.id == role.id;
    if (isSelected) {
      color = hoverColor = getRoleBgColor(role);
    } else {
      color = Colors.transparent;
      hoverColor = getRoleBgColor(role).withOpacity(0.5);
    }
    textColor = getRoleColor(role, isSelected);
    return WebHoverButton(
      key: ValueKey(role.hashCode),
      color: color,
      hoverColor: hoverColor,
      borderRadius: 4,
      onTap: () async {
        if (!canEdit) {
          showToast('只能设置比自己当前角色等级低的角色'.tr);
          return;
        }
        _model.toggleRole(role);
      },
      builder: (isHover, child) {
        final isEveryone = role.id == _model.guildId;
        final showDeleteIcon =
            canEdit && !isEveryone && (isSelected || isHover);
        return Row(
          children: <Widget>[
            Expanded(
              child: Text(
                role?.name ?? '',
                overflow: TextOverflow.ellipsis,
                style: _theme.textTheme.bodyText2.copyWith(color: textColor),
                maxLines: 1,
              ),
            ),
            sizeWidth12,
            if (!canEdit)
              Icon(
                IconFont.buffChannelLock,
                size: 16,
                color: CustomColor(context).disableColor,
              ),
            if (showDeleteIcon)
              GestureDetector(
                onTap: () => _model.onDelete(role),
                child: const Icon(
                  IconFont.buffCommonDeleteRed,
                  size: 16,
                  color: DefaultTheme.dangerColor,
                ),
              )
          ],
        );
      },
    );
  }
}
