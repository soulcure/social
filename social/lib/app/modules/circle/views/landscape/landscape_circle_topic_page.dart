import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/app/modules/circle/controllers/circle_controller.dart';
import 'package:im/app/modules/circle/controllers/circle_topic_controller.dart';
import 'package:im/common/extension/string_extension.dart';
import 'package:im/pages/guild_setting/circle/circle_detail_page/circle_page.dart';
import 'package:im/pages/guild_setting/circle/circle_topic_item/circle_topic_item_web.dart';
import 'package:im/routes.dart';
import 'package:im/svg_icons.dart';
import 'package:im/widgets/refresh/net_checker.dart';
import 'package:im/widgets/svg_tip_widget.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

class LandscapeCircleTopicPage extends StatefulWidget {
  final String topicId;
  final int showType;

  const LandscapeCircleTopicPage({Key key, this.topicId, this.showType = 0})
      : super(key: key);

  @override
  _LandscapeCircleTopicPageState createState() =>
      _LandscapeCircleTopicPageState();
}

class _LandscapeCircleTopicPageState extends State<LandscapeCircleTopicPage>
    with AutomaticKeepAliveClientMixin {
  CircleController get circleController => GetInstance().find();
  CircleTopicController controller;

  String get tagId => widget.topicId.hasValue ? widget.topicId : '_all';

  /// 滑动到底部，自动加载更多
  final ScrollController _scrollController = ScrollController();
  double curOff = 0;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    controller = CircleTopicController.to(topicId: tagId);
    _scrollController.addListener(_scrollOffsetChange);
    super.initState();
  }

  void _scrollOffsetChange() {
    if (curOff == _scrollController.offset) return;
    curOff = _scrollController.offset;
    if (_scrollController.offset ==
            _scrollController.position.maxScrollExtent &&
        !controller.refreshController.isLoading &&
        controller.hasNext == '1') {
      controller.refreshController.requestLoading();
    }
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_scrollOffsetChange)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return GestureDetector(
      onTap: () {},
      onHorizontalDragStart: (_) {},
      behavior: HitTestBehavior.translucent,
      child: GetBuilder<CircleTopicController>(
          tag: tagId,
          builder: (c) {
            return NetChecker(
              futureGenerator: () =>
                  controller.loadData().timeout(const Duration(seconds: 15)),
              retry: () {
                setState(() {});
              },
              builder: (v) {
                if (c.list.isNotEmpty)
                  return _buildPostListView();
                else
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 80),
                      child: SvgTipWidget(
                        svgName: SvgIcons.svgCircleNoneDynamic,
                        text: '快来抢发第一条动态'.tr,
                        textSize: 14,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  );
              },
            );
          }),
    );
  }

  Widget _buildPostListView() {
    final cacheExtent = MediaQuery.of(context).size.height *
        MediaQuery.of(context).devicePixelRatio;
    return SmartRefresher(
      controller: controller.refreshController,
      enablePullUp: true,
      enablePullDown: false,
      onLoading: controller.loadMoreData,
      child: ListView.builder(
        key: PageStorageKey(widget.topicId),
        controller: _scrollController,
        cacheExtent: cacheExtent,
        clipBehavior: Clip.none,
        itemCount: controller.list.length,
        itemBuilder: (context, index) => _buildTopicItem(index),
      ),
    );
  }

  Widget _buildTopicItem(int index) {
    final model = controller.list[index];
    final postId = model?.postInfoDataModel?.postId ?? "";
    final key = postId.isEmpty ? UniqueKey() : Key(postId);

    /// TODO: gesture 后面想移动到item内部
    return GestureDetector(
        onTap: () {
          Routes.pushCirclePage(context,
                  model: model,
                  extraData: ExtraData(extraType: ExtraType.fromCircleList),
                  // circleOwnerId: circleController.circleInfoDataModel.ownerId,
                  modifyCallBack: (info) {
            controller.loadData(reload: true);
          }) /*.then((value) {
            if (value ?? false) {
              controller.loadData(reload: true);
            }
          })*/
              ;
        },
        child: Column(
          children: [
            CircleTopicItem(
              model,
              key: key,
              onItemDeleteCallBack: (dataModel) {
                controller.removeItem(dataModel.postId);
              },
              onRefreshCallBack: () {
                controller.loadData(reload: true);
              },
              onItemModifyCallBack: (topicIds) {
                controller.loadData(reload: true);
              },
            ),
            if (index + 1 < controller.list.length) const SizedBox(height: 6)
          ],
        ));
  }
}
