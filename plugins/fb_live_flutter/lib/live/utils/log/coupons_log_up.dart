import 'package:fb_live_flutter/fb_live_flutter.dart';
import 'package:fb_live_flutter/live/bloc/logic/goods_logic.dart';
import 'package:fb_live_flutter/live/model/coupons/coupons_list_model.dart';
import 'package:fb_live_flutter/live/model/room_infon_model.dart';
import 'package:fb_live_flutter/live/utils/func/utils_class.dart';

/// 优惠券日志上报
class CouponsLogUp {
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
  // 16. push_coupons_show=(直播间页)推送领券卡片曝光

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
    CouponListModel? item,
    int? rank,
    String optType, {
    required RoomInfon roomInfoObject,
  }) async {
    /// [2021 11.26] 管理身份不需要上报直播商品日志
    /// [2021 11.29] 优惠券相关【主播/小助手】也不需要上报日志
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
        "opt_content": item?.typeStr ?? 'opt_content',
        "channel_id": roomInfoObject.channelId,
        "room_id": roomInfoObject.roomId,
        "guild_id": roomInfoObject.serverId,
        "room_title": roomInfoObject.roomTitle,
        "product_type": "conpus",
        "product_id": item?.id ?? '',
        "product_name": item?.title ?? '',
        "product_real_price": item?.value ?? 0,
        "product_original_price": 0,
        "product_sort": rank ?? "",
        "user_type": "${strNoEmpty(fbApi.getUserId()) ? 1 : 0}",
        "user_name": (await fbApi.getUserInfo(fbApi.getUserId()!,
                guildId: fbApi.getCurrentChannel()!.guildId))
            .shortId,
        "nick_name": "", //(await fbApi.getUserInfo(fbApi.getUserId())).name
      },
      logType: logName,
    );
  }

  // (直播页)点击领券卡片;【用户在观看直播间内点击领券卡片时上报一条日志】
  static Future<void> clickCouponsCard({
    required RoomInfon roomInfoObject,
  }) async {
    const String optType = "click_coupons_card";
    return extensionEvent(null, null, optType, roomInfoObject: roomInfoObject);
  }

  // (优惠券页)优惠券列表页曝光;
  static Future<void> couponsSelectPageShow(
    CouponListModel item,
    int? rank, {
    required RoomInfon roomInfoObject,
  }) async {
    const String optType = "coupons_select_page_show";
    return extensionEvent(item, rank, optType, roomInfoObject: roomInfoObject);
  }

  // (优惠券页)点击立即领取;
  static Future<void> clickReceiveCoupons(
    CouponListModel? item,
    int rank, {
    required RoomInfon roomInfoObject,
  }) async {
    const String optType = "click_receive_coupons";
    return extensionEvent(item, rank, optType, roomInfoObject: roomInfoObject);
  }

  // (优惠券页)点击去使用;
  static Future<void> clickUseCoupons(
    CouponListModel? item,
    int rank, {
    required RoomInfon roomInfoObject,
  }) async {
    const String optType = "click_use_coupons";
    return extensionEvent(item, rank, optType, roomInfoObject: roomInfoObject);
  }

  // (直播间页)推送领券卡片曝光;
  static Future<void> pushCouponsShow({
    required RoomInfon roomInfoObject,
  }) async {
    const String optType = "push_coupons_show";
    return extensionEvent(null, null, optType, roomInfoObject: roomInfoObject);
  }
}
