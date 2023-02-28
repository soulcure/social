import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

///从 10%显示的地方开始
const double LowerBound = 0.06;

///摔动速度识别定义
const double kMinFlingVelocity = 200;

///只有正负的区别
const double velocity = 20;

class InnerDrawer extends StatefulWidget {
  const InnerDrawer(
      {Key key, @required this.scaffold, @required this.rightChild})
      : super(key: key);

  /// A Scaffold is generally used but you are free to use other widgets
  final Widget scaffold;

  /// Right child
  final Widget rightChild;

  @override
  InnerDrawerState createState() => InnerDrawerState();
}

class InnerDrawerState extends State<InnerDrawer>
    with SingleTickerProviderStateMixin {
  ///屏幕宽度
  double _initWidth = 0;

  AnimationController _controller;

  ///_controller.value=LowerBound
  void open() {
    //velocity 如果速度为正，动画将complete，否则将dismiss
    _controller.fling(velocity: -velocity);
  }

  ///_controller.value=1
  void close() {
    _controller.fling(velocity: velocity);
  }

  @override
  void initState() {
    _controller = AnimationController(
        value: 1,
        lowerBound: LowerBound,
        duration: const Duration(milliseconds: 20),
        vsync: this)
      ..addListener(_animationChanged);
    //..addStatusListener(_animationStatusChanged);

    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_initWidth == 0) {
      _initWidth = MediaQuery.of(context).size.width;
    }

    return Stack(
      alignment: AlignmentDirectional.centerEnd,
      children: <Widget>[
        _rightChild,
        GestureDetector(
          onHorizontalDragDown: _handleDragDown,
          onHorizontalDragUpdate: _handleDragMove,
          onHorizontalDragEnd: _handleDragEnd,
          excludeFromSemantics: true,
          //语义树中排除一些手势
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: Align(
                alignment: AlignmentDirectional.centerEnd,
                widthFactor: _controller.value,
                child: _scaffold),
          ),
        ),
      ],
    );
  }

  void _animationChanged() {
    setState(() {});
  }

  // void _animationStatusChanged(AnimationStatus status) {
  //   switch (status) {
  //     case AnimationStatus.reverse:
  //       break;
  //     case AnimationStatus.forward:
  //       break;
  //     case AnimationStatus.dismissed:
  //       break;
  //     case AnimationStatus.completed:
  //       break;
  //   }
  // }

  void _handleDragDown(DragDownDetails details) {
    _controller.stop();
  }

  void _handleDragMove(DragUpdateDetails details) {
    final double delta = details.primaryDelta / _width;
    _controller.value += delta;
  }

  void _handleDragEnd(DragEndDetails details) {
    if (_controller.isDismissed) return;
    if (details.velocity.pixelsPerSecond.dx.abs() >= kMinFlingVelocity) {
      final double visualVelocity =
          (details.velocity.pixelsPerSecond.dx + velocity) / _width;
      _controller.fling(velocity: visualVelocity);
    } else if (_controller.value < 0.5) {
      open();
    } else {
      close();
    }
  }

  double get _width {
    return _initWidth;
  }

  /// Scaffold
  Widget get _scaffold {
    return widget.scaffold;
  }

  Widget get _rightChild {
    final Container child = Container(
        padding: const EdgeInsets.only(left: 30), child: widget.rightChild);
    return child;
    // return widget.rightChild;
  }
}
