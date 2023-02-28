import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:im/api/pay_api.dart';
import 'package:im/common/extension/string_extension.dart';
import 'package:im/pay/iap/iap_repeat_verify_receipt.dart';
import 'package:im/utils/universal_platform.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../../loggers.dart';
import '../pay_manager.dart';
import 'iap_data_store.dart';

/// 苹果内购助手
class IAPHelper {
  static IAPHelper instance = IAPHelper();

  /// 内购连接类
  InAppPurchaseConnection _connection;

  /// 支付监听流
  StreamSubscription<List<PurchaseDetails>> _subscription;

  /// 缓存购买商品信息 目前iOS用到
  Map productsCache = {};

  /// 支付成功回调
  OnSuccess _onSuccess;

  /// 支付失败回调
  OnError _onError;

  //最近一次发起购买的订单号，在UserApplicationName为nil时使用
  String lastOrderID;

  //最近一次购买道具的道具id
  String lastProductID;

  /// 支付助手初始化
  IAPHelper() {
    if (UniversalPlatform.isIOS) {
      try {
        /// 清理过期的订单信息
        IAPDataStoreOrderId.clearExpiredOrderID();

        /// 开启补单监听timer
        IAPRepeatVerifyReceipt.instance.start();

        _connection ??= InAppPurchaseConnection.instance;

        final purchaseUpdated =
            InAppPurchaseConnection.instance.purchaseUpdatedStream;
        _subscription =
            purchaseUpdated.listen(_listenToPurchaseUpdated, onDone: () {
          _subscription.cancel();
          print('购买状态更新监听取消');
        }, onError: (error) {
          // 监听出错
          print('购买状态更新监听出错');
        });
      } catch (e) {
        print(e);
      }
    }
  }

  /// 开启监听
  Future<void> startObservingPaymentQueue() async {
    if (UniversalPlatform.isIOS) {
      await _connection.startObservingPaymentQueue();
    }
  }

  ///移除监听
  Future<void> removeObservingPaymentQueue() async {
    if (UniversalPlatform.isIOS) {
      await _connection.removeObservingPaymentQueue();
    }
  }

  Future<void> pay(
      {@required String productId,
      @required String orderId,
      OnSuccess onSuccess,
      OnError onError}) async {
    _onSuccess = onSuccess;
    _onError = onError;

    if (!UniversalPlatform.isIOS) {
      return;
    }

    /// 当前支付是否可用
    final isAvailable = await _connection.isAvailable();
    if (!isAvailable) {
      _onError?.call(PayErrorCode.notAvailable.index.toString(), '当前商品不可用'.tr);
      return;
    }

    /// 判断缓存中是否有查询过此道具
    if (productsCache[productId] == null) {
      /// 查询商品信息
      final ProductDetailsResponse productDetailResponse =
          await _connection.queryProductDetails({productId});

      /// 查询商品信息是否出现异常
      if (productDetailResponse.error != null) {
        _onError?.call(productDetailResponse.error.code, '获取购买商品信息出现异常'.tr);
        return;
      }

      /// 判断是否存在无效商品
      if (productDetailResponse.invalidProductIdentifiers.isNotEmpty) {
        _onError?.call(PayErrorCode.invalid.index.toString(), '存在无效商品信息'.tr);
        return;
      }

      /// 判断商品信息是否为空
      if (productDetailResponse.products.isEmpty) {
        _onError?.call(
            PayErrorCode.notPayInfo.index.toString(), '获取购买商品信息失败'.tr);
        return;
      }

      /// 缓存道具信息
      productDetailResponse.products.forEach((product) {
        productsCache[product.productIdentifier] = product;
      });
    }

    // 生成订单之后，保存订单到本地，防止丢单和苹果抽风不给订单号（applicationUsername为空）
    await IAPDataStoreOrderId.saveOrderWithProductID(
        productId: productId, orderId: orderId);

    try {
      /// 进行支付
      await _connection.pay(
          purchaseParam: PurchaseParam(
              productIdentifier: productId, applicationUserName: orderId));
    } on PlatformException catch (e) {
      _onError?.call(e?.code, e?.message);
      logger.severe(e?.message);
    }

    lastOrderID = orderId;
    lastProductID = productId;
    return;
  }

