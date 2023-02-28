import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:fb_live_flutter/live/api/fblive_provider.dart';
import 'package:fb_live_flutter/live/event_bus_model/goods_html_bus.dart';
import 'package:fb_live_flutter/live/model/goods/goods_push_model.dart';
import 'package:fb_live_flutter/live/model/room_infon_model.dart';
import 'package:fb_live_flutter/live/net/api.dart';
import 'package:fb_live_flutter/live/pages/goods/widget/goods_card.dart';
import 'package:fb_live_flutter/live/utils/live/base_bloc.dart';
import 'package:fb_live_flutter/live/utils/theme/my_toast.dart';
import 'package:flutter/material.dart';
import 'package:oktoast/oktoast.dart';

///
/// 【2021 11.18】正在推送的商品，允许被移除，移除的同时取消推送
///
/// 怎么做【主播端逻辑】？
/// 1.取消当点击管理时默认取消上次已选择的数据；
/// 2.取消全选当中对推荐中的商品判断；
/// 3.取消商品管理中选择商品时的【商品是否正在推荐中】判断，让其可选；
/// 4.当选择移除的商品包含推荐的商品则发送一条【取消推送商品】消息；
/// 5.暂停倒计时，倒计时的描述设置为0；
///
/// 怎么做【观众端逻辑】？
/// 1.当收到取消商品推送消息时移除商品推送消息队列及动画；
///
///
/// 影响范围有哪些？
/// 1。点击管理；
/// 2。全选；
/// 3。点击选择；
///
///
/// ==================================================================
/// 【2021 11.13】【APP】主播和助手同时推送不同商品，主播和助手显示的推送不一致
///
/// 旧版回答：
/// 这个是没问题的，会保持最新的商品；但如果同时点击推送的话是有概率会互相抵掉收到的商品信息然后显示自己推送的，这种概率也非常小，
///
/// 新版决策：
/// 主播推送的权重大于小助手，所以延时200毫秒，如同时推送则覆盖小助手推送
///

abstract class GoodsPushLogicRoom {
  RoomInfon get roomInfoObjectValue;
}

