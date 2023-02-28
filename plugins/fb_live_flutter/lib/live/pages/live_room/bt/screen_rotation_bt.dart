import 'package:fb_live_flutter/live/pages/live_room/interface/live_interface.dart';
import 'package:fb_live_flutter/live/pages/live_room/widget/screen_rotation_icon.dart';
import 'package:fb_live_flutter/live/utils/ui/frame_size.dart';
import 'package:fb_live_flutter/live/widget_common/flutter/click_event.dart';
import 'package:fb_live_flutter/live/widget_common/logo/sw_logo.dart';
import 'package:flutter/material.dart';

/// 二、实现基本画面横竖屏旋转功能
class ScreenRotationBt extends Positioned {
  final ClickEventCallback? onTap;
  final LiveInterface bloc;

  ScreenRotationBt(this.bloc, {this.onTap})
      : super(
          top: (!bloc.isScreenRotation
                  ? FrameSize.padTopH() + FrameSize.px(11)
                  : FrameSize.px(11)) +
              30.px +
              20.px,
          right: FrameSize.px(12),
          child: () {
            return !bloc.isShowRotationButton
                ? Container()
                : SwLogo(
                    isCircle: true,
                    backgroundColor: Colors.black.withOpacity(0.25),
                    circleRadius: 30.px / 2,
                    iconWidget: ScreenRotationIcon(bloc.isScreenRotation),
                    iconWidth: FrameSize.px(17),
                    iconColor: Colors.white,
                    onTap: onTap,
                  );
          }(),
        );
}
