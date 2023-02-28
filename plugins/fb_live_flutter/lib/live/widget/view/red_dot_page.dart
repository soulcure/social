import 'dart:math';

import 'package:fb_live_flutter/live/utils/ui/frame_size.dart';
import 'package:flutter/material.dart';

class RedDotPage extends StatefulWidget {
  final Offset? startPosition;
  final Offset? endPosition;

  const RedDotPage({Key? key, this.startPosition, this.endPosition})
      : super(key: key);

  @override
  _RedDotPageState createState() => _RedDotPageState();
}

class _RedDotPageState extends State<RedDotPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller; // 动画 controller
  late Animation<double> _animation; // 动画
  double? left; // 小圆点的left（动态计算）
  double? top; // 小远点的right（动态计算）

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        duration: const Duration(milliseconds: 700), vsync: this);

    _animation = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
      parent: _controller,
      curve: const Cubic(0.215, 0.61, 0.355, 1.2),
    ));

    // 二阶贝塞尔曲线用值
    final x0 = widget.startPosition!.dx;
    final y0 = widget.startPosition!.dy;

    final x1 = widget.startPosition!.dx - 0;
    final y1 = widget.startPosition!.dy - 0;

    final x2 = widget.endPosition!.dx;
    final y2 = widget.endPosition!.dy;

    _animation.addListener(() {
      // t 动态变化的值
      final t = _animation.value;
      if (mounted)
        setState(() {
          left = pow(1 - t, 2) * x0 + 2 * t * (1 - t) * x1 + pow(t, 2) * x2;
          top = pow(1 - t, 2) * y0 + 2 * t * (1 - t) * y1 + pow(t, 2) * y2;
        });
    });

    // 初始化小圆点的位置
    left = widget.startPosition!.dx;
    top = widget.startPosition!.dy;

    // 显示小圆点的时候动画就开始
    _controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    // 用 Stack -> Positioned 来控制小圆点的位置
    return Stack(
      children: <Widget>[
        Positioned(
          left: left,
          top: top,
          child: ClipOval(
            child: Container(
              width: 6.px,
              height: 6.px,
              color: Colors.red,
            ),
          ),
        )
      ],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
