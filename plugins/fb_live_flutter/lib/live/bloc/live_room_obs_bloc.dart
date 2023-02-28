import 'dart:async';
import 'dart:ui';

import 'package:fb_live_flutter/fb_live_flutter.dart';
import 'package:fb_live_flutter/live/api/fblive_provider.dart';
import 'package:fb_live_flutter/live/bloc/logic/coupons_logic.dart';
import 'package:fb_live_flutter/live/bloc/logic/goods_logic.dart';
import 'package:fb_live_flutter/live/bloc/with/live_loading.dart';
import 'package:fb_live_flutter/live/bloc/with/live_mix.dart';
import 'package:fb_live_flutter/live/bloc/with/live_orientation.dart';
import 'package:fb_live_flutter/live/event_bus_model/goods_html_bus.dart';
import 'package:fb_live_flutter/live/event_bus_model/live_status_model.dart';
import 'package:fb_live_flutter/live/event_bus_model/send_gifts_model.dart';
import 'package:fb_live_flutter/live/model/live/obs_rsp_model.dart';
import 'package:fb_live_flutter/live/model/room_infon_model.dart';
import 'package:fb_live_flutter/live/net/api.dart';
import 'package:fb_live_flutter/live/pages/live_room/interface/live_interface.dart';
import 'package:fb_live_flutter/live/pages/live_room/live_room_obs.dart';
import 'package:fb_live_flutter/live/utils/func/router.dart';
import 'package:fb_live_flutter/live/utils/live/base_bloc.dart';
import 'package:fb_live_flutter/live/utils/live/zego_manager.dart';
import 'package:fb_live_flutter/live/utils/live_status_enum.dart';
import 'package:fb_live_flutter/live/utils/other/float/float_mode.dart';
import 'package:fb_live_flutter/live/utils/other/float_plugin.dart';
import 'package:fb_live_flutter/live/utils/other/float_util.dart';
import 'package:fb_live_flutter/live/utils/solve_repeat/solve_repeat_logic.dart';
import 'package:fb_live_flutter/live/utils/theme/my_toast.dart';
import 'package:fb_live_flutter/live/utils/ui/dialog_util.dart';
import 'package:fb_live_flutter/live/utils/ui/frame_size.dart';
import 'package:fb_live_flutter/live/utils/ui/loading.dart';
import 'package:fb_live_flutter/live/widget_common/dialog/sw_dialog.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:oktoast/oktoast.dart';
import 'package:zego_express_engine/zego_express_engine.dart';

import 'logic/live_load_logic.dart';
import 'obs/anchor_not_push.dart';

