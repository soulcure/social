import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/api/data_model/user_info.dart';
import 'package:im/core/widgets/button/fade_button.dart';
import 'package:im/icon_font.dart';
import 'package:im/pages/home/model/chat_index_model.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/pages/search/model/search_member_model.dart';
import 'package:im/pages/search/model/search_model.dart';
import 'package:im/pages/search/widgets/member_nickname.dart';
import 'package:im/pages/search/widgets/search_list_view.dart';
import 'package:im/themes/const.dart';
import 'package:im/widgets/realtime_user_info.dart';
import 'package:im/widgets/user_info/popup/user_info_popup.dart';
import 'package:provider/provider.dart';

/// 搜索成员tab页
class SearchMembersView extends StatefulWidget {
  final String guildId;
  final String channelId;

  const SearchMembersView(this.guildId, {Key key, this.channelId})
      : super(key: key);

  @override
  _SearchMembersViewState createState() => _SearchMembersViewState();
}

class _SearchMembersViewState extends State<SearchMembersView>
    with AutomaticKeepAliveClientMixin {
  SearchInputModel inputModel;
  SearchMemberListModel searchMemberModel;
  SearchTabModel searchTabModel;

  @override
  void initState() {
    super.initState();
    searchMemberModel =
        SearchMemberListModel(widget.guildId, channelId: widget.channelId);
    _registerTabChangeListener();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return StreamBuilder<String>(
      stream: _inputStream(context),
      builder: (context, snapshot) {
        final searchKey = snapshot.data;
        return SearchListView<UserInfo>(
          dataFetcher: () =>
              searchMemberModel.searchMembers(searchKey, isNeedRole: true),
          emptyResultBuilder: (_) => _buildEmptyResult(searchKey),
          listBuilder: _buildMemResultList,
        );
      },
    );
  }

  /// 监听tab变化，如果搜索关键字较之上次发生变化，则重新搜索
  void _registerTabChangeListener() {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      _onTabSelect();
      searchTabModel?.addListener(_onTabSelect);
    });
  }

  /// 切换tab页时触发
  void _onTabSelect() {
    // 是否选中成员搜索tab页
    final isSelected = searchTabModel?.isSelectMemberTab() == true;
    // 搜索成员的key是否发生变化
    final isKeyChange = inputModel.input != searchMemberModel.searchKey;
    if (isSelected && isKeyChange) {
      // 触发重新搜索成员
      inputModel.repeatLast();
    }
  }

  Stream<String> _inputStream(BuildContext context) {
    inputModel ??= Provider.of<SearchInputModel>(context, listen: false);
    searchTabModel ??= Provider.of<SearchTabModel>(context, listen: false);
    return inputModel.searchStream
        // 只有选中成员搜索才处理输入事件
        .where((event) {
      if (searchTabModel.isGroup) {
        return true;
      } else {
        return searchTabModel.isSelectMemberTab();
      }
    });
  }

  /// 构建成员搜索列表
  Widget _buildMemResultList(List<UserInfo> users) {
    return ListView.separated(
      itemCount: users.length,
      separatorBuilder: (_, __) => const Padding(
        padding: EdgeInsets.only(left: 68),
        child: divider,
      ),
      itemBuilder: (_, i) => _buildMemListItem(users[i]),
    );
  }

  Widget _buildEmptyResult(String searchKey) {
    if (searchKey == null || searchKey.isEmpty) {
      // 没有输入
      return SearchNoResultView(hint: "搜索你想要找的成员".tr);
    }
    // 没有搜索到成员
    return const SearchNoResultView();
  }

  Widget _buildMemListItem(UserInfo user) {
    return FadeButton(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      onTap: () {
        // todo: test
        return showUserInfoPopUp(
          context,
          guildId: ChatTargetsModel.instance.selectedChatTarget.id,
          userInfo: user,
          channelId: widget.channelId ?? GlobalState.selectedChannel.value?.id,
          showRemoveFromGuild: true,
          enterType: EnterType.fromServer,
        );
      },
      child: Row(
        children: [
          RealtimeAvatar(
            userId: user.userId,
            size: 40,
          ),
          sizeWidth12,
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                HighlightMemberNickName(
                  user,
                  guildId: widget.guildId,
                  keyword: searchMemberModel.searchKey,
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
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    super.dispose();
    searchTabModel.removeListener(_onTabSelect);
  }
}

class SearchNoResultView extends StatelessWidget {
  final String hint;

  const SearchNoResultView({Key key, this.hint = "未搜索到相关成员"}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Stack(children: [
        Positioned(
          top: 91,
          left: 0,
          right: 0,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(50)),
                  color: Color(0xFFF5F5F8),
                ),
                child: const Icon(
                  IconFont.buffCommonSearch,
                  size: 40,
                  color: Color(0x7F8F959E),
                ),
              ),
              sizeHeight24,
              Text(
                hint.tr,
                style: const TextStyle(color: Color(0xFF8F959E), fontSize: 14),
              ),
            ],
          ),
        )
      ]),
    );
  }
}
