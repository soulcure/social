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

///??????????????????????????????
Future<bool> isShowWeChatLogin() async {
  final bool config = ServerSideConfiguration.to.wechatLoginOpen.value;
  final bool install = await fluwx.isWeChatInstalled;
  return config && install;
}

///??????????????????????????????
bool isShowAppleLogin() {
  return ServerSideConfiguration.to.appleLoginOpen.value;
}

/// login??????
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
  bool _checkboxSelected = false; // ???????????????
  bool _rememberPwdSelected = false;

  bool _showBack = false;
  StreamSubscription<fluwx.BaseWeChatResponse> _wxStreamSubscription;
  ValueNotifier<bool> coverViewVisiable = ValueNotifier(false);

  // ?????????????????????????????????
  // ??????????????????????????????????????????????????????????????????????????????
  // android??????, iOS????????????????????????
  // bool get _thirdLoginOpen =>
  //     ServerSideConfiguration.to.thirdLoginOpen.value && !widget.binding;

  AppLifecycleState _currentLifecycleState = AppLifecycleState.resumed;

  // ????????????????????????iOS??????????????????????????????
  bool get _absorbBodyPointer =>
      UniversalPlatform.isIOS &&
      _currentLifecycleState != AppLifecycleState.resumed;

  final _pushLoginPageSubject = BehaviorSubject<String>();

  /// ???????????????????????????
  /// TODO: ???flag??????????????????????????????fanbook??????????????????ui??????????????????, ????????????????????????
  /// ??????'??????'??????????????????
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
      /// ?????????????????????????????????

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

    // ???????????????????????????????????????????????????
    _mobileController.selection =
        TextSelection(baseOffset: mobile.length, extentOffset: mobile.length);

    SpService.to.setBool(SP.rememberPwd, false);

    if (UniversalPlatform.isMobileDevice) {
      // ??????????????????
      listenWeChatResponseHandler();
    }

    if (UniversalPlatform.isMobileDevice &&
        Global.initJverifySDKSuccess &&
        widget.loginType != LoginType.LoginTypeApple) {
      // ?????????????????????(??????UI???????????????????????????)???????????????????????????????????????????????????cover
      JVerifyUtil.checkVerifyEnable()
          .then((value) => coverViewVisiable.value = value && widget.showCover);
      // ?????????????????????
      // <???????????????> https://docs.jiguang.cn/jverification/client/android_api/
      Jverify().addAuthPageEventListener((event) {
        // ???????????????????????????????????????????????????????????????????????????
        if (event.code == 1) {
          // login activity closed.
          setNavBackVisibility(true);
          JVerifyUtil.jverifyAuthPageOpened = false;
          // ???????????????????????????????????????????????????????????????????????????splash???
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
      // ?????????????????????
      _toOneKeyLogin();
    }

    _pushLoginPageSubject
        .throttleTime(const Duration(seconds: 2))
        .listen((event) => _toOneKeyLogin());
  }

  Future<void> _validPhone() async {
    final mobile = _mobileController.text;
    if (_countryCode.phoneCode == '86') {
      // ?????????????????????????????????11???
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
                        // TODO ??????UnconstrainedBox???????????????IconButton??????????????????????????????
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
                    widget.binding ? '???????????????'.tr : '??????????????????'.tr,
                    style: const TextStyle(
                      fontSize: 24,
                      height: 1.16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF363940),
                    ),
                  ),
                  sizeHeight12,
                  Text(
                      '%s?????????????????????????????????'
                          .trArgs([if (widget.binding) '??????'.tr else '?????????'.tr]),
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
                                  // TODO?????????????????????????????????????????????????????????????????????
                                  // autofocus: true,
                                  readOnly: _loading,
                                  focusNode: _focusNode,
                                  keyboardType: TextInputType.phone,
                                  controller: _mobileController,
                                  inputFormatters: <TextInputFormatter>[
                                    LengthLimitingTextInputFormatter(
                                        _inputLength), //????????????
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                  decoration: InputDecoration(
                                    contentPadding: EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: isWeb ? 10 : 12),
                                    border: InputBorder.none,
                                    hintText: '??????????????????'.tr,
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
                                    '???????????????'.tr,
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
                              // ????????????checkbox?????????????????????
                              // ???????????????????????????????????????????????????????????????
                              // ?????????????????????????????????????????????
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
                                // ??????
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
                                text: "??????????????????".tr,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyText1
                                    .copyWith(
                                        fontSize: isWeb ? 12 : 13,
                                        height: 1.3)),
                            TextSpan(
                                text: "????????????".tr,
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
                                        title: '????????????'.tr);
                                  },
                                style: TextStyle(
                                    fontSize: isWeb ? 12 : 13,
                                    color: Theme.of(context).primaryColor,
                                    height: 1.3)),
                            TextSpan(
                                text: "???".tr,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyText1
                                    .copyWith(
                                        fontSize: isWeb ? 12 : 13,
                                        height: 1.3)),
                            TextSpan(
                                text: "????????????".tr,
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
                                        title: '????????????'.tr);
                                  },
                                style: TextStyle(
                                    fontSize: isWeb ? 12 : 13,
                                    color: Theme.of(context).primaryColor,
                                    height: 1.3)),
                            TextSpan(
                                text: "???".tr,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyText1
                                    .copyWith(
                                        fontSize: isWeb ? 12 : 13,
                                        height: 1.3)),
                            TextSpan(
                                text: "???????????????".tr,
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
                                        title: '???????????????'.tr);
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
                          child: Text('30??????????????????'.tr,
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
        // ????????????????????????????????????????????????????????????????????????
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
                        // ??????????????????????????????(Stack+Positioned)????????????????????????????????????
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
    // ??????????????????????????????
    if (!_checkboxSelected) {
      showToast("????????????????????????????????????????????????????????????????????????".tr, radius: 8);

      /// ?????????????????????
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

  /// ??????????????????
  /// ???????????????(android??????)??????????????????????????????????????????????????????????????????????????????
  /// ?????????????????????[needCheck?????????????????????????????????check?????????
  Future _toOneKeyLogin({bool needCheck = true}) async {
    Global.thirdLoginClickable = true;
    if (needCheck) {
      // ????????????????????????????????????????????????????????????????????????sim???
      final bool checkEnv = await JVerifyUtil.checkVerifyEnable();
      debugPrint('??????????????????: $checkEnv');
      if (!checkEnv) {
        // setNavBackVisibility(false);
        // showBack???true?????????????????????????????????????????????????????????????????????????????????????????????
        // ???????????????????????????????????????toast
        if (_showBack) {
          showToast('???????????????????????????????????????'.tr, radius: 8);
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

  /// ????????????/????????????????????????????????????????????????????????????????????????
  /// [onOther] ??????????????????????????????????????????????????????????????????????????????????????????
  /// [thirdLoginOpen] ?????????????????????????????????
  /// [binding] ??????????????????????????????
  /// [thirdParty??????????????????????????????
  Future oneKeyLoginAuth({
    Function onOther,
    bool appleLoginOpen = true,
    bool wechatLoginOpen = true,
    bool binding = false,
    String thirdParty = "",
  }) async {
    final Jverify jVerify = Jverify();
    // ?????????????????? UI
    JVerifyUtil.buildAuthorizationView(
      context,
      onOther,
      appleLoginOpen: appleLoginOpen,
      wechatLoginOpen: wechatLoginOpen,
      binding: binding,
    );
    // ??????loginAuthSyncApi??????????????????
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
        // ??????loginToken?????????message??????loginToken
        logger.info("loginAuth???code=$code,message=$content,op=$operator");
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
        // 2005???timeout,??????loginAuthSyncyAPi?????????timeout,????????????????????????
        // ?????????????????????????????????????????????????????????????????????????????????????????????????????????????????????
      } else if (code == 6001 || code == 6004) {
        // 6001??????????????????6004????????????????????????requesting..please try again later.
        // ?????????vpn????????????????????????????????????6001??????????????????
        if (JVerifyUtil.jverifyAuthPageOpened) {
          await CommonAlertDialog.show(context,
              '??????${binding ? "??????".tr : "??????".tr}????????????????????????${binding ? "??????".tr : "??????".tr}??????');
        }
      }
    });
    // ???????????????dismiss
    // ????????????????????????????????????A-sim???4G??????B-sim???4G?????????dismiss????????????????????????????????????
    JVerifyUtil.jverifyChecked = false;
    jVerify.loginAuthSyncApi(autoDismiss: true, timeout: 4000);
  }

  /// ??????????????????????????????
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
        // TODO ?????????load?????????iOS??????????????????checkout???"9e7b91b57"????????????
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
          // ???????????????????????????
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
