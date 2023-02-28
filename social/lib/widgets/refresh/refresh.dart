import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/utils/orientation_util.dart';
import 'package:im/widgets/refresh/list_model.dart';
import 'package:im/widgets/refresh/net_checker.dart';
import 'package:im/widgets/refresh/refresh_header.dart';
import 'package:provider/provider.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

import '../../loggers.dart';

typedef WidgetBuilder = Widget Function(BuildContext context);

/// 刷新器，实现刷新效果，无网络提示效果
class Refresher extends StatefulWidget {
  /// 子对象
//  final Widget child;
  final WidgetBuilder builder;

  /// 实现ListModel的model类
  final ListModel model;

  /// 是否启用网络检查
  final bool enableNetChecker;

  /// 是否启用刷新功能
  final bool enableRefresh;

  final Axis scrollDirection;

  /// 首次开始加载时触发，可以获得 Future 实例
  /// 如果有数据依赖于初始数据，需要用到它
  final Function(Future) onStartFetchData;

  final ScrollController scrollController;

  const Refresher({
    Key key,
    @required this.builder,
    @required this.model,
    this.enableNetChecker = true,
    this.enableRefresh = true,
    this.onStartFetchData,
    this.scrollDirection = Axis.vertical,
    this.scrollController,
  }) : super(key: key);

  @override
  _RefresherState createState() => _RefresherState();
}

class _RefresherState extends State<Refresher> {
  ///刷新控制器
  RefreshController _controller;

  @override
  void initState() {
    _controller = RefreshController();
    if (widget.onStartFetchData != null)
      widget.onStartFetchData(widget.model.fetchData());
    if (widget.scrollController != null && OrientationUtil.landscape) {
      widget.scrollController.addListener(_onScroll);
    }
    super.initState();
  }

  void _onScroll() {
    if (widget.scrollController.offset ==
            widget.scrollController.position.maxScrollExtent &&
        !_controller.isLoading &&
        _controller.footerStatus != LoadStatus.noMore) {
      _controller.requestLoading();
    }
  }

  @override
  void dispose() {
    if (widget.scrollController != null && OrientationUtil.landscape) {
      widget.scrollController.removeListener(_onScroll);
    }
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
        value: widget.model,
        child: Consumer<ListModel>(builder: (context, model, w) {
          Widget child;
          if (widget.enableNetChecker) {
            child = NetChecker(
              futureGenerator: widget.model.fetchData,
              retry: () {
                setState(() {});
              },
              builder: (res) {
                widget.model.list = res;
                return _buildSmartRefresher(context);
              },
            );
          } else {
            child = _buildSmartRefresher(context);
          }
          return child;
        }));
  }

  SmartRefresher _buildSmartRefresher(BuildContext context) {
    return SmartRefresher(
      scrollDirection: widget.scrollDirection,
      enablePullDown: widget.enableRefresh,
      enablePullUp: true,
      controller: _controller,
      onRefresh: _onRefresh,
      onLoading: _onLoadMore,
      header: const RefreshHeader(),
      footer: ClassicFooter(
        idleText: OrientationUtil.portrait ? '上拉加载更多'.tr : '滑动到底部加载更多'.tr,
        loadingText: '加载中'.tr,
        canLoadingText: '上拉加载更多'.tr,
        failedText: '加载失败'.tr,
        noDataText: '没有更多了'.tr,
      ),
      child: widget.builder(context),
    );
  }

  Future _onRefresh() async {
    widget.model.clear();
    await widget.model.getNextPage();
    _controller.refreshCompleted();
    _controller.resetNoData();
  }

  Future _onLoadMore() async {
    try {
      final numNew = await widget.model.getNextPage();
      if (numNew < widget.model.pageSize) {
        _controller.loadNoData();
      } else {
        _controller.loadComplete();
      }
    } catch (e) {
      logger.severe(e);
      _controller.loadFailed();
    }
  }
}
