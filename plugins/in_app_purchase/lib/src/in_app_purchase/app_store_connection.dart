import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:in_app_purchase/src/in_app_purchase/in_app_purchase_connection.dart';
import 'package:in_app_purchase/src/store_kit_wrappers/enum_converters.dart';

import '../../store_kit_wrappers.dart';
import 'product_details.dart';
import 'purchase_details.dart';

class AppStoreConnection implements InAppPurchaseConnection {
  static AppStoreConnection? get instance => _getOrCreateInstance();
  static AppStoreConnection? _instance;
  static late SKPaymentQueueWrapper _skPaymentQueueWrapper;
  static _TransactionObserver? _observer;

  /// 此方法用于测试
  @visibleForTesting
  AppStoreConnection();

  Stream<List<PurchaseDetails>> get purchaseUpdatedStream =>
      _observer!.purchaseUpdatedController.stream;

  /// 交易状态监听对象
  @visibleForTesting
  static SKTransactionObserverWrapper? get observer => _observer;

  static AppStoreConnection? _getOrCreateInstance() {
    if (_instance != null) {
      return _instance;
    }

    _instance = AppStoreConnection();
    _skPaymentQueueWrapper = SKPaymentQueueWrapper();
    _observer = _TransactionObserver(StreamController.broadcast());
    _skPaymentQueueWrapper.setTransactionObserver(observer);
    return _instance;
  }

  /// 开启监听
  @override
  Future<void> startObservingPaymentQueue() {
    return _skPaymentQueueWrapper.startObservingPaymentQueue();
  }

  ///移除监听
  @override
  Future<void> removeObservingPaymentQueue() {
    return _skPaymentQueueWrapper.removeObservingPaymentQueue();
  }

  /// 支付是否可用
  @override
  Future<bool?> isAvailable() => SKPaymentQueueWrapper.canMakePayments();

  /// 购买 / 支付
  @override
  Future<bool> pay({required PurchaseParam purchaseParam}) async {
    await _skPaymentQueueWrapper.addPayment(SKPaymentWrapper(
        productIdentifier: purchaseParam.productIdentifier,
        quantity: 1,
        applicationUsername: purchaseParam.applicationUserName,
        simulatesAskToBuyInSandbox: purchaseParam.simulatesAskToBuyInSandbox,
        requestData: null));
    return true; // There's no error feedback from iOS here to return.
  }

  /// 完成购买流程 (调用苹果的 finishTransaction)
  @override
  Future<void> completePurchase(PurchaseDetails purchaseDetail) {
    return _skPaymentQueueWrapper
        .finishTransaction(purchaseDetail.skPaymentTransaction!);
  }

  /// 恢复购买
  @override
  Future<QueryPurchaseDetailsResponse> queryPastPurchases(
      {String? applicationUserName}) async {
    IAPError? error;
    List<PurchaseDetails> pastPurchases = [];

    try {
      final List<SKPaymentTransactionWrapper> restoredTransactions =
          await _observer!.getRestoredTransactions(
              queue: _skPaymentQueueWrapper,
              applicationUserName: applicationUserName);
      _observer!.cleanUpRestoredTransactions();
      pastPurchases =
          restoredTransactions.map((SKPaymentTransactionWrapper transaction) {
        assert(transaction.transactionState ==
            SKPaymentTransactionStateWrapper.restored);
        return PurchaseDetails.fromSKTransaction(transaction)
          ..status = SKTransactionStatusConverter()
              .toPurchaseStatus(transaction.transactionState)
          ..error = transaction.error != null
              ? IAPError(
                  code: transaction.error!.code.toString(),
                  message: transaction.error!.domain,
                  details: transaction.error!.userInfo,
                )
              : null;
      }).toList();
    } on PlatformException catch (e) {
      error = IAPError(code: e.code, message: e.message, details: e.details);
    } on SKError catch (e) {
      error = IAPError(
          code: e.code.toString(), message: e.domain, details: e.userInfo);
    }
    return QueryPurchaseDetailsResponse(
        pastPurchases: pastPurchases, error: error);
  }

