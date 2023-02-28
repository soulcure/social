import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/app/modules/send_code/controllers/send_code_param.dart';
import 'package:im/widgets/circular_progress.dart';
import 'package:im/widgets/toast.dart';
import 'package:im/api/user_api.dart';
import 'package:im/utils/utils.dart';
import 'package:pedantic/pedantic.dart';

class SendCodeController extends GetxController {
  Worker worker;
  Rx<String> codeRequestQueue = Rx<String>(null);
  Timer _countTimer;

  Rx<bool> enableSend = false.obs;
  Rx<bool> sendLoading = false.obs;
  FocusNode node;
  Rx<int> count = 60.obs;

  String country;
  String mobile;
  CodeType _codeType;
  CodeCallBack _codeCallBack;
  bool isProcess = false;

  @override
  void onInit() {
    super.onInit();
    node = FocusNode();
    node.requestFocus();

    final SendCodeParam param = Get.arguments;
    if (param != null) {
      mobile = param.mobile;
      country = param.country;
      _codeCallBack = param.onCheckCode;
      _codeType = param.codeType;
    }

    // 500毫秒以内只执行一次
    worker = debounce<String>(codeRequestQueue, _doRequest,
        time: const Duration(milliseconds: 500));
  }

  @override
  void onReady() {
    super.onReady();

    /// 开始计数
    startCount();

    /// 发送验证码
    sendCode();
  }

  @override
  void onClose() {
    worker.dispose();

    _countTimer?.cancel();
    node?.dispose();

    super.onClose();
  }

  void startCount() {
    count.value = 60;
    _countTimer?.cancel();
    _countTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      count.value--;
      if (count.value == 0) {
        enableSend.value = true;
        _countTimer.cancel();
      }
    });
  }

  void sendCode() {
    if (sendLoading.value) return;
    sendLoading.value = true;

    /// 新增短信验证类别
    UserApi.sendCaptcha(int.parse(mobile), getPlatform(), country,
            codeType: _codeType.value)
        .then((res) {
      Toast.iconToast(icon: ToastIcon.success, label: '验证码已发送'.tr);
      startCount();
      enableSend.value = false;
      sendLoading.value = false;
    }).catchError((e) {
      sendLoading.value = false;
    });
  }

  Future<void> _doRequest(String code) async {
    if (isProcess) return;
    isProcess = true;

    unawaited(Get.dialog(
      UnconstrainedBox(
        child: Container(
          width: 128,
          height: 128,
          decoration: BoxDecoration(
              color: Colors.black54, borderRadius: BorderRadius.circular(10)),
          child: Center(
            child: CircularProgress(
              primaryColor: Colors.white,
              secondaryColor: Colors.white.withOpacity(0),
              strokeWidth: 3,
              size: 33,
            ),
          ),
        ),
      ),
      barrierDismissible: false,
    ));

    final result = await _codeCallBack(code);
    Get.back();

    /// 验证码验证失败，停留在该页面继续等待用户输入
    if (result != null &&
        ((result is bool && result) ||
            (result is String && result.isNotEmpty))) {
      Get.back(result: result);
    }

    isProcess = false;
  }
}
