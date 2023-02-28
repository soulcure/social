import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/core/http_middleware/http.dart';
import 'package:im/core/widgets/button/fade_button.dart';
import 'package:im/pages/guild_setting/circle/circle_detail_page/common.dart';
import 'package:im/pages/home/json/text_chat_json.dart';
import 'package:im/pages/home/view/text_chat/items/components/parsed_text_extension.dart';
import 'package:im/pages/home/view/text_chat/text_chat_ui_creator.dart';
import 'package:im/pages/search/model/search_message_controller.dart';
import 'package:im/pages/search/model/search_model.dart';
import 'package:im/pages/search/search_util.dart';
import 'package:im/svg_icons.dart';
import 'package:im/themes/const.dart';
import 'package:im/utils/orientation_util.dart';
import 'package:im/utils/utils.dart';
import 'package:im/widgets/realtime_user_info.dart';
import 'package:provider/provider.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

/// 搜索消息tab页
class SearchMessagesView extends StatefulWidget {
  final String guildId;

  const SearchMessagesView(this.guildId, {Key key}) : super(key: key);

  @override
  _SearchMessagesViewState createState() => _SearchMessagesViewState();
}

class _SearchMessagesViewState extends State<SearchMessagesView>
    with AutomaticKeepAliveClientMixin {
  SearchInputModel inputModel;
  SearchTabModel searchTabModel;
  SearchMessageController searchMessageController;

  RequestType requestType = RequestType.normal;
  RefreshController _refreshController;
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    inputModel = Provider.of<SearchInputModel>(context, listen: false);
    searchTabModel = Provider.of<SearchTabModel>(context, listen: false);
    _refreshController = RefreshController();
    searchMessageController = SearchMessageController(
        widget.guildId, inputModel, searchTabModel, _refreshController);
    Get.put(searchMessageController, tag: widget.guildId);
    _registerTabChangeListener();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    //滚动时，取消输入框焦点
    if (inputModel.inputFocusNode.hasFocus) {
      FocusScope.of(context).requestFocus(FocusNode());
    }

    if (OrientationUtil.landscape &&
        _scrollController.offset ==
            _scrollController.position.maxScrollExtent &&
        !_refreshController.isLoading &&
        searchMessageController.hasNextPage) {
      debugPrint('getChat search -->> requestLoading');
      _refreshController.requestLoading();
    }
  }

  /// 监听tab变化，如果搜索关键字较之上次发生变化，则重新搜索
  void _registerTabChangeListener() {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      _onTabSelect();
      searchTabModel?.addListener(_onTabSelect);
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final childWidget = GetBuilder<SearchMessageController>(
      tag: widget.guildId,
      builder: (c) {
        if (c.resultList.isEmpty) {
          if (c.searchStatus == SearchStatus.searching) {
            return SearchUtil.buildSearchingView();
          } else if (c.searchStatus == SearchStatus.fail) {
            return SearchUtil.buildRetryView(() {
              c.reSearch();
            });
            // } else if (c.searchStatus == SearchStatus.success) {
            //   return const SearchNoResultView(hint: "未搜索到相关消息");
          } else {
            return SearchNullView(
              svgName: SvgIcons.nullState,
              text: '搜索消息对话'.tr,
            );
          }
        } else if (c.resultList.length < c.size) {
          _refreshController.loadNoData();
        }

        final smartRefresher = SmartRefresher(
          scrollDirection: Axis.vertical,
          enablePullDown: false,
          enablePullUp: true,
          controller: _refreshController,
          onLoading: () {
            requestType = RequestType.normal;
            c.searchMore().then((value) {
              if (value < c.size) {
                _refreshController.loadNoData();
              } else {
                _refreshController.loadComplete();
              }
            }).catchError((error) {
              if (Http.isNetworkError(error))
                requestType = RequestType.netError;
              else
                requestType = RequestType.dataError;
              _refreshController.loadFailed();
            });
          },
          footer: CustomFooter(
            height: 58,
            builder: (context, mode) {
              return footBuilder(context, mode,
                  requestType: requestType, showDivider: false);
            },
          ),
          child: _buildMsgResultList(c),
        );
        return smartRefresher;
      },
    );

    return childWidget;
  }

  @override
  bool get wantKeepAlive => true;

  /// 构建消息搜索列表
  Widget _buildMsgResultList(SearchMessageController c) {
    return ListView.separated(
        controller: _scrollController,
        itemCount: c.resultList.length,
        separatorBuilder: (context, i) => sizedBox,
        itemBuilder: (context, i) => _buildSearchResultItem(c, i));
  }

  /// 构建搜索item
  Widget _buildSearchResultItem(SearchMessageController c, int i) {
    final item = c.resultList[i];
    MessageEntity lastItem;
    if (i > 0) {
      lastItem = c.resultList[i - 1];
    }
    final channelName = c.getChannelName(item.channelId);
    final isShowChannel =
        lastItem == null || lastItem.channelId != item.channelId;
    return Column(
      children: [
        if (isShowChannel)
          FadeButton(
            onTap: () => c.gotoChannel(context, item.channelId),
            child: Container(
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.only(left: 16, top: 16, bottom: 6),
              color: const Color(0xFFF5F5F8),
              child: Text(
                '#$channelName',
                style: const TextStyle(color: Color(0xFF6D6F73), fontSize: 14),
              ),
            ),
          ),
        if (!isShowChannel)
          const Padding(padding: EdgeInsets.only(left: 68), child: divider),
        FadeButton(
          // height: 64,
          padding:
              const EdgeInsets.only(left: 16, right: 16, top: 10, bottom: 8),
          onTap: () => c.gotoChatWindow(context, item),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RealtimeAvatar(userId: item.userId, size: 32),
              sizeWidth12,
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                            child: RealtimeNickname(
                          userId: item.userId,
                          style: const TextStyle(
                              color: Color(0xFF646A73), fontSize: 13),
                          showNameRule: ShowNameRule.remarkAndGuild,
                        )),
                        sizeWidth4,
                        Text(
                          formatDate2Str(item.time),
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF8F959E),
                          ),
                        ),
                      ],
                    ),
                    sizeHeight4,
                    // AbsorbPointer(
                    //   child:
                    TextChatUICreator.createItemContent(item,
                        context: context,
                        index: i,
                        searchKey: c.searchKey,
                        messageList: c.resultList,
                        refererChannelSource: RefererChannelSource
                            .MessageSearch, onUnFold: (string) {
                      if (!c.unFoldMessageList.contains(string)) {
                        c.unFoldMessageList.add(string);
                      }
                    }, isUnFold: (string) {
                      return c.unFoldMessageList.contains(string);
                    }),
                    // ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 切换tab页时触发
  void _onTabSelect() {
    // 是否选中消息搜索tab页
    final isSelected = searchTabModel?.isSelectMessageTab() == true;
    // 搜索消息的key是否发生变化
    final isKeyChange = inputModel.input != searchMessageController.searchKey;
    if (isSelected && isKeyChange) {
      // 触发重新搜索消息
      inputModel.repeatLast();
    }
  }

  @override
  void dispose() {
    super.dispose();
    _scrollController?.dispose();
    _refreshController?.dispose();
    searchTabModel.removeListener(_onTabSelect);
    Get.delete<SearchMessageController>(tag: widget.guildId);
  }
}
