import 'package:fb_live_flutter/live/utils/func/router.dart';
import 'package:fb_live_flutter/live/widget_common/dialog/sw_scroll_dialog.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class BottomSheetDrag extends StatefulWidget {
  final Widget child;
  final double height;
  final bool isSmartDialog;

  const BottomSheetDrag(
      {required this.child, required this.height, this.isSmartDialog = false});

  @override
  _BottomSheetDragState createState() => _BottomSheetDragState();
}

class _BottomSheetDragState extends State<BottomSheetDrag>
    with TickerProviderStateMixin {
  double? offsetDistance;

  ///滑动位置超过这个位置，会滚到顶部；小于，会滚动底部。
  late double maxOffsetDistance;

  bool onResetControllerValue = false;
  bool isPop = false;

  late AnimationController animalController;
  late Animation<double> animation;

  @override
  void initState() {
    super.initState();
    animalController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 250));
    maxOffsetDistance = widget.height * 0.2;
  }

  double get defaultOffsetDistance => 0;

  @override
  Widget build(BuildContext context) {
    if (offsetDistance == null || onResetControllerValue) {
      ///说明是第一次加载,由于BottomDragWidget中 alignment: Alignment.bottomCenter,故直接设置
      offsetDistance = defaultOffsetDistance;
    }

    ///偏移值在这个范围内
    offsetDistance = offsetDistance!.clamp(0.0, widget.height);

    return Transform.translate(
      offset: Offset(0, offsetDistance!),
      child: NotificationListener<OverscrollNotification>(
        onNotification: (notification) {
          final DragUpdateDetails? details = notification.dragDetails;
          if (notification.dragDetails != null &&
              notification.dragDetails?.delta != null) {
            offsetDistance = offsetDistance! + details!.delta.dy;
            setState(() {});
          }

          return false;
        },
        child: NotificationListener<UserScrollNotification>(
          onNotification: (value) {
            double? start;
            double end;
            if (offsetDistance! <= maxOffsetDistance) {
              ///这个判断通过，说明已经child位置超过警戒线了，需要滚动到顶部了
              start = offsetDistance;
              end = 0.0;
            } else {
              start = offsetDistance;
              end = defaultOffsetDistance;
              if (!isPop) {
                if (widget.isSmartDialog) {
                  RouteUtil.pop();
                } else {
                  Get.back();
                }
                isPop = true;
              }
              return false;
            }

            ///easeOut 先快后慢
            final CurvedAnimation curve = CurvedAnimation(
                parent: animalController, curve: Curves.easeOut);
            animation = Tween(begin: start, end: end).animate(curve)
              ..addListener(() {
                if (!onResetControllerValue) {
                  offsetDistance = animation.value;
                  setState(() {});
                }
              });

            ///自己滚动
            if (animalController.status == AnimationStatus.completed) {
              animalController.reset();
            }
            if (offsetDistance! > 0) animalController.forward();
            return false;
          },
          child: ScrollConfiguration(
            behavior: MyBehavior(),
            child: widget.child,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    animalController.dispose();
    super.dispose();
  }
}
