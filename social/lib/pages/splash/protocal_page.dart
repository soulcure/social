import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:im/icon_font.dart';
import 'package:im/routes.dart';
import 'package:im/themes/const.dart';
import 'package:im/utils/sensitive_sdk_util.dart';
import 'package:pedantic/pedantic.dart';
import 'package:websafe_svg/websafe_svg.dart';

class ProtocalPage extends StatefulWidget {
  @override
  _ProtocalPageState createState() => _ProtocalPageState();
}

class _ProtocalPageState extends State<ProtocalPage>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((d) {
      _checkSensitiveSDK();
    });
  }

  Future<void> _checkSensitiveSDK() async {
    // 检测是否需要弹窗
    await SensitiveSDKUtil.request(context);
    unawaited(Routes.pushLoginPage(context, replace: true, showCover: false));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final TextStyle style1 = Theme.of(context)
        .textTheme
        .bodyText1
        .copyWith(fontSize: 13, height: 1.3);
    final TextStyle style2 = TextStyle(
        fontSize: 13, color: Theme.of(context).primaryColor, height: 1.3);
    final body = GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Stack(
          children: [
            MediaQuery.removePadding(
              removeTop: true,
              context: context,
              child: ListView(
                physics: const NeverScrollableScrollPhysics(),
                children: <Widget>[
                  const SizedBox(height: 44, width: double.infinity),
                  const SizedBox(height: 44),
                  const SizedBox(height: 48),
                  Text(
                    '手机号码登录'.tr,
                    style: const TextStyle(
                      fontSize: 24,
                      height: 1.16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF363940),
                    ),
                  ),
                  sizeHeight12,
                  Text('未注册的手机号验证后自动登录'.tr,
                      style: Theme.of(context)
                          .textTheme
                          .bodyText1
                          .copyWith(height: 1.21, fontSize: 14)),
                  const SizedBox(height: 32),
                  Column(
                    children: [
                      Builder(
                        builder: (context) => Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: const Color(0x408F959E)),
                          ),
                          height: 48,
                          child: Row(
                            children: <Widget>[
                              SizedBox(
                                width: 66,
                                child: Center(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: <Widget>[
                                      const Text(
                                        '+86',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Color(0xFF1F2125),
                                        ),
                                      ),
                                      Icon(
                                        IconFont.buffDownMore,
                                        color: Theme.of(context)
                                            .textTheme
                                            .bodyText2
                                            .color,
                                        size: 16,
                                      )
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(
                                height: 20,
                                child:
                                    VerticalDivider(color: Color(0x328F959E)),
                              ),
                              Expanded(
                                child: TextField(
                                  keyboardType: TextInputType.phone,
                                  enabled: false,
                                  decoration: InputDecoration(
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    border: InputBorder.none,
                                    hintText: '请输入手机号'.tr,
                                    hintStyle: const TextStyle(
                                      color: Color(0x968F959E),
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      sizeHeight16,
                      SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: TextButton(
                            onPressed: () {},
                            style: TextButton.styleFrom(
                              backgroundColor: Theme.of(context)
                                  .primaryColor
                                  .withOpacity(0.4),
                            ),
                            child: Text(
                              '获取验证码'.tr,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.4),
                              ),
                            ),
                          )),
                      sizeHeight16,
                    ],
                  ),
                  Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(
                          top: 6,
                          right: 8,
                          bottom: 6,
                        ),
                        child: WebsafeSvg.asset(
                          'assets/svg/uncheck_image.svg',
                          fit: BoxFit.fill,
                          width: 16,
                          height: 16,
                        ),
                      ),
                      sizeWidth4,
                      Expanded(
                        child: Text.rich(
                          TextSpan(children: [
                            TextSpan(text: "请阅读并同意".tr, style: style1),
                            TextSpan(text: "隐私政策".tr, style: style2),
                            TextSpan(text: "、".tr, style: style1),
                            TextSpan(text: "用户协议".tr, style: style2),
                            TextSpan(text: "和".tr, style: style1),
                            TextSpan(text: "服务器公约".tr, style: style2),
                          ]),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
    return Scaffold(
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
          body,
        ],
      ),
      // body: Container(
      //   decoration: const BoxDecoration(
      //     image: DecorationImage(
      //       fit: BoxFit.fill,
      //       image: AssetImage('assets/images/login_page_bg.png'),
      //
      //     ),
      //   ),
      //   child: body,
      // ),
    );
  }
}
