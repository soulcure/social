import 'package:fb_live_flutter/live/api/fblive_provider.dart';
import 'package:fb_live_flutter/live/pages/room_list/room_list_body.dart';
import 'package:fb_live_flutter/live/pages/room_list/widget/create_room_button.dart';
import 'package:fb_live_flutter/live/utils/ui/window_util.dart';
import 'package:fb_live_flutter/live/widget_common/flutter/tab_indicator.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'package:im/icon_font.dart';
import '../../net/api.dart';
import '../../utils/manager/event_bus_manager.dart';
import '../../utils/ui/frame_size.dart';
import '../../utils/ui/nil.dart';
import 'widget/actions_btn_widegt.dart';

class RoomList extends StatefulWidget {
  final String? title;
  final GestureTapCallback? backAction;

  const RoomList({this.title, this.backAction});

  @override
  _RoomListState createState() => _RoomListState();
}

class _RoomListState extends State<RoomList>
    with
        TickerProviderStateMixin,
        WidgetsBindingObserver,
        AutomaticKeepAliveClientMixin {
  TabController? tabController;
  List tabs = ['直播', '我的'];
  bool fbCanStartLive = false;
  String? _nickName;
  bool isFirstEnter = true;

  @override
  void dispose() {
    super.dispose();
    EventBusManager.destroy();
    WidgetsBinding.instance!.removeObserver(this);
  }

  @override
  void initState() {
    super.initState();
    saveUserInfo();
    fbApiCanStartLive();
    tabController = TabController(length: tabs.length, vsync: this);
    if (isFirstEnter) {
      navigatorCreateRoom(context, isToPage: false);
      isFirstEnter = false;
    }
    WidgetsBinding.instance!.addObserver(this);
  }

  ///切换到前后台
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      WindowUtil.setStatusTextColorBlack();
    }
  }

  //上报用户信息
  void saveUserInfo() {
    final String? userId = fbApi.getUserId();
    fbApi
        .getUserInfo(userId!, guildId: fbApi.getCurrentChannel()!.guildId)
        .then((value) {
      _nickName = value.nickname;
      Api.postUserInfo(_nickName, value.avatar, userId, value.shortId);
    });
  }

  // FBAPI--是否有开播权限
  void fbApiCanStartLive() {
    fbCanStartLive = fbApi.canStartLive();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    WindowUtil.setStatusTextColorBlack();
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      width: FrameSize.winWidth(),
      child: Column(
        children: [
          if (!kIsWeb)
            _getAppBar(context)
          else if (kIsWeb && fbApi.canStartLive())
            _getWebAppBar(context),
          SizedBox(height: kIsWeb ? 0 : FrameSize.px(12)),
          Expanded(
            child: tabBarViewWidget(context),
          ),
        ],
      ),
    );
  }

  ///移动端appBar背景
  Widget _getAppBar(context) {
    return Container(
      width: FrameSize.winWidth(),
      height: FrameSize.px(44),
      padding: const EdgeInsets.only(left: 12, right: 12),
      color: Colors.white,
      child: tabBarView(context),
    );
  }

  ///Web端appBar背景
  Widget _getWebAppBar(context) {
    return Container(
      height: 48.px,
      padding: EdgeInsets.symmetric(horizontal: 24.px),
      child: tabBarView(context),
    );
  }

  ///Web端、移动端appBar样式判断
  Widget tabBarView(BuildContext context) {
    return Row(
      children: [
        if (kIsWeb)
          const Nil()
        else
          InkWell(
            onTap: widget.backAction ?? () => Navigator.pop(context),
            child: Icon(
              IconFont.buffNavBarBackChannelItem,
              size: 24,
            ),
          ),
        Expanded(
            child: Center(
          child: tabBarWidget(),
        )),
        ActionsBtn(fbCanStartLive: fbCanStartLive),
      ],
    );
  }

  ///TabBar
  Widget tabBarWidget() {
    return fbCanStartLive
        ? TabBar(
            controller: tabController,
            isScrollable: true,
            indicatorSize: TabBarIndicatorSize.label,
            indicatorColor: const Color(0xff6179F2),
            indicator: const MyTabIndicator(),
            unselectedLabelStyle: TextStyle(
              fontSize: FrameSize.px(17),
            ),
            labelColor: const Color(0xff1F2125),
            unselectedLabelColor: const Color(0xff1F2125).withOpacity(0.5),
            labelStyle: TextStyle(
              fontSize: FrameSize.px(17),
              fontWeight: FontWeight.w600,
            ),
            indicatorPadding: const EdgeInsets.only(bottom: kIsWeb ? 8 : 0),
            labelPadding:
                const EdgeInsets.symmetric(vertical: 10, horizontal: 25),
            tabs: List.generate(tabs.length, (index) {
              return Tab(
                child: Text(tabs[index], softWrap: false),
              );
            }))
        : Container(
            alignment: Alignment.centerLeft,
            height: FrameSize.padTopH() + FrameSize.px(44),
            padding: const EdgeInsets.only(left: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(height: 1),
                Text(
                  tabs[0],
                  style: TextStyle(
                    fontSize: FrameSize.px(15),
                    color: const Color(0xff6179f2),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Container(
                  color: const Color(0xff6179F2),
                  height: FrameSize.px(2),
                  width: FrameSize.px(30),
                ),
              ],
            ),
          );
  }

  ///TabBarView
  Widget tabBarViewWidget(BuildContext context) {
    final _roomListWidget = fbCanStartLive
        ? TabBarView(
            controller: tabController,
            children: [
              //直播列表-直播
              RoomListBody(
                index: 0,
                fbCanStartLive: fbCanStartLive,
              ),
              //我发起的
              RoomListBody(
                index: 1,
                fbCanStartLive: fbCanStartLive,
              ),
            ],
          ) //只直播列表
        : RoomListBody(
            index: 0,
            fbCanStartLive: fbCanStartLive,
          );
    const _edgeScrollArea = SizedBox(
      width: 24,
      height: double.infinity,
      child: DecoratedBox(decoration: BoxDecoration(color: Colors.transparent)),
    );
    return Stack(
      children: [
        _roomListWidget,
        _edgeScrollArea,
      ],
    );
  }

  @override
  bool get wantKeepAlive => true;
}
