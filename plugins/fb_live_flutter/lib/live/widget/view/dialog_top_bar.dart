import 'package:flutter/material.dart';
import 'package:fb_live_flutter/live/utils/ui/frame_size.dart';

/// IOS对话框顶部可拖动指示器
class DialogTopBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      padding: EdgeInsets.only(top: FrameSize.px(8)),
      child: Container(
        width: 35.px,
        height: 4.px,
        decoration: const BoxDecoration(
          color: Color(0xffE0E2E6),
          borderRadius: BorderRadius.all(Radius.circular(2)),
        ),
      ),
    );
  }
}