mixin GoodsPushLogic
    on BaseAppCubit<int>, BaseAppCubitState, GoodsPushLogicRoom {
  Timer? timer;
  bool inCountdown = false;

  int? count = 0;

  /// 【APP】点击推送商品，上一个商品推送倒计时未重置
  int? currentPushID;

  /// 是否正在推送中
  bool isPushing = false;

  void cancel() {
    timer?.cancel();
    timer = null;
  }

  void start() {
    cancel();
    timer = Timer.periodic(const Duration(milliseconds: 1000), (timer) {
      if (count! <= 0) {
        inCountdown = false;
        onRefresh();
        return;
      }

      var _count = count;
      if (_count != null) {
        _count--;
        count = _count;
      }

      onRefresh();
    });
  }

  /// 初始化开始倒计时
  /// 商品可推送列表中初始化赋值倒计时[2021 11.11]
  Future<void> initStartCount(String roomId) async {
    final Map resultData = await Api.liveGoodsGetRecommend(roomId);
    if (resultData["code"] == 200) {
      final GoodsPushModel pushModel =
          GoodsPushModel.fromJson(resultData['data']);
      count = pushModel.countdown;
      currentPushID = pushModel.itemId;
      start();
    }
  }

  /// 刷新推送状态
  void refreshPushStatus(GoodsPushCard widget) {
    /// 【2021 11.24】取消倒计时系列
    /// 修复倒计时一直为60的问题及推送了两个的问题
    /// 【APP】取消推送，同时推送两个
    ///
    /// 正确方式：
    /// 1.点击第二个商品推送的时候，第一个商品不应该有延迟取消推送
    widget.manageBloc.inCountdown = false;
    widget.manageBloc.count = 0;
    widget.manageBloc.cancel();
    widget.manageBloc.currentPushID = null;
    widget.manageBloc.onRefresh();
  }

  Future actionPush(String e, State<GoodsPushCard> thisState,
      {VoidCallback? onComplete, VoidCallback? onCardRefresh}) {
    return liveGoodsRecommend(thisState, onComplete, onCardRefresh);
  }

  /// 取消推送中转方法
  Future cancelPush(String e, State<GoodsPushCard> thisState,
      {VoidCallback? onComplete, VoidCallback? onCardRefresh}) {
    return liveGoodsRecommendCancel(thisState, onComplete, onCardRefresh);
  }

  /*
  * 取消推荐直播间商品[post]
  * */
  Future liveGoodsRecommendCancel(State<GoodsPushCard> thisState,
      VoidCallback? onComplete, VoidCallback? onCardRefresh) async {
    final widget = thisState.widget;

    /// 【2021 11.24】应：（不需要提示
    // myLoadingToast(tips: "正在取消");
    final Map resultData =
        await Api.goodsCancelRecommend(roomInfoObjectValue.roomId);
    if (resultData["code"] == 200) {
      const String type = "productRemove";

      final goodsCancelPushJson = json.encode({
        "content": type,
        "currentPushID": currentPushID,
      });

      /// 推送给观众
      await fbApi.sendGoodsNotice(
        roomInfoObjectValue.serverId,
        roomInfoObjectValue.channelId,
        roomInfoObjectValue.roomId,
        type,
        goodsCancelPushJson,
      );

      /// 主播推送的权重大于小助手，如同时推送则覆盖小助手推送
      if (widget.manageBloc.statePage!.widget.isAnchor!) {
        await Future.delayed(const Duration(milliseconds: 200));
      }

      /// 推送给自己
      goodsAnchorPushBus.fire(
        GoodsPushEvenModel(
          json: goodsCancelPushJson,
          user: await fbApi.getUserInfo(fbApi.getUserId()!,
              guildId: roomInfoObjectValue.serverId),
          type: type,
        ),
      );

      await Future.delayed(const Duration(milliseconds: 500)).then((value) {
        dismissAllToast();

        /// 【2021 11.24】应：（不需要提示
        // mySuccessToast("取消成功");

        /// 取消倒计时系列
        inCountdown = false;
        count = 0;
        cancel();

        if (onComplete != null) {
          onComplete();
        }
      });
    } else {
      /// 处理库存不足
      stockNot(thisState, resultData, onCardRefresh);
    }
  }

  /*
  * 推荐直播间商品[post]
  * */
  Future liveGoodsRecommend(State<GoodsPushCard> thisState,
      VoidCallback? onComplete, VoidCallback? onCardRefresh) async {
    final widget = thisState.widget;

    /// 【2021 11.24】应：（不需要提示
    // myLoadingToast(tips: "正在推送");
    final Map resultData = await Api.liveGoodsRecommend(
        roomInfoObjectValue.roomId, widget.item.itemId, widget.rank);
    if (resultData["code"] == 200) {
      final String goodsPushJson = json.encode(GoodsPushModel(
        title: widget.item.title ?? '',
        expiredTime: DateTime.now().add(const Duration(seconds: 60)).toString(),
        index: widget.rank,
        shopId: widget.item.shopId,
        itemId: widget.item.itemId,
        subTitle: widget.item.summary,
        alias: widget.item.alias,
        image: widget.item.image,
        origin: widget.item.origin,
        price: widget.item.price,
        detailUrl: widget.item.detailUrl,
        quantity: widget.item.quantity,
      ));
      const String type = "productPush";
      await fbApi.sendGoodsNotice(
        roomInfoObjectValue.serverId,
        roomInfoObjectValue.channelId,
        roomInfoObjectValue.roomId,
        type,
        goodsPushJson,
      );

      /// 主播推送的权重大于小助手，如同时推送则覆盖小助手推送
      if (widget.manageBloc.statePage!.widget.isAnchor!) {
        await Future.delayed(const Duration(milliseconds: 200));
      }

      goodsAnchorPushBus.fire(
        GoodsPushEvenModel(
          json: goodsPushJson,
          user: await fbApi.getUserInfo(fbApi.getUserId()!,
              guildId: roomInfoObjectValue.serverId),
          type: type,
        ),
      );

      await Future.delayed(const Duration(milliseconds: 500)).then((value) {
        /// 【2021 12.15】刷新推送按钮状态
        refreshPushStatus(widget);

        dismissAllToast();
        mySuccessToast("推送成功");

        inCountdown = true;
        count = 60;
        start();

        if (onComplete != null) {
          onComplete();
        }
      });
    } else {
      stockNot(thisState, resultData, onCardRefresh);
    }
  }

  /*
  * 库存不足相应处理
  * */
  void stockNot(
      State<GoodsPushCard> thisState, Map value, VoidCallback? onCardRefresh) {
    /// 700=处理库存不足ui效果
    if (value['code'] == 700) {
      thisState.widget.item.quantity = 0;
      if (onCardRefresh != null) {
        onCardRefresh();
      }
    }
  }

  @override
  Future<void> close() {
    cancel();
    return super.close();
  }
}