  /// 实现抽象类查询道具信息方法
  @override
  Future<ProductDetailsResponse> queryProductDetails(
      Set<String> identifiers) async {
    final SKRequestMaker requestMaker = SKRequestMaker();
    SKProductResponseWrapper response;
    PlatformException? exception;
    try {
      response = await requestMaker.startProductRequest(identifiers.toList());
    } on PlatformException catch (e) {
      exception = e;
      response = SKProductResponseWrapper(
          products: [], invalidProductIdentifiers: identifiers.toList());
    }
    List<ProductDetails> productDetails = [];
    if (response.products.isNotEmpty) {
      productDetails = response.products
          .map((SKProductWrapper productWrapper) =>
              ProductDetails.fromSKProduct(productWrapper))
          .toList();
    }
    List<String> invalidIdentifiers = response.invalidProductIdentifiers;
    if (productDetails.isEmpty) {
      invalidIdentifiers = identifiers.toList();
    }
    ProductDetailsResponse productDetailsResponse = ProductDetailsResponse(
      products: productDetails,
      invalidProductIdentifiers: invalidIdentifiers,
      error: exception == null
          ? null
          : IAPError(
              code: exception.code,
              message: exception.message,
              details: exception.details),
    );
    return productDetailsResponse;
  }
}

/// 观察者监听对象类
class _TransactionObserver implements SKTransactionObserverWrapper {
  final StreamController<List<PurchaseDetails>> purchaseUpdatedController;

  /// 恢复购买交易数据
  List<SKPaymentTransactionWrapper>? _restoredTransactions;

  /// 数据流用到
  Completer<List<SKPaymentTransactionWrapper>>? _restoreCompleter;

  _TransactionObserver(this.purchaseUpdatedController);

  /// 当观察者队列中的交易状态(添加或状态改变)发生变化时发送
  void updatedTransactions({List<SKPaymentTransactionWrapper>? transactions}) {
    /// 判断恢复购买有触发
    if (_restoreCompleter != null) {
      if (_restoredTransactions == null) {
        _restoredTransactions = [];
      }

      /// 获取恢复购买数据
      _restoredTransactions!
          .addAll(transactions!.where((SKPaymentTransactionWrapper wrapper) {
        return wrapper.transactionState ==
            SKPaymentTransactionStateWrapper.restored;
      }).map((SKPaymentTransactionWrapper wrapper) => wrapper));
    }

    ///正常购买道具
    purchaseUpdatedController
        .add(transactions!.where((SKPaymentTransactionWrapper wrapper) {
      return wrapper.transactionState !=
          SKPaymentTransactionStateWrapper.restored;
    }).map((SKPaymentTransactionWrapper transaction) {
      PurchaseDetails purchaseDetails =
          PurchaseDetails.fromSKTransaction(transaction);
      return purchaseDetails;
    }).toList());
  }

  /// 通知观察者任意一个交易被移除队列(通过 finishTransaction)
  void removedTransactions({List<SKPaymentTransactionWrapper>? transactions}) {
    // TODO: 1/22/21 暂时业务用不到
    print('removedTransactions ${transactions.toString()}');
  }

  /// 恢复购买失败回调
  void restoreCompletedTransactionsFailed({SKError? error}) {
    _restoreCompleter!.completeError(error!);
  }

  /// 恢复购买成功回调
  void paymentQueueRestoreCompletedTransactionsFinished() {
    _restoreCompleter!.complete(_restoredTransactions ?? []);
  }

  /// 当用户从AppStore发起支付时回调
  bool shouldAddStorePayment(
      {SKPaymentWrapper? payment, SKProductWrapper? product}) {
    // TODO: 1/22/21 待实现
    return true;
  }

  /// 本类自定义清理恢复购买数据方法
  void cleanUpRestoredTransactions() {
    _restoredTransactions = null;
    _restoreCompleter = null;
  }

  Future<List<SKPaymentTransactionWrapper>> getRestoredTransactions(
      {required SKPaymentQueueWrapper queue, String? applicationUserName}) {
    _restoreCompleter = Completer();
    queue.restoreTransactions(applicationUserName: applicationUserName);
    return _restoreCompleter!.future;
  }
}
