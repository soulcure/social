import 'package:fb_live_flutter/live/utils/ui/frame_size.dart';
import 'package:fb_live_flutter/live/utils/ui/ui.dart';
import 'package:fb_live_flutter/live/widget_common/image/sw_image.dart';
import 'package:flutter/material.dart';

class ScreenSharingPage extends StatefulWidget {
  final double? height;
  final double? width;
  final bool isOverlay;

  const ScreenSharingPage({this.height, this.width, this.isOverlay = false});

  @override
  _ScreenSharingPageState createState() => _ScreenSharingPageState();
}

class _ScreenSharingPageState extends State<ScreenSharingPage> {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xff1F2125),
      height: widget.height ?? FrameSize.winHeight(),
      width: widget.width ?? FrameSize.winWidth(),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SwImage('assets/live/main/ic_screen_sharing.png',
              width: widget.isOverlay ? 22 : 44.px),
          const Space(),
          Text(
            '你正在共享',
            style: TextStyle(
              color: Colors.white.withOpacity(0.2),
              fontSize: widget.isOverlay ? 9 : 17.px,
            ),
          )
        ],
      ),
    );
  }
}
