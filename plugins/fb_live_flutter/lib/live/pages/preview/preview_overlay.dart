import 'dart:io';

import 'package:fb_live_flutter/fb_live_flutter.dart';
import 'package:fb_live_flutter/live/bloc/with/live_mix.dart';
import 'package:fb_live_flutter/live/utils/mix/webview_route_mix.dart';
import 'package:fb_live_flutter/live/utils/other/float/float_preview_mode.dart';
import 'package:fb_live_flutter/live/utils/ui/frame_size.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zego_express_engine/zego_express_engine.dart';

class OverlayPreView {
  static double viewHeight = FrameSize.px(138.5); //浮窗中画面的高
  static OverlayEntry? overlayEntry;

  static void showOverlayEntry({
    required BuildContext context,
    final bool showSmallWindowNeedDelay = false,
    LiveValueModel? liveValueModel,
  }) {
    /// 一定要延时，否则：
    /// "iOS主播退桌面，然后回直播间，立刻切小窗口，小窗口消失"
    Future.delayed(Duration(milliseconds: showSmallWindowNeedDelay ? 150 : 0))
        .then((value) {
      overlayEntry = OverlayEntry(builder: (context) {
        return DraggablePreView(
          overlayEntry: overlayEntry,
          liveValueModel: liveValueModel,
        );
      });

      /// Android已经改全局浮窗了
      if (Platform.isIOS) {
        //往Overlay中插入插入OverlayEntry
        Overlay.of(context, rootOverlay: true)!.insert(overlayEntry!);
      }
    });
  }

  static void removeOverlayEntry([bool isDismiss = true]) {
    if (overlayEntry != null) {
      try {
        overlayEntry?.remove();
      } catch (e) {
        fbApi.fbLogger.warning('remove overlay entry failed ${e.toString()}');
      }
      overlayEntry = null;
    }
  }
}

class DraggablePreView extends StatefulWidget {
  final OverlayEntry? overlayEntry;
  final LiveValueModel? liveValueModel;

  const DraggablePreView({
    Key? key,
    this.overlayEntry,
    this.liveValueModel,
  }) : super(key: key);

  @override
  _DraggablePreViewState createState() => _DraggablePreViewState();
}

class _DraggablePreViewState extends State<DraggablePreView>
    with WidgetsBindingObserver, PreViewWebViewRouteMix {
  double viewWidth = FrameSize.px(90); //浮窗中画面的宽
  double viewHeight = FrameSize.px(139); //浮窗中画面的高

  Offset moveOffset = Offset(FrameSize.screenW() - FrameSize.px(90),
      FrameSize.screenH() / 2 - FrameSize.px(139) / 2);

  double _left = FrameSize.screenW() - FrameSize.px(90);
  double _top = FrameSize.screenH() / 2 - FrameSize.px(139) / 2;

  @override
  void initState() {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
    final int widthPx = viewWidth.toInt() * FrameSize.pixelRatio().toInt();

    final int heightPx = viewHeight.toInt() * FrameSize.pixelRatio().toInt();

    _left = FrameSize.screenW() - FrameSize.px(90);
    _top = FrameSize.screenH() / 2 - FrameSize.px(139) / 2;
    ZegoExpressEngine.instance
        .updateTextureRendererSize(
            widget.liveValueModel!.textureId, widthPx, heightPx)
        .then((value) {
      if (value) {
        final ZegoCanvas previewCanvas =
            ZegoCanvas.view(widget.liveValueModel!.textureId);
        previewCanvas.viewMode = ZegoViewMode.AspectFill;
      }
    });

    WidgetsBinding.instance!.addObserver(this);

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: _top,
      left: _left,
      child: GestureDetector(
        // 移动中
        onPanUpdate: (details) {
          setState(() {
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
              _top = FrameSize.screenH() - FrameSize.padBotH() - viewWidth * 2;
            }
          });
        },
        // 移动结束
        onPanEnd: (details) {
          setState(() {
            if (_left + viewWidth / 2 < FrameSize.screenW() / 2) {
              _left = 0;
            } else {
              _left = FrameSize.screenW() - viewWidth;
            }
          });
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

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: floatPreViewWindow.pushToPreView,
        child: Container(
          padding: const EdgeInsets.all(2),
          color: Colors.white,
          width: viewWidth,
          height: viewHeight,
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Texture(textureId: widget.liveValueModel!.textureId),
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
                top: 6,
                right: 6,
                child: _closeBtn(),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _closeBtn() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        floatPreViewWindow.close();
      },
      child: Container(
        width: FrameSize.px(20),
        height: FrameSize.px(20),
        padding: const EdgeInsets.all(5),
        child: const Image(
            image: AssetImage("assets/live/LiveRoom/close_btn.png")),
      ),
    );
  }

  ///切换到前后台
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.inactive:
        // 处于这种状态的应用程序应该假设它们可能在任何时候暂停。
        break;
      case AppLifecycleState.resumed: //从后台切换前台，界面可见
        break;
      case AppLifecycleState.paused: // 界面不可见，后台
        break;
      case AppLifecycleState.detached: // APP结束时调用
        break;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance!.removeObserver(this);
    super.dispose();
  }
}
