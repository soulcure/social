import 'package:flutter/services.dart';
import 'package:in_app_purchase/src/channel.dart';

import 'sk_product_wrapper.dart';

class SKRequestMaker {
  /// 获取道具信息
  /// 商品唯一标识集合[productIdentifiers]
  Future<SKProductResponseWrapper> startProductRequest(
      List<String> productIdentifiers) async {
    final Map<String, dynamic>? productResponseMap =
        await channel.invokeMapMethod<String, dynamic>(
      '-[InAppPurchasePlugin startProductRequest:result:]',
      productIdentifiers,
    );
    if (productResponseMap == null) {
      throw PlatformException(
        code: 'storeKit_no_response',
        message: 'StoreKit: Failed to get response from platform.',
      );
    }
    return SKProductResponseWrapper.fromJson(productResponseMap);
  }

  /// 刷新票据
  /// receiptProperties 票据属性
  /// receiptProperties 为空时全部刷新
  /// receiptProperties 有指定属性时,根据属性刷新
  Future<void> startRefreshReceiptRequest({Map? receiptProperties}) {
    return channel.invokeMethod<void>(
      '-[InAppPurchasePlugin refreshReceipt:result:]',
      receiptProperties,
    );
  }
}
