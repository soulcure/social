import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/app/modules/circle/views/portrait/widgets/circle_loading_item.dart';
import 'package:im/app/theme/app_theme.dart';
import 'package:im/core/widgets/button/fade_button.dart';
import 'package:im/svg_icons.dart';
import 'package:im/utils/orientation_util.dart';
import 'package:im/widgets/app_bar/appbar_builder.dart';
import 'package:im/widgets/svg_tip_widget.dart';

///整个圈子页面的加载态
class CircleNewLoadingView extends StatefulWidget {
  final Future<dynamic> Function() future;

  const CircleNewLoadingView(this.future);

  static Widget get sortBar => Container(
        height: 36,
        alignment: Alignment.bottomLeft,
        padding: const EdgeInsets.only(left: 16, bottom: 3),
        child: Container(
          decoration: BoxDecoration(
            color: appThemeData.dividerColor,
            borderRadius: BorderRadius.circular(2),
          ),
          width: 56,
          height: 18,
        ),
      );

  @override
  _CircleLoadingViewState createState() => _CircleLoadingViewState();
}

class _CircleLoadingViewState extends State<CircleNewLoadingView>
    with SingleTickerProviderStateMixin {
  AnimationController controller;
  Animation<double> animation;

  @override
  void initState() {
    controller =
        AnimationController(duration: const Duration(seconds: 1), vsync: this);
    animation = Tween<double>(begin: .4, end: 1).animate(controller);
    controller.repeat(reverse: true);
    super.initState();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: widget.future().timeout(const Duration(seconds: 15)),
      builder: (context, snapshot) {
        final loadError = snapshot.connectionState == ConnectionState.done &&
            snapshot.hasError;
        return Scaffold(
          backgroundColor: loadError
              ? appThemeData.backgroundColor
              : const Color(0xFFEDEFF2),
          appBar:
              OrientationUtil.portrait ? const FbAppBar.diyTitleView() : null,
          body: () {
            if (loadError) {
              return GestureDetector(
                  onTap: () {
                    setState(() {});
                  },
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 40),
                          child: SvgTipWidget(
                            svgName: SvgIcons.noNetState,
                            desc: '加载失败，请重试'.tr,
                          ),
                        ),
                        FadeButton(
                          onTap: () => setState(() {}),
                          decoration: BoxDecoration(
                            color: appThemeData.primaryColor,
                            borderRadius: BorderRadius.circular(5),
                          ),
                          width: 180,
                          height: 36,
                          child: Text(
                            '重新加载'.tr,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ));
            } else {
              return Container(
                color: Colors.white,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnimatedBuilder(
                      animation: animation,
                      builder: (context, child) => Opacity(
                        opacity: animation.value,
                        child: child,
                      ),
                      child: _head(),
                    ),
                    Divider(height: .5, color: appThemeData.dividerColor),
                    AnimatedBuilder(
                      animation: animation,
                      builder: (context, child) => Opacity(
                        opacity: animation.value,
                        child: child,
                      ),
                      child: CircleNewLoadingView.sortBar,
                    ),
                    _body(),
                  ],
                ),
              );
            }
          }(),
        );
      },
    );
  }

  Widget _head() {
    return Padding(
      padding: const EdgeInsets.only(left: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 88,
            child: Row(
              children: [
                SizedBox(
                  width: 64,
                  height: 64,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: appThemeData.dividerColor,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _greyBlock(width: 102, height: 22),
                    const SizedBox(height: 8),
                    _greyBlock(width: 240, height: 16),
                  ],
                )
              ],
            ),
          ),
          SizedBox(
            height: 52,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _greyBlock(width: 336, height: 16),
                const SizedBox(height: 4),
                _greyBlock(width: 178, height: 16),
              ],
            ),
          ),
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: List.generate(
                6,
                (index) => Center(
                    child: Padding(
                  padding: const EdgeInsets.only(right: 24),
                  child: _greyBlock(width: 64, height: 20),
                )),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Expanded _body() {
    return Expanded(
      child: Container(
        color: appThemeData.scaffoldBackgroundColor,
        child: ListView(
          children: List.generate(
            3,
            (index) => Container(
              color: Colors.white,
              margin: const EdgeInsets.only(bottom: 8),
              child: AnimatedBuilder(
                animation: animation,
                builder: (context, child) => Opacity(
                  opacity: animation.value,
                  child: child,
                ),
                child: const CircleLoadingItem(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _greyBlock({double width, double height}) {
    return Container(
      decoration: BoxDecoration(
        color: appThemeData.dividerColor,
        borderRadius: BorderRadius.circular(2),
      ),
      width: width,
      height: height,
    );
  }
}

///普通列表加载态
class CircleLoadingListView extends StatefulWidget {
  const CircleLoadingListView({Key key}) : super(key: key);

  @override
  _CircleLoadingListViewState createState() => _CircleLoadingListViewState();
}

class _CircleLoadingListViewState extends State<CircleLoadingListView>
    with SingleTickerProviderStateMixin {
  AnimationController controller;
  Animation<double> animation;

  @override
  void initState() {
    controller =
        AnimationController(duration: const Duration(seconds: 1), vsync: this);
    animation = Tween<double>(begin: 1, end: 0.4).animate(controller);
    controller.repeat(reverse: true);
    super.initState();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverOverlapInjector(
          handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
        ),
        SliverToBoxAdapter(
          child: Container(
            color: Colors.white,
            child: AnimatedBuilder(
              animation: animation,
              builder: (context, child) => Opacity(
                opacity: animation.value,
                child: child,
              ),
              child: CircleNewLoadingView.sortBar,
            ),
          ),
        ),
        SliverList(
          delegate: SliverChildListDelegate(
            List.generate(
              3,
              (index) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                color: Colors.white,
                child: AnimatedBuilder(
                  animation: animation,
                  builder: (context, child) => Opacity(
                    opacity: animation.value,
                    child: child,
                  ),
                  child: const CircleLoadingItem(),
                ),
              ),
            ),
          ),
        )
      ],
    );
  }
}

///网格列表加载态
class CircleLoadingGridView extends StatefulWidget {
  const CircleLoadingGridView({Key key}) : super(key: key);

  @override
  _CircleLoadingGridViewState createState() => _CircleLoadingGridViewState();
}

class _CircleLoadingGridViewState extends State<CircleLoadingGridView>
    with SingleTickerProviderStateMixin {
  AnimationController controller;
  Animation<double> animation;

  @override
  void initState() {
    controller =
        AnimationController(duration: const Duration(seconds: 1), vsync: this);
    animation = Tween<double>(begin: 1, end: 0.4).animate(controller);
    controller.repeat(reverse: true);
    super.initState();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverOverlapInjector(
          handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
        ),
        SliverToBoxAdapter(
          child: Container(
            color: Colors.white,
            child: AnimatedBuilder(
              animation: animation,
              builder: (context, child) => Opacity(
                opacity: animation.value,
                child: child,
              ),
              child: CircleNewLoadingView.sortBar,
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(10),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              mainAxisSpacing: 4,
              crossAxisSpacing: 8,
              crossAxisCount: 2,
              mainAxisExtent: 247,
            ),
            delegate: SliverChildListDelegate(
              List.generate(
                6,
                (_) => AnimatedBuilder(
                  animation: animation,
                  builder: (context, child) => Opacity(
                    opacity: animation.value,
                    child: child,
                  ),
                  child: const CircleLoadingItem(grid: true),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
