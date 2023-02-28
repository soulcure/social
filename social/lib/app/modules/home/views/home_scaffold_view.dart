import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/app/modules/home/controllers/home_scaffold_controller.dart';
import 'package:im/common/extension/string_extension.dart';
import 'package:im/core/back_to_desktop.dart';
import 'package:im/dlog/dlog_manager.dart';
import 'package:im/pages/chat_index/chat_index.dart';
import 'package:im/pages/home/model/chat_index_model.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/pages/home/view/tab_bar.dart';
import 'package:im/utils/orientation_util.dart';
import 'package:im/utils/universal_platform.dart';
import 'package:im/web/pages/main/main_window.dart';
import 'package:im/web/utils/show_web_tooltip.dart';
import 'package:im/widgets/cache_widget.dart';
import 'package:im/widgets/top_status_bar.dart';
import 'package:provider/provider.dart';

import '../../../../global.dart';

class HomeScaffoldView extends GetView<HomeScaffoldController> {
  /// 首页颜色是个特殊颜色，不属于主题
  static Color get backgroundColor {
    return const Color(0xFFEDEEF2);
  }

  static const kEmptyView = SizedBox();

  final Widget Function(ChatChannel) buildSecondWindow;
  final Widget Function() buildChatTargetList;
  final Widget Function() buildThirdWindow;
  final Widget Function(BaseChatTarget) buildGuildView;
  final Widget guildViewEmptyWidget;
  final Widget firstWindowTabBar;

  const HomeScaffoldView({
    @required this.buildChatTargetList,
    @required this.buildSecondWindow,
    @required this.buildGuildView,
    @required this.buildThirdWindow,
    this.firstWindowTabBar,
    this.guildViewEmptyWidget,
  });

