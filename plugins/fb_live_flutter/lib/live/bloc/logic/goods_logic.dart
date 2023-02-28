import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:fb_live_flutter/fb_live_flutter.dart';
import 'package:fb_live_flutter/live/api/fblive_provider.dart';
import 'package:fb_live_flutter/live/bloc_model/shop_bloc_model.dart';
import 'package:fb_live_flutter/live/bloc_model/user_join_live_room_model.dart';
import 'package:fb_live_flutter/live/event_bus_model/goods/goods_push_rm_model.dart';
import 'package:fb_live_flutter/live/model/goods/goods_add.dart';
import 'package:fb_live_flutter/live/model/goods/goods_push_model.dart';
import 'package:fb_live_flutter/live/net/api.dart';
import 'package:fb_live_flutter/live/pages/live_room/interface/live_interface.dart';
import 'package:fb_live_flutter/live/utils/func/utils_class.dart';
import 'package:fb_live_flutter/live/utils/log/coupons_log_up.dart';
import 'package:fb_live_flutter/live/utils/log/goods_log_up.dart';
import 'package:fb_live_flutter/live/utils/other/goods_util.dart';
import 'package:fb_live_flutter/live/widget_common/dialog/sw_dialog.dart';
import 'package:flutter/cupertino.dart';

class GoodsLogicValue {
  static bool? isAssistantValue;
}

