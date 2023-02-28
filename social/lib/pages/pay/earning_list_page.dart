import 'package:fb_live_flutter/fb_live_flutter.dart';
import 'package:get/get.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:im/pages/ledou/detail_page.dart';
import 'package:im/pages/ledou/model/entity.dart';
import 'package:im/pages/ledou/widgets/detail_item.dart';
import 'package:im/widgets/app_bar/custom_appbar.dart';
import 'package:im/widgets/default_tip_widget.dart';
import 'package:im/widgets/refresh/list_model.dart';
import 'package:im/widgets/refresh/refresh.dart';

import '../../global.dart';
import '../../icon_font.dart';
import '../../routes.dart';

class EarningListModel extends ListModel<TransactionEntity> {
  EarningListModel() {
    pageSize = 20;
    fetchData = _earningData;
    // fetchData = _mockData;
  }

  Future<List<TransactionEntity>> _earningData() async {
    final res = await JiGouLiveAPI.tradeList(3, Global.user.id, pageNum,
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
              TransactionType.earning, r.amount, r.merchandiseName);
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
  //     (index) {
  //       return TransactionEntity(
  //         "order${pageNum * pageSize + index}",
  //         DateTime.now(),
  //         TransactionType.earning,
  //         5,
  //         "鲜花",
  //       );
  //     },
  //   );
  // }

}

class EarningListPage extends StatefulWidget {
  @override
  _EarningListPageState createState() => _EarningListPageState();
}

class _EarningListPageState extends State<EarningListPage> {
  final model = EarningListModel();

  @override
  void initState() {
    super.initState();
  }

  Widget _buildEmptyView() {
    return Container(
      color: Colors.white,
      alignment: Alignment.center,
      padding: const EdgeInsets.only(bottom: 100),
      child: DefaultTipWidget(
        icon: IconFont.buffPayNoRecord,
        iconSize: 40,
        iconBackgroundColor: const Color(0xFFF5F5F8),
        iconColor: const Color(0xFF8F959E).withOpacity(0.65),
        text: '暂无记录'.tr,
      ),
    );
    // return SliverFillViewport(
    //   delegate: SliverChildBuilderDelegate(
    //         (context, index) => Container(
    //       alignment: Alignment.center,
    //       padding: const EdgeInsets.only(bottom: 100),
    //       child: DefaultTipWidget(
    //         icon: IconFont.buffChatPin,
    //         iconSize: 34,
    //         iconBackgroundColor: Theme.of(context).backgroundColor,
    //         text:'暂无记录'.tr,
    //       ),
    //     ),
    //     childCount: 1,
    //   ),
    // );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: CustomAppbar(
        title: '收益明细'.tr,
      ),
      body: Container(color: Colors.white, child: _buildEarnListView()),
    );
  }

  /// 构建消费明细页面
  Widget _buildEarnListView() {
    return Refresher(
      builder: (_) {
        if (model.length <= 0) {
          return _buildEmptyView();
        } else {
          return ListView.builder(
            itemCount: model.length,
            itemBuilder: (_, i) {
              final data = model.list[i];
              return TransactionItem(data, onTap: () {
                Routes.pushLedouDetailPage(
                    TransactionDetailViewModel(data.orderNum));
              });
            },
          );
        }
      },
      model: model,
    );
  }
}
