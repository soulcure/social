import 'dart:math';
import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

enum BallType {
  ///
  /// 空心
  ///
  hollow,

  ///
  /// 实心
  ///
  solid
}

///
/// 球的样式
///
class BallStyle {
  ///
  /// 尺寸
  ///
  final double? size;

  ///
  /// 实心球颜色
  ///
  final Color? color;

  ///
  /// 球的类型 [ BallType ]
  ///
  final BallType? ballType;

  ///
  /// 边框宽
  ///
  final double? borderWidth;

  ///
  /// 边框颜色
  ///
  final Color? borderColor;

  const BallStyle(
      {this.size,
      this.color,
      this.ballType,
      this.borderWidth,
      this.borderColor});

  BallStyle copyWith(
      {double? size,
      Color? color,
      BallType? ballType,
      double? borderWidth,
      Color? borderColor}) {
    return BallStyle(
        size: size ?? this.size,
        color: color ?? this.color,
        ballType: ballType ?? this.ballType,
        borderWidth: borderWidth ?? this.borderWidth,
        borderColor: borderColor ?? this.borderColor);
  }

  @override
  // ignore: hash_and_equals, avoid_equals_and_hash_code_on_mutable_classes
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other.runtimeType != runtimeType) return false;
    return other is BallStyle &&
        other.size == size &&
        other.color == color &&
        other.ballType == ballType &&
        other.borderWidth == borderWidth &&
        other.borderColor == borderColor;
  }
}

///
/// desc:
///
class DelayTween extends Tween<double> {
  final double? delay;

  DelayTween({double? begin, double? end, this.delay})
      : super(begin: begin, end: end);

  @override
  double lerp(double t) {
    return super.lerp((math.sin((t - delay!) * 2 * math.pi) + 1) / 2);
  }

  @override
  double evaluate(Animation<double> animation) => lerp(animation.value);
}

///
/// 默认球的样式
///
const kDefaultBallStyle = BallStyle(
  size: 10,
  color: Colors.white,
  ballType: BallType.solid,
  borderWidth: 0,
  borderColor: Colors.white,
);

///
/// desc:球
///
class Ball extends StatelessWidget {
  ///
  /// 球样式
  ///
  final BallStyle? style;

  const Ball({
    Key? key,
    this.style,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final BallStyle _ballStyle = kDefaultBallStyle.copyWith(
        size: style?.size,
        color: style?.color,
        ballType: style?.ballType,
        borderWidth: style?.borderWidth,
        borderColor: style?.borderColor);

    return SizedBox(
      width: _ballStyle.size,
      height: _ballStyle.size,
      child: DecoratedBox(
        decoration: BoxDecoration(
            shape: BoxShape.circle,
            color:
                _ballStyle.ballType == BallType.solid ? _ballStyle.color : null,
            border: Border.all(
                color: _ballStyle.borderColor!, width: _ballStyle.borderWidth!)),
      ),
    );
  }
}

///
/// desc:
///

class BallCirclePulseLoading extends StatefulWidget {
  final double radius;
  final BallStyle? ballStyle;
  final Duration duration;
  final Curve curve;
  final int count;

  const BallCirclePulseLoading(
      {Key? key,
      this.radius = 24,
      this.ballStyle,
      this.count = 11,
      this.duration = const Duration(milliseconds: 1000),
      this.curve = Curves.linear})
      : super(key: key);

  @override
  _BallCirclePulseLoadingState createState() => _BallCirclePulseLoadingState();
}

class _BallCirclePulseLoadingState extends State<BallCirclePulseLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..repeat();
    _animation = _controller.drive(CurveTween(curve: widget.curve));

    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Flow(
      delegate: _CircleFlow(widget.radius),
      children: List.generate(widget.count, (index) {
        return Center(
          child: ScaleTransition(
            scale: DelayTween(begin: 0, end: 1, delay: index * .1)
                .animate(_animation),
            child: Ball(
                style: kDefaultBallStyle.copyWith(
                    size: widget.ballStyle?.size,
                    color: widget.ballStyle?.color,
                    ballType: widget.ballStyle?.ballType,
                    borderWidth: widget.ballStyle?.borderWidth,
                    borderColor: widget.ballStyle?.borderColor)),
          ),
        );
      }),
    );
  }
}

class _CircleFlow extends FlowDelegate {
  final double radius;

  _CircleFlow(this.radius);

  @override
  void paintChildren(FlowPaintingContext context) {
    double x = 0; //开始(0,0)在父组件的中心
    double y = 0;
    for (int i = 0; i < context.childCount; i++) {
      x = radius * cos(i * 2 * pi / (context.childCount - 1)); //根据数学得出坐标
      y = radius * sin(i * 2 * pi / (context.childCount - 1)); //根据数学得出坐标
      context.paintChild(i, transform: Matrix4.translationValues(x, y, 0));
    }
  }

  @override
  bool shouldRepaint(FlowDelegate oldDelegate) => true;
}
