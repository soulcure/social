import 'package:fb_live_flutter/live/utils/ui/frame_size.dart';
import 'package:fb_live_flutter/live/utils/ui/ui.dart';
import 'package:flutter/material.dart';

class AnchorLeaveWidget extends StatelessWidget {
  /// 绝对不能加const，否则：
  ///【APP】安卓观众横屏状态下主播暂时离开位置不对
  ///https://www.tapd.cn/51131968/bugtrace/bugs/view?bug_id=1151131968001000692
  //
  // ignore: prefer_const_constructors_in_immutables
  AnchorLeaveWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: FrameSize.winWidth(),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '主播暂时离开',
            style: TextStyle(
              fontSize: 19.px,
              color: Colors.white,
            ),
          ),
          Space(height: 13.5.px),
          Text(
            '休息片刻，更多精彩马上回来',
            style: TextStyle(
              fontSize: 16.px,
              color: const Color(0xffB4B4B4),
            ),
          ),
        ],
      ),
    );
  }
}
