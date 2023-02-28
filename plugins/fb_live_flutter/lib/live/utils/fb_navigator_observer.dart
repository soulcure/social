import 'package:fb_live_flutter/live/event_bus_model/goods_html_bus.dart';
import 'package:fb_live_flutter/live/utils/func/router.dart';
import 'package:fb_live_flutter/live/utils/func/utils_class.dart';
import 'package:fb_live_flutter/live/utils/other/float/float_mode.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../event_bus_model/sheet_gifts_bottom_model.dart';
import 'config/route_path.dart';
import 'manager/event_bus_manager.dart';

class FBNavigatorObserver extends NavigatorObserver {
  @override
  void didPop(Route route, Route? previousRoute) {
    /// 移除路由名【含空】
    RouteUtil.routeNamesContainNull.remove(route.settings.name);

    /// 对话框返回到了直播页也需要刷新【是否直播页面/是否包含直播页面】
    /// 【2021 12.21】解决直播带货对话框关闭后直播页面前后台切换出现错误
    popPreviousHandle(previousRoute);

    /// 防止打开的是对话框，但以路由形式，导致错乱
    if (!strNoEmpty(route.settings.name) ||
        route.settings.name == DialogRoutePath.confirmDialog) {
      return;
    }

    /// 移除路由名
    RouteUtil.routeNames.remove(route.settings.name);

    /// 延迟100毫秒防止路由没删除完就去判断最后一个路由
    /// 出现了分享页面返回小窗口还在的问题
    Future.delayed(const Duration(milliseconds: 100)).then((value) {
      popHandle(route);
    });
  }

  void popPreviousHandle(Route? previousRoute) {
    /// 【2021 12.23】路由问题
    /// 2.路由previoursRoute的判空需要处理
    if ((previousRoute?.settings.name ?? "") == "/liveRoom") {
      RouteUtil.routeHasLive = true;
    }
  }

  void popHandle(Route route) {
    /// 【2021 11.30】修复分享好友后返回路由页面出现小窗口消失
    /// 【2021 12.23】3.endIsLive的判断做好数组边界处理
    final bool endIsLive = listNoEmpty(RouteUtil.routeNames) &&
        RouteUtil.routeNames[RouteUtil.routeNames.length - 1] == "/liveRoom";

    if (route.settings.name == "/chooseGifts") {
      EventBusManager.eventBus.fire(SheetGiftsBottomModel(height: 0));
    } else if (route.settings.name == "/liveRoom") {
      RouteUtil.routeHasLive = false;
    } else if (route.settings.name == RoutePath.livePreviewPage) {
      RouteUtil.routeHasPreView = false;
      RouteUtil.routeIsPreview = false;
    } else if (endIsLive) {
      /// 关闭的是"直播带货/分享"UI，需要隐藏小窗口且播放直播页面的画面。

      floatWindow.close();
    }
  }

  @override
  void didPush(Route route, Route? previousRoute) {
    super.didPush(route, previousRoute);

    /// 记录路由名【含空】
    RouteUtil.routeNamesContainNull.add(route.settings.name);

    /// 防止打开的是对话框，但以路由形式，导致错乱
    if (!strNoEmpty(route.settings.name) ||
        route.settings.name == DialogRoutePath.confirmDialog) {
      return;
    }

    /// 记录路由名
    RouteUtil.routeNames.add(route.settings.name);

    pushHandle(route);
  }

  void pushHandle(Route route) {
    if (route.settings.name == "/liveRoom") {
      RouteUtil.routeHasLive = true;
      // RouteUtil.routeIsLive = true;
    } else if (route.settings.name == RoutePath.livePreviewPage) {
      RouteUtil.routeHasPreView = true;
      RouteUtil.routeIsPreview = true;
    } else if (RouteUtil.routeHasLive) {
      /// 打开的是直播带货的url，需要显示小窗口

      /// web不需要处理
      if (kIsWeb) {
        return;
      }

      goodsHtmlBus.fire(GoodsIosShowWindowEvenModel(true));
    }
  }

  @override
  void didReplace({Route? newRoute, Route? oldRoute}) {
    final String oldName = oldRoute?.settings.name ?? '';
    final String newName = newRoute?.settings.name ?? '';

    /// 如果路由名字列表【包含空的】才去做替换操作
    if (listNoEmpty(RouteUtil.routeNamesContainNull)) {
      final int indexRoute = RouteUtil.routeNamesContainNull.length - 1;
      if (RouteUtil.routeNamesContainNull[indexRoute] == oldName) {
        RouteUtil.routeNamesContainNull[indexRoute] = newName;
      }
    }

    /// 旧路由名字和新路由名字都不为空才去处理
    if (strNoEmpty(oldName) && strNoEmpty(newName)) {
      final int indexRouteNoteNull = RouteUtil.routeNames.length - 1;
      if (RouteUtil.routeNames[indexRouteNoteNull] == oldName) {
        RouteUtil.routeNames[indexRouteNoteNull] = newName;
      }
    }

    popHandle(oldRoute!);
    pushHandle(newRoute!);
  }

  /// 修复路由记录层面出错
  /// 【2021 12.15】修复obs开播过后点开播返回直播列表再点开播无响应；
  @override
  void didRemove(Route route, Route? previousRoute) {
    super.didRemove(route, previousRoute);

    /// 移除路由名【含空】
    RouteUtil.routeNamesContainNull.remove(route.settings.name);

    /// 防止打开的是对话框，但以路由形式，导致错乱
    if (!strNoEmpty(route.settings.name) ||
        route.settings.name == DialogRoutePath.confirmDialog) {
      return;
    }

    /// 移除路由名
    RouteUtil.routeNames.remove(route.settings.name);
  }
}

/// 【Android端】主播点其他直播弹出提示后点小窗再返回小窗不弹出
/// 原因：
/// 1.fbLiveRouteObserver设置了范型为PageRoute，对话框是DialogRoute；
/// 2.因为1所以当提示存在的时进入直播间再返回不会触发didPop;
/// 解决方案：
/// 1.fbLiveRouteObserver设置范型为Route<dynamic>；
final fbLiveRouteObserver = RouteObserver<Route<dynamic>>();

/// 预览【路由观察器】
final previewRouteObserver = RouteObserver<Route<dynamic>>();
