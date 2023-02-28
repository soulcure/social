import 'package:flutter/material.dart';

final List<String> likeIconList = [
  'assets/live/LiveRoom/applause.png',
  'assets/live/LiveRoom/first_heart.png',
  'assets/live/LiveRoom/like.png',
  'assets/live/LiveRoom/love.png',
  'assets/live/LiveRoom/ok.png',
  'assets/live/LiveRoom/plus_one.png',
];

class UpClickAnimation extends StatelessWidget {
  final int? randomNum;
  final Animation<double> controller;
  final Animation<double> opacity1; //动画前70%的距离 渐变不透明
  final Animation<double> opacity2; //动画后30%的距离 渐变透明
  final Animation<double> scale1; //变大
  final Animation<double> scale2; //变小
  final Animation<double> offsetAnimation; //移动

  UpClickAnimation({Key? key, required this.controller, this.randomNum})
      : offsetAnimation = Tween<double>(
          begin: 200,
          end: 0,
        ).animate(
          CurvedAnimation(
            parent: controller,
            curve: const Interval(0, 1),
          ),
        ),
        opacity1 = Tween<double>(
          begin: 0.3,
          end: 1,
        ).animate(
          CurvedAnimation(
            parent: controller,
            curve: const Interval(
              0,
              0.6,
              curve: Curves.easeInQuint,
            ),
          ),
        ),
        opacity2 = Tween<double>(
          begin: 1,
          end: 0,
        ).animate(
          CurvedAnimation(
            parent: controller,
            curve: const Interval(0.7, 1),
          ),
        ),
        // 礼物数量变大
        scale1 = Tween<double>(begin: 0.2, end: 1).animate(
          CurvedAnimation(
            parent: controller,
            curve: const Interval(0, 0.6, curve: Curves.easeOut),
          ),
        ),

        // 礼物数量变小
        scale2 = Tween<double>(
          begin: 1,
          end: 0.2,
        ).animate(
          CurvedAnimation(
            parent: controller,
            curve: const Interval(0.7, 1, curve: Curves.easeIn),
          ),
        ),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(animation: controller, builder: _buildAnimation);
  }

  Widget _buildAnimation(BuildContext context, Widget? child) {
    return Transform.translate(
      offset: Offset(0, offsetAnimation.value),
      child: Opacity(
        opacity: (offsetAnimation.value > 72) ? opacity1.value : opacity2.value,
        child: Transform.scale(
          scale: scale1.value >= 1.0 ? scale2.value : scale1.value,
          child: Image.asset(
            likeIconList[randomNum!],
            width: 42,
            height: 42,
          ),
        ),
      ),
    );
  }
}
