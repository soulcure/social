import 'dart:ui' show hashValues;

import 'package:in_app_purchase/src/store_kit_wrappers/sk_payment_queue_wrapper.dart';
import 'package:json_annotation/json_annotation.dart';

import 'enum_converters.dart';
import 'sk_product_wrapper.dart';

part 'sk_payment_transaction_wrappers.g.dart';

/// 购买状态变化回调处理类
/// 只有设置了监听 [SKPaymentQueueWrapper.setTransactionObserver]
/// 才能收到对应的监听回调
abstract class SKTransactionObserverWrapper {
  /// 当观察者队列中的交易状态(添加或状态改变)发生变化时发送
  void updatedTransactions({List<SKPaymentTransactionWrapper>? transactions});

  /// 通知观察者任意一个交易被移除队列(通过 finishTransaction)
  void removedTransactions({List<SKPaymentTransactionWrapper>? transactions});

  /// 恢复购买失败回调
  void restoreCompletedTransactionsFailed({SKError? error});

  /// 恢复购买成功回调
  void paymentQueueRestoreCompletedTransactionsFinished();

  /// 当用户从AppStore发起支付时回调
  bool shouldAddStorePayment(
      {SKPaymentWrapper? payment, SKProductWrapper? product});
}

/// 交易状态
/// Dart 封装 StoreKit
/// [SKPaymentTransactionState](https://developer.apple.com/documentation/storekit/skpaymenttransactionstate?language=objc).
enum SKPaymentTransactionStateWrapper {
  /// 正在购买中,需要用户等待支付状态更新
  /// 在此状态下不能finished结束当前交易状态
  @JsonValue(0)
  purchasing,

  ///用户已经成功付款,给用户下发商品
  @JsonValue(1)
  purchased,

  /// 交易失败
  /// 通过返回来的 [SKPaymentTransactionWrapper] 对象查看错误信息
  /// [SKPaymentTransactionWrapper.error]获取错误信息
  @JsonValue(2)
  failed,

  /// 恢复购买
  /// 通过[SKPaymentTransactionWrapper.originalTransaction]获取之前购买的票据
  @JsonValue(3)
  restored,

  /// 交易在队列中,等待用户付款动作
  /// 等待其他交易完成
  @JsonValue(4)
  deferred,
}

@JsonSerializable(/*nullable: true*/)
class SKPaymentTransactionWrapper {
  /// 当前交易状态
  @SKTransactionStatusConverter()
  final SKPaymentTransactionStateWrapper? transactionState;

  /// 支付的时候通过[addPayment]传入的 payment
  final SKPaymentWrapper? payment;

  /// 之前购买过的交易信息
  /// 只有状态为 [SKPaymentTransactionStateWrapper.restored] 恢复当前购买
  /// 恢复购买的时候 transactionIdentifier会是一个新的id
  final SKPaymentTransactionWrapper? originalTransaction;

  /// 交易时间戳
  /// 当前交易添加到服务器队列的日期
  /// 只有在 [SKPaymentTransactionStateWrapper.purchased]
  /// 或者 [SKPaymentTransactionStateWrapper.restored]状态下才有
  final double? transactionTimeStamp;

  /// 交易流水ID
  /// 只有在[SKPaymentTransactionStateWrapper.purchased] 或
  /// [SKPaymentTransactionStateWrapper.restored]状态下有
  ///
  final String? transactionIdentifier;

  /// 当前交易的base64字符串票据信息
  /// 此字段苹果从iOS7以后不推荐使用
  /// 推荐使用[[NSBundle mainBundle] appStoreReceiptURL]获取凭证
  /// [SKReceiptManager.retrieveReceiptData]
  final String? transactionReceipt;

  /// 交易发生错误的错误信息
  /// 只有在 [SKPaymentTransactionStateWrapper.failed]状态下有
  final SKError? error;

  /// 实例方法
  SKPaymentTransactionWrapper(
      {required this.transactionState,
      required this.payment,
      required this.originalTransaction,
      required this.transactionTimeStamp,
      required this.transactionIdentifier,
      required this.transactionReceipt,
      required this.error});

  /// Map序列化成实例对象
  factory SKPaymentTransactionWrapper.fromJson(Map map) {
    return _$SKPaymentTransactionWrapperFromJson(map);
  }

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    return other is SKPaymentTransactionWrapper &&
        other.payment == payment &&
        other.transactionState == transactionState &&
        other.originalTransaction == originalTransaction &&
        other.transactionTimeStamp == transactionTimeStamp &&
        other.transactionIdentifier == transactionIdentifier &&
        other.transactionReceipt == transactionReceipt &&
        other.error == error;
  }

  @override
  int get hashCode => hashValues(
      this.payment,
      this.transactionState,
      this.originalTransaction,
      this.transactionTimeStamp,
      this.transactionIdentifier,
      this.transactionReceipt,
      this.error);

  @override
  String toString() => _$SKPaymentTransactionWrapperToJson(this).toString();

  /// 将交易对象的 商品ID 和 交易流水ID 封装成Map
  /// 用于Finish结束交易用
  Map<String, String?> toFinishMap() => {
        "transactionIdentifier": this.transactionIdentifier,
        "productIdentifier": this.payment?.productIdentifier,
      };
}
