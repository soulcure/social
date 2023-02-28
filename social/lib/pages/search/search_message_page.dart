import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/pages/search/model/search_model.dart';
import 'package:im/pages/search/widgets/search_input_box.dart';
import 'package:im/pages/search/widgets/search_members_view.dart';
import 'package:im/pages/search/widgets/search_messages_view.dart';
import 'package:im/themes/const.dart';
import 'package:im/utils/orientation_util.dart';
import 'package:im/web/widgets/app_bar/web_appbar.dart';
import 'package:im/widgets/button/flat_action_button.dart';
import 'package:provider/provider.dart';

class SearchMessagePage extends StatelessWidget {
  final String guildId;
  final String channelId;
  final SearchInputModel _searchInputModel;

  SearchMessagePage(this.guildId, {Key key, this.channelId})
      : _searchInputModel = SearchInputModel(),
        super(key: key);

  /// 构造输入栏
  Widget _buildSearchBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 12, top: 6, bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 36,
              child: SearchInputBox(
                searchInputModel: _searchInputModel,
                height: 36,
                focusNode: _searchInputModel.inputFocusNode,
              ),
            ),
          ),
          FlatActionButton(
            padding: const EdgeInsets.only(right: 16, left: 12),
            onPressed: Get.back,
            child: Text(
              "取消".tr,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      // resizeToAvoidBottomInset: false,
      appBar: OrientationUtil.landscape
          ? WebAppBar(
              title: '搜索'.tr,
              backAction: Get.back,
            )
          : null,
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          // 点击空白处 收起键盘
          FocusScope.of(context).requestFocus(FocusNode());
        },
        child: SafeArea(
          child: ChangeNotifierProvider<SearchInputModel>(
            create: (_) => _searchInputModel,
            child: Column(
              children: [
                _buildSearchBar(context),
                Expanded(child: SearchTabView(guildId, channelId: channelId)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 构建输入框下方的界面，包含结果列表，搜索错误，搜索为空，搜索中等状态
class SearchTabView extends StatefulWidget {
  final String guildId;
  final String channelId;

  const SearchTabView(this.guildId, {Key key, this.channelId})
      : super(key: key);

  @override
  _SearchTabViewState createState() => _SearchTabViewState();
}

class _SearchTabViewState extends State<SearchTabView>
    with SingleTickerProviderStateMixin {
  SearchTabModel _searchTabModel;
  TabController _tabController;

  @override
  void initState() {
    super.initState();
    _searchTabModel = SearchTabModel();
    _tabController = TabController(
      length: widget.channelId == null ? 2 : 1,
      vsync: this,
      initialIndex: _searchTabModel.currentTab,
    );

    if (widget.channelId != null) {
      _searchTabModel.isGroup = true;
    } else {
      _searchTabModel.isGroup = false;
    }
  }

  /// 用户切换tab时调用
  void _onTabChange(int tab) {
    _searchTabModel.setCurrentTab(_tabController.index);
  }

  void _onGroupChange(int tab) {
    if (tab == 0) _searchTabModel.isGroup = true;
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => _searchTabModel,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              indicatorSize: TabBarIndicatorSize.label,
              indicatorColor: Get.theme.primaryColor,
              labelPadding:
                  const EdgeInsets.only(left: 12, right: 12, bottom: 10.5),
              tabs: widget.channelId == null
                  ? [
                      SearchTab(text: "消息".tr, index: 0),
                      SearchTab(text: "成员".tr, index: 1),
                    ]
                  : [
                      SearchTab(text: "成员".tr, index: 0),
                    ],
              onTap: widget.channelId == null ? _onTabChange : _onGroupChange,
            ),
          ),
          const Divider(color: Color(0xFFF5F5F8), height: 1, thickness: 1),
          sizeHeight10,
          Expanded(
            child: TabBarView(
              controller: _tabController,
              physics: const NeverScrollableScrollPhysics(),
              children: widget.channelId == null
                  ? [
                      // 消息搜索Tab页
                      SearchMessagesView(widget.guildId),
                      // 联系人搜索Tab页
                      SearchMembersView(
                        widget.guildId,
                        channelId: widget.channelId,
                      ),
                    ]
                  : [
                      // 联系人搜索Tab页
                      SearchMembersView(
                        widget.guildId,
                        channelId: widget.channelId,
                      ),
                    ],
            ),
          ),
        ],
      ),
    );
  }
}

class SearchTab extends StatelessWidget {
  final String text;
  final int index;

  const SearchTab({
    Key key,
    @required this.text,
    @required this.index,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final selectTextStyle = TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 15,
      color: Get.theme.primaryColor,
    );
    const unSelectTextStyle = TextStyle(
      fontWeight: FontWeight.normal,
      fontSize: 15,
      color: Color(0xFF1F2329),
    );

    return Selector<SearchTabModel, int>(
      selector: (_, model) => model.currentTab,
      builder: (_, currentTab, __) => Text(
        text,
        style: currentTab == index ? selectTextStyle : unSelectTextStyle,
      ),
    );
  }
}
