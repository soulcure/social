import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fb_live_flutter/live/utils/ui/frame_size.dart';
import 'package:fb_live_flutter/live/utils/func/router.dart';
import 'package:fb_live_flutter/live/utils/ui/ui.dart';

class BottomDialogButton extends StatelessWidget {
  final VoidCallback? onNotAgain;
  final VoidCallback? onNow;

  const BottomDialogButton({this.onNotAgain, this.onNow});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        Expanded(
          child: CupertinoButton(
            padding: EdgeInsets.symmetric(vertical: FrameSize.px(10)),
            color: const Color(0xffF5F5F8),

            /// 【这两个按钮做成了方圆，应该是圆形】https://www.tapd.cn/51131968/bugtrace/bugs/view?bug_id=1151131968001000310
            borderRadius: BorderRadius.all(Radius.circular(30.px)),
            onPressed: () {
              RouteUtil.pop();
              if (onNotAgain != null) onNotAgain!();
            },
            child: Text(
              "不再提示",
              style: TextStyle(fontSize: 16.px, color: const Color(0xFF198CFE)),
            ),
          ),
        ),
        Space(width: 16.px),
        Expanded(
            child: CupertinoButton(
          padding: EdgeInsets.symmetric(vertical: 10.px),
          color: const Color(0xFF198CFE),
          borderRadius: BorderRadius.all(Radius.circular(20.px)),
          onPressed: () {
            RouteUtil.pop();
            if (onNow != null) onNow!();
          },
          child: Text(
            "我知道了",
            style: TextStyle(fontSize: 16.px),
          ),
        )),
      ],
    );
  }
}
