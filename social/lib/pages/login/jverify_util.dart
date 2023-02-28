import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fluwx/fluwx.dart' as fluwx;
import 'package:get/get.dart';
import 'package:im/api/api.dart';
import 'package:im/api/user_api.dart';
import 'package:im/core/config.dart';
import 'package:im/dlog/dlog_manager.dart';
import 'package:im/global.dart';
import 'package:im/loggers.dart';
import 'package:im/routes.dart';
import 'package:im/utils/invite_code/invite_code_util.dart';
import 'package:im/utils/universal_platform.dart';
import 'package:jverify/jverify.dart'
    if (dart.library.html) 'package:im/pages/login/jverify_web.dart';
import 'package:oktoast/oktoast.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import 'login_threshold.dart';
import 'model/country_model.dart';

class JVerifyUtil {
  static Jverify jVerify = Jverify();

  /// 极光授权页面是否打开
  static bool jverifyAuthPageOpened = false;

  /// 极光授权页checkbox是否选中
  static bool jverifyChecked = false;

  static int _otherNumberLoginOffsetY = 0;

  /// 自定义微信登录按钮组件唯一标识
  static const String wxWidgetId = "id_wx_login_button";

  /// 自定义苹果登录按钮组件唯一标识
  static const String appleWidgetId = "id_apple_login_button";

  /// 初始化极光认证sdk
  static Future<void> init() async {
    final Completer completer = Completer();
    // 初始化 SDK 之前添加监听
    jVerify.addSDKSetupCallBackListener((event) {
      Global.initJverifySDKSuccess = event.code == 8000;
      logger.info('JverifySdk初始化 ${event.code}');
      completer.complete();
    });
    // 打开调试模式
    jVerify.setDebugMode(Config.isDebug);
    // 初始化sdk,  appKey 和 channel 只对ios设置有效
    jVerify.setup(
      appKey: "df59cd0f418a857fe19363a1",
      channel: "devloper-default",
      timeout: 3000,
    );
    return completer.future;
  }

  /// 判断当前网络环境是否可以发起认证
  static Future<bool> checkVerifyEnable() async {
    if (!Global.initJverifySDKSuccess) return false;
    final Map<dynamic, dynamic> enableRet = await jVerify.checkVerifyEnable();
    return enableRet['result'];
  }

  /// 登录预取号
  static Future<bool> preLogin({int timeOut = 3000}) async {
    final Map<dynamic, dynamic> enableRet = await jVerify.checkVerifyEnable();
    if (!enableRet['result']) {
      return false;
    }
    final Map<dynamic, dynamic> preLoginRet =
        await jVerify.preLogin(timeOut: timeOut);
    return preLoginRet['code'] == 7000;
  }

  static void buildAuthorizationView(
    BuildContext context,
    Function onOther, {
    bool appleLoginOpen = true,
    bool wechatLoginOpen = true,
    bool binding = false,
  }) {
    final JVUIConfig uiConfig = JVerifyUtil.buildSelfView(binding: binding);
    final List<JVCustomWidget> customWidgets = JVerifyUtil.buildCustomWidgets(
      context,
      onOther,
      appleLoginOpen: appleLoginOpen,
      wechatLoginOpen: wechatLoginOpen,
      binding: binding,
    );
    jVerify.setCustomAuthorizationView(false, uiConfig, widgets: customWidgets);
  }

  /// 获取媒体窗口逻辑大小
  static Size get windowLogicalSize {
    final _size = ui.window.physicalSize / ui.window.devicePixelRatio;
    return _size.isEmpty ? const Size(375, 812) : _size;
  }

  /// 获取状态栏高度
  static int get windowStatusBarHeight {
    final barHeight = MediaQueryData.fromWindow(ui.window).padding.top.toInt();
    return barHeight > 0 ? barHeight : 28;
  }

  static int calculateSize(int src, {bool withW = false}) {
    // final screenSize = Global.mediaInfo.size;
    final screenSize = windowLogicalSize;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;
    final double widthFactor = screenWidth / 375;
    final double heightFactor = screenHeight / 812;
    final double ret = withW ? (widthFactor * src) : (heightFactor * src);
    return ret.floor();
  }

