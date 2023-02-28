import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:im/app/theme/app_theme.dart';
import 'package:im/core/http_middleware/http.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

class CircleHeadLoadIndicator extends RefreshIndicator {
  @override
  State<StatefulWidget> createState() {
    return _CircleHeadLoadIndicatorState();
  }
}

class _CircleHeadLoadIndicatorState
    extends RefreshIndicatorState<CircleHeadLoadIndicator>
    with TickerProviderStateMixin {
  AnimationController controller;
  Animation<double> animation;
  double _offset = 0;
  final _image =
      Image.asset('assets/images/circle_loading.png', width: 20, height: 20);

  @override
  void initState() {
    controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    animation = controller.drive(Tween<double>(begin: 0, end: 1));
    super.initState();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget buildContent(BuildContext context, RefreshStatus mode) {
    return Container(
      padding: const EdgeInsets.only(top: 10),
      alignment: Alignment.center,
      height: 60,
      child: () {
        switch (mode) {
          case RefreshStatus.idle:
            return Transform.rotate(
              angle: ((2 * math.pi) / 80) * _offset,
              child: _image,
            );
            break;
          case RefreshStatus.refreshing:
          case RefreshStatus.completed:
            return RotationTransition(
              turns: animation,
              child: _image,
            );
            break;
          case RefreshStatus.failed:
            return Text(
              networkErrorText,
              style: appThemeData.textTheme.caption,
            );
            break;
          default:
            return _image;
        }
      }(),
    );
  }

  @override
  void onOffsetChange(double offset) {
    _offset = offset;
    setState(() {});
  }

  @override
  void onModeChange(RefreshStatus mode) {
    if (mode == RefreshStatus.refreshing) controller.repeat();
  }
}

class CircleFootLoadIndicator extends LoadIndicator {
  const CircleFootLoadIndicator({this.noMore, this.footHeight, Key key})
      : super(key: key, height: footHeight, loadStyle: LoadStyle.ShowAlways);
  final bool noMore;

  final double footHeight;

  @override
  State<CircleFootLoadIndicator> createState() =>
      _CircleFootLoadIndicatorState();
}

class _CircleFootLoadIndicatorState
    extends LoadIndicatorState<CircleFootLoadIndicator> {
  @override
  Widget buildContent(BuildContext context, LoadStatus mode) {
    return Container(
      height: widget.footHeight,
      alignment: Alignment.center,
      padding: EdgeInsets.only(bottom: Get.mediaQuery.padding.bottom),
      child: () {
        if (mode == LoadStatus.loading)
          return const CircleLoadingIndicator();
        else if (mode == LoadStatus.failed)
          return Text(
            "- 加载失败，请检查网络 -",
            style: appThemeData.textTheme.headline2.copyWith(fontSize: 11),
          );
        else if ((mode == LoadStatus.idle || mode == LoadStatus.canLoading) &&
            widget.noMore)
          return Text(
            "- 没有更多了 -",
            style: appThemeData.textTheme.headline2.copyWith(fontSize: 11),
          );
        else
          return const SizedBox();
      }(),
    );
  }
}

class CircleLoadingIndicator extends StatefulWidget {
  const CircleLoadingIndicator({Key key}) : super(key: key);

  @override
  State<CircleLoadingIndicator> createState() => _CircleLoadingIndicatorState();
}

class _CircleLoadingIndicatorState extends State<CircleLoadingIndicator>
    with SingleTickerProviderStateMixin {
  AnimationController controller;
  Animation<double> animation;
  final _image =
      Image.asset('assets/images/circle_loading.png', width: 20, height: 20);

  @override
  void initState() {
    controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    animation = controller.drive(Tween<double>(begin: 0, end: 1));
    controller.repeat();
    super.initState();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: animation,
      child: _image,
    );
  }
}

/// * 透明的蒙层
class CircleLayerView extends StatelessWidget {
  final Function onTap;

  const CircleLayerView({this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onVerticalDragStart: (_) {
        onTap();
      },
      onHorizontalDragEnd: (_) {
        onTap();
      },
      behavior: HitTestBehavior.translucent,
      child: Container(),
    );
  }
}
