import 'dart:io';

import 'package:fb_live_flutter/fb_live_flutter.dart';
import 'package:fb_live_flutter/live/api/fblive_provider.dart';
import 'package:fb_live_flutter/live/bloc/with/live_mix.dart';
import 'package:fb_live_flutter/live/utils/fb_navigator_observer.dart';
import 'package:fb_live_flutter/live/utils/live/zego_manager.dart';
import 'package:fb_live_flutter/live/utils/other/float_util.dart';
import 'package:fb_live_flutter/live/utils/ui/window_util.dart';
import 'package:fb_live_flutter/live/widget_common/flutter/click_event.dart';
import 'package:fb_live_flutter/live/widget_common/logo/sw_logo.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zego_express_engine/zego_express_engine.dart';

import '../../bloc/preview_bloc.dart';
import '../../utils/ui/frame_size.dart';
import '../../utils/ui/ui.dart';

class LivePreviewPage extends StatefulWidget {
  final LiveValueModel? liveValueModel;
  final FBChatChannel? liveChannel;

  const LivePreviewPage({
    this.liveValueModel,
    this.liveChannel,
  });

  @override
  _LivePreviewPageState createState() => _LivePreviewPageState();
}

/*
* 【预览页面】item类型
* */
enum LivePreviewItemType {
// 翻转
  flip,
// 镜像
  mirror,
}

/*
* 【预览页面】item模型
* */
class LivePreviewItemModel {
  final String image;
  final String text;
  final LivePreviewItemType value;

  LivePreviewItemModel(this.image, this.text, this.value);
}

class _LivePreviewPageState extends State<LivePreviewPage>
    with RouteAware, WidgetsBindingObserver {
  PreviewBloc previewBloc = PreviewBloc();

  final List<LivePreviewItemModel> _itemList = [
    LivePreviewItemModel('assets/live/preview/preview_mirror.png', '镜像',
        LivePreviewItemType.mirror),
    LivePreviewItemModel(
        'assets/live/preview/preview_flip.png', '翻转', LivePreviewItemType.flip),
  ];

  @override
  void initState() {
    super.initState();
    previewBloc.init(this, widget.liveChannel);
    WidgetsBinding.instance!.addObserver(this);
  }

  Widget buildItem(LivePreviewItemModel e) {
    return ClickEvent(
      onTap: () async {
        return previewBloc.action(e.value);
      },
      child: Column(
        children: [
          Image.asset(
            e.image,
            color: Colors.white,
            width: FrameSize.px(25),
          ),
          const Space(),
          Text(
            e.text,
            style: TextStyle(
              color: const Color(0xffF3F8FF),
              fontSize: FrameSize.px(12),
              fontWeight: FontWeight.w600,
            ),
          )
        ],
      ),
    );
  }

  @override
  void didPop() {
    super.didPop();
    if (previewBloc.isShowOverlay) {
      previewBloc.showOverlayView(context);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    previewRouteObserver.subscribe(
        this, ModalRoute.of(context) as Route<dynamic>);
  }

  @override
  Widget build(BuildContext context) {
    final Widget body = Stack(
      children: [
        BlocBuilder(
          bloc: previewBloc,
          builder: (context, _) {
            return previewBloc.previewViewWidget ?? Container();
          },
        ),
        Container(
          width: FrameSize.winWidth(),
          height: FrameSize.winHeight(),
          color: Colors.black.withOpacity(0.3),
        ),
        Positioned(
          right: 12.px,
          top: FrameSize.padTopH() + 11.px,
          child: SwLogo(
            isCircle: true,
            backgroundColor: Colors.black.withOpacity(0.25),
            icon: 'assets/live/LiveRoom/close.png',
            iconColor: Colors.white,
            iconWidth: 20.px,
            onTap: () async {
              previewBloc.isShowOverlay = false;
              fbApi.globalNavigatorKey.currentState!.pop();
              await engineClose();
            },
          ),
        ),
        Positioned(
          bottom: 10,
          right: 20,
          left: 20,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  SizedBox(
                    width: FrameSize.px(184),
                    height: FrameSize.px(40),
                    child: ElevatedButton(
                      ///直播ui验收11.16
                      /// https://idreamsky.feishu.cn/docs/doccnz6i3Yf4BiqBoUpZYcIA8PC
                      /// [ ] 按钮颜色
                      /// [ ] 按钮改为圆形
                      style: ButtonStyle(
                          padding: MaterialStateProperty.all(EdgeInsets.zero),
                          backgroundColor: MaterialStateProperty.all(
                            Theme.of(context).primaryColor,
                          ),
                          shape: MaterialStateProperty.all(
                            RoundedRectangleBorder(
                              borderRadius: BorderRadius.all(
                                Radius.circular((40 / 2).px),
                              ),
                            ),
                          )),
                      onPressed: () =>
                          previewBloc.pushToRoomPage(context, this),
                      child: const Text('开始'),
                    ),
                  ),
                ]..insertAll(0, _itemList.map(buildItem).toList()),
              ),
              Space(height: FrameSize.padTopH()),
              Text(
                '点击开始直播即代表同意《Fanbook直播协议》',
                style: TextStyle(
                  fontSize: 14.px,
                  color: const Color(0xffF3F8FF).withOpacity(0.7),
                ),
              ),
              Space(height: FrameSize.padTopH() + 20),
            ],
          ),
        ),
      ],
    );
    return AnnotatedRegion(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(body: body),
    );
  }

  ///切换到前后台
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    previewBloc.setNeedDelay(state);

    if (state == AppLifecycleState.resumed) {
      /// 设置为当前在不app外
      previewBloc.isOutsideApp = false;

      ZegoManager.handleFloat(
        onComplete: () {
          previewBloc.startPreviewEnd();
        },
        isPreview: true,
      );

      /// 再次检测小窗
      FloatUtil.dismissFloat(200);
    } else if (state == AppLifecycleState.paused && Platform.isAndroid) {
      /// 设置为当前在app外
      previewBloc.isOutsideApp = true;

      /// 主播要为空，否则会走预览线路
      FloatUtil.showPreviewFloat(context, previewBloc.isOutsideApp);
    }
  }

  @override
  void dispose() {
    super.dispose();
    WindowUtil.setStatusTextColorBlack();
    previewRouteObserver.unsubscribe(this);
    WidgetsBinding.instance!.removeObserver(this);
  }

  // 引擎关闭
  Future engineClose() async {
    //停止本地预览
    await ZegoExpressEngine.instance.stopPreview();
    //销毁预览容器
    await ZegoExpressEngine.instance
        .destroyTextureRenderer(previewBloc.liveValueModel!.textureId);
    //注销
    await ZegoExpressEngine.destroyEngine();
  }
}