  /// 自定义授权页自带控件属性
  static JVUIConfig buildSelfView({bool binding = false}) {
    int currentOffset = 0;
    // final screenSize = Global.mediaInfo.size;
    final screenSize = windowLogicalSize;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;
    final int statusBarHeight = windowStatusBarHeight;
    final bool isiOS = UniversalPlatform.isIOS;
    const privacyTextWidgetHeight = 36;

    final int size88 = calculateSize(88);
    final int size36 = calculateSize(36);
    final int size24 = calculateSize(24);
    final int size8 = calculateSize(8);

    /// 以下是需要微调的参数
    const int minMarginHorizontal = 32;
    const int btnHeight = 48;
    const int numberFontSize = 26; // 电话号码字体大小
    final int numberToLogo = size36; // 电话号码离logo距离
    final int sloganToNumber = size8; // 认证服务字样离电话号码距离
    final int oneKeyLoginToSlogan = size24; // 一键登录离认证服务字样距离
    const int otherToOneKeyLogin = 16; // 其它号码登录离一键登录距离
    const int privacyToOtherToOneKeyLogin = 24;

    final int tmpTop = (screenHeight * 0.23).ceil();
    // logo离顶部距离(android是距离status bar底部)
    final int logoToTop = isiOS ? tmpTop : tmpTop - statusBarHeight;

    // 自定义授权的 UI 界面，以下设置的图片必须添加到资源文件里，
    // android项目将图片存放至drawable文件夹下，可使用图片选择器的文件名,例如：btn_login.xml,入参为"btn_login"。
    // ios项目存放在 Assets.xcassets。
    final JVUIConfig uiConfig = JVUIConfig();
    uiConfig.authBackgroundImage = 'login_auth_bg';

    // 0. 状态栏及导航栏
    uiConfig.navColor = Colors.white.value;
    uiConfig.navHidden = true;
    uiConfig.navReturnBtnHidden = true;
    uiConfig.statusBarDarkMode = true;
    uiConfig.statusBarTransparent = true;
    // currentOffset 为logo顶部距屏幕顶部距离
    currentOffset = logoToTop;

    // 1. logo
    // uiConfig.logoOffsetX = isiOS ? 0 : null;
    uiConfig.logoVerticalLayoutItem = JVIOSLayoutItem.ItemSuper;
    // !!! logoOffsetY为0时，android在status　bar下面，iOS则靠手机顶边　!!!
    uiConfig.logoOffsetY = logoToTop;
    uiConfig.logoWidth = size88;
    uiConfig.logoHeight = size88;
    uiConfig.logoImgPath = "login_logo";
    // currentOffset　为logo底部距顶部距离
    currentOffset += uiConfig.logoHeight;

    // 2.　电话号码
    // uiConfig.numFieldOffsetX = isiOS ? 0 : null;
    uiConfig.numberVerticalLayoutItem = JVIOSLayoutItem.ItemLogo;
    uiConfig.numberFieldWidth = 200;
    uiConfig.numberFieldHeight = 30;
    uiConfig.numberColor = 0xFF363940;
    uiConfig.numberSize = numberFontSize;
    uiConfig.numFieldOffsetY =
        isiOS ? numberToLogo : currentOffset + numberToLogo;
    // currentOffset　为电话号码字样底部距顶部距离
    currentOffset += numberToLogo + uiConfig.numberFieldHeight;

    // 3. xxx帐号提供认证服务字样
    uiConfig.sloganVerticalLayoutItem = JVIOSLayoutItem.ItemNumber;
    uiConfig.sloganTextColor = 0xFF8F959E;
    uiConfig.sloganTextSize = 14;
    // uiConfig.sloganHeight = 20;　这里设置高度的话，iOS显示异常！！！
    uiConfig.sloganOffsetY =
        isiOS ? sloganToNumber : currentOffset + sloganToNumber;
    // currentOffset 为认证服务字样底部距顶部距离
    currentOffset += sloganToNumber + 17; // 17是slogan高度

    // 4. 登录按钮  android使用的selector, iOS使用图片
    uiConfig.logBtnVerticalLayoutItem = JVIOSLayoutItem.ItemSlogan;
    uiConfig.logBtnBackgroundPath = "btn_one_key";
    uiConfig.loginBtnNormalImage = "btn_one_key";
    uiConfig.loginBtnPressedImage = "btn_one_key";
    uiConfig.loginBtnUnableImage = "btn_one_key";
    final int btnWidth = screenWidth.ceil() - minMarginHorizontal * 2;
    uiConfig.logBtnWidth = btnWidth;
    uiConfig.logBtnHeight = btnHeight;
    uiConfig.logBtnText =
        "本机号码一键%s".trArgs([if (binding) '绑定'.tr else '登录'.tr]);
    uiConfig.logBtnTextColor = Colors.white.value;
    uiConfig.logBtnTextSize = 16;
    uiConfig.logBtnOffsetY =
        isiOS ? oneKeyLoginToSlogan : currentOffset + oneKeyLoginToSlogan;
    //　currentOffset 为一键登录按钮底部距顶部距离
    currentOffset += uiConfig.logBtnHeight + oneKeyLoginToSlogan;

    // 5. 其它号码登录按钮　因为这个按钮在自定义控件接口中定义，所以这里赋值一个全局变量
    // 这里+2的原因是屏幕兼容时ceil可能有点偏差,　不然视觉上离得有点近
    _otherNumberLoginOffsetY = currentOffset + otherToOneKeyLogin + 2;
    // _otherNumberLoginOffsetY += isiOS ? 10 : 0;
    // currentOffset 为其它号码底部距顶部距离
    currentOffset += btnHeight + otherToOneKeyLogin;

    // 6. 协议
    // 自定义协议1
    uiConfig.clauseName = "隐私政策".tr;
    uiConfig.clauseUrl =
        'https://${ApiUrl.privacyUrl}?udx=93${DateTime.now().millisecondsSinceEpoch}3d4';
    //　自定义协议2
    uiConfig.clauseNameTwo = "用户协议".tr;
    uiConfig.clauseUrlTwo =
        'https://${ApiUrl.termsUrl}?udx=93${DateTime.now().millisecondsSinceEpoch}3c4';
    // only android 设置隐私条款不选中时点击登录按钮默认显示toast。
    uiConfig.privacyHintToast = true;
    uiConfig.privacyState = false; //设置默认勾选
    const boxSize = 30;
    // const boxPadding = 6;
    // uiConfig.privacyCheckboxSize = isiOS ? (boxSize + boxPadding * 2) : boxSize;
    uiConfig.privacyCheckboxSize = boxSize;
    uiConfig.privacyCheckboxInCenter = true;
    uiConfig.checkedImgPath = "check_image"; //图片必须存在
    uiConfig.uncheckedImgPath = "uncheck_image"; //图片必须存在
    // uiConfig.privacyOffsetX = isiOS
    // ? (minMarginHorizontal + boxSize + boxPadding)
    // : minMarginHorizontal - 2;
    uiConfig.privacyOffsetX = minMarginHorizontal - 2 - 10;
    // privacyOffsetY为0时，隐私是底边靠屏底边 (android　是紧挨，iOS是以底部切后台的横线
    // 为准，所以iOS这里再offset一个12
    uiConfig.privacyOffsetY = screenHeight.ceil() -
        currentOffset -
        privacyToOtherToOneKeyLogin -
        privacyTextWidgetHeight -
        (isiOS ? 0 : statusBarHeight - 7);
    uiConfig.privacyVerticalLayoutItem = JVIOSLayoutItem.ItemSuper;

    uiConfig.clauseBaseColor = 0xFF8F959E;
    uiConfig.clauseColor = 0xFF198CFE;
    uiConfig.privacyText = [
      "请阅读并同意".tr,
      " ",
    ];
    uiConfig.privacyTextSize = 13;
    uiConfig.privacyWithBookTitleMark = false;
    uiConfig.privacyNavColor = Colors.white.value;
    uiConfig.privacyNavTitleTextColor = Colors.black.value;
    uiConfig.privacyNavTitleTextSize = 16;
    uiConfig.privacyNavTitleTitle1 = "隐私政策".tr; //only ios
    uiConfig.privacyStatusBarDarkMode = true;
    uiConfig.privacyNavTitleTitle2 = "用户协议".tr;
    uiConfig.privacyStatusBarColorWithNav = true;
    uiConfig.privacyItem = [
      JVPrivacy("隐私政策".tr,
          'https://${ApiUrl.privacyUrl}?udx=93${DateTime.now().millisecondsSinceEpoch}3d4',
          beforeName: "", afterName: "", separator: "、"),
      JVPrivacy("用户协议".tr,
          'https://${ApiUrl.termsUrl}?udx=93${DateTime.now().millisecondsSinceEpoch}3c4',
          beforeName: "", separator: "和"),
    ];
    // iOS　animation
    uiConfig.needStartAnim = true;
    uiConfig.needCloseAnim = true;
    uiConfig.modelTransitionStyle = JVIOSUIModalTransitionStyle.CoverVertical;
    // android animation
    uiConfig.enterAnim = 'login_auth_slide_enter';
    uiConfig.exitAnim = 'login_auth_slide_exit';

    uiConfig.privacyNavReturnBtnImage = "return_bg"; //图片必须存在;
    return uiConfig;
  }

