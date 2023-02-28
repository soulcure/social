import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:im/pages/ledou/model/ledou_model.dart';
import 'package:im/pages/ledou/widgets/custom_view_pager.dart';
import 'package:im/pages/ledou/widgets/transaction_list_view.dart';
import 'package:im/widgets/app_bar/custom_appbar.dart';
import 'package:im/widgets/default_tip_widget.dart';

import '../../icon_font.dart';

class LedouTransactionPage extends StatelessWidget {
  final topUpModel = TopUpModel();
  final consumptionModel = ConsumptionModel();

  @override
  Widget build(BuildContext context) {
    // final ThemeData _theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppbar(
        title: '乐豆明细'.tr,
      ),
      body: CustomViewPager(
        tabs: [
          CustomTab("充值明细".tr),
          CustomTab("消费明细".tr),
        ],
        pages: [
          _buildTopUpView(),
          _buildConsumptionView(),
        ],
      ),
    );
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
  }

  /// 构建充值明细页面
  Widget _buildTopUpView() {
    return TransactionListView(
      adapter: topUpModel,
      emptyView: _buildEmptyView(),
    );
  }

  /// 构建消费明细页面
  Widget _buildConsumptionView() {
    return TransactionListView(
      adapter: consumptionModel,
      emptyView: _buildEmptyView(),
    );
  }
}
