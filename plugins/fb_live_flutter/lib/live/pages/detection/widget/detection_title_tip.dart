import 'package:flutter/material.dart';
import 'package:fb_live_flutter/live/utils/ui/frame_size.dart';
import 'package:fb_live_flutter/live/utils/ui/ui.dart';

class DetectionTitleTip extends StatelessWidget {
  final bool? isFail;
  final String? title;

  const DetectionTitleTip({
    this.isFail,
    this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (isFail != null)
          Image.asset(
            isFail!
                ? 'assets/live/main/stop.png'
                : 'assets/live/main/web_check_ok.png',
            width: 20.px,
          ),
        if (isFail != null) Space(width: 4.px),
        Text(
          title ?? '标题',
          style: TextStyle(
            color: const Color(0xff8F959E),
            fontSize: FrameSize.px(14),
          ),
        )
      ],
    );
  }
}
