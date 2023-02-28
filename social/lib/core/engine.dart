import 'package:flutter/widgets.dart';
import 'package:fluwx/fluwx.dart';
import 'package:im/core/config.dart';
import 'package:im/core/error_reporter.dart';
import 'package:im/core/http_middleware/http.dart';

// import 'package:im/core/openinstall.dart';
import 'package:im/global.dart';
import 'package:im/utils/universal_platform.dart';
import 'package:pedantic/pedantic.dart';

class Engine {
  // 自定义登录回调事件
  static bool initialized = false;

  static WidgetsBinding _widgetsBinding;

  /// app启动初始化操作
  static Future<void> init() async {
    await Global.user.read();
    // if (UniversalPlatform.isMobileDevice) Openinstall.init();
    // 以下移到app中提前初始化
    // final savedEnvVar = StorageService.to.getInt(Config.networkEnvSharedKey);
    // if (savedEnvVar != null) {
    //   Config.env = Env.values[savedEnvVar];
    // } else if (Config.isDebug) {
    //   Config.env = Env.test;
    // }
    // 全局错误捕获上报
    ErrorReporter.init();

    Http.init();
    if (UniversalPlatform.isMobileDevice)
      // 注册微信api
      unawaited(registerWxApi(
        appId: Config.appId,
        universalLink: Config.universalLink,
      ));

    // 初始化完毕
    initialized = true;
  }

  /// 在[allowRender]之前, flutter engine将不会任何渲染frame，但在启动时，原生闪屏
  /// 界面不受影响
  static void deferRender(WidgetsBinding widgetsBinding) {
    if (!UniversalPlatform.isMobileDevice) return;
    _widgetsBinding = widgetsBinding;
    _widgetsBinding?.deferFirstFrame();
  }

  /// 通知framework可让engine渲染frame了
  static void allowRender() {
    if (!UniversalPlatform.isMobileDevice) return;
    _widgetsBinding?.allowFirstFrame();
    _widgetsBinding = null;
  }
}
