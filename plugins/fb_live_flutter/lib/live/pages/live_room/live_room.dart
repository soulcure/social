import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:fb_live_flutter/live/bloc/with/live_mix.dart';
import 'package:fb_live_flutter/live/bloc_model/anchor_close_live_bt_bloc_model.dart';
import 'package:fb_live_flutter/live/pages/live_room/widget/live_comon.dart';
import 'package:fb_live_flutter/live/pages/live_room/widget/up_like_gesture.dart';
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

import '../../bloc/live_room_bloc.dart';
import '../../bloc_model/live_preview_bloc_model.dart';
import '../../bloc_model/online_user_count_bloc_model.dart';
import '../../bloc_model/screen_clear_bloc_model.dart';
import '../../bloc_model/show_anchor_leave_blic_model.dart';
import '../../bloc_model/show_image_filter_bloc_model.dart';
import '../../utils/live_status_enum.dart';
import '../../utils/ui/frame_size.dart';
import '../playback/widget/live_logo_background.dart';
import '../screen_sharing/screen_sharing_page.dart';
import 'bt/screen_rotation_bt.dart';
import 'decoration/bg_box_decoration.dart';
import 'decoration/transform_box.dart';
import 'widget/anchor_leave_widget.dart';
import 'widget/anchor_left_top_widget.dart';
import 'widget/fb_keep_alive.dart';
import 'widget/live_view_widget.dart';
import 'widget/top_right_widget.dart';

class LiveRoom extends StatefulWidget {
  final bool? isOverlayViewPush; //是否是点击浮窗进入

  // 是否来自预览
  final bool isFromPreview;

  // 是否来自直播列表页面
  final bool? isFromList;

  final LiveValueModel? liveValueModel;

  bool? get isAnchor => liveValueModel!.isAnchor;

  final bool autoFloatOnFirstFrame;

  const LiveRoom({
    Key? key,
    this.isFromList,
    this.isOverlayViewPush = false,
    this.isFromPreview = false,
    required this.liveValueModel,
    this.autoFloatOnFirstFrame = false,
  }) : super(key: key);

  @override
  LiveRoomState createState() => LiveRoomState();
}

