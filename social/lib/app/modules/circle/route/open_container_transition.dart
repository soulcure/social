import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import 'open_container.dart';

typedef OCGetController<T extends GetxController> = Function();

typedef PreAction = Function();

class OpenContainerTransition<T extends GetxController>
    extends StatelessWidget {
  const OpenContainerTransition({
    Key key,
    this.controller,
    this.tag,
    this.openWidget,
    this.outSideWidget,
    this.transitionDuration = const Duration(milliseconds: 300),
    this.routeSettings,
    this.preAction,
  }) : super(key: key);

  ///Get控制器
  final OCGetController<T> controller;

  ///控制器Tag
  final String tag;

  ///展开的内部组件
  final Widget openWidget;

  ///外部的未展开组件
  final Widget outSideWidget;
  final Duration transitionDuration;

  ///路由设置
  final RouteSettings routeSettings;

  ///路由跳转前的预处理方法
  final PreAction preAction;

  @override
  Widget build(BuildContext context) {
    return OpenContainer(
      routeSettings: routeSettings,
      closedElevation: 0,
      openElevation: 0,
      transitionDuration: transitionDuration,
      openShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      closedBuilder: (context, action) {
        return GestureDetector(
          onTap: () {
            preAction?.call();
            Get.put<T>(controller.call(), tag: tag);
            action();
          },
          child: outSideWidget,
        );
      },
      openBuilder: (context, action) => _DeleteController<T>(
        tag: tag,
        child: openWidget,
      ),
    );
  }
}

class _DeleteController<T extends GetxController> extends StatefulWidget {
  final String tag;
  final Widget child;

  const _DeleteController({
    Key key,
    @required this.child,
    @required this.tag,
  }) : super(key: key);

  @override
  State createState() => _DeleteControllerState<T>();
}

class _DeleteControllerState<T extends GetxController>
    extends State<_DeleteController<T>> {
  @override
  Widget build(BuildContext context) {
    return widget.child;
  }

  @override
  void dispose() {
    Get.delete<T>(tag: widget.tag);
    super.dispose();
  }
}
