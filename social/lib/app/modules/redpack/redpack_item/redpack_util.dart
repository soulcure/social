import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:im/app/modules/redpack/redpack_item/redpack_info_ben.dart';
import 'package:im/app/modules/redpack/redpack_item/redpack_item_bean.dart';

class RedPackUtil {
  static final RedPackUtil _singleton = RedPackUtil._internal();

  Box<RedPackItemBean> redPackBox;

  factory RedPackUtil() {
    return _singleton;
  }

  RedPackUtil._internal();

  ///open hive box for redPack
  Future<void> initBox() async {
    if (redPackBox == null || !redPackBox.isOpen) {
      final redPackInfoBeanAdapter = RedPackInfoBeanAdapter();
      if (!Hive.isAdapterRegistered(redPackInfoBeanAdapter.typeId)) {
        Hive.registerAdapter(redPackInfoBeanAdapter);
      }

      final redPackItemBeanAdapter = RedPackItemBeanAdapter();
      if (!Hive.isAdapterRegistered(redPackItemBeanAdapter.typeId)) {
        Hive.registerAdapter(redPackItemBeanAdapter);
      }
      redPackBox = await Hive.openBox<RedPackItemBean>("redPackItemBean");
      debugPrint("RedPack initBox RedPackItemBean isOpen=${redPackBox.isOpen}");
    }
  }

  ///抢红包完成后，存储抢红包结果到hive
  void putRedPack(String channelId, String messageId, String redPackId,
      int status, String subMoney) {
    final RedPackInfoBean bean = RedPackInfoBean(
      messageId: messageId,
      id: redPackId,
      status: status,
      subMoney: subMoney,
    );
    RedPackItemBean packItemBean = redPackBox.get(channelId);
    if (packItemBean != null) {
      final res = packItemBean.redPackInfoList
          .firstWhere((e) => e.messageId == messageId, orElse: () => null);
      if (res != null) {
        res.status = status;
        res.subMoney = subMoney;
      } else {
        packItemBean.redPackInfoList.add(bean);
      }
    } else {
      final List<RedPackInfoBean> redPackInfoList = [bean];
      packItemBean = RedPackItemBean(
          channelId: channelId, redPackInfoList: redPackInfoList);
    }

    redPackBox.put(channelId, packItemBean);
  }

  ///获取存储在hive的红包状态
  int getRedPackStatus(
      Box<RedPackItemBean> box, String channelId, String messageId) {
    int status = 0;
    final RedPackItemBean packItemBean = box.get(channelId);
    if (packItemBean != null) {
      final res = packItemBean.redPackInfoList
          .firstWhere((e) => e.messageId == messageId, orElse: () => null);
      if (res != null) {
        status = res.status;
      }
    }
    return status;
  }

  ///通过红包id获取存储在本地的红包状态
  int openRedPackStatus(String channelId, String redPackId) {
    int status = 0;
    final RedPackItemBean packItemBean = redPackBox.get(channelId);
    if (packItemBean != null) {
      final res = packItemBean.redPackInfoList
          .firstWhere((e) => e.id == redPackId, orElse: () => null);
      if (res != null) {
        status = res.status;
      }
    }
    return status;
  }

  ///获取存储在hive的红包金额
  String getRedPackMoney(String channelId, String redPackId) {
    String subMoney = '';
    final RedPackItemBean packItemBean = redPackBox.get(channelId);
    if (packItemBean != null) {
      final res = packItemBean.redPackInfoList
          .firstWhere((e) => e.id == redPackId, orElse: () => null);
      if (res != null) {
        subMoney = res.subMoney;
      }
    }
    return subMoney;
  }

  ///监听：红包状态
  ValueListenable redPackValueListenable(String channelId) {
    return redPackBox.listenable(keys: [channelId]);
  }
}
