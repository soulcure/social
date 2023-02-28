import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:im/api/pay_api.dart';
import 'package:im/core/config.dart';
import 'package:im/global.dart';
import 'package:im/pay/iap/iap_helper.dart';
import 'package:im/utils/universal_platform.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

/// 成功
typedef OnSuccess = void Function(String productId);

/// 失败
typedef OnError = void Function(String code, String message);

class PayManager {
  /// 防止多次点击计时器
  static Timer _debounce;

  /// n秒内， 不允许发起订单,用来记录状态
  static bool isFrequentlyBuyState = false;

  static Future<void> pay(
      {String thirdOrderNo,
      String payServiceOrder,
      String appId,
      String totalPrice,
      String productType = '1',
      String quantity = '1',
      @required String price,
      PayType payType = PayType.Apple,
      String extraInfo,
      String currency = 'CNY',
      @required String productId,
      @required String productName,
      OnSuccess onSuccess,
      OnError onError}) async {
    //  频繁操作时， 不处理
    if (isFrequentlyBuyState == true) {
      onError("-1", "operation too frequently");
      return;
    }

    ///  记录购买状态， 开启频繁操作逻辑
    isFrequentlyBuyState = true;

    /// 防止重复点击
    _debounce = Timer(const Duration(seconds: 2), () {
      isFrequentlyBuyState = false;
      _debounce.cancel();
    });

    /// 平台参数
    String payPlatform = 'android';
    if (UniversalPlatform.isIOS) {
      payPlatform = 'ios';
    }

    /// 获取当前用户id
    final userId = Global.user.id;

    try {
      // 创建订单
      final res = await PayApi.createOrder(
          thirdOrderNo: thirdOrderNo,
          payServiceOrder: payServiceOrder,
          appId: appId,
          platform: payPlatform,
          userId: userId,
          totalPrice: price,
          productType: productType,
          quantity: quantity,
          payType: payType,
          extraInfo: extraInfo,
          currency: currency,
          productId: productId,
          productName: productName,
          price: price);

      // 服务端返回的订单号
      final orderId = res['order_no'];

      if (UniversalPlatform.isIOS) {
        await IAPHelper.instance.pay(
            productId: productId,
            orderId: orderId,
            onSuccess: onSuccess,
            onError: onError);
      } else if (UniversalPlatform.isAndroid) {
        /// android 支付
        final params = <String, String>{};
        params['mer_order_no'] = orderId; // 商户订单号
        params['create_time'] =
            res['create_time']; // 订单创建时间 yyyyMMddHHmmss 20180813142345
        params['expire_time'] = res['expire_time']; // 订单失效时间 yyyyMMddHHmmss
        params['order_amt'] = price; // 订单金额（单位:元，1分=0.01元）
        params['notify_url'] =
            '${Config.host}/openApi/payment/sandcallback'; // 回调地址
        params['goods_name'] = productName; // 商品名称
        //微信小程序 02010005,  支付宝生活号 02020004
        params['product_code'] = '02020004,02010005'; // 支付产品编码
        await platform.invokeMethod('startAndroidPay', {
          'payParams': params,
        });
        print('pay --> 提前支付回调');
        onSuccess(productId);
      }
    } catch (e) {
      print(e);
      onError?.call(
          PayErrorCode.createOrderIdFail.index.toString(), '服务端创建订单失败'.tr);
    }
  }

  /// 开启监听 目前只有iOS需要此方法
  static Future<void> startObservingPaymentQueue() async {
    if (UniversalPlatform.isIOS) {
      await IAPHelper.instance.startObservingPaymentQueue();
    }
  }

  ///移除监听 目前只有iOS需要此方法
  static Future<void> removeObservingPaymentQueue() async {
    if (UniversalPlatform.isIOS) {
      await IAPHelper.instance.removeObservingPaymentQueue();
    }
  }
}
