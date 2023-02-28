import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:fb_live_flutter/live/bloc/live_room_obs_bloc.dart';
import 'package:fb_live_flutter/live/bloc/with/live_mix.dart';
import 'package:fb_live_flutter/live/bloc_model/anchor_close_live_bt_bloc_model.dart';
import 'package:fb_live_flutter/live/pages/live_room/widget/anchor_left_top_widget.dart';
import 'package:fb_live_flutter/live/pages/live_room/widget/live_comon.dart';
import 'package:fb_live_flutter/live/pages/live_room/widget/live_view_widget.dart';
import 'package:fb_live_flutter/live/utils/func/router.dart';
import 'package:fb_live_flutter/live/utils/live/zego_manager.dart';
import 'package:fb_live_flutter/live/utils/other/float_util.dart';
import 'package:fb_live_flutter/live/utils/solve_repeat/solve_repeat.dart';
import 'package:fb_live_flutter/live/widget/live/coupons_bt.dart';
import 'package:fb_live_flutter/live/widget_common/flutter/my_scaffold.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc_model/live_preview_bloc_model.dart';
import '../../bloc_model/online_user_count_bloc_model.dart';
import '../../bloc_model/screen_clear_bloc_model.dart';
import '../../utils/live_status_enum.dart';
import '../../utils/ui/frame_size.dart';
import 'decoration/bg_box_decoration.dart';
import 'widget/fb_keep_alive.dart';
import 'widget/top_right_widget.dart';

class LiveRoomObs extends StatefulWidget {
  final bool? isOverlayViewPush; //是否是点击浮窗进入

  // 是否来自直播列表页面
  final bool? isFromList;
  final LiveValueModel? liveValueModel;

  bool? get isAnchor => liveValueModel!.isAnchor;

  final bool autoFloatOnFirstFrame;

  const LiveRoomObs({
    Key? key,
    this.isFromList,
    this.isOverlayViewPush = false,
    required this.liveValueModel,
    this.autoFloatOnFirstFrame = false,
  }) : super(key: key);

  @override
  LiveRoomObsState createState() => LiveRoomObsState();
}

