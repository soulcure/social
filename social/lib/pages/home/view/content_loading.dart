import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/themes/const.dart';
import 'package:im/utils/orientation_util.dart';
import 'package:tuple/tuple.dart';

class ContentLoadingView extends StatelessWidget {
  final Color backgroundColor;
  final Color contentColor;

  const ContentLoadingView({
    this.backgroundColor,
    this.contentColor,
  });

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
    int group = 0;
    while (remainH > 0) {
      final count = group.isEven ? 3 : 4;
      final res = _buildUnit(context, count);
      children.add(res.item1);
      remainH -= res.item2;
      if (remainH > 0) {
        children.add(sizeHeight24);
        remainH -= 24;
      }
      group++;
    }

    return SizedBox(
      height: height,
      child: Padding(
        padding:
            EdgeInsets.symmetric(horizontal: OrientationUtil.portrait ? 16 : 8),
        child: Container(
          height: OrientationUtil.portrait ? 52 : 42,
          padding: EdgeInsets.symmetric(
              horizontal: OrientationUtil.portrait ? 0 : 8),
          decoration: BoxDecoration(
              color: backgroundColor ?? Theme.of(context).backgroundColor),
          child: _AlwaysAnimation(
            child: ListView(
              physics: const NeverScrollableScrollPhysics(),
              children: children,
            ),
          ),
        ),
      ),
    );
  }

  Tuple2<Widget, double> _buildUnit(BuildContext context, int count) {
    const double avatarSize = 32;
    const double itemHeight = 16;
    const double itemPadding = 10;
    final color = contentColor ?? const Color(0xFFE8E9EB);
    final double height = max(
      avatarSize,
      itemHeight * count + itemPadding * (count - 1),
    );
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(
        count,
        (i) {
          return Flexible(
            child: FractionallySizedBox(
              widthFactor: i.isEven ? 0.9 : 0.4,
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(6),
                ),
                height: itemHeight,
              ),
            ),
          );
        },
      ),
    );
    final view = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          width: avatarSize,
          height: avatarSize,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: SizedBox(height: height, child: content),
        ),
      ],
    );
    return Tuple2(view, height);
  }
}

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
