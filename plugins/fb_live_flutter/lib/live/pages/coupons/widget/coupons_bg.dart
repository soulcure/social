import 'package:fb_live_flutter/live/utils/ui/frame_size.dart';
import 'package:flutter/material.dart';

class CouponsBg extends StatelessWidget {
  final double leftWidth;
  final bool isExpanded;
  final bool isGrey;
  final double? expandedHeight;

  const CouponsBg(
    this.leftWidth,
    this.isExpanded,
    this.isGrey,
    this.expandedHeight,
  );

  /*
  * grey文件名后缀
  * */
  String get greyEndStr {
    return isGrey ? "_grey" : "";
  }

  @override
  Widget build(BuildContext context) {
    /// 展开之后的高度值
    final expandedHeightValue = expandedHeight ?? 178.px;
    final double height = isExpanded ? expandedHeightValue : 178.px / 2;

    /// 背景颜色
    const bgColor = Color.fromRGBO(253, 246, 246, 1);
    const bgColorGrey = Color.fromRGBO(249, 250, 250, 1);
    final Color useBgColor = isGrey ? bgColorGrey : bgColor;

    /// 线/边框颜色
    const borderColor = Color.fromRGBO(249, 211, 220, 1);
    const borderColorGrey = Color.fromRGBO(233, 234, 235, 1);
    final Color useBorderColor = isGrey ? borderColorGrey : borderColor;

    return Row(
      children: [
        BorderContainer(
          width: leftWidth,
          height: height,
          isLeft: true,
          useBgColor: useBgColor,
          useBorderColor: useBorderColor,
        ),
        SizedBox(
          width: 10.px,
          height: height,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Image.asset("assets/live/main/coupons_bg_u_top$greyEndStr.png"),
              Container(height: 2.px, color: useBgColor),
              Expanded(
                child: Container(
                  color: useBgColor,
                  width: 20.px,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: List.generate(
                        isExpanded ? expandedHeightValue ~/ 10 : 10, (index) {
                      return Container(
                        margin: EdgeInsets.only(bottom: 1.px),
                        width: 1,
                        height: 5,
                        color: useBorderColor,
                      );
                    }),
                  ),
                ),
              ),
              Container(height: 2.px, color: useBgColor),
              Image.asset(
                  "assets/live/main/coupons_bg_u_bottom$greyEndStr.png"),
            ],
          ),
        ),
        Expanded(
          child: BorderContainer(
            width: null,
            height: height,
            isLeft: false,
            useBgColor: useBgColor,
            useBorderColor: useBorderColor,
          ),
        ),
      ],
    );
  }
}

class BorderContainer extends StatelessWidget {
  final double height;
  final double? width;
  final bool isLeft;
  final Color useBgColor;
  final Color useBorderColor;

  const BorderContainer({
    required this.height,
    required this.width,
    required this.isLeft,
    required this.useBgColor,
    required this.useBorderColor,
  });

  @override
  Widget build(BuildContext context) {
    final double borderWidth = 1.0.px;
    final borderRadius = BorderRadius.horizontal(
      left: Radius.circular(isLeft ? 8.px : 0),
      right: Radius.circular(!isLeft ? 8.px : 0),
    );

    return Container(
      width: width ?? 0,
      height: height,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        color: useBorderColor,
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          color: useBgColor,
        ),
        margin: EdgeInsets.only(
          left: isLeft ? borderWidth : 0,
          right: isLeft ? 0 : borderWidth,
          top: borderWidth,
          bottom: borderWidth,
        ),
      ),
    );
  }
}
