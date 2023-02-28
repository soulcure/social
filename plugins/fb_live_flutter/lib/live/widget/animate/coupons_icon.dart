import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:fb_live_flutter/live/utils/ui/frame_size.dart';
import 'package:fb_live_flutter/live/widget_common/flutter/click_event.dart';

/// 【2021 11.27】
///
/// 优惠券ICO的动画：第一次出现是从右边飞出，先飞到大图的固定位置，
/// 再移动到小图的固定位置（同时缩小），到了小图位置后，就常驻，
/// 然后每30秒左右晃3下（像微信拍一拍的样子）
class CouponsIcon extends StatefulWidget {
  final double top;
  final ClickEventCallback? onTap;
  final bool isNeedAnimate;

  const CouponsIcon(
    this.top, {
    this.onTap,
    this.isNeedAnimate = true,
  });

  @override
  _CouponsIconState createState() => _CouponsIconState();
}

int stayMilliseconds = 1500;

/// 【2021 12.1】优惠券入口边缘动画出现的时间更改为200毫秒
int appearMilliseconds = 200;
int moveMilliseconds = 350;

class _CouponsIconState extends State<CouponsIcon>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  /// 左右移动动画
  AnimationController? _firstAnimationController;
  late Animation<RelativeRect> _firstAnimation;

  /// 缩放动画
  AnimationController? _secondAnimationController;
  late Animation<double> _secondAnimation;

  /// 对齐方式动画
  AnimationController? _alignController;
  late Animation<AlignmentGeometry> _alignAnimation;

  /// 因为使用了缩放盒子缩放一半，所以实际padding要*2
  double get rightPadding {
    if (FrameSize.isHorizontal()) {
      return 17.px * 2;
    }
    return 10.px * 2;
  }

  @override
  void initState() {
    firstAnimateInit();
    secondAnimateInit();
    alignAnimateInit();
    super.initState();
  }

  /*
  * 缩放动画控制器初始化
  * */
  void secondAnimateInit() {
    _secondAnimationController = AnimationController(
        duration: Duration(milliseconds: moveMilliseconds), vsync: this);

    _secondAnimation =
        Tween<double>(begin: widget.isNeedAnimate ? 1 : 0.5, end: 0.5)
            .animate(_secondAnimationController!);
  }

  /*
  * 对齐方式动画控制器初始化
  * */
  void alignAnimateInit() {
    _alignController = AnimationController(
        duration: Duration(milliseconds: moveMilliseconds), vsync: this);

    _alignAnimation = Tween<AlignmentGeometry>(
      begin: widget.isNeedAnimate ? Alignment.bottomRight : Alignment.topRight,
      end: Alignment.topRight,
    ).animate(_alignController!);
  }

  /*
  * 左右移动动画控制器初始化
  * */
  void firstAnimateInit() {
    _firstAnimationController = AnimationController(

        /// 优惠券边缘移动出现动画加快
        duration: Duration(milliseconds: appearMilliseconds),
        vsync: this);

    /// 大图模式=原来尺寸*2，因为缩放是从1缩放到0.5
    final double bigWidth = 36.px * 2;
    final double bigHeight = 40.5.px * 2;

    final double spaceTop = 40.5.px + 20.px; //
    final double bTop = widget.top;
    final double allMarginBottom =
        FrameSize.winHeight() - bigHeight - bTop - spaceTop;

    final bLeft = FrameSize.winWidth();
    final bRight = -bigWidth - rightPadding;

    const eRight = 0.0;

    final eLeft = FrameSize.winWidth() - bigWidth - rightPadding - eRight;

    final end = RelativeRect.fromLTRB(
      /// 【2021 12.28】优惠券图标适配有左右安全区时
      eLeft - (FrameSize.padLeft() + FrameSize.padRight()),
      bTop,
      eRight,
      allMarginBottom,
    );
    _firstAnimation = RelativeRectTween(
      begin: widget.isNeedAnimate
          ? RelativeRect.fromLTRB(
              bLeft,
              bTop,
              bRight,
              allMarginBottom,
            )
          : end,
      end: end,
    ).animate(_firstAnimationController!);

    _firstAnimation.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        Future.delayed(Duration(milliseconds: stayMilliseconds)).then((value) {
          _secondAnimationController?.forward();
          _alignController!.forward();
        });
      }
    });

    //开始动画
    _firstAnimationController!.forward();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return PositionedTransition(
      rect: _firstAnimation,
      child: ScaleTransition(
        scale: _secondAnimation,
        alignment: Alignment.topRight,
        child: AlignTransition(
          alignment: _alignAnimation,
          child: CouponsMainIcon(widget.onTap, rightPadding),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _firstAnimationController?.dispose();
    _secondAnimationController?.dispose();
    _alignController?.dispose();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;
}

class CouponsMainIcon extends StatefulWidget {
  final ClickEventCallback? onTap;
  final double rightPadding;

  const CouponsMainIcon(this.onTap, this.rightPadding);

  @override
  _CouponsMainIconState createState() => _CouponsMainIconState();
}

class _CouponsMainIconState extends State<CouponsMainIcon>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late Animation<double> animation;
  late AnimationController controller;

  Timer? timer;
  int downCount = 0;

  @override
  void initState() {
    super.initState();
    start(true);
    startCount();
  }

  /// 【2021 11.30】
  /// 优惠券动画效果调整，从右往左到大图标停顿两秒，大图标移动变小图标后晃两下。
  ///
  /// 开始倒计时
  void startCount() {
    /// stayMilliseconds 为停留毫秒
    /// appearMilliseconds 为从右到左时间
    /// moveMilliseconds 为从大到小移动/缩放时间
    final int millisecondsValue =
        stayMilliseconds + moveMilliseconds + appearMilliseconds;
    Future.delayed(Duration(milliseconds: millisecondsValue)).then((value) {
      animateOk();
    });
    downCount = 30;
    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (downCount <= 0) {
        animateOk();
        downCount = 30;
      } else {
        /// 优惠券入口抖动倒计时
        downCount--;
      }
    });
  }

  void animateOk() {
    if (mounted) setState(() => start(false));
  }

  void start(bool isInit) {
    controller = AnimationController(
        duration: const Duration(milliseconds: 750), vsync: this);
    final List<TweenSequenceItem<double>> items = [];
    final item = [
      TweenSequenceItem<double>(tween: Tween(begin: 0, end: 10), weight: 1),
      TweenSequenceItem<double>(tween: Tween(begin: 10, end: 0), weight: 1),
      TweenSequenceItem<double>(tween: Tween(begin: 0, end: -10), weight: 1),
      TweenSequenceItem<double>(tween: Tween(begin: -10, end: 0), weight: 1),
    ];
    items.addAll(item);
    items.addAll(item);
    items.addAll(item);
    items.addAll(item);
    animation = TweenSequence<double>(items).animate(controller);
    if (!isInit) controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return AnimateWidget(
      animation: animation,
      child: ClickEvent(
        onTap: widget.onTap,
        child: Container(
          padding: EdgeInsets.only(right: widget.rightPadding),
          child: Image.asset('assets/live/main/live_coupons.png'),
        ),
      ),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    timer?.cancel();
    timer = null;
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
    final result = Transform(
      transform: Matrix4.rotationZ(animation.value * pi / 180),
      alignment: Alignment.bottomCenter,
      child: child,
    );
    return result;
  }
}
