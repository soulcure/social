import 'package:flutter/foundation.dart';
import 'package:im/core/http_middleware/http.dart';

enum PayType {
  /// 杉德
  SanDe,

  /// 苹果
  Apple,
}

class PayApi {
  /// 创建订单接口
  /// productType 1 : 虚疑商品 2: 实物
  static Future createOrder(
      {String thirdOrderNo,
      String payServiceOrder,
      String appId,
      String platform = 'ios',
      String userId,
      String totalPrice,
      String productType = '1',
      String quantity = '1',
      @required String price,
      PayType payType = PayType.Apple,
      String extraInfo,
      String currency = 'CNY',
      @required String productId,
      @required String productName}) async {
    try {
      /// 支付方式
      String payMethod = 'apple_pay';
      if (payType == PayType.SanDe) {
        payMethod = 'sand_pay';
      }
      final res = await Http.request('/api/payment/create', data: {
        'third_order_no': thirdOrderNo,
        "pay_service_order": payServiceOrder,
        "app_id": appId,
        "platform": platform,
        "user_id": userId,
        "total_price": totalPrice,
        "product_type": productType,
        "quantity": quantity,
        "price": price,
        "pay_method": payMethod,
        "extra_info": payServiceOrder,
        "currency": currency,
        "product_id": productId,
        "product_name": productName,
      });
      return res;
    } catch (e) {
      return Future.value();
    }
  }

  /// 苹果票据校验
  static Future appleReceipt(
      {@required String orderNo, // 订单号
      @required String receipt // 苹果base64票据
      }) async {
    final res = await Http.request(
      '/api/payment/appleReceipt',
      data: {
        'order_no': orderNo,
        "receipt": receipt,
      },
      isOriginDataReturn: true,
    );
    return res;
  }
}
