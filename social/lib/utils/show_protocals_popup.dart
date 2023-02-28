import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:im/api/api.dart';
import 'package:im/common/extension/uri_extension.dart';
import 'package:im/core/config.dart';
import 'package:im/routes.dart';
import 'package:im/services/sp_service.dart';
import 'package:im/themes/custom_color.dart';
import 'package:im/utils/utils.dart';
import 'package:sliding_sheet/sliding_sheet.dart';

Future<bool> showProtocalsPopup(BuildContext context) async {
  final theme = Theme.of(context);
  final textColor = theme.textTheme.bodyText2.color;
  final textStyle1 =
      theme.textTheme.bodyText1.copyWith(fontSize: 15, height: 1.53);
  final textStyle2 =
      TextStyle(fontSize: 14, color: theme.primaryColor, height: 1.53);
  final primaryColor = theme.primaryColor;
  return showSlidingBottomSheet<bool>(
    context,
    resizeToAvoidBottomInset: false,
    builder: (context) {
      return SlidingSheetDialog(
        isDismissable: false,
        dismissOnBackdropTap: false,
        axisAlignment: 1,
        color: CustomColor(context).backgroundColor7,
        extendBody: true,
        elevation: 8,
        cornerRadius: 10,
        padding: EdgeInsets.zero,
        duration: const Duration(milliseconds: 300),
        scrollSpec: const ScrollSpec(physics: NeverScrollableScrollPhysics()),
        avoidStatusBar: true,
        snapSpec: SnapSpec(
          snappings: const [0.9],
          onSnap: (state, snap) {},
        ),
        builder: (_, state) {
          return Material(
            child: Column(
              children: [
                Center(
                  child: Container(
                    width: MediaQuery.of(context).size.width,
                    // height: 354,
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
                                fontSize: 18,
                                fontWeight: FontWeight.bold),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 26.5),
                          child: Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                    text:
                                        "${"欢迎您选择由深圳市创梦天地科技有限公司（以下简称“我们”）为您提供的网络服务，".tr}${"我们非常重视您的个人信息保护并充分尊重您的用户权利。在您使用我们的服务前，请您务必审慎阅读".tr}",
                                    style: textStyle1),
                                TextSpan(
                                    text: "《创梦天地个人信息保护政策》".tr,
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
                                    style: textStyle2),
                                TextSpan(text: "、".tr, style: textStyle1),
                                TextSpan(
                                    text: "《Fanbook软件许可及用户协议》".tr,
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
                                    style: textStyle2),
                                TextSpan(text: "和".tr, style: textStyle1),
                                TextSpan(
                                    text: "《Fanbook服务器公约》".tr,
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
                                    style: textStyle2),
                                TextSpan(
                                    text:
                                        '的全部内容，如您同意以上协议内容，请点击“同意并继续”，开始使用我们的服务。'
                                            .tr,
                                    style: textStyle1),
                              ],
                            ),
                          ),
                        ),
                        // ignore: sized_box_for_whitespace
                        const SizedBox(height: 24),
                        SizedBox(
                          height: 40,
                          child: Row(
                            children: <Widget>[
                              const SizedBox(width: 32),
                              Expanded(
                                child: GestureDetector(
                                  behavior: HitTestBehavior.translucent,
                                  onTap: () {
                                    Navigator.of(context).pop(false);
                                  },
                                  child: Container(
                                    alignment: Alignment.center,
                                    decoration: const BoxDecoration(
                                      borderRadius: BorderRadius.all(
                                        Radius.circular(3),
                                      ),
                                      color: Color(0xFFF5F5F8),
                                    ),
                                    child: Text(
                                      "不同意".tr,
                                      style: TextStyle(
                                        color: primaryColor,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: GestureDetector(
                                  behavior: HitTestBehavior.translucent,
                                  onTap: () {
                                    SpService.to
                                        .setBool(SP.agreedProtocals, true);
                                    Navigator.of(context).pop(true);
                                  },
                                  child: Container(
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                        borderRadius: const BorderRadius.all(
                                            Radius.circular(3)),
                                        color: primaryColor),
                                    child: Text(
                                      "同意并继续".tr,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 32),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
                Container(
                  color: theme.backgroundColor,
                  height: getBottomViewInset(),
                )
              ],
            ),
          );
        },
      );
    },
  );
}
