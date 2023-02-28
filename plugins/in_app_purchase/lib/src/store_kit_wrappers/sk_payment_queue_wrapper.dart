import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:in_app_purchase/src/channel.dart';
import 'package:json_annotation/json_annotation.dart';

import 'sk_payment_transaction_wrappers.dart';
import 'sk_product_wrapper.dart';

part 'sk_payment_queue_wrapper.g.dart';

class SKPaymentQueueWrapper {
  /// 交易队列监听对象
  SKTransactionObserverWrapper? _observer;

  /// 初始化实例对象
  static final SKPaymentQueueWrapper _singleton = SKPaymentQueueWrapper._();

  /// 返回实例对象(用作单例)
  factory SKPaymentQueueWrapper() {
    return _singleton;
  }

  /// 初始化构造函数
  SKPaymentQueueWrapper._();

  /// 获取队列中的所有未结束的交易信息
  /// [`-[SKPaymentQueue transactions]`](https://developer.apple.com/documentation/storekit/skpaymentqueue/1506026-transactions?language=objc)
  Future<List<SKPaymentTransactionWrapper>?> transactions() async {
    return _getTransactionList(
        await channel.invokeListMethod<Map>('-[SKPaymentQueue transactions]'));
  }

  /// 支付是否可用
  ///  [`-[SKPaymentQueue canMakePayments:]`](https://developer.apple.com/documentation/storekit/skpaymentqueue/1506139-canmakepayments?language=objc).
  static Future<bool?> canMakePayments() async =>
      await channel.invokeMethod<bool>('-[SKPaymentQueue canMakePayments:]');

  /// 设置监听
  void setTransactionObserver(SKTransactionObserverWrapper? observer) {
    _observer = observer;
    callbackChannel.setMethodCallHandler(
        _handleObserverCallbacks as Future<dynamic> Function(MethodCall)?);
  }

  /// 向PaymentQueue队列中中添加一个支付对象
  ///
  /// 这将向应用商店发送一个购买请求以进行确认。
  /// 交易状态更新回调给,需要设置实现监听回调方法 [SKTransactionObserverWrapper]
  ///
  /// 在调用这个方法之前需要满足几个条件
  ///
  ///   - 应该至少要添加监听回调 [SKTransactionObserverWrapper]  相当于原生 [addTransactionObserver].
  ///   -  使用[payment.productIdentifier]前,需要使用[SKRequestMaker.startProductRequest]获取商品信息
  ///      这样一个有效的 'SKProduct' 就被添加到了缓存队列了
  ///
  /// 这个方法使用相当于 原生中的 StoreKit [`-[SKPaymentQueue addPayment:]`]
  /// (https://developer.apple.com/documentation/storekit/skpaymentqueue/1506036-addpayment?preferredLanguage=occ).
  ///
  /// 沙盒 [sandbox
  /// testing](https://developer.apple.com/apple-pay/sandbox-testing/).
  Future<void> addPayment(SKPaymentWrapper payment) async {
    assert(_observer != null,
        '[in_app_purchase]: 在支付前必须实现支付队列的监听回调 `SkPaymentQueueWrapper.setTransactionObserver`');
    Map requestMap = payment.toMap();
    await channel.invokeMethod<void>(
      '-[InAppPurchasePlugin addPayment:result:]',
      requestMap,
    );
  }

  /// 完成一个交易并从队列中移除
  /// 确保道具下发给用户了,再调用此方法
  /// 调用完该方法后,交易状态的更新将会被 [SKPaymentTransactionWrapper.removedTransactions] 监听到
  /// 如果交易状态在购买中时[SKPaymentTransactionStateWrapper.purchasing],调用此方法会抛出异常
  ///
  /// 该方法相当于原生S toreKit 的[`-[SKPaymentQueue
  /// finishTransaction:]`](https://developer.apple.com/documentation/storekit/skpaymentqueue/1506003-finishtransaction?language=objc).
  Future<void> finishTransaction(
      SKPaymentTransactionWrapper transaction) async {
    Map<String, String?> requestMap = transaction.toFinishMap();
    await channel.invokeMethod<void>(
      '-[InAppPurchasePlugin finishTransaction:result:]',
      requestMap,
    );
  }

