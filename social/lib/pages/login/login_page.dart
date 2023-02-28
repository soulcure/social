import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:fluwx/fluwx.dart' as fluwx;
import 'package:get/get.dart';
import 'package:im/api/api.dart';
import 'package:im/api/user_api.dart';
import 'package:im/common/extension/uri_extension.dart';
import 'package:im/core/config.dart';
import 'package:im/core/widgets/loading.dart';
import 'package:im/db/db.dart';
import 'package:im/dlog/dlog_manager.dart';
import 'package:im/global.dart';
import 'package:im/icon_font.dart';
import 'package:im/loggers.dart';
import 'package:im/pages/login/country_page/country_page_web.dart';
import 'package:im/pages/login/jverify_util.dart';
import 'package:im/pages/login/login_threshold.dart';
import 'package:im/pages/login/model/country_model.dart';
import 'package:im/pages/login/third_login.dart';
import 'package:im/routes.dart';
import 'package:im/services/server_side_configuration.dart';
import 'package:im/services/sp_service.dart';
import 'package:im/themes/const.dart';
import 'package:im/themes/custom_color.dart';
import 'package:im/themes/default_theme.dart';
import 'package:im/themes/web_light_theme.dart';
import 'package:im/utils/invite_code/invite_code_util.dart';
import 'package:im/utils/orientation_util.dart';
import 'package:im/utils/show_confirm_dialog.dart';
import 'package:im/utils/universal_platform.dart';
import 'package:im/utils/utils.dart';
import 'package:im/widgets/button/round_check_box.dart';
import 'package:im/widgets/dialog/show_alert_dialog.dart';
import 'package:im/widgets/fb_check_box.dart';
import 'package:im/widgets/super_tooltip.dart';
import 'package:jverify/jverify.dart'
    if (dart.library.html) 'package:im/pages/login/jverify_web.dart';
import 'package:oktoast/oktoast.dart';
import 'package:pedantic/pedantic.dart';
import 'package:rxdart/rxdart.dart';
import 'package:websafe_svg/websafe_svg.dart';

///是否显示微信登录入口
Future<bool> isShowWeChatLogin() async {
  final bool config = ServerSideConfiguration.to.wechatLoginOpen.value;
  final bool install = await fluwx.isWeChatInstalled;
  return config && install;
}

///是否显示苹果登录入口
bool isShowAppleLogin() {
  return ServerSideConfiguration.to.appleLoginOpen.value;
}

/// login界面
class LoginPage extends StatefulWidget {
  final String mobile;
  final CountryModel country;
  final String alertInfo;
  final bool binding;
  final bool showCover;
  final String thirdParty;
  final LoginType loginType;

  const LoginPage({
    this.mobile,
    this.country,
    this.alertInfo,
    this.binding = false,
    this.showCover = true,
    this.thirdParty = "",
    this.loginType = LoginType.LoginTypePhoneNum,
  });

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with WidgetsBindingObserver {
  TextEditingController _mobileController;
  final _focusNode = FocusNode();
  bool _loading = false;
  bool _isValid = false;
  int _inputLength = 11;
  CountryModel _countryCode;
  bool _checkboxSelected = false; // 协议复选框
  bool _rememberPwdSelected = false;

  bool _showBack = false;
  StreamSubscription<fluwx.BaseWeChatResponse> _wxStreamSubscription;
  ValueNotifier<bool> coverViewVisiable = ValueNotifier(false);

  // 是否显示第三方登录入口
  // 只有在登录非绑定页面的情况下才有显示第三方登录的可能
  // android显示, iOS需要判断审核开关
  // bool get _thirdLoginOpen =>
  //     ServerSideConfiguration.to.thirdLoginOpen.value && !widget.binding;

  AppLifecycleState _currentLifecycleState = AppLifecycleState.resumed;

  // 极光授权原生页在iOS平台上会发生事件穿透
  bool get _absorbBodyPointer =>
      UniversalPlatform.isIOS &&
      _currentLifecycleState != AppLifecycleState.resumed;

  final _pushLoginPageSubject = BehaviorSubject<String>();

  /// 是否极光授权有回调
  /// TODO: 此flag解决外部分享链接进入fanbook时一键登录页ui消失回调执行, 而授权回调未执行
  /// 导致'闪屏'不消失的问题
  bool _jvCallbackedFlag = false;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _currentLifecycleState = state;
    if (UniversalPlatform.isIOS) {
      setState(() {});
    }
    if (state != AppLifecycleState.resumed) {
      _focusNode.unfocus();
    }
  }

