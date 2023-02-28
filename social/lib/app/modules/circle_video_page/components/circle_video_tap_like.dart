import 'dart:math';

import 'package:flutter/material.dart';

class TikTokFavoriteAnimationIcon extends StatefulWidget {
  final Offset position;
  final double size;
  final Function onAnimationComplete;

  const TikTokFavoriteAnimationIcon({
    Key key,
    this.onAnimationComplete,
    this.position,
    this.size = 300,
  }) : super(key: key);

  @override
  _TikTokFavoriteAnimationIconState createState() =>
      _TikTokFavoriteAnimationIconState();
}

class _TikTokFavoriteAnimationIconState
    extends State<TikTokFavoriteAnimationIcon> with TickerProviderStateMixin {
  AnimationController _animationController;

  double rotate = pi / 10.0 * (2 * Random().nextDouble() - 1);

  double appearDuration = 0.1;

  double dismissDuration = 0.8;

  @override
  void initState() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _animationController.addListener(() {
      setState(() {});
    });
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      startAnimation();
    });
    super.initState();
  }

  @override
  void dispose() {
    _animationController?.dispose();
    super.dispose();
  }

  //开始动画
  Future<void> startAnimation() async {
    await _animationController.forward();
    widget.onAnimationComplete?.call();
  }

  @override
  Widget build(BuildContext context) {
    return widget.position == null
        ? const SizedBox()
        : Positioned(
            left: widget.position.dx - widget.size / 2,
            top: widget.position.dy - widget.size * 0.8,
            child: _getBody(),
          );
  }

  //获取动画的值
  double get value => _animationController?.value;

  double get opacity {
    if (value < appearDuration) {
      return 0.9 / appearDuration * value;
    }
    if (value < dismissDuration) {
      return 0.9;
    }
    final res = 0.9 - (value - dismissDuration) / (1 - dismissDuration);
    return res < 0 ? 0 : res;
  }

  double get scale {
    if (value <= 0.8) {
      return 0.6 + value / 0.5 * 0.3;
    } else {
      return 1.08 + (value - 0.8) / 0.2 * 0.5;
    }
  }

  Widget _getBody() {
    return Transform.rotate(
      angle: rotate,
      child: Opacity(
        opacity: opacity,
        child: Transform.scale(
          alignment: Alignment.bottomCenter,
          scale: scale,
          child: _getContent(),
        ),
      ),
    );
  }

  Widget _getContent() {
    return ShaderMask(
      blendMode: BlendMode.srcATop,
      shaderCallback: (bounds) => RadialGradient(
        center: Alignment.topLeft.add(const Alignment(0.5, 0.5)),
        colors: const [
          Color(0xffEF6F6F),
          Color(0xffF03E3E),
        ],
      ).createShader(bounds),
      child: Image.asset(
        'assets/images/red_heart.webp',
        width: widget.size,
        height: widget.size,
      ),
    );
  }
}
