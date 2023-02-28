import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:fb_live_flutter/live/api/fblive_provider.dart';
import 'package:fb_live_flutter/live/event_bus_model/room_list_model.dart';
import 'package:fb_live_flutter/live/net/api.dart';
import 'package:fb_live_flutter/live/pages/playback/playback_page.dart';
import 'package:fb_live_flutter/live/pages/room_list/widget/roomlist_nodata_widget.dart';
import 'package:fb_live_flutter/live/pages/room_list/widget/web_playback_generation_page.dart';
import 'package:fb_live_flutter/live/utils/func/router.dart';
import 'package:fb_live_flutter/live/utils/func/utils_class.dart';
import 'package:fb_live_flutter/live/utils/theme/my_theme.dart';
import 'package:fb_live_flutter/live/utils/theme/my_toast.dart';
import 'package:fb_live_flutter/live/utils/ui/listview_custom_view.dart';
import 'package:fb_live_flutter/live/utils/ui/ui.dart';
import 'package:fb_live_flutter/live/widget_common/flutter/bottom_sheet_drag.dart';
import 'package:fb_live_flutter/live/widget_common/flutter/click_event.dart';
import 'package:fb_live_flutter/live/widget_common/image/sw_image.dart';
import 'package:fb_live_flutter/live/widget_common/logo/sw_logo.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get/get_rx/src/rx_types/rx_types.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

import '../../model/room_list_model.dart';
import '../../utils/ui/frame_size.dart';
import 'widget/room_list_grid.dart';

///用户个人主页、用户回放专辑(移动端)
class UserHomePage extends StatefulWidget {
  final RoomListModel? item;
  final bool isDownClose; //下拉关闭
  final double? height;
  final String? anchorId;
  final bool isHorizontal;
  final VoidCallback? onTap;
  final bool isSmartDialog;
  final bool isReplace;
  final bool? isAnchor;
  final bool isFromList;

  const UserHomePage({
    this.item,
    this.isDownClose = false,
    this.height,
    this.isSmartDialog = false,
    this.isAnchor = false,
    required this.anchorId,
    this.onTap,
    this.isHorizontal = false,
    this.isReplace = false,
    this.isFromList = false,
  });

  @override
  _UserHomePageState createState() => _UserHomePageState();
}

class _UserHomePageState extends State<UserHomePage> {
  List<RoomListModel> _roomList = [];

  int pageNum = 1;

  bool isLoadOk = false;
  final RefreshController _refreshController = RefreshController();

  Rx<LoadStatus>? footerMode = LoadStatus.canLoading.obs;

  StreamSubscription? _roomListEventBus;

  @override
  void initState() {
    super.initState();
    _getAlbumListFunc();
    _roomListEventBus = roomListEventBus.on().listen((event) {
      pageNum = 1;
      _getAlbumListFunc();
    });

    Future.delayed(const Duration(milliseconds: 200)).then((value) {
      // 本对话框不允许横屏打开
      if (FrameSize.isHorizontal()) {
        Get.back();
      }
    });
  }

  String? get getAnchorId {
    return widget.anchorId ?? widget.item?.anchorId;
  }

  Future _getAlbumListFunc() async {
    try {
      footerMode?.value = LoadStatus.loading;

      if (!strNoEmpty(getAnchorId)) {
        myFailToast('用户异常');
        loadFailedState();
        return;
      }
      if (pageNum == 1) {
        _roomList = [];
      }
      Map? resData;
      try {
        resData = await Api.playbackList(pageNum, getAnchorId);
      } catch (e) {
        loadFailedState();
        return;
      }
      if (resData!['code'] != 200) {
        loadFailedState();
        return;
      }
      final List? dataList = resData["data"]["result"];
      if (!listNoEmpty(dataList)) {
        _refreshController.loadNoData();
        footerMode?.value = LoadStatus.noMore;
        if (!isLoadOk) {
          isLoadOk = true;
          if (mounted) setState(() {});
        }
        return;
      }
      dataList!.forEach((element) {
        final RoomListModel roomListModel =
            RoomListModel.fromJson(element, openTypeContent: 4);
        _roomList.add(roomListModel);
      });
      isLoadOk = true;
      if (dataList.length >= 10) {
        _refreshController.loadComplete();
        footerMode?.value = LoadStatus.idle;
      } else {
        _refreshController.loadNoData();
        footerMode?.value = LoadStatus.noMore;
      }

      if (mounted) setState(() {});
    } catch (e) {
      fbApi.fbLogger.info("加载列表数据出现错误:${e.toString()}");
      loadFailedState();
    }
  }

