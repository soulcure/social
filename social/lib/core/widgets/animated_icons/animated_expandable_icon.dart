import 'package:flutter/material.dart';
import 'package:im/icon_font.dart';
import 'package:im/themes/const.dart';

class AnimatedExpandableIcon extends StatefulWidget {
  final ValueSetter<bool> onChange;
  final double size;
  final double space;
  final Widget follow;
  final bool initialExpanded;
  final Color color;
  final GestureTapCallback onLongPress;
  const AnimatedExpandableIcon({
    @required this.onChange,
    this.initialExpanded,
    this.size,
    this.follow,
    this.color,
    this.space = 0,
    this.onLongPress,
  });

  @override
  _AnimatedExpandableIconState createState() => _AnimatedExpandableIconState();
}

class _AnimatedExpandableIconState extends State<AnimatedExpandableIcon>
    with SingleTickerProviderStateMixin {
  AnimationController _animationController;
  Animation<double> _animation;

  @override
  void initState() {
    _animationController = AnimationController(
      value: widget.initialExpanded ? 1 : 0,
      vsync: this,
      duration: kThemeAnimationDuration,
    );
    final sortCurve = CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInSine,
        reverseCurve: Curves.easeOutSine);
    _animation = Tween<double>(begin: -0.25, end: 0).animate(sortCurve);

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: _toggle,
      onLongPress: widget.onLongPress,
      child: Row(
        children: <Widget>[
          sizeWidth8,
          RotationTransition(
              turns: _animation,
              child: Icon(
                IconFont.buffDownArrow,
                color: widget.color,
                size: widget.size,
              )),
          if (widget.space != null) SizedBox(width: widget.space),
          if (widget.follow != null) Expanded(child: widget.follow),
        ],
      ),
    );
  }

  void _toggle() {
    setState(() {
      if (_animationController.isCompleted) {
        _animationController.reverse();
        widget.onChange(false);
      } else {
        _animationController.forward();
        widget.onChange(true);
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}
