import 'package:fb_live_flutter/live/api/fblive_provider.dart';
import 'package:fb_live_flutter/live/utils/ui/frame_size.dart';
import 'package:flutter/material.dart';

///  【2021 12.1】只为解决模糊问题没必要使用fanbook方提供的组件，
///  反而不好控制
///  【2022年前】 因为主题色原因，还是需要使用fanbook方提供的组件
Widget checkboxIcon(bool selected, {double? size, bool disabled = false}) {
  return fbApi.checkboxIcon(
    selected,
    size: size ?? 18.33.px,
    disabled: disabled,
  );
}

/// 横线
class HorizontalLine extends StatelessWidget {
  final double height;
  final Color? color;
  final EdgeInsetsGeometry? margin;

  const HorizontalLine({
    this.height = 0.5,
    this.color,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      color: color ?? const Color(0xffF5F5F8),
      margin: margin,
    );
  }
}

/// 竖线
class VerticalLine extends StatelessWidget {
  final double width;
  final double height;
  final Color color;
  final double vertical;

  const VerticalLine({
    this.width = 1.0,
    this.height = 25,
    this.color = const Color(0xff000000),
    this.vertical = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      color: color,
      margin: EdgeInsets.symmetric(vertical: vertical),
      height: height,
    );
  }
}

/// 间隔组件
class Space extends StatelessWidget {
  final double width;
  final double height;

  const Space({this.width = 10.0, this.height = 10.0, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(width: width, height: height);
  }
}
