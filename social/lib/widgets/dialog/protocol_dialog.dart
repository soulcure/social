import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/api/api.dart';
import 'package:im/services/sp_service.dart';
import 'package:im/utils/orientation_util.dart';

import '../../routes.dart';

class ProtocolDialog extends StatelessWidget {
  const ProtocolDialog();

  /// 检查Android的通知权限是否打开，没有则提示
  /// 返回值代表用户是否同意
  static Future<bool> show(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (ctx) => const ProtocolDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWeb = !OrientationUtil.portrait;
    final theme = Theme.of(context);
    final textColor = theme.textTheme.bodyText2.color;
    // final bgColor = theme.scaffoldBackgroundColor;
    final btnTextColor = theme.primaryColor;
    final textStyle1 = theme.textTheme.bodyText1
        .copyWith(fontSize: isWeb ? 12 : 15, height: 1.3);
    final textStyle2 = TextStyle(
        fontSize: isWeb ? 12 : 14, color: theme.primaryColor, height: 1.3);

    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: Container(
            width: 280,
            height: 346,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: Colors.white,
            ),
            padding: const EdgeInsets.fromLTRB(0, 16, 0, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  alignment: Alignment.center,
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Text(
                    '隐私政策、用户协议和服务器公约'.tr,
                    style: TextStyle(
                        color: textColor,
                        fontSize: 17,
                        fontWeight: FontWeight.bold),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                      child: Text.rich(TextSpan(children: [
                        TextSpan(
                            text: "欢迎您选择由深圳市创梦天地科技有限公司（以下简称“我们”）为您提供的网络服务，".tr +
                                "我们非常重视您的个人信息保护并充分尊重您的用户权利。在您使用我们的服务前，请您务必审慎阅读"
                                    .tr,
                            style: textStyle1),
                        TextSpan(
                            text: "《创梦天地个人信息保护政策》".tr,
                            recognizer: TapGestureRecognizer()
                              ..onTap = () => Routes.pushHtmlPage(context,
                                  'https://${ApiUrl.privacyUrl}?udx=93${DateTime.now().millisecondsSinceEpoch}3d4',
                                  title: '隐私政策'.tr),
                            style: textStyle2),
                        TextSpan(text: "、".tr, style: textStyle1),
                        TextSpan(
                            text: "《Fanbook软件许可及用户协议》".tr,
                            recognizer: TapGestureRecognizer()
                              ..onTap = () => Routes.pushHtmlPage(context,
                                  'https://${ApiUrl.termsUrl}?udx=93${DateTime.now().millisecondsSinceEpoch}3c4',
                                  title: '用户协议'.tr),
                            style: textStyle2),
                        TextSpan(text: "和".tr, style: textStyle1),
                        TextSpan(
                            text: "《Fanbook服务器公约》".tr,
                            recognizer: TapGestureRecognizer()
                              ..onTap = () => Routes.pushHtmlPage(context,
                                  'https://${ApiUrl.conventionUrl}?udx=93${DateTime.now().millisecondsSinceEpoch}3d4',
                                  title: '服务器公约'.tr),
                            style: textStyle2),
                        TextSpan(
                            text: "的全部内容，同意并接受全部条款后方可开始使用我们的服务。".tr,
                            style: textStyle1),
                      ]))),
                ),
                const SizedBox(height: 10),
                const Divider(thickness: 0.5, color: Color(0xcccccccc)),
                // ignore: sized_box_for_whitespace
                Container(
                  height: 50,
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: GestureDetector(
                          behavior: HitTestBehavior.translucent,
                          onTap: () {
                            Navigator.of(context).pop(false);
                          },
                          child: Container(
                            alignment: Alignment.center,
                            child: Text(
                              "不同意".tr,
                              style: TextStyle(color: textColor, fontSize: 16),
                            ),
                          ),
                        ),
                      ),
                      const VerticalDivider(
                          thickness: 0.5, color: Color(0xcccccccc)),
                      Expanded(
                        child: GestureDetector(
                          behavior: HitTestBehavior.translucent,
                          onTap: () {
                            // SpService.to.setBool(SP.checkProtocol, true);
                            SpService.to.setBool(SP.agreedProtocals, true);
                            Navigator.of(context).pop(true);
                          },
                          child: Container(
                            alignment: Alignment.center,
                            child: Text(
                              "同意并继续".tr,
                              style: TextStyle(
                                  color: btnTextColor,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
