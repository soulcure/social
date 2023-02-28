/*
 * @FilePath       : /social/lib/app/modules/redpack/open_pack/components/open_redpack_detail_transition.dart
 * 
 * @Info           : 
 * 
 * @Author         : Whiskee Chan
 * @Date           : 2022-01-19 15:51:33
 * @Version        : 1.0.0
 * 
 * Copyright 2022 iDreamSky FanBook, All Rights Reserved.
 * 
 * @LastEditors    : Whiskee Chan
 * @LastEditTime   : 2022-01-19 20:46:14
 * 
 */

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:get/get_navigation/src/routes/custom_transition.dart';

enum ORPTransitionStatus {
  START_FADE_IN,
  START_RIGHT_OUT,
}

class OpenRedPackTransition extends CustomTransition {
  /// 当前转场状态
  ORPTransitionStatus status = ORPTransitionStatus.START_FADE_IN;

  /// 构造函数
  @override
  Widget buildTransition(
      BuildContext context,
      Curve curve,
      Alignment alignment,
      Animation<double> animation,
      Animation<double> secondaryAnimation,
      Widget child) {
    //  监听：动画执行过程
    //  - 设置进出场状态修改转场类型
    switch (status) {
      case ORPTransitionStatus.START_FADE_IN:
        if (animation.value == 1) {
          status = ORPTransitionStatus.START_RIGHT_OUT;
        }
        break;
      case ORPTransitionStatus.START_RIGHT_OUT:
        if (animation.value == 0) {
          status = ORPTransitionStatus.START_FADE_IN;
        }
        break;
    }
    return status == ORPTransitionStatus.START_RIGHT_OUT
        ? SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1, 0),
              end: Offset.zero,
            ).animate(animation),
            child: child)
        : FadeTransition(opacity: animation, child: child);
  }
}
