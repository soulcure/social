import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/api/api.dart';
import 'package:im/icon_font.dart';
import 'package:im/routes.dart';
import 'package:im/themes/const.dart';
import 'package:im/widgets/app_bar/appbar_builder.dart';
import 'package:im/widgets/circular_progress.dart';
import 'package:im/widgets/link_tile.dart';

import '../controllers/bind_payment_controller.dart';

class BindPaymentView extends GetView<BindPaymentController> {
  @override
  Widget build(BuildContext context) {
    // final statusHeight = Get.mediaQuery.padding.top;

    return Scaffold(
      appBar: FbAppBar.custom('绑定管理'.tr),
      body: Obx(() {
        if (controller.isLoading.value) {
          return _buildLoading(context);
        } else {
          return _buildContent(context);
        }
      }),
    );
  }

  Container _buildContent(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Obx(() {
        return Column(
          children: [
            if (controller.alipayNickname.value != null &&
                controller.alipayNickname.value.isNotEmpty)
              _buildPayInfo(context, controller.alipayNickname.value)
            else
              _buildBindPay(context),
          ],
        );
      }),
    );
  }

  ListView _buildBindPay(BuildContext context) {
    const textStyle =
        TextStyle(fontSize: 16, color: Color(0xFF363940), height: 1.25);
    const textStyle2 =
        TextStyle(fontSize: 14, color: Color(0xFF198CFE), height: 1.53);
    final textStyle1 =
        Get.theme.textTheme.bodyText1.copyWith(fontSize: 15, height: 1.53);

    return ListView(
      shrinkWrap: true,
      children: [
        LinkTile(
          context,
          Text('绑定支付宝账号'.tr, style: textStyle),
          onTap: controller.bindAliPay,
          borderRadius: 8,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Text.rich(
            TextSpan(
              text: '绑定即代表同意'.tr,
              style: textStyle1,
              children: [
                TextSpan(
                  text: "《绑定支付宝账号授权协议》".tr,
                  recognizer: TapGestureRecognizer()
                    ..onTap = () => Routes.pushHtmlPage(context,
                        'https://${ApiUrl.payAuthUrl}?udx=93${DateTime.now().millisecondsSinceEpoch}43c',
                        title: '支付宝账号授权协议'.tr),
                  style: textStyle2,
                  children: [
                    TextSpan(
                      text: "，绑定后将使用此支付宝账号收发红包。".tr,
                      style: textStyle1,
                    )
                  ],
                ),
              ],
            ),
          ),
        )
      ],
    );
  }

  Widget _buildPayInfo(BuildContext context, String nickname) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      IconFont.buffAlipay,
                      color: Color(0xFF027AFF),
                      size: 20,
                    ),
                    sizeWidth8,
                    Text(
                      nickname,
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1F2126)),
                    ),
                    const Expanded(child: SizedBox()),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 1.5),
                      decoration: const BoxDecoration(
                        color: Color(0x1A198CFE),
                        borderRadius: BorderRadius.all(Radius.circular(4)),
                      ),
                      child: Text(
                        '当前绑定'.tr,
                        style: const TextStyle(
                          color: Color(0xFF198CFE),
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    )
                  ],
                ),
                sizeHeight8,
                Text(
                  '将使用此支付宝账号收发红包。'.tr,
                  style:
                      const TextStyle(color: Color(0xFF8D93A6), fontSize: 14),
                ),
              ],
            ),
          ),
          const Divider(
            height: 2,
            color: Color(0x1A8D93A6),
            indent: 16,
          ),
          LinkTile(
            context,
            Text(
              '解除绑定'.tr,
              style: const TextStyle(color: Color(0xFF1F2126), fontSize: 16),
            ),
            onTap: controller.unbindAlipay,
            borderRadius: 8,
          ),
        ],
      ),
    );
  }

  Widget _buildLoading(BuildContext context) {
    return const Center(
      child: CircularProgress(
        strokeWidth: 2,
        size: 33,
      ),
    );
  }
}
