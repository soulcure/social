import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:im/icon_font.dart';
import 'package:im/themes/const.dart';
import 'package:im/utils/orientation_util.dart';
import 'package:im/utils/universal_platform.dart';
import 'package:im/widgets/text_field/native_input.dart';
import 'package:websafe_svg/websafe_svg.dart';

import '../controllers/send_code_controller.dart';

class SendCodeView extends GetView<SendCodeController> {
  final TextEditingController _captchaController = TextEditingController();

  //限制长度
  final int limitLength = 6;

  @override
  Widget build(BuildContext context) {
    final isWeb = !OrientationUtil.portrait;

    final subtitle = Get.textTheme.bodyText1
        .copyWith(height: 1.21, fontSize: isWeb ? 12 : 14);

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
                      color: Get.textTheme.bodyText2.color,
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
                        color: Get.textTheme.bodyText1.color,
                      ),
                      Text('返回'.tr, style: Get.textTheme.bodyText1)
                    ],
                  ),
                ),
              ),
            SizedBox(height: isWeb ? 18 : 48),
            Text(
              '验证手机号'.tr,
              style: const TextStyle(
                fontSize: 24,
                height: 1.16,
                fontWeight: FontWeight.w600,
              ),
            ),
            sizeHeight12,
            Text.rich(
              TextSpan(
                text: '验证码已发送至 +%s %s '.trArgs([
                  controller.country.toString(),
                  controller.mobile.toString()
                ]),
                style: subtitle,
              ),
            ),
            SizedBox(
              height: isWeb ? 64 : 32,
            ),
            Container(
              height: 48,
              decoration: BoxDecoration(
                // color: Get.theme.scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0x408F959E)),
              ),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: NativeInput(
                      keyboardType: TextInputType.phone,
                      controller: _captchaController,
                      focusNode: controller.node,
                      autofocus: true,
                      // style: Get.textTheme.bodyText1,
                      inputFormatters: <TextInputFormatter>[
                        LengthLimitingTextInputFormatter(limitLength)
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
                      onChanged: (value) {
                        if (value.trim().length != limitLength) {
                          return;
                        }
                        controller.node.unfocus();
                        controller.codeRequestQueue.subject.add(value);
                      },
                      onEditingComplete: () {
                        if (UniversalPlatform.isIOS) controller.node.unfocus();
                      },
                    ),
                  ),
                  Obx(() => Padding(
                        padding: const EdgeInsets.only(right: 16),
                        child: controller.enableSend.value
                            ? GestureDetector(
                                onTap: controller.sendCode,
                                behavior: HitTestBehavior.translucent,
                                child: Text(
                                  '重新发送'.tr,
                                  style:
                                      TextStyle(color: Get.theme.primaryColor),
                                ),
                              )
                            : Text('${controller.count.value} s',
                                style: Get.textTheme.bodyText1),
                      ))
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
            backgroundColor: Get.theme.backgroundColor,
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
            backgroundColor: Get.theme.scaffoldBackgroundColor,
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
}
