import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:im/utils/universal_platform.dart';
import 'package:oktoast/oktoast.dart';

import 'jverify_util.dart';
import 'login_page.dart';

typedef ThirdLoginAction = Future<void> Function(BuildContext context);

class ThirdLogin extends StatelessWidget {
  final bool isChecked;

  const ThirdLogin({Key key, this.isChecked = false}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: isShowWeChatLogin(), //异步加载方法
      builder: (context, snapshot) {
        ///微信登录开启
        if (snapshot.hasData && (snapshot.data as bool)) {
          return Column(
            children: [
              thirdLoginTitle(),
              const SizedBox(height: 20),
              thirdLogin(context, true),
            ],
          );
        } else {
          ///微信登录关闭
          if (UniversalPlatform.isIOS || UniversalPlatform.isMacOS) {
            return Column(
              children: [
                if (isShowAppleLogin()) thirdLoginTitle(),
                const SizedBox(height: 20),
                thirdLogin(context, false),
              ],
            );
          }
        }
        return const SizedBox();
      },
    );
  }

  Widget thirdLoginTitle() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset('assets/images/other_line.png'),
        const SizedBox(width: 8),
        Text(
          '其它方式登录'.tr,
          style: const TextStyle(fontSize: 13, color: Color(0xFF8F959E)),
        ),
        const SizedBox(width: 8),
        Image.asset('assets/images/other_line.png'),
      ],
    );
  }

  Widget thirdLogin(BuildContext context, bool hasWx) {
    return SizedBox(
      width: 120,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          if ((UniversalPlatform.isIOS || UniversalPlatform.isMacOS) &&
              isShowAppleLogin())
            appleLogin(context),
          if (hasWx) wxLogin(context),
        ],
      ),
    );
  }

  Widget appleLogin(BuildContext context) {
    return _thirdLoginWidget(
      context: context,
      action: (context) => JVerifyUtil.loginWithApple(context, isChecked: true),
      child: Image.asset('assets/images/btn_apple.png', width: 48, height: 48),
    );
  }

  Widget wxLogin(BuildContext context) {
    return _thirdLoginWidget(
      context: context,
      action: (context) => JVerifyUtil.loginWithWx(isChecked: true),
      child: Image.asset('assets/images/btn_wechat.png', width: 48, height: 48),
    );
  }

  Widget _thirdLoginWidget({
    BuildContext context,
    ThirdLoginAction action,
    Widget child,
  }) {
    return GestureDetector(
      onTap: () {
        if (!isChecked) {
          showToast("阅读并同意隐私政策、用户协议和服务器公约才能登录".tr, radius: 8);
        } else {
          action(context);
        }
      },
      child: child,
    );
  }
}
