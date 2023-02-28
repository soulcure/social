import 'package:flutter/material.dart';
import 'package:fb_live_flutter/live/utils/ui/frame_size.dart';

class WebTitle extends StatelessWidget {
  final String? title;

  const WebTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title ?? '标题',
      style:
          TextStyle(color: const Color(0xff1F2125), fontSize: FrameSize.px(20)),
    );
  }
}
