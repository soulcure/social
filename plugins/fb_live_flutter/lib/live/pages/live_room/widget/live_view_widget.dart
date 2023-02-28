import 'dart:math' as math;

import 'package:fb_live_flutter/live/model/live/view_render_alg_model.dart';
import 'package:fb_live_flutter/live/pages/live_room/interface/live_interface.dart';
import 'package:fb_live_flutter/live/utils/ui/frame_size.dart';
import 'package:flutter/material.dart';

class LiveViewWidgetView extends StatelessWidget {
  final ViewRenderAlgModel algModel;
  final LiveInterface liveInterface;
  final int? textureId;

  const LiveViewWidgetView(
    this.algModel,
    this.liveInterface, {
    this.textureId,
  });

  @override
  Widget build(BuildContext context) {
    final Texture viewWidget = Texture(textureId: textureId!);

    Widget resultView = SizedBox(
      width: algModel.viewWidth,

      /// 如果画面需要旋转且屏幕旋转横屏了，宽度为屏幕最新宽度，防止出现状态栏导致出错
      height: algModel.needRotate && liveInterface.isScreenRotation
          ? FrameSize.winWidth()
          : algModel.viewHeight,
      child: viewWidget,
    );
    if (algModel.needRotate) {
      final double rotate =
          liveInterface.liveValueModel!.screenDirection != "RH"
              ? math.pi / 2
              : -(math.pi / 2);
      resultView = UnconstrainedBox(
        child: Transform.rotate(angle: rotate, child: resultView),
      );
    }
    final bool isHorizontal = algModel.axis == Axis.horizontal;
    return Container(
      width: FrameSize.winWidthDynamic(context),
      height: isHorizontal && !liveInterface.isScreenRotation
          ? FrameSize.winHeight() * 0.7
          : FrameSize.winHeight(),
      alignment: Alignment.center,
      child: resultView,
    );
  }
}

class LiveViewWidget extends StatelessWidget {
  final LiveInterface liveInterface;
  final bool isObs;
  final bool alignedToAndroid;

  const LiveViewWidget(this.liveInterface,
      {this.isObs = false, this.alignedToAndroid = false});

  @override
  Widget build(BuildContext context) {
    if (liveInterface.liveValueModel!.textureId >= 0) {
      final double _w = FrameSize.winWidth();
      double _h;

      final double widthResult = alignedToAndroid
          ? liveInterface.liveValueModel!.playerVideoHeight
          : liveInterface.liveValueModel!.playerVideoWidth;
      final double heightResult = alignedToAndroid
          ? liveInterface.liveValueModel!.playerVideoWidth
          : liveInterface.liveValueModel!.playerVideoHeight;

      try {
        /// 防止影响普通直播，普通直播调用此组件时有判断宽大于高，所以不会有问题
        // todo 尝试优化代码
        if (isObs) {
          _h = !liveInterface.isScreenRotation &&

                  /// 修复obs主播端画面问题
                  widthResult > heightResult
              ? (FrameSize.winWidth() * heightResult / widthResult)
              : FrameSize.winHeight();
        } else {
          _h = !liveInterface.isScreenRotation
              ? (FrameSize.winWidth() * heightResult / widthResult)
              : FrameSize.winHeight();
        }
      } catch (e) {
        _h = FrameSize.winHeight();
      }

      /// obs画面向上效果，当视频画面宽度大于高度时
      bool isVideoHorizontal;
      try {
        isVideoHorizontal = widthResult > heightResult;
      } catch (e) {
        isVideoHorizontal = false;
      }
      return Container(
        alignment: Alignment.center,
        height: FrameSize.winHeight() *
            (isVideoHorizontal && !liveInterface.isScreenRotation ? 0.7 : 1),
        child: SizedBox(
          /// obs的话不默认全屏幕宽高，
          /// 因为如果全屏幕宽高的话有几率初始化时出现短暂黑屏。
          ///
          /// 普通直播需要全屏幕宽高因为普通直播推流的是摄像头流，需要全屏幕显示
          /// 【2021 11.20】
          width: _w.isNaN && isObs
              ? 0
              : _w.isNaN
                  ? FrameSize.winWidth()
                  : _w,
          height: _h.isNaN && isObs
              ? 0
              : _w.isNaN
                  ? FrameSize.winHeight()
                  : _h,
          child: Texture(textureId: liveInterface.liveValueModel!.textureId),
        ),
      );
    } else {
      return Container();
    }
  }
}
