import 'dart:async';
import 'dart:math';

import 'package:fb_live_flutter/live/bloc_model/like_click_bloc_model.dart';
import 'package:fb_live_flutter/live/model/room_infon_model.dart';
import 'package:fb_live_flutter/live/net/api.dart';
import 'package:fb_live_flutter/live/pages/live_room/widget/up_click_widget.dart';
import 'package:fb_live_flutter/live/pages/live_room/widget/up_like_add.dart';
import 'package:fb_live_flutter/live/utils/log/live_log_up.dart';
import 'package:fb_live_flutter/live/utils/ui/frame_size.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'audiences_bottom_widget.dart';
import 'image_show.dart';

class MathPoint {
  MathPoint(this.x, this.y);

  double x, y;
}

class UpLikeGesture extends StatefulWidget {
  final Widget child;
  final bool? isAnchor;
  final String? roomId;
  final UpLikeClickBlock upLikeClickBlock;
  final RoomInfon? roomInfoObject;

  const UpLikeGesture({
    required this.child,
    required this.isAnchor,
    required this.roomId,
    required this.upLikeClickBlock,
    required this.roomInfoObject,
  });

  @override
  _UpLikeGestureState createState() => _UpLikeGestureState();
}

class _UpLikeGestureState extends State<UpLikeGesture> {
  // 记录时间
  DateTime touchTime = DateTime.now();

  // 记录坐标
  MathPoint touchPoint = MathPoint(-999, -999);

  Timer? _timer;

  bool isClickShow = false;

  @override
  Widget build(BuildContext context) {
    if (widget.isAnchor!) {
      return widget.child;
    }
    return GestureDetector(
      onTapUp: (details) {
        // 当前时间-上次记录的时间
        final t = DateTime.now().millisecondsSinceEpoch -
            touchTime.millisecondsSinceEpoch;
        // 显示的视图高度
        final viewSize = 58.px + 20.px;
        final resultPosition = viewSize + (viewSize / 2);
        // 获取当前坐标
        final currentPoint = MathPoint(details.localPosition.dx,
            details.localPosition.dy - resultPosition - 10.px);
        // 记录当前时间
        touchTime = DateTime.now();
        // 记录当前坐标
        touchPoint = currentPoint;
        // 判断两次间隔是否小于300毫秒
        if (t < 300 || isClickShow) {
          isClickShow = true;

          touchTime = DateTime.fromMicrosecondsSinceEpoch(0);

          /// 【2021 12.27】触动反馈优化
          HapticFeedback.lightImpact();

          BlocProvider.of<LikeClickBlocModel>(context).add(1);

          showLike(currentPoint.x, currentPoint.y);

          _startTimerUpLick(
            () async {
              final int count =
                  BlocProvider.of<LikeClickBlocModel>(context).count;
              final Map status = await Api.thumbUp(widget.roomId, count);
              if (status["code"] == 200) {
                LiveLogUp.audioLike(widget.roomInfoObject!);
                widget.upLikeClickBlock(count, 'licknum');
                BlocProvider.of<LikeClickBlocModel>(context).reset();
                isClickShow = false;
              }
            },
          );
        }
      },
      behavior: HitTestBehavior.translucent,
      child: widget.child,
    );
  }

  // 清除定时器
  void _cancelTimer() {
    _timer?.cancel();
  }

  void _startTimerUpLick(VoidCallback? cancelCallBack) {
    _cancelTimer();
    // 创建定时器
    _timer = Timer.periodic(const Duration(milliseconds: 300), (timer) {
      try {
        _cancelTimer();
        if (cancelCallBack != null) {
          cancelCallBack();
        }
      } catch (e) {
        _cancelTimer();
      }
    });
  }

  void showLike(double dx, double dy) {
    final overlayState = Overlay.of(context)!;
    OverlayEntry? overlayEntry;
    const double width = 50;
    const double height = 50;
    final double x = dx - width / 2;
    final double y = dy + height / 2;

    final int count = BlocProvider.of<LikeClickBlocModel>(context).count;

    overlayEntry = OverlayEntry(builder: (context) {
      return Stack(
        children: <Widget>[
          Positioned(
            left: x,
            top: y,
            child: LikeView(
              overlayEntry: overlayEntry,
              count: count,
            ),
          ),
        ],
      );
    });

    ///插入全局悬浮控件
    overlayState.insert(overlayEntry);
  }
}

class LikeView extends StatefulWidget {
  const LikeView({this.overlayEntry, this.count});

  final OverlayEntry? overlayEntry;
  final int? count;

  @override
  State<StatefulWidget> createState() {
    return LikeViewState();
  }
}

class LikeViewState extends State<LikeView> with TickerProviderStateMixin {
  AnimationController? controller;
  late Animation<double> display;

  AnimationController? controllerScale;
  late Animation<double> scale;

  /// 不能包含+1，效果不好看，也不是表情
  /// 【2021 12.29】直播间双击点赞表情调整
  String imagePath = likeIconList[Random().nextInt(5)];

  @override
  void initState() {
    super.initState();
    controllerScale = AnimationController(
        duration: const Duration(milliseconds: 200), vsync: this);
    scale = Tween<double>(
      begin: 0,
      end: 48,
    ).animate(
      CurvedAnimation(parent: controllerScale!, curve: Curves.ease),
    );

    controller = AnimationController(
        duration: const Duration(milliseconds: 500), vsync: this)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          widget.overlayEntry!.remove();
        }
      });
    // 动画二组
    // 消失动画
    display = Tween<double>(
      begin: 1,
      end: 0,
    ).animate(
      /// 0.6开始，执行颜色变化动画
      CurvedAnimation(parent: controller!, curve: const Interval(0.6, 1)),
    );
    controller!.forward();

    controllerScale!.forward();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Column(
        children: [
          UpLikeAdd(widget.count),
          SizedBox(
            height: 58.px,
            child: AnimatedBuilder(
              builder: (context, child) {
                final double addValue = 10 - (display.value * 10);
                final size = scale.value + addValue;

                return Opacity(
                  opacity: display.value,
                  child: ImageShow(imagePath, size, size),
                );
              },
              animation: controller!,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    controller?.stop();
    controller?.dispose();
    controllerScale?.stop();
    controllerScale?.dispose();
    super.dispose();
  }
}
