import 'dart:convert' show json;

import 'package:fb_ali_pay/fb_ali_pay.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:im/api/redpack_api.dart';
import 'package:im/app/modules/send_code/controllers/send_code_controller.dart';
import 'package:im/app/modules/send_code/controllers/send_code_param.dart';
import 'package:im/app/routes/app_pages.dart';
import 'package:im/global.dart';
import 'package:im/loggers.dart';
import 'package:im/pages/login/model/country_model.dart';
import 'package:im/services/server_side_configuration.dart';
import 'package:im/services/sp_service.dart';
import 'package:im/widgets/red_packet_popup.dart';
import 'package:im/widgets/toast.dart';
import 'package:oktoast/oktoast.dart';
import 'package:url_launcher/url_launcher.dart';

import '../widgets/bound_dialog.dart';

class BindPaymentController extends GetxController {
  final alipayNickname = ''.obs;
  final isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();

    isLoading.value = true;
  }

  @override
  void onReady() {
    super.onReady();

    /// 查询当前账户是否已绑定
    _fetchAlipayInfo().then((value) async {
      /// 如果检测结果为空，代表未绑定
      if (alipayNickname.value == null) {
        /// 第一次进入，并且未直接跳转到发送验证码界面，则弹出“点亮红包”页面一次
        bool isFirsPopRedPacket = true;
        if (SpService.to.containsKey(SP.isFirsPopRedPacket)) {
          isFirsPopRedPacket = SpService.to.getBool(SP.isFirsPopRedPacket);
        }
        if (isFirsPopRedPacket) {
          await SpService.to.setBool(SP.isFirsPopRedPacket, false);
          await showRedPacketPopup(Get.context, onAgree: () {
            /// 同意，进入发送验证码准备绑定
            Get.back();
            bindAliPay();
          });
        }
      }
    }).onError((error, stackTrace) {
      isLoading.value = false;
    });
  }

  Future<void> _fetchAlipayInfo() async {
    /// 查询当前账户是否已绑定
    alipayNickname.value = await RedPackAPI.getBindAlipayInfo();
    isLoading.value = false;
  }

  @override
  void onClose() {
    super.onClose();
  }

  /// 绑定支付宝
  Future<void> bindAliPay() async {
    final isAliPayInstalled = await FbAliPay.isInstalledAliPay();
    if (!isAliPayInstalled) {
      /// 未安装支付宝跳转到支付宝官网
      await launch('https://ds.alipay.com/');
      return;
    }

    /// 获取当前用户手机号与区号
    await _sendCode(CodeType.bindAlipay);
  }

  /// 解绑支付宝
  Future<void> unbindAlipay() async {
    /// 获取当前用户手机号与区号
    await _sendCode(CodeType.unbindAlipay);
  }

  Future _sendCode(CodeType codeType) async {
    /// 获取当前用户手机号与区号
    final String mobile = Global.user.mobile;
    CountryModel country;
    final countryString = SpService.to.getString(SP.country);
    if (countryString != null && countryString.isNotEmpty) {
      final map = json.decode(countryString);
      country = CountryModel.fromMap(map);
    }

    final SendCodeParam param = SendCodeParam(
        codeType: codeType,
        onCheckCode: codeType == CodeType.bindAlipay
            ? _processBindCode
            : _processUnbindCode,
        country: (country ?? (CountryModel.defaultModel)).phoneCode,
        mobile: mobile);

    final result = await Get.toNamed(
      Routes.SEND_CODE,
      arguments: param,
    );

    if (codeType == CodeType.bindAlipay) {
      await _bindAlipayDone(result);
    } else {
      await _unbindAlipayDone(result);
    }

    Future.delayed(const Duration(milliseconds: 500), () {
      /// FIXME: 2022/1/19 防止外部调用导致SendCode页面未作Close操作，后期需要彻查改问题并修改
      if (Get.isRegistered<SendCodeController>()) {
        Get.delete<SendCodeController>();
      }
    });
  }

  /// 处理绑定验证码是否合法
  Future<String> _processBindCode(String code) async {
    final ResData res = await RedPackAPI.getAlipayAuthInfo(code);
    String result;
    switch (res.type) {
      case SendCodeType.success:
        result = res.data;
        break;
      case SendCodeType.fail:
      case SendCodeType.serverFail:
        showToast((res.type as SendCodeType).value);
        break;
      default:
    }
    return Future.value(result);
  }

  /// 处理解绑验证码
  Future<bool> _processUnbindCode(String code) async {
    /// 获取绑定前info，如果成功代表验证码OK
    try {
      final uid = await RedPackAPI.unbindAlipay(code);
      if (uid != null) {
        ServerSideConfiguration.to.aliPayUid = null;
        return Future.value(true);
      } else {
        return Future.value(false);
      }
    } catch (e, s) {
      logger.warning('RedPackAPI.unbindAlipay', e, s);
    }

    return Future.value(false);
  }

  Future<void> _bindAlipayDone(serviceCode) async {
    /// 获取到服务码进行绑定操作
    if (serviceCode != null &&
        (serviceCode is String && serviceCode.isNotEmpty)) {
      /// 调起支付宝绑定
      final authCode = await FbAliPay.aliPayAuth(serviceCode).catchError((e) {
        logger.info('获取支付宝授权码失败', e);
      });

      /// 调用API服务器关联绑定
      if (authCode.isNotEmpty) {
        /// 第一次绑定，弹窗提醒
        ResData res = await RedPackAPI.bindUid(authCode, true);

        /// NOTE: 2022/1/10 换绑操作必须放置在第一个判断
        if (res.type == BindType.bound) {
          /// 弹窗确认后再调用
          final bool isReplace =
              await _showDialog(Global.user.nickname, res.data);
          if (isReplace) {
            /// 第二次绑定
            res = await RedPackAPI.bindUid(authCode, false);
          } else {
            return;
          }
        }

        switch (res.type) {
          case BindType.success:
            Toast.iconToast(
                icon: ToastIcon.success,
                label: (res.type as BindType).value.tr);
            await _refresh();
            break;
          case BindType.repeat:
          case BindType.bound:
          case BindType.fail:
          case BindType.serverFail:
            showToast(BindType.repeat.value);
            break;
          default:
        }
      } else {
        showToast('授权失败，请重试'.tr);
      }
    }
  }

  Future<void> _unbindAlipayDone(result) async {
    /// 验证成功，需要处理
    if (result != null && (result is bool && result)) {
      Toast.iconToast(icon: ToastIcon.success, label: "解绑成功".tr);

      /// 刷新界面
      await _refresh();
    }
  }

  /// 显示换绑弹窗
  Future<bool> _showDialog(String nickname, String thirdNickname) async {
    return Get.dialog<bool>(
      UnconstrainedBox(
        child: BoundDialog(nickname: nickname, thirdNickname: thirdNickname),
      ),
      barrierDismissible: false,
    );
  }

  Future _refresh() async {
    /// 刷新界面
    isLoading.value = true;
    await _fetchAlipayInfo().then((_) {
      isLoading.value = false;
    });
  }
}
