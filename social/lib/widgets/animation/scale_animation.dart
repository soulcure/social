import 'package:flutter/material.dart';

/// 缩放动画组件
class ScaleAnimation extends StatefulWidget {
  const ScaleAnimation(
      {@required this.child,
      @required this.begin,
      @required this.end,
      @required this.duration,
      this.curve});

  final Widget child;
  final double begin;
  final double end;
  final Duration duration;
  final Curve curve;

  @override
  _ScaleAnimationState createState() => _ScaleAnimationState();
}

class _ScaleAnimationState extends State<ScaleAnimation>
    with TickerProviderStateMixin {
  AnimationController _controller;
  CurvedAnimation _curve;
  Animation _animation;
  double _end;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);
    _curve = CurvedAnimation(
        parent: _controller, curve: widget.curve ?? Curves.ease);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_end != widget.end) {
      _end = widget.end;
      _animation = Tween(begin: widget.begin, end: widget.end).animate(_curve);
      _controller.reset();
      _controller.forward();
    }

    return ScaleTransition(
      scale: _animation,
      child: widget.child,
    );
  }
}
