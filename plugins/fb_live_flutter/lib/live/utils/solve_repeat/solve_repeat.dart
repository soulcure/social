import 'package:fb_live_flutter/fb_live_flutter.dart';
import 'package:fb_live_flutter/live/event_bus_model/emoji_keyboard_model.dart';
import 'package:fb_live_flutter/live/event_bus_model/room_list_model.dart';
import 'package:fb_live_flutter/live/utils/fb_navigator_observer.dart';
import 'package:fb_live_flutter/live/utils/manager/event_bus_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

export 'solve_repeat_page.dart';

abstract class LivePageHandleInterface {
  Future<bool> popHandle();

  bool get isScreenRotation;

  bool get mounted;

  BuildContext get context;
}

mixin LivePageCommon
    on RouteAware, WidgetsBindingObserver, LivePageHandleInterface
    implements EmojiKeyboardChangeListener {
  void initStateHandle() {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);

    WidgetsBinding.instance!.addObserver(this);
    EmojiKeyboardManager.addOnChangeListener(this);
  }

  @override
  void didPop() {
    WidgetsBinding.instance!.addPostFrameCallback((timeStamp) {
      popHandle();
    });
    super.didPop();
  }

  void didChangeDependenciesHandle() {
    fbLiveRouteObserver.subscribe(
        this, ModalRoute.of(context) as Route<dynamic>);
  }

  @override
  void onDismiss() {
    EventBusManager.eventBus.fire(EmojiKeyBoardModel(height: 0));
  }

  @override
  void didPopNext() {
    super.didPopNext();
    if (mounted && isScreenRotation) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    }
  }

  @override
  void onShow(double height) {
    if (height < 0) {
      height = 0;
    }
    EventBusManager.eventBus.fire(EmojiKeyBoardModel(height: height));
  }

  void deactivateHandle() {
    // ignore: deprecated_member_use
    SystemChrome.setEnabledSystemUIOverlays(
        [SystemUiOverlay.bottom, SystemUiOverlay.top]);
  }

  void disposeHandle() {
    fbLiveRouteObserver.unsubscribe(this);

    EmojiKeyboardManager.removeOnChangeListener(this);
    WidgetsBinding.instance!.removeObserver(this);

    Future.delayed(const Duration(milliseconds: 500)).then((value) {
      roomListSetStateEventBus.fire(LiveRoomListSetStateEvent());
    });
  }
}