class LiveRoomObsState extends State<LiveRoomObs>
    with
        RouteAware,
        TickerProviderStateMixin,
        WidgetsBindingObserver,
        AutomaticKeepAliveClientMixin,
        LivePageHandleInterface,
        LivePageCommon,
        LiveObsPageHandle {
  final LiveRoomObsBloc _liveObsBloc = LiveRoomObsBloc();

  @override
  void initState() {
    _liveObsBloc.init(this);
    super.initState();
  }

  @override
  bool get isScreenRotation {
    return _liveObsBloc.isScreenRotation;
  }

  Widget body() {
    return MyScaffold(
      resizeToAvoidBottomInset: false,
      body: Container(
        decoration: const BgBoxDecoration(),
        height: FrameSize.winHeight(),
        child: Stack(
          children: [
            BlocBuilder<LivePreviewBlocModel, int>(
                builder: (context, textureID) {
              /// 这里传递是obs，让组件内不去设置默认画面为全屏幕宽高，
              /// 如果不传true的话初始化将出现短暂黑屏。
              return LiveViewWidget(_liveObsBloc, isObs: true);
            }),
            PageView(
              controller: PageController(),
              onPageChanged: (pageIndex) {
                _liveObsBloc.tipsLoginBlocModel?.add(pageIndex == 0);
              },
              children: [
                FBKeepAlive(
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width,
                    height: MediaQuery.of(context).size.height,
                    child: Stack(
                      children: [
                        /// 优惠券入口
                        CouponsBt(
                          liveValueModel: _liveObsBloc.liveValueModel!,
                          liveBloc: _liveObsBloc,
                          goodsLogic: _liveObsBloc,
                          liveShopInterface: _liveObsBloc,
                          couponsLogic: _liveObsBloc,
                        ),
                        AnchorLeftTopWidget(
                          context: context,
                          bloc: _liveObsBloc,
                          isScreenRotation: isScreenRotation,
                        ),
                        Positioned(
                          top: !isScreenRotation
                              ? FrameSize.padTopH() + FrameSize.px(11)
                              : FrameSize.px(11),
                          right: FrameSize.px(12),
                          child: BlocBuilder<ScreenClearBlocModel, bool>(
                            builder: (context, clearState) {
                              return Offstage(
                                offstage: clearState,
                                child:
                                    BlocBuilder<OnlineUserCountBlocModel, int>(
                                  builder: (context, onlineNum) {
                                    return TopRightView(
                                      countBloc: _liveObsBloc,
                                      isExternal: true,
                                      isAnchor: _liveObsBloc.isAnchor,
                                      onlineUserCountModel:
                                          _liveObsBloc.onlineUserCountModel,
                                      roomId: widget.liveValueModel!.getRoomId,
                                      userOnlineList:
                                          _liveObsBloc.userOnlineList,
                                      isScreenRotation: isScreenRotation,
                                      closeClickBlock:
                                          _liveObsBloc.audienceCloseRoom,
                                      roomInfoObject: _liveObsBloc
                                          .liveValueModel!.roomInfoObject!,
                                    );
                                  },
                                ),
                              );
                            },
                          ),
                        ),

                        ///  【APP】推送的时候送礼，送礼特效和IM信息有重叠
                        ///  2021 11.10
                        LiveGiftCommon(
                          animationCompleteGiftsOne:
                              _liveObsBloc.animationCompleteGiftsOne,
                          animationCompleteGiftsTwo:
                              _liveObsBloc.animationCompleteGiftsTwo,
                          animationCompleteGiftsThree:
                              _liveObsBloc.animationCompleteGiftsThree,
                          bottomViews:
                              BlocBuilder<AnchorCloseLiveBtBlocModel, int>(
                                  builder: (context, onlineNum) {
                            return BottomViewsCommon(
                              bloc: _liveObsBloc,
                              liveShop: _liveObsBloc,
                              more: null,
                              isExternal: true,
                              pushGoodsLiveRoomModel:
                                  _liveObsBloc.pushGoodsLiveRoomModel,
                              isScreenRotation: _liveObsBloc.isScreenRotation,
                              roomId: widget.liveValueModel!.getRoomId,
                              upLikeClickBlock: (likeNum, typeString) {
                                _liveObsBloc.upLikeClickBlock(
                                    likeNum, typeString, this);
                              },
                              goodsQueue: _liveObsBloc.goodsQueue,
                              fbApiSendLiveMsg: _liveObsBloc.fbApiSendLiveMsg,
                              buttonClickBlock: _liveObsBloc.buttonClickBlock,
                              goodsLogic: _liveObsBloc,
                            );
                          }),
                          animationCompeteTips:
                              _liveObsBloc.animationCompeteTips,
                        ),

                        LiveWidgetListCommon(
                          isAnchor: _liveObsBloc.isAnchor,
                          stream:
                              _liveObsBloc.widgetListStreamController.stream,
                        ),
                      ],
                    ),
                  ),
                ),
                const FBKeepAliveFull(),
              ],
            )
          ],
        ),
      ),
    );
  }

  @override
  Future<bool> popHandle() async {
    _liveObsBloc.didPop();
    return true;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    _liveObsBloc.cleanGiftBloc();

    _liveObsBloc.okContext(context);
    if (widget.liveValueModel!.liveStatus == LiveStatus.abnormalLogin) {
      return Container();
    }

    final Widget bodyChild = body();

    return BlocBuilder<LiveRoomObsBloc, int>(
      builder: (context, value) {
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle.light,
          child: MultiBlocProvider(
            providers: _liveObsBloc.providers,
            child: bodyChild,
          ),
        );
      },
      bloc: _liveObsBloc,
    );
  }

  @override
  void dispose() {
    _liveObsBloc.close();

    //强制竖屏
    SystemChrome.setPreferredOrientations(
        [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);

    super.dispose();
  }

  ///切换到前后台
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _liveObsBloc.setNeedDelay(state);

    if (state == AppLifecycleState.resumed) {
      /// 设置为当前不在app外
      _liveObsBloc.isOutsideApp = false;

      /// 防止回到app又打开了小窗口又没关闭
      if (RouteUtil.routeIsLiveNotContainNull) {
        ZegoManager.handleFloat(onComplete: _liveObsBloc.refreshLiveView);

        /// 这里设置500导致了【iOS主播退桌面，然后回直播间，立刻切小窗口，小窗口消失】，
        /// 现改为200。
        unawaited(
            FloatUtil.dismissFloat(200, onThen: _liveObsBloc.refreshLiveView));
      }
    } else if (state == AppLifecycleState.paused && Platform.isAndroid) {
      /// 设置为当前在app外
      _liveObsBloc.isOutsideApp = true;

      _liveObsBloc.didPop();
    }
  }

  @override
  bool get wantKeepAlive => true;
}
