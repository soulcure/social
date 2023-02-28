import 'dart:async';

import 'package:fb_live_flutter/fb_live_flutter.dart';
import 'package:fb_live_flutter/live/bloc/with/live_mix.dart';
import 'package:fb_live_flutter/live/pages/live_room/room_middle_page.dart';
import 'package:fb_live_flutter/live/utils/func/router.dart';
import 'package:fb_live_flutter/live/utils/other/float/float_preview_mode.dart';
import 'package:fb_live_flutter/live/utils/other/float_util.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:zego_express_engine/zego_express_engine.dart';

import '../pages/preview/live_preview.dart';
import '../utils/live/base_bloc.dart';
import '../utils/live/zego_manager.dart';
import '../utils/ui/frame_size.dart';

class PreviewBloc extends BaseAppCubit<int>
    with BaseAppCubitState, SmallWindowMixin {
  PreviewBloc() : super(0);

  /// 画面组件
  Widget? previewViewWidget;

  /// 是否需要显示悬浮窗
  bool isShowOverlay = true;

  /// 是否app外面【退到桌面/其他app/正在运行的应用列表】
  /// android悬浮窗用到。
  bool isOutsideApp = false;

  late State<LivePreviewPage> statePage;

  LiveValueModel? liveValueModel = LiveValueModel();

  FBChatChannel? liveChannel = fbApi.getCurrentChannel();

  /*
  * 初始化
  * */
  Future init(State<LivePreviewPage> state, FBChatChannel? channel) async {
    statePage = state;
    liveChannel = channel ?? fbApi.getCurrentChannel();
    if (statePage.widget.liveValueModel != null) {
      liveValueModel = statePage.widget.liveValueModel!;
    }

    /// 【2021 12.08】
    /// 初始化检测小窗是否打开状态
    /// 解决桌面点击小窗打开app后小窗还存在[OPPO reno2Z 和红米note4X]
    unawaited(FloatUtil.dismissFloat(200));

    if (state.widget.liveValueModel?.textureId == null ||
        state.widget.liveValueModel?.textureId == -1) {
      await ZegoManager.createEngine(state.widget.liveValueModel!.isAnchor);
      await start();
      await ZegoExpressEngine.instance
          .setVideoMirrorMode(ZegoVideoMirrorMode.BothMirror);
      await ZegoExpressEngine.instance
          .useFrontCamera(liveValueModel!.useFrontCamera);
    } else {
      await startPreviewEnd();
    }
  }

  /*
  * 镜像值改变
  * */
  Future onPreviewMirrorValueChanged() async {
    onRefresh();

    liveValueModel!.isMirror = !liveValueModel!.isMirror;
    await checkMirrorMode();
  }

  /*
  * 显示悬浮窗
  * */
  void showOverlayView(BuildContext context) {
    floatPreViewWindow.open(
      statePage.context,
      liveValueModel,
      isOutsideApp,
      showSmallWindowNeedDelay: showSmallWindowNeedDelay,
    );

    /// 已经延时过了，下次不延时
    showSmallWindowNeedDelay = false;
  }

  /*
  * 事件处理
  * */
  Future action(LivePreviewItemType value) async {
    switch (value) {
      case LivePreviewItemType.mirror:
        await onPreviewMirrorValueChanged();
        break;
      default:
        await _flipCamera();
        break;
    }
  }

  /*
  * 摄像头翻转
  * */
  Future _flipCamera() async {
    liveValueModel!.useFrontCamera = !liveValueModel!.useFrontCamera;
    if (!liveValueModel!.useFrontCamera) {
      //非镜像
      liveValueModel!.isMirror = false;
      await ZegoExpressEngine.instance
          .setVideoMirrorMode(ZegoVideoMirrorMode.NoMirror);
    } else {
      liveValueModel!.isMirror = true;
      await ZegoExpressEngine.instance
          .setVideoMirrorMode(ZegoVideoMirrorMode.BothMirror);
    }
    await ZegoExpressEngine.instance
        .useFrontCamera(liveValueModel!.useFrontCamera);
  }

  /*
  * 检查镜像模式
  * */
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
  * 开始初始化
  * */
  Future start() async {
    await ZegoExpressEngine.instance.setVideoConfig(ZegoVideoConfig(
        720, 1280, 720, 1280, 25, 2000, ZegoVideoCodecID.Default, 2));
    await startPreviewEnd();
  }

  /*
  * 开始预览
  * */
  Future startPreviewEnd() async {
    final int screenWidthPx =
        FrameSize.screenW().toInt() * FrameSize.pixelRatio().toInt();
    final int screenHeightPx =
        FrameSize.screenH().toInt() * FrameSize.pixelRatio().toInt();
    if (statePage.widget.liveValueModel?.textureId != null &&
        statePage.widget.liveValueModel?.textureId != -1) {
      await ZegoExpressEngine.instance
          .updateTextureRendererSize(statePage.widget.liveValueModel!.textureId,
              screenWidthPx, screenHeightPx)
          .then((value) {
        if (value) {
          final ZegoCanvas previewCanvas =
              ZegoCanvas.view(statePage.widget.liveValueModel!.textureId);
          previewCanvas.viewMode = ZegoViewMode.AspectFill;
          previewViewWidget =
              Texture(textureId: statePage.widget.liveValueModel!.textureId);
          onRefresh();
        }
      });
    } else {
      await ZegoExpressEngine.instance
          .createTextureRenderer(screenWidthPx, screenHeightPx)
          .then((viewID) async {
        await _startPreview(viewID);
        statePage.widget.liveValueModel!.textureId = viewID;
        previewViewWidget = Texture(textureId: viewID);
        onRefresh();
      });
    }
  }

  /*
  * 开始预览
  * */
  Future _startPreview(int viewID) async {
    final ZegoCanvas canvas = ZegoCanvas.view(viewID);
    canvas.viewMode = ZegoViewMode.AspectFill;

    // 设置音量
    await ZegoExpressEngine.instance.startPreview(canvas: canvas);
  }

  /*
  * 跳转到房间页面
  * */
  Future pushToRoomPage(
      BuildContext context, State<LivePreviewPage> state) async {
    // 设置非obs
    liveValueModel!.setObs(false);
    liveValueModel!.isAnchor = true;

    /// 防止过度修改到直播逻辑
    liveValueModel!.textureId = -1;

    await RouteUtil.push(
        context,
        RoomMiddlePage(
          isFromPreview: true,
          liveValueModel: liveValueModel!,
        ),
        kIsWeb ? "liveRoomWebContainer" : "/liveRoom",
        isReplace: true);
  }
}
