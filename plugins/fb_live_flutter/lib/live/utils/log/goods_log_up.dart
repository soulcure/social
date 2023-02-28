import 'package:fb_live_flutter/live/api/fblive_provider.dart';
import 'package:fb_live_flutter/live/bloc/logic/goods_logic.dart';
import 'package:fb_live_flutter/live/model/goods/goods_add.dart';
import 'package:fb_live_flutter/live/model/room_infon_model.dart';
import 'package:fb_live_flutter/live/utils/func/utils_class.dart';

/// 商品日志上报
class GoodsLogUp {
  static String logName = "dlog_app_live_product_behavior_fb";

  // "枚举值：
  // 1. shopping_cart_show=货架商品列表页曝光；
  // 2. click_product=(商品列表页)点击商品;
  // 3. click_add=(商品列表页)点击添加购物车;
  // 4. click_grab=(商品列表页)点击马上抢;
  // 5. click_list_order_button=(商品列表页)点击可购买商品弹窗页上的订单按钮;
  // 6. click_trolley_button=(商品列表页)点击可购买商品弹窗页上的购物车按钮;
  // 7. product_select_page_show=商品类选择页曝光;
  // 8. click_select_confirm=(商品类选择页)点击确定;
  // 9. click_product_detail=(商品类选择页)点击商品详情;
  // 10. push_product_show=(直播间页)推送商品卡片曝光;
  // 11. click_product_card=(直播页)点击推送商品卡片;
  // 12. click_coupons_card=(直播页)点击领券卡片;
  // 13. coupons_select_page_show=(优惠券页)优惠券列表页曝光;
  // 14. click_receive_coupons=(优惠券页)点击立即领取;
  // 15. click_use_coupons=(优惠券页)点击去使用;"

  /// ==================================================================
  // "== 日志类型：直播商品用户行为日志【dlog_app_live_product_behavior_fb】
  //
  // ==根据指标需求，需上报接口及行为场景如下：
  // == 页面1：商品列表页面
  // 1. 用户点击商品货架后拉起可购买商品弹窗页曝光时上报多条日志，即曝光N个商品上报N条记录【opt_type上报shopping_cart_show】
  // 2. 用户点击商品列表页上某个商品时上报一条日志【opt_type上报click_product】：
  // 3. 用户点击添加购物车时上报一条日志【opt_type上报click_add】
  // 4. 用户点击马上抢时上报一条日志【opt_type上报click_grab】
  // 5. 用户点击可购买商品弹窗页上的订单按钮时上报一条日志【opt_type上报click_list_order_button】
  // 6. 用户点击可购买商品弹窗页上的购物车按钮时上报一条日志【opt_type上报click_trolley_button 】
  //
  // == 页面2：商品选择页面
  // 7. 用户点击马上抢或加入购物车拉起商品类选择页曝光时上报一条日志【opt_type上报product_select_page_show】
  // 8. 用户选择商品类别后，点击确定时上报一条日志【opt_type上报click_select_confirm】：
  // 9. 用户，点击商品详情时上报一条日志【opt_type上报click_product_detail】
  //
  // ==页面3：直播间页面
  // 10. 用户在观看直播间内商品卡片曝光时上报一条日志【opt_type上报push_product_show】;
  // 11. 用户在观看直播间内点击商品卡片时上报一条日志【opt_type上报click_product_card】
  // 12. 用户在观看直播间内点击领券卡片时上报一条日志【opt_type上报click_coupons_card】
  //
  // ==页面4：优惠券领取页
  // 13. 用户在点击领券卡片后拉起优惠券领取页面曝光时上报多条日志，即曝光N个优惠券上报N条记录【opt_type上报coupons_select_page_show】
  // 14. 用户在优惠券列表页时点击立即领取时上报一条日志【opt_type上报click_receive_coupons】
  // 15. 用户在优惠券列表页领取优惠券后点击马上使用时上报一条日志【opt_type上报click_use_coupons】
  //
  // 注：每条行为日志audio_log_type都上报3，为直播日志"

  /// 是否管理身份，是的话不需要上报日志
  static bool isAdmin(RoomInfon roomInfoObject) {
    return GoodsLogicValue.isAssistantValue! ||
        roomInfoObject.anchorId == fbApi.getUserId();
  }

