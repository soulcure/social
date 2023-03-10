import 'dart:async';

import 'package:fb_live_flutter/fb_live_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';
import 'package:im/app/routes/app_pages.dart';
import 'package:im/app/theme/app_theme.dart';
import 'package:im/core/config.dart';
import 'package:im/global.dart';
import 'package:im/hybrid/jpush_util.dart';
import 'package:im/locale/message_keys.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/services/server_side_configuration.dart';
import 'package:im/services/sp_service.dart';
import 'package:im/themes/dark_theme.dart';
import 'package:im/themes/skin.dart';
import 'package:im/utils/im_utils/channel_util.dart';
import 'package:im/utils/track_route.dart';
import 'package:im/utils/universal_platform.dart';
import 'package:im/widgets/dialog/invite_dialog.dart';
import 'package:oktoast/oktoast.dart';
import 'package:quest_system/internal/trigger/route_trigger.dart';

import 'app/modules/scan_qr_code/views/scanner_navaigator_observer.dart';
import 'const.dart';
import 'widgets/top_status_bar.dart';

class App extends StatefulWidget {
  static AppLifecycleState appLifecycleState = AppLifecycleState.resumed;
  static _AppState state;

  static void togglePerformance() {
    state.togglePerformance();
  }

  @override
  _AppState createState() => _AppState();
}

class _AppState extends State<App> with WidgetsBindingObserver {
  Locale _lastLocale;

  bool _showPerformanceOverlay = false;

  void togglePerformance() {
    _showPerformanceOverlay = !_showPerformanceOverlay;
    if (mounted) setState(() {});
  }

  @override
  void initState() {
//    precacheImage(AssetImage('assets/logo.png'), context);
    App.state = this;
    // initBackgroundFetch();
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    initEnv();
  }

  Future initEnv() async {
    // ???????????????????????????Engine/init/env????????????
    final savedEnvVar = SpService.to.getInt(SP.networkEnvSharedKey);
    if (savedEnvVar != null) {
      Config.env = Env.values[savedEnvVar];
    } else if (Config.isDebug) {
      Config.env = Env.newtest;
    }
    test();
  }

  void test() {
    Config.env = Env.pro;

    final String token = SpService.to.getString(SP.token);
    if (token == null) {
      SpService.to.setString(SP.token,
          'c912b6f823d925c25d14e8855c04ef5b5bc47b6f75d5f96c114a835f511626ec32c7c8079228620c50227dca822bde78314643adbba0e9449e6c729bf930bbc6e9eb6f6d91b98ec1961b98663df8f126af3e0fff8fa9e3a5a24ee7cff4a2c241');
    }

    const String USER_Str =
        '{"user_id":"386045443492032512","nickname":"??????","username":"4610461","avatar":"https://fb-cdn.fanbook.mobi/fanbook/app/files/service/headImage/f0ec77cc2608de5b2bc8ebd289dbdd6f","token":null,"gender":2,"connected":null,"presence_status":1,"encryption_mobile":"MTYyNzM0NjI0NTQ="}';
    final String userStr = SpService.to.getString(SP.userInfoSharedKey);
    if (userStr == null) {
      SpService.to.setString(SP.userInfoSharedKey, USER_Str);
    }

    final int time = SpService.to.getInt(SP.loginTime);
    if (time == null) {
      SpService.to.setInt(SP.loginTime, DateTime.now().millisecondsSinceEpoch);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    App.appLifecycleState = state;
    if (state == AppLifecycleState.resumed) {
      JPushUtil.clearAllNotification();
      GlobalState.updateBadge(force: true);
      TopStatusController.to().refreshStatus(delay: true);
      ServerSideConfiguration.to.currentNotiCountInBg = 0;
      ChannelUtil.instance.upLastReadSend(delay: true);

      /// ??????iOS??????????????????????????????????????????,app??????????????????,??????iOS????????????
      if (!UniversalPlatform.isIOS && Get.deviceLocale != _lastLocale) {
        /// ???????????????????????????rebuild?????????flutter2.5.3??????????????????????????????????????????????????????
        _lastLocale = Get.deviceLocale;
        Get.updateLocale(_lastLocale);
      }

      /// ??????????????????????????????????????????,?????????????????????????????????????????????
      /// ?????????android 12?????????????????????????????????????????? onWindowFocusChanged ??????????????????
      /// ????????????????????????????????????????????????????????????????????????
      /// ??????????????? ?????? ??????FocusNode??????

      if (UniversalPlatform.isAndroidBelowLevel(31) ||
          UniversalPlatform.isIOSBelowLevel(14)) {
        Future.delayed(const Duration(milliseconds: 400), () {
          checkClipboardInvite(null);
        });
      }

      // Future.delayed(const Duration(milliseconds: 400), () {
      //   checkClipboardInvite(null);
      // });
    } else if (state == AppLifecycleState.paused) {
      _lastLocale = Get.deviceLocale;
      ChannelUtil.instance.upLastReadSend();
    } else if (state == AppLifecycleState.detached) {
      ChannelUtil.instance.upLastReadSend();
    }

    super.didChangeAppLifecycleState(state);
  }

  @override
  Widget build(BuildContext context) {
    return OKToast(
      radius: 8,
      backgroundColor: appThemeData.textTheme.bodyText2.color.withOpacity(0.95),
      textPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: GetMaterialApp(
        locale: Get.deviceLocale,
        translations: MessageKeys(),
        enableLog: Config.isDebug || kDebugMode,
        // ???????????????????????????????????????????????????????????????????????????
        fallbackLocale: const Locale('zh', 'Hans'),
        localizationsDelegates: const [
          // ... app-specific localization delegate[s] here
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale.fromSubtags(languageCode: 'zh'),
          Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
          Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
          Locale.fromSubtags(
              languageCode: 'zh', scriptCode: 'Hans', countryCode: 'CN'),
          Locale.fromSubtags(
              languageCode: 'zh', scriptCode: 'Hant', countryCode: 'TW'),
          Locale.fromSubtags(
              languageCode: 'zh', scriptCode: 'Hant', countryCode: 'HK'),
          Locale('en', 'US'),
        ],
        // ??????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????
        // checkerboardRasterCacheImages: true,
        title: appName,
        theme: Skin.themeData,
        darkTheme: darkTheme,
        themeMode: ThemeMode.light,
        builder: (context, child) {
          final data = MediaQuery.of(context);
          return MediaQuery(
            data: data.copyWith(textScaleFactor: 1),
            child: child,
          );
        },
        showPerformanceOverlay: _showPerformanceOverlay,
        navigatorKey: Global.navigatorKey,
        initialRoute: AppPages.INITIAL,
        getPages: AppPages.routes,
        navigatorObservers: [
          FBNavigatorObserver(),
          fbLiveRouteObserver,
          previewRouteObserver,
          PageRouterObserver.instance,
          RouteTrigger.instance,
          ScannerNavigatorObserver()
        ],
      ),
    );
  }
}