mixin GoodsLogic on LiveInterface {
  int? shopId;

  bool? isAssistantValue;
  bool openCommerce = false;

  GoodsPushModel? pushModel;

  final Queue<GoodsPushModel> goodsQueue = Queue<GoodsPushModel>();

  PushGoodsLiveRoomModel? pushGoodsLiveRoomModel;
  ShopBlocModelQuick? shopBlocModelQuick;
  CouponsBlocModelQuick? couponsBlocModelQuick;

  /*
  * 获取直播间优惠券数量
  * */
  Future liveCouponCount(String roomId) async {
    /// 请求获取优惠券数量接口
    final Map resultData = await Api.liveCouponCount(0, roomId);

    if (resultData["code"] == 200) {
      /// 获取到的优惠券数量
      final int count = resultData["data"]["count"];

      if (count > 0) {
        /// 如果大于0则优惠券入口显示，否则不去触发
        couponsBlocModelQuick!.add(CouponsState(isShowCoupons: true));

        /// 如果没有上报优惠券入口显示日志才去上报，
        /// 防止出现切换小窗口再进入直播间重复上报。
        if (!liveValueModel!.isUpLogCoupons) {
          /// 上报日志
          await CouponsLogUp.pushCouponsShow(
              roomInfoObject: getRoomInfoObject!);

          /// 标识已经上报
          liveValueModel!.isUpLogCoupons = true;
        }
      }

      /// 清除主要是防止被刷新后数量重置
      /// 如：唤起键盘
      await Future.delayed(const Duration(milliseconds: 100));
      couponsBlocModelQuick!.add(CouponsState());
    }
  }

  /*
  * 商品收到推送处理
  * */
  Future<void> onGoodsNoticeHandle(FBUserInfo user, String type, String json,
      bool? isAnchor, String? roomId) async {
    if (type == "productRemove") {
      goodsPushRmBus.fire(GoodsPushRmModel());
      await Future.delayed(const Duration(milliseconds: 600)).then((value) {
        final goodsMsgModel = GoodsPushModel(
          expiredTime: DateTime.now().toString(),
          countdown: 0,
        );
        goodsQueue.addLast(goodsMsgModel);
        pushGoodsLiveRoomModel!.add(GoodsPushModel());
      });
      return;
    }
    if (type == "couponPush") {
      if (isAnchor! || (isAssistantValue ?? false)) {
        return;
      }

      /// 【新】2021 12.17 直接显示优惠券入口，收到推送就一定是有优惠券，
      /// 没必要再去取接口数据了。
      couponsBlocModelQuick!.add(CouponsState(isShowCoupons: true));
      return;
    }

    final goodsMsgModel = GoodsPushModel.fromJson(jsonDecode(json));
    goodsQueue.addLast(goodsMsgModel);
    pushGoodsLiveRoomModel!.add(GoodsPushModel());

    /// (直播间页)推送商品卡片曝光;[日志上报]
    final GoodsListModel goodsListModel = GoodsListModel(
      detailUrl: goodsMsgModel.detailUrl,
      itemId: goodsMsgModel.itemId,
      title: goodsMsgModel.title,
      price: goodsMsgModel.price,
      origin: goodsMsgModel.origin,
    );
    await GoodsLogUp.pushProductShow(goodsListModel, goodsMsgModel.index,
        roomInfoObject: getRoomInfoObject!);
  }

  /// 授权有赞
  ///
  /// @王增阳  与俊杰沟通，用户授权配置，为了我们自己前端测试[11.9]
  Future<void> authCheck(BuildContext context, VoidCallback onTap) async {
    if (configProvider.openAuthorization) {
      final value = await Api.youZanCheckAuth(shopId);
      if (value['data']['auth']) {
        onTap();
      } else {
        await confirmSwDialog(context, text: '您未授权信息到"有赞商城"', okText: '去授权',
            onPressed: () async {
          await fbApi.pushLinkPage(context,
              GoodsUtil.joinMiniProgramSuffix(value['data']['jumpUrl']),
              title: "授权认证");
        });
      }
    } else {
      onTap();
    }
  }

  /*
  * 直播带货系列接口
  * */
  Future<void> goodsApi(String roomId, FBLiveMsgHandler liveRoomBloc) async {
    /// 没有开启直播带货功能直接返回
    if (!openCommerce) {
      return;
    }

    /// 获取直播间带货信息（直播带货2.0）
    ///
    /// 【2022 01.03】
    /// [x] 直播带货系列api部分不需要等待
    await commerce2(roomId, onComplete: () async {
      /// 有直播带货，去获取数量
      await liveGoodsGetCount(roomId);

      /// 获取直播间推荐商品（直播带货2.0）
      await liveGoodsGetRecommend(roomId, liveRoomBloc);

      /// 获取优惠券数量
      await liveCouponCount(roomId);
    });
  }

  /// 43. 获取直播间带货信息（直播带货2.0）
  Future commerce2(String? roomId, {VoidCallback? onComplete}) async {
    if (!strNoEmpty(roomId)) {
      return;
    }
    if (shopId != null && shopId != 0) {
      return;
    }

    /// 获取直播间带货信息【New】
    final Map status = await Api.commerce2(roomId!);
    if (status["code"] == 200) {
      shopId = status['data']['shopId'];

      /// 直播间带货信息接口调用流程，先检查直播间是否开启带货，
      /// 再拿到商铺ID，只能拿到商铺ID后，才可把后面接口调用，
      /// 并且显示出货架和优惠券ICO。【优惠卷】开播，立马点优惠卷，打不开
      if (onComplete != null) {
        onComplete();
      }
    }
  }

  // 44. 是否是直播小助手
  Future<bool> isAssistant(String? roomId) async {
    if (!strNoEmpty(roomId)) {
      return false;
    }
    final Map status = await Api.isAssistant(roomId!);
    if (status["code"] == 200) {
      try {
        return status['data']["assistant"];
      } catch (e) {
        return false;
      }
    } else {
      return false;
    }
  }

  /*
  * 获取直播间商品数量
  * */
  Future liveGoodsGetCount(String roomId) async {
    final Map resultData = await Api.liveGoodsGetCount(roomId);
    if (resultData["code"] == 200) {
      final int? count = resultData["data"]["count"];

      /// 【2021 12.28】
      /// 4.横屏点击货架自动切换成竖屏再切换成横屏，货架数量没显示
      shopBlocModelQuick!.add(ShopState(count: count ?? 0));

      /// 清除主要是防止被刷新后数量重置
      /// 【APP】带货主播唤起键盘时，图标上的商品总数变为0
      await Future.delayed(const Duration(milliseconds: 100));
      shopBlocModelQuick!.add(ShopState());
    }
  }

  /*
  * 获取直播间推荐商品
  * */
  Future liveGoodsGetRecommend(
      String roomId, FBLiveMsgHandler liveRoomBloc) async {
    final Map resultData = await Api.liveGoodsGetRecommend(roomId);
    if (resultData["code"] == 200) {
      pushModel = GoodsPushModel.fromJson(resultData['data']);
      liveRoomBloc.onGoodsNotice(
          await fbApi.getUserInfo(fbApi.getUserId()!,
              guildId: getRoomInfoObject!.serverId),
          "productPush",
          json.encode(pushModel));
    }
  }
}