  /// 商品购买状态更新
  void _listenToPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) {
    purchaseDetailsList.forEach((purchaseDetails) async {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        /// 购买进行中,待客户操作
        logger.info('用户正在支付中...');
      } else {
        /// 购买失败
        if (purchaseDetails.status == PurchaseStatus.error) {
          if (purchaseDetails.error.code == '2') {
            _onError?.call(PayErrorCode.cancel.index.toString(), '用户取消了支付'.tr);
          } else {
            _onError?.call(purchaseDetails.error.code, '购买商品出错了'.tr);
          }
        } else if (purchaseDetails.status == PurchaseStatus.purchased) {
          /// 苹果透传orderId
          String orderId =
              purchaseDetails.skPaymentTransaction.payment.applicationUsername;

          /// 票据信息
          final receipt = purchaseDetails.transactionReceipt;

          /// 道具标识
          final productId = purchaseDetails.productIdentifier;

          if (orderId.noValue) {
            logger.severe('applicationUsername 找不到订单号');
            orderId = lastOrderID;
            if (orderId.noValue) {
              logger.severe('lastOrderID 找不到订单号');
              orderId = await IAPDataStoreOrderId.orderIdForProductId(
                  productId: productId);
            }

            if (orderId.noValue) {
              logger.severe('完全找不到订单号，需联系客服补单 $productId');
              await finishTransaction(purchaseDetails);
              return;
            }
          } else {
            // 苹果订单回调中带有orderID时，删掉本地缓存
            await IAPDataStoreOrderId.deleteOrderFromLocalOrderListWithOrderID(
                orderId: orderId);
          }

          /// 记录收据信息
          await IAPDataStoreReceipt.saveReceiptData(
              receipt: receipt, orderId: orderId, productId: productId);

          /// 购买成功的进行票据校验
          await serverVerifyReceipt(
              orderId: orderId,
              transactionReceipt: receipt,
              onSuss: () {
                // 删除本地缓存的票据信息
                IAPDataStoreReceipt.deleteReceiptData(orderId: orderId);
                // 删除本地保存的订单信息
                IAPDataStoreOrderId.deleteOrderFromLocalOrderListWithOrderID(
                    orderId: orderId);

                _onSuccess?.call(productId);
              },
              onFail: (code, message) {
                if (isDeleteReceipt(code)) {
                  // 删除本地缓存的票据信息
                  IAPDataStoreReceipt.deleteReceiptData(orderId: orderId);
                  // 删除本地保存的订单信息
                  IAPDataStoreOrderId.deleteOrderFromLocalOrderListWithOrderID(
                      orderId: orderId);

                  _onError?.call(
                      PayErrorCode.verifyReceiptFail.index.toString(),
                      '校验票据失败,超过次数,删除票据'.tr);
                } else {
                  // 不是特殊错误码，开启订单验票轮询,但是为了不在短时间内发起相同的请求，要稍微延迟1s
                  IAPRepeatVerifyReceipt.instance.start();
                  _onError?.call(code, message);
                }
              });
        }

        /// 结束购买交易
        if (purchaseDetails.pendingCompletePurchase) {
          await finishTransaction(purchaseDetails);
        }
      }
    });
  }

  /// 结束票据交易
  Future<void> finishTransaction(PurchaseDetails purchaseDetail) async {
    if (UniversalPlatform.isIOS) {
      await InAppPurchaseConnection.instance.completePurchase(purchaseDetail);
      lastOrderID = null;
      lastProductID = null;
    }
  }

  /// 服务端校验票据
  Future<void> serverVerifyReceipt(
      {String orderId,
      String transactionReceipt,
      Function onSuss,
      Function(String code, String message) onFail}) async {
    if (!UniversalPlatform.isIOS) {
      return;
    }
    if (transactionReceipt.noValue) {
      onFail(PayErrorCode.receiptEmpty.index.toString(), '校验票据失败'.tr);
      return;
    }
    try {
      final res = await PayApi.appleReceipt(
          orderNo: orderId, receipt: transactionReceipt);

      final status = res['status'] ?? false;
      final code = res['code']?.toString() ?? '';
      final desc = res['desc'] ?? '';
      if (status) {
        onSuss?.call();
      } else {
        onFail?.call(code, desc);
      }
    } catch (e) {
      if (e is DioError) {
        final code = e?.response?.statusCode?.toString();
        final message = e?.response?.statusMessage?.toString();
        final DioErrorType type = e?.type;
        if (type == DioErrorType.connectTimeout) {
          onFail?.call(PayErrorCode.timeOut.index.toString(), '校验票据超时'.tr);
        } else {
          onFail?.call(code, message);
        }
      } else {
        onFail?.call(
            PayErrorCode.verifyReceiptFail.index.toString(), '校验票据失败'.tr);
      }
    }
  }

  /// 根据验票错误码判定是否需要删除缓存的订单票据数据
  bool isDeleteReceipt(String code) {
    if (code.noValue) return false;
    if (code == '1200') {
      /// 找不到订单
      return true;
    } else if (code == '1203') {
      /// Product ID 不正确
      return true;
    } else if (code == '1204') {
      /// 无效票据
      return true;
    } else if (code == '1205') {
      /// 票剧已绑定其它订单
      return true;
    }
    return false;
  }
}
