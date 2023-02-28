import 'dart:convert';

import 'package:fb_live_flutter/live/api/fblive_provider.dart';
import 'package:fb_live_flutter/live/event_bus_model/coupons/coupons_model.dart';
import 'package:fb_live_flutter/live/model/coupons/coupons_list_model.dart';
import 'package:fb_live_flutter/live/model/room_infon_model.dart';
import 'package:fb_live_flutter/live/net/api.dart';
import 'package:fb_live_flutter/live/utils/func/router.dart';
import 'package:fb_live_flutter/live/utils/func/utils_class.dart';
import 'package:fb_live_flutter/live/utils/live/base_bloc.dart';
import 'package:fb_live_flutter/live/utils/log/coupons_log_up.dart';
import 'package:fb_live_flutter/live/utils/theme/my_toast.dart';
import 'package:flutter/cupertino.dart';
import 'package:oktoast/oktoast.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

import 'coupons_add_tab_bloc.dart';

abstract class CouponsRoomInfo {
  RoomInfon get roomInfoObject;
}

mixin CouponsAddApi on BaseAppCubit<int>, BaseAppCubitState, CouponsRoomInfo {
  int pageNum = 1;
  int? total = 0;

  bool isLoadOk = false;
  bool isRefreshing = false;

  List<CouponListModel> models = [];

  final RefreshController refreshController = RefreshController();
  ScrollController scrollController = ScrollController();

  bool get isHaveData {
    return listNoEmpty(models);
  }

  /*
  * 直播间优惠券列表
  * */
  Future<void> liveCouponList(int couponType,
      {required bool isToast, bool isRefresh = true}) async {
    if (isRefresh && pageNum != 1) {
      pageNum = 1;
    }
    try {
      final value =
          await Api.liveCouponList(couponType, pageNum, roomInfoObject.roomId);
      if (value["code"] != 200) {
        isLoadOk = true;
        onRefresh();
        return;
      }
      final List<CouponListModel> data =
          List.from(value['data'] ?? []).map<CouponListModel>((e) {
        final CouponListModel couponListModel = CouponListModel.fromJson(e);

        /// [2021 12.3] 修复优惠券日志数据不全
        CouponsLogUp.couponsSelectPageShow(couponListModel, null,
            roomInfoObject: roomInfoObject);

        return couponListModel;
      }).toList();

      if (pageNum <= 1) {
        models = data;
        refreshController.loadComplete();
      } else {
        if (listNoEmpty(data)) {
          models.addAll(data);
          refreshController.loadComplete();
        } else {
          refreshController.loadNoData();
        }
      }

      /// 获取优惠券数量
      final Map liveCouponCount =
          await Api.liveCouponCount(couponType, roomInfoObject.roomId);
      if (liveCouponCount["code"] != 200) {
        return;
      }
      final int? count = liveCouponCount["data"]["count"];
      total = count;

      isLoadOk = true;
      onRefresh();
      if (isToast) {
        await Future.delayed(const Duration(milliseconds: 200)).then((value) {
          dismissAllToast();
        });
      }
    } catch (e) {
      isLoadOk = true;
      onRefresh();
      if (isToast) {
        await Future.delayed(const Duration(milliseconds: 200)).then((value) {
          dismissAllToast();
        });
      }
    }
  }

  /*
  * 刷新优惠券库存[新]
  *
  * 【2021 11.20】【优惠卷】优惠卷显示不对，详细见视频
  * */
  Future<void> refreshStockNew() async {
    await Future.delayed(Duration.zero).then((value) {
      /// 【优惠券列表】刷新中提示 ui显示
      // myLoadingToast(tips: '刷新中...');
      isRefreshing = true;
      onRefresh();
    });
    final refreshData = await couponRefreshStock();
    if (refreshData == null) {
      isRefreshing = false;
      onRefresh();
      return;
    }
    await liveCouponList(0, isToast: false);

    isRefreshing = false;
    onRefresh();

    dismissAllToast();

    /// 【2021 11.24】【优惠券列表】刷新完成提示 应：（不需要提示
    // mySuccessToast('刷新成功');
  }

  /*
  * 查询优惠券库存数量【Api】
  * */
  Future<int?> shopCouponStock(int shopId, int activityId) async {
    final value = await Api.shopCouponStock(shopId, activityId);
    if (value['code'] != 200) {
      return null;
    }
    return value['data']['stock'] ?? 0;
  }

  /*
  * 【V3】刷新优惠券库存【Api】
  * */
  Future<Map?> couponRefreshStock() async {
    final value = await Api.couponRefreshStock(roomInfoObject.roomId);
    if (value['code'] != 200) {
      return null;
    }
    return value['data'];
  }

  /*
  * 查询店铺商品列表
  * */
  Future<void> shopCouponList(int couponType, List<CouponListModel> okModels,
      {bool isRefresh = true}) async {
    /// 【优惠券管理列表】加载中提示 ui上提示
    // await Future.delayed(Duration.zero).then((value) {
    // myLoadingToast(tips: '加载中...');
    // });

    if (isRefresh && pageNum != 1) {
      pageNum = 1;
    }

    try {
      final value = await Api.shopCouponList(
          pageNum: pageNum,
          couponType: couponType,
          roomId: roomInfoObject.roomId);
      if (value["code"] != 200) {
        isLoadOk = true;
        onRefresh();
        return;
      }
      final int totalValue = value['data']['total'];
      if (totalValue > 0) {
        total = totalValue;
      }
      final List<CouponListModel> data =
          List.from(value['data']['data'] ?? []).map<CouponListModel>((e) {
        final CouponListModel couponListModel = CouponListModel.fromJson(e);
        return couponListModel;
      }).toList();

      if (pageNum <= 1) {
        models = data;
        refreshController.loadComplete();
      } else {
        if (listNoEmpty(data)) {
          models.addAll(data);
          refreshController.loadComplete();
        } else {
          refreshController.loadNoData();
        }
      }

      isLoadOk = true;
      dismissAllToast();
      onRefresh();
      return;
    } catch (e) {
      dismissAllToast();
      return;
    }
  }

  /*
  * 新增直播间优惠券
  *
  * [2021 11.15]需要接收已选择的models，来判断是否为从无到有，如果是的话需要推送给观众，
  * 观众入口就要开始显示。
  * */
  Future liveCouponAdd(
      List<CouponListModel> okModels, final CouponsAddTabBloc tabBloc) async {
    if (tabBloc.selectData.length > 1) {
      myLoadingToast(tips: "正在添加");
    }
    final List<int?> itemIds = [];
    tabBloc.selectData.forEach(itemIds.add);
    final value = await Api.liveCouponAdd(itemIds, roomInfoObject.roomId);
    if (value["code"] != 200) {
      return;
    }

    /// 刷新优惠券列表
    couponsBus.fire(CouponsRefreshModel(0));

    dismissAllToast();
    RouteUtil.pop();

    /// 【APP】添加优惠券和移除优惠券，没有提示
    await Future.delayed(const Duration(milliseconds: 100)).then((value) {
      mySuccessToast("添加成功");
    });

    if (!listNoEmpty(okModels)) {
      /// 优惠券从无到有，需要推送给观众让其显示入口
      pushShowEntrance();
    }
    return value;
  }

  /// 推送给观众，让其显示优惠券入口
  void pushShowEntrance() {
    const String pushType = "couponPush";

    /// 推送
    fbApi.sendGoodsNotice(
      roomInfoObject.serverId,
      roomInfoObject.channelId,
      roomInfoObject.roomId,
      pushType,
      json.encode({
        "isShow": "true",
        "content": pushType,
      }),
    );
  }

  /*
  * 移除直播间优惠券
  * */
  Future liveCouponRemove(final CouponsAddTabBloc tabBloc) async {
    if (tabBloc.selectData.length > 1) {
      myLoadingToast(tips: "正在移除");
    }
    final List<int?> itemIds = [];
    tabBloc.selectData.forEach(itemIds.add);
    final value = await Api.liveCouponRemove(itemIds, roomInfoObject.roomId);
    if (value["code"] != 200) {
      return;
    }

    /// 刷新优惠券列表
    couponsBus.fire(CouponsRefreshModel(0));

    dismissAllToast();
    RouteUtil.pop();

    /// 【APP】添加优惠券和移除优惠券，没有提示
    await Future.delayed(const Duration(milliseconds: 100)).then((value) {
      mySuccessToast("移除成功");
    });
    return value;
  }
}
