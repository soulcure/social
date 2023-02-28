import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:im/app/modules/wallet/controllers/wallet_verified_controller.dart';
import 'package:im/app/theme/app_theme.dart';
import 'package:im/core/widgets/button/fade_button.dart';
import 'package:im/themes/const.dart';
import 'package:im/themes/default_theme.dart';
import 'package:im/utils/utils.dart';
import 'package:im/widgets/app_bar/custom_appbar.dart';
import 'package:im/widgets/button/custom_icon_button.dart';
import 'package:websafe_svg/websafe_svg.dart';

import '../../../../icon_font.dart';

/// 描述：实名认证
///
/// author: seven.cheng
/// date: 2022/4/7 10:36
class WalletVerifiedPage extends StatefulWidget {
  const WalletVerifiedPage({Key key}) : super(key: key);

  @override
  State<WalletVerifiedPage> createState() => _WalletVerifiedPageState();
}

class _WalletVerifiedPageState extends State<WalletVerifiedPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
          _buildBody(),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          CustomAppbar(
            title: '实名认证'.tr,
            backgroundColor: Colors.transparent,
            leadingBuilder: (icon) {
              return Row(children: [
                sizeWidth12,
                CustomIconButton(
                  iconData: IconFont.buffNavBarBackItem,
                  iconColor: Theme.of(context).textTheme.bodyText2.color,
                  onPressed: () {
                    Get.back();
                  },
                ),
                sizeWidth8,
              ]);
            },
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 32),
              child: _buildContent(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return GetBuilder<WalletVerifiedController>(builder: (controller) {
      return SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            sizeHeight44,
            Text(
              '完成实名认证'.tr,
              style: appThemeData.textTheme.headline1.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            sizeHeight12,
            Text(
              '仅限实名认证为年满18周岁的中国大陆用户使用，填写的实名信息需与手机号持有人相符'.tr,
              style: TextStyle(color: Get.theme.disabledColor, fontSize: 13),
            ),
            sizeHeight40,
            _buildMobile(controller),
            sizeHeight6,
            _buildDivider(),
            sizeHeight12,
            _buildCaptcha(controller),
            sizeHeight6,
            _buildDivider(),
            sizeHeight12,
            _buildUserName(controller),
            sizeHeight6,
            _buildDivider(),
            sizeHeight12,
            _buildIdCard(controller),
            sizeHeight6,
            _buildDivider(),
            sizeHeight40,
            _buildSubmitButton(),
          ],
        ),
      );
    });
  }

  Widget _buildDivider() => Divider(
        thickness: 0.5,
        color: Get.theme.dividerTheme.color,
      );

  Widget _buildMobile(WalletVerifiedController controller) {
    return GetBuilder<WalletVerifiedController>(
        id: WalletVerifiedController.UPDATE_CAPTCHA,
        builder: (controller) {
          return Row(
            children: [
              Expanded(
                child: TextField(
                  keyboardType: TextInputType.phone,
                  controller: controller.mobileController,
                  inputFormatters: <TextInputFormatter>[
                    LengthLimitingTextInputFormatter(11),
                    //限制长度
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    border: InputBorder.none,
                    hintText: '输入有效手机号'.tr,
                    hintStyle: const TextStyle(
                      color: Color(0x968F959E),
                      fontSize: 16,
                    ),
                    suffixIcon: IconButton(
                        icon: Icon(
                          isNotNullAndEmpty(
                                  controller.mobileController.text.trim())
                              ? IconFont.buffClose
                              : null,
                          color: Get.theme.disabledColor.withOpacity(0.65),
                          size: 20,
                        ),
                        onPressed: () {
                          WidgetsBinding.instance.addPostFrameCallback(
                              (_) => controller.mobileController.clear());
                        }),
                  ),
                ),
              ),
              _buildGetCaptcha(controller),
            ],
          );
        });
  }

  /// - 获取验证码
  Widget _buildGetCaptcha(WalletVerifiedController controller) {
    return SizedBox(
        width: 95,
        height: 28,
        child: FadeButton(
          onTap: controller.isGetCaptchaEnable() ? controller.getCaptcha : null,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: controller.isGetCaptchaEnable()
                ? Get.theme.primaryColor
                : Get.theme.disabledColor.withOpacity(0.1),
          ),
          child: controller.isGettingCaptcha
              ? DefaultTheme.defaultLoadingIndicator(color: Colors.white)
              : controller.countdownCount == 60
                  ? Text(
                      '获取验证码'.tr,
                      style: TextStyle(
                          fontSize: 14,
                          color: controller.isGetCaptchaEnable()
                              ? Colors.white
                              : Get.theme.disabledColor.withOpacity(0.7)),
                    )
                  : Text(
                      '已发送%s'.trArgs([controller.countdownCount.toString()]),
                      style: TextStyle(
                          fontSize: 14, color: Get.theme.disabledColor),
                    ),
        ));
  }

  /// - 构建验证码输入框
  Widget _buildCaptcha(WalletVerifiedController controller) {
    return TextField(
      keyboardType: TextInputType.number,
      controller: controller.captchaController,
      inputFormatters: <TextInputFormatter>[
        LengthLimitingTextInputFormatter(6),
        FilteringTextInputFormatter.digitsOnly,
      ],
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        border: InputBorder.none,
        hintText: '输入6位验证码'.tr,
        hintStyle: const TextStyle(
          color: Color(0x968F959E),
          fontSize: 16,
        ),
      ),
    );
  }

  /// - 构建真实姓名输入框
  Widget _buildUserName(WalletVerifiedController controller) {
    return TextField(
      keyboardType: TextInputType.name,
      controller: controller.useNameController,
      inputFormatters: <TextInputFormatter>[
        LengthLimitingTextInputFormatter(20),
      ],
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        border: InputBorder.none,
        hintText: '输入真实姓名'.tr,
        hintStyle: const TextStyle(
          color: Color(0x968F959E),
          fontSize: 16,
        ),
      ),
    );
  }

  /// - 构建身份证输入框
  Widget _buildIdCard(WalletVerifiedController controller) {
    return GetBuilder<WalletVerifiedController>(
        id: WalletVerifiedController.UPDATE_ID_CARD,
        builder: (controller) {
          return TextField(
            keyboardType: TextInputType.text,
            controller: controller.idCardController,
            inputFormatters: <TextInputFormatter>[
              LengthLimitingTextInputFormatter(18),
            ],
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
              border: InputBorder.none,
              hintText: '输入身份证号'.tr,
              hintStyle: const TextStyle(
                color: Color(0x968F959E),
                fontSize: 16,
              ),
              suffixIcon: IconButton(
                  icon: Icon(
                    isNotNullAndEmpty(controller.idCardController.text.trim())
                        ? IconFont.buffClose
                        : null,
                    color: Get.theme.disabledColor.withOpacity(0.65),
                    size: 20,
                  ),
                  onPressed: () {
                    WidgetsBinding.instance.addPostFrameCallback(
                        (_) => controller.idCardController.clear());
                  }),
            ),
          );
        });
  }

  /// - 提交按钮
  Widget _buildSubmitButton() {
    return GetBuilder<WalletVerifiedController>(
        id: WalletVerifiedController.UPDATE_SUBMIT_BUTTON,
        builder: (controller) {
          return SizedBox(
              width: double.infinity,
              height: 48,
              child: FadeButton(
                onTap: controller.isSubmitEnable() && !controller.isSubmitting
                    ? controller.submit
                    : null,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  color: controller.isSubmitEnable()
                      ? Theme.of(context).primaryColor
                      : Theme.of(context).primaryColor.withOpacity(0.4),
                ),
                child: controller.isSubmitting
                    ? DefaultTheme.defaultLoadingIndicator(color: Colors.white)
                    : Text(
                        '实名认证'.tr,
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            color: controller.isSubmitEnable()
                                ? Colors.white
                                : Colors.white.withOpacity(0.5)),
                      ),
              ));
        });
  }
}
