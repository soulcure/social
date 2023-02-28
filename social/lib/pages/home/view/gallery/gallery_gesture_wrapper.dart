import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:photo_view/photo_view.dart';

GlobalKey<_GalleryGestureWrapperState> galleryGestureWrapperKey = GlobalKey();

class GalleryGestureWrapper extends StatefulWidget {
  final Widget child;

  final bool isSelfGesture;

  final VoidCallback onDismiss;
  final VoidCallback onTap;
  final VoidCallback onScaleStart;
  final VoidCallback onScaleEnd;

  const GalleryGestureWrapper({
    Key key,
    this.child,
    this.isSelfGesture = false,
    this.onDismiss,
    this.onTap,
    this.onScaleStart,
    this.onScaleEnd,
  }) : super(key: key);

  @override
  _GalleryGestureWrapperState createState() => _GalleryGestureWrapperState();
}

class _GalleryGestureWrapperState extends State<GalleryGestureWrapper>
    with TickerProviderStateMixin {
  Color _backgroundColor = Colors.black;

  /// 返回事件记录
  Offset initPosition;
  Offset initOffset;
  bool isDrag = false;
  List<Offset> updatePosition = [];
  Offset currentOffset = const Offset(0, 0);
  double scale = 1;

  /// 拖动取消动画
  bool isAnimate = false;
  AnimationController _bakOffsetAnimationController;
  Animation<Offset> _bakOffsetAnimation;
  AnimationController _bakScaleAnimationController;
  Animation<double> _bakScaleAnimation;

  @override
  void initState() {
    // 动画
    _bakOffsetAnimationController = AnimationController(
        duration: const Duration(milliseconds: 200), vsync: this)
      ..addListener(() => setState(() {}));
    _bakOffsetAnimation = Tween(begin: Offset.zero, end: Offset.zero)
        .animate(_bakOffsetAnimationController);
    _bakScaleAnimationController = AnimationController(
        duration: const Duration(milliseconds: 200), vsync: this);
    _bakScaleAnimation =
        Tween<double>(begin: 1, end: 1).animate(_bakScaleAnimationController);

    super.initState();
  }

  void onScaleStart(BuildContext context, ScaleStartDetails details,
      Offset offset, PhotoViewControllerValue controllerValue) {
    widget.onScaleStart?.call();
    initOffset = details.localFocalPoint;
    initPosition = controllerValue.position;
    isDrag = false;
    setState(() => isAnimate = false);
    _bakOffsetAnimationController.reset();
    _bakScaleAnimationController.reset();
  }

  void onScaleUpdate(BuildContext context, ScaleUpdateDetails details,
      Offset offset, PhotoViewControllerValue controllerValue) {
    updatePosition.add(controllerValue.position);
    final currentOffset = Offset(details.localFocalPoint.dx - initOffset.dx,
        details.localFocalPoint.dy - initOffset.dy);
    if (isDrag ||
        (updatePosition.length > 3 &&
                (updatePosition[3].dy - initPosition.dy).abs() < 8 &&
                (updatePosition[3].dx - initPosition.dx).abs() < 4) &&
            (scale == details.scale)) {
      var verticalDistance = currentOffset.dy > 300 ? 300 : currentOffset.dy;
      verticalDistance = verticalDistance < 0 ? 0 : verticalDistance;
      final color = Color.fromRGBO(0, 0, 0, 1 - verticalDistance / 300);
      // scale
      final scale = (1 - verticalDistance / 300) < 0.3
          ? 0.3
          : (1 - verticalDistance / 300);
      _bakOffsetAnimation = _bakOffsetAnimationController
          .drive(Tween(begin: this.currentOffset, end: Offset.zero));
      _bakScaleAnimation =
          _bakScaleAnimationController.drive(Tween(begin: scale, end: 1));
      setState(() {
        _backgroundColor = color;
        isDrag = true;
        this.currentOffset = currentOffset;
        this.scale = scale;
      });
    }
  }

  void onScaleEnd(BuildContext context, ScaleEndDetails details, Offset offset,
      PhotoViewControllerValue controllerValue) {
    if (currentOffset.dy > 60) {
      // 滑动结束在pop的时候，如果用户手动点击或者其余操作，会导致widget渲染异常【表现就是图片固定在聊天页面】，所以把pop放到下一帧去能解决此问题
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
        Get.back();
      });

      widget.onDismiss?.call();
      return;
    }

    widget.onScaleEnd?.call();
    if (isDrag) {
      setState(() => isAnimate = true);
      _bakOffsetAnimationController.forward();
      _bakScaleAnimationController.forward();
    }
    updatePosition = [];

    setState(() {
      isDrag = false;
      scale = 1;
      currentOffset = Offset.zero;
      _backgroundColor = Colors.black;
    });
  }

  @override
  Widget build(BuildContext context) {
    final child = Container(
      color: _backgroundColor,
      child: Transform.translate(
        offset: isAnimate ? _bakOffsetAnimation.value : currentOffset,
        child: Transform.scale(
            //_bakScaleAnimation
            scale: isAnimate ? _bakScaleAnimation.value : scale,
            child: widget.child),
      ),
    );
    if (widget.isSelfGesture) {
      return WillPopScope(
        onWillPop: () async {
          widget.onDismiss?.call();
          return true;
        },
        child: GestureDetector(
          onScaleUpdate: (details) {
            onScaleUpdate(
                context,
                details,
                null,
                const PhotoViewControllerValue(
                    position: Offset.zero,
                    scale: null,
                    rotation: null,
                    rotationFocusPoint: null));
          },
          onScaleStart: (details) {
            onScaleStart(
                context,
                details,
                null,
                const PhotoViewControllerValue(
                    position: Offset.zero,
                    scale: null,
                    rotation: null,
                    rotationFocusPoint: null));
          },
          onScaleEnd: (details) {
            onScaleEnd(
                context,
                details,
                null,
                const PhotoViewControllerValue(
                    position: Offset.zero,
                    scale: null,
                    rotation: null,
                    rotationFocusPoint: null));
          },
          onTap: widget.onTap,
          child: child,
        ),
      );
    }
    return child;
  }
}
