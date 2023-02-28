import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:im/api/data_model/user_info.dart';
import 'package:im/common/permission/permission.dart';
import 'package:im/common/permission/permission_model.dart';
import 'package:im/db/db.dart';
import 'package:im/icon_font.dart';
import 'package:im/pages/guild_setting/role/role.dart';
import 'package:im/pages/home/model/chat_index_model.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/pages/search/model/search_model.dart';
import 'package:im/pages/search/widgets/member_nickname.dart';
import 'package:im/pages/search/widgets/search_input_box.dart';
import 'package:im/svg_icons.dart';
import 'package:im/themes/const.dart';
import 'package:im/utils/utils.dart';
import 'package:im/widgets/app_bar/appbar_builder.dart';
import 'package:im/widgets/avatar.dart';
import 'package:im/widgets/fb_check_box.dart';
import 'package:im/widgets/load_more.dart';
import 'package:im/widgets/search_widget/ordered_member_search_controller.dart';
import 'package:im/widgets/svg_tip_widget.dart';
import 'package:oktoast/oktoast.dart';

class SelectRoleUserPage extends StatefulWidget {
  final String guildId;
  final String cateId;

  const SelectRoleUserPage({Key key, this.guildId, this.cateId})
      : super(key: key);

  @override
  SelectRoleUserPageState createState() => SelectRoleUserPageState();
}

class SelectRoleUserPageState<T extends SelectRoleUserPage> extends State<T> {
  final searchInputModel = SearchInputModel();
  final inputController = TextEditingController();

  Set<String> selectedRoleIds = {};
  Set<String> selectedUserIds = {};

  List<Role> roles = [];

  OrderedMemberSearchController _searchController;
  ValueListenable<Box<GuildPermission>> _box;
  bool isLoaded = false;

  @override
  void initState() {
    super.initState();

    _searchController = OrderedMemberSearchController.fromDebouncedTextStream(
      guildId: widget.guildId,
      channelId: "0",
      stream: searchInputModel.searchStream,
    );

    /// 此订阅会被 searchInputModel.dispose 关闭，不需要单独关闭
    searchInputModel.searchStream.listen((event) {
      _searchController?.update();
    });

    _box = Db.guildPermissionBox.listenable(keys: [widget.guildId]);
    _box.addListener(refresh);
  }

  void refresh() {
    _searchController.update();
  }

  @override
  void dispose() {
    super.dispose();
    searchInputModel.dispose();
    inputController.dispose();
    _searchController.dispose();
    _box.removeListener(refresh);
  }