  @override
  void initState() {
    if (kIsWeb) {
      /// 登录前得把缓存数据清空

      Db.remarkBox?.clear();
      Db.remarkListBox?.clear();
      Db.dmListBox?.clear();
      Db.channelBox?.clear();
      Db.guildBox?.clear();
      Db.friendListBox?.clear();
    }

    final mobile = widget.mobile?.toString() ?? '';
    _mobileController = TextEditingController(text: mobile)
      ..addListener(() async {
        await _validPhone();
        setState(() {});
      });
    _countryCode = widget.country ?? CountryModel.defaultModel;
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    if (widget.alertInfo != null) {
      Future.delayed(const Duration(milliseconds: 300)).then((value) {
        showTokenFailDialog(context, alterInfo: widget.alertInfo);
      });
    }

    // 针对不同手机，需强行设置光标的位置
    _mobileController.selection =
        TextSelection(baseOffset: mobile.length, extentOffset: mobile.length);

    SpService.to.setBool(SP.rememberPwd, false);

    if (UniversalPlatform.isMobileDevice) {
      // 微信回调监听
      listenWeChatResponseHandler();
    }

    if (UniversalPlatform.isMobileDevice &&
        Global.initJverifySDKSuccess &&
        widget.loginType != LoginType.LoginTypeApple) {
      // 当从隐私协议页(背景UI与原手机登录页一致)进入登录页时，不需要在第一时间显示cover
      JVerifyUtil.checkVerifyEnable()
          .then((value) => coverViewVisiable.value = value && widget.showCover);
      // 授权页事件监听
      // <事件返回码> https://docs.jiguang.cn/jverification/client/android_api/
      Jverify().addAuthPageEventListener((event) {
        // 授权页关闭时在登录页显示返回按钮，可再次拉起授权页
        if (event.code == 1) {
          // login activity closed.
          setNavBackVisibility(true);
          JVerifyUtil.jverifyAuthPageOpened = false;
          // 外部分享时，会被动关闭一键登录页面。也不需要展示伪splash。
          if (!_jvCallbackedFlag) coverViewVisiable.value = false;
        } else if (event.code == 2) {
          // login activity started
          JVerifyUtil.jverifyAuthPageOpened = true;
          coverViewVisiable.value = true;
        } else if (event.code == 6) {
          JVerifyUtil.jverifyChecked = true;
        } else if (event.code == 7) {
          JVerifyUtil.jverifyChecked = false;
        } else if (event.code == 8) {
          // login button clicked.
          Global.thirdLoginClickable = false;
        }
      });
      // 尝试拉起授权页
      _toOneKeyLogin();
    }

    _pushLoginPageSubject
        .throttleTime(const Duration(seconds: 2))
        .listen((event) => _toOneKeyLogin());
  }

  Future<void> _validPhone() async {
    final mobile = _mobileController.text;
    if (_countryCode.phoneCode == '86') {
      // 如果是中国只判断是不是11位
      _isValid = mobile.length == 11;
      _inputLength = 11;
    } else if (_countryCode.phoneCode == '852' ||
        _countryCode.phoneCode == '853') {
      _isValid = mobile.length == 8;
      _inputLength = 8;
    } else if (_countryCode.phoneCode == '886') {
      _isValid = mobile.length == 9;
      _inputLength = 9;
    } else {
      _isValid = mobile.isNotEmpty;
      _inputLength = 20;
    }
  }

