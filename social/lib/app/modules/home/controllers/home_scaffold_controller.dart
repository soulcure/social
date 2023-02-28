import 'dart:ui';

import 'package:flutter/animation.dart';
import 'package:get/get.dart';
import 'package:im/app/modules/direct_message/controllers/direct_message_controller.dart';
import 'package:im/app/routes/app_pages.dart';
import 'package:im/pages/home/model/chat_index_model.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/pages/home/view/tab_bar.dart';
import 'package:im/utils/orientation_util.dart';
import 'package:pedantic/pedantic.dart';
import 'package:quest_system/quest_system.dart';

class HomeScaffoldController extends GetxController
    with GetSingleTickerProviderStateMixin {
  static HomeScaffoldController get to => Get.find();

  final kSpaceBetweenWindow = 8.0;

  /// 当前展示的窗口索引 0~2
  final RxInt windowIndex = 0.obs;
  final RxDouble chatWindowX = 0.0.obs;

  final RxBool hideChatIndexWindow = false.obs;
  final RxBool hideMemberListWindow = true.obs;
  final RxDouble chatWindowXWithTextAlpha = 0.0.obs;
  final RxBool scrollEnable = false.obs;

  double _chatWindowAnimationBegin;
  double _chatWindowAnimationEnd;
  AnimationController animationController;

  /// 聊天窗口能达到的最小 x 坐标
  double get minChatWindowX => -(sideWindowWidth + kSpaceBetweenWindow * 2);

  /// 聊天窗口能达到的最大 x 坐标
  double get maxChatWindowX => sideWindowWidth + kSpaceBetweenWindow;

  /// 滑动屏幕时的距离
  double swipeDistance;

  RxBool dragging = false.obs;

  /// 数据上报用来记录上一次频道信息
  ChatChannel chatChannel;

  double get windowPadding {
    final topPadding = Get.mediaQuery.padding.top;
    if (topPadding == 0) return 30;
    return topPadding <= 34 ? 10 : 0;
  }

  @override
  void onInit() {
    super.onInit();
    animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    final animation =
        animationController.drive(CurveTween(curve: Curves.easeOut));
    animationController.addListener(() {
      chatWindowX.value = lerpDouble(
        _chatWindowAnimationBegin,
        _chatWindowAnimationEnd,
        animation.value,
      );
    });

    ChatTargetsModel.instance.addListener(() {
      final target = ChatTargetsModel.instance.selectedChatTarget;
      if (target == null) {
        scrollEnable.value = true;
        return;
      }
      //服务器被封禁，不允许滑动
      scrollEnable.value = !((target as GuildTarget)?.isBan ?? false);
    });
    chatWindowX.value = sideWindowWidth + kSpaceBetweenWindow;
    ever(chatWindowX, _updateVisibleWindows);
  }

  @override
  void onReady() {
    super.onReady();
  }

  @override
  void onClose() {
    animationController.dispose();
    windowIndex.close();
    chatWindowX.close();
    hideChatIndexWindow.close();
    hideMemberListWindow.close();
    chatWindowXWithTextAlpha.close();
    scrollEnable.close();
  }

  Future gotoIndex(int index,
      {bool animate = true, bool draged = false}) async {
    ///切换路由发送任务触发数据
    RouteTrigger.instance.dispatch(
      QuestTriggerData(
        condition: RouteCondition(
          routeName: () {
            switch (index) {
              case 0:
                return Routes.FIRST_SCREEN;
              case 1:
                return Routes.SECOND_SCREEN;
              case 2:
                return Routes.THIRD_SCREEN;
            }
          }(),
          isRemove: false,
        ),
      ),
    );
    if (index != windowIndex.value) Get.focusScope.unfocus();

    windowIndex.value = index;

    _chatWindowAnimationBegin = chatWindowX.value;
    switch (windowIndex.value) {
      case 0:
        _chatWindowAnimationEnd = maxChatWindowX;
        break;
      case 1:
        _chatWindowAnimationEnd = 0;
        break;
      case 2:
        _chatWindowAnimationEnd = minChatWindowX;
        break;
    }

    windowIndex.value = index;

    if (animate) {
      if (!draged) await Future.delayed(const Duration(milliseconds: 150));
      animationController.reset();
      unawaited(animationController.forward());
    } else {
      chatWindowX.value = _chatWindowAnimationEnd;
    }
  }

  bool get canChatWindowVisible =>
      OrientationUtil.landscape ||
      windowIndex.value == 1 ||
      DirectMessageController.directChatPageVisible;

  void back() {
    gotoIndex(windowIndex.value - 1);
  }

  /// 侧边窗口的宽度
  double get sideWindowWidth {
    const kPeekChatWindowWidth = 0.1;
    return Get.width * (1 - kPeekChatWindowWidth);
  }

  void _updateVisibleWindows(double chatWindowX) {
    // 切换侧边窗口的显示
    hideMemberListWindow.value = chatWindowX >= 0;
    hideChatIndexWindow.value = chatWindowX <= 0;
    chatWindowXWithTextAlpha.value = chatWindowX;
  }

  Future<void> gotoWindow(int index, {bool animate = true}) async {
    HomeTabBar.gotoIndex(0);
    await gotoIndex(index, animate: animate);
  }
}