class LiveRoomObsBloc extends BaseAppCubit<int>
    with
        BaseAppCubitState,
        LiveLoadInterface,
        LiveNetErrorLogic,
        LiveOutSyncLogic,
        AnchorNotPush,
        SmallWindowMixin,
        LiveInterface,
        LiveLoadWith,
        LiveMix,
        LiveLoadLogic,
        GoodsLogic,
        CouponsLogic,
        LiveShopInterface,
        LiveOrientation,
        LiveLogicCommonAbs,
        LiveLogicCommon,
        LiveStatusHandle {
  LiveRoomObsBloc() : super(0);

  State<LiveRoomObs>? statePage;

  bool isShowOBSToast = false; //是否显示【OBS停止推流后】相关提示

  StreamSubscription? _goodsAnchorPushBus;

  Loading? _initLoadingWidget;

  @override
  String get roomId => statePage!.widget.liveValueModel!.getRoomId;

  @override
  bool get mounted => statePage!.mounted;

  String get loadText {
    return "直播间连接中";
  }

  Future<void> init(State<LiveRoomObs> state) async {
    statePage = state;

    liveValueModel = statePage?.widget.liveValueModel ?? LiveValueModel();

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
    if (state.widget.liveValueModel!.textureId > 0) {
      liveValueModel!.textureId = state.widget.liveValueModel!.textureId;
    }

    liveValueModel!.zegoViewMode = ZegoViewMode.AspectFit;

    isShowOverlayView = false;
    isOverlayViewPush = state.widget.isOverlayViewPush;
    if (isOverlayViewPush!) {
      isEnterSuccess = true;
    } else {
      liveValueModel!.playerVideoWidth = 0;
      liveValueModel!.playerVideoHeight = 0;
    }
    liveValueModel!.liveStatus = state.widget.liveValueModel!.liveStatus;

    if (checkLiveStatus(
        navigatorToAudienceClosePage: () {},
        anchorCloseRoomHandle: anchorCloseRoom)) {
      return;
    }

    sendGiftsEventBusValue =
        sendGiftsEventBus.on<SendGitsEvent>().listen((event) {
      sendGiftsClickBlock(event.giftSucModel);
    });

    goodsHtmlBusValue = goodsHtmlBus.on<GoodsHtmlEvenModel>().listen((event) {
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
        openLoading(loadText);
      }

      //获取房间信息
      await getRoomInfo();
    });
  }

  // 引擎处理
  Future engineHandle() async {
    /*
      * 不是悬浮窗进入
      * */
    if (!statePage!.widget.isOverlayViewPush!) {
      await ZegoManager.createEngine(statePage!.widget.isAnchor!);
      // 拉b帧
      await ZegoExpressEngine.instance.enableHardwareDecoder(false);
      await ZegoExpressEngine.instance.enableCheckPoc(false);
      isStartLive = false;
      roomBottomBlocModel!.add(true);
    } else {
      /// 能打开浮窗说明画面是有的，连线也成功过
      isPushed = true;

      /// 悬浮窗进来的直接设置首帧是好了的，防止主播离开状态异常
      isRenderVideoFirstFrame = true;

      liveValueModel!.textureId = statePage!.widget.liveValueModel!.textureId;

      unawaited(refreshLiveView());

      isStartLive = false; //已经开启直播
      isPlaying = false; //已经上报拉流

      chatListBlocModel!.add({});

      /// 主播关闭直播按钮刷新
      anchorCloseLiveBtBlocModel!.add(0);

      await getOnLineCount();

      /// 【APP】从小窗口进入直播间，点赞数没有更新
      /// 【APP】小窗口返回直播间，在线人数显示有误
      ///
      startTimerGetOnline();
    }
  }

  Future refreshLiveView() async {
    // 预览推拉流状态
    int screenWidthPx;

    int screenHeightPx;

    if (liveValueModel!.playerVideoWidth > liveValueModel!.playerVideoHeight) {
      screenWidthPx = liveValueModel!.playerVideoWidth.toInt() *
          FrameSize.pixelRatio().toInt();
      screenHeightPx = liveValueModel!.playerVideoHeight.toInt() *
          FrameSize.pixelRatio().toInt();
    } else {
      // // 预览推拉流状态
      screenWidthPx =
          FrameSize.screenW().toInt() * FrameSize.pixelRatio().toInt();

      screenHeightPx =
          FrameSize.screenH().toInt() * FrameSize.pixelRatio().toInt();
    }

    await ZegoExpressEngine.instance
        .updateTextureRendererSize(
            liveValueModel!.textureId, screenWidthPx, screenHeightPx)
        .then((value) {
      if (value) {
        final ZegoCanvas previewCanvas =
            ZegoCanvas.view(liveValueModel!.textureId);
        previewCanvas.viewMode = liveValueModel!.zegoViewMode;

        ZegoManager.audiencePullStream(
            previewCanvas, statePage!.widget.liveValueModel!.getRoomId);

        livePreviewBlocModel!.add(0);
      }
    });
  }

  Future obsModelInit() async {
    final obsAddressValue =
        await Api.obsAddress(statePage!.widget.liveValueModel!.getRoomId);
    if (obsAddressValue['code'] != 200) {
      return;
    }
    liveValueModel!.obsModel = ObsRspModel.fromJson(obsAddressValue['data']);
  }

  void didPop() {
    /// 如果没有主动关闭直播并且加载直播成功
    if (!isProactiveClose && isEnterSuccess) {
      showOverlayView(FBLiveEvent.gotoChat);
    }

    /// 这里不需要调用[exitReport-退出直播上报]，只有主播会到obs专有页面和逻辑，
    /// 而主播只需调停止直播相关[anchorCloseRoom]方法都已处理
  }

  void _initLoading(String text) {
    Future.delayed(Duration.zero, () async {
      _initLoadingWidget = await Loading.timerToast(context!, text, cancel: () {
        _cancelInitLoadingDialog();
      });
    });
  }

  void _cancelInitLoadingDialog() {
    _initLoadingWidget?.dismiss();
    close();
    isShowOverlayView = false;
    RouteUtil.pop();
  }

  /*
  * 屏幕旋转后刷新状态
  * */
  @override
  Future rotationRefreshState([bool isCancelScreenPush = false]) async {
    // 预览推拉流状态
    int screenWidthPx;

    int screenHeightPx;

    if (liveValueModel!.playerVideoWidth > liveValueModel!.playerVideoHeight) {
      liveValueModel!.zegoViewMode = ZegoViewMode.AspectFit;

      screenWidthPx = liveValueModel!.playerVideoWidth.toInt() *
          FrameSize.pixelRatio().toInt();
      screenHeightPx = liveValueModel!.playerVideoHeight.toInt() *
          FrameSize.pixelRatio().toInt();
    } else {
      // // 预览推拉流状态
      screenWidthPx =
          FrameSize.screenW().toInt() * FrameSize.pixelRatio().toInt();

      screenHeightPx =
          FrameSize.screenH().toInt() * FrameSize.pixelRatio().toInt();
    }
    final first = isScreenRotation ? screenHeightPx : screenWidthPx;
    final second = isScreenRotation ? screenWidthPx : screenHeightPx;
    if (liveValueModel!.textureId == -1) {
      /// 因为obs主播需要没有直播视图时显示背景logo，而且obs主播也只有这一个地方创建视图，所以不需要改变
      await ZegoExpressEngine.instance
          .createTextureRenderer(screenWidthPx, screenHeightPx)
          .then((textureID) {
        final ZegoCanvas previewCanvas = ZegoCanvas.view(textureID);
        liveValueModel!.textureId = textureID;

        previewCanvas.viewMode = liveValueModel!.zegoViewMode;
        ZegoManager.audiencePullStream(
            previewCanvas, statePage!.widget.liveValueModel!.getRoomId);

        livePreviewBlocModel!.add(0);
      });
    } else {
      await ZegoExpressEngine.instance
          .updateTextureRendererSize(liveValueModel!.textureId, first, second)
          .then((value) {
        final ZegoCanvas previewCanvas =
            ZegoCanvas.view(liveValueModel!.textureId);
        previewCanvas.viewMode = liveValueModel!.zegoViewMode;
        ZegoManager.audiencePullStream(
            previewCanvas, statePage!.widget.liveValueModel!.getRoomId);

        if (!livePreviewBlocModel!.isClosed) {
          livePreviewBlocModel!.add(0);
        }
      });
    }

    /// 告诉小窗现在为屏幕共享模式
    eventBus.fire(LiveSizeEvent(liveValueModel!.playerVideoWidth,
        liveValueModel!.playerVideoHeight, liveValueModel!.zegoViewMode));

    /// 告诉原生部分视图更新了
    await FloatPlugin.changeViewMode(liveValueModel!.playerVideoWidth,
        liveValueModel!.playerVideoHeight, liveValueModel!.zegoViewMode);
  }

  // 监听Zegeo公共回调
  void _zegoOnEvent() {
    // 房间流更新回调【流新增、流删除】
    // 【APP】第一次：IOS端OBS推流直播，私聊观众，然后点击右侧小窗口回到直播间，主播端黑屏
    livePreviewBlocModel!.add(0);
    ZegoExpressEngine.onRoomStreamUpdate =
        (roomID, updateType, streamList, extendedData) {
      fbApi.fbLogger.info(
          'onRoomStreamUpdate roomID:$roomID updateType:$updateType streamList:$streamList');
      if (updateType == ZegoUpdateType.Delete) {
        checkStateIsClose();
      } else if (updateType == ZegoUpdateType.Add) {
        liveValueModel!.liveStatus = LiveStatus.playStreamSuccess;
        eventBus.fire(LiveStatusEvent(LiveStatus.playStreamSuccess));

        if (!statePage!.widget.isAnchor!) {
          isOverlayViewPush = false;
        }

        /// 流更新后拉流
        addStreamAfterPull(statePage!.widget.liveValueModel!.getRoomId);
      }
    };
    // 房间状态回调
    ZegoExpressEngine.onRoomStateUpdate =
        (roomID, state, errorCode, extendedData) {
      fbApi.fbLogger.info(
          'onRoomStateUpdate roomID:$roomID state:$state errorCode:$errorCode extendedData:$extendedData');

      if (state == ZegoRoomState.Connected) {
        /// 判断连线【异常恢复检测】
        /// 只有5秒倒计时完了才开始再次检测，里面有判断
        /// 当网络断开重连的时候也会触发
        restoreCheckAttachment(
            !isShowOverlayView || routeHasLive, statePage!.mounted);

        /// obs连接成功，开始倒计时判断连线
        startAttachment(!isShowOverlayView || routeHasLive, statePage!.mounted);

        /// 弱网恢复网连接成功后，右滑小窗口会消失 @王增阳
        liveValueModel!.liveStatus = LiveStatus.pushStreamSuccess;
        eventBus.fire(LiveStatusEvent(LiveStatus.pushStreamSuccess));

        // 连接成功后调用obs直播开始接口
        anchorStartLive();
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

  // 监听拉流回调
  void _zegoOnPullEvent() {
    // 拉流分辨率变更通知
    ZegoExpressEngine.onPlayerVideoSizeChanged = (streamID, width, height) {
      liveValueModel!.playerVideoWidth = width.toDouble();
      liveValueModel!.playerVideoHeight = height.toDouble();

      rotationRefreshState();
    };

    // 拉流端渲染完视频首帧【第一帧】回调。
    ZegoExpressEngine.onPlayerRenderVideoFirstFrame = (streamID) {
      playerRenderVideoFirstFrame();

      /// 【2021 11.26】检测到流添加且能拉成功且第一帧能渲染，连线状态更新为主播已推流
      ///  由于创建直播间默认就有一条流，鹅且能拉，所以只能在第一帧来判断主播推出去的流是否真实的了
      setPushed();
    };

    // 拉流质量回调
    ZegoExpressEngine.onPlayerQualityUpdate = (streamID, quality) {
      netErrorCall(quality.level);
      handleRePull(quality.avTimestampDiff, onComplete: refreshLiveView);
    };

    // 拉流状态回调
    ZegoExpressEngine.onPlayerStateUpdate =
        (streamID, state, errorCode, extendedData) {
      fbApi.fbLogger.info(
          "ZegoExpressEngine.onPlayerStateUpdate streamID:$streamID,state:$state,errorCode:$errorCode ");
      // 调用拉流接口成功后，当拉流器状态发生变更，如出现网络中断导致推流异常等情况，SDK在重试拉流的同时，会通过该回调通知
      if (state == ZegoPlayerState.NoPlay) {
        // 主播被禁播
        if (errorCode == 1004099) {
          liveValueModel!.liveStatus = LiveStatus.anchorViolation;
          eventBus.fire(LiveStatusEvent(LiveStatus.anchorViolation));
          // 主播违规，直接跳转关闭直播
          // _navigatorToAudienceClosePage();
        } else if (errorCode == 1002050) {
          fbApi.fbLogger.info("onPlayerStateUpdate::状态码为1002050不处理，公共回调自然会处理");
        } else if (errorCode != 0) {
          playFailStatusHandle();
        }
      } else if (state == ZegoPlayerState.PlayRequesting) {
        // 重试拉流
      } else if (state == ZegoPlayerState.Playing) {
        liveValueModel!.liveStatus = LiveStatus.playStreamSuccess;
        eventBus.fire(LiveStatusEvent(LiveStatus.playStreamSuccess));

        /// 变更为拉流首帧后才去除loading 【2021 11.12】
        // closeLoading();

        // 通知服务端
        if (isPlaying) {
          // 上报服务器
          if (!isAnchor) setLiveEnter();
          // 通知FB[防止调用了两次进入房间，先注释]
          // fbApiEnterLiveRoom();
          isPlaying = false;
        }
        // 拉流成功，开启定时器轮询线上人数
        startTimerGetOnline();

        // 外部推流改变服务端直播状态
        liveValueModel!.liveStatus = LiveStatus.pushStreamSuccess;
        eventBus.fire(LiveStatusEvent(LiveStatus.pushStreamSuccess));

        ZegoExpressEngine.instance.setStreamExtraInfo("obs 推流");
        // 推流成功，开启定时器轮询线上人数
        startTimerGetOnline();
      }
    };
  }

  // 设置推拉流及视频画面
  @override
  Future setStreamAndTexture() async {
    // 不是悬浮窗进入-登录房间
    if (!isOverlayViewPush!) {
      await ZegoManager.zegoLoginRoom(liveValueModel!.zegoTokenModel!);
    }
    if (!statePage!.widget.isOverlayViewPush!) {
      /// 【2021 12.09】只调用【拉流回调事件】，不去创建视图，当流添加会拉流，
      /// 在尺寸变更之后才去刷新拉流端视图。
      _zegoOnPullEvent();
    }
    // 监听房间回调状态
    _zegoOnEvent();
  }

  // 主播关闭直播下线
  @override
  Future<void> anchorCloseRoom() async {
    await anchorCloseRoomHandle(call: () async {
      await anchorCloseLive();
    });
  }

  // 主播关闭直播下线[事件]
  Future<void> anchorCloseRoomHandle({VoidCallback? call}) async {
    liveValueModel!.liveStatus = LiveStatus.anchorClosesLive;
    eventBus.fire(LiveStatusEvent(LiveStatus.anchorClosesLive));
    isShowOverlayView = false;
    if (call != null) call();
    // 统计上报
    await setLiveExit();
    // FB 主播关闭直播上报
    fbApiStopLive();
    // 移除IM消息回调
    fbApiRemoveLiveMsgHandler();
  }

  // 监听到直播结束
  Future _listeningClose() async {
    if (!anchorCloseLiveActively) {
      await anchorCloseRoomHandle(call: await anchorCloseLive());
    }
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

      floatWindow.open(
        statePage!.context,
        liveValueModel,
        isOutsideApp,
        showSmallWindowNeedDelay: showSmallWindowNeedDelay,

        /// 不显示关闭按钮，因为能走到这必是obs主播
        isShowClose: false,
      );

      /// 已经延时过了，下次不延时
      showSmallWindowNeedDelay = false;
    }
  }

  void buttonClickBlock(int index, String text) {
    if (index == 0) {
      // 发送弹幕消息
      fbApiSendLiveMsg(text);
    } else if (index == 1) {
    } else if (index == 3) {
      /// 打开主播结束对话框
      dismissAllToast();
      DialogUtil.confirmEndLiveTip(context, onPressed: () {
        /// 设置"主播主动点结束直播且【确定】"为true
        anchorCloseLiveActively = true;

        anchorCloseRoom();
      }).then((value) {
        /// 【2021 12.1】关闭主播结束对话框-二次确认的重提示应该盖住toast的提示。

        /// 判断连线【异常恢复检测】
        /// 只有5秒倒计时完了才开始再次检测，里面有判断
        /// 当网络断开重连的时候也会触发
        restoreCheckAttachment(
            !isShowOverlayView || routeHasLive, statePage!.mounted);
      });
    }
  }

  //房间信息
  @override
  Future getRoomInfo() async {
    final Map resultData =
        await Api.getRoomInfo(statePage!.widget.liveValueModel!.getRoomId);
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
      likeClickPreviewBlocModel!.add(likeClickPreviewBlocModel!.count);
      shareType = getRoomInfoObject!.shareType;
      roomBottomBlocModel!.add(true);

      /// 8. 获取直播间基础信息 【新增直播带货状态是否开启字段】
      if (resultData['data']['openCommerce']) {
        openCommerce = true;

        /// 不是主播或者是悬浮窗进入才在这调
        /// 主播第一次开播在这调会出现提示未开启
        if (!isAnchor || statePage!.widget.isOverlayViewPush!) {
          await goodsApi(statePage!.widget.liveValueModel!.getRoomId, this);
        }
      } else {
        shopBlocModelQuick!.add(null);
      }
      if (!isAnchor && isOverlayViewPush!) {
        if (liveValueModel!.liveStatus == LiveStatus.anchorClosesLive ||
            liveValueModel!.liveStatus == LiveStatus.anchorViolation ||
            liveValueModel!.liveStatus == LiveStatus.abnormalLogin ||
            liveValueModel!.liveStatus == LiveStatus.kickOutServer) {
          await _listeningClose();
          return;
        }
      }

      if (getRoomInfoObject?.tips != null &&
          getRoomInfoObject!.tips!.length > 1) {
        chatListBlocModel!.add({});
      }

      if (getRoomInfoObject!.status == 1 || getRoomInfoObject!.status == 2) {
        //浮窗进入直播间 需要判断下是否是主播离开

        if ((!isShowOverlayView || routeHasLive) &&
            liveValueModel!.liveStatus == LiveStatus.anchorLeave) {
          // eventBus.fire(LiveStatusEvent(LiveStatus.anchorLeave));
          showConfirmDialog(() {
            if (!isAnchor) {
              myToastLong('主播暂时离开了，Ta有可能是去上厕所了，等等吧',
                  duration: const Duration(days: 1)); // 固定半透明
            }
          });
        }

        /// 【2021 12.08】只有在有网络情况才去请求接口
        // 如果没有直播参数模型，再次请求接口获取
        if (liveValueModel!.obsModel == null) {
          await obsModelInit();
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

  // 上报当前角色开始Obs直播【必须是主播】
  @override
  Future setLiveObsStart() async {
    if (!isAnchor) {
      return;
    }
    final _obsStartLiveValue =
        await Api.obsStartLive(statePage!.widget.liveValueModel!.getRoomId);
    if (_obsStartLiveValue['code'] != 200) {
      _initLoadingWidget?.dismiss();
      await confirmSwDialog(context,
          text: _obsStartLiveValue['msg'],
          okText: '重试',
          cancelText: '退出', onPressed: () {
        _initLoading(loadText);
        setLiveObsStart();

        /// 【2021 12.07】重提示，退出按钮，不能退到列表
      }, onCancel: goBack);
    }
    await getOnLineCount(); //进入直播后查询在线人数
  }

  // 用户端查询房间状态
  Future<int?> getRoomStatus() async {
    final Map resultData =
        await Api.getRoomInfo(statePage!.widget.liveValueModel!.getRoomId);
    if (resultData["code"] == 200) {
      final roomInfo = RoomInfon.fromJson(resultData["data"]);
      if (roomInfo.status == 3) {
        liveValueModel!.liveStatus = LiveStatus.anchorClosesLive;
        eventBus.fire(LiveStatusEvent(LiveStatus.anchorClosesLive));
        showConfirmDialog(() {
          anchorIsClose = true;
          // 主播主动关闭直播
          if (!isShowOverlayView || routeHasLive) {
            _listeningClose();
          }
        });
      } else if (roomInfo.status == 4 || roomInfo.status == 6) {
        liveValueModel!.liveStatus = LiveStatus.anchorClosesLive;
        eventBus.fire(LiveStatusEvent(LiveStatus.anchorClosesLive));
        anchorIsClose = true;
        // 主播违规，直接跳转关闭直播
        if (!isShowOverlayView || routeHasLive) {
          await _listeningClose();
        }
      } else if (roomInfo.status == 1 || roomInfo.status == 2) {
        //  房间还存在

        isOverlayViewPush = false;

        liveValueModel!.liveStatus = LiveStatus.anchorLeave;
        eventBus.fire(LiveStatusEvent(LiveStatus.anchorLeave));
      }
      return roomInfo.status;
    }
    return -1;
  }

  @override
  void negationScreenRotation([bool? value]) {}

  @override
  Future<void> close() {
    fbApi.removeFBLiveEventListener(showOverlayView);
    fbApi.unregisterLiveCloseListener(fanBookCloseListener);
    fbApi.removeWsConnectStatusCallback();

    cancelSubAndStream();

    _goodsAnchorPushBus?.cancel();
    for (final AnimationController c in animationControllerList) {
      c.dispose();
    }

    // 网络异常计时器取消
    netErrorTimerCancel();

    /// 屏幕共享才有的
    // timer?.cancel();
    // 关闭定线上人数查询定时器
    cancelTimer();
    // 关闭常显示弹窗
    closeLoading();
    upLickWidgetList.clear();
    animationControllerList.clear();

    chatListBlocModel?.close();
    pushGoodsLiveRoomModel?.close();

    giftClickBlocModel?.close();
    likeClickBlocModel?.close();
    shopBlocModelQuick?.close();
    couponsBlocModelQuick?.close();
    screenClearBlocModel?.close();
    anchorCloseLiveBtBlocModel?.close();

    if (!isShowOverlayView) {
      ZegoManager.destroyEngine(
          isAnchor: isAnchor,
          textureID: liveValueModel!.textureId,
          roomId: statePage!.widget.liveValueModel!.getRoomId);

      /// 保证小窗口实体是不存在了，防止下次进入时直接调起了悬浮窗的实体
      floatWindow.close();
    }

    return super.close();
  }

  /*
  * 检测是否关闭
  * */
  void checkStateIsClose() {
    // 查询房间状态xxxx
    getRoomStatus();
    // 拉流端手动停止拉流
    ZegoExpressEngine.instance
        .stopPlayingStream(statePage!.widget.liveValueModel!.getRoomId);
  }

  @override
  Future checkMirrorMode() async {
    fbApi.fbLogger.info("obs不支持镜像");
  }

  @override
  bool? get isOverlayViewPushValue => statePage!.widget.isOverlayViewPush;

  @override
  String? get widgetRoomId => statePage!.widget.liveValueModel!.getRoomId;

  @override
  bool? get widgetIsAnchor => statePage!.widget.isAnchor;

  @override
  bool? get widgetIsFromList => statePage?.widget.isFromList;

  @override
  bool get anchorIsObs => true;
}