  @override
  Widget build(BuildContext context) {
    return CacheWidget(
      builder: () => WillPopScope(
        onWillPop: () async {
          if (controller.windowIndex > 0) {
            controller.back();
          } else if (HomeTabBar.instanceKey.currentState.index != 0) {
            HomeTabBar.gotoIndex(0);
          } else {
            await backToDeskTop();
          }
          return false;
        },
        child: Builder(builder: (context) {
          return OrientationBuilder(builder: (context, _) {
            return MultiProvider(
              providers: [
                ChangeNotifierProvider.value(value: ChatTargetsModel.instance),
                ChangeNotifierProvider.value(value: Global.user),
              ],
              child: Material(
                color: HomeScaffoldView.backgroundColor,
                child: Overlay(initialEntries: [
                  OverlayEntry(builder: _buildBody),
                  OverlayEntry(builder: (_) => HomeTabView()),
                  // OverlayEntry(builder: (_) => Dock(key: Dock.instanceKey)),
                  /// Android 在横屏状态下打开应用，在启动页是横屏的，会导致这里不创建 TabBar
                  if (OrientationUtil.portrait || UniversalPlatform.isAndroid)
                    OverlayEntry(
                        builder: (_) => firstWindowTabBar ?? HomeTabBar()),
                ]),
              ),
            );
          });
        }),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    return OrientationBuilder(
      builder: (__, _) {
        if (OrientationUtil.portrait)
          return Stack(
            children: <Widget>[
              Positioned(
                left: Get.width -
                    controller.sideWindowWidth -
                    controller.kSpaceBetweenWindow -
                    8,
                width: controller.sideWindowWidth + 8,
                height: Get.height,
                child: Obx(() {
                  return _wrapWindowSwipe(
                    Visibility(
                      visible: !controller.hideMemberListWindow.value &&
                          GlobalState.selectedChannel.value != null,
                      maintainAnimation: true,
                      maintainState: true,
                      replacement: kEmptyView,
                      child: buildThirdWindow(),
                    ),
                    enable: controller.scrollEnable.value,
                  );
                }),
              ),
              ValueListenableBuilder(
                valueListenable: TopStatusController.to().showStatusUI,
                builder: (context, visible, child) {
                  return AnimatedPositioned(
                      duration: kThemeAnimationDuration,
                      top: (visible
                              ? TopStatusBar.height
                              : controller.windowPadding) +
                          MediaQuery.of(context).padding.top,
                      bottom: 0,
                      width: controller.sideWindowWidth + 8,
                      child: Obx(() {
                        return _wrapWindowSwipe(
                          Offstage(
                              offstage: controller.hideChatIndexWindow.value,
                              child: ChatIndex(
                                buildGuildView: buildGuildView,
                                emptyWidget: guildViewEmptyWidget,
                                chatTargetList: buildChatTargetList(),
                              )),
                          enable: controller.scrollEnable.value,
                        );
                      }));
                },
              ),
              ObxValue<RxDouble>(
                (chatWindowX) {
                  return Positioned(
                    left: chatWindowX.value,
                    width: Get.width,
                    height: Get.height,
                    child: Obx(
                      () {
                        return _wrapWindowSwipe(
                          ValueListenableBuilder(
                            valueListenable: GlobalState.selectedChannel,
                            builder: (context, channel, child) {
                              return CacheWidget(
                                cacheKey: channel.hashCode,
                                builder: () => buildSecondWindow(channel),
                              );
                            },
                          ),
                          enable: controller.scrollEnable.value,
                        );
                      },
                    ),
                  );
                },
                controller.chatWindowX,
              ),
              _buildChatWindowMantelet(),
              TopStatusBar(),
            ],
          );
        else
          return Listener(
            onPointerDown: (event) {
              WebToolTipManager.instance.clear();
            },
            child: Container(
              color: Theme.of(context).dividerTheme.color,
              child: Stack(
                children: [
                  Row(
                    children: [
                      SafeArea(
                          child: SizedBox(
                              width: 342,
                              child: ChatIndex(
                                buildGuildView: buildGuildView,
                                chatTargetList: buildChatTargetList(),
                              ))),
                      const SizedBox(width: 1),
                      Expanded(
                        child: MainWindow(
                          defaultChild: ValueListenableBuilder(
                              valueListenable: GlobalState.selectedChannel,
                              builder: (c, _, child) => buildSecondWindow(
                                  GlobalState.selectedChannel.value)),
                        ),
                      ),
                    ],
                  ),
                  ValueListenableBuilder(
                    valueListenable: TopStatusController.to().showStatusUI,
                    builder: (context, visible, child) => AnimatedPositioned(
                      left: 0,
                      right: 0,
                      height: visible
                          ? (TopStatusBar.height +
                              MediaQuery.of(context).padding.top)
                          : 0,
                      top: visible
                          ? 0
                          : -(TopStatusBar.height +
                              MediaQuery.of(context).padding.top),
                      duration: kThemeAnimationDuration,
                      child: child,
                    ),
                    child: TopStatusBar(),
                  ),
                ],
              ),
            ),
          );
      },
    );
  }

  GestureDetector _wrapWindowSwipe(Widget child,
          {VoidCallback onTap, bool enable = true}) =>
      GestureDetector(
          onHorizontalDragStart: enable ? _onDragStart : null,
          onHorizontalDragUpdate: enable ? _onDragUpdate : null,
          onHorizontalDragEnd: enable ? _onDragEnd : null,
          onTap: enable ? onTap : null,
          child: child);

  void _onDragStart(DragStartDetails details) {
    controller.animationController.stop();
    controller.swipeDistance = 0;
    controller.dragging.value = true;
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (details.delta.dx != 0) Get.focusScope.unfocus();

    controller.swipeDistance += details.delta.dx;
    var value = controller.chatWindowX.value + details.delta.dx;

    final double min =
        checkMemberWindowEnabled() ? controller.minChatWindowX : 0;
    // 限制聊天窗口的拖动范围
    if (value > controller.maxChatWindowX)
      value = controller.maxChatWindowX;
    else if (value < min) value = min;

    controller.chatWindowX.value = value;
  }

  void _onDragEnd(DragEndDetails details) {
    final prospectiveDistance = controller.swipeDistance.abs() +
        (details.velocity.pixelsPerSecond.dx *
                kThemeAnimationDuration.inMilliseconds /
                1000)
            .abs();

    int newIndex = controller.windowIndex.value;
    if (prospectiveDistance > Get.width / 3) {
      if (controller.swipeDistance > 0 && controller.windowIndex > 0)
        newIndex--;
      else if (controller.swipeDistance < 0 && newIndex < 2) newIndex++;
    }

    /// 如果没有选中频道，不可切换到成员列表
    if (!checkMemberWindowEnabled() && newIndex == 2)
      newIndex = controller.windowIndex.value = 1;

    controller.gotoIndex(newIndex, draged: true);
    controller.dragging.value = false;

    /// 如果滑动到聊天公屏页,触发数据上报逻辑
    if (newIndex == 1) {
      channelDataReport();
    }
  }

  void channelDataReport() {
    final c = GlobalState.selectedChannel?.value;
    if (c == null || c.id.noValue || c.guildId.noValue) return;

    /// 如果上一次频道id和当前的频道id相同,不上报数据
    if (c.id == controller.chatChannel?.id) return;
    controller.chatChannel = c;

    DLogManager.getInstance().customEvent(
        actionEventId: 'click_enter_chatid',
        actionEventSubId: c.id ?? '',
        actionEventSubParam: '1',
        pageId: 'page_chitchat_chat',
        extJson: {"guild_id": c.guildId});
  }

  /// 检查是否能够切换到第三屏（成员列表），返回 true 为允许
  bool checkMemberWindowEnabled() {
    final c = GlobalState.selectedChannel.value;
    if (c == null) return false;
    if (c.type == ChatChannelType.guildLive) return false;
    return true;
  }

  /// 浮在聊天窗口上方的挡板
  /// 在非聊天窗口页面时，用于阻挡手势操作
  Widget _buildChatWindowMantelet() {
    return ObxValue<RxInt>(
      (windowIndex) {
        double x;
        switch (windowIndex.value) {
          case 0:
            x = controller.maxChatWindowX;
            break;
          case 1:
            x = 9999;
            break;
          case 2:
            x = controller.minChatWindowX;
            break;
        }
        return Positioned(
          left: x,
          width: Get.width,
          height: Get.height,
          child: Obx(() {
            return _wrapWindowSwipe(
              Container(color: Colors.transparent),
              onTap: () {
                controller.gotoWindow(1);
              },
              enable: controller.scrollEnable.value,
            );
          }),
        );
      },
      controller.windowIndex,
    );
  }
}
