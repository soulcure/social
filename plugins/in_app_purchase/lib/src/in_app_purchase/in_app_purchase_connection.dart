import 'app_store_connection.dart';
import 'product_details.dart';
import 'purchase_details.dart';

abstract class InAppPurchaseConnection {
  Stream<List<PurchaseDetails>>? get purchaseUpdatedStream => _getStream();

  /// 购买商品信息流
  Stream<List<PurchaseDetails>>? _purchaseUpdatedStream;

  Stream<List<PurchaseDetails>>? _getStream() {
    if (_purchaseUpdatedStream != null) {
      return _purchaseUpdatedStream;
    }

    _purchaseUpdatedStream = AppStoreConnection.instance!.purchaseUpdatedStream;

    return _purchaseUpdatedStream;
  }

  /// 支付是否可用
  Future<bool?> isAvailable();

  /// 查询道具信息
  Future<ProductDetailsResponse> queryProductDetails(Set<String> identifiers);

  /// 支付 / 购买
  Future<bool> pay({required PurchaseParam purchaseParam});

  /// 完成购买流程 (调用苹果的 finishTransaction)
  Future<void> completePurchase(PurchaseDetails purchaseDetail);

  /// 开启监听
  Future<void> startObservingPaymentQueue();

  ///移除监听
  Future<void> removeObservingPaymentQueue();


  /// 查询购买过的商品信息
  Future<QueryPurchaseDetailsResponse> queryPastPurchases(
      {String? applicationUserName});

  static InAppPurchaseConnection? get instance => _getOrCreateInstance();
  static InAppPurchaseConnection? _instance;

  static InAppPurchaseConnection? _getOrCreateInstance() {
    if (_instance != null) {
      return _instance;
    }

    _instance = AppStoreConnection.instance;

    return _instance;
  }
}

/// 交易错误状态
enum PayErrorCode {
  /// 未知错误
  unknown,

  /// 用户取消支付
  cancel,

  /// 支付商品id无效
  invalid,

  /// 支付票据为空
  receiptEmpty,

  /// 校验票据失败
  verifyReceiptFail,

  /// 购买不可用
  notAvailable,

  /// 没有支付信息
  notPayInfo,

  /// 创建订单失败
  createOrderIdFail,

  /// 校验票据超时
  timeOut,
}

/// 内购错误信息
class IAPError {
  /// Creates a new IAP error object with the given error details.
  IAPError({required this.code, required this.message, this.details});

  /// 错误码
  final String code;

  /// 错误信息
  final String? message;

  /// 错误详细信息
  final dynamic details;
}