class LiveRoomState extends State<LiveRoom>
    with
        RouteAware,
        TickerProviderStateMixin,
        WidgetsBindingObserver,
        LivePageHandleInterface,
        LivePageCommon,
        LivePageHandle {
  final LiveRoomBloc _liveBloc = LiveRoomBloc();

  @override
  void initState() {
    _liveBloc.init(this, autoFloat: widget.autoFloatOnFirstFrame);
    super.initState();
  }

  @override
  bool get isScreenRotation {
    return _liveBloc.isScreenRotation;
  }

  Widget body() {
    final child = Stack(
      children: [
        BlocBuilder<LivePreviewBlocModel, int>(
          builder: (context, textureID) {
            if (_liveBloc.liveValueModel!.textureId >= 0) {
              return TransformBox(
                _liveBloc.isWebFlip,
                child: LiveViewWidgetView(_liveBloc.algModel, _liveBloc,
                    textureId:
                        (_liveBloc.isOverlayViewPush! && !widget.isAnchor!)
                            ? widget.liveValueModel!.textureId
                            : _liveBloc.liveValueModel!.textureId),
              );
            } else {
              return Container();
            }
          },
        ),
        BlocBuilder<ShowImageFilterBlocModel, bool>(
          builder: (context, _showImageFilter) {
            return Offstage(
              offstage: _showImageFilter,
              child: _liveBloc.getRoomInfoObject == null
                  ? Container()
                  : LiveLogoBackground(

                      /// 【APP】切换小窗口后，主播暂时离开背景封面不是直播封面而是摄像头最后一帧的背景
                      _liveBloc.getRoomInfoObject!.roomLogo),
            );
          },
        ),
        BlocBuilder<ShowScreenSharingBlocModel, bool>(
          builder: (context, _showImageFilter) {
            if (_liveBloc.liveValueModel!.isScreenSharing) {
              return const ScreenSharingPage();
            }
            return Container();
          },
        ),
        BlocBuilder<ShowAnchorLeaveBlocModel, bool>(
            builder: (context, _showAnchorLeave) {
          return Offstage(
            offstage: _showAnchorLeave,
            child: AnchorLeaveWidget(),
          );
        }),
        UpLikeGesture(
          isAnchor: widget.isAnchor,
          roomId: widget.liveValueModel!.getRoomId,
          upLikeClickBlock: (likeNum, typeString) {
            _liveBloc.upLikeClickBlock(likeNum, typeString, this);
          },
          roomInfoObject: _liveBloc.getRoomInfoObject,
          child: PageView(
            onPageChanged: (pageIndex) {
              _liveBloc.tipsLoginBlocModel?.add(pageIndex == 0);
            },
            children: [
              FBKeepAlive(
                child: Builder(builder: (context) {
                  return Stack(
                    children: [
                      /// 横屏禁止侧边滑动退出页面
                      if (Platform.isIOS && FrameSize.isHorizontal())
                        WillPopScope(
                          onWillPop: () async {
                            return false;
                          },
                          child: Container(),
                        ),

                      /// 优惠券入口
                      BlocBuilder<LivePreviewBlocModel, int>(
                        builder: (context, textureID) {
                          return CouponsBt(
                            liveValueModel: _liveBloc.liveValueModel!,
                            liveBloc: _liveBloc,
                            goodsLogic: _liveBloc,
                            liveShopInterface: _liveBloc,
                            couponsLogic: _liveBloc,
                          );
                        },
                      ),
                      AnchorLeftTopWidget(
                        context: context,
                        bloc: _liveBloc,
                        isScreenRotation: isScreenRotation,
                      ),
                      Positioned(
                        top: !isScreenRotation
                            ? FrameSize.padTopHDynamic(context) +
                                FrameSize.px(11)
                            : FrameSize.px(11),
                        right: FrameSize.px(12),
                        child: BlocBuilder<ScreenClearBlocModel, bool>(
                          builder: (context, clearState) {
                            return Offstage(
                              offstage: clearState,
                              child: BlocBuilder<OnlineUserCountBlocModel, int>(
                                builder: (context, onlineNum) {
                                  return TopRightView(
                                    countBloc: _liveBloc,
                                    isExternal: widget.liveValueModel!.getIsObs,
                                    isAnchor: _liveBloc.isAnchor,
                                    onlineUserCountModel:
                                        _liveBloc.onlineUserCountModel,
                                    roomId: widget
                                        .liveValueModel!.roomInfoObject!.roomId,
                                    userOnlineList: _liveBloc.userOnlineList,
                                    isScreenRotation: isScreenRotation,
                                    closeClickBlock: () async {
                                      _liveBloc.negationScreenRotation(false);
                                      await _liveBloc
                                          .setSystemPortraitVertical();

                                      RouteCloseMix.notActiveCloseThen(
                                          action: () {
                                        // 用户点击关闭直播
                                        _liveBloc.audienceIsClose = true;

                                        _liveBloc.audienceCloseRoom();
                                      });
                                    },
                                    roomInfoObject: _liveBloc.getRoomInfoObject,
                                  );
                                },
                              ),
                            );
                          },
                        ),
                      ),
                      //是否横屏按钮
                      if (!widget.isAnchor! && !kIsWeb)
                        BlocBuilder<LivePreviewBlocModel, int>(
                          builder: (context, textureID) {
                            return ScreenRotationBt(_liveBloc, onTap: () async {
                              /// 防止出现路由和事件同时触发
                              if (!RouteUtil.routeCanRotate()) {
                                return;
                              }
                              if (_liveBloc.isRotating) {
                                return;
                              }

                              await _liveBloc.rotationHandle();
                              await Future.delayed(
                                  const Duration(milliseconds: 200));
                            });
                          },
                        ),

                      ///  【APP】推送的时候送礼，送礼特效和IM信息有重叠
                      ///  2021 11.10
                      LiveGiftCommon(
                        animationCompleteGiftsOne:
                            _liveBloc.animationCompleteGiftsOne,
                        animationCompleteGiftsTwo:
                            _liveBloc.animationCompleteGiftsTwo,
                        animationCompleteGiftsThree:
                            _liveBloc.animationCompleteGiftsThree,
                        bottomViews:
                            BlocBuilder<AnchorCloseLiveBtBlocModel, int>(
                          builder: (context, onlineNum) {
                            return BottomViewsCommon(
                              bloc: _liveBloc,
                              liveShop: _liveBloc,
                              more: _liveBloc,
                              isExternal: widget.liveValueModel!.getIsObs,
                              pushGoodsLiveRoomModel:
                                  _liveBloc.pushGoodsLiveRoomModel,
                              isScreenRotation: _liveBloc.isScreenRotation,
                              roomId:
                                  widget.liveValueModel!.roomInfoObject!.roomId,
                              upLikeClickBlock: (likeNum, typeString) {
                                _liveBloc.upLikeClickBlock(
                                    likeNum, typeString, this);
                              },
                              goodsQueue: _liveBloc.goodsQueue,
                              fbApiSendLiveMsg: _liveBloc.fbApiSendLiveMsg,
                              buttonClickBlock: _liveBloc.buttonClickBlock,
                              goodsLogic: _liveBloc,
                            );
                          },
                        ),
                        animationCompeteTips: _liveBloc.animationCompeteTips,
                      ),
                      LiveWidgetListCommon(
                        isAnchor: _liveBloc.isAnchor,
                        stream: _liveBloc.widgetListStreamController.stream,
                      ),
                    ],
                  );
                }),
              ),
              const FBKeepAliveFull(),
            ],
          ),
        )
      ],
    );
    final liveScreenShouldHide =
        widget.autoFloatOnFirstFrame && !(widget.isOverlayViewPush ?? false);
    return MyScaffold(
        backgroundColor: liveScreenShouldHide ? Colors.transparent : null,
        resizeToAvoidBottomInset: false,
        body: liveScreenShouldHide
            ? ConstrainedBox(
                constraints: BoxConstraints.tight(Size.zero),
                child: child,
              )
            : Container(decoration: const BgBoxDecoration(), child: child));
  }

  @override
  Future<bool> popHandle() async {
    _liveBloc.didPop();
    return true;
  }

  @override
  Widget build(BuildContext context) {
    _liveBloc.cleanGiftBloc();

    _liveBloc.okContext(context);
    if (widget.liveValueModel!.liveStatus == LiveStatus.abnormalLogin) {
      return Container();
    }

    final Widget bodyChild = body();
    return BlocBuilder<LiveRoomBloc, int>(
      builder: (context, value) {
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle.light,
          child: MultiBlocProvider(
            providers: _liveBloc.providersValue,
            child: bodyChild,
          ),
        );
      },
      bloc: _liveBloc,
    );
  }

  @override
  void dispose() {
    _liveBloc.close();

    //强制竖屏
    _liveBloc.setSystemPortraitVertical();

    super.dispose();
  }

  ///切换到前后台
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _liveBloc.setNeedDelay(state);

    _liveBloc.checkScreen(state, _liveBloc, _liveBloc.liveValueModel!);
    if (state == AppLifecycleState.resumed) {
      /// app恢复设置竖屏
      _liveBloc.appResumedSetVertical();

      /// 设置为当前不在app外
      _liveBloc.isOutsideApp = false;

      /// 【2021 12.15】app恢复，标识更新
      /// 修复app退到后台不显示悬浮窗
      if (Platform.isAndroid) {
        /// 只有Android才有全局悬浮窗，回来需要关闭
        RouteCloseMix.setNotActiveClose();
      }

      /// 检测直播状态
      _liveBloc.checkLiveStatusHandle();

      /// 防止回到app又打开了小窗口又没关闭
      if (RouteUtil.routeIsLiveNotContainNull) {
        ZegoManager.handleFloat(onComplete: _liveBloc.refreshLiveView);

        /// 这里设置500导致了【iOS主播退桌面，然后回直播间，立刻切小窗口，小窗口消失】，
        /// 现改为200。
        unawaited(
            FloatUtil.dismissFloat(200, onThen: _liveBloc.refreshLiveView));
      }
    } else if (state == AppLifecycleState.paused && Platform.isAndroid) {
      /// 设置为当前在app外
      _liveBloc.isOutsideApp = true;

      /// 记录离开了app
      /// 因为[appResumedSetVertical]需要延时操作，不太适合使用[_liveBloc.liveValueModel!.isOutsideApp]
      _liveBloc.isLeaveApp = true;

      /// 【2021 12.10】app暂停时调用blo内的打开小窗口，而不是单独写
      _liveBloc.didPop();
    }
  }
}
