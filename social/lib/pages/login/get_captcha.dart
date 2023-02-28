import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:im/api/user_api.dart';
import 'package:im/core/widgets/loading.dart';
import 'package:im/dlog/dlog_manager.dart';
import 'package:im/pages/login/login_threshold.dart';
import 'package:im/themes/const.dart';
import 'package:im/utils/invite_code/invite_code_util.dart';
import 'package:im/utils/orientation_util.dart';
import 'package:im/utils/utils.dart';
import 'package:im/widgets/text_field/native_input.dart';
import 'package:oktoast/oktoast.dart';
import 'package:websafe_svg/websafe_svg.dart';

import '../../icon_font.dart';
import 'model/country_model.dart';

/// 获取验证码
class LoginCaptchaPage extends StatefulWidget {
  final int mobile;
  final CountryModel country;
  final String thirdParty;
  final LoginType loginType;

  const LoginCaptchaPage(
      this.mobile, this.country, this.thirdParty, this.loginType);

  @override
  _LoginCaptchaPageState createState() => _LoginCaptchaPageState();
}

class _LoginCaptchaPageState extends State<LoginCaptchaPage> {
  final TextEditingController _captchaController = TextEditingController();
  final int _limitLength = 6;
  int _count = 60;
  Timer _countTimer;
  bool _enableSend = false;
  bool _sendLoading = false;
  FocusNode _node;

  Rx<String> codeRequestQueue = Rx<String>(null);

  Worker worker;

  @override
  void initState() {
    _node = FocusNode();
    _node.requestFocus();
    worker = debounce<void>(codeRequestQueue, doRequest,
        time: const Duration(milliseconds: 500));
    startCount();
    super.initState();
  }

