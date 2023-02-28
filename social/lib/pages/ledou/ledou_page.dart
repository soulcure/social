import 'dart:async';

import 'package:fb_live_flutter/fb_live_flutter.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/core/widgets/button/fade_background_button.dart';
import 'package:im/icon_font.dart';
import 'package:im/live_provider/live_api_provider.dart';
import 'package:im/pages/ledou/widgets/custom_view_pager.dart';
import 'package:im/routes.dart';
import 'package:im/themes/const.dart';
import 'package:im/utils/universal_platform.dart';
import 'package:im/widgets/app_bar/custom_appbar.dart';

import '../../loggers.dart';

/// 乐豆（虚拟币）页面
class LeDouPage extends StatefulWidget {
  @override
  _LeDouPageState createState() => _LeDouPageState();
}

class _LeDouPageState extends State<LeDouPage> with WidgetsBindingObserver {
  /// 乐豆额度
  int chargeBalance = 0;

  /// 收益额度
  double profitBalance = 0;

  /// 用来做支付成功后刷新机制的计时器
  Timer _timer;

  /// 标记是否成功获取到了乐豆信息
  bool _isGetLeDouInfo = false;

  /// 计时器循环次数
  int _timerCount = 0;

  @override
  void initState() {
    super.initState();
    if (UniversalPlatform.isAndroid) {
      WidgetsBinding.instance.addObserver(this);
    }
    _isGetLeDouInfo = false;
    getLeDouInfo();
  }

  @override
  void dispose() {
    if (UniversalPlatform.isAndroid) {
      WidgetsBinding.instance.removeObserver(this);
    }
    if (_timer != null) {
      _timer.cancel();
      _timer = null;
    }
    super.dispose();
  }

  // 页面的生命周期，是否在前台或者后台的判断
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (UniversalPlatform.isAndroid) {
      switch (state) {
        case AppLifecycleState.inactive: // 处于这种状态的应用程序应该假设它们可能在任何时候暂停。
          break;
        case AppLifecycleState.resumed: // 应用程序可见，前台
          refreshLeDouInfo();
          break;
        case AppLifecycleState.paused: // 应用程序不可见，后台
          break;
        case AppLifecycleState.detached:
          break;
      }
    }
  }

  /// 从服务端获取乐豆信息
  void getLeDouInfo() {
    JiGouLiveAPI.accountInfo().then((value) {
      if (value["code"] == 200) {
        logger.info('乐豆 -- 充值日志  $value');
        final data = value["data"];
        final chargeBalanceTemp = int.parse(data["balance"]);
        final profitBalanceTemp = double.parse(data["incomeBalance"]);

        /// 如果值相同就不错任何处理
        if (chargeBalance == chargeBalanceTemp &&
            profitBalance == profitBalanceTemp) {
          return;
        }
        chargeBalance = chargeBalanceTemp;
        profitBalance = profitBalanceTemp;
        _isGetLeDouInfo = true;
        setState(() {});
      }
    });
  }

  /// 充值成功刷新乐豆信息
  void refreshLeDouInfo() {
    /// 重置状态
    _isGetLeDouInfo = false;
    _timerCount = 0;
    _timer?.cancel();

    const timeInterval = Duration(seconds: 2);

    _timer = Timer.periodic(timeInterval, (timer) {
      _timerCount++;
      // 成功获取或者获取超过3次停止计时器
      if (_isGetLeDouInfo == true || _timerCount > 3) {
        _timer.cancel();
      } else {
        getLeDouInfo();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppbar(
        title: '乐豆'.tr,
      ),
      backgroundColor: Colors.white,
      body: CustomViewPager(
        tabs: [
          CustomTab("充值".tr),
          CustomTab("收益".tr),
        ],
        pages: [
          _buildChargeView(context),
          _buildProfitView(),
        ],
      ),
    );
  }

  /// 构建充值页面
  Widget _buildChargeView(BuildContext context) {
    //TODO: 替换成真实的数据源
    const textBlack = Color(0xFF363940);
    const green = Color(0xFF00B34A);
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 80),
          child: Icon(
            IconFont.buffLedouFill,
            size: 48,
            color: green,
          ),
        ),
        sizeHeight16,
        Text(
          "我的乐豆".tr,
          style: const TextStyle(fontSize: 16, color: textBlack, height: 1.25),
        ),
        sizeHeight24,
        Text(
          chargeBalance.toString(),
          style: const TextStyle(
              fontSize: 48,
              color: textBlack,
              height: 1.08,
              fontWeight: FontWeight.w500),
        ),
        _gotoDetailText("乐豆明细".tr, Routes.pushLedouTransactionPage),
        const Expanded(child: sizedBox),
        FadeBackgroundButton(
          onTap: () => FBLiveApiProvider.instance.showPayBottomSheet(
            context,
            callback: (paymentResult) {
              if (UniversalPlatform.isIOS &&
                  paymentResult.status != PaymentStatus.cancel) {
                refreshLeDouInfo();
              }
            },
          ),
          backgroundColor: green,
          borderRadius: 4,
          width: 184,
          height: 40,
          padding: const EdgeInsets.symmetric(vertical: 9.5),
          tapDownBackgroundColor: green.withOpacity(0.8),
          child: Text(
            "充值".tr,
            style: const TextStyle(
                fontSize: 17, color: Colors.white, height: 1.23),
          ),
        ),
        const SizedBox(height: 100),
      ],
    );
  }

  /// 构建收益页面
  Widget _buildProfitView() {
    const textBlack = Color(0xFF363940);
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 80),
          child: Icon(
            IconFont.buffLedouFill,
            size: 48,
            color: Color(0xFFF2AA19),
          ),
        ),
        sizeHeight16,
        Text(
          "总收益".tr,
          style: const TextStyle(fontSize: 16, color: textBlack, height: 1.25),
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "￥".tr,
              style: const TextStyle(
                  color: textBlack,
                  fontSize: 34,
                  fontWeight: FontWeight.w600,
                  height: 1.29),
            ),
            Text(
              (profitBalance / 10).toStringAsFixed(2),
              style: const TextStyle(
                  fontSize: 48,
                  color: textBlack,
                  fontWeight: FontWeight.w600,
                  height: 1.08),
            ),
          ],
        ),
        sizeHeight6,
        Text(
          "乐豆 %s".trArgs([profitBalance.toString()]),
          style: const TextStyle(fontSize: 16, color: textBlack, height: 1.25),
        ),
        // sizeHeight16,
        _gotoDetailText("收益明细".tr, Routes.pushEarningListPage),
      ],
    );
  }

  /// 跳转到详情页的文本组件
  Widget _gotoDetailText(String text, VoidCallback gotoDetail) {
    const textGray = Color(0xFF8F959E);
    return GestureDetector(
      onTap: gotoDetail,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // const MoreIcon(
            //   size: 12,
            //   color: Colors.transparent,
            // ),
            const Icon(
              IconFont.buffPayArrowNext,
              size: 12,
              color: Colors.transparent,
            ),
            sizeWidth2,
            Text(
              text,
              style:
                  const TextStyle(color: textGray, fontSize: 14, height: 1.14),
            ),
            sizeWidth2,
            const Icon(
              IconFont.buffPayArrowNext,
              size: 12,
              color: textGray,
            ),
            // const MoreIcon(
            //   size: 12,
            //   color: textGray,
            // ),
          ],
        ),
      ),
    );
  }
}
