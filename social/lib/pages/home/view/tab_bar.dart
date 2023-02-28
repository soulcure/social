import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:im/app/modules/direct_message/controllers/direct_message_controller.dart';
import 'package:im/app/modules/direct_message/views/direct_message_view.dart';
import 'package:im/app/modules/home/controllers/home_scaffold_controller.dart';
import 'package:im/app/modules/task/task_util.dart';
import 'package:im/common/extension/string_extension.dart';
import 'package:im/dlog/dlog_manager.dart';
import 'package:im/hybrid/jpush_util.dart';
import 'package:im/icon_font.dart';
import 'package:im/pages/home/components/red_dot.dart';
import 'package:im/pages/home/model/chat_index_model.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/pages/personal/personal_page.dart';
import 'package:im/themes/const.dart';
import 'package:im/themes/custom_color.dart';
import 'package:im/utils/universal_platform.dart';
import 'package:im/utils/utils.dart';
import 'package:im/widgets/realtime_user_info.dart';
import 'package:pedantic/pedantic.dart';
import 'package:provider/provider.dart';

import '../../../global.dart';

class HomeTabBar extends StatefulWidget {
  static Rx<int> index = 0.obs;
  static ValueNotifier<int> numUnread = ValueNotifier(0);
  static GlobalKey<HomeTabBarState> instanceKey = GlobalKey();
  static const height = 56.0;

  HomeTabBar() : super(key: instanceKey);

  static void gotoIndex(int index) {
    instanceKey.currentState?._gotoIndex(index);
  }

  static int get currentIndex =>
      instanceKey.currentState?._tabBarController?.index ?? 0;

  @override
  State<StatefulWidget> createState() => HomeTabBarState();
}

class HomeTabBarState extends State with TickerProviderStateMixin {
  TabController _tabBarController;
  AnimationController _animationController;

  int get index => _tabBarController.index;

  Worker worker1;
  Worker worker2;

  @override
  void initState() {
    final double initialValue = UniversalPlatform.isMobileDevice
        ? (JPushUtil.hasAppLaunchParameters() ? 0 : 1)
        : 0;
    _animationController = AnimationController(
        value: initialValue, duration: kThemeAnimationDuration, vsync: this);
    _tabBarController = TabController(length: 3, vsync: this);

    // 这里是为了处理代码跳转时收起 tab bar
    ever(HomeScaffoldController.to.windowIndex, _onChangeWindowIndex);
    // 这里是为了手势触发时的显示和隐藏
    ever(HomeScaffoldController.to.dragging, _onToggleDragging);

    super.initState();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _tabBarController.dispose();
    super.dispose();
  }

  void _gotoIndex(int index) {
    if (HomeTabBar.index.value == index) return;
    HomeTabBar.index.value = index;
    _tabBarController.animateTo(index);
    onChangeTab(index);
  }

  void onChangeTab(int index) {
    unawaited(HapticFeedback.lightImpact());

    if (index == 0) {
      final guildId = ChatTargetsModel.instance.selectedChatTarget?.id;
      if (guildId.hasValue) {
        unawaited(TaskUtil.instance.reqTaskByGuildId(guildId));
      }

      if (HomeScaffoldController.to.windowIndex.value != 0) {
        _animationController.reverse();
      }
    } else {
      _animationController.forward();
    }
    HomeTabBar.index.value = index;

    if (index == 1) {
      //fix: 私信在搜索状态下，切换tab后，再回来，也重置未搜索时
      DirectMessageController.to.clearSearchText();
      DirectMessageController.to.resetNoSearchUpdate();
    }
    setState(() {});
  }

  void _onChangeWindowIndex(_) {
    if (HomeScaffoldController.to.windowIndex.value != 0) {
      _animationController.reverse();
      _tabBarController.index = 0;
    } else {
      _animationController.forward();
    }
  }

  void _onToggleDragging(_) {
    if (HomeScaffoldController.to.dragging.value) {
      _animationController.reverse();
    } else if (HomeScaffoldController.to.windowIndex.value == 0) {
      _animationController.forward();
    }
  }

