import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:im/common/extension/string_extension.dart';
import 'package:im/pay/iap/iap_data_store.dart';
import 'package:im/pay/iap/iap_helper.dart';

import '../../loggers.dart';

class IAPRepeatVerifyReceipt {
  // 验票轮询间隔 单位 秒
  static const receiptInterval = 60;

  /// 计时器
  Timer timer;

  IAPRepeatVerifyReceipt._();

  static final _instance = IAPRepeatVerifyReceipt._();

  static IAPRepeatVerifyReceipt get instance {
    return _instance;
  }

  /// 开启补单
  void start() {
    timer ??= Timer.periodic(const Duration(seconds: receiptInterval), (timer) {
      /// 开始校验
      startVerifyReceiptData();
    });
    logger.info('开启了苹果票据轮训, $receiptInterval 秒执行一次');
  }

  /// 停止补单
  void stop() {
    //可以使用timer.cancel()来取消定时器，避免无限回调
    if (timer != null) {
      timer.cancel();
      timer = null;
      logger.info('没有轮训的苹果票据,停止轮训');
    }
  }

  /// 判断是否有网络
  Future<bool> isConnected() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  /// 校验票据方法
  Future<void> startVerifyReceiptData() async {
    /// 没有网络补单不做任何处理
    if (!await isConnected()) return;
    final receiptMapTemp = await IAPDataStoreReceipt.getReceiptData();

    if (receiptMapTemp.isEmpty) {
      stop();
      return;
    }

    final receiptMap =
        IAPDataStoreReceipt.filterCurrentLifeCycleOrder(receiptMapTemp);

    if (receiptMap.isEmpty) {
      stop();
      return;
    }

    final orderList = receiptMap.keys.toList();
    final receiptList = receiptMap.values.toList();

    for (int i = 0; i < orderList.length; i++) {
      /// 订单号Id
      final String orderId = orderList[i];

      /// 票据相关Map信息
      final receiptInfo = receiptList[i];

      /// base64的票据
      final String base64ReceiptString = receiptInfo['receipt'];

      /// 商品唯一标识
      final productId = receiptInfo['productID'];

      if (orderId.noValue) break;

      final verifyTimes = await IAPDataStoreReceiptTimes.catchOrderVerifyTimes(
          orderID: orderId);

      /// 重试次数已用光，删除该票据
      if (verifyTimes <= 0) {
        await IAPDataStoreReceipt.deleteReceiptData(orderId: orderId);
        logger.info('苹果票据次数已经用完,删除票据 订单号: $orderId');
        break;
      }

      /// 校验苹果票据
      await IAPHelper.instance.serverVerifyReceipt(
          orderId: orderId,
          transactionReceipt: base64ReceiptString,
          onSuss: () {
            // 验单成功，删除本地缓存的票据信息
            IAPDataStoreReceipt.deleteReceiptData(orderId: orderId);
            // 验单成功，删除本地保存的订单信息
            IAPDataStoreOrderId.deleteOrderFromLocalOrderListWithOrderID(
                orderId: orderId);
            logger.info('苹果票据校验成功$productId, 订单号: $orderId');
          },
          onFail: (code, message) {
            // 校验失败

            if (IAPHelper.instance.isDeleteReceipt(code)) {
              // 删除本地缓存的票据信息
              IAPDataStoreReceipt.deleteReceiptData(orderId: orderId);
              //删除本地保存的订单信息
              IAPDataStoreOrderId.deleteOrderFromLocalOrderListWithOrderID(
                  orderId: orderId);
              logger.info(' 特殊错误码，需要从轮询缓存中删除该票据, 订单号: $orderId');
            } else {
              if (base64ReceiptString.noValue) {
                // 删除本地缓存的票据信息
                IAPDataStoreReceipt.deleteReceiptData(orderId: orderId);
                //删除本地保存的订单信息
                IAPDataStoreOrderId.deleteOrderFromLocalOrderListWithOrderID(
                    orderId: orderId);
                logger.severe('苹果票据不存在,进行缓存删除, 订单号: $orderId');
              } else {
                // 验票失败，重试次数减一
                IAPDataStoreReceiptTimes.saveOrderVerifyTimes(
                    orderId: orderId, times: -1);
                // 生命周期内针对每个订单记录验票次数
                IAPDataStoreReceipt.countCurrentLifeCycleOrder(orderId);
                logger.severe('苹果票据校验失败,减少验证次数, 订单号: $orderId');
              }
            }
          });
    }
  }
}
