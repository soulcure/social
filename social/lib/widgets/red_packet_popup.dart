import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/api/api.dart';
import 'package:im/app/modules/bind_payment/controllers/bind_payment_controller.dart';
import 'package:im/core/widgets/button/fade_button.dart';
import 'package:im/icon_font.dart';
import 'package:im/routes.dart';
import 'package:im/themes/const.dart';
import 'package:im/themes/custom_color.dart';
import 'package:im/utils/orientation_util.dart';
import 'package:im/utils/show_bottom_modal.dart';

/// 点亮红包功能弹窗
Future<T> showRedPacketPopup<T>(BuildContext context,
    {VoidCallback onAgree, VoidCallback onDisagree}) async {
  if (OrientationUtil.portrait) {
    return showBottomModal<T>(
      context,
      resizeToAvoidBottomInset: false,
      backgroundColor: CustomColor(context).backgroundColor6,
      builder: (context, _) =>
          RedPacketPopup(onAgree: onAgree, onDisagree: onDisagree),
    );
  } else {
    /// TODO: 2022/1/10 横屏待实现
    return null;
  }
}

class RedPacketPopup extends StatelessWidget {
  final VoidCallback onDisagree;
  final VoidCallback onAgree;

  const RedPacketPopup({this.onAgree, this.onDisagree, Key key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    const titleStyle = TextStyle(
        color: Color(0xFF1F2126), fontSize: 20, fontWeight: FontWeight.w500);
    const textStyle1 = TextStyle(color: Color(0xFF8D93A6), fontSize: 16);

    const textStyle2 =
        TextStyle(fontSize: 13, color: Color(0xFF198CFE), height: 1.5);

    const btHeight = 44.0;
    const btWidth = 147.5;
    const radius = 6.0;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32),
      alignment: Alignment.topCenter,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            IconFont.buffRedPacket,
            color: Color(0xFFF35D4C),
            size: 48,
          ),
          Padding(
            padding: const EdgeInsets.only(top: 24),
            child: Text('点亮红包功能'.tr, style: titleStyle),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              '使用红包功能需要绑定支付宝帐号'.tr,
              style: textStyle1,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 44),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                FadeButton(
                  height: btHeight,
                  width: btWidth,
                  onTap: onDisagree ?? Get.back,
                  decoration: BoxDecoration(
                    color: const Color(0x1A8D93A6),
                    borderRadius: BorderRadius.circular(radius),
                  ),
                  child: Text(
                    '取消'.tr,
                    style:
                        const TextStyle(color: Color(0xFF1F2126), fontSize: 16),
                  ),
                ),
                sizeWidth16,
                FadeButton(
                  height: btHeight,
                  width: btWidth,
                  onTap: onAgree ??
                      () {
                        Get.back();

                        /// 同意，通过绑定页面进入发送验证码界面
                        final bindPaymentController =
                            Get.put<BindPaymentController>(
                                BindPaymentController());

                        bindPaymentController.bindAliPay().then((value) {
                          Get.delete<BindPaymentController>();
                        });
                      },
                  decoration: BoxDecoration(
                    color: const Color(0xFF198CFE),
                    borderRadius: BorderRadius.circular(radius),
                  ),
                  child: Text(
                    '去绑定'.tr,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 24),
            child: Text.rich(
              TextSpan(
                  text: '绑定即代表同意'.tr,
                  style: textStyle1.copyWith(fontSize: 13),
                  children: [
                    TextSpan(
                      text: "《绑定支付宝账号授权协议》".tr,
                      recognizer: TapGestureRecognizer()
                        ..onTap = () => Routes.pushHtmlPage(context,
                            'https://${ApiUrl.payAuthUrl}?udx=93${DateTime.now().millisecondsSinceEpoch}43c',
                            title: '支付宝账号授权协议'.tr),
                      style: textStyle2,
                    )
                  ]),
            ),
          ),
        ],
      ),
    );
  }
}
