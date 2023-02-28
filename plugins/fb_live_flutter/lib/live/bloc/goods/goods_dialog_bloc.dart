import 'package:fb_live_flutter/live/api/fblive_provider.dart';
import 'package:fb_live_flutter/live/model/room_infon_model.dart';
import 'package:fb_live_flutter/live/pages/goods/goods_dialog.dart';
import 'package:fb_live_flutter/live/utils/live/base_bloc.dart';
import 'package:fb_live_flutter/live/utils/live/goods_manage_light_util.dart';
import 'package:fb_live_flutter/live/utils/log/goods_log_up.dart';
import 'package:fb_live_flutter/live/utils/other/goods_util.dart';
import 'package:fb_live_flutter/live/utils/theme/my_toast.dart';
import 'package:flutter/material.dart';

import 'goods_manage_api.dart';
import 'goods_push_logic.dart';

/*
* 【商品对话框】item类型
* */
enum GoodsDialogItemType {
// 购物车
  shoppingCart,
// 订单
  order,

  // ==============分割线==================

  // 添加
  add,
  // 管理
  manage,
}

/*
* 【商品对话框】item模型
* */
class GoodsDialogItemModel {
  final String image;
  final String text;
  final GoodsDialogItemType value;

  GoodsDialogItemModel(this.image, this.text, this.value);
}

/// 关于商品呼吸灯，以当前直播间为参照，如果本来就有商品，显示呼吸灯，
/// 当点击后消失，再增加新商品，显示呼吸灯，点击后消失。以及 呼吸灯的交互动画。
///
/// ps：只有观众有，小助手和主播不能购买商品；
/// date：2021 11.20【old】
///
/// 怎么做【初始化逻辑】？
/// 1。进入直播间且打开商品列表后请求【获取购物车数量接口】；
/// 2。判断上次处理的是否为当前直播间且与上次的用户相同且与上次的数量相同；
/// 3。如果上次处理的是当前直播间则取上次存储的是否显示呼吸灯；
/// 4。如果上次处理的不是当前直播间则判断购物车数量是否大于0；
/// 5。如果购物车数量大于0则显示呼吸灯，否则不显示；
///
/// 怎么做【添加逻辑】？
/// 1。添加购物车后设置显示呼吸灯；
/// 2。【存储/替换】当前设置之后的数据；
///
/// 怎么做【已读回执】？
/// 1。点击购物车图标后设置不显示呼吸灯；
/// 2。【存储/替换】当前设置之后的数据；
///
/// 设置的数据必备指标：
/// 1。满足判断房间id；
/// 2。满足判断是否显示呼吸灯；
/// 3。满足判断是否当前用户；
/// 4。满足判断上次的数量与这次请求时的数量是否相同；
///
///
/// 关于商品呼吸灯，以当前直播间为参照，如果本来就有商品，显示呼吸灯，
/// 当点击后消失，再增加新商品，显示呼吸灯，点击后消失。以及 呼吸灯的交互动画。
///
///
/// ps：只有观众有，小助手和主播不能购买商品；
/// date：2021 11.22【new】
///
/// 临时存储到内存中。
class GoodsDialogBloc extends BaseAppCubit<int>
    with BaseAppCubitState, GoodsPushLogicRoom, GoodsManageApi {
  GoodsDialogBloc() : super(0);

  State<GoodsDialogPage>? statePage;

  BuildContext? get context {
    return statePage?.context ?? fbApi.globalNavigatorKey.currentContext;
  }

  int? get shopId {
    return statePage!.widget.shopId;
  }

  void init(State<GoodsDialogPage> state) {
    statePage = state;

    liveGoodsList();
    liveCartCount();
  }

  @override
  void onRefresh() {
    /// 后续考虑去除setState，使用super.onRefresh();
    if (statePage!.mounted) {
      // ignore: invalid_use_of_protected_member
      statePage?.setState(() {});
    }
  }

  void action(GoodsDialogItemModel? value) {
    switch (value!.value) {
      case GoodsDialogItemType.order:
        fbApi.pushLinkPage(
            context!,
            GoodsUtil.joinMiniProgramSuffix(
              "https://shop$shopId.youzan.com/wsctrade/order/list?kdt_id=$shopId&type=all",
            ),
            title: '订单');
        GoodsLogUp.clickListOrderButton(
            roomInfoObject: statePage!.widget.roomInfoObject);
        break;
      case GoodsDialogItemType.shoppingCart:

        /// 红点已读回执
        isShowCartRedPoint.value = false;

        /// 内存已读处理
        GoodsManageCartUtil.readCount(
            cartCount, statePage!.widget.roomInfoObject.roomId);

        /// 打开连接
        fbApi.pushLinkPage(
            context!,
            GoodsUtil.joinMiniProgramSuffix(
                "https://shop$shopId.youzan.com/wsctrade/cart?kdt_id=$shopId"),
            title: '购物车');
        GoodsLogUp.clickTrolleyButton(
            roomInfoObject: statePage!.widget.roomInfoObject);
        break;
      default:
        myToast('敬请期待');
        break;
    }
  }

  @override
  RoomInfon get roomInfoObjectValue => statePage!.widget.roomInfoObject;
}
