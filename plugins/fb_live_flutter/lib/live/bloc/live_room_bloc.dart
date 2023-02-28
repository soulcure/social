import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:fb_live_flutter/fb_live_flutter.dart';
import 'package:fb_live_flutter/live/api/fblive_provider.dart';
import 'package:fb_live_flutter/live/bloc/with/live_loading.dart';
import 'package:fb_live_flutter/live/bloc/with/live_orientation.dart';
import 'package:fb_live_flutter/live/bloc/with/screen_with.dart';
import 'package:fb_live_flutter/live/bloc_model/show_anchor_leave_blic_model.dart';
import 'package:fb_live_flutter/live/bloc_model/show_image_filter_bloc_model.dart';
import 'package:fb_live_flutter/live/event_bus_model/goods_html_bus.dart';
import 'package:fb_live_flutter/live/event_bus_model/ios_screen_even.dart';
import 'package:fb_live_flutter/live/event_bus_model/live/ios_screen_direction_model.dart';
import 'package:fb_live_flutter/live/event_bus_model/live/live_route_active_close.dart';
import 'package:fb_live_flutter/live/event_bus_model/live/window_direction_model.dart';
import 'package:fb_live_flutter/live/event_bus_model/live_status_model.dart';
import 'package:fb_live_flutter/live/event_bus_model/refresh_room_list_model.dart';
import 'package:fb_live_flutter/live/event_bus_model/screen_rotation_model.dart';
import 'package:fb_live_flutter/live/event_bus_model/send_gifts_model.dart';
import 'package:fb_live_flutter/live/model/close_audience_room_model.dart';
import 'package:fb_live_flutter/live/model/room_infon_model.dart';
import 'package:fb_live_flutter/live/net/api.dart';
import 'package:fb_live_flutter/live/pages/close_room/close_room_audience.dart';
import 'package:fb_live_flutter/live/pages/live_room/interface/live_interface.dart';
import 'package:fb_live_flutter/live/pages/live_room/live_room.dart';
import 'package:fb_live_flutter/live/utils/config/route_path.dart';
import 'package:fb_live_flutter/live/utils/config/steam_info_config.dart';
import 'package:fb_live_flutter/live/utils/func/check.dart';
import 'package:fb_live_flutter/live/utils/func/router.dart';
import 'package:fb_live_flutter/live/utils/live/base_bloc.dart';
import 'package:fb_live_flutter/live/utils/live/zego_manager.dart';
import 'package:fb_live_flutter/live/utils/live_status_enum.dart';
import 'package:fb_live_flutter/live/utils/manager/event_bus_manager.dart';
import 'package:fb_live_flutter/live/utils/other/fb_api_model.dart';
import 'package:fb_live_flutter/live/utils/other/float/float_mode.dart';
import 'package:fb_live_flutter/live/utils/other/float_plugin.dart';
import 'package:fb_live_flutter/live/utils/other/float_util.dart';
import 'package:fb_live_flutter/live/utils/other/ios_screen_plugin.dart';
import 'package:fb_live_flutter/live/utils/other/ios_screen_util.dart';
import 'package:fb_live_flutter/live/utils/other/screen_orientation_util.dart';
import 'package:fb_live_flutter/live/utils/solve_repeat/solve_repeat_logic.dart';
import 'package:fb_live_flutter/live/utils/theme/my_toast.dart';
import 'package:fb_live_flutter/live/utils/ui/dialog_util.dart';
import 'package:fb_live_flutter/live/utils/ui/frame_size.dart';
import 'package:fb_live_flutter/live/utils/ui/loading.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart'; // ignore: implementation_imports
// ignore: implementation_imports
import 'package:flutter_bloc/src/bloc_provider.dart' as bloc_p;
import 'package:flutter_rotate/flutter_rotate.dart';
import 'package:get/get.dart';
import 'package:oktoast/oktoast.dart';
import 'package:replay_kit_launcher/replay_kit_launcher.dart';
import 'package:zego_express_engine/zego_express_engine.dart';

import 'logic/coupons_logic.dart';
import 'logic/goods_logic.dart';
import 'logic/live_load_logic.dart';
import 'with/live_mix.dart';

