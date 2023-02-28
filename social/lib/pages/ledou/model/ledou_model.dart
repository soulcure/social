import 'package:fb_live_flutter/fb_live_flutter.dart';
import 'package:im/pages/ledou/model/entity.dart';
import 'package:im/pages/ledou/widgets/transaction_list_view.dart';

import '../../../global.dart';

/// 获取充值记录的model
class TopUpModel extends TransactionListViewAdapter<TransactionEntity> {
  TopUpModel() {
    pageSize = 20;
    fetchData = _topUpData;
    // fetchData = _mockData;
  }

  Future<List<TransactionEntity>> _topUpData() async {
    final res = await JiGouLiveAPI.tradeList(1, Global.user.id, pageNum,
        pageSize: pageSize);
    try {
      if (res["code"] == 200) {
        final data = res["data"];
        // final pageNum = data["pageNum"];
        // final pageSize = data["pageSize"];
        // final total = data["total"];
        // final pageCount = data["pageCount"];
        final result = data["result"] as List;
        return result.map((e) {
          final r = AccountDetailAdminView(e);
          return TransactionEntity(r.id.toString(), r.createdAt,
              TransactionType.topUp, r.amount, r.merchandiseName);
        }).toList();
      }
      return null;
    } catch (e) {
      return null;
    }
  }

// Future<List<TransactionEntity>> _mockData() async {
//   await Future.delayed(const Duration(seconds: 1));
//   return List.generate(
//     pageSize,
//     (index) => TransactionEntity(
//       "order${pageNum * pageSize + index}",
//       DateTime.now(),
//       TransactionType.topUp,
//       10,
//       "鲜花",
//     ),
//   );
// }

// @override
// TransactionDetailViewModel convert2Detail(TopUpEntity data) {
//   return TransactionDetailViewModel("充值详情".tr, "充值".tr, "+${data.ledou}", [
//     DetailItemViewModel("订单号".tr, data.orderNum),
//     DetailItemViewModel("交易类型".tr, "充值".tr),
//     // DetailItemViewModel("金额".tr, "${data.amount}元"),
//     DetailItemViewModel("交易时间".tr, formatDetailDate(data.date)),
//   ]);
// }
}

/// 获取消费记录的model
class ConsumptionModel extends TransactionListViewAdapter<TransactionEntity> {
  ConsumptionModel() {
    pageSize = pageSize;
    fetchData = _consumptionData;
    // fetchData = _mockData;
  }

  Future<List<TransactionEntity>> _consumptionData() async {
    final res = await JiGouLiveAPI.tradeList(2, Global.user.id, pageNum,
        pageSize: pageSize);
    if (res["code"] == 200) {
      final data = res["data"];
      // final pageNum = data["pageNum"];
      // final pageSize = data["pageSize"];
      // final total = data["total"];
      // final pageCount = data["pageCount"];
      final result = data["result"] as List;
      return result.map((e) {
        final r = AccountDetailAdminView(e);
        return TransactionEntity(r.id.toString(), r.createdAt,
            TransactionType.consumption, r.amount, r.merchandiseName);
      }).toList();
    }

    return null;
  }

// Future<List<TransactionEntity>> _mockData() async {
//   await Future.delayed(const Duration(seconds: 1));
//   return List.generate(
//     pageSize,
//     (index) {
//       return TransactionEntity("order${pageNum * pageSize + index}",
//           DateTime.now(), TransactionType.consumption, 5, "鲜花");
//     },
//   );
// }

// @override
// TransactionDetailViewModel convert2Detail(ConsumptionEntity data) {
//   return TransactionDetailViewModel(
//     "消费详情".tr,
//     "送出-${data.gift}",
//     "-${data.unitPrice * data.quantity}",
//     [
//       DetailItemViewModel("订单号".tr, data.orderNum),
//       DetailItemViewModel("交易类型".tr, "直播打赏".tr),
//       DetailItemViewModel("礼物名称".tr, data.gift),
//       DetailItemViewModel("单价".tr, "${data.unitPrice}乐豆"),
//       DetailItemViewModel("数量".tr, data.quantity.toString()),
//       DetailItemViewModel("所在直播间".tr, data.liveRoom, maxLine: 2),
//       DetailItemViewModel("主播昵称".tr, data.streamer, maxLine: 2),
//       DetailItemViewModel("交易时间".tr, formatDetailDate(data.date)),
//     ],
//   );
// }
}
