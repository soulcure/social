import 'package:fb_live_flutter/live/utils/ui/frame_size.dart';
import 'package:flutter/material.dart';

class GiftsChooseAnimationView extends StatefulWidget {
  final int? count;
  final Offset position;
  final Function? onAnimationComplete;

  const GiftsChooseAnimationView({
    Key? key,
    this.count,
    required this.position,
    this.onAnimationComplete,
  }) : super(key: key);

  @override
  GiftsChooseAnimationViewState createState() =>
      GiftsChooseAnimationViewState();
}

class GiftsChooseAnimationViewState extends State<GiftsChooseAnimationView>
    with TickerProviderStateMixin {
  Animation<double>? animationGiftNum_1,
      animationGiftNum_2,
      animationGiftNum_3,
      opacity2,
      opacity;
  AnimationController? controller;
  bool aniContinue = true;
  int? preCount = -1;

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  void initState() {
    controller = AnimationController(
        duration: const Duration(milliseconds: 3600), vsync: this);

    // 移动
    final double? an3Begin = FrameSize.px(46);
    animationGiftNum_3 = Tween<double>(
      begin: 0,
      end: an3Begin,
    ).animate(CurvedAnimation(
      parent: controller!,
      curve: const Interval(0.55, 0.65, curve: Curves.easeIn),
    ));

    // 变大
    animationGiftNum_1 = Tween<double>(
      begin: 0,
      end: 1.6,
    ).animate(CurvedAnimation(
      parent: controller!,
      curve: const Interval(0.75, 0.85, curve: Curves.easeOut),
    ));

    // 变小
    animationGiftNum_2 = Tween<double>(
      begin: 1.6,
      end: 1,
    ).animate(CurvedAnimation(
      parent: controller!,
      curve: const Interval(0.85, 1, curve: Curves.easeIn),
    ));

    opacity = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(
      CurvedAnimation(
        parent: controller!,
        curve: const Interval(0, 0.1),
      ),
    );
    opacity2 = Tween<double>(
      begin: 1,
      end: 0,
    ).animate(
      CurvedAnimation(
        parent: controller!,
        curve: const Interval(0.9, 1),
      ),
    );

    controller!.forward();
    super.initState();
  }

  double get textScale {
    double scale = animationGiftNum_1!.value >= 1.6
        ? animationGiftNum_2!.value
        : animationGiftNum_1!.value;
    if (controller!.status == AnimationStatus.reverse) {
      if (scale < 1.3) {
        scale = 1.3;
      }
    }
    return scale;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.count == null || widget.count! <= 0) {
      aniContinue = false;
    } else if (controller!.isDismissed) {
      preCount = widget.count;
      controller!.forward(from: 0.8);
    } else if (controller!.isCompleted) {
      preCount = widget.count;
      controller!.forward(from: 0.8);
    } else {
      preCount = widget.count;
      controller!.forward(from: 0.8);
    }

    if (preCount! < 1) {
      if (preCount == -1) {
        return Container();
      }
      preCount = 1;
    }

    return AnimatedBuilder(
      animation: controller!,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(widget.position.dx, -animationGiftNum_3!.value),
          child: Opacity(
            opacity: animationGiftNum_3!.value <= 1.0
                ? opacity!.value
                : opacity2!.value,
            child: SizedBox(
              width: FrameSize.px(38),
              height: FrameSize.px(46),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Image(
                    image: const AssetImage(
                      "assets/live/LiveRoom/gift_click_num.png",
                    ),
                    width: FrameSize.px(38),
                    height: FrameSize.px(46),
                  ),
                  Transform.scale(
                    scale: textScale,
                    child: Container(
                      width: FrameSize.px(38),
                      height: FrameSize.px(38),
                      alignment: Alignment.center,
                      child: Text(
                        '$preCount',
                        style: const TextStyle(
                          color: Color(0xFFF0AFFF),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
