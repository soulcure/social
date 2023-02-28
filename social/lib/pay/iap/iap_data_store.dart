import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:im/common/extension/list_extension.dart';
import 'package:im/common/extension/string_extension.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../loggers.dart';
import 'iap_repeat_verify_receipt.dart';

class IAPDataStoreOrderId {
  /// 订单信息保存文件名称
  static const kLocalOrderCacheFileName = "fb_kLocalOrderCacheFileName.store";

  // 保存商品唯一标识 Key(com.xx.xx)
  static const _kProductID = "kProductID";

// 保存订单号Key
  static const _kOrderID = "kOrderID";

// 保存订单日期Key
  static const _kExpiredTime = "kExpiredTime";

  // 订单缓存7天过期 单位：s
  static const _kExpiredTimeInterval = 7 * 24 * 60 * 60;

  /// 保存订单信息，应对bug：在玩家未绑定支付方式的情况下，
  /// apple会回调支付失败，之后如果玩家绑定支付方式并支付成功， 回调支付成功，
  /// 但此时 payment.applicationUsername 为 nil
  static Future<void> saveOrderWithProductID(
      {@required String productId, @required String orderId}) async {
    if (productId.noValue || orderId.noValue) {
      print('保存订单数据不符合规则');
      return;
    }

    final String fileContent =
        await IAPDataStoreHelper.fileRead(fileName: kLocalOrderCacheFileName);

    List list = [];
    if (fileContent.hasValue) {
      list = jsonDecode(fileContent);
    }

    /// 数据去重
    // await deleteOrderFromLocalOrderListWithOrderID(orderId: orderId);

    /// 有效期
    final timeStamp = DateTime.now()
        .add(const Duration(seconds: _kExpiredTimeInterval))
        .millisecondsSinceEpoch
        .toString();

    /// 把订单信息封装进Map
    final orderInfo = {
      _kProductID: productId,
      _kOrderID: orderId,
      _kExpiredTime: timeStamp
    };

    if (list != null) {
      list.insert(0, orderInfo);
    }

    /// 把订单数据信息转换成string
    final listString = jsonEncode(list);

    /// 写入文件
    await IAPDataStoreHelper.fileWrite(
        fileName: kLocalOrderCacheFileName, contents: listString);
  }

  /// 通过orderID删除缓存的订单信息
  static Future<void> deleteOrderFromLocalOrderListWithOrderID(
      {@required String orderId}) async {
    if (orderId.noValue) {
      return;
    }

    final String fileContent =
        await IAPDataStoreHelper.fileRead(fileName: kLocalOrderCacheFileName);

    List list = [];
    if (fileContent.hasValue) {
      list = jsonDecode(fileContent);
    }

    if (list.noValue) return;

    final listTemp = List.from(list);
    for (final Map orderInfoMap in listTemp) {
      int expiredTime = 0;
      try {
        expiredTime = int.parse(orderInfoMap[_kExpiredTime]);
      } catch (e) {
        expiredTime = 0;
      }

      final nowTime = DateTime.now().millisecondsSinceEpoch;

      if (expiredTime <= nowTime) {
        break;
      }

      final orderIdCache = orderInfoMap[_kOrderID];
      if (orderIdCache == orderId) {
        list.remove(orderInfoMap);

        /// 把订单数据信息转换成string
        final listString = jsonEncode(list);

        /// 写入文件
        await IAPDataStoreHelper.fileWrite(
            fileName: kLocalOrderCacheFileName, contents: listString);

        return;
      }
    }
  }

  /// 清理过期的缓存数据
  static Future<void> clearExpiredOrderID() async {
    final String fileContent =
        await IAPDataStoreHelper.fileRead(fileName: kLocalOrderCacheFileName);

    if (fileContent.noValue) {
      return;
    }
    List list = [];
    if (fileContent.hasValue) {
      list = jsonDecode(fileContent);
    }

    if (list.noValue) return;

    final listTemp = List.from(list);
    for (final orderInfoMap in listTemp) {
      int expiredTime = 0;
      try {
        expiredTime = int.parse(orderInfoMap[_kExpiredTime]);
      } catch (e) {
        expiredTime = 0;
      }
      final nowTime = DateTime.now().millisecondsSinceEpoch;

      if (expiredTime <= nowTime) {
        final expiredIndex = listTemp.indexOf(orderInfoMap);

        list.removeRange(expiredIndex, list.length - expiredIndex);

        /// 把订单数据信息转换成string
        final listString = jsonEncode(list);

        /// 写入文件
        await IAPDataStoreHelper.fileWrite(
            fileName: kLocalOrderCacheFileName, contents: listString);
        break;
      }
    }
  }

