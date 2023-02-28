import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/api/data_model/user_info.dart';
import 'package:im/common/extension/string_extension.dart';
import 'package:im/common/permission/permission.dart';
import 'package:im/common/permission/permission_model.dart';
import 'package:im/common/permission/permission_utils.dart';
import 'package:im/core/widgets/button/fade_background_button.dart';
import 'package:im/icon_font.dart';
import 'package:im/pages/guild_setting/channel/add_overwrite_model.dart';
import 'package:im/pages/guild_setting/role/role.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/pages/search/model/search_member_model.dart';
import 'package:im/pages/search/model/search_model.dart';
import 'package:im/pages/search/widgets/member_nickname.dart';
import 'package:im/pages/search/widgets/search_input_box.dart';
import 'package:im/pages/search/widgets/search_list_view.dart';
import 'package:im/pages/search/widgets/search_members_view.dart';
import 'package:im/routes.dart';
import 'package:im/themes/const.dart';
import 'package:im/widgets/app_bar/custom_appbar.dart';
import 'package:im/widgets/button/more_icon.dart';
import 'package:im/widgets/realtime_user_info.dart';
import 'package:im/widgets/refresh/refresh.dart';
import 'package:oktoast/oktoast.dart';
import 'package:pedantic/pedantic.dart';

/// - 权限选择 角色/成员 页面
class AddOverwritePage extends StatefulWidget {
  String get channelId => channel.id;
  final ChatChannel channel;

  // type 1 角色  2 成员
  final int type;

  final List<String> filterIds;

  const AddOverwritePage({
    @required this.channel,
    @required this.type,
    @required this.filterIds,
  });

  @override
  _AddOverwritePageState createState() => _AddOverwritePageState();
}

class _AddOverwritePageState extends State<AddOverwritePage> {
  ThemeData _theme;
  AddOverwriteModel _model;
  SearchMemberListModel _searchMemberModel;
  bool _addLoading = false;
  SearchInputModel _searchInputModel;
  TextEditingController _inputController;
  String searchKey;

  @override
  void initState() {
    if (_isAddRole()) {
      // 角色
      _model = AddOverwriteRoleModel(widget.channelId);
    } else {
      // 成员
      _model = AddOverwriteUserModel(widget.channelId);
      _searchMemberModel = SearchMemberListModel(_model.currentGuildId);
      _searchInputModel = SearchInputModel();
      _inputController = TextEditingController()
        ..addListener(() {
          if (_inputController.text.trim().isEmpty) {
            _model.clear();
          }
        });
    }
    super.initState();
  }

