import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/themes/const.dart';
import 'package:tuple/tuple.dart';

///语音频道-用户列表呼吸态
class AudioLoadingView extends StatelessWidget {
  const AudioLoadingView();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraint) {
        return _defaultItemWidget(context, constraint.maxHeight);
      },
    );
  }

  Widget _defaultItemWidget(BuildContext context, double height) {
    double remainH = height;
    final List<Widget> children = [];
    while (remainH > 0) {
      final res = _buildUnit(context);
      children.add(res.item1);
      remainH -= res.item2;
      if (remainH > 0) {
        children.add(sizeHeight20);
        remainH -= 20;
      }
    }

    return SizedBox(
      height: height,
      child: Container(
        height: height,
        decoration: BoxDecoration(color: Theme.of(context).backgroundColor),
        child: _AlwaysAnimation(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(0, 15, 0, 15),
            physics: const NeverScrollableScrollPhysics(),
            children: children,
          ),
        ),
      ),
    );
  }

  ///单行Widget
  Tuple2<Widget, double> _buildUnit(BuildContext context) {
    const double avatarSize = 32;
    const color = Color(0xFFE8E9EB);
    const height = avatarSize + 3;
    final content = FractionallySizedBox(
      alignment: Alignment.centerLeft,
      widthFactor: max(Random().nextInt(8), 4) * 0.1,
      heightFactor: 0.7,
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(6),
        ),
      ),
    );
    final view = Row(
      children: <Widget>[
        sizeWidth15,
        Container(
          width: avatarSize,
          height: avatarSize,
          decoration: const BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        sizeWidth15,
        Expanded(
          child: SizedBox(height: height, child: content),
        ),
      ],
    );
    return Tuple2(view, height);
  }
}

///动画：opacity循环变化
class _AlwaysAnimation extends StatefulWidget {
  final Widget child;

  const _AlwaysAnimation({Key key, this.child}) : super(key: key);

  @override
  __AlwaysAnimationState createState() => __AlwaysAnimationState();
}

class __AlwaysAnimationState extends State<_AlwaysAnimation>
    with SingleTickerProviderStateMixin {
  AnimationController _animation;

  @override
  void initState() {
    _animation = AnimationController(vsync: this, duration: 1.5.seconds)
      ..repeat(
        reverse: true,
        min: 0.2,
        max: 0.8,
      );
    // _animation.forward();
    super.initState();
  }

  @override
  void dispose() {
    _animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
        animation: _animation,
        builder: (context, _) => Opacity(
              opacity: _animation.value,
              child: widget.child,
            ));
  }
}