  /// 根据商品唯一标识查找缓存中的orderId
  static Future<String> orderIdForProductId(
      {@required String productId}) async {
    final String fileContent =
        await IAPDataStoreHelper.fileRead(fileName: kLocalOrderCacheFileName);

    if (fileContent.noValue) {
      return '';
    }
    List list = [];
    if (fileContent.hasValue) {
      list = jsonDecode(fileContent);
    }

    if (list.noValue) return '';

    for (final orderInfoMap in list) {
      int expiredTime = 0;
      try {
        expiredTime = int.parse(orderInfoMap[_kExpiredTime]);
      } catch (e) {
        expiredTime = 0;
      }

      final nowTime = DateTime.now().millisecondsSinceEpoch;

      if (expiredTime <= nowTime) {
        break;
      }

      /// 获取缓存中的productId
      final productIDCache = orderInfoMap[_kProductID];

      /// 缓存中的 商品标识 和 传入的商品标识一致,说明有此id订单号
      if (productIDCache == productId) {
        /// 拿到订单号返回
        final orderId = orderInfoMap[_kOrderID];
        return orderId;
      }
    }
    return '';
  }
}

class IAPDataStoreReceipt {
  ///  补单数据的存放文件名
  static const _kReceiptOrderFileName = "fb_Receipt.store";

  // 单个订单验票总次数
  static const _kReceiptOrderTimes = 15;

  /// 保存当前
  static final List _loopCounterList = [];

  /// 获取票据信息
  static Future<Map> getReceiptData() async {
    try {
      final String fileContent =
          await IAPDataStoreHelper.fileRead(fileName: _kReceiptOrderFileName);

      if (fileContent.noValue) {
        return {};
      }
      Map map = {};

      if (fileContent.hasValue) {
        map = jsonDecode(fileContent);
      }

      return map ??= {};
    } catch (e) {
      print(e);
      return {};
    }
  }

  static Future<void> saveReceiptData(
      {@required String receipt,
      @required String orderId,
      @required String productId}) async {
    if (receipt.noValue || orderId.noValue) return;
    final String fileContent =
        await IAPDataStoreHelper.fileRead(fileName: _kReceiptOrderFileName);

    Map map = {};

    if (fileContent.hasValue) {
      map = jsonDecode(fileContent);
    }

    final receiptInfo = {'receipt': receipt, 'productID': productId};

    map[orderId] = receiptInfo;

    /// 把订单票据数据信息转换成string
    final mapString = jsonEncode(map);

    /// 写入文件
    await IAPDataStoreHelper.fileWrite(
        fileName: _kReceiptOrderFileName, contents: mapString);

    /// 保存每单票据验证次数
    await IAPDataStoreReceiptTimes.saveOrderVerifyTimes(
        orderId: orderId, times: _kReceiptOrderTimes);

    /// 停止订单轮训
    IAPRepeatVerifyReceipt.instance.stop();
  }

  /// 根据orderId 删除票据缓存数据
  static Future<void> deleteReceiptData({@required String orderId}) async {
    if (orderId.noValue) return;

    final String fileContent =
        await IAPDataStoreHelper.fileRead(fileName: _kReceiptOrderFileName);

    Map map = {};

    if (fileContent.hasValue) {
      map = jsonDecode(fileContent);
    }

    final orderList = map.keys;

    for (final orderIdItem in orderList) {
      if (orderIdItem == orderId) {
        map.remove(orderId);

        /// 把订单票据数据信息转换成string
        final mapString = jsonEncode(map);

        /// 写入文件
        await IAPDataStoreHelper.fileWrite(
            fileName: _kReceiptOrderFileName, contents: mapString);
        if (map.isEmpty) {
          /// 停止订单轮训
          IAPRepeatVerifyReceipt.instance.stop();
        }
        break;
      }
    }

    /// 删除重试次数
    await IAPDataStoreReceiptTimes.deleteVerifyTimes(orderID: orderId);
  }

