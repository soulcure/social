import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/api/data_model/user_info.dart';
import 'package:im/app/theme/app_theme.dart';
import 'package:im/common/extension/string_extension.dart';
import 'package:im/common/permission/permission.dart';
import 'package:im/common/permission/permission_utils.dart';
import 'package:im/core/widgets/button/fade_background_button.dart';
import 'package:im/global.dart';
import 'package:im/icon_font.dart';
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

import 'model/member_manage_model.dart';

class MemberManagePage extends StatefulWidget {
  final String guildId;

  const MemberManagePage(this.guildId);

  @override
  _MemberManagePageState createState() => _MemberManagePageState();
}

class _MemberManagePageState extends State<MemberManagePage> {
  ThemeData _theme;
  MemberManageModel _model;
  SearchMemberListModel _searchMemberModel;
  SearchInputModel _searchInputModel;
  TextEditingController _searchInputController;
  String searchKey;

  @override
  void initState() {
    _model = MemberManageModel(guildId: widget.guildId);
    _searchMemberModel = SearchMemberListModel(widget.guildId);
    _searchInputModel = SearchInputModel();
    _searchInputController = TextEditingController()
      ..addListener(() {
        if (_searchInputController.text.trim().isEmpty) {
          _model.clear();
        }
      });
    super.initState();
  }

  @override
  void dispose() {
    _model.destroy();
    _searchInputController.dispose();
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
            title: '成员'.tr,
          ),
          body: ValidPermission(
            permissions: const [],
            builder: (value, _) {
              return Column(
                children: [
                  _buildSearchBox(),
                  Expanded(child: _buildSearchList()),
                ],
              );
            },
          ),
        ));
  }

  Widget _buildSearchList() {
    return StreamBuilder(
      stream: _searchInputModel.searchStream,
      builder: (context, snapshot) {
        searchKey = snapshot.data;
        if (searchKey == null || searchKey.isEmpty)
          return Refresher(
            key: ValueKey("MemberManage$searchKey"),
            model: _model,
            enableRefresh: false,
            builder: (context) {
              return _buildList(
                _model.list,
              );
            },
          );
        return SearchListView<UserInfo>(
          dataFetcher: () =>
              _searchMemberModel.searchMembers(searchKey, isNeedRole: true),
          listBuilder: _buildList,
        );
      },
    );
  }

  Widget _buildList(List<UserInfo> users) {
    if (users == null || users.isEmpty) {
      return _buildBlank();
    }
    return ListView.separated(
      padding: const EdgeInsets.only(top: 16),
      separatorBuilder: (_, index) => Padding(
        padding: const EdgeInsets.only(left: 60),
        child: Divider(color: appThemeData.dividerColor),
      ),
      itemBuilder: (context, index) {
        // 服务器所有者排第一位，后面出现需去重
        if (index != 0 &&
            _model.list.length > index &&
            _model.list[index].userId == _model.list.first.userId) {
          return const SizedBox();
        }
        return _buildItem(users[index]);
      },
      itemCount: users.length,
    );
  }

  Widget _buildItem(UserInfo user) {
    bool hasPermission;

    bool isGuildOwner = false;
    if (!PermissionUtils.isGuildOwner(userId: user.userId)) {
      hasPermission = PermissionUtils.comparePosition(roleIds: user.roles) == 1;
    } else {
      hasPermission = PermissionUtils.isGuildOwner(userId: Global.user.id);
      isGuildOwner = PermissionUtils.isGuildOwner(userId: user.userId);
    }
    final ownerBadge = isGuildOwner
        ? const Padding(
            padding: EdgeInsets.only(left: 8),
            child: Icon(
              IconFont.buffOtherStars,
              color: Color(0xffFAA61A),
              size: 18,
            ),
          )
        : null;
    return FadeBackgroundButton(
      backgroundColor: _theme.backgroundColor,
      tapDownBackgroundColor: _theme.backgroundColor.withOpacity(0.5),
      onTap: () async {
        if (!hasPermission) {
          showToast('只能管理比自己角色等级低的其他成员╮(╯▽╰)╭'.tr);
          return;
        }
        final userId =
            await Routes.pushMemberSettingPage(context, widget.guildId, user);
        if (userId != null) {
          _model.removeMember(userId);
        }
      },
      child: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            RealtimeAvatar(
              userId: user.userId,
              size: 40,
            ),
            sizeWidth8,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      // Flexible(
                      //   child: RealtimeNickname(
                      //     userId: userInfo.userId,
                      //     style: const TextStyle(fontSize: 16),
                      //     preferentialRemark: true,
                      //   ),
                      // ),
                      Expanded(
                        child: HighlightMemberNickName(
                          user,
                          keyword: searchKey,
                          badge: ownerBadge,
                        ),
                      ),
                    ],
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
              Icon(
                IconFont.buffChannelLock,
                color: Theme.of(context).disabledColor.withOpacity(0.5),
              ),
          ],
        ),
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
        inputController: _searchInputController,
        borderRadius: 18,
        hintText: "搜索用户".tr,
        autoFocus: false,
        height: 36,
      ),
    );
  }

  Widget _buildBlank() {
    if (_searchInputController.text.hasValue) {
      return const SearchNoResultView();
    }
    return sizedBox;
  }
}