class LiveRoomBloc extends BaseAppCubit<int>
    with
        BaseAppCubitState,
        ScreenWithAbs,
        LiveLoadInterface,
        LiveNetErrorLogic,
        LiveOutSyncLogic,
        SmallWindowMixin,
        LiveMoreInterface,
        LiveInterface,
        LiveLoadWith,
        LiveMix,
        ScreenWith,
        LiveLoadLogic,
        GoodsLogic,
        CouponsLogic,
        LiveShopInterface,
        LiveOrientation,
        LiveLogicCommonAbs,
        LiveLogicCommon,
        LiveStatusHandle {
  LiveRoomBloc() : super(0);

  State<LiveRoom>? statePage;

  StreamSubscription? _goodsAnchorPushBus;
  StreamSubscription? _liveRouteActiveCloseBus;
  StreamSubscription? _orientationBus;

  bool audienceIsClose = false;

  bool isWebFlip = false; //是否web镜像

  double videoRecvBytes = 0;

  String streamExtraInfo = "";

  // 出现拉流质量回调数据长度重复次数
  int recvBytesRepCount = 0;

  bool autoFloatOnFirstFrame = false;

  /// 状态管理--end

  @override
  String get roomId => statePage!.widget.liveValueModel!.roomInfoObject!.roomId;

  @override
  bool get mounted => statePage!.mounted;

  List<bloc_p.BlocProviderSingleChildWidget> get providersValue {
    return providers
      ..addAll(
        [
          BlocProvider<ShowImageFilterBlocModel>(
            create: (context) =>
                showImageFilterBlocModel = ShowImageFilterBlocModel(false),
          ),
          BlocProvider<ShowScreenSharingBlocModel>(
            create: (context) =>
                showScreenSharingBlocModel = ShowScreenSharingBlocModel(false),
          ),
          BlocProvider<ShowAnchorLeaveBlocModel>(
            create: (context) =>
                showAnchorLeaveBlocModel = ShowAnchorLeaveBlocModel(true),
          ),
        ],
      );
  }

  StreamSubscription? _batteryStateSubscription;

  // 【主播】【iOS】【屏幕共享】横竖屏转换处理-监听器
  StreamSubscription? _iosScreenDirectionBusSubs;

  Future<void> init(State<LiveRoom> state, {bool autoFloat = false}) async {
    autoFloatOnFirstFrame = autoFloat;

    unawaited(FlutterRotate.reg());

    iosCheckIsScreen();

    RouteCloseMix.setNotActiveClose();

    statePage = state;
    liveValueModel = statePage?.widget.liveValueModel ?? LiveValueModel();

    // 开始监听eventBus
    _iosScreenDirectionBusSubs =
        iosScreenDirectionBus.on<IosScreenDirectionModel>().listen((event) {
      IosScreenUtil.changeHandle(event, liveValueModel);
    });

    fbApi.registerLiveCloseListener(fanBookCloseListener);
    fbApi.addFBLiveEventListener(showOverlayView);

    /// 【2021 12.08】
    /// 初始化检测小窗是否打开状态
    /// 解决桌面点击小窗打开app后小窗还存在[OPPO reno2Z 和红米note4X]
    unawaited(FloatUtil.dismissFloat(200));

    /// 解决房间收不到消息问题【2021 11.11】
    fbApi.registerWsConnectStatusCallback((status) {
      if (status == FBWsConnectionStatus.connected) {
        fbApi.sendLiveConnect(getRoomInfoObject!.serverId,
            getRoomInfoObject!.channelId, getRoomInfoObject!.roomId);
      }
    });
    isAnchor = state.widget.isAnchor!;
    liveValueModel!.isScreenSharing =
        statePage!.widget.liveValueModel?.isScreenSharing ?? false;
    if (liveValueModel!.isScreenSharing) {
      isFromOverlayFirstScreen = true;
    }
    if (state.widget.liveValueModel!.textureId > 0) {
      liveValueModel!.textureId = state.widget.liveValueModel!.textureId;
    }

    /// 【2021 12.03】
    /// 如果是obs的话，默认填充模式设置为false，否则obs推流竖屏初始化时会出现填满拉伸；
    if (statePage!.widget.liveValueModel!.getIsObs) {
      liveValueModel!.zegoViewMode = ZegoViewMode.AspectFit;
    }

    isShowOverlayView = false;
    isOverlayViewPush = state.widget.isOverlayViewPush;
    if (isOverlayViewPush!) {
      isEnterSuccess = true;
    }
    liveValueModel!.liveStatus = state.widget.liveValueModel!.liveStatus;

    if (checkLiveStatus(
        navigatorToAudienceClosePage: _navigatorToAudienceClosePage,
        anchorCloseRoomHandle: anchorCloseRoom)) {
      return;
    }

    sendGiftsEventBusValue =
        sendGiftsEventBus.on<SendGitsEvent>().listen((event) {
      sendGiftsClickBlock(event.giftSucModel);
    });

    goodsHtmlBusValue = goodsHtmlBus.on<GoodsHtmlEvenModel>().listen((event) {
      if (isAnchor && liveValueModel!.isScreenSharing) {
        return;
      }
      refreshLiveView();
    });

    goodsHtmlIosBusValue =
        goodsHtmlBus.on<GoodsIosShowWindowEvenModel>().listen((event) {
      didPop();
    });

    _goodsAnchorPushBus =
        goodsAnchorPushBus.on<GoodsPushEvenModel>().listen((event) {
      onGoodsNotice(event.user, event.type, event.json);
    });

    _liveRouteActiveCloseBus =
        liveRouteActiveCloseBus.on<LiveRouteActiveCloseModel>().listen((event) {
      if (event.value) {
        RouteCloseMix.setActiveClose();
      } else {
        RouteCloseMix.setNotActiveClose();

        checkLiveStatusHandle();
      }
    });

    _orientationBus =
        orientationBus.on<ScreenOrientationEven>().listen((event) {
      final int orientationValue = event.orientation;
      if (liveOrientationValue == orientationValue) {
        return;
      }
      liveOrientationValue = orientationValue;

      if (!isShowRotationButton) {
        return;
      }

      if (!RouteUtil.routeCanRotate()) {
        return;
      }

      screenOrientationHandle(liveOrientationValue);
    });

    // 网络中断监听
    final result = await initConnectivity();
    if (result == 'none' || result == 'fail') {
      netErrorStatusHandle();
      return;
    }

    WidgetsBinding.instance!.addPostFrameCallback((timeStamp) async {
      /// openLoading放到[getZegoToken]外面主要为了让加载中早点显示出来
      // 开启房间loading，如果是外部推流则不提示
      if (!state.widget.isOverlayViewPush!) {
        openLoading("直播间连接中");
      }

      //获取房间信息
      await getRoomInfo();
    });
  }

  /*
  * 引擎处理
  * */
  Future engineHandle() async {
    if (!statePage!.widget.isOverlayViewPush!) {
      ///关联问题：
      /// 【2021 12.08】屏幕共享推流黑屏，与ZEGO沟通调试
      /// 1.先外部采集，然后开启预览
      /// 2.然后又开启外部采集的行为.
      ///
      /// 结论：
      /// 先判断是否来自预览，因为预览已经创建过引擎且开启了外部采集，所以不需要再开启了
      ///
      /// 影响范围：
      /// 镜像、翻转、屏幕共享、停止共享、切换横屏游戏
      if (!statePage!.widget.isFromPreview) {
        await ZegoManager.createEngine(statePage!.widget.isAnchor!);
      }
      // 如果是主播的话开启硬解码
      // 开启硬编码无美颜
      if (isAnchor) {
        await ZegoExpressEngine.instance.enableHardwareDecoder(true);
      } else if (statePage!.widget.liveValueModel!.getIsObs) {
        // 拉b帧
        await ZegoExpressEngine.instance.enableHardwareDecoder(false);
        await ZegoExpressEngine.instance.enableCheckPoc(false);
      }

      if (statePage!.widget.liveValueModel!.getIsObs) {
        isStartLive = false;
        roomBottomBlocModel!.add(true);
      }
    } else {
      /// 悬浮窗进来的直接设置首帧是好了的，防止主播离开状态异常
      isRenderVideoFirstFrame = true;

      /// 需要在refreshLiveView之前去设置视图id，否则会出现
      /// 修复【第一次进入直播间，再退小窗口，再进入直播间，黑屏】
      /// 【2021 12.1】
      liveValueModel!.textureId = statePage!.widget.liveValueModel!.textureId;

      unawaited(refreshLiveView());

      isStartLive = false; //已经开启直播
      isPlaying = false; //已经上报拉流
      setNotAnchorLeave();
      chatListBlocModel!.add({});

      /// 主播关闭直播按钮刷新
      anchorCloseLiveBtBlocModel!.add(0);

      await getOnLineCount();

      /// 【APP】从小窗口进入直播间，点赞数没有更新
      /// 【APP】小窗口返回直播间，在线人数显示有误
      startTimerGetOnline();
    }
  }

  /// 【2021 12.15】检测直播状态
  ///
  /// 【Android】app切换到后台显示小窗后直播结束出错
  /// 问题根源：
  /// 	1.在app生命周期恢复时没有去检测直播状态；
  /// 	2.在退到列表时有因为点小窗会跳转到直播页，直播初始化生命周期会去检测状态；
  /// 	3.在直播间内点h5显示小窗因为会会退路由到直播间页面再去检测直播间状态；
  /// 解决方案：
  /// 	在app恢复生命周期使用检测直播状态
  void checkLiveStatusHandle() {
    /// 如果直播已结束，再次查询房间状态
    if (anchorIsClose) {
      getRoomStatus();
    }
  }

  /*
  * iOS检测检测
  * */
  void iosCheckIsScreen() {
    if (!Platform.isIOS) {
      return;
    }
    _batteryStateSubscription = iosScreenBus.on().listen((event) {
      if (event == "ScreenOpened" && !liveValueModel!.isScreenSharing) {
        ZegoExpressEngine.instance.enableCamera(false);

        // 告诉拉流端开启了屏幕共享，需要切换拉流视图模式
        ZegoExpressEngine.instance.setStreamExtraInfo(sendSteamInfo(
            screenShare: true, mirror: false, liveValueModel: liveValueModel!));
        liveValueModel!.isScreenSharing = true;
        showImageFilterBlocModel!.add(false);
        showScreenSharingBlocModel!.add(false);
      } else if (event == "ScreenClosed" && liveValueModel!.isScreenSharing) {
        /// 这里面会开启摄像头
        ZegoManager.changeLive(liveValueModel!);

        ZegoExpressEngine.instance.muteMicrophone(false);
        liveValueModel!.isScreenSharing = false;
        Future.delayed(const Duration(milliseconds: 1000)).then((value) {
          showImageFilterBlocModel!.add(true);
          showScreenSharingBlocModel!.add(true);
        });

        final ZegoVideoMirrorMode mirrorMode = liveValueModel!.isMirror
            ? ZegoVideoMirrorMode.BothMirror
            : ZegoVideoMirrorMode.NoMirror;
        ZegoExpressEngine.instance.setVideoMirrorMode(mirrorMode);
        if (isFromOverlayFirstScreen ?? false) {
          isFromOverlayFirstScreen = false;
          onRefresh();
        }
      }
    });
  }

  /*
  * 检查镜像模式
  * */
  @override
  Future checkMirrorMode() async {
    if (!liveValueModel!.isMirror) {
      liveValueModel!.isMirror = false;
      await ZegoExpressEngine.instance
          .setVideoMirrorMode(ZegoVideoMirrorMode.NoMirror);
    } else {
      liveValueModel!.isMirror = true;
      await ZegoExpressEngine.instance
          .setVideoMirrorMode(ZegoVideoMirrorMode.BothMirror);
    }
  }

  /*
  * 上报主播屏幕尺寸
  * */
  Future anchorScreenSizePost() async {
    // 如果不是主播则直接返回
    if (!isAnchor) {
      return;
    }
    const int widthPx = 720;
    final int heightPx = 720 * FrameSize.winHeight() ~/ FrameSize.winWidth();
    if (!isScreenRotation) {
      await Api.liveScreenSize(
          statePage!.widget.liveValueModel!.roomInfoObject!.roomId,
          widthPx,
          heightPx);
    } else {
      await Api.liveScreenSize(
          statePage!.widget.liveValueModel!.roomInfoObject!.roomId,
          heightPx,
          widthPx);
    }
  }

  void liveWillClose() {
    /// 主要为了解决列表时还弹出提示【禁播提示】
    ///
    /// [anchorCloseLiveActively]是为了防止出现已经在执行主动关闭了还执行被动关闭
    if (!mounted || !RouteUtil.routeHasLive || anchorCloseLiveActively) {
      return;
    }

    /// 先关闭愿有提示再弹出新提示
    showConfirmDialog(() {
      Loading.liveWillClose(context, onPressed: () {
        getRoomInfoObject!.status = 4;
        anchorCloseRoom();
      });
    });
  }

  void didPop() {
    /// 如果没有主动关闭直播并且加载直播成功
    if (!isProactiveClose && isEnterSuccess) {
      RouteCloseMix.notActiveCloseThen(action: () {
        showOverlayView(FBLiveEvent.gotoChat);
      });
    } else {
      /// 未达到显示悬浮窗资格，调用didPop就是退出页面，需要上报退出，
      /// 包括手动点"x"也是在这上报，
      exitReport();
    }
  }

  // 监听Zegeo公共回调
  void _zegoOnEvent() {
    // 房间流更新回调【流新增、流删除】
    ZegoExpressEngine.onRoomStreamUpdate =
        (roomID, updateType, streamList, extendedData) {
      fbApi.fbLogger.info(
          'onRoomStreamUpdate roomID:$roomID updateType:$updateType streamList:$streamList extendedData:$extendedData');

      if (!isPlayStream(streamList, statePage)) {
        return;
      }
      if (updateType == ZegoUpdateType.Delete) {
        // 查询房间状态xxxx
        getRoomStatus();
        // 拉流端手动停止拉流
        ZegoExpressEngine.instance.stopPlayingStream(roomId);
      } else if (updateType == ZegoUpdateType.Add) {
        liveValueModel!.liveStatus = LiveStatus.playStreamSuccess;
        eventBus.fire(LiveStatusEvent(LiveStatus.playStreamSuccess));
        // 3、8号修改拉流
        /// 刷新直播预览UI

        if (isRenderVideoFirstFrame) {
          // 切换背景-隐藏主播已离开提示
          setNotAnchorLeave();
        }

        if (!statePage!.widget.isAnchor!) {
          isOverlayViewPush = false;
        }

        /// 流更新后拉流
        addStreamAfterPull(roomId);
      }
    };

    // 房间状态回调
    ZegoExpressEngine.onRoomStateUpdate =
        (roomID, state, errorCode, extendedData) {
      fbApi.fbLogger.info(
          'onRoomStateUpdate roomID:$roomID state:$state errorCode:$errorCode extendedData:$extendedData');

      /// 连接成功，关闭所有okToast，让结束回调不执行，防止出现【连接超时提示】
      /// 10.15 ：【APP优先】进入直播间，弱网，断网，loading长驻。  另外，主播断流后，观众从列表进入直播间应该显示什么？  @彭路
      if (state == ZegoRoomState.Connected) {
        netErrorTimerCancel();

        /// 弱网恢复网连接成功后，右滑小窗口会消失 @王增阳
        if (statePage!.widget.isAnchor!) {
          liveValueModel!.liveStatus = LiveStatus.pushStreamSuccess;
          eventBus.fire(LiveStatusEvent(LiveStatus.pushStreamSuccess));
        } else {
          liveValueModel!.liveStatus = LiveStatus.playStreamSuccess;
          eventBus.fire(LiveStatusEvent(LiveStatus.playStreamSuccess));
        }
      }

      if (errorCode == 1002030 || errorCode == 1002031) {
        cantOpenLiveStatusHandle();
      } else if (errorCode == 1002052 || errorCode == 1002053) {
        netWordErrorStatusHandle();
      } else if (errorCode == 1000055 || errorCode == 1000060) {
        netConfigStatusHandle();
      } else if (errorCode == 1002050) {
        abnormalLoginStatusHandle();
      }
    };
  }

  // 监听推流回调
  void zegoOnPushEvent() {
    // 推流端接受自定义消息
    ZegoExpressEngine.onIMRecvCustomCommand = (roomID, fromUser, command) {
      final Map? commandMap = jsonDecode(command);
      if (commandMap != null &&
          commandMap['mType'] == 1 &&
          commandMap['msg'] != null) {
        myToast(commandMap['msg'], duration: const Duration(seconds: 3));
      }
    };
    // 推流质量消息
    ZegoExpressEngine.onPublisherQualityUpdate = (streamID, quality) {
      netErrorCall(quality.level);
    };

    // 推流回调状态回调
    ZegoExpressEngine.onPublisherStateUpdate =
        (streamID, state, errorCode, extendedData) async {
      // 调用推流接口成功后，当推流器状态发生变更，如出现网络中断导致推流异常等情况，SDK在重试推流的同时，会通过该回调通知
      if (state == ZegoPublisherState.NoPublish && errorCode != 0) {
        /// 只处理主流的操作信息 ，不是主流不操作
        /// 解决两次出现【 推流失败，该流被后台系统配置为禁止推送】
        if (!isMainSteamId(streamID, statePage)) {
          return;
        }

        /// 多次违规发言，被禁止推送
        if (errorCode == 1003025) {
          liveValueModel!.liveStatus = LiveStatus.anchorViolation;
          eventBus.fire(LiveStatusEvent(LiveStatus.anchorViolation));
          await FbApiModel.violationsAction(getRoomInfoObject!.roomId);

          /// 标记为结束，下次进入时会查询直播状态
          anchorIsClose = true;

          if (!isShowOverlayView) {
            //  || routeHasLive
            liveWillClose();
          }
        } else if (errorCode == 1002050) {
          liveValueModel!.liveStatus = LiveStatus.abnormalLogin;
          eventBus.fire(LiveStatusEvent(LiveStatus.abnormalLogin));
          if (!isShowOverlayView || routeHasLive) {
            showConfirmDialog(() {
              RouteUtil.popToLive();
              // closeAllSmartDialog();
              Loading.showConfirmDialog(context!, {
                'content': '你的账号当前在另一台设备中登录，如果这不是你本人的操作，请立刻重新登录修改密码',
                'confirmText': '退出',
                'cancelShow': false
              }, () {
                goBack();
                EventBusManager.eventBus.fire(RefreshRoomListModel(true));
              });
            });
          }
        } else if (errorCode != 0) {
          fbApi.fbLogger.warning('push stream failed, $errorCode');
          liveValueModel!.liveStatus = LiveStatus.pushStreamFailed;
          eventBus.fire(LiveStatusEvent(LiveStatus.pushStreamFailed));
          if (!isShowOverlayView || routeHasLive) {
            showConfirmDialog(() {
              Loading.showConfirmDialog(
                  context!,
                  {
                    'content': '推流失败，请重试！',
                    'confirmText': '确认',
                    'cancelShow': false
                  },
                  setStreamAndTexture);
            });
          }
        }
      } else if (state == ZegoPublisherState.PublishRequesting) {
        // 重试中
      } else if (state == ZegoPublisherState.Publishing) {
        liveValueModel!.liveStatus = LiveStatus.pushStreamSuccess;
        eventBus.fire(LiveStatusEvent(LiveStatus.pushStreamSuccess));
        closeLoading();

        // 推流成功-去掉背景
        hideBackground();

        // 推流成功-让观众去掉主播离开状态[2021 11.18]
        await ZegoExpressEngine.instance.setStreamExtraInfo(
            sendSteamInfo(appIsResume: true, liveValueModel: liveValueModel!));

        if (isStartLive) {
          await anchorStartLive();
        }
        //清理流附加消息内容【app进入后台杀进程过后，恢复直播，需要刷新下直播状态】
        // ZegoExpressEngine.instance.setStreamExtraInfo("AppResumed");
        // 推流成功，开启定时器轮询线上人数
        startTimerGetOnline();
        if (!liveValueModel!.isScreenSharing) await checkMirrorMode();
      }
    };

    // 房间人数变化回调
    ZegoExpressEngine.onRoomUserUpdate = (roomID, updateType, userList) {};
  }

  // 监听拉流回调
  void _zegoOnPullEvent() {
    // 拉流分辨率变更通知
    ZegoExpressEngine.onPlayerVideoSizeChanged = (streamID, width, height) {
      fbApi.fbLogger.info(
          'onPlayerVideoSizeChanged: streamID:$streamID roomID:$roomId width:$width height:$height');

      liveValueModel!.playerVideoWidth = width.toDouble();
      liveValueModel!.playerVideoHeight = height.toDouble();

      rotationRefreshState();
    };

    /// 房间流附加信息更新
    ZegoExpressEngine.onRoomStreamExtraInfoUpdate = (roomID, streamList) {
      if (streamList.isNotEmpty) {
        streamList.forEach((element) {
          final SteamInfoModel steamInfoModel =
              SteamInfoModel.fromParam(element.extraInfo);

          /// 不等于空才进行处理
          if (steamInfoModel.appIsResume != null) {
            /// app是否为恢复状态，如果不是的话设置为主播离开
            if (steamInfoModel.appIsResume!) {
              /// 首帧绘制完毕才可以设置为主播不离开，否则会出现初始化短暂黑屏
              if (isRenderVideoFirstFrame) {
                /// 设置ui为主播不离开【去除主播离开ui】
                setNotAnchorLeave();

                /// 设置直播状态为拉流成功
                liveValueModel!.liveStatus = LiveStatus.playStreamSuccess;
                eventBus.fire(LiveStatusEvent(LiveStatus.playStreamSuccess));
              }
            } else {
              /// 设置ui为主播离开【显示主播离开ui】
              setAnchorLeave();

              /// 设置直播状态为主播离开
              liveValueModel!.liveStatus = LiveStatus.anchorLeave;
              eventBus.fire(LiveStatusEvent(LiveStatus.anchorLeave));

              /// 标记流附加消息为主播离开，
              /// 这样在第一帧回调的时候就不会去除主播离开的ui元素了。
              ///
              /// 原因：
              /// 主播离开因为只是关闭了摄像头和麦克风，
              /// 所以第一帧回调还是能拿到，所以需要配合来处理主播离开状态。
              streamInfoIsAnchorLeave = true;
            }
          }

          /// 不等于空才进行处理
          if (steamInfoModel.screenDirection != null &&
              steamInfoModel.platform != null &&
              steamInfoModel.screenShare != null) {
            /// 是iOS且推送了横屏
            if (steamInfoModel.platform == "ios" &&
                steamInfoModel.screenShare!) {
              liveValueModel!.screenDirection = steamInfoModel.screenDirection;
              rotationRefreshState();
            } else {
              /// 【APP】IOS屏幕共享熄屏自动关闭屏幕共享，再亮屏恢复普通直播。观众看到的画面拉升了
              liveValueModel!.screenDirection = "V";
            }

            /// 通知【Android】悬浮窗，视图方向变更
            FloatPlugin.screenDirectionChange(liveValueModel!.screenDirection!);

            /// 通知【IOS】悬浮窗，视图方向变更
            windowDirectionBus.fire(WindowDirectionModel());
          }
          if (steamInfoModel.screenShare != null) {
            if (steamInfoModel.screenShare!) {
              /// 记录-屏幕共享推流为true
              liveValueModel!.isScreenPush = true;

              if (liveValueModel!.zegoViewMode != ZegoViewMode.AspectFit) {
                liveValueModel!.zegoViewMode = ZegoViewMode.AspectFit;

                rotationRefreshState();
              }
            } else if (!steamInfoModel.screenShare!) {
              /// 记录-屏幕共享推流为false
              liveValueModel!.isScreenPush = false;

              /// 告诉小窗现在不为屏幕共享模式
              // eventBus.fire(LivePushMode(false));

              if (liveValueModel!.zegoViewMode != ZegoViewMode.AspectFill) {
                liveValueModel!.zegoViewMode = ZegoViewMode.AspectFill;

                rotationRefreshState(true);
              }
            }
          }
          if (steamInfoModel.mirror!) {
            isWebFlip = true;
            livePreviewBlocModel!.add(0);
          } else if (!steamInfoModel.mirror!) {
            isWebFlip = false;
            livePreviewBlocModel!.add(0);
          }
          streamExtraInfo = element.extraInfo;
        });
      }
    };

    // 拉流端渲染完视频首帧【第一帧】回调。
    ZegoExpressEngine.onPlayerRenderVideoFirstFrame = (streamID) {
      playerRenderVideoFirstFrame();
      Future.delayed(const Duration(milliseconds: 100), () {
        if (autoFloatOnFirstFrame) {
          Get.back();
        }
      });
    };

    // 拉流质量回调
    ZegoExpressEngine.onPlayerQualityUpdate = (streamID, quality) {
      netErrorCall(quality.level);
      handleRePull(quality.avTimestampDiff, onComplete: refreshLiveView);
    };

    // 拉流状态回调
    ZegoExpressEngine.onPlayerStateUpdate =
        (streamID, state, errorCode, extendedData) {
      // 调用拉流接口成功后，当拉流器状态发生变更，如出现网络中断导致推流异常等情况，SDK在重试拉流的同时，会通过该回调通知
      if (state == ZegoPlayerState.NoPlay) {
        // 主播被禁播
        if (errorCode == 1004099) {
          liveValueModel!.liveStatus = LiveStatus.anchorClosesLive;
          eventBus.fire(LiveStatusEvent(LiveStatus.anchorViolation));
          // 主播违规，直接跳转关闭直播
          _navigatorToAudienceClosePage();
        } else if (errorCode == 1002050) {
          fbApi.fbLogger.info("onPlayerStateUpdate::状态码为1002050不处理，公共回调自然会处理");
        } else if (errorCode != 0) {
          playFailStatusHandle();
        }
      } else if (state == ZegoPlayerState.PlayRequesting) {
        // 重试拉流
      } else if (state == ZegoPlayerState.Playing) {
        /// 【APP】观众显示主播暂时离开，调转商城H5页面再返回时直播背景变了。再滑动小窗口白屏
        // liveStatus = LiveStatus.playStreamSuccess;
        // eventBus.fire(LiveStatusEvent(LiveStatus.playStreamSuccess));

        /// 变更为拉流首帧后才去除loading 【2021 11.12】
        // closeLoading();

        // 播放成功-去掉背景
        /// 【APP】观众显示主播暂时离开，调转商城H5页面再返回时直播背景变了。再滑动小窗口白屏
        // hideBackground();

        // 【old-已废弃】处理流附加消息【显示背景&主播离开】
        // handleStreamExtraInfoUpdate(streamExtraInfo);
        // 通知服务端
        if (isPlaying) {
          // 上报服务器
          setLiveEnter();
          // 通知FB[防止调用了两次进入房间，先注释]
          // fbApiEnterLiveRoom();
          isPlaying = false;
        }
        // 拉流成功，开启定时器轮询线上人数
        startTimerGetOnline();
      }
    };
  }

  /// 设置推拉流及视频画面，分别情况有
  /// 1.观众第一次进入直播间；
  /// 2.观众小窗进入直播间；
  /// 3.主播第一次进入直播间；
  /// 4.主播小窗进入直播间；
  @override
  Future setStreamAndTexture() async {
    // 登录房间
    if (!isOverlayViewPush!) {
      await ZegoManager.zegoLoginRoom(liveValueModel!.zegoTokenModel!);
    }

    /// 公共回调注册
    _zegoOnEvent();

    /// 推流回调和拉流回调注册
    if (!isAnchor) {
      /// 不是主播监听拉流回调
      _zegoOnPullEvent();
    } else {
      /// 是主播监听推流回调
      zegoOnPushEvent();
    }

    if (statePage!.widget.liveValueModel!.textureId <= 0 &&

        /// 浮窗进入不需要创建视图
        !statePage!.widget.isOverlayViewPush!) {
      // // 预览推拉流状态
      final int screenWidthPx =
          FrameSize.screenW().toInt() * FrameSize.pixelRatio().toInt();

      final int screenHeightPx =
          FrameSize.screenH().toInt() * FrameSize.pixelRatio().toInt();
      await ZegoExpressEngine.instance
          .createTextureRenderer(screenWidthPx, screenHeightPx)
          .then((textureID) {
        final ZegoCanvas previewCanvas = ZegoCanvas.view(textureID);
        previewCanvas.viewMode = liveValueModel!.zegoViewMode;

        liveValueModel!.textureId = textureID;

        // 【只是创建视图，不需要更新UI】2022 0324
        // livePreviewBlocModel.add(0);

        /// 【2021 12.09】修复obs观众拉流端初始化3-5秒画面拉伸
        ///
        /// 是主播才在初始化的时候创建视图，观众只去做拉流回调监听等，
        /// 在尺寸变更之后才去刷新拉流端视图
        if (statePage!.widget.isAnchor!) {
          /// 刷新直播预览UI
          refreshUi(previewCanvas);
        }
      });
    }
  }

  /*
  * 屏幕旋转后刷新状态
  * */
  @override
  Future rotationRefreshState([bool isCancelScreenPush = false]) async {
    if (isAnchor) {
      return;
    }
    algModel = viewRenderAlg();

    await ZegoExpressEngine.instance
        .updateTextureRendererSize(
      liveValueModel!.textureId,
      (algModel.viewWidth * FrameSize.pixelRatio()).toInt(),
      (algModel.viewHeight * FrameSize.pixelRatio()).toInt(),
    )
        .then((value) {
      final ZegoCanvas previewCanvas =
          ZegoCanvas.view(liveValueModel!.textureId);
      previewCanvas.viewMode = algModel.viewMode;
      ZegoManager.audiencePullStream(previewCanvas, roomId);

      if (!livePreviewBlocModel!.isClosed) {
        livePreviewBlocModel!.add(0);
      }
    });

    /// 告诉小窗现在为屏幕共享模式
    eventBus.fire(LiveSizeEvent(liveValueModel!.playerVideoWidth,
        liveValueModel!.playerVideoHeight, liveValueModel!.zegoViewMode));

    /// 告诉原生部分视图更新了
    await FloatPlugin.changeViewMode(liveValueModel!.playerVideoWidth,
        liveValueModel!.playerVideoHeight, liveValueModel!.zegoViewMode);
  }

  /*
  * 刷新直播ui
  * */
  @override
  Future refreshLiveView() async {
    algModel = viewRenderAlg();

    await ZegoExpressEngine.instance
        .updateTextureRendererSize(
      liveValueModel!.textureId,
      (algModel.viewWidth * FrameSize.pixelRatio()).toInt(),
      (algModel.viewHeight * FrameSize.pixelRatio()).toInt(),
    )
        .then((value) {
      if (value) {
        final ZegoCanvas previewCanvas =
            ZegoCanvas.view(liveValueModel!.textureId);

        previewCanvas.viewMode = algModel.viewMode;

        if (isAnchor) {
          /// 屏幕共享当从别的页面返回到直播页面不需要开启预览
          if (liveValueModel!.isScreenSharing) {
            return;
          }
          ZegoExpressEngine.instance.startPreview(canvas: previewCanvas);
        } else {
          ZegoManager.audiencePullStream(previewCanvas, roomId);
        }

        livePreviewBlocModel!.add(0);
      }
    });
  }

  /// 刷新直播预览UI
  Future refreshUi(ZegoCanvas? previewCanvas) async {
    if (isAnchor) {
      //  注册推流回调事件
      zegoOnPushEvent();
      if (!statePage!.widget.isOverlayViewPush!) {
        //  推流
        await ZegoManager.anchorPushStream(
            previewCanvas, liveValueModel!.zegoTokenModel,
            isSetConfig:
                !(statePage!.widget.liveValueModel?.isScreenSharing ?? false));
      } else {
        /// log[2021 10.27]
        /// 修复【恢复直播】悬浮窗进入直播间画面显示黑屏，但推流正常
        await ZegoExpressEngine.instance.startPreview(canvas: previewCanvas);
      }

      // 等待【确保视图创建完成，防止卡顿】
      await Future.delayed(const Duration(milliseconds: 200));

      // 关闭toast
      dismissAllToast();

      /// 直播刷新
      livePreviewBlocModel!.add(0);
    } else {
      // 拉流回调事件
      _zegoOnPullEvent();
    }
  }

  // 直播结束-用户跳转
  void _navigatorToAudienceClosePage() {
    /// 只有非主播关闭情况下且没有显示浮窗情况下需要处理跳转结束页
    RouteCloseMix.notActiveCloseThen(
        action: _navigatorToAudienceClosePageHandle);
  }

  // 直播结束-用户跳转【处理】
  void _navigatorToAudienceClosePageHandle() {
    RouteUtil.popToLive();
    eventBus.fire(LiveCloseEvent());
    // 移除IM消息回调
    fbApiRemoveLiveMsgHandler();
    // 上报当前角色直播间
    // 【直播管理平台】观众观看直播，不主动退出直播间，主播结束直播，观众的观看时长显示为0
    setLiveExit();
    // FBAPI--用户退出房间
    fbApiExitLiveRoom();
    final nickName = getRoomInfoObject?.nickName ?? '';
    final anchorId = getRoomInfoObject?.anchorId ?? '';
    final avatarUrl = getRoomInfoObject?.avatarUrl ?? '';
    final int audienceCount = onlineUserCountModel?.total ?? 0;
    final roomLogo = getRoomInfoObject?.roomLogo ?? '';
    final serverId = getRoomInfoObject?.serverId ?? '';
    final CloseAudienceRoomModel closeAudienceRoomModel =
        CloseAudienceRoomModel(
      nickName: nickName,
      avatarUrl: avatarUrl,
      audienceCount: audienceCount,
      roomLogo: roomLogo,
      userId: anchorId,
      serverId: serverId,
    );
    if (!audienceIsClose) {
      final bool isReplace = RouteUtil.routeNamesContainNull[
              RouteUtil.routeNamesContainNull.length - 1] ==
          RoutePath.liveRoom;

      try {
        RouteUtil.push(
            fbApi.globalNavigatorKey.currentContext,
            CloseAudienceRoom(
                roomId: getRoomInfoObject!.roomId,
                closeAudienceRoomModel: closeAudienceRoomModel),
            "liveCloseAudienceRoom",
            isReplace: isReplace);
      } catch (e) {
        fbApi.fbLogger.warning('replace route failed.');
      }
    }
  }

  // 主播关闭直播下线
  @override
  Future<void> anchorCloseRoom() async {
    liveValueModel!.liveStatus = LiveStatus.anchorClosesLive;
    eventBus.fire(LiveStatusEvent(LiveStatus.anchorClosesLive));
    isShowOverlayView = false;
    await anchorCloseLive();
    // 统计上报
    await setLiveExit();
    // FB 主播关闭直播上报
    fbApiStopLive();
    // 移除IM消息回调
    fbApiRemoveLiveMsgHandler();
  }

  void showOverlayView(FBLiveEvent event) {
    if (liveValueModel!.liveStatus == LiveStatus.openLiveFailed ||
        liveValueModel!.liveStatus == LiveStatus.networkError ||
        liveValueModel!.liveStatus == LiveStatus.anchorViolation ||
        liveValueModel!.liveStatus == LiveStatus.pushStreamFailed ||
        liveValueModel!.liveStatus == LiveStatus.playStreamFailed) {
    } else {
      isShowOverlayView = true;

      if (!statePage!.widget.isAnchor! &&
          statePage!.widget.liveValueModel!.textureId >= 0 &&
          statePage!.widget.liveValueModel!.liveStatus !=
              LiveStatus.anchorLeave) {
        liveValueModel!.textureId = statePage!.widget.liveValueModel!.textureId;
      }

      rotateScreenExec(context).then((_) {
        floatWindow.open(
          statePage!.context,
          liveValueModel,
          isOutsideApp,
          showSmallWindowNeedDelay: showSmallWindowNeedDelay,
        );

        /// 已经延时过了，下次不延时
        showSmallWindowNeedDelay = false;
      });
    }
  }

  void buttonClickBlock(int index, String text) {
    if (index == 0) {
      // 发送弹幕消息
      fbApiSendLiveMsg(text);
    } else if (index == 1) {
    } else if (index == 3) {
      DialogUtil.confirmEndLiveTip(context, onPressed: () {
        /// 设置"主播主动点结束直播且【确定】"为true
        anchorCloseLiveActively = true;

        /// 执行直播结束逻辑
        anchorCloseRoom();
      });
    }
  }

  //房间信息
  @override
  Future getRoomInfo() async {
    final Map resultData = await Api.getRoomInfo(roomId);
    if (resultData["code"] == 200) {
      // 设置房间信息
      liveValueModel!.roomInfoObject = RoomInfon.fromJson(resultData["data"]);
      // 设置是否主播
      liveValueModel!.isAnchor =
          fbApi.getUserId() == liveValueModel!.roomInfoObject!.anchorId;

      /// 监听FB注册回调
      /// 【2021 12.15】修复【直播相关bugly问题总结 2】
      /// 只有房间基本信息获取了才去监听im，
      /// 防止出现收到消息时[roomInfoObject]为空，导致一些判断出错
      fbApiRegisterMsgHandler();

      //上报用户信息
      if (!statePage!.widget.isOverlayViewPush!) {
        await saveUserInfo(getRoomInfoObject!.serverId);
      }

      /// 获取完信息，左上角刷新，防止不显示头像
      likeClickPreviewBlocModel?.add(likeClickPreviewBlocModel?.count);
      shareType = getRoomInfoObject!.shareType;
      roomBottomBlocModel?.add(true);

      if (getRoomInfoObject!.status == 2 && !statePage!.widget.isAnchor!) {
        /// 【2021 12.29】
        /// live_room_bloc（同obs)中的getRoomInfo获取房间信息中，fbApiEnterLiveRoom事件逻辑需要处理一下。在这同步一下。
        ///
        /// 只在房间状态为正在直播时才去调用进入房间，这样房间不正常时点退出
        /// 则不需要嗲用退出房间；
        ///
        /// 主播在推流状态回调为推流中时才会调用[fbApiEnterLiveRoom]，
        ///
        /// 不管是obs直播还是普通直播观众都是走到的[live_room_bloc]
        /// 所以观众只需要改这里；
        await fbApiEnterLiveRoom();
      }

      /// 8. 获取直播间基础信息 【新增直播带货状态是否开启字段】
      if (resultData['data']['openCommerce']) {
        openCommerce = true;

        /// 不是主播或者是悬浮窗进入才在这调
        /// 主播第一次开播在这调会出现提示未开启
        if (!isAnchor || statePage!.widget.isOverlayViewPush!) {
          await goodsApi(roomId, this);
        }
      } else {
        shopBlocModelQuick?.add(null);
      }
      if (!isAnchor && isOverlayViewPush!) {
        if (liveValueModel!.liveStatus == LiveStatus.anchorClosesLive ||
            liveValueModel!.liveStatus == LiveStatus.anchorViolation ||
            liveValueModel!.liveStatus == LiveStatus.abnormalLogin ||
            liveValueModel!.liveStatus == LiveStatus.kickOutServer) {
          _navigatorToAudienceClosePage();
          return;
        }
      }

      if (getRoomInfoObject?.tips != null &&
          getRoomInfoObject!.tips!.length > 1) {
        chatListBlocModel?.add({});
      }

      if (getRoomInfoObject!.status == 1 || getRoomInfoObject!.status == 2) {
        //浮窗进入直播间 需要判断下是否是主播离开

        if ((!isShowOverlayView || routeHasLive) &&
            liveValueModel!.liveStatus == LiveStatus.anchorLeave) {
          // eventBus.fire(LiveStatusEvent(LiveStatus.anchorLeave));
          setAnchorLeave();
        }

        /// 【2021 12.08】必须是主播才去上报主播尺寸，而且要在网络连接正常后
        if (statePage!.widget.isAnchor!) {
          // 上报主播屏幕尺寸
          await anchorScreenSizePost();
        }

        // 获取当前用户
        await getCurrentUser();

        // 引擎处理
        await engineHandle();

        // 初始化房间
        await setStreamAndTexture();
      } else if (getRoomInfoObject!.status == 3) {
        if (!isShowOverlayView || routeHasLive) {
          offlineStatusHandle();
        }
      } else if (getRoomInfoObject!.status == 4) {
        unawaited(violationsStatusHandle());
      } else if (getRoomInfoObject!.status == 5) {
        timeoutStatusHandle();
      } else if (getRoomInfoObject!.status == 6) {
        unawaited(systemBanStatusHandle());
      }
    } else {
      liveRoomInfoFail();
    }
  }

  @override
  Future setLiveObsStart() async {
    fbApi.fbLogger.info("setLiveObsStart::普通直播不需要调用");
  }

  // 用户端查询房间状态
  @override
  Future<int?> getRoomStatus() async {
    if (liveValueModel!.liveStatus == LiveStatus.anchorViolation &&
        statePage!.widget.isAnchor!) {
      await Future.delayed(const Duration(milliseconds: 300)).then((value) {
        liveWillClose();
      });
      return -1;
    }

    final Map resultData = await Api.getRoomInfo(roomId);
    if (resultData["code"] == 200) {
      final roomInfo = RoomInfon.fromJson(resultData["data"]);
      if (roomInfo.status == 3) {
        liveValueModel!.liveStatus = LiveStatus.anchorClosesLive;
        eventBus.fire(LiveStatusEvent(LiveStatus.anchorClosesLive));

        /// 没必要隐藏主播下线，因为在[_navigatorToAudienceClosePage]内有[popToLive]
        /// [showConfirmDialog] 就是隐藏主播下线等重提示
        // showConfirmDialog(() {
        anchorIsClose = true;
        // 主播主动关闭直播
        if (!isShowOverlayView || routeHasLive) {
          _navigatorToAudienceClosePage();
        }
        // });
      } else if (roomInfo.status == 4 || roomInfo.status == 6) {
        liveValueModel!.liveStatus = LiveStatus.anchorClosesLive;
        eventBus.fire(LiveStatusEvent(LiveStatus.anchorClosesLive));
        anchorIsClose = true;
        // 主播违规，直接跳转关闭直播
        if (!isShowOverlayView || routeHasLive) {
          _navigatorToAudienceClosePage();
        }
      } else if (roomInfo.status == 1 || roomInfo.status == 2) {
        //  房间还存在

        showImageFilter = false;
        showImageFilterBlocModel!.add(showImageFilter);
        isOverlayViewPush = false;
        // if (!isShowOverlayView||routeHasLive) {
        //主播进入更换 '直播中断'
        if (isAnchor) {
        } else {
          // showConfirmDialog(() {
          //   showToast('主播暂时离开了，Ta有可能是去上厕所了，等等吧',
          //       textPadding: EdgeInsets.fromLTRB(FrameSize.px(40),
          //           FrameSize.px(30), FrameSize.px(40), FrameSize.px(30)),
          //       duration: const Duration(days: 1)); // 固定半透明
          // });
          showAnchorLeave = false;
          showAnchorLeaveBlocModel!.add(showAnchorLeave);
          liveValueModel!.liveStatus = LiveStatus.anchorLeave;
          eventBus.fire(LiveStatusEvent(LiveStatus.anchorLeave));
          isOverlayViewPush = false;
        }
        // }
      }
      return roomInfo.status;
    }
    return -1;
  }

  @override
  void negationScreenRotation([bool? value]) {
    if (value != null) {
      isScreenRotation = value;
    } else {
      isScreenRotation = !isScreenRotation;
    }
    // 聊天消息到最底下
    rotationEventBus.fire(ScreenRotationEvent());
    onRefresh();
  }

  @override
  Future<void> close() {
    unawaited(FlutterRotate.unreg());

    fbApi.removeFBLiveEventListener(showOverlayView);
    fbApi.unregisterLiveCloseListener(fanBookCloseListener);
    fbApi.removeWsConnectStatusCallback();

    cancelSubAndStream();

    // IOS主播屏幕共享监听旋转【删除】
    _iosScreenDirectionBusSubs?.cancel();
    _iosScreenDirectionBusSubs = null;

    _goodsAnchorPushBus?.cancel();
    _liveRouteActiveCloseBus?.cancel();
    _orientationBus?.cancel();
    for (final AnimationController c in animationControllerList) {
      c.dispose();
    }
    timer?.cancel();
    // 网络异常计时器取消
    netErrorTimerCancel();
    // 关闭定线上人数查询定时器
    cancelTimer();
    // 关闭常显示弹窗
    closeLoading();
    upLickWidgetList.clear();
    animationControllerList.clear();

    chatListBlocModel?.close();
    pushGoodsLiveRoomModel?.close();
    _batteryStateSubscription?.cancel();

    giftClickBlocModel?.close();
    likeClickBlocModel?.close();
    showScreenSharingBlocModel?.close();
    shopBlocModelQuick?.close();
    couponsBlocModelQuick?.close();
    screenClearBlocModel?.close();
    anchorCloseLiveBtBlocModel?.close();
    if (!isShowOverlayView) {
      liveValueModel!.isScreenSharing = false;
      if (liveValueModel!.isScreenSharing) {
        ZegoExpressEngine.instance
            .stopPublishingStream(channel: ZegoManager.screenChannel); //停止推流
        if (!kIsWeb && Platform.isIOS) {
          ReplayKitLauncher.finishReplayKitBroadcast(
              configProvider.broadcastNotificationName);
          IosScreenPlugin.stopGetData();
        }
      }
      ZegoManager.destroyEngine(
          isAnchor: isAnchor,
          textureID: liveValueModel!.textureId,
          roomId: roomId);

      /// 保证小窗口实体是不存在了，防止下次进入时直接调起了悬浮窗的实体
      floatWindow.close();
    }

    return super.close();
  }

  void hideBackground() {
    showImageFilter = true;
    showImageFilterBlocModel!.add(showImageFilter);
  }

  @override
  bool? get isOverlayViewPushValue => statePage!.widget.isOverlayViewPush;

  @override
  String? get widgetRoomId =>
      statePage!.widget.liveValueModel!.roomInfoObject!.roomId;

  @override
  bool? get widgetIsAnchor => statePage!.widget.isAnchor;

  @override
  bool? get widgetIsFromList => statePage?.widget.isFromList;

  @override
  bool get anchorIsObs => false;
}
