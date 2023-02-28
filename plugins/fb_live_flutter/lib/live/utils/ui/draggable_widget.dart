import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:fb_live_flutter/live/bloc/with/live_mix.dart';
import 'package:fb_live_flutter/live/bloc/with/screen_with.dart';
import 'package:fb_live_flutter/live/event_bus_model/community_llive_bus.dart';
import 'package:fb_live_flutter/live/event_bus_model/ios_screen_even.dart';
import 'package:fb_live_flutter/live/event_bus_model/live/ios_screen_direction_model.dart';
import 'package:fb_live_flutter/live/event_bus_model/live/window_direction_model.dart';
import 'package:fb_live_flutter/live/pages/screen_sharing/screen_sharing_page.dart';
import 'package:fb_live_flutter/live/utils/other/float/float_mode.dart';
import 'package:fb_live_flutter/live/utils/other/ios_screen_util.dart';
import 'package:fb_live_flutter/live/widget_common/flutter/click_event.dart';
import 'package:fb_live_flutter/live/widget_common/image/sw_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zego_express_engine/zego_express_engine.dart';

import '../../event_bus_model/close_live_model.dart';
import '../../event_bus_model/live_status_model.dart';
import '../../model/room_infon_model.dart';
import '../../model/zego_token_model.dart';
import '../../net/api.dart';
import '../live/zego_manager.dart';
import '../live_status_enum.dart';
import '../mix/webview_route_mix.dart';
import '../other/fb_api_model.dart';
import 'frame_size.dart';

class DraggableView extends StatefulWidget {
  final LiveValueModel? liveValueModel;

  const DraggableView(this.liveValueModel);

  @override
  DraggableViewState createState() => DraggableViewState();
}

