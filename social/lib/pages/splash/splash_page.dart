import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:im/api/user_api.dart';
import 'package:im/common/extension/string_extension.dart';
import 'package:im/core/config.dart';
import 'package:im/core/engine.dart';
import 'package:im/dlog/dlog_manager.dart';
import 'package:im/pages/home/home_page.dart';
import 'package:im/pages/login/jverify_util.dart';
import 'package:im/pay/pay_manager.dart';
import 'package:im/routes.dart';
import 'package:im/services/sp_service.dart';
import 'package:im/utils/deeplink_processor.dart';
import 'package:im/utils/invite_code/invite_code_util.dart';
import 'package:im/utils/sensitive_sdk_util.dart';
import 'package:im/utils/universal_platform.dart';
import 'package:im/utils/utils.dart';
import 'package:im/web/utils/web_util/web_util.dart';
import 'package:jverify/jverify.dart'
    if (dart.library.html) 'package:im/pages/login/jverify_web.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:pedantic/pedantic.dart';
import 'package:uuid/uuid.dart';
import 'package:websafe_svg/websafe_svg.dart';

import '../../const.dart';
import '../../global.dart';
import '../../loggers.dart';

class SplashPage extends StatefulWidget {
  // final String queryString;
  const SplashPage();

  @override
  _SplashPageState createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  final Jverify jVerify = Jverify();

  @override
  void initState() {
    super.initState();
    // 判断是否web邀请链接
    if (kIsWeb) {
      final href = webUtil.getHref();
      final params = Uri.parse(href).queryParameters;
      final code = params['c'];
      if (isNotNullAndEmpty(code)) {
        HomePage.inviteStream.add(InviteUrlStream(
            '${Config.webLinkPrefix}$code', InviteURLFrom.clipBoard));
        InviteCodeUtil.setInviteCode(href);
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((d) async {
      Config.useHttps = SpService.to.getBool(SP.useHttps) ?? true;
      Global.mediaInfo ??= MediaQuery.of(context);

      try {
        await Global.getDeviceInfo();
      } catch (e) {
        logger.warning(e);
      }

      // 初始化一次
      // 设备初始化
      // Global.deviceInfo;

      Global.packageInfo = kIsWeb
          ? PackageInfo(
              appName: appName,
              version: '1.6.50',
              packageName: 'web',
              buildNumber: '20')
          : await PackageInfo.fromPlatform();

      await Engine.init();

      // a.直接初始化相关敏感SDK的情况包括:
      //    1.不需要登录，注:旧包升新包，旧包没缓存agreedProtocals，这里设成true
      //    2.用户已选择过同意标志为true
      // b.需要在登录页面弹显式隐私对话框的情况: 需要登录且用户从未同意过隐私政策
      bool agreedProtocals = SpService.to.getBool(SP.agreedProtocals) ?? true;

      /// token验证+本地时间验证
      if (kIsWeb) {
        agreedProtocals = true;
        Config.token = webUtil.getCookie('token');
      } else
        Config.token = SpService.to.getString(SP.token);

      if (!needLogin || agreedProtocals) {
        if (!agreedProtocals)
          await SpService.to.setBool(SP.agreedProtocals, true);
        await SensitiveSDKUtil.handleEvents();
      }

      if (kIsWeb) {
        var webUUid = webUtil.getCookie('uuid');
        if (webUUid.noValue) {
          webUUid = const Uuid().v4();
          webUtil.setCookie('uuid', webUUid);
        }
        Config.webUUid = webUUid;
      }

      bool registerNotComplete = (Global.user.nickname?.isEmpty ?? true) ||
          (Global.user.avatar?.isEmpty ?? true);

      if (Config.autoLogin && needLogin) {
        await autoLogin();
        registerNotComplete = false;
      }

      await InviteCodeUtil.checkInviteUrl();

      /// 数据上报初始化
      if (!UniversalPlatform.isAndroid)
        await DLogManager.getInstance().initDLog();

      /// 注册解析deep link监听，当app运行时，可以处理外部打开的deep link
      if (!kIsWeb) DeepLinkProcessor.instance.registerDeepLinkProcessor();

      if (needLogin) {
        Config.permission = null;
        if (Global.initJverifySDKSuccess && UniversalPlatform.isMobileDevice) {
          // 尝试预登录，加速后面显示授权页
          await JVerifyUtil.preLogin();
        }
        if (UniversalPlatform.isMobileDevice && !agreedProtocals) {
          unawaited(Routes.pushProtocalPage(context, replace: true));
        } else {
          unawaited(Routes.pushLoginPage(context, replace: true));
        }
      } else {
        if (registerNotComplete ||
            (kIsWeb &&
                SpService.to.getString(SP.unModifyInfo) == Global.user.id))
          unawaited(
              Routes.pushLoginModifyUserInfoPage(context, isFirstIn: true));
        else {
          if (DateTime.now().isAfter(DateTime.fromMillisecondsSinceEpoch(
                  SpService.to.getInt(SP.loginTime))
              .add(const Duration(days: 15)))) {
            unawaited(UserApi.updateToken());
          }
          unawaited(Routes.pushHomePage(context));

          /// 自动登录后也要初始化内购
          unawaited(PayManager.startObservingPaymentQueue());

          /// 登录成功数据上报
          unawaited(DLogManager.getInstance().userLogin());
        }
      }

      Engine.allowRender();

      /// 启动权限判断
//      try {
//        await UserApi.checkToken(Config.token);
//        unawaited(Routes.pushHomePage(context));
//      } catch (e){
//        unawaited(Routes.pushLoginPage(context, replace: true));
//      }
    });
  }

  bool get needLogin =>
      Config.token == null ||
      Config.token.isEmpty ||
      SpService.to.getInt(SP.loginTime) == null ||
      Global.user.id == null ||
      DateTime.now().isAfter(
          DateTime.fromMillisecondsSinceEpoch(SpService.to.getInt(SP.loginTime))
              .add(const Duration(days: 30)));

  Future autoLogin() async {
    final _jsonMap =
        await UserApi.login(13790435335, "008010", "android", "86");

    Global.user = LocalUser.fromJson(_jsonMap)..cache();
    // 保存区号
    unawaited(SpService.to.setString(SP.country, "86"));
    // 保存token
    Config.token = _jsonMap['sign'];
    unawaited(SpService.to.setString(SP.token, _jsonMap['sign']));
    // 保存时间戳
    unawaited(SpService.to
        .setInt(SP.loginTime, DateTime.now().millisecondsSinceEpoch));
  }

  @override
  Widget build(BuildContext context) {
    Global.mediaInfo ??= MediaQuery.of(context);
    // android12（S+) 启动屏大小固定为(200, 80)
    final splashLogo = UniversalPlatform.isAndroidAboveLevel(31)
        ? WebsafeSvg.asset('assets/splash_screen_branding.svg',
            width: 200, height: 80)
        : WebsafeSvg.asset("assets/launch_screen_logo.svg",
            width: 146, height: 32);

    return Container(
      alignment: Alignment.bottomCenter,
      color: Colors.white,
      padding:
          EdgeInsets.only(bottom: 48 + MediaQuery.of(context).padding.bottom),
      child: splashLogo,
    );
  }
}
