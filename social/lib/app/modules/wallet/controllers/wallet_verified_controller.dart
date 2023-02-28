import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/api/user_api.dart';
import 'package:im/utils/utils.dart';
import 'package:oktoast/oktoast.dart';

import '../../../../global.dart';

/// 描述：
///
/// author: seven.cheng
/// date: 2022/4/7 11:04

class WalletVerifiedController extends GetxController {
  /// - 更新倒计时
  static const String UPDATE_CAPTCHA = 'update_captcha';

  /// - 更新提交按钮
  static const String UPDATE_SUBMIT_BUTTON = 'update_submit_button';

  /// - 更新身份证输入框
  static const String UPDATE_ID_CARD = 'update_id_card';

  /// - 手机号码输入框
  TextEditingController mobileController;

  /// - 验证码输入框
  TextEditingController captchaController;

  /// - 姓名输入框
  TextEditingController useNameController;

  /// - 身份证输入框
  TextEditingController idCardController;

  /// - 验证码倒计时
  int countdownCount = 60;
  Timer _timer;

  /// - 正在请求验证吗
  bool isGettingCaptcha = false;

  /// - 提交
  bool isSubmitting = false;

  /// - Get: 手机号码
  String get _submitMobileValue => mobileController.text.contains('*')
      ? Global.user.mobile
      : mobileController.text.trim();

  @override
  void onInit() {
    super.onInit();

    // 初始手机号隐藏中间4位
    mobileController = TextEditingController(
        text: Global.user.mobile.replaceRange(3, 7, '****'))
      ..addListener(() {
        update([UPDATE_CAPTCHA]);
        update([UPDATE_SUBMIT_BUTTON]);
      });
    captchaController = TextEditingController(text: '')
      ..addListener(() => update([UPDATE_SUBMIT_BUTTON]));
    useNameController = TextEditingController(text: '')
      ..addListener(() => update([UPDATE_SUBMIT_BUTTON]));
    idCardController = TextEditingController(text: '')
      ..addListener(() {
        update([UPDATE_ID_CARD]);
        update([UPDATE_SUBMIT_BUTTON]);
      });
  }

  @override
  void onClose() {
    super.onClose();
    mobileController?.dispose();
    captchaController?.dispose();
    useNameController?.dispose();
    idCardController?.dispose();
    _timer?.cancel();
  }

  /// - 获取验证码是否可用
  bool isGetCaptchaEnable() =>
      mobileController.text.trim().isNotEmpty &&
      countdownCount == 60 &&
      !isGettingCaptcha;

  /// - 获取验证码
  Future<void> getCaptcha() async {
    try {
      isGettingCaptcha = true;
      update([UPDATE_CAPTCHA]);
      await UserApi.sendCaptcha(
          int.parse(_submitMobileValue), getPlatform(), '86',
          codeType: 'wallet_open');
      isGettingCaptcha = false;
      _countDown();
    } catch (e) {
      print(e);
      isGettingCaptcha = false;
      update([UPDATE_CAPTCHA]);
    }
  }

  /// - 开始倒计时
  void _countDown() {
    _timer = Timer.periodic(const Duration(milliseconds: 1000), (timer) {
      countdownCount--;
      if (countdownCount == 0) {
        countdownCount = 60;
        _timer.cancel();
      }
      update([UPDATE_CAPTCHA]);
    });
  }

  /// - 提交按钮是否可用
  bool isSubmitEnable() =>
      mobileController.text.trim().length == 11 &&
      captchaController.text.trim().length == 6 &&
      useNameController.text.trim().length > 1 &&
      idCardController.text.trim().length == 18;

  /// - 提交
  Future<void> submit() async {
    try {
      isSubmitting = true;
      update([UPDATE_SUBMIT_BUTTON]);
      final isSuccess = await UserApi.walletVerified(
        _submitMobileValue,
        captchaController.text.trim(),
        useNameController.text.trim(),
        idCardController.text.trim(),
      );
      isSubmitting = false;
      update([UPDATE_SUBMIT_BUTTON]);
      //  请求成功返回
      if (isSuccess) {
        showToast('认证成功'.tr);
        Get.back(result: isSuccess);
      }
    } catch (e) {
      print(e);
      isSubmitting = false;
      update([UPDATE_SUBMIT_BUTTON]);
    }
  }
}
