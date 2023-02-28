import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:dynamic_view/dynamic_view.dart';
import 'package:fb_live_flutter/fb_live_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bugly/flutter_bugly.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:get/get.dart';
import 'package:im/app.dart';
import 'package:im/core/config.dart';
import 'package:im/db/db.dart';
import 'package:im/hybrid/webrtc/room_manager.dart';
import 'package:im/loggers.dart';
import 'package:im/pages/home/model/text_channel_util.dart';
import 'package:im/pages/logging/let_log.dart';
import 'package:im/pages/tool/debug_page.dart';
import 'package:im/services/connectivity_service.dart';
import 'package:im/services/server_side_configuration.dart';
import 'package:im/services/sp_service.dart';
import 'package:im/utils/universal_platform.dart';
import 'package:im/ws/ws.dart';
import 'package:logging/logging.dart';
import 'package:pedantic/pedantic.dart';
import 'package:replay_kit_launcher/replay_kit_launcher.dart';
import 'package:shake/shake.dart';

import 'configure_nonweb.dart' if (dart.library.html) 'configure_web.dart';
import 'core/engine.dart';
import 'global.dart';
import 'live_provider/live_api_provider.dart';
import 'live_provider/live_config_provider.dart';
import 'pages/home/view/text_chat/items/model/dynamic_view_config.dart';

Future main() async {
  final binding = WidgetsFlutterBinding.ensureInitialized();
  // flutter闪屏后再隐藏原生闪屏UI([Engine.allowRender])
  Engine.deferRender(binding);

  // 屏幕旋转监听插件初始化
  await initServices();
  initUtils();

  // 给直播模块提供fb相关能力
  LiveProvider.init(
    api: FBLiveApiProvider.instance,
    config: FBLiveConfigProvider.instance,
  );

  DynamicView.config = FbDynamicViewConfig();

  // 隐藏键盘，防止设备屏幕viewPadding获取不正确
  if (!kIsWeb) {
    await SystemChannels.textInput.invokeMethod('TextInput.hide');
    // 竖屏显示
    unawaited(SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]));

    // android悬浮窗
    if (UniversalPlatform.isAndroid) {
      FloatPlugin.initStreamOnAndroid();
    }

    /// ios屏幕共享监听方向
    IosScreenUtil.init();

    /// 重力旋转监听器初始化
    ScreenOrientationUtil.init();
    // iOS监听是否屏幕共享
    if (UniversalPlatform.isIOS) {
      ReplayKitLauncher()
          .eventChannel
          .receiveBroadcastStream()
          .listen(iosScreenBus.fire);
    }

    if (Config.isDebug || Config.env != Env.pro) {
      CachedNetworkImage.logLevel = CacheManagerLogLevel.debug;

      /// ShakeDetector 会消耗 20% iPhone CPU，因此除了调试环境，都不添加摇晃
      if (UniversalPlatform.isMobileDevice) {
        logger.info("Start shake detector");
        ShakeDetector.autoStart(onPhoneShake: () {
          DebugPage.show();
        });
      }
      if (UniversalPlatform.isPc) {
        RawKeyboard.instance.addListener((v) {
          if (v.character == ''.tr) {
            DebugPage.show();
          }
        });
      }
    }
  }

  if (UniversalPlatform.isAndroid) {
    await Global.getAndroidSdkInt();
  }

  // 设置Android头部的导航栏透明
  if (UniversalPlatform.isAndroid) {
    final systemUiOverlayStyle =
        SystemUiOverlayStyle.dark.copyWith(statusBarColor: Colors.transparent);
    SystemChrome.setSystemUIOverlayStyle(systemUiOverlayStyle);

    if (Config.isDebug || Config.env != Env.pro) {
      await AndroidInAppWebViewController.setWebContentsDebuggingEnabled(true);
    }
  } else if (UniversalPlatform.isIOS) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
  }
  // 注释掉了，原因加上之后，会导致页面内的futrue第二次报错无法被FutrueBuilder捕获

  ///设置使用bugly捕捉全局异常和闪退
  if (UniversalPlatform.isAndroid || UniversalPlatform.isIOS) {
    FlutterBugly.postCatchedException(
      initApp,
      onException: (detail) {
        logger.severe('', detail);
      },
      //debug模式下，闪退会上报，异常不会上报bugly，异常会在本地Logger中打印
      //release模式下，异常和闪退都会上报，在本地Logger中都不会打印
      debugUpload: !Config.isDebug,
    );
  } else {
    initApp();
  }
  logger.info("flutter-bugly --> isDebug:${Config.isDebug} ");
}

Future<void> initServices() async {
  Get.put(ConnectivityService());
  Get.put(ServerSideConfiguration());
  await Get.putAsync(() => SpService().init());
}

void initUtils() {
  initLogger();
  RoomManager.init();

  ///TODO:默认大小是100M，后面可以根据机型做一些调整
  PaintingBinding.instance.imageCache.maximumSizeBytes = 50 * 1024 * 1024;
  assert((() {
    Config.isDebug = true;
    Config.env = Env.dev;
    return true;
  })());
}

void initLogger() {
  if (!kDebugMode && !Config.isDebug) {
    Get.isLogEnable = false;
    logger.level = Level.OFF;
    return;
  }

  logger.level = Level.ALL;
  logger.onRecord.listen((record) {
    switch (record.level.name) {
      case "WARNING":
        LoggerPage.warn(record.message);
        break;
      case "SEVERE":
        LoggerPage.error(record.message, record.error);
        break;
      default:
        LoggerPage.log(record.message);
        break;
    }
    if (record.error != null) print(record.error.toString());
    print(record.message);
  });
}

void initApp() {
  Ws.instance ??= Ws();
  TextChannelUtil.instance ??= TextChannelUtil();
  Db.init();
  Db.compactAllBox();
  // 配置web路由history模式
  configureApp();
  runApp(App());
}
