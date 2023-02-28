import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:fb_live_flutter/live/utils/ui/frame_size.dart';

class LiveLogoBackground extends StatelessWidget {
  final String? roomLogo;
  final Color? color;

  const LiveLogoBackground(this.roomLogo, {this.color});

  @override
  Widget build(BuildContext context) {
    /// [2021 01.17]
    /// 【APP】主播离开背景上下不一样
    return SizedBox(
      height: FrameSize.winHeightDynamic(context),
      width: FrameSize.winWidthDynamic(context),
      child: Stack(
        children: [
          if (roomLogo != null)
            CachedNetworkImage(
              imageUrl: roomLogo!,
              height: FrameSize.winHeightDynamic(context),
              width: FrameSize.winWidthDynamic(context),
              fit: BoxFit.cover,
            )
          else
            Container(),

          /// [2021 11.30] 同步fanbook，去掉蒙板判断透明逻辑
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              color: color ?? Colors.black54,
            ),
          )
        ],
      ),
    );
  }
}