  /// 自定义授权页其它控件
  static List<JVCustomWidget> buildCustomWidgets(
    BuildContext context,
    Function onOther, {
    bool appleLoginOpen = true,
    bool wechatLoginOpen = true,
    bool binding = false,
  }) {
    // final screenSize = Global.mediaInfo.size;
    final screenSize = windowLogicalSize;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;
    final bool isiOS = UniversalPlatform.isIOS;

    final int size102 = calculateSize(102);
    final int size78 = calculateSize(78);
    final int size16 = calculateSize(16);
    final int size8 = calculateSize(8);

    const int space = 10;

    const int minMarginHorizontal = 32;
    const int thirdBtnWidth = 48;
    const int thirdBtnHeight = 48;
    final int otherLoginTextToThirdBtn = size16; // 其他文字离第三方登录距离
    final int thirdBtnToBottom = isiOS ? size78 : size102; // 第三方登录按钮离底部距离

    final int btnWidth = screenWidth.ceil() - minMarginHorizontal * 2;

    // 添加自定义控件---其他号码登陆按钮
    final List<JVCustomWidget> widgetList = [];
    const String btnWidgetId = "id_other_number_login_button"; // 标识控件 id
    final JVCustomWidget buttonWidget =
        JVCustomWidget(btnWidgetId, JVCustomWidgetType.button);
    buttonWidget.title = "其他号码%s".trArgs([if (binding) '绑定'.tr else '登录'.tr]);
    buttonWidget.textAlignment = JVTextAlignmentType.center;
    buttonWidget.top = _otherNumberLoginOffsetY;
    buttonWidget.left = minMarginHorizontal;
    buttonWidget.width = btnWidth;
    buttonWidget.height = 48;
    buttonWidget.isShowUnderline = false;
    buttonWidget.titleFont = 16;
    // android不能使用xml!!!　和iOS一起都使用图片
    buttonWidget.btnNormalImageName = "btn_other_login";
    // 添加点击事件监听
    jVerify.addClikWidgetEventListener(btnWidgetId, (eventId) {
      if (btnWidgetId == eventId) {
        jVerify.dismissLoginAuthView();
        onOther();
      }
    });
    widgetList.add(buttonWidget);

    // 如果是绑定，不需要其它登录方式组件
    if (binding) {
      return widgetList;
    }

    if (!appleLoginOpen && !wechatLoginOpen) {
      return widgetList;
    }

    // 添加自定义控件---微信登陆按钮
    final JVCustomWidget wxBtnWidget =
        JVCustomWidget(wxWidgetId, JVCustomWidgetType.button);
    int top = wxBtnWidget.top;

    if ((UniversalPlatform.isIOS || UniversalPlatform.isMacOS) &&
        appleLoginOpen) {
      // 添加自定义控件---apple登陆按钮
      final JVCustomWidget appleBtnWidget =
          JVCustomWidget(appleWidgetId, JVCustomWidgetType.button);
      appleBtnWidget.width = thirdBtnWidth;
      appleBtnWidget.height = thirdBtnHeight;
      appleBtnWidget.top =
          screenHeight.ceil() - thirdBtnToBottom - thirdBtnHeight;

      if (wechatLoginOpen) {
        appleBtnWidget.left =
            ((screenWidth - space) / 2).ceil() - thirdBtnWidth;
      } else {
        appleBtnWidget.left = ((screenWidth - thirdBtnWidth) / 2).ceil();
      }

      appleBtnWidget.isShowUnderline = false;
      appleBtnWidget.btnNormalImageName = "login_apple";
      // 添加点击事件监听
      jVerify.addClikWidgetEventListener(
        appleWidgetId,
        (eventId) => nativeThirdLoginHandler(context, eventId),
      );
      widgetList.add(appleBtnWidget);
      top = appleBtnWidget.top;

      if (wechatLoginOpen) {
        wxBtnWidget.width = thirdBtnWidth;
        wxBtnWidget.height = thirdBtnHeight;
        wxBtnWidget.top =
            screenHeight.ceil() - thirdBtnToBottom - thirdBtnWidth;
        wxBtnWidget.left = ((screenWidth + space) / 2).ceil();

        wxBtnWidget.isShowUnderline = false;
        wxBtnWidget.btnNormalImageName = "login_wechat";
        // 添加点击事件监听
        jVerify.addClikWidgetEventListener(
          wxWidgetId,
          (eventId) => nativeThirdLoginHandler(context, eventId),
        );
        widgetList.add(wxBtnWidget);
      }
    } else {
      if (wechatLoginOpen) {
        wxBtnWidget.width = thirdBtnWidth;
        wxBtnWidget.height = thirdBtnHeight;
        wxBtnWidget.top =
            screenHeight.ceil() - thirdBtnToBottom - thirdBtnWidth;
        wxBtnWidget.left = ((screenWidth.ceil() - thirdBtnWidth) * 0.5).ceil();

        wxBtnWidget.isShowUnderline = false;
        wxBtnWidget.btnNormalImageName = "login_wechat";
        // 添加点击事件监听
        jVerify.addClikWidgetEventListener(
          wxWidgetId,
          (eventId) => nativeThirdLoginHandler(context, eventId),
        );
        widgetList.add(wxBtnWidget);
        top = wxBtnWidget.top;
      }
    }

    // 添加自定义控件---第三方登录文字显示
    const String textWidgetId = "id_text_third_login"; // 标识控件 id
    final JVCustomWidget textWidget =
        JVCustomWidget(textWidgetId, JVCustomWidgetType.textView);
    textWidget.title = "其它方式登录".tr;
    textWidget.width = 96;
    textWidget.height = 16;
    textWidget.top = top - otherLoginTextToThirdBtn - 16;
    textWidget.left = ((screenWidth - textWidget.width) * 0.5).ceil();
    textWidget.titleFont = 13;
    textWidget.titleColor = 0xFF8F959E;
    textWidget.textAlignment = JVTextAlignmentType.center;
    widgetList.add(textWidget);

    // 添加自定义控件---第三方登录文字左边line
    const String textLeftLineWidgetId = "id_text_third_left_line"; // 标识控件 id
    final JVCustomWidget textLeftLineWidget =
        JVCustomWidget(textLeftLineWidgetId, JVCustomWidgetType.button);
    textLeftLineWidget.width = 16;
    textLeftLineWidget.height = 1;
    textLeftLineWidget.top = top - otherLoginTextToThirdBtn - size16 + size8;
    textLeftLineWidget.left = textWidget.left - textLeftLineWidget.width;
    textLeftLineWidget.btnNormalImageName = "other_line";
    textLeftLineWidget.isClickEnable = false;
    widgetList.add(textLeftLineWidget);

    // 添加自定义控件---第三方登录文字右边line
    const String textRightLineWidgetId = "id_text_third_right_line"; // 标识控件 id
    final JVCustomWidget textRightLineWidget =
        JVCustomWidget(textRightLineWidgetId, JVCustomWidgetType.button);
    textRightLineWidget.width = size16;
    textRightLineWidget.height = 1;
    textRightLineWidget.top = top - otherLoginTextToThirdBtn - size16 + size8;
    textRightLineWidget.left = textWidget.left + textWidget.width;
    textRightLineWidget.btnNormalImageName = "other_line";
    textRightLineWidget.isClickEnable = false;
    widgetList.add(textRightLineWidget);

    return widgetList;
  }

