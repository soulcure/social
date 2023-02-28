import 'package:flutter/material.dart';
import 'package:im/api/data_model/user_info.dart';
import 'package:im/app/modules/tc_doc_add_group_page/controllers/tc_doc_add_group_page_controller.dart';
import 'package:im/app/modules/tc_doc_add_group_page/entities/tc_doc_group.dart';
import 'package:im/app/modules/tc_doc_add_group_page/widgets/tc_doc_group_mixin.dart';
import 'package:im/app/theme/app_theme.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/pages/search/widgets/search_list_view.dart';
import 'package:im/themes/const.dart';
import 'package:im/widgets/avatar.dart';
import 'package:im/widgets/realtime_user_info.dart';
import 'package:im/widgets/segment_list/segment_member_list_options.dart';

class TcDocMembers extends StatefulWidget {
  final TcDocAddGroupPageController controller;

  const TcDocMembers(this.controller);

  @override
  State<TcDocMembers> createState() => _TcDocMembersState();
}

class _TcDocMembersState extends State<TcDocMembers>
    with AutomaticKeepAliveClientMixin, TcDocGroupMixin {
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return StreamBuilder(
      stream: widget.controller.searchInputModel.searchStream,
      builder: (context, snapshot) {
        final searchKey = snapshot.data;
        if (searchKey == null || searchKey.isEmpty) {
          return SegmentMemberListOptions(
            widget.controller.guildId,
            '0',
            ChatChannelType.guildCircle,
            // filterUsers: widget.controller.filterUsers,
            filterUser: widget.controller.filterUser,
            toggleSelect: (userId, [isSelect]) => widget.controller
                .toggleSelect(userId, TcDocGroupType.user, isSelect),
            isSelected: widget.controller.isSelected,
          );
        } else {
          return SearchListView<UserInfo>(
            dataFetcher: () => widget.controller.searchMemberModel
                .searchMembers(searchKey, isNeedRole: true),
            listBuilder: _buildList,
          );
        }
      },
    );
  }

  Widget _buildList(List<UserInfo> users) {
    final newUsers = widget.controller.filterUsers(users);
    return ListView.separated(
      padding: EdgeInsets.zero,
      separatorBuilder: (_, index) => const Divider(
        thickness: 0.5,
        indent: 44,
      ),
      itemBuilder: (context, index) {
        // 服务器所有者排第一位，后面出现需去重
        if (index != 0 && newUsers[index].userId == newUsers.first.userId) {
          return const SizedBox();
        }
        return _buildItem(newUsers[index]);
      },
      itemCount: newUsers.length,
    );
  }

  Widget _buildItem(UserInfo user) {
    return GestureDetector(
      onTap: () {
        widget.controller.toggleSelect(user.userId, TcDocGroupType.user);
      },
      child: Container(
        height: 64,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        color: appThemeData.backgroundColor,
        child: UserInfo.consume(user.userId, builder: (context, userInfo, _) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              ...buildLeading(
                  widget.controller, user.userId, TcDocGroupType.user),
              Avatar(
                url: userInfo.avatar,
                radius: 20,
              ),
              sizeWidth8,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: RealtimeNickname(userId: user.userId),
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
                  ],
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
