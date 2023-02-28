import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:get/get.dart';
import 'package:get/get_rx/src/rx_workers/utils/debouncer.dart';
import 'package:im/app/modules/circle/controllers/circle_controller.dart';
import 'package:im/app/modules/circle/controllers/circle_topic_controller.dart';
import 'package:im/app/modules/circle/models/circle_post_data_type.dart';
import 'package:im/app/modules/circle/models/circle_topic_data_model.dart';
import 'package:im/app/modules/circle/route/open_container_transition.dart';
import 'package:im/app/modules/circle/views/portrait/widgets/circle_loading_fake_item.dart';
import 'package:im/app/modules/circle/views/portrait/widgets/circle_pined_item.dart';
import 'package:im/app/modules/circle/views/portrait/widgets/circle_topic_staggered_item.dart';
import 'package:im/app/modules/circle/views/widgets/loading_indicator.dart';
import 'package:im/app/modules/circle_detail/circle_detail_router.dart';
import 'package:im/app/modules/circle_detail/controllers/circle_detail_controller.dart';
import 'package:im/app/modules/circle_detail/views/circle_detail_view.dart';
import 'package:im/app/modules/circle_video_page/controllers/circle_video_page_controller.dart';
import 'package:im/app/modules/circle_video_page/views/circle_video_view.dart';
import 'package:im/app/routes/app_pages.dart';
import 'package:im/app/theme/app_theme.dart';
import 'package:im/core/http_middleware/http.dart';
import 'package:im/core/widgets/button/fade_button.dart';
import 'package:im/pages/guild_setting/circle/circle_detail_page/circle_page.dart';
import 'package:im/svg_icons.dart';
import 'package:im/widgets/svg_tip_widget.dart';
import 'package:oktoast/oktoast.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

class PortraitCircleTopicPage extends StatefulWidget {
  final String topicId;

  ///话题类型
  final CircleTopicType type;

  const PortraitCircleTopicPage({Key key, this.topicId, this.type})
      : super(key: key);

  @override
  _PortraitCircleTopicPageState createState() =>
      _PortraitCircleTopicPageState();
}

