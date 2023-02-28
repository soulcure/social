import 'dart:async';

import 'package:fb_live_flutter/live/api/fblive_provider.dart';
import 'package:fb_live_flutter/live/net/api.dart';
import 'package:fb_live_flutter/live/pages/coupons/widget/coupons_card.dart';
import 'package:fb_live_flutter/live/utils/live/base_bloc.dart';
import 'package:fb_live_flutter/live/utils/theme/my_toast.dart';
import 'package:flutter/material.dart';
import 'package:oktoast/oktoast.dart';

class CouponsCardBloc extends BaseAppCubit<int> with BaseAppCubitState {
  CouponsCardBloc() : super(0);

  State<CouponsCard>? statePage;

  BuildContext? get context {
    return statePage?.context ?? fbApi.globalNavigatorKey.currentContext;
  }

  /// 店铺Id
  int? get shopId {
    return statePage!.widget.item!.shopId;
  }

  /// 优惠券Id
  int? get activityId {
    return statePage!.widget.item!.id;
  }

  void init(State<CouponsCard> state) {
    statePage = state;

    return;
  }

  /*
  * 领取优惠券处理
  * */
  Future<void> receiveHandle() async {
    /// 【2021 11.24】【优惠券列表】点击立即领取【领取中】提示 应：（不需要提示
    // myLoadingToast(tips: "领取中");

    /// 【2021 11.21】不能主动去检测库存了，要完全靠状态码来，
    /// 否则会出现领取过后重新打开对话框再点领取没法到已领取状态了，
    /// 会提示库存为0
    ///
    /// 问题：修复领取优惠券过后下次领提示库存为0
    ///
    /// 【2021 11.22】去掉观众端点击库存为0的商品之后的toast提示。保持原有查询检测流程
    ///
    final int? stockValue = await shopCouponStock();
    if (stockValue == null) {
      return;
    }
    if (stockValue <= 0) {
      dismissAllToast();

      /// 优惠券卡片状态设置为库存不足
      statePage!.widget.item!.status = CouponsStatus.gone;
      onRefresh();
      return;
    }
    return liveCouponSend();
  }

  /*
  * 查询优惠券库存数量【Api】
  * */
  Future<int?> shopCouponStock() async {
    final value = await Api.shopCouponStock(shopId, activityId);
    if (value['code'] != 200) {
      return null;
    }
    return value['data']['stock'] ?? 0;
  }

  /*
  * 库存不足相应处理
  * */
  void stockNot(Map value) {
    /// 700=处理库存不足ui效果
    if (value['code'] == 700) {
      /// 优惠券卡片状态设置为库存不足
      statePage!.widget.item!.status = CouponsStatus.gone;
      onRefresh();
    } else if (value['code'] == 701) {
      /// 优惠券卡片状态设置为已经领取
      ///
      /// 优惠券领取过的，库存的响应码  优惠券列表状态更新的问题及方案
      statePage!.widget.item!.status = CouponsStatus.received;
      onRefresh();
    }
  }

  /*
  * 用户领取直播间优惠券【Api】
  * */
  Future<void> liveCouponSend() async {
    final value = await Api.liveCouponSend(
        activityId, statePage!.widget.roomInfoObject.roomId);
    if (value['code'] != 200) {
      stockNot(value);
      return;
    }

    dismissAllToast();
    statePage!.widget.item!.status = CouponsStatus.received;
    onRefresh();
    mySuccessToast("领取成功");
  }

  @override
  Future<void> close() {
    return super.close();
  }
}