  static void nativeThirdLoginHandler(BuildContext context, String widgetId) {
    if (!jverifyChecked) {
      jVerify.showNativeToast('请阅读并同意相关协议'.tr);
      return;
    }
    if (wxWidgetId == widgetId) {
      loginWithWx();
    } else if (appleWidgetId == widgetId) {
      loginWithApple(context);
    }
  }

  static int lastClickTime = 0;

  static Future<void> loginWithWx({bool isChecked = false}) async {
    final int now = DateTime.now().millisecondsSinceEpoch;
    if (now - lastClickTime < 2000) return;
    lastClickTime = now;
    if (!Global.thirdLoginClickable) {
      // debugPrint('thirdLoginClickable false');
      return;
    }
    if (!jverifyChecked && !isChecked) {
      jVerify.showNativeToast('请阅读并同意相关协议'.tr);
      return;
    }
    if (!(await fluwx.isWeChatInstalled)) {
      showToast('未安装微信'.tr, radius: 8);
      return;
    }
    await fluwx.sendWeChatAuth(scope: 'snsapi_userinfo');
  }

  static Future<void> loginWithApple(BuildContext context,
      {bool isChecked = false}) async {
    if (!jverifyChecked && !isChecked) {
      jVerify.showNativeToast('请阅读并同意相关协议'.tr);
      return;
    }
    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        webAuthenticationOptions: WebAuthenticationOptions(
          // fanbook clientId
          clientId: 'com.idreamsky.buff',

          redirectUri:
              // For web your redirect URI needs to be the host of the "current page",
              // while for Android you will be using the API server that redirects back into your app via a deep link
              // 重定向地址，用于web或android上的ios账号登录，暂未使用
              Uri.parse(
            'https://a1.fanbook.mobi/callbacks/sign_in_with_apple',
          ),
        ),
      );