class _PortraitCircleTopicPageState extends State<PortraitCircleTopicPage>
    with AutomaticKeepAliveClientMixin {
  CircleController get circleController => GetInstance().find();
  CircleTopicController controller;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    controller = CircleTopicController.to(topicId: widget.topicId);
    controller.loadCached();
    controller.loadData();
    super.initState();
  }

  bool retry = false;

  final debounce = Debouncer(delay: const Duration(milliseconds: 100));

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return GetBuilder<CircleTopicController>(
      tag: widget.topicId,
      builder: (controller) {
        if (controller.loadFinish) {
          // 加载完成
          final hasPost = controller.list.isNotEmpty;
          return NotificationListener<UserScrollNotification>(
            onNotification: (notification) {
              debounce(() =>
                  circleController.switchFloatButton(notification.direction));
              return true;
            },
            child: RefreshConfiguration(
              footerTriggerDistance: Get.height / 2,
              hideFooterWhenNotFull: true,
              child: SmartRefresher(
                controller: controller.refreshController,
                enablePullUp: hasPost,
                onRefresh: () => controller.loadData(reload: true),
                onLoading: controller.loadMoreData,
                header: CircleHeadLoadIndicator(),
                footer: CircleFootLoadIndicator(
                  noMore: controller.hasNext == '0',
                  footHeight: 60 + Get.mediaQuery.padding.bottom,
                ),
                child: hasPost ? _buildPostListView() : _buildEmptyView(),
              ),
            ),
          );
        } else if (controller.loadFailed) {
          //加载失败
          if (retry) showToast(networkErrorText);
          return _buildErrorWidget();
        } else {
          //加载中
          return const CircleLoadingGrid();
        }
      },
    );
  }

  Widget _buildPostListView() {
    ///只在“最新”分类下显示置顶的特殊Item
    final showPined = circleController.pinedList.isNotEmpty &&
        circleController.pinedList[0].post != null &&
        widget.type == CircleTopicType.all;
    return MasonryGridView.count(
      key: PageStorageKey(widget.topicId),
      mainAxisSpacing: 5,
      crossAxisSpacing: 5,
      padding: const EdgeInsets.all(5),
      crossAxisCount: 2,
      itemCount: controller.list.length + (showPined ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == 0 && showPined)
          return CirclePinedItem(circleController.pinedList);
        else
          return _buildTopicItem(index - (showPined ? 1 : 0));
      },
    );
  }

  Widget _buildEmptyView() {
    final subscription = widget.topicId == "1";
    return LayoutBuilder(
      builder: (context, constrains) {
        return Column(
          children: [
            SizedBox(
                height: (Get.height - Get.mediaQuery.padding.top - 88) / 4),
            Image.asset(
              "assets/images/post_list_empty.png",
              width: 140,
            ),
            const SizedBox(height: 16),
            Text(
              subscription ? '暂无订阅内容'.tr : '开始你的第一个笔记～'.tr,
              style: appThemeData.textTheme.bodyText2.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              subscription
                  ? '自己发布的和订阅的内容都汇聚\n在这里，方便实时查看'
                  : '这里空空如也，快去发布动态\n遇见更多有趣的人吧',
              style: appThemeData.textTheme.headline2
                  .copyWith(fontSize: 14, height: 1.25),
              textAlign: TextAlign.center,
            ),
          ],
        );
      },
    );
  }

  Widget _buildTopicItem(int index) {
    final model = controller.list[index];
    final postId = model?.postInfoDataModel?.postId ?? "";
    final key = postId.isEmpty ? UniqueKey() : Key(postId);
    if (model.postInfoDataModel.postType == CirclePostDataType.video &&
        model.postInfoDataModel.firstMedia.isNotEmpty)
      return OpenContainerTransition<CircleVideoPageController>(
        controller: () => CircleVideoPageController(
          CircleVideoPageControllerParam(
            model: model,
            topicId: controller.topicId,
            circlePostDateModels: controller.list,
          ),
        ),
        outSideWidget: CircleTopicStaggeredItem(
          model,
          key: key,
        ),
        openWidget: const CircleVideoView(),
        routeSettings: const RouteSettings(
          name: Routes.CIRCLE_VIDEO_PAGE,
        ),
      );
    else {
      final paramData = CircleDetailData(
        model,
        extraData: ExtraData(extraType: ExtraType.fromCircleList),
        circlePostDataModels: controller.list,
        circleListTopicId: controller.topicId,
        modifyCallBack: (info) {
          controller.loadData(reload: true);
        },
      );
      final routeSettings =
          RouteSettings(name: Routes.CIRCLE_DETAIL, arguments: paramData);
      return OpenContainerTransition<CircleDetailController>(
        tag: model.postId,
        controller: () => CircleDetailController(paramData),
        preAction: () =>
            CircleDetailRouter.findAndRemoveExistingDetailPage(model.postId),
        outSideWidget: CircleTopicStaggeredItem(
          model,
          key: key,
        ),
        openWidget: CircleDetailView(paramData: paramData),
        routeSettings: routeSettings,
      );
    }
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 40),
            child: SvgTipWidget(
              svgName: SvgIcons.noNetState,
              desc: '加载失败，请重试'.tr,
            ),
          ),
          FadeButton(
            onTap: () {
              controller.loadData();
              retry = true;
            },
            decoration: BoxDecoration(
              color: appThemeData.primaryColor,
              borderRadius: BorderRadius.circular(5),
            ),
            width: 180,
            height: 36,
            child: Text(
              '重新加载'.tr,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}

class CircleLoadingGrid extends StatefulWidget {
  const CircleLoadingGrid({Key key}) : super(key: key);

  @override
  State<CircleLoadingGrid> createState() => _CircleLoadingGridState();
}

class _CircleLoadingGridState extends State<CircleLoadingGrid>
    with SingleTickerProviderStateMixin {
  Animation<double> animation;
  AnimationController controller;

  @override
  void initState() {
    controller =
        AnimationController(duration: const Duration(seconds: 1), vsync: this);
    animation = Tween<double>(begin: 1, end: .6).animate(controller);
    controller.repeat(reverse: true);
    super.initState();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: Get.height - Get.mediaQuery.padding.top - 88,
      child: FittedBox(
        fit: BoxFit.fitWidth,
        alignment: Alignment.topCenter,
        child: AnimatedBuilder(
          animation: animation,
          builder: (context, child) => Opacity(
            opacity: animation.value,
            child: Column(
              children: List.generate(4, (_) => _row()),
            ),
          ),
        ),
      ),
    );
  }

  Widget _row() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(5, 5, 5, 0),
      child: Row(
        children: const [
          CircleLoadingFakeItem(),
          SizedBox(width: 5),
          CircleLoadingFakeItem(),
        ],
      ),
    );
  }
}