  /// 恢复购买
  /// @param applicationName 根据支付时SKPayment中传入的applicationName恢复购买
  /// applicationName 为空时,恢复以前完成的所有交易
  /// 如果你的应用中有非消耗品 / 自动订阅 / 非自动订阅 必须提供UI给用户提供恢复功能
  ///
  /// 在恢复购买之前,需要确认实现了监听回调方法 [SKTransactionObserverWrapper]
  /// 调用restoreCompletedTransactions方法后,系统会回调
  /// [SKTransactionObserverWrapper.paymentQueueRestoreCompletedTransactionsFinished],
  /// 和 [SKTransactionObserverWrapper.updatedTransaction]
  /// 这些交易完成后,需要调用[finishTransaction]结束交易
  ///
  /// `applicationUserName`和之前购买传入的值一致,表示恢复指定交易
  /// `applicationUserName`不传时,表示恢复所有购买的交易记录
  ///
  /// 这个方法触发 [`-[SKPayment
  /// restoreCompletedTransactions]`](https://developer.apple.com/documentation/storekit/skpaymentqueue/1506123-restorecompletedtransactions?language=objc)
  /// 或者 [`-[SKPayment restoreCompletedTransactionsWithApplicationUsername:]`](https://developer.apple.com/documentation/storekit/skpaymentqueue/1505992-restorecompletedtransactionswith?language=objc)
  /// 是取决于是否设置了' applicationUserName '.
  Future<void> restoreTransactions({String? applicationUserName}) async {
    await channel.invokeMethod<void>(
        '-[InAppPurchasePlugin restoreTransactions:result:]',
        applicationUserName);
  }

  /// 开始监听
  Future<void> startObservingPaymentQueue() async {
    await channel.invokeMethod<void>(
        '-[FBIAPaymentQueueHandler startObservingPaymentQueue:result:]');
  }

  Future<void> removeObservingPaymentQueue() async {
    await channel.invokeMethod<void>(
        '-[FBIAPaymentQueueHandler removeObservingPaymentQueue:result:]');
  }

  /// 交易监听回调方法
  Future<dynamic>? _handleObserverCallbacks(MethodCall call) {
    assert(_observer != null,
        '[in_app_purchase]: (Fatal)The observer has not been set but we received a purchase transaction notification. Please ensure the observer has been set using `setTransactionObserver`. Make sure the observer is added right at the App Launch.');
    switch (call.method) {
      case 'updatedTransactions':
        {
          final List<SKPaymentTransactionWrapper>? transactions =
              _getTransactionList(call.arguments);
          return Future<void>(() {
            _observer!.updatedTransactions(transactions: transactions);
          });
        }
      case 'removedTransactions':
        {
          final List<SKPaymentTransactionWrapper>? transactions =
              _getTransactionList(call.arguments);
          return Future<void>(() {
            _observer!.removedTransactions(transactions: transactions);
          });
        }
      case 'restoreCompletedTransactionsFailed':
        {
          SKError error = SKError.fromJson(call.arguments);
          return Future<void>(() {
            _observer!.restoreCompletedTransactionsFailed(error: error);
          });
        }
      case 'paymentQueueRestoreCompletedTransactionsFinished':
        {
          return Future<void>(() {
            _observer!.paymentQueueRestoreCompletedTransactionsFinished();
          });
        }
      case 'shouldAddStorePayment':
        {
          SKPaymentWrapper payment =
              SKPaymentWrapper.fromJson(call.arguments['payment']);
          SKProductWrapper product =
              SKProductWrapper.fromJson(call.arguments['product']);
          return Future<void>(() {
            if (_observer!.shouldAddStorePayment(
                    payment: payment, product: product) ==
                true) {
              SKPaymentQueueWrapper().addPayment(payment);
            }
          });
        }
      default:
        break;
    }
    return null;
  }