  @override
  void dispose() {
    worker.dispose();
    _captchaController.dispose();
    _countTimer?.cancel();
    _node?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isWeb = !OrientationUtil.portrait;
    final child = GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if (!isWeb) ...[
              const SizedBox(height: 44, width: double.infinity),
              SizedBox(
                height: 44,
                child: UnconstrainedBox(
                  alignment: Alignment.centerLeft,
                  // TODO 不用UnconstrainedBox包一下的话IconButton怎么调都占一行？？？
                  child: IconButton(
                    constraints: const BoxConstraints(
                      minHeight: 44,
                      minWidth: 44,
                    ),
                    padding: EdgeInsets.zero,
                    alignment: Alignment.centerLeft,
                    icon: Icon(
                      IconFont.buffNavBarBackItem,
                      color: Theme.of(context).textTheme.bodyText2.color,
                    ),
                    onPressed: Get.back,
                  ),
                ),
              )
            ] else
              Container(
                margin: const EdgeInsets.only(top: 10),
                height: 24,
                width: 100,
                child: TextButton(
                  onPressed: Get.back,
                  child: Row(
                    children: [
                      Icon(
                        IconFont.buffNavBarBackItem,
                        size: 14,
                        color: Theme.of(context).textTheme.bodyText1.color,
                      ),
                      Text('返回'.tr,
                          style: Theme.of(context).textTheme.bodyText1)
                    ],
                  ),
                ),
              ),
            SizedBox(height: isWeb ? 18 : 48),
            Text(
              '输入验证码'.tr,
              style: const TextStyle(
                fontSize: 24,
                height: 1.16,
                fontWeight: FontWeight.w600,
              ),
            ),
            sizeHeight12,
            Text(
                '验证码已发送至 +%s %s'.trArgs([
                  widget.country.phoneCode.toString(),
                  widget.mobile.toString()
                ]),
                style: Theme.of(context)
                    .textTheme
                    .bodyText1
                    .copyWith(height: 1.21, fontSize: isWeb ? 12 : 14)),
            SizedBox(
              height: isWeb ? 64 : 32,
            ),
            Container(
              height: 48,
              decoration: BoxDecoration(
                // color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0x408F959E)),
              ),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: NativeInput(
                      keyboardType: TextInputType.phone,
                      controller: _captchaController,
                      focusNode: _node,
                      // style: Theme.of(context).textTheme.bodyText1,
                      inputFormatters: <TextInputFormatter>[
                        LengthLimitingTextInputFormatter(_limitLength) //限制长度
                      ],
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        border: InputBorder.none,
                        hintText: '输入验证码'.tr,
                        hintStyle: const TextStyle(
                          color: Color(0x968F959E),
                          fontSize: 16,
                        ),
                      ),
                      onChanged: _onChanged,
                      autofocus: true,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: _enableSend
                        ? GestureDetector(
                            onTap: _getCaptcha,
                            child: Text(
                              '重新发送'.tr,
                              style: TextStyle(
                                  color: Theme.of(context).primaryColor),
                            ),
                          )
                        : Text('$_count s',
                            style: Theme.of(context).textTheme.bodyText1),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
    return OrientationBuilder(
      builder: (context, _) {
        if (OrientationUtil.portrait) {
          return Scaffold(
            resizeToAvoidBottomInset: false,
            backgroundColor: Theme.of(context).backgroundColor,
            // appBar: MyAppBar(
            //   backgroundColor: Theme.of(context).backgroundColor,
            //   leading: const CustomBackButton(),
            // ),
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
                child,
              ],
            ),
          );
        } else {
          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            body: Center(
              child: Container(
                alignment: Alignment.center,
                width: 400,
                height: 521,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 26,
                      spreadRadius: 7,
                      offset: Offset(0, 7),
                      color: Color(0x1F717D8D),
                    )
                  ],
                ),
                child: child,
              ),
            ),
          );
        }
      },
    );
  }

  void startCount() {
    _count = 60;
    _countTimer?.cancel();
    _countTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _count--;
      if (_count == 0) {
        _enableSend = true;
        _countTimer.cancel();
      }
      setState(() {});
    });
  }

  void _getCaptcha() {
    if (_sendLoading) return;
    _sendLoading = true;
    UserApi.sendCaptcha(widget.mobile, getPlatform(), widget.country.phoneCode)
        .then((res) {
      showToastWidget(
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            color: const Color(0xFF15171A),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(
                Icons.info,
                size: 17,
                color: Colors.white,
              ),
              sizeWidth5,
              Text(
                '验证码已发送'.tr,
                style: Theme.of(context)
                    .textTheme
                    .bodyText2
                    .copyWith(fontSize: 14, color: Colors.white),
              )
            ],
          ),
        ),
      );
      startCount();
      _enableSend = false;
      _sendLoading = false;
    }).catchError((e) {
      _sendLoading = false;
    });
  }

  Future<void> doRequest(void _) async {
    try {
      Loading.show(context);
      FocusScope.of(context).unfocus();
      final _jsonMap = await UserApi.login(
        widget.mobile,
        _captchaController.text,
        getPlatform(),
        widget.country.phoneCode,
        thirdParty: widget.thirdParty,
      );
      Loading.hide();
      await LoginThreshold.entry(context, _jsonMap,
          country: widget.country.toString(),
          thirdParty: widget.thirdParty,
          loginType: widget.loginType);
    } catch (e) {
      String loginTypeStr = "other_number_login";
      if (widget.loginType == LoginType.LoginTypeOneKey) {
        /// 本机号码一键登录
        loginTypeStr = "oneclick_login";
      } else if (widget.loginType == LoginType.LoginTypeWX) {
        /// 微信授权登录
        loginTypeStr = "wechat_login";
      } else if (widget.loginType == LoginType.LoginTypeApple) {
        /// apple授权登录
        loginTypeStr = "apple_login";
      }

      Loading.hide();
      DLogManager.getInstance().customEvent(
          actionEventId: 'login_status',
          actionEventSubId: '0',
          actionEventSubParam: e?.toString(),
          pageId: 'page_login',
          extJson: {
            "login_type": loginTypeStr,
            'invite_code': InviteCodeUtil.inviteCode
          });
    }
  }

  Future<void> _onChanged(value) async {
    if (value.trim().length != _limitLength) {
      return;
    }
    codeRequestQueue.subject.add(value);
  }

// _buildCaptcha() {
//   List<Widget> _list = [];

//   for (var i = 0; i < _limitLength; i++) {
//     _list.add(_buildCaptchaItem());

//     if (i != _limitLength) {
//       _list.add(sizeWidth16);
//     }
//   }
//   return Container(
//       alignment: Alignment.center,
//       child: Row(
//         children: _list,
//       ));
// }

// _buildCaptchaItem() {
//   return Container(
//     width: 20,
//     height: 50,
//     color: Theme.of(context).backgroundColor,
//     child: TextField(
//       decoration: InputDecoration(focusColor: Colors.transparent),
//     ),
//   );
// }
}
