import 'package:flutter/cupertino.dart';

class BreatheWidget extends StatefulWidget {
  final Widget animatedWidget;

  const BreatheWidget(this.animatedWidget, {Key key}) : super(key: key);

  @override
  _BreatheWidgetState createState() => _BreatheWidgetState();
}

class _BreatheWidgetState extends State<BreatheWidget>
    with SingleTickerProviderStateMixin {
  AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        duration: const Duration(milliseconds: 2 * 1000), vsync: this);
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    //渐变
    //FadeTransition
    return FadeTransition(
      opacity: _controller.drive(Tween(begin: 0.05, end: 0.1)),
      child: widget.animatedWidget,
    );
  }
}