  Widget _tap({Widget icon, String text, int index}) {
    final iconNormalColor =
        Theme.of(context).textTheme.bodyText1.color.withOpacity(0.6);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: <Widget>[
          const SizedBox(height: 11),
          icon,
          sizeHeight5,
          Text(
            text,
            style: TextStyle(
                color: _tabBarController.index == index
                    ? Theme.of(context).primaryColor
                    : iconNormalColor,
                fontSize: 10,
                height: 1),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final iconNormalColor =
        Theme.of(context).textTheme.bodyText1.color.withOpacity(0.6);
    final bgColor =
        isDarkMode(context) ? const Color(0xFF15171A) : Colors.white;
    final bottomPadding = Get.mediaQuery.viewPadding.bottom;
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: SizeTransition(
          axisAlignment: -1,
          sizeFactor: _animationController,
          child: Column(
            children: <Widget>[
              const Divider(height: 0.5),
              Container(
                height: HomeTabBar.height + bottomPadding,
                alignment: Alignment.topCenter,
                padding: EdgeInsets.only(bottom: bottomPadding),
                color: CustomColor(context).backgroundColor3,
                child: TabBar(
                  onTap: (index) {
                    if (HomeTabBar.index.value != index) {
                      switch (index) {
                        case 0:
                          DLogManager.getInstance()
                              .customEvent(actionEventId: 'click_chat_tab');
                          break;
                        case 1:
                          DLogManager.getInstance()
                              .customEvent(actionEventId: 'click_contacts_tab');
                          break;
                        case 2:
                          DLogManager.getInstance()
                              .customEvent(actionEventId: 'click_me_tab');
                      }
                    }

                    onChangeTab(index);
                  },
                  controller: _tabBarController,
                  indicatorColor: Colors.transparent,
                  tabs: <Widget>[
                    _tap(
                        index: 0,
                        icon: RedDotListenable(
                            alignment: Alignment.topLeft,
                            offset: const Offset(20, -4),
                            borderColor: bgColor,
                            valueListenable: GlobalState.totalNumUnread,
                            child: Icon(
                              IconFont.buffTabHome,
                              size: 22,
                              color: _tabBarController.index == 0
                                  ? Theme.of(context).primaryColor
                                  : iconNormalColor,
                            )),
                        text: '频道'.tr),
                    GestureDetector(
                      onDoubleTap: scrollToNextUnread(),
                      behavior: HitTestBehavior.translucent,
                      child: _tap(
                          index: 1,
                          icon: MuteRedDotListenable(
                              alignment: Alignment.topLeft,
                              offset: const Offset(14, -6),
                              borderColor: bgColor,
                              valueListenable:
                                  DirectMessageController.numUnreadMute,
                              child: Icon(
                                IconFont.buffTabMessage,
                                size: 22,
                                color: _tabBarController.index == 1
                                    ? Theme.of(context).primaryColor
                                    : iconNormalColor,
                              )),
                          text: '消息'.tr),
                    ),
                    _tap(
                        index: 2,
                        icon: Opacity(
                          opacity: _tabBarController.index == 2 ? 1 : 0.5,
                          child: Consumer<LocalUser>(
                            builder: (context, user, widget) {
                              return Stack(
                                clipBehavior: Clip.none,
                                children: <Widget>[
                                  RealtimeAvatar(
                                    userId: user.id,
                                    size: 22,
                                    showNftFlag: false,
                                  )
                                ],
                              );
                            },
                          ),
                        ),
                        text: '我'.tr),
                  ],
                ),
              ),
            ],
          )),
    );
  }

  Function scrollToNextUnread() {
    if (_tabBarController.index == 1) {
      return DirectMessageController.to.scrollToRedPoint;
    }
    return null;
  }
}

class HomeTabView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(
          bottom:
              HomeTabBar.height + MediaQuery.of(context).viewPadding.bottom),
      child: ObxValue<RxInt>(
        (index) {
          switch (index.value) {
            case 1:
              return DirectMessageView();
            case 2:
              return PersonalPage();
            default:
              return const SizedBox();
          }
        },
        HomeTabBar.index,
      ),
    );
  }
}