  @override
  Widget build(BuildContext context) {
    final ownerId =
        (ChatTargetsModel.instance.getChatTarget(widget.guildId) as GuildTarget)
            .ownerId;

    roles = guildRoles();
    return GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Scaffold(
            backgroundColor: Theme.of(context).backgroundColor,
            appBar: appBar(),
            body: GetBuilder<OrderedMemberSearchController>(
                init: _searchController,
                builder: (omsCtr) {
                  final userList = filterUser(omsCtr.list)
                      .where((e) => e.userId != ownerId)
                      .toList();
                  return roles.isEmpty && userList.isEmpty && isLoaded
                      ? emptyWidget()
                      : userAndRoleList(omsCtr, context, userList, ownerId);
                })));
  }

  /// 角色 和 用户列表
  Widget userAndRoleList(OrderedMemberSearchController omsCtr,
      BuildContext context, List<UserInfo> userList, String ownerId) {
    isLoaded = true;
    return Column(
      children: [
        Container(
          height: 36,
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: SearchInputBox(
              borderRadius: 5,
              hintText: "搜索成员".tr,
              inputController: inputController,
              searchInputModel: searchInputModel,
              height: 36,
              autoFocus: false),
        ),
        Expanded(
          child: LoadMore(
            autoStart: true,
            fetchNextPage: omsCtr.fetchNextPage,
            builder: (loadingWidget) {
              return Scrollbar(
                child: CustomScrollView(
                  slivers: [
                    SliverVisibility(
                        visible: roles.isNotEmpty &&
                            (searchInputModel.input == null ||
                                searchInputModel.input.isEmpty),
                        sliver: _buildHeader(
                            context, "角色-${roles?.length}".tr, true)),
                    _buildList(
                        indent: 56,
                        data: roles.isNotEmpty &&
                                (searchInputModel.input == null ||
                                    searchInputModel.input.isEmpty)
                            ? roles
                            : [],
                        builder: (e) => buildRoleItem(context, e)),
                    SliverVisibility(
                        visible: userList.isNotEmpty,
                        sliver: _buildHeader(
                            context, "成员-${userList?.length}".tr, false)),
                    _buildList(
                        data: userList ?? [],
                        builder: (e) => buildUserItem(context, e),
                        indent: 50),
                    _buildLoadingWidget(loadingWidget),
                    SliverToBoxAdapter(
                        child: SizedBox(height: getBottomViewInset())),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  /// 空页面
  Widget emptyWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 100),
        child: SvgTipWidget(
          svgName: SvgIcons.nullState,
          text: '暂无角色或成员'.tr,
        ),
      ),
    );
  }

  Widget appBar() {
    return FbAppBar.custom(
      '选择成员'.tr,
    );
  }

  // 用户数据过滤
  List<UserInfo> filterUser(List<UserInfo> users) {
    return users;
  }

  // 角色列表数据源
  List<Role> guildRoles() {
    final List<Role> rs =
        List.from(PermissionModel.getPermission(widget.guildId).roles);
    for (final role in rs) {
      // 去掉全体成员
      if (role.id == widget.guildId) {
        rs.remove(role);
        break;
      }
    }
    return rs;
  }

  void onTapRole(String roleId) {
    if (selectedRoleIds.contains(roleId)) {
      selectedRoleIds.remove(roleId);
    } else {
      if (selectedUserIds.length + selectedRoleIds.length >= 50) {
        showToast('最多可选择50项'.tr);
        return;
      }
      selectedRoleIds.add(roleId);
    }
    setState(() {});
  }

  void onTapUser(String userId) {
    if (selectedUserIds.contains(userId)) {
      selectedUserIds.remove(userId);
    } else {
      if (selectedUserIds.length + selectedRoleIds.length >= 50) {
        showToast('最多可选择50项'.tr);
        return;
      }
      selectedUserIds.add(userId);
    }
    setState(() {});
  }

  Widget _buildLoadingWidget(Widget Function() loadingWidget) {
    return GetBuilder<OrderedMemberSearchController>(
        builder: (_) => SliverVisibility(
            visible: _.showLoadingWidget,
            sliver: SliverPadding(
                padding: const EdgeInsets.only(top: 8),
                sliver: SliverToBoxAdapter(
                  child: loadingWidget(),
                ))));
  }

  SliverList _buildList<U>(
      {List<U> data, Widget Function(U) builder, double indent = 16}) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
          (context, index) => index.isEven
              ? builder(data[index ~/ 2])
              : Divider(
                  indent: indent,
                  color: Theme.of(context).dividerColor.withOpacity(0.1)),
          childCount: data.length * 2 - 1),
    );
  }

  Widget _buildHeader(BuildContext context, String label, bool isRole) {
    return SliverToBoxAdapter(
      child: Container(
        color: const Color(0xFFf5f5f8),
        height: isRole ? 37 : 47,
        margin: isRole ? const EdgeInsets.fromLTRB(0, 10, 0, 0) : null,
        padding: isRole
            ? const EdgeInsets.fromLTRB(16, 16, 16, 0)
            : const EdgeInsets.fromLTRB(16, 26, 16, 0),
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodyText1.copyWith(
              fontSize: 14, height: 1, color: const Color(0xFF5C6273)),
        ),
      ),
    );
  }

  Widget _listCell({
    double height,
    GestureTapCallback onTap,
    @required Widget child,
  }) {
    return GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: onTap,
        child: SizedBox(
          height: height,
          child: child,
        ));
  }

  Widget buildRoleItem(BuildContext context, Role r) {
    final roleIcon =
        r.managed ? IconFont.buffBotIconColor : IconFont.buffRoleIconColor;
    final _theme = Theme.of(context);
    final roleColor =
        r.color != 0 ? Color(r.color) : _theme.textTheme.bodyText1.color;
    return _listCell(
        height: 64,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: <Widget>[
              IgnorePointer(
                child: FBCheckBox(
                    value: selectedRoleIds.contains(r.id),
                    onChanged: (value) {}),
              ),
              sizeWidth12,
              Icon(roleIcon, size: 28, color: roleColor),
              sizeWidth12,
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 16, height: 1.25, color: Color(0xFF1F2126)),
                    ),
                    sizeHeight6,
                    Row(
                      children: [
                        const Icon(IconFont.buffMembersNum,
                            size: 12, color: Color(0xFF8D93A6)),
                        sizeWidth4,
                        Text(
                          '${r?.memberCount?.toString() ?? 0} 位成员',
                          style: const TextStyle(
                              fontSize: 12,
                              height: 1.25,
                              color: Color(0xFF8D93A6)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        onTap: () => onTapRole(r.id));
  }

  Widget buildUserItem(BuildContext context, UserInfo userInfo) {
    return _listCell(
        height: 64,
        child: Container(
          padding: const EdgeInsets.only(left: 16, right: 16),
          child: Row(
            children: <Widget>[
              IgnorePointer(
                child: FBCheckBox(
                    value: selectedUserIds.contains(userInfo.userId),
                    onChanged: (value) {}),
              ),
              sizeWidth10,
              Avatar(
                size: 40,
                url: userInfo.avatar,
                radius: 20,
              ),
              sizeWidth12,
              Expanded(
                  child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: <Widget>[
                      Flexible(
                        child: HighlightMemberNickName(
                          userInfo,
                          keyword: inputController.text,
                        ),
                      ),
                      sizeWidth8,
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "#${userInfo.username}",
                    style: TextStyle(
                        fontSize: 13, color: Theme.of(context).disabledColor),
                  ),
                ],
              )),
            ],
          ),
        ),
        onTap: () => onTapUser(userInfo.userId));
  }
}
