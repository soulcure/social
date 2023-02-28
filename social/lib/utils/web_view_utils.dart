import 'dart:async';

import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:im/common/extension/string_extension.dart';
import 'package:im/core/config.dart';
import 'package:im/loggers.dart';
import 'package:im/utils/universal_platform.dart';
import 'package:pedantic/pedantic.dart';

class WebViewUtils {
  static WebViewUtils _instance;
  static WebViewUtils instance() {
    return (_instance != null) ? _instance : _init();
  }

  static WebViewUtils _init() {
    return _instance = WebViewUtils();
  }

  // 目前只支持android和ios
  Future<void> deleteAll() async {
    if (UniversalPlatform.isAndroid) {
      unawaited(WebStorageManager.instance().android.deleteAllData());
    } else if (UniversalPlatform.isIOS) {
      // 骚操作解决iOS下webview localstorage 缓存问题.
      final webView = HeadlessInAppWebView();
      await webView.run();
      await WebStorageManager.instance().ios.removeDataModifiedSince(
          dataTypes: IOSWKWebsiteDataType.values, date: DateTime(1970));
      await webView.dispose();
    }

    unawaited(CookieManager.instance().deleteAllCookies());
    logger.info('清除webview缓存(页面、cookie、storage等)');
  }

  Future<void> setWebViewToken() async {
    if (Config.token.hasValue) {
      await CookieManager.instance().setCookie(
        url: Uri(scheme: 'https', host: Config.webDomain),
        domain: '.${Config.webDomain}',
        name: 'token',
        value: Config.token,
        // debug模式secure设置为false，方便调试
        isSecure: !Config.isDebug,
        // 没设置cookie有效期在ios部分机型上会设置失败
        maxAge: 365 * 24 * 3600,
      );
    }
  }
}
