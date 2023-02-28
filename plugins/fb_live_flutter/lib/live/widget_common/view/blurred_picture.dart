import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:fb_live_flutter/live/utils/ui/frame_size.dart';

///高斯模糊、蒙板
class BlurredPicture extends StatelessWidget {
  final String? backgroundImage;
  final Widget? child;

  const BlurredPicture({this.backgroundImage, this.child});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: FrameSize.winWidth(),
      height: FrameSize.winHeight(),
      child: Stack(
        fit: StackFit.expand,
        children: [
          //高斯模糊
          Image.network(
            backgroundImage!,
            fit: BoxFit.cover,
            width: FrameSize.winWidth(),
            height: FrameSize.winHeight(),
          ),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(color: Colors.black.withOpacity(0.8)),
          ),
          child ?? Container(),
        ],
      ),
    );
  }
}