  /// 从原生获取到的Map数据转换为 对象
  List<SKPaymentTransactionWrapper>? _getTransactionList(dynamic arguments) {
    final List<SKPaymentTransactionWrapper>? transactions = arguments
        .map<SKPaymentTransactionWrapper>(
            (dynamic map) => SKPaymentTransactionWrapper.fromJson(map))
        .toList();
    return transactions;
  }
}

/// Dart 封装的 模型对象
/// 对应iOS [SKPayment](https://developer.apple.com/documentation/storekit/skpayment?language=objc).
/// 支付时需要用到的对象
/// [SKPaymentQueueWrapper.addPayment] 传入对应的支付参数进行支付
@JsonSerializable(nullable: true)
class SKPaymentWrapper {
  /// 商品ID
  final String? productIdentifier;

  /// 用户名 (在业务上被用来传orderId了)
  final String? applicationUsername;

  /// 此属性是苹果为将来使用而保留
  /// 在支付的时候,该值必须是null,否则支付会被拒绝
  /// 官方文档说明 https://developer.apple.com/documentation/storekit/skpayment/1506159-requestdata?language=objc
  final String? requestData;

  /// 商品数量 (默认是1   最小值为 1 最大值为 10)
  final int? quantity;

  /// 是否为沙盒购买
  final bool? simulatesAskToBuyInSandbox;

  SKPaymentWrapper(
      {required this.productIdentifier,
      this.applicationUsername,
      this.requestData,
      this.quantity,
      this.simulatesAskToBuyInSandbox = false});

  /// 从map数据映射构造出一个实例对象
  /// 传入的map不能为null
  factory SKPaymentWrapper.fromJson(Map map) {
    return _$SKPaymentWrapperFromJson(map);
  }

  /// 实例对象转换成map对象
  Map<String, dynamic> toMap() {
    return {
      'productIdentifier': productIdentifier,
      'applicationUsername': applicationUsername,
      'requestData': requestData,
      'quantity': quantity,
      'simulatesAskToBuyInSandbox': simulatesAskToBuyInSandbox
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) {
      return true;
    }

    if (other.runtimeType != runtimeType) {
      return false;
    }
    final SKPaymentWrapper typedOther = other as SKPaymentWrapper;
    return typedOther.productIdentifier == productIdentifier &&
        typedOther.applicationUsername == applicationUsername &&
        typedOther.quantity == quantity &&
        typedOther.simulatesAskToBuyInSandbox == simulatesAskToBuyInSandbox &&
        typedOther.requestData == requestData;
  }

  @override
  int get hashCode => hashValues(
      this.productIdentifier,
      this.applicationUsername,
      this.quantity,
      this.simulatesAskToBuyInSandbox,
      this.requestData);

  @override
  String toString() => _$SKPaymentWrapperToJson(this).toString();
}

/// Dart封装的内购错误对象
/// [NSError][https://developer.apple.com/documentation/foundation/nserror?language=objc]
class SKError {
  /// 对应苹果NSError错误码
  /// Error [code](https://developer.apple.com/documentation/foundation/1448136-nserror_codes)
  final int? code;

  /// 错误域
  /// [domain](https://developer.apple.com/documentation/foundation/nscocoaerrordomain?language=objc)
  final String? domain;

  /// 错误详细信息
  /// 对应的内容key 必须和苹果key一致 [NSErrorUserInfoKey](https://developer.apple.com/documentation/foundation/nserroruserinfokey?language=objc).
  final Map<String, dynamic>? userInfo;

  SKError({required this.code, required this.domain, required this.userInfo});

  factory SKError.fromJson(Map map) {
    assert(map != null);
    return _$SKErrorFromJson(map);
  }

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }
    final SKError typedOther = other as SKError;
    return typedOther.code == code &&
        typedOther.domain == domain &&
        DeepCollectionEquality.unordered()
            .equals(typedOther.userInfo, userInfo);
  }

  @override
  int get hashCode => hashValues(this.code, this.domain, this.userInfo);

  @override
  String toString() => _$SKErrorToJson(this).toString();
}
