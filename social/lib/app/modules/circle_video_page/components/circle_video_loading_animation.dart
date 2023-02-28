import 'package:flutter/material.dart';

class CircleVideoLoadingAnimation extends StatefulWidget {
  const CircleVideoLoadingAnimation({
    key,
    @required this.spreadOffset,
    @required this.size,
    this.duration = const Duration(milliseconds: 650),
    this.curve = Curves.easeOutQuad,
  }) : super(key: key);

  ///光条向两侧移动的最大Offset
  final double spreadOffset;
  final Duration duration;
  final Curve curve;
  final Size size;

  @override
  _CircleVideoLoadingAnimationState createState() =>
      _CircleVideoLoadingAnimationState();
}

class _CircleVideoLoadingAnimationState
    extends State<CircleVideoLoadingAnimation>
    with SingleTickerProviderStateMixin {
  AnimationController _animationController;
  Animation<double> _animationOffset;
  Animation<double> _animationOpacity;

  @override
  void initState() {
    _animationController =
        AnimationController(vsync: this, duration: widget.duration);
    final Animation<double> curve =
        CurveTween(curve: Curves.easeOutQuad).animate(_animationController);
    _animationOffset =
        Tween<double>(begin: 0, end: widget.spreadOffset).animate(curve);
    _animationOpacity = Tween<double>(begin: 1, end: .1).animate(curve);
    _animationController.addListener(() {
      setState(() {});
    });
    _animationController.repeat();
    super.initState();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: CircleLoadingPainter(
        widget.size,
        _animationOffset.value,
        _animationOpacity.value,
      ),
      size: widget.size,
    );
  }
}

class CircleLoadingPainter extends CustomPainter {
  CircleLoadingPainter(this._size, this._aniOffset, this._opacity);

  final Size _size;
  final double _aniOffset;
  final double _opacity;

  @override
  void paint(Canvas canvas, Size size) {
    final Gradient gradient = LinearGradient(colors: [
      Colors.transparent,
      Color.fromRGBO(255, 255, 255, _opacity),
      Colors.transparent
    ]);
    Rect rect(bool offset) {
      final rightOffset = _aniOffset;
      final leftOffset = -_aniOffset;
      return Rect.fromLTWH(
          offset ? rightOffset : leftOffset, 0, _size.width, _size.height);
    }

    Paint paint(Rect rect) {
      return Paint()
        ..isAntiAlias = true
        ..shader = gradient.createShader(rect)
        ..style = PaintingStyle.fill;
    }

    canvas.drawRect(rect(true), paint(rect(true)));
    canvas.drawRect(rect(false), paint(rect(false)));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