  static Future<void> extensionEvent(
    GoodsListModel? item,
    int? rank,
    String optType, {
    required RoomInfon roomInfoObject,
  }) async {
    /// [2021 11.26] 管理身份不需要上报直播商品日志
    ///
    /// 【今天】直播带货，【直播商品用户行为日志】这个日志下的，
    /// 所有opt_type行为都只上报观众的，不上报主播与小助手的。
    /// 【埋点】直播商品行为，这个日志主播和小助手端，不需要上报任何日志
    if (isAdmin(roomInfoObject)) {
      return;
    }
    fbApi.extensionEvent(
      extJson: {
        "audio_log_type": 3,
        "opt_type": optType,
        "opt_content": item?.detailUrl ?? 'opt_content',
        "channel_id": roomInfoObject.channelId,
        "room_id": roomInfoObject.roomId,
        "guild_id": roomInfoObject.serverId,
        "room_title": roomInfoObject.roomTitle,
        "product_type": "product",
        "product_id": item?.itemId,
        "product_name": item?.title,
        "product_real_price": item?.price ?? 0,
        "product_original_price": item?.origin ?? 0,
        "product_sort": rank,
        "user_type": "${strNoEmpty(fbApi.getUserId()) ? 1 : 0}",
        "user_name": (await fbApi.getUserInfo(fbApi.getUserId()!,
                guildId: roomInfoObject.serverId))
            .shortId,
        "nick_name": "", //(await fbApi.getUserInfo(fbApi.getUserId())).name
      },
      logType: logName,
    );
  }

  // 货架商品列表页曝光
  static Future<void> shoppingCartShow(
    GoodsListModel item,
    int rank, {
    required RoomInfon roomInfoObject,
  }) async {
    const String optType = "shopping_cart_show";
    return extensionEvent(item, rank, optType, roomInfoObject: roomInfoObject);
  }

  // (商品列表页)点击商品;
  static Future<void> clickProduct(
    GoodsListModel? item,
    int? rank, {
    required RoomInfon roomInfoObject,
  }) async {
    const String optType = "click_product";
    return extensionEvent(item, rank, optType, roomInfoObject: roomInfoObject);
  }

  // (商品列表页)点击添加购物车;
  static Future<void> clickAdd(
    GoodsListModel item,
    int rank, {
    required RoomInfon roomInfoObject,
  }) async {
    const String optType = "click_add";
    return extensionEvent(item, rank, optType, roomInfoObject: roomInfoObject);
  }

  // (商品列表页)点击马上抢;
  static Future<void> clickGrab(
    GoodsListModel item,
    int rank, {
    required RoomInfon roomInfoObject,
  }) async {
    const String optType = "click_grab";
    return extensionEvent(item, rank, optType, roomInfoObject: roomInfoObject);
  }

  // (商品列表页)点击可购买商品弹窗页上的订单按钮;
  static Future<void> clickListOrderButton({
    required RoomInfon roomInfoObject,
  }) async {
    const String optType = "click_list_order_button";
    return extensionEvent(null, null, optType, roomInfoObject: roomInfoObject);
  }

  // (商品列表页)点击可购买商品弹窗页上的购物车按钮;
  static Future<void> clickTrolleyButton({
    required RoomInfon roomInfoObject,
  }) async {
    const String optType = "click_trolley_button";
    return extensionEvent(null, null, optType, roomInfoObject: roomInfoObject);
  }

  // 商品类选择页曝光
  static Future<void> productSelectPageShow(
    GoodsListModel item,
    int rank, {
    required RoomInfon roomInfoObject,
  }) async {
    const String optType = "product_select_page_show";
    return extensionEvent(item, rank, optType, roomInfoObject: roomInfoObject);
  }

  // (商品类选择页)点击确定;
  static Future<void> clickSelectConfirm(
    GoodsListModel item,
    int rank, {
    required RoomInfon roomInfoObject,
  }) async {
    const String optType = "click_select_confirm";
    return extensionEvent(item, rank, optType, roomInfoObject: roomInfoObject);
  }

  // (商品类选择页)点击商品详情;
  static Future<void> clickProductDetail(
    GoodsListModel? item,
    int rank, {
    required RoomInfon roomInfoObject,
  }) async {
    const String optType = "click_product_detail";
    return extensionEvent(item, rank, optType, roomInfoObject: roomInfoObject);
  }

  // (直播间页)推送商品卡片曝光;
  static Future<void> pushProductShow(
    GoodsListModel item,
    int? rank, {
    required RoomInfon roomInfoObject,
  }) async {
    const String optType = "push_product_show";
    return extensionEvent(item, rank, optType, roomInfoObject: roomInfoObject);
  }

  // (直播页)点击推送商品卡片;
  static Future<void> clickProductCard(
    GoodsListModel item,
    int? rank, {
    required RoomInfon roomInfoObject,
  }) async {
    const String optType = "click_product_card";
    return extensionEvent(item, rank, optType, roomInfoObject: roomInfoObject);
  }
}