  @override
  void dispose() {
    _mobileController.dispose();
    _wxStreamSubscription.cancel();
    _pushLoginPageSubject.close();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isWeb = !OrientationUtil.portrait;
    final body = GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: isWeb ? 36 : 16),
        child: Stack(
          children: [
            MediaQuery.removePadding(
              removeTop: true,
              context: context,
              child: ListView(
                physics: const NeverScrollableScrollPhysics(),
                children: <Widget>[
                  if (!isWeb)
                    const SizedBox(height: 44, width: double.infinity),
                  SizedBox(
                    height: 44,
                    child: Visibility(
                      visible: _showBack,
                      child: UnconstrainedBox(
                        alignment: Alignment.centerLeft,
                        // TODO 不用UnconstrainedBox包一下的话IconButton怎么调都占一行？？？
                        child: IconButton(
                          constraints:
                              const BoxConstraints(minHeight: 44, minWidth: 44),
                          padding: EdgeInsets.zero,
                          alignment: Alignment.centerLeft,
                          icon: Icon(
                            IconFont.buffNavBarBackItem,
                            color: Theme.of(context).textTheme.bodyText2.color,
                          ),
                          onPressed: () =>
                              _pushLoginPageSubject.add('pushLoginAuth'),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: isWeb ? 60 : 48),
                  Text(
                    widget.binding ? '绑定手机号'.tr : '手机号码登录'.tr,
                    style: const TextStyle(
                      fontSize: 24,
                      height: 1.16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF363940),
                    ),
                  ),
                  sizeHeight12,
                  Text(
                      '%s的手机号验证后自动登录'
                          .trArgs([if (widget.binding) '绑定'.tr else '未注册'.tr]),
                      style: Theme.of(context)
                          .textTheme
                          .bodyText1
                          .copyWith(height: 1.21, fontSize: isWeb ? 12 : 14)),
                  SizedBox(
                    height: isWeb ? 64 : 32,
                  ),
                  Column(
                    children: [
                      Builder(
                        builder: (context) => Container(
                          decoration: BoxDecoration(
                            // color: Theme.of(context).scaffoldBackgroundColor,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0x408F959E)),
                          ),
                          height: isWeb ? 42 : 48,
                          child: Row(
                            children: <Widget>[
                              GestureDetector(
                                onTap: () async {
                                  _focusNode.unfocus();
                                  if (isWeb) {
                                    SuperTooltip _tip;
                                    _tip = SuperTooltip(
                                      popupDirection: TooltipDirection.leftTop,
                                      offsetX: 328,
                                      offsetY: 22,
                                      arrowBaseWidth: 0,
                                      arrowLength: 0,
                                      arrowTipDistance: 0,
                                      borderWidth: 1,
                                      borderColor: const Color(0xff717D8D)
                                          .withOpacity(0.1),
                                      shadowColor: const Color(0xff717D8D)
                                          .withOpacity(0.1),
                                      outsideBackgroundColor:
                                          Colors.transparent,
                                      borderRadius: 4,
                                      content: Container(
                                          width: 328,
                                          decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(3.2),
                                              color: CustomColor(context)
                                                  .backgroundColor6,
                                              boxShadow: const [
                                                BoxShadow(
                                                  blurRadius: 16,
                                                  color: Color(0x40717D8D),
                                                  offset: Offset(0, 7),
                                                )
                                              ]),
                                          child: SizedBox(
                                            height: 500,
                                            child: CountryPageWeb(
                                              callback: (model) {
                                                setState(() {
                                                  _countryCode = model;
                                                });
                                                unawaited(_validPhone());
                                                _tip.close();
                                              },
                                            ),
                                          )),
                                    );
                                    _tip.show(context);
                                  } else {
                                    final result =
                                        await Routes.pushCountryPage(context);
                                    if (result != null) {
                                      setState(() {
                                        _countryCode = result;
                                      });
                                      unawaited(_validPhone());
                                    }
                                  }
                                },
                                child: SizedBox(
                                    width: 66,
                                    child: Center(
                                        child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: <Widget>[
                                          Text(
                                            '+${_countryCode.phoneCode}',
                                            style: const TextStyle(
                                                fontSize: 16,
                                                color: Color(0xFF1F2125)),
                                          ),
                                          Icon(
                                            IconFont.buffDownMore,
                                            color: Theme.of(context)
                                                .textTheme
                                                .bodyText2
                                                .color,
                                            size: 16,
                                          )
                                        ]))),
                              ),
                              const SizedBox(
                                height: 20,
                                child:
                                    VerticalDivider(color: Color(0x328F959E)),
                              ),
                              Expanded(
                                child: TextField(
                                  // TODO　受一键页影响这个地方需要处理一下，后面想办法
                                  // autofocus: true,
                                  readOnly: _loading,
                                  focusNode: _focusNode,
                                  keyboardType: TextInputType.phone,
                                  controller: _mobileController,
                                  inputFormatters: <TextInputFormatter>[
                                    LengthLimitingTextInputFormatter(
                                        _inputLength), //限制长度
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                  decoration: InputDecoration(
                                    contentPadding: EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: isWeb ? 10 : 12),
                                    border: InputBorder.none,
                                    hintText: '请输入手机号'.tr,
                                    hintStyle: const TextStyle(
                                      color: Color(0x968F959E),
                                      fontSize: 16,
                                    ),
                                    suffixIcon: IconButton(
                                        icon: Icon(
                                          _mobileController.text.trim() == ''
                                              ? null
                                              : IconFont.buffClose,
                                          color: const Color(0xFFaaaaaa),
                                          size: 20,
                                        ),
                                        onPressed: () {
                                          WidgetsBinding.instance
                                              .addPostFrameCallback((_) =>
                                                  _mobileController.clear());
                                        }),
                                  ),
//                                  onFieldSubmitted: (value) {
//                                    if (!_isValid || _loading) return;
//                                    toCaptcha();
//                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      sizeHeight16,
                      SizedBox(
                          width: double.infinity,
                          height: isWeb ? 42 : 48,
                          child: TextButton(
                            onPressed:
                                (!_isValid || _loading) ? null : toCaptcha,
                            style: TextButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6)),
                              backgroundColor: (!_isValid || _loading)
                                  ? Theme.of(context)
                                      .primaryColor
                                      .withOpacity(0.4)
                                  : Theme.of(context).primaryColor,
                            ),
                            child: _loading
                                ? DefaultTheme.defaultLoadingIndicator(
                                    color: Colors.white)
                                : Text(
                                    '获取验证码'.tr,
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w400,
                                        color: (!_isValid || _loading)
                                            ? Colors.white.withOpacity(0.5)
                                            : Colors.white),
                                  ),
                          )),
                      sizeHeight16,
                    ],
                  ),
                  Row(
                    children: [
                      if (OrientationUtil.portrait)
                        RoundCheckBox(
                          left: 0,
                          right: 8,
                          defaultValue: _checkboxSelected ?? false,
                          onChanged: (value) {
                            setState(() {
                              _checkboxSelected = value;
                              // 登录时有checkbox限制用户看隐私
                              // 进入主页后里面目前就不需要再弹隐私对话框了
                              // 防止以后隐私更新，暂保留并注释
                              //
                              // if (_checkboxSelected) {
                              //   SharedData.instance
                              //       .setBool("checkProtocol", true);
                              // } else {
                              //   SharedData.instance
                              //       .setBool("checkProtocol", false);
                              // }
                            });
                          },
                        )
                      else
                        FBCheckBox(
                            value: _checkboxSelected ?? false,
                            onChanged: (value) {
                              setState(() {
                                _checkboxSelected = value;
                                // 同上
                                //
                                // if (_checkboxSelected) {
                                //   SharedData.instance
                                //       .setBool("checkProtocol", true);
                                // } else {
                                //   SharedData.instance
                                //       .setBool("checkProtocol", false);
                                // }
                              });
                            }),
                      sizeWidth4,
                      Expanded(
                        child: Text.rich(
                          TextSpan(children: [
                            TextSpan(
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () {
                                    setState(() {
                                      _checkboxSelected = !_checkboxSelected;
                                    });
                                  },
                                text: "请阅读并同意".tr,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyText1
                                    .copyWith(
                                        fontSize: isWeb ? 12 : 13,
                                        height: 1.3)),
                            TextSpan(
                                text: "隐私政策".tr,
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () {
                                    final Map<String, String> params = {
                                      'udx':
                                          '93${DateTime.now().millisecondsSinceEpoch}3d4',
                                    };

                                    final uri = Uri.parse(
                                            '${Config.useHttps ? "https" : "http"}://${ApiUrl.privacyUrl}')
                                        .addParams(params);
                                    Routes.pushHtmlPageWithUri(context, uri,
                                        title: '隐私政策'.tr);
                                  },
                                style: TextStyle(
                                    fontSize: isWeb ? 12 : 13,
                                    color: Theme.of(context).primaryColor,
                                    height: 1.3)),
                            TextSpan(
                                text: "、".tr,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyText1
                                    .copyWith(
                                        fontSize: isWeb ? 12 : 13,
                                        height: 1.3)),
                            TextSpan(
                                text: "用户协议".tr,
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () {
                                    final Map<String, String> params = {
                                      'udx':
                                          '93${DateTime.now().millisecondsSinceEpoch}3c4',
                                    };

                                    final uri = Uri.parse(
                                            '${Config.useHttps ? "https" : "http"}://${ApiUrl.termsUrl}')
                                        .addParams(params);
                                    Routes.pushHtmlPageWithUri(context, uri,
                                        title: '用户协议'.tr);
                                  },
                                style: TextStyle(
                                    fontSize: isWeb ? 12 : 13,
                                    color: Theme.of(context).primaryColor,
                                    height: 1.3)),
                            TextSpan(
                                text: "和".tr,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyText1
                                    .copyWith(
                                        fontSize: isWeb ? 12 : 13,
                                        height: 1.3)),
                            TextSpan(
                                text: "服务器公约".tr,
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () {
                                    final Map<String, String> params = {
                                      'udx':
                                          '93${DateTime.now().millisecondsSinceEpoch}3d4',
                                    };

                                    final uri = Uri.parse(
                                            '${Config.useHttps ? "https" : "http"}://${ApiUrl.conventionUrl}')
                                        .addParams(params);
                                    Routes.pushHtmlPageWithUri(context, uri,
                                        title: '服务器公约'.tr);
                                  },
                                style: TextStyle(
                                    fontSize: isWeb ? 12 : 13,
                                    color: Theme.of(context).primaryColor,
                                    height: 1.3)),
                          ]),
                          maxLines: 2,
                          // overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (kIsWeb)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FBCheckBox(
                            value: _rememberPwdSelected,
                            onChanged: (value) => toggleRememberPwd()),
                        sizeWidth4,
                        GestureDetector(
                          onTap: toggleRememberPwd,
                          child: Text('30天内自动登录'.tr,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyText1
                                  .copyWith(fontSize: 12, height: 1.3)),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            if (!widget.binding)
              Positioned(
                left: 0,
                right: 0,
                bottom: 78,
                child: ThirdLogin(isChecked: _checkboxSelected),
              ),
          ],
        ),
      ),
    );
    return WillPopScope(
      onWillPop: () async {
        if (!UniversalPlatform.isMobileDevice) {
          return Future.value(true);
        }
        // 捕捉虚拟返回键行为，一键环境下返回时拉起一键登录
        final bool checkEnv = await JVerifyUtil.checkVerifyEnable();
        if (checkEnv) {
          await _toOneKeyLogin(needCheck: false);
          return Future.value(false);
        } else {
          return Future.value(true);
        }
      },
      child: OrientationBuilder(builder: (context, _) {
        if (OrientationUtil.portrait) {
          return ValueListenableBuilder(
              valueListenable: coverViewVisiable,
              builder: (context, value, child) {
                return value
                    ? Container(
                        alignment: Alignment.bottomCenter,
                        color: Colors.white,
                        padding: EdgeInsets.only(
                            bottom: 48 + MediaQuery.of(context).padding.bottom),
                        child: WebsafeSvg.asset(
                          "assets/launch_screen_logo.svg",
                          width: 146,
                          height: 32,
                        ))
                    : Scaffold(
                        // 解决添加其它登录方式(Stack+Positioned)布局会被键盘顶上去的问题
                        resizeToAvoidBottomInset: false,
                        backgroundColor: Theme.of(context).backgroundColor,
                        body: Stack(
                          children: [
                            Positioned(
                              top: 0,
                              child: WebsafeSvg.asset(
                                'assets/svg/login_page_bg.svg',
                                fit: BoxFit.fitWidth,
                                alignment: Alignment.topCenter,
                                width: Get.width,
                              ),
                            ),
                            AbsorbPointer(
                              absorbing: _absorbBodyPointer,
                              child: body,
                            ),
                          ],
                        ),
                      );
              });
        } else {
          return Scaffold(
            body: Center(
              child: Container(
                width: 400,
                height: 521,
                decoration: webBorderDecoration,
                child: body,
              ),
            ),
          );
        }
      }),
    );
  }

  void toggleRememberPwd() {
    setState(() {
      _rememberPwdSelected = !_rememberPwdSelected;
      SpService.to.setBool(SP.rememberPwd, _rememberPwdSelected);
    });
  }

  Future toCaptcha() async {
    // 是否满足协议提示条件
    if (!_checkboxSelected) {
      showToast("阅读并同意隐私政策、用户协议和服务器公约才能登录".tr, radius: 8);

      /// 获取验证码失败
      DLogManager.getInstance().customEvent(
          actionEventId: 'get_verify_code_stauts',
          actionEventSubId: '0',
          actionEventSubParam: '2',
          pageId: 'page_login');
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
    });

    try {
      await UserApi.sendCaptcha(int.parse(_mobileController.text.trim()),
          getPlatform(), _countryCode.phoneCode);
      setState(() {
        _loading = false;
      });
      unawaited(Routes.pushLoginCaptchaPage(
        context,
        mobile: int.parse(_mobileController.text.trim()),
        country: _countryCode,
        fadeIn: true,
        thirdParty: widget.thirdParty,
        loginType: widget.loginType,
      ));
      DLogManager.getInstance().customEvent(
          actionEventId: 'get_verify_code_stauts',
          actionEventSubId: '1',
          pageId: 'page_login');
    } catch (e) {
      print(e);
      setState(() {
        _loading = false;
      });

      DLogManager.getInstance().customEvent(
          actionEventId: 'get_verify_code_stauts',
          actionEventSubId: '0',
          actionEventSubParam: '1',
          pageId: 'page_login');
    }
  }

  void setNavBackVisibility(bool visible) {
    if (!mounted) return;
    if (_showBack == visible) return;
    setState(() => _showBack = visible);
  }

  /// 一键登录入口
  /// 在监听返回(android侧滑)时需先判断环境是否支持一键，不支持的话直接退出应用，
  /// 所以这加个参数[needCheck］在上述情况下防止多次check环境。
  Future _toOneKeyLogin({bool needCheck = true}) async {
    Global.thirdLoginClickable = true;
    if (needCheck) {
      // 每次尝试一键登录时都要判断一下环境，防止中途拔掉sim卡
      final bool checkEnv = await JVerifyUtil.checkVerifyEnable();
      debugPrint('一键登录环境: $checkEnv');
      if (!checkEnv) {
        // setNavBackVisibility(false);
        // showBack为true时证明之前有拉起过授权页，只有在这种情况下，尝试点击返回键再次
        // 拉起时如果环境有问题，需要toast
        if (_showBack) {
          showToast('网络异常，请检查网络后重试'.tr, radius: 8);
        }
        return;
      }
    }
    final bool isInstallWeChat = await isShowWeChatLogin();
    await oneKeyLoginAuth(
      onOther: () => setNavBackVisibility(true),
      appleLoginOpen: isShowAppleLogin(),
      wechatLoginOpen: isInstallWeChat,
      binding: widget.binding,
      thirdParty: widget.thirdParty,
    );
  }

  /// 一键登录/绑定之请求授权，如果绑定的话，需要传入第三方参数
  /// [onOther] 点击其它方式登录按钮回调，这里需要更新显示登录页面左上返回键
  /// [thirdLoginOpen] 第三方登录入口是否显示
  /// [binding] 一键登录还是一键绑定
  /// [thirdParty］第三方登录注册凭证
  Future oneKeyLoginAuth({
    Function onOther,
    bool appleLoginOpen = true,
    bool wechatLoginOpen = true,
    bool binding = false,
    String thirdParty = "",
  }) async {
    final Jverify jVerify = Jverify();
    // 调用接口设置 UI
    JVerifyUtil.buildAuthorizationView(
      context,
      onOther,
      appleLoginOpen: appleLoginOpen,
      wechatLoginOpen: wechatLoginOpen,
      binding: binding,
    );
    // 添加loginAuthSyncApi接口回调事件
    jVerify.addLoginAuthCallBackListener((event) async {
      final int code = event.code;
      final String content = event.message;
      final String operator = event.operator;
      // Jverify().dismissLoginAuthView();
      // if (!JVerifyUtil.jverifyAuthPageOpened) {
      //   coverViewVisiable.value = false;
      //   return;
      // }

      _jvCallbackedFlag = true;
      if (code == 6000) {
        // 获取loginToken成功　message就是loginToken
        logger.info("loginAuth，code=$code,message=$content,op=$operator");
        Loading.show(context);
        try {
          final _jsonMap =
              await UserApi.loginOneKey(content, thirdParty: thirdParty);
          Loading.hide();
          debugPrint('loginOneKey result: $_jsonMap');
          await _handlerLogin(_jsonMap,
              oneKey: true,
              thirdParty: thirdParty,
              loginType: LoginType.LoginTypeOneKey);
        } catch (e) {
          coverViewVisiable.value = false;
          DLogManager.getInstance().customEvent(
              actionEventId: 'login_status',
              actionEventSubId: '0',
              pageId: 'page_login',
              actionEventSubParam: e?.toString() ?? '',
              extJson: {
                "login_type": "oneclick_login",
                'invite_code': InviteCodeUtil.inviteCode
              });
          Loading.hide();
        }
        return;
      }

      DLogManager.getInstance().customEvent(
          actionEventId: 'login_status',
          actionEventSubId: '0',
          pageId: 'page_login',
          actionEventSubParam: code?.toString() ?? '',
          extJson: {
            "login_type": "oneclick_login",
            'invite_code': InviteCodeUtil.inviteCode
          });
      coverViewVisiable.value = false;
      logger.warning("loginAuth code=$code, op=$operator");
      // https://docs.jiguang.cn/jverification/client/android_api/
      if (code == 2005) {
        // 2005为timeout,对应loginAuthSyncyAPi里面的timeout,即拉起授权页超时
        // 其实这种情况目前不需要做任何处理，表现为授权页不拉起而一直显示为手机号登录页面
      } else if (code == 6001 || code == 6004) {
        // 6001是获取失败，6004是频繁获取时提示requesting..please try again later.
        // 注：开vpn的情况下，授权页未弹起，6001同样也会回调
        if (JVerifyUtil.jverifyAuthPageOpened) {
          await CommonAlertDialog.show(context,
              '一键${binding ? "绑定".tr : "登录".tr}失败，请选择其他${binding ? "绑定".tr : "登录".tr}方式');
        }
      }
    });
    // 修改为自动dismiss
    // 目前在授权页拉后，然后将A-sim卡4G换成B-sim卡4G时手动dismiss无效，无法关闭授权原生页
    JVerifyUtil.jverifyChecked = false;
    jVerify.loginAuthSyncApi(autoDismiss: true, timeout: 4000);
  }

  /// 监听微信授权后的回调
  void listenWeChatResponseHandler() {
    _wxStreamSubscription = fluwx.weChatResponseEventHandler
        .distinct((a, b) => a == b)
        .listen((event) async {
      if (event is fluwx.WeChatAuthResponse) {
        if (event.code == null || event.code.isEmpty) {
          DLogManager.getInstance().customEvent(
              actionEventId: 'login_status',
              actionEventSubId: '0',
              pageId: 'page_login',
              actionEventSubParam: "${event.errCode}",
              extJson: {
                "login_type": "wechat_login",
                'invite_code': InviteCodeUtil.inviteCode
              });
          return;
        }
        debugPrint('login wx code: ${event.code}');
        Jverify().dismissLoginAuthView();
        // TODO 此处加load会导致iOS卡死现象，有checkout到"9e7b91b57"这时出现
        // Loading.show(context);
        Map<String, dynamic> _jsonMap;
        try {
          _jsonMap = await UserApi.loginWx(event.code);
        } catch (e) {
          DLogManager.getInstance().customEvent(
              actionEventId: 'login_status',
              actionEventSubId: '0',
              pageId: 'page_login',
              actionEventSubParam: e?.toString() ?? '',
              extJson: {
                "login_type": "wechat_login",
                'invite_code': InviteCodeUtil.inviteCode
              });
          // Loading.hide();
          return;
        }
        // Loading.hide();
        debugPrint('login wx result: $_jsonMap');
        if (_jsonMap['n'] == 1) {
          // 微信新用户，未绑定
          await Routes.pushLoginPage(
            context,
            replace: true,
            binding: true,
            thirdParty: _jsonMap['third_party'],
            loginType: LoginType.LoginTypeWX,
          );
        } else {
          await _handlerLogin(_jsonMap, loginType: LoginType.LoginTypeWX);
        }
      }
    });
  }

  Future _handlerLogin(
    var _jsonMap, {
    bool oneKey = false,
    String thirdParty,
    LoginType loginType = LoginType.LoginTypePhoneNum,
  }) async {
    // https://community.jiguang.cn/question/394450
    await LoginThreshold.entry(
      context,
      _jsonMap,
      oneKey: oneKey,
      thirdParty: thirdParty,
      country: CountryModel.defaultModel.toString(),
      loginType: loginType,
    );
  }
}
