import 'package:in_app_purchase/src/channel.dart';

class SKReceiptManager {
  /// 获取票据信息
  /// 通过调用 [[NSBundle mainBundle] appStoreReceiptURL]获取凭证
  static Future<String?> retrieveReceiptData() {
    return channel.invokeMethod<String>(
        '-[InAppPurchasePlugin retrieveReceiptData:result:]');
  }
}