      // ignore: avoid_print
      debugPrint("apple credential=$credential");

      final Map<String, String> data = {
        'userIdentifier': credential.userIdentifier,
        'authorizationCode': credential.authorizationCode,
        'identityToken': credential.identityToken,
        if (credential.givenName != null) 'givenName': credential.givenName,
        if (credential.familyName != null) 'familyName': credential.familyName,
        if (credential.email != null) 'email': credential.email,
      };

      final _jsonMap = await UserApi.loginApple(data);

      debugPrint("apple _jsonMap=$_jsonMap");

      Jverify().dismissLoginAuthView(); //苹果登录无论新老用户都需要关闭第三方一键登录界面（原生界面）
      if (_jsonMap['n'] == 1) {
        // apple新用户，未绑定
        await Routes.pushLoginPage(
          context,
          replace: true,
          binding: true,
          thirdParty: _jsonMap['third_party'],
          loginType: LoginType.LoginTypeApple,
        );
      } else {
        await LoginThreshold.entry(
          context,
          _jsonMap,
          country: CountryModel.defaultModel.toString(),
          loginType: LoginType.LoginTypeApple,
        );
      }
    } catch (e) {
      DLogManager.getInstance().customEvent(
          actionEventId: 'login_status',
          actionEventSubId: '0',
          pageId: 'page_login',
          actionEventSubParam: e?.toString() ?? '',
          extJson: {
            "login_type": "apple_login",
            'invite_code': InviteCodeUtil.inviteCode
          });
    }
  }
}
