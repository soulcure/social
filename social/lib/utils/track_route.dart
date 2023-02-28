import 'package:flutter/cupertino.dart';
import 'package:im/app/routes/app_pages.dart' as get_pages show Routes;
import 'package:im/common/extension/string_extension.dart';
import 'package:im/routes.dart';
import 'package:im/utils/texture_overlap_notifier.dart';

/// 监测页面间的路由跳转
class PageRouterObserver extends RouteObserver<PageRoute> {
  final List<Route> _histories = [];
  static final instance = PageRouterObserver();

  // 由于htmlPage与小程序都使用了webview,并且webview在android中使用了hybird模式调用原生
  // 此模式在有纹理重叠时导致卡死，所以需要在使用webview的页面发送事件通知视频小窗隐藏
  bool isWebViewRouteEvent(String routeName) {
    if (routeName == null || routeName.isEmpty) return false;
    return routeName == htmlRoute ||
        routeName.startsWith(get_pages.Routes.MINI_PROGRAM_PAGE);
  }

  @override
  void didPush(Route route, Route previousRoute) {
    super.didPush(route, previousRoute);
    final name = route.settings.name;
    if (name.hasValue) {
      _histories.add(route);
      if (isWebViewRouteEvent(name))
        TextureOverlapNotifier.instance
            .emit(TextureOverlapEvent(overlap: true));
    }
  }

  @override
  void didPop(Route route, Route previousRoute) {
    super.didPop(route, previousRoute);
    final name = route.settings.name;
    if (name.hasValue) {
      _histories.remove(route);
      if (isWebViewRouteEvent(name))
        TextureOverlapNotifier.instance.emit(TextureOverlapEvent());
    }
  }

  @override
  void didReplace({Route newRoute, Route oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (_histories.isNotEmpty && _histories.last == oldRoute) {
      _histories.remove(oldRoute);
      _histories.add(newRoute);
      final name = newRoute.settings.name;
      if (name.hasValue) {
        if (isWebViewRouteEvent(name))
          TextureOverlapNotifier.instance
              .emit(TextureOverlapEvent(overlap: true));
      }
    }
  }

  @override
  void didRemove(Route route, Route previousRoute) {
    super.didRemove(route, previousRoute);
    _histories.remove(route);
    final name = route.settings.name;
    if (name.hasValue) {
      if (isWebViewRouteEvent(name))
        TextureOverlapNotifier.instance.emit(TextureOverlapEvent());
    }
  }

  /// 检测回退栈中是否包含某个页面
  bool hasPage(String page) {
    return _histories.any((p) => p.settings.name.split('?')[0] == page);
  }

  /// 最顶部的页面
  Route get topPage => _histories.isNotEmpty ? _histories.last : null;

  /// * 页面是否在顶部
  bool routeIsTop(String name) {
    return topPage.settings.name == name;
  }

  Route getRoute(bool Function(Route route) test) {
    return _histories.firstWhere(test, orElse: () => null);
  }

  /// * 当前路由name是否已打开
  Route getRouteByName(String name) =>
      _histories.firstWhere((p) => p.settings.name == name, orElse: () => null);
}

/// 监听路由变化，是否打开WebView,决定是否隐藏视频小窗
/// 目前Android端为了解决H5的一个黑屏问题，设置了混杂模式，导致与texture视图重叠(比如直播或视频小窗化）时卡死闪退
class WebViewRouteEvent {
  bool push;

  WebViewRouteEvent({this.push = false});
}
