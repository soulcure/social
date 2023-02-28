import 'package:fb_live_flutter/live/utils/func/router.dart';
import 'package:fb_live_flutter/live/utils/ui/frame_size.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class GoodsTitleBar extends StatelessWidget {
  final String? title;
  final GestureTapCallback? onPop;
  final Widget? rWidget;
  final double leftSpace;
  final bool isClose;

  const GoodsTitleBar({
    this.title,
    this.onPop,
    this.rWidget,
    this.isClose = false,
    this.leftSpace = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        InkWell(
          onTap: () {
            if (onPop != null) {
              onPop!();
            } else {
              RouteUtil.pop();
            }
          },
          child: Container(
            width: isClose ? 24.px : 36.px,
            height: isClose ? 24.px : 44.px,
            alignment: Alignment.center,
            margin:
                EdgeInsets.only(right: leftSpace, left: isClose ? 12.px : 0),
            child: UnconstrainedBox(
              child: Image.asset(
                isClose
                    ? 'assets/live/main/goods_close.png'
                    : "assets/live/main/ic_left_chevron.png",
                width: 24.px,
                height: 24.px,
              ),
            ),
          ),
        ),
        Container(
          height: 24.px,
          alignment: Alignment.center,
          padding: EdgeInsets.only(bottom: rWidget != null ? 4.px : 0),
          child: Text(
            title ?? '添加商品',
            style: TextStyle(
              color: const Color(0xff1F2125),
              fontSize: 17.px,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        rWidget ?? SizedBox(width: 36.px, height: 44.px)
      ],
    );
  }
}