class DraggableViewState extends State<DraggableView>
    with WidgetsBindingObserver, ScreenWithAbs, ScreenWith, WebViewRouteMix {
  double viewWidth = FrameSize.px(90); //浮窗中画面的宽
  double viewHeight = FrameSize.px(139); //浮窗中画面的高

  /// 小窗口存储的画面宽度
  double? playerVideoWidth;

  /// 小窗口存储的画面高度
  double? playerVideoHeight;

  int? _previewViewID;
  bool _showImageFilter = true; //模糊图层默认隐藏
  String? _liveStatus; //流状态提示
  StreamSubscription? _liveStatusSubscription;

  /// 直播尺寸变更-事件监听
  StreamSubscription? _liveSizeSubscription;
  StreamSubscription? _liveRoomChartSubscription;
  StreamSubscription? _closeLiveSubscription;
  StreamSubscription? _windowDirectionBus;
  StreamSubscription? _initiativeCloseLiveSubscription;

  LiveStatus? currentLiveStatus;

  Offset moveOffset = Offset(FrameSize.screenW() - FrameSize.px(90),
      FrameSize.screenH() / 2 - FrameSize.px(139) / 2);

  LiveValueModel? liveValueModel;

  // 【主播】【iOS】【屏幕共享】横竖屏转换处理-监听器
  StreamSubscription? _iosScreenDirectionBusSubs;

  bool get isShowHomeIcon {
    return (liveValueModel!.isScreenSharing) && liveValueModel!.isAnchor;
  }

  static double defTopOffset = FrameSize.winHeight() -
      FrameSize.padBotH() -
      FrameSize.px(139) -
      (148 / 2).px;

  double _left = FrameSize.screenW() - FrameSize.px(90);
  double _top = FrameSize.screenH() / 2 - FrameSize.px(139) / 2;

  StreamSubscription? _batteryStateSubscription;

  ZegoViewMode viewMode = ZegoViewMode.AspectFill;

  /// 可直接使用的直播画面宽度
  double get usePlayerVideoWidth {
    return playerVideoWidth ?? liveValueModel!.playerVideoWidth;
  }

  /// 可直接使用的直播画面高度
  double get usePlayerVideoHeight {
    return playerVideoHeight ?? liveValueModel!.playerVideoHeight;
  }

  @override
  void initState() {
    liveValueModel = widget.liveValueModel!;

    // 开始监听eventBus
    _iosScreenDirectionBusSubs =
        iosScreenDirectionBus.on<IosScreenDirectionModel>().listen((event) {
      IosScreenUtil.changeHandle(event, liveValueModel);
    });

    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);

    /// 初始化赋值当前页存储的画面宽高为父级的
    playerVideoWidth = liveValueModel!.playerVideoWidth;
    playerVideoHeight = liveValueModel!.playerVideoHeight;

    viewMode = liveValueModel!.zegoViewMode;

    /// 初始化画面视图
    refreshViewInit();

    if (isShowHomeIcon) {
      _left = liveValueModel!.overlayHomeLeft;
      _top = liveValueModel!.overlayHomeTop;
    } else {
      _left = liveValueModel!.overlayLeft;
      _top = liveValueModel!.overlayTop;
    }
    currentLiveStatus = liveValueModel!.liveStatus;

    if (currentLiveStatus != null) {
      _getLiveStatus(currentLiveStatus);
    }

    _batteryStateSubscription = iosScreenBus.on().listen((event) {
      if (event == "ScreenOpened" && !isScreenSharing) {
        ZegoExpressEngine.instance.enableCamera(false);
        liveValueModel!.isScreenSharing = true;
        setState(() {});
      } else if (event == "ScreenClosed" && isScreenSharing) {
        /// 这里面会开启摄像头
        ZegoManager.changeLive(liveValueModel);

        ZegoExpressEngine.instance.muteMicrophone(false);
        liveValueModel!.isScreenSharing = false;

        final ZegoVideoMirrorMode mirrorMode = liveValueModel!.isMirror
            ? ZegoVideoMirrorMode.BothMirror
            : ZegoVideoMirrorMode.NoMirror;
        ZegoExpressEngine.instance.setVideoMirrorMode(mirrorMode);
        setState(() {});
      }
    });

    WidgetsBinding.instance!.addObserver(this);

    _liveStatusSubscription = eventBus.on<LiveStatusEvent>().listen((event) {
      _getLiveStatus(event.status);
    });

    /// 监听画面尺寸变更【2021 11.24】
    ///
    /// "当直播窗缩小后，直播画面被压缩，严重变形。【必现】
    /// 机型：苹果11、苹果12
    /// （安卓手机显示正常）"
    _liveSizeSubscription = eventBus.on<LiveSizeEvent>().listen((event) {
      playerVideoWidth = event.width;
      playerVideoHeight = event.height;

      viewMode = event.viewMode;

      refreshView();
    });

    _windowDirectionBus =
        windowDirectionBus.on<WindowDirectionModel>().listen((event) {
      if (mounted) setState(() {});
    });
    _initiativeCloseLiveSubscription = initiativeCloseLiveEventBus
        .on<InitiativeCloseLiveEvent>()
        .listen((event) => floatWindow.close());
    _closeLiveSubscription =
        closeEventBus.on<CloserLiveEvent>().listen((event) {
      floatWindow.eventBusCloseLive(event);
    });
    super.initState();
  }

  /*
  * 初始化画面视图【初始化时调用，因为是创建视图】
  * */
  void refreshViewInit() {
    final int widthPx = viewWidth.toInt() * FrameSize.pixelRatio().toInt();
    final int heightPx = viewHeight.toInt() * FrameSize.pixelRatio().toInt();

    ZegoExpressEngine.instance
        .createTextureRenderer(widthPx, heightPx)
        .then((textureId) {
      /// 赋值视图id为新创建的
      _previewViewID = textureId;

      textureHandle();
    });

    /// 防止收到小窗尺寸变更后小窗ui没更新
    if (mounted) setState(() {});
  }

  /*
  * 刷新画面显示【刷新时使用，更新视图】
  * */
  void refreshView() {
    if (_previewViewID == null) {
      /// 如果刷新视图时视图id还是为空，说明创建的时候失败了，直接去重新创建
      refreshViewInit();
      return;
    }

    final int widthPx = viewWidth.toInt() * FrameSize.pixelRatio().toInt();
    final int heightPx = viewHeight.toInt() * FrameSize.pixelRatio().toInt();

    ZegoExpressEngine.instance
        .updateTextureRendererSize(_previewViewID!, widthPx, heightPx)
        .then((textureId) {
      textureHandle();
    });

    /// 防止收到小窗尺寸变更后小窗ui没更新
    if (mounted) setState(() {});
  }

  /*
  * texture处理
  * */
  void textureHandle() {
    final ZegoCanvas previewCanvas = ZegoCanvas.view(_previewViewID!);

    /// 【2021 12.28】
    /// 【APP】ios机型进行obs直播，主播小窗口白屏 [2行]
    previewCanvas.viewMode =
        liveValueModel!.getIsObs ? ZegoViewMode.AspectFit : viewMode;
    if (liveValueModel!.isAnchor && !liveValueModel!.getIsObs) {
      ZegoExpressEngine.instance.startPreview(canvas: previewCanvas);
    } else {
      ZegoManager.audiencePullStream(previewCanvas, liveValueModel!.getRoomId);
    }
  }

  void _getLiveStatus(LiveStatus? liveStatus) {
    switch (liveStatus) {
      case LiveStatus.openLiveSuccess: //开播成功

        break;
      case LiveStatus.openLiveFailed: //开播失败
        break;
      case LiveStatus.anchorClosesLive: //主播关闭直播

        setState(() {
          currentLiveStatus = LiveStatus.anchorClosesLive;
          _showImageFilter = false;
          _liveStatus = '直播结束';
        });
        break;
      case LiveStatus.anchorViolation: //主播违规关闭直播
        setState(() {
          currentLiveStatus = LiveStatus.anchorViolation;
          _showImageFilter = false;
          if (liveValueModel!.isAnchor) {
            _liveStatus = '直播违规关闭';
          } else {
            _liveStatus = '直播结束';
          }
        });
        break;
      case LiveStatus.anchorLeave: //主播离开
        setState(() {
          currentLiveStatus = LiveStatus.anchorLeave;
          _showImageFilter = false;
          _liveStatus = '主播暂时离开';
        });
        break;
      case LiveStatus.playStreamSuccess: //拉流成功
        setState(() {
          currentLiveStatus = LiveStatus.playStreamSuccess;
          _showImageFilter = true;
          _liveStatus = '';
        });
        break;

      ///  【APP】观众弱网看直播小窗口模式下不应该提示网络断开，没有画面[11.15]
      case LiveStatus.networkError: //网络问题，无法开启直播 //网络连接不稳定 //网络不稳定 //网络错误
        break;
      case LiveStatus.abnormalLogin: //账号异地登录
        setState(() {
          currentLiveStatus = LiveStatus.abnormalLogin;
          _showImageFilter = false;
          _liveStatus = '账号异地登录';
        });
        break;
      case LiveStatus.pushStreamFailed: //推流失败
        setState(() {
          currentLiveStatus = LiveStatus.pushStreamFailed;
          _showImageFilter = false;
          _liveStatus = '直播失败';
        });
        break;
      case LiveStatus.pushStreamSuccess: //推流成功
        setState(() {
          currentLiveStatus = LiveStatus.pushStreamSuccess;
          _showImageFilter = true;
          _liveStatus = '';
        });
        break;
      case LiveStatus.playStreamFailed: //拉流失败
        setState(() {
          currentLiveStatus = LiveStatus.playStreamFailed;
          _showImageFilter = false;
          _liveStatus = '拉流失败';
        });
        break;
      case LiveStatus.kickOutServer:
        setState(() {
          currentLiveStatus = LiveStatus.kickOutServer;
          _showImageFilter = false;
          if (liveValueModel!.isAnchor) {
            _liveStatus = '被踢出服务器';
          } else {
            _liveStatus = '直播结束';
          }
        });
        break;
      default:
        break;
    }
  }

  @override
  void dispose() {
    // IOS主播屏幕共享监听旋转【删除】
    _iosScreenDirectionBusSubs?.cancel();
    _iosScreenDirectionBusSubs = null;

    _liveStatusSubscription?.cancel();
    _liveStatusSubscription = null;

    /// 画面尺寸变更事件监听器销毁
    _liveSizeSubscription?.cancel();
    _liveSizeSubscription = null;
    _closeLiveSubscription?.cancel();
    _closeLiveSubscription = null;
    _liveRoomChartSubscription?.cancel();
    _liveRoomChartSubscription = null;

    _initiativeCloseLiveSubscription?.cancel();
    _initiativeCloseLiveSubscription = null;

    _windowDirectionBus?.cancel();
    _windowDirectionBus = null;
    WidgetsBinding.instance!.removeObserver(this);
    _batteryStateSubscription?.cancel();
    timer?.cancel();

    /// 销毁小窗口视图
    ZegoExpressEngine.instance.destroyTextureRenderer(_previewViewID!);

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      /// 【2021 11.25】优化小窗口位置（安卓苹果统一）
      /// 直播UI验收11.16 - 飞书云文档   【商品分享】安卓、IOS分享商品，都会出现挡住
      top: _top,
      left: _left,
      child: GestureDetector(
        // 移动中
        onPanUpdate: (details) {
          setState(() {
            if (isShowHomeIcon) {
              _top = details.globalPosition.dy;
              _left = details.globalPosition.dx;
            } else {
              _left = details.globalPosition.dx - viewWidth / 2;
              _top = details.globalPosition.dy - viewHeight / 2;
              if (_left <= 0) {
                _left = 0;
              } else if (_left >= FrameSize.screenW() - viewWidth) {
                _left = FrameSize.screenW() - viewWidth;
              }

              if (_top <= FrameSize.padTopH() + 64) {
                _top = FrameSize.padTopH() + 64;
              } else if (_top >=
                  FrameSize.screenH() - FrameSize.padBotH() - viewWidth * 2) {
                _top =
                    FrameSize.screenH() - FrameSize.padBotH() - viewWidth * 2;
              }
            }
          });
        },
        // 移动结束
        onPanEnd: (details) {
          setState(() {
            if (isShowHomeIcon) {
              if (_top <= (FrameSize.padTopH() + 5.5.px)) {
                _top = FrameSize.padTopH() + 5.5.px;
              } else if (_top >=
                  FrameSize.screenH() - (FrameSize.padBotH() * 2)) {
                _top = FrameSize.screenH() - (FrameSize.padBotH() * 2);
              }
            }
            if (_left + viewWidth / 2 < FrameSize.screenW() / 2) {
              _left = 0;
            } else {
              if (isShowHomeIcon) {
                _left = FrameSize.screenW() - 32.px;
              } else {
                _left = FrameSize.screenW() - viewWidth;
              }
            }
          });

          /// 设置全局存储位置数据
          if (isShowHomeIcon) {
            liveValueModel!.overlayHomeLeft = _left;
            liveValueModel!.overlayHomeTop = _top;
          } else {
            liveValueModel!.overlayLeft = _left;
            liveValueModel!.overlayTop = _top;
          }
        },

        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Material(
            child: StatefulBuilder(
              key: contentStateKey,
              builder: (context, _) {
                return _draggableView(context);
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _draggableView(BuildContext context) {
    if (isWebViewRoute) {
      return Container();
    }
    if (isShowHomeIcon) {
      return ClickEvent(
        onTap: () async {
          floatWindow.floatClick();
        },
        child: Container(
          width: 32.px,
          height: 32.px,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xff000000).withOpacity(0.6),
            borderRadius: const BorderRadius.all(Radius.circular(5)),
          ),
          child: SwImage(
            "assets/live/main/float_screen_home.png",
            width: 16.px,
            height: 16.px,
          ),
        ),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: ClickEvent(
        onTap: () async {
          floatWindow.floatClick();
        },
        child: Container(
          padding: const EdgeInsets.all(2),
          width: viewWidth,
          height: viewHeight,
          child: Stack(
            children: [
              SizedBox(width: viewWidth, height: viewHeight),
              if (liveValueModel!.isScreenSharing)
                ScreenSharingPage(
                    width: viewWidth, height: viewHeight, isOverlay: true)
              else if (liveValueModel!.screenDirection == "V")
                ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: () {
                      if (_previewViewID == null) {
                        return const Center(
                          child: SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        );
                      }
                      return Texture(textureId: _previewViewID!);
                    }())
              else
                Center(
                  child: () {
                    Widget resultView = Texture(textureId: _previewViewID!);
                    resultView = SizedBox(
                      width:
                          viewHeight * playerVideoWidth! / playerVideoHeight!,

                      /// 如果画面需要旋转且屏幕旋转横屏了，宽度为屏幕最新宽度，防止出现状态栏导致出错
                      height: viewWidth,
                      child: resultView,
                    );

                    final double rotate =
                        liveValueModel!.screenDirection != "RH"
                            ? math.pi / 2
                            : -(math.pi / 2);
                    return resultView = UnconstrainedBox(
                      child: Transform.rotate(angle: rotate, child: resultView),
                    );
                  }(),
                ),
              Offstage(
                offstage: _showImageFilter,
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    width: viewWidth,
                    height: viewHeight,
                    alignment: Alignment.center,
                    padding: const EdgeInsets.only(left: 6, right: 6),
                    child: Text(
                      _liveStatus ?? '',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.normal,
                        color: Colors.white,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 0,
                child: Container(
                  width: viewWidth - 4,
                  height: 30,
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(8),
                        topRight: Radius.circular(8)),
                    gradient: LinearGradient(
                      begin: Alignment.topRight,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.black38,
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 0,
                right: 0,

                /// IOS主播悬浮窗不显示关闭按钮【2021 10.27】
                child: isAnchor ? Container() : _closeBtn(),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _closeBtn() {
    return InkWell(
      onTap: floatWindow.close,
      child: Container(
        width: FrameSize.px(20),
        height: FrameSize.px(20),
        margin: const EdgeInsets.all(6),
        padding: const EdgeInsets.all(5),
        child: const Image(
            image: AssetImage("assets/live/LiveRoom/close_btn.png")),
      ),
    );
  }

  ///切换到前后台
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    checkScreen(state, null, liveValueModel);

    switch (state) {
      case AppLifecycleState.inactive:
        // 处于这种状态的应用程序应该假设它们可能在任何时候暂停。
        break;
      case AppLifecycleState.resumed: //从后台切换前台，界面可见
        break;
      case AppLifecycleState.paused: // 界面不可见，后台
        break;
      case AppLifecycleState.detached: // APP结束时调用
        if (liveValueModel!.isAnchor) {
          ZegoExpressEngine.instance.logoutRoom(liveValueModel!.getRoomId);
        }
        break;
    }
  }

  @override
  bool get isAnchor => liveValueModel!.isAnchor;

  bool get isScreenSharing => liveValueModel!.isScreenSharing;

  ZegoTokenModel? get zegoTokenModel => liveValueModel!.zegoTokenModel;

  //查询房间状态
  @override
  Future<int?> getRoomStatus() async {
    final Map resultData = await Api.getRoomInfo(liveValueModel!.getRoomId);
    if (resultData["code"] == 200) {
      final roomInfo = RoomInfon.fromJson(resultData["data"]);
      if (roomInfo.status == 3) {
        // 主播主动关闭直播
      } else if (roomInfo.status == 5) {
        // 超时关闭
      } else if (roomInfo.status == 4 || roomInfo.status == 6) {
        await FbApiModel.violationsAction(roomInfo.roomId);
        // 主播违规，直接跳转关闭直播
      } else if (roomInfo.status == 1 || roomInfo.status == 2) {
        //房间还在
      }
      return roomInfo.status;
    }
    return -1;
  }
}
