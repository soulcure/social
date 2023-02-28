import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/src/store_kit_wrappers/enum_converters.dart';
import 'package:in_app_purchase/store_kit_wrappers.dart';

import 'in_app_purchase_connection.dart';

class PurchaseParam {
  /// 商品唯一标识ID
  final String productIdentifier;

  /// 把苹果的applicationUserName当做订单号扩展参数
  final String applicationUserName;

  /// 是否沙盒测试,非必传
  final bool? simulatesAskToBuyInSandbox;

  PurchaseParam({required this.productIdentifier,
    required this.applicationUserName,
    this.simulatesAskToBuyInSandbox});
}

/// 交易状态
enum PurchaseStatus {
  /// 交易等待中
  pending,

  /// 购买完成并且是成功支付状态
  purchased,

  /// 购买出错
  error
}

class PurchaseDetails {
  /// 购买的交易信息
  final SKPaymentTransactionWrapper? skPaymentTransaction;

  /// 交易时间戳
  final String? transactionTimeStamp;

  /// 交易流水ID
  final String? transactionIdentifier;

  /// 商品唯一标识id
  final String? productIdentifier;

  /// base64票据信息
  final String? transactionReceipt;

  /// 交易状态
  PurchaseStatus? _status;

  /// get方法
  PurchaseStatus? get status => _status;

  /// set方法
  set status(PurchaseStatus? status) {
    if (status == PurchaseStatus.purchased || status == PurchaseStatus.error) {
      _pendingCompletePurchase = true;
    }

    _status = status;
  }

  /// 错误信息
  IAPError? error;

  bool get pendingCompletePurchase => _pendingCompletePurchase;
  bool _pendingCompletePurchase = false;

  PurchaseDetails({this.skPaymentTransaction,
    this.transactionTimeStamp,
    this.transactionIdentifier,
    this.productIdentifier,
    this.transactionReceipt});

  PurchaseDetails.fromSKTransaction(SKPaymentTransactionWrapper transaction)
      : this.transactionIdentifier = transaction.transactionIdentifier,
        this.productIdentifier = transaction.payment!.productIdentifier,
        this.transactionReceipt = transaction.transactionReceipt,
        this.transactionTimeStamp = transaction.transactionTimeStamp != null
            ? (transaction.transactionTimeStamp! * 1000).toInt().toString()
            : null,
        this.skPaymentTransaction = transaction {
    status = SKTransactionStatusConverter()
        .toPurchaseStatus(transaction.transactionState);
    if (status == PurchaseStatus.error) {
      error = IAPError(
        code: transaction.error!.code.toString(),
        message: transaction.error!.domain,
        details: transaction.error!.userInfo,
      );
    }
  }
}

/// 查询购买过的商品
class QueryPurchaseDetailsResponse {
  /// Creates a new [QueryPurchaseDetailsResponse] object with the provider information.
  QueryPurchaseDetailsResponse({required this.pastPurchases, this.error});

  /// A list of successfully fetched past purchases.
  ///
  /// If there are no past purchases, or there is an [error] fetching past purchases,
  /// this variable is an empty List.
  /// You should verify the purchase data using [PurchaseDetails.verificationData] before using the [PurchaseDetails] object.
  final List<PurchaseDetails> pastPurchases;

  /// The error when fetching past purchases.
  ///
  /// If the fetch is successful, the value is null.
  final IAPError? error;
}