  /// 过滤掉当前生命周期中已验证次数到达规定次数的订单
  static Map filterCurrentLifeCycleOrder(Map receiptMap) {
    if (receiptMap.isEmpty) return receiptMap;

    if (_loopCounterList.noValue) return receiptMap;

    final receiptMapTemp = Map.from(receiptMap);

    for (final repeatedItem in _loopCounterList) {
      final String orderId = repeatedItem['order_id'];
      final times = repeatedItem['times'];

      if (orderId.noValue) break;

      for (final orderIdItem in receiptMap.keys) {
        if (orderIdItem == null || orderIdItem.isEmpty) break;

        if (orderIdItem == orderId) {
          if (times >= _kReceiptOrderTimes) {
            receiptMapTemp.remove(orderId);
          }
        }
      }
    }
    return receiptMapTemp;
  }

  /// 当前生命周期中,订单验证次数
  static void countCurrentLifeCycleOrder(String orderId) {
    if (orderId.noValue) return;

    Map repeatedItem = {};
    for (final tmpMap in _loopCounterList) {
      final orderIdItem = tmpMap['order_id'];
      if (orderId == orderIdItem) {
        repeatedItem = tmpMap;
        break;
      }
    }

    if (repeatedItem.isEmpty) {
      repeatedItem['order_id'] = orderId;
      repeatedItem['times'] = 1;
      _loopCounterList.add(repeatedItem);
    } else {
      int times = repeatedItem['times'] as int;
      times = times + 1;
    }
  }
}

/// 票据重试次数
class IAPDataStoreReceiptTimes {
  /// 补单次数前缀
  static const _kReceiptOrderTimesPrefix = "kReceiptOrderTimesPrefix";

  /// 保存重试次数
  /// @param orderID 订单ID
  /// @param times 重试次数
  static Future<void> saveOrderVerifyTimes(
      {@required String orderId, @required int times}) async {
    if (times >= 0) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          _kReceiptOrderTimesPrefix + orderId, times.toString());
    } else {
      int currentTimes = await catchOrderVerifyTimes(orderID: orderId);
      if (currentTimes <= 0) return;
      await saveOrderVerifyTimes(orderId: orderId, times: --currentTimes);
    }
  }

  /// 获取重试次数
  static Future<int> catchOrderVerifyTimes({@required String orderID}) async {
    final prefs = await SharedPreferences.getInstance();

    final timesStr = prefs.getString(_kReceiptOrderTimesPrefix + orderID);

    if (timesStr == null) {
      return 0;
    }
    final times = int.parse(timesStr);
    if (times <= 0) {
      await IAPDataStoreReceiptTimes.deleteVerifyTimes(orderID: orderID);
    }
    return times;
  }

  /// 删除票据次数信息
  static Future<void> deleteVerifyTimes({@required String orderID}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kReceiptOrderTimesPrefix + orderID);
  }
}

/// 文件操作辅助类
class IAPDataStoreHelper {
  /// 文件写入
  static Future<void> fileWrite(
      {@required String fileName, @required String contents}) async {
    File file = await getFileObject(fileName: fileName);

    file = await file.writeAsString(contents);
  }

  /// 读取文件内容
  static Future<String> fileRead({@required String fileName}) async {
    final file = await getFileObject(fileName: fileName);

    final fileContent = await file.readAsString();
    return fileContent;
  }

  /// 获取文件操作对象
  static Future<File> getFileObject({@required String fileName}) async {
    final appDocDir = await getApplicationDocumentsDirectory();
    final appDocPath = p.join(appDocDir.path, fileName);

    final file = File(appDocPath);

    if (!appDocDir.existsSync()) {
      appDocDir.createSync(recursive: true);
    }

    final isExist = file.existsSync();

    logger.info('$fileName 文件是否存在: $isExist');
    //如果文件存在，删除
    if (!isExist) {
      //创建文件
      file.createSync(recursive: true);
    }
    return file;
  }
}
