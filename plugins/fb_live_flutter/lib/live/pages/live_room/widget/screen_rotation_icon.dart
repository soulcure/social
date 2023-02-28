import 'package:flutter/material.dart';
import 'package:fb_live_flutter/live/utils/ui/frame_size.dart';

class ScreenRotationIcon extends StatelessWidget {
  final bool isScreenRotation;
  final double? width;

  const ScreenRotationIcon(this.isScreenRotation, {this.width});

  @override
  Widget build(BuildContext context) {
    ///6. 图标不对，设计稿是长方形，并且翻转的样式也不对 横竖屏切换问题汇总 - 飞书云文档 (feishu.cn)
    if (!isScreenRotation) {
      return Image.asset(
        'assets/live/main/ic_screen_rotation_down.png',
        width: width ?? FrameSize.px(20),
        color: Colors.white,
      );
    } else {
      return Image.asset(
        'assets/live/main/ic_screen_rotation_up.png',
        width: width ?? FrameSize.px(30),
        color: Colors.white,
      );
    }
  }
}
