import 'package:fb_live_flutter/live/pages/preview/preview_overlay.dart';
// import 'package:fb_live_flutter/utils/texture_overlap_notifier.dart';
import 'package:flutter/material.dart';

import '../ui/draggable_widget.dart';

/// 小窗口-监听webview路由材料
mixin WebViewRouteMix on State<DraggableView> {
  // 是否存在webViewRoute，存在则不显示视图
  bool isWebViewRoute = false;

  // 小窗口局部刷新key
  GlobalKey contentStateKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    // 监听是否webView路由
    // TextureOverlapNotifier.instance.listen((event) {
    //   isWebViewRoute = event.overlap;
    //   contentStateKey.currentState?.setState(() {});
    // });
  }
}

/// 预览小窗口-监听webview路由材料
mixin PreViewWebViewRouteMix on State<DraggablePreView> {
  // 是否存在webViewRoute，存在则不显示视图
  bool isWebViewRoute = false;

  // 小窗口局部刷新key
  GlobalKey contentStateKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    // 监听是否webView路由
    // TextureOverlapNotifier.instance.listen((event) {
    //   isWebViewRoute = event.overlap;
    //   contentStateKey.currentState?.setState(() {});
    // });
  }
}
