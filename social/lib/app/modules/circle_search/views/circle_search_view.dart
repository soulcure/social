import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:get/get.dart';
import 'package:im/app/modules/circle/views/portrait/widgets/circle_topic_staggered_item.dart';
import 'package:im/app/modules/circle_detail/circle_detail_router.dart';
import 'package:im/app/modules/circle_detail/controllers/circle_detail_controller.dart';
import 'package:im/app/theme/app_theme.dart';
import 'package:im/core/http_middleware/http.dart';
import 'package:im/dlog/dlog_manager.dart';
import 'package:im/pages/guild_setting/circle/circle_detail_page/circle_page.dart';
import 'package:im/pages/search/model/search_model.dart';
import 'package:im/pages/search/search_util.dart';
import 'package:im/utils/orientation_util.dart';
import 'package:im/web/widgets/app_bar/web_appbar.dart';
import 'package:im/widgets/app_bar/custom_appbar.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

import '../../../../pages/guild_setting/circle/circle_detail_page/common.dart';
import '../../../../pages/search/widgets/search_input_box.dart';
import '../../../../widgets/button/flat_action_button.dart';
import '../controllers/circle_search_controller.dart';

///圈子搜索页
// ignore: must_be_immutable
class CircleSearchView extends GetView<CircleSearchController> {
  String guildId;
  String channelId;
  RequestType requestType = RequestType.normal;
  RefreshController _refreshController;
  SearchInputModel _searchInputModel;
  final _searchInputController = TextEditingController();

  //圈子搜索Controller
  CircleSearchController searchController;

  CircleSearchView({this.guildId, this.channelId}) {
    searchController = CircleSearchController(guildId, channelId);
    Get.put(searchController, tag: guildId);
    _refreshController = searchController.refreshController;
    _searchInputModel = searchController.searchInputModel;
    debugPrint('getChat search new: $guildId - $channelId');
    searchController.scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    final sc = searchController.scrollController;

    //滚动时，取消输入框焦点
    if (_searchInputModel.inputFocusNode.hasFocus) {
      _searchInputModel.inputFocusNode.unfocus();
    }
    if (OrientationUtil.landscape &&
        sc.offset == sc.position.maxScrollExtent &&
        !_refreshController.isLoading &&
        searchController.hasNextPage) {
      debugPrint('getChat search -- requestLoading');
      _refreshController.requestLoading();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEDEFF2),
      resizeToAvoidBottomInset: false,
      appBar: OrientationUtil.landscape
          ? WebAppBar(
              title: '圈子搜索'.tr,
              backAction: Get.back,
            )
          : NullAppbar(),
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          // 点击空白处 收起键盘
          FocusScope.of(context).requestFocus(FocusNode());
        },
        child: Column(
          children: [
            _buildSearchBar(context),
            Expanded(
              child: GetBuilder<CircleSearchController>(
                tag: guildId,
                builder: (c) {
                  if (c.resultList.isEmpty) {
                    if (c.searchStatus == SearchStatus.searching) {
                      return SearchUtil.buildSearchingView();
                    } else if (c.searchStatus == SearchStatus.fail) {
                      return SearchUtil.buildRetryView(() {
                        c.reSearch();
                      });
                    } else {
                      return _buildEmptyView(c.searched);
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
                    // header: const RefreshHeader(),
                    footer: CustomFooter(
                      height: 58,
                      builder: (context, mode) {
                        return footBuilder(
                          context,
                          mode,
                          requestType: requestType,
                          showDivider: false,
                          showIdleWidget: false,
                        );
                      },
                    ),
                    child: _buildList(context, c),
                  );
                  return smartRefresher;
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyView(bool searched) {
    return Column(
      children: [
        const SizedBox(height: 220),
        Image.asset(
          searched
              ? 'assets/images/search_empty.png'
              : "assets/images/search.png",
          width: 56,
        ),
        const SizedBox(height: 16),
        Text(
          searched ? '暂无动态'.tr : '搜索圈子动态'.tr,
          style: appThemeData.textTheme.caption.copyWith(fontSize: 14),
        ),
      ],
    );
  }

  ///搜索结果列表
  Widget _buildList(BuildContext context, CircleSearchController c) {
    final cacheExtent = MediaQuery.of(context).size.height *
        MediaQuery.of(context).devicePixelRatio;

    final widget = CustomScrollView(
      controller: searchController.scrollController,
      key: PageStorageKey(channelId + c.pageKey.toString()),
      cacheExtent: cacheExtent,
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(5),
          sliver: SliverMasonryGrid.count(
            crossAxisCount: 2,
            childCount: c.resultList.length,
            itemBuilder: (context, index) {
              final model = c.resultList[index];
              final postId = model?.postInfoDataModel?.postId ?? "";
              final key = postId.isEmpty ? UniqueKey() : Key(postId);
              return GestureDetector(
                onTap: () {
                  _searchInputModel.inputFocusNode.unfocus();

                  ///跳转到详情页
                  CircleDetailRouter.push(CircleDetailData(
                    model,
                    extraData: ExtraData(extraType: ExtraType.fromSearch),
                  )).then((value) {
                    c.update();
                  });

                  DLogManager.getInstance().extensionEvent(
                      logType: "dlog_app_user_search_fb",
                      extJson: {
                        "guild_id": guildId ?? '',
                        "opt_type": "search_jump_into",
                        "opt_source": "1",
                        "opt_sub_source": channelId ?? '',
                        "opt_content": c?.searchKeyValue ?? '',
                      });
                },
                child: CircleTopicStaggeredItem(
                  model,
                  key: key,
                  searchKey: c.searchKeyValue,
                ),
              );
            },
            mainAxisSpacing: 5,
            crossAxisSpacing: 5,
          ),
        ),
      ],
    );
    return widget;
  }

  ///输入栏
  Widget _buildSearchBar(BuildContext context) {
    final widget = Container(
      color: Colors.white,
      padding: const EdgeInsets.only(left: 12, top: 6, bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 36,
              child: SearchInputBox(
                borderRadius: 4,
                searchInputModel: _searchInputModel,
                inputController: _searchInputController,
                height: 36,
                hintText: '搜索圈子动态'.tr,
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
    return widget;
  }
}
