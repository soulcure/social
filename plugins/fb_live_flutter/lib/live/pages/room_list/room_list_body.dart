import 'package:fb_live_flutter/live/api/fblive_provider.dart';
import 'package:fb_live_flutter/live/bloc/room_list_bloc.dart';
import 'package:fb_live_flutter/live/model/room_list_model.dart';
import 'package:fb_live_flutter/live/pages/room_list/widget/room_list_grid.dart';
import 'package:fb_live_flutter/live/pages/room_list/widget/roomlist_nodata_widget.dart';
import 'package:fb_live_flutter/live/utils/ui/frame_size.dart';
import 'package:fb_live_flutter/live/utils/ui/listview_custom_view.dart';
import 'package:fb_live_flutter/live/widget_common/flutter/click_event.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

class RoomListBody extends StatefulWidget {
  final int? index;
  final bool? fbCanStartLive;

  const RoomListBody({this.index, this.fbCanStartLive});

  @override
  _RoomListBodyState createState() => _RoomListBodyState();
}

class _RoomListBodyState extends State<RoomListBody>
    with AutomaticKeepAliveClientMixin {
  final RoomListBloc _bloc = RoomListBloc();

  @override
  void initState() {
    super.initState();

    /// bloc初始化方法
    _bloc.init(this);
  }

  /*
  * item操作之后的响应
  * 
  * RoomListModel为数据模型，int为操作类型
  * */
  void onActionHandle(RoomListModel model, int type) {
    // 删除操作
    if (type == 1) {
      _bloc.roomList.remove(model);
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    /// 给bloc设置上下文
    _bloc.contextValue = context;

    return BlocBuilder(
      bloc: _bloc,
      builder: (_, __) {
        if (!_bloc.isRefresh) {
          return Container();
        }
        return kIsWeb
            ? Column(
                children: [_liveListView(context)],
              )
            : _liveListView(context);
      },
    );
  }

  ///直播列表
  Widget _liveListView(BuildContext context) {
    if (kIsWeb) {
      return _bloc.roomList.isEmpty
          ? RoomListNoDataView(fbCanStartLive: widget.fbCanStartLive)
          : Padding(
              padding: kIsWeb && fbApi.canStartLive()
                  ? EdgeInsets.only(
                      left: 24.px, right: 24.px, bottom: 24.px, top: 15.px)
                  : EdgeInsets.all(24.px),
              child: CustomScrollView(shrinkWrap: true, slivers: [
                RoomListGrid(_bloc.roomList, (e) {
                  return _getListData(context, e);
                }, isSliver: true),
                SliverToBoxAdapter(
                  child: (_bloc.roomList.isEmpty ||
                          (_bloc.roomList.length) < _bloc.pageSize)
                      ? Container()
                      : GestureDetector(
                          onTap: _bloc.onLoadingData,
                          child: Container(
                            height: 120,
                            color: Colors.green,
                            padding: const EdgeInsets.fromLTRB(35, 12, 35, 12),
                            alignment: Alignment.bottomCenter,
                            child: const Text(
                              "点击加载更多",
                              style: TextStyle(
                                  color: Color(0xFF6379F1),
                                  height: 1,
                                  fontSize: 16),
                            ),
                          ),
                        ),
                ),
              ]),
            );
    } else {
      return SmartRefresher(
        enablePullUp: true,
        header: WaterDropHeader(
          complete: _headerViewStatus(refreshStatus: true),
          failed: _headerViewStatus(refreshStatus: false),
        ),
        footer: const CustomFooterView(),
        controller: _bloc.refreshController,
        onRefresh: _bloc.onRefreshData,
        onLoading: _bloc.onLoadingData,
        child: _bloc.roomList.isEmpty
            ? RoomListNoDataView(fbCanStartLive: widget.fbCanStartLive)
            : kIsWeb
                ? RoomListGrid(
                    _bloc.roomList,
                    (index) {
                      return _getListData(context, index);
                    },
                    physics: const NeverScrollableScrollPhysics(),
                  )
                : Wrap(
                    spacing: 4.px,
                    runSpacing: 4.px,
                    children: List.generate(_bloc.roomList.length, (index) {
                      return Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                        ),
                        margin: EdgeInsets.only(
                            left: index.isEven ? 4.px : 0,
                            right: index.isOdd ? 4.px : 0),
                        width: ((FrameSize.winWidth() - 12.px) / 2) - 0.5,
                        child: _getListData(context, _bloc.roomList[index]),
                      );
                    }),
                  ),
      );
    }
  }

  ///直播列表item
  Widget _getListData(context, RoomListModel item) {
    return ClickEvent(
      onTap: () async {
        return _bloc.action(item);
      },

      ///直播列表
      child: RoomListCard(
        item: item,
        isUserHome: item.openType == 3,
        onAction: onActionHandle,
      ),
    );
  }

  //app 下拉刷新列表header
  Widget _headerViewStatus({required bool refreshStatus}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        if (refreshStatus)
          const Icon(Icons.done, color: Colors.grey)
        else
          const Icon(Icons.clear, color: Colors.grey),
        Container(width: 15),
        Text(
          refreshStatus ? "刷新成功" : "刷新失败",
          style: const TextStyle(color: Colors.grey),
        )
      ], /**/
    );
  }

  @override
  void dispose() {
    super.dispose();
    _bloc.close();
  }

  @override
  bool get wantKeepAlive => true;
}
