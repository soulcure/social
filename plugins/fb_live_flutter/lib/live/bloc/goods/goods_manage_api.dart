import 'dart:convert';

import 'package:fb_live_flutter/fb_live_flutter.dart';
import 'package:fb_live_flutter/live/event_bus_model/goods/goods_count_model.dart';
import 'package:fb_live_flutter/live/event_bus_model/goods_html_bus.dart';
import 'package:fb_live_flutter/live/model/goods/goods_add.dart';
import 'package:fb_live_flutter/live/net/api.dart';
import 'package:fb_live_flutter/live/utils/func/utils_class.dart';
import 'package:fb_live_flutter/live/utils/live/base_bloc.dart';
import 'package:fb_live_flutter/live/utils/live/goods_manage_light_util.dart';
import 'package:fb_live_flutter/live/utils/theme/my_toast.dart';
import 'package:get/get.dart';
import 'package:oktoast/oktoast.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

import 'goods_push_logic.dart';

mixin GoodsManageApi
    on BaseAppCubit<int>, BaseAppCubitState, GoodsPushLogicRoom {
  int pageNum = 1;
  int? dataCount = 0;

  /// 购物车数量
  int cartCount = 0;

  bool isLoadOk = false;
  bool isManageMode = false;

  /// 是否显示购物车红点
  /// 【APP】购物车上方的红点，在购物车没有商品的时候有这个红点
  RxBool isShowCartRedPoint = false.obs;

  List<GoodsListModel> models = [];
  List selectData = [];

  final RefreshController refreshController = RefreshController();

  bool get isHaveData {
    return listNoEmpty(models);
  }

  /*
  * 查询直播间商品列表
  * */
  Future<void> liveGoodsList(
      [bool isRefresh = true, bool isLoadingToast = true]) async {
    if (isRefresh && pageNum != 1) {
      pageNum = 1;
    }
    final value = await Api.liveGoodsList(pageNum, roomInfoObjectValue.roomId);
    if (value["code"] != 200) {
      isLoadOk = true;
      onRefresh();
      return;
    }
    await liveGoodsGetCount();
    final List<GoodsListModel> data =
        List.from(value['data'] ?? []).map<GoodsListModel>((e) {
      final GoodsListModel goodsListModel = GoodsListModel.fromJson(e);
      return goodsListModel;
    }).toList();

    /// 【APP】商品添加成功后，跳转至管理商品页面
    if (isRefresh && models.length != data.length) {
      isManageMode = false;
    }

    if (pageNum <= 1) {
      models = data;
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
  }

  /*
  * 获取直播间商品数量
  * */
  Future liveGoodsGetCount() async {
    final Map resultData =
        await Api.liveGoodsGetCount(roomInfoObjectValue.roomId);
    if (resultData["code"] == 200) {
      dataCount = resultData["data"]["count"];
      goodsCountBus.fire(GoodsCountModel(dataCount));
    }
  }

  /*
  * 删除选择的直播间商品【新版-推送中商品可以移除时再使用】
  * */
  Future liveGoodsRemoveSelect(int? currentPushID, bool pushCountEffect) async {
    if (selectData.length > 1) {
      myLoadingToast(tips: "正在移除");
    }

    /// 是否包含了推送中的item
    bool isContainPushItem = false;

    final List<int?> itemIds = [];
    selectData.forEach((element) {
      itemIds.add(element.itemId);

      /// 删除的时候如果包含了推送中的id则标识[isContainPushItem]为true，
      /// 表示包含了正在推送的item，需要删除
      if (currentPushID != null && element.itemId == currentPushID) {
        isContainPushItem = true;
      }
    });

    /// 因为接口目前还没调整所以放这
    if (isContainPushItem && pushCountEffect) {
      /// 移除了包含了推送中的商品，需要通知观众取消推送
      await sendRemoveGoodsMsg(currentPushID);
    }

    final value =
        await Api.liveGoodsRemove(itemIds, roomInfoObjectValue.roomId);
    if (value["code"] != 200) {
      return;
    }

    selectData.forEach((element) {
      final int at = models.indexOf(element);
      models.removeAt(at);

      /// 【APP】除了被推送的商品，移除其他商品，被推送的商品序号有误
      if (dataCount! > 0) {
        var _dataCount = dataCount;
        if (_dataCount != null) {
          _dataCount--;
          dataCount = _dataCount;
        }
      }
    });
    selectData = [];

    dismissAllToast();
    mySuccessToast("移除成功");
    onRefresh();
  }

  /*
  * 发送删除推送消息【新版-可以移除时再使用】
  * */
  Future<void> sendRemoveGoodsMsg(int? currentPushID) async {
    const String type = "productRemove";

    /// 推送的json
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

    /// 推送给自己
    goodsAnchorPushBus.fire(
      GoodsPushEvenModel(
        json: goodsCancelPushJson,
        user: await fbApi.getUserInfo(fbApi.getUserId()!,
            guildId: roomInfoObjectValue.serverId),
        type: type,
      ),
    );
  }

  /*
  * 删除单个直播间商品
  * */
  Future liveGoodsRemoveItem(int index) async {
    final value = await Api.liveGoodsRemove(
        [models[index].itemId], roomInfoObjectValue.roomId);
    if (value["code"] != 200) {
      return;
    }

    models.removeAt(index);
    onRefresh();

    dismissAllToast();
    mySuccessToast("移除成功");
    return 1;
  }

  /*
  * 获取购物车商品数量
  * */
  Future<void> liveCartCount() async {
    final value = await Api.liveCartCount(roomInfoObjectValue.roomId);
    if (value['code'] != 200) {
      return;
    }

    /// 购物车数量赋值为接口返回的
    cartCount = value['data']['count'] ?? 0;

    /// 是否应该显示呼吸灯【数量判断】
    final bool isShow = cartCount > 0;

    /// 设置购物车数量，处理是否要显示呼吸灯
    await GoodsManageCartUtil.setCount(cartCount, isShow, () {
      isShowCartRedPoint.value = true;
      onRefresh();
    }, roomInfoObjectValue.roomId);
  }
}