  /*
  * 加载失败
  * */
  void loadFailedState() {
    /// 这里不存在下拉刷新，所以只有load状态变更
    _refreshController.loadFailed();
    footerMode?.value = LoadStatus.failed;

    if (mounted) setState(() {});
  }

  double get height {
    return widget.height ?? FrameSize.winHeight() * 0.90;
  }

  //上拉
  Future _onLoading() async {
    pageNum++;
    await _getAlbumListFunc();
  }

  /*
  * item操作之后的响应
  *
  * RoomListModel为数据模型，int为操作类型
  * */
  void onActionHandle(RoomListModel model, int type) {
    // 删除操作
    if (type == 1) {
      _roomList.remove(model);
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final Widget body = SmartRefresher(
      enablePullUp: true,
      enablePullDown: false,
      footer: widget.isFromList
          ? CustomFooter(
              builder: (context, mode) {
                return Container();
              },
            )
          : const CustomFooterView(),
      controller: _refreshController,
      onLoading: _onLoading,
      child: ListView(
        physics: const ClampingScrollPhysics(),
        children: [
          fbApi.userInfoComponent(
              context, widget.anchorId ?? widget.item!.anchorId!,
              guildId:
                  widget.item?.serverId ?? fbApi.getCurrentChannel()!.guildId),
          if (isLoadOk && !listNoEmpty(_roomList))
            const RoomListNoDataView(
              fbCanStartLive: false,
              text: '暂无内容',
              isSpace: false,
            )
          else
            RoomListGrid(
              _roomList,
              (index) {
                return ClickEvent(
                  onTap: () async {
                    await toPage(index);
                  },
                  child: RoomListCard(
                    item: index,
                    isUserHome: index.openType == 3,
                    onAction: onActionHandle,
                  ),
                );
              },
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
            ),
          if (widget.isFromList)
            Obx(
              () {
                return CustomFooterView(
                    loadStatus: footerMode?.value ?? LoadStatus.canLoading);
              },
            ),
        ],
      ),
    );

    if (!widget.isDownClose) return body;

    ///[BottomSheetDrag]底部弹出框下拉关闭
    return BottomSheetDrag(
      height: height,
      isSmartDialog: widget.isSmartDialog,
      child: Container(
        width: FrameSize.winWidth(),
        height: height,
        padding: EdgeInsets.only(
            top: FrameSize.px(20), bottom: widget.isFromList ? 30.px : 0),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
        ),
        child: body,
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
    _roomListEventBus?.cancel();
    _roomListEventBus = null;
  }

  Future toPage(RoomListModel index) async {
    if (widget.isHorizontal) {
      RouteUtil.pop();
      //强制竖屏
      await SystemChrome.setPreferredOrientations(
          [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
    } else {
      RouteUtil.pop();
    }
    final RoomListModel _model = index;
    if (!strNoEmpty(_model.okNickName)) {
      _model.okNickName = widget.item?.okNickName;
    }
    if (!strNoEmpty(_model.avatarUrl)) {
      _model.avatarUrl = widget.item?.avatarUrl;
    }
    if (!strNoEmpty(_model.serverId)) {
      _model.serverId = widget.isFromList
          ? fbApi.getCurrentChannel()!.guildId
          : widget.item?.serverId;
    }
    if (_model.watchNum == 0 || _model.watchNum == null) {
      _model.watchNum = index.watchNum ?? widget.item?.watchNum;
    }
    await Future.delayed(const Duration(milliseconds: 100));

    await RouteUtil.push(
        context,
        PlaybackPage(
          _model,
          isFromLive: widget.isSmartDialog || widget.isHorizontal,
          isNeedWakelock: widget.isFromList,
        ),
        'PlaybackPage',
        isReplace: widget.isReplace);
    if (widget.isHorizontal) {
      widget.onTap!();
    }
  }
}

///用户主页、用户回放专辑（Web端）
class WebUserHomePage extends StatelessWidget {
  final RoomListModel? item;

  const WebUserHomePage({this.item});

  @override
  Widget build(BuildContext context) {
    const String _copyText = '#256674';
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.px, vertical: 24.px),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '回放列表',
                style: TextStyle(
                  fontSize: 20.px,
                  color: const Color(0xff1F2125),
                ),
              ),
              SwImage('assets/live/main/close.png', width: 20.px, height: 20.px,
                  onTap: () async {
                RouteUtil.pop();
              }),
            ],
          ),
        ),
        const HorizontalLine(height: 1, color: Color(0xffF0F1F2)),
        Expanded(
            child: ListView(
          padding: EdgeInsets.symmetric(horizontal: 16.px),
          children: [
            Padding(
              padding: EdgeInsets.symmetric(vertical: 10.px),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 40.px,
                    backgroundImage:
                        CachedNetworkImageProvider(item!.avatarUrl!),
                  ),
                  SwImage(
                    'assets/live/main/ic_more.png',
                    width: 24.px,
                    color: const Color(0xff2B2F36),
                    onTap: () async {},
                  ),
                ],
              ),
            ),
            SizedBox(height: 10.px),
            Row(
              children: [
                Text(
                  item!.okNickName ?? '',
                  style: TextStyle(
                    fontSize: 20.px,
                    color: const Color(0xff1F2125),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(width: 8.px),
                SwLogo(
                  icon: 'assets/live/main/tab_male.png',
                  iconWidth: 15.px,
                ),
              ],
            ),
            SizedBox(height: 8.px),
            Text(
              '昵称：我是服务器昵称',
              style: TextStyle(
                fontSize: 14.px,
                color: const Color(0xff6D6F73),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 8.px),
            Row(
              children: [
                Text(
                  _copyText,
                  style: TextStyle(
                    fontSize: 14.px,
                    color: const Color(0xff6D6F73),
                  ),
                ),
                SwImage(
                  'assets/live/main/copy.png',
                  width: 11.75.px,
                  color: const Color(0xff8F959E),
                  margin: EdgeInsets.only(left: 5.75.px),
                  onTap: () async {
                    await copyText(_copyText, '复制成功');
                  },
                ),
              ],
            ),
            SizedBox(height: 19.px),
            const HorizontalLine(height: 1, color: Color(0xffF0F1F2)),
            Column(
              children: List.generate(10, (index) {
                return ClickEvent(
                  onTap: () async {
                    RouteUtil.pop();
                    //直播回放生成中
                    await RouteUtil.push(
                        context,
                        WebPlaybackGenerationPage(item: item),
                        'WebPlaybackGenerationPage');
                  },
                  child: Container(
                    height: 120.px,
                    padding: EdgeInsets.symmetric(vertical: 16.px),
                    child: Row(
                      children: [
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: 160.px,
                              height: 88.px,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(3.2.px),
                                color: Colors.black,
                              ),
                              child: SwImage(
                                item?.roomLogo,
                              ),
                            ),
                            const SwLogo(
                              isCircle: true,
                              icon: 'assets/live/main/play_white.png',
                            ),
                          ],
                        ),
                        SizedBox(width: 16.px),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '这里展示直播间标题这里展示直播间标题这里展示直播间标题这里展示直这里展示直播间标题这里展示直播间标题这里展示直播这里展示直播间标题这里展示直播间标题这里展示直播间标题这里展示直播间标题这里展示直播间标题间标题这里展示直播间标题这里展示直播间标题这里展示直播间标题播间标题这里展示这里展示直播间标题这里展示直播间标题这里展示直播间标题这里展示直播间标题直播间标题这里展示直播间标题这里展示直播间标题这里展示直播间标题',
                                style: TextStyle(
                                  fontSize: 16.px,
                                  color: const Color(0xff1F2125),
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                              SizedBox(height: 10.px),
                              Expanded(
                                child: Text(
                                  '2021.06.04 18:00',
                                  style: TextStyle(
                                    fontSize: 14.px,
                                    color: const Color(0xff8F959E),
                                  ),
                                ),
                              ),
                              Row(
                                children: [
                                  SwImage(
                                    'assets/live/main/share_icon.png',
                                    width: 20.px,
                                    color: MyTheme.blueColor,
                                    margin: EdgeInsets.only(right: 16.29.px),
                                  ),
                                  SwImage(
                                    'assets/live/main/ic_more.png',
                                    color: MyTheme.blueColor,
                                    width: 20.px,
                                  )
                                ],
                              )
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ],
        )),
      ],
    );
  }
}
