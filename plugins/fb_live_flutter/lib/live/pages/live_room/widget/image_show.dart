import 'dart:math';

import 'package:flutter/material.dart';
import 'package:fb_live_flutter/live/utils/ui/frame_size.dart';

// 【2021 12.30】
//
// 10. 双击点赞动效仿抖音
// 双击点赞效果的需求：
// 首先，手指触发产生表情包的位置要在手指上面的40个像素（手指点击的位置到动画的中心点位置）
// 动画总时长500ms，脚本为：
// 1. 从0变大到   48*48px(一倍图)不透明，过程时间为200ms
// 2. 按中心点顺时针旋转15度，过程时间为100ms
// 3. 放大到 58*58px(一倍图)，过程时间为200ms，过程中且透明度渐变为0
class ImageShow extends StatefulWidget {
  final String image;
  final double width;
  final double height;

  const ImageShow(this.image, this.width, this.height);

  @override
  _ImageShowState createState() => _ImageShowState();
}

class _ImageShowState extends State<ImageShow>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late Animation<double> animation;
  AnimationController? controller;

  late Animation<double> scale;
  AnimationController? controllerScale;

  @override
  void initState() {
    super.initState();
    start(true);

    controllerScale = AnimationController(
        duration: const Duration(milliseconds: 200), vsync: this);
    scale = Tween<double>(
      begin: 0,
      end: 10,
    ).animate(
      CurvedAnimation(parent: controllerScale!, curve: Curves.ease),
    );

    Future.delayed(const Duration(milliseconds: 300)).then((value) {
      if (mounted) controllerScale?.forward();
    });
  }

  void start(bool isInit) {
    controller = AnimationController(
        duration: const Duration(milliseconds: 200 + 100), vsync: this);
    final List<TweenSequenceItem<double>> items = [];
    final item = [
      TweenSequenceItem<double>(
          tween: Tween(begin: 0, end: pi * 0.15), weight: 1),
    ];
    items.addAll(item);
    animation = TweenSequence<double>(items).animate(controller!);
    if (mounted) controller!.forward();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return AnimateWidget(
      animation: animation,
      child: Container(
        width: 68.px,
        height: 68.px,
        alignment: Alignment.center,
        child: Container(
          width: 58.px + scale.value,
          height: 58.px + scale.value,
          alignment: Alignment.center,
          child: Image.asset(widget.image,
              fit: BoxFit.fill, width: widget.width, height: widget.height),
        ),
      ),
    );
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;
}

class AnimateWidget extends AnimatedWidget {
  final Widget? child;

  const AnimateWidget({
    required Animation<double> animation,
    this.child,
  }) : super(listenable: animation);

  @override
  Widget build(BuildContext context) {
    final Animation<double> animation = listenable as Animation<double>;
    final result = Transform.rotate(
      angle: animation.value,
      child: child,
    );
    return result;
  }
}