  @override
  void dispose() {
    _model.dispose();
    _inputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _theme = Theme.of(context);
    return GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          // 点击空白处 收起键盘
          FocusScope.of(context).requestFocus(FocusNode());
        },
        child: Scaffold(
            appBar: CustomAppbar(
              title: widget.type == 1 ? '选择角色'.tr : '选择成员'.tr,
            ),
            body: Column(
              children: <Widget>[
                if (_isAddMember()) _buildSearchBox(),
                Expanded(child: _buildList(_model)),
              ],
            )));
  }

  Widget _buildList(AddOverwriteModel model) {
    if (_isAddMember()) {
      return StreamBuilder(
        stream: _searchInputModel.searchStream,
        builder: (context, snapshot) {
          searchKey = snapshot.data;
          if (searchKey == null || searchKey.isEmpty) {
            return Refresher(
              model: model,
              enableRefresh: false,
              builder: (context) {
                return listViewBuilder(model.dataList);
              },
            );
          }
          return SearchListView<UserInfo>(
            dataFetcher: () =>
                _searchMemberModel.searchMembers(searchKey, isNeedRole: true),
            emptyResultBuilder: (_) => const SearchNoResultView(),
            listBuilder: listViewBuilder,
          );
        },
      );
    }

    return Refresher(
      model: model,
      enableRefresh: false,
      builder: (context) => listViewBuilder(model.dataList),
    );
  }

  Widget listViewBuilder(List dataList) {
    dataList = dataList.where((element) {
      if (element is UserInfo) {
        return !widget.filterIds.contains(element.userId);
      } else if (element is Role) {
        return !widget.filterIds.contains(element.id);
      } else {
        return true;
      }
    }).toList();
    if (dataList.isEmpty) {
      return _buildBlank();
    } else {
      return ListView.separated(
        padding: const EdgeInsets.only(top: 16),
        separatorBuilder: (_, __) => const Padding(
          padding: EdgeInsets.only(left: 60),
          child: Divider(color: Color(0xFFF5F5F8), thickness: 0.5),
        ),
        itemBuilder: (context, index) {
          // 服务器所有者排第一位，后面出现需去重
          if (_isAddMember() &&
              index != 0 &&
              dataList[index].userId == dataList.first.userId) {
            return const SizedBox();
          }
          return _buildItem(dataList[index]);
        },
        itemCount: dataList.length,
      );
    }
  }

  Widget _buildItem(item) {
    String id;
    String name;
    String actionType;
    bool hasPermission;
    String noPermissionTip;
    Widget child;
    if (item is UserInfo) {
      if (PermissionUtils.isGuildOwner(userId: item.userId)) {
        hasPermission = false;
      } else {
        hasPermission =
            PermissionUtils.comparePosition(roleIds: item.roles) == 1;
      }
      id = item.userId;
      name = item.nickname;
      actionType = 'user';
      noPermissionTip = '😑 只能设置比自己当前角色等级低的成员'.tr;
      child = _buildMemberItem(item, hasPermission);
    } else if (item is Role) {
      hasPermission = PermissionUtils.comparePosition(roleIds: [item.id]) == 1;
      id = item.id;
      name = item.name;
      actionType = 'role';
      noPermissionTip = '😑 只能设置比自己当前角色等级低的角色'.tr;
      child = _buildRoleItem(item, hasPermission);
    }

    return FadeBackgroundButton(
      backgroundColor: _theme.backgroundColor,
      tapDownBackgroundColor: hasPermission
          ? _theme.backgroundColor.withOpacity(0.5)
          : Colors.transparent,
      onTap: () async {
        if (!hasPermission) {
          showToast(noPermissionTip);
          return;
        }

        // 成员列表已经没有全量数据，先删除此本地判断的拦截
        // if (item is UserInfo &&
        //     !MemberListModel.instance.fullList.contains(item.userId)) {
        //   showToast('😑 成员已不在此服务器');
        //   return;
        // }

        if (_addLoading) return;
        _addLoading = true;
        final PermissionOverwrite overwrite = PermissionOverwrite(
            id: id,
            channelId: widget.channelId,
            guildId: _model.gp.guildId,
            actionType: actionType,
            allows: Permission.VIEW_CHANNEL.value,
            deny: 0,
            name: name);

        try {
          await PermissionModel.updateOverwrite(overwrite,
              isCirclePermission:
                  widget.channel.type == ChatChannelType.guildCircleTopic);
          unawaited(Routes.pushOverwritePage(context, overwrite, widget.channel,
              replace: true));
        } finally {
          _addLoading = false;
        }
      },
      child: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.all(16),
        child: child,
      ),
    );
  }

  Widget _buildMemberItem(UserInfo user, bool hasPermission) {
    final double opacity = hasPermission ? 1 : 0.4;
    final contentStyle = TextStyle(
      color: _theme.textTheme.bodyText2.color.withOpacity(opacity),
    );
    final highlightStyle = TextStyle(
      color: const Color(0xFF1B4EBF).withOpacity(opacity),
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Opacity(
          opacity: hasPermission ? 1 : 0.5,
          child: RealtimeAvatar(
            userId: user.userId,
            size: 40,
          ),
        ),
        sizeWidth12,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              HighlightMemberNickName(
                user,
                keyword: searchKey,
                contentStyle: contentStyle,
                highlightStyle: highlightStyle,
              ),
              sizeHeight4,
              Text(
                '#${user.username}',
                style: const TextStyle(
                  color: Color(0xFF8F959E),
                  fontSize: 13,
                ),
              ),
              if (user.roles?.isNotEmpty ?? false) sizeHeight10,
              if (user.roles?.isNotEmpty ?? false) _buildMemberRoles(user),
            ],
          ),
        ),
        if (hasPermission)
          const MoreIcon()
        else
          const Icon(IconFont.buffChannelLock),
      ],
    );
  }

  Widget _buildRoleItem(Role item, bool hasPermission) {
    Color textColor = _theme.textTheme.bodyText2.color;
    final int roleColorValue = _model.gp.roles
        .firstWhere((element) => element.id == item.id, orElse: () => null)
        ?.color;
    if (roleColorValue != 0 && roleColorValue != null)
      textColor = Color(roleColorValue);
    return Row(
      children: <Widget>[
        Expanded(
            child: Text(
          item.name,
          overflow: TextOverflow.ellipsis,
          style: _theme.textTheme.bodyText2
              .copyWith(color: textColor.withOpacity(hasPermission ? 1 : 0.4)),
        )),
        if (hasPermission)
          const MoreIcon()
        else
          const Icon(IconFont.buffChannelLock),
      ],
    );
  }

  Widget _buildBlank() {
    if (_isAddMember() && _inputController.text.hasValue) {
      /// 搜索结果为空
      return const SearchNoResultView();
    }

    /// 没有成员
    return Container(
      alignment: Alignment.topCenter,
      padding: const EdgeInsets.only(top: 50),
      child: Text(
        _isAddRole() ? '暂无角色'.tr : '暂无成员'.tr,
        style: Theme.of(context).textTheme.bodyText1.copyWith(fontSize: 14),
      ),
    );
  }

  Widget _buildMemberRoles(UserInfo user) {
    return UserInfo.withUserRoles(user, builder: (context, roles, widget) {
      if (roles.isEmpty) return const SizedBox();
      return Wrap(
        spacing: 8,
        runSpacing: 4,
        children: roles
            .map((e) => Container(
                  height: 20,
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  decoration: BoxDecoration(
                    color: _theme.scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                            color: e.color == 0
                                ? Theme.of(context).textTheme.bodyText2.color
                                : Color(e.color),
                            shape: BoxShape.circle),
                      ),
                      sizeWidth5,
                      Flexible(
                        child: Text(
                          e.name,
                          overflow: TextOverflow.ellipsis,
                          style:
                              _theme.textTheme.bodyText2.copyWith(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ))
            .toList(),
      );
    });
  }

  Widget _buildSearchBox() {
    return Container(
      color: Colors.white,
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: SearchInputBox(
        searchInputModel: _searchInputModel,
        inputController: _inputController,
        borderRadius: 18,
        hintText: "搜索用户".tr,
        iconSize: 16,
        height: 36,
      ),
    );
  }

  /// 是否为添加角色页面
  bool _isAddRole() {
    return widget.type == 1;
  }

  /// 是否为添加成员页面
  bool _isAddMember() {
    return widget.type == 2;
  }
}
//
//typedef OnReorder = void Function(List<Role>);
//
//class OrderRoleList extends StatefulWidget {
//  final List<Role> roles;
//  final OnReorder onReorder;
//  const OrderRoleList(this.roles, {this.onReorder});
//  @override
//  _OrderRoleListState createState() => _OrderRoleListState();
//}
//
//class _OrderRoleListState extends State<OrderRoleList> {
//  List<Role> _newRoles;
//
//  @override
//  void initState() {
//    _newRoles = [...widget.roles];
//    super.initState();
//  }
//
//  @override
//  Widget build(BuildContext context) {
//    final List<Widget> _rows = _newRoles.map(_buildItem).toList();
//    return CustomScrollView(
//      slivers: <Widget>[
//        ReorderableSliverList(
//          delegate: ReorderableSliverChildListDelegate(_rows),
//          onReorder: _onReorder,
//        )
//      ],
//    );
//  }
//
//  Widget _buildItem(Role role) {
//    return FadeBackgroundButton(
//      backgroundColor: Colors.transparent,
//      tapDownBackgroundColor:
//          Theme.of(context).scaffoldBackgroundColor.withOpacity(0.5),
//      child: Container(
//        alignment: Alignment.centerLeft,
//        padding: const EdgeInsets.all(16),
//        child: Row(
//          children: <Widget>[
//            GestureDetector(
//              onTap: () => _onDelete(role),
//              child:
//                  const Icon(Icons.remove_circle, size: 18, color: Colors.red),
//            ),
//            sizeWidth12,
//            Expanded(
//              child: Text(
//                role.name,
//                style: const TextStyle(fontSize: 14),
//              ),
//            ),
//            const Icon(Icons.drag_handle)
//          ],
//        ),
//      ),
//    );
//  }
//
//  void _onReorder(int oldIndex, int newIndex) {
//    final Role role = _newRoles.removeAt(oldIndex);
//    _newRoles.insert(newIndex, role);
//    resetPosition();
//    widget.onReorder(_newRoles);
//  }
//
//  Future<void> _onDelete(Role role) async {
//    final res = await showConfirmDialog(context,
//        title: '提示'.tr, content: '确认删除 ${role.name}');
//    if (res) {
//      _newRoles.remove(role);
//      resetPosition();
//    }
//  }
//
//  void resetPosition() {
//    setState(() {
//      for (var i = 0; i < _newRoles.length; i++) {
//        _newRoles[i].setPosition(_newRoles.length - 1 - i);
//      }
//    });
//  }
//}
