import 'dart:collection';
import 'dart:io';

import 'package:fb_live_flutter/live/api/fblive_provider.dart';
import 'package:fb_live_flutter/live/model/online_user_count.dart';
import 'package:fb_live_flutter/live/model/room_infon_model.dart';
import 'package:fb_live_flutter/live/utils/func/check.dart';
import 'package:fb_live_flutter/live/utils/func/utils_class.dart';
import 'package:fb_live_flutter/live/utils/log/live_log_up.dart';
import 'package:flutter/foundation.dart';

import 'address.dart';
import 'http_manager.dart';

class Api {
  /*
   *1、保存用户信息
      - 接口地址：/v1/member
      - 请求参数参数名         类型    必填   描述
                id          int64   是     用户Id
                nickName   string   是     主播昵称
                avatarUrl  string   是     主播头像
                shortId  string     是     用户短Id
  */
  static Future postUserInfo(String? nickName, String avatarUrl, String? userId,
      String? shortId) async {
    final params = SplayTreeMap<String, dynamic>();
    params["id"] = userId;
    params["nickName"] = nickName;
    params["avatarUrl"] = avatarUrl;
    params["shortId"] = shortId;
    return HttpManager.getInstance().post(Address.saveUserinfo, params: params);
  }

  /*
   *2、正在直播的直播间列表
    - 接口地址：/v1/live/ing
    参数名 类型  必填  描述
    serverId  string  否 服务器Id，openType=2 必填
    openType  int 是
    直播间开发类型：1-公开到广场、2-仅服务器可见 本服务器数据刷新完成后开始刷新广场数据
    pageSize  int 是 分页大小，最小值为1
    pageNum  int  是  页码，最大值50
    channelId  string  否  频道id
    anchorId   string  否   主播Id
  */
  static Future getLiveRoomList(
    String? serverId,
    int pageNum,
    String? anchorId,
  ) {
    final params = SplayTreeMap<String, dynamic>();
    params["pageSize"] = 10;
    params["pageNum"] = pageNum;
    params["serverId"] = serverId;
    params["withObs"] = true;
    params["channelId"] = fbApi.getCurrentChannel()?.id;
    if (anchorId != null) params["anchorId"] = anchorId;
    return HttpManager.getInstance().get(Address.videolistUrl, params: params);
  }

  /*
   *3、图片上传接口
    - 接口地址：/v1//upload/img
    参数名   类型      必填    描述
    file    file      是      上传的图片内容，只支持png、jpg
  */
  static Future uploadImage(String file) {
    return HttpManager.getInstance().upload(Address.uploadImg, imagePath: file);
  }

  // web 端
  static Future webUploadImage(Map _file) {
    return HttpManager.getInstance()
        .webUpload(Address.uploadImg, fileMap: _file);
  }

/*
 *4、查询系统标签
  - 接口地址：/v1/system/tags
  - 请求参数 pageSize 分页大小，最小值为1
          pageNum  int 是  页码，最大值50
 */
  static Future getTags(int pageSize, int pageNum) async {
    final params = SplayTreeMap<String, dynamic>();
    params["pageSize"] = pageSize;
    params["pageNum"] = pageNum;
    return HttpManager.getInstance().get(Address.getTags, params: params);
  }

  /*
   *5、开直播    接口地址：/v1/live/open
    serverId 服务器Id serverName  服务器名称  channelId 分页大小，最小值为1
    channelName 频道名称
    roomTitle 直播间标题
    roomLogo  直播间封面URL
    systemTags  直播间系统标签ID列表
    userTags  用户自定义标签列表
    openType  开放状态：1-公开到广场、2-仅服务器可见
    liveType int 是 直播类型：0-默认、1-Android、2-WEB、3-OBS、4-iOS
  */
  static Future createLiveRoom(
    String? serverId,
    String? serverName,
    String? channelId,
    String? channelName,
    String? roomTitle,
    String? roomLogo,
    List<int?> systemTags,
    List<String?> userTags,
    int openType,
    int? shareType,
    bool isExternal,
    bool openCommerce,
    List assistants,
  ) {
    final params = SplayTreeMap<String, dynamic>();
    params["serverId"] = serverId;
    params["serverName"] = serverName;
    params["channelId"] = channelId;
    params["channelName"] = channelName;
    params["roomTitle"] = roomTitle;
    params["roomLogo"] = roomLogo;
    params["systemTags"] = systemTags;
    params["userTags"] = userTags;
    params["openType"] = openType;
    params["shareType"] = shareType;

    int platformType;
    if (kIsWeb) {
      platformType = 2;
    } else if (Platform.isIOS || Platform.isAndroid) {
      platformType = 4;
    } else {
      platformType = 1;
    }
    final int liveType = isExternal ? 3 : platformType;
    params["liveType"] = liveType;

    /// 是否开启带货
    params["openCommerce"] = openCommerce;

    /// 修复小助手数据传输失败
    assistants.remove("");

    /// 直播小助手
    params["assistants"] = assistants;
    return HttpManager.getInstance().post(Address.creatlive, params: params);
  }

  /*
   *6、获取直播间基础信息
    - 接口地址：/v1/live/room/:roomId
    roomId  直播间Id
  */
  static Future getRoomInfo(String roomId) {
    final params = SplayTreeMap<String, dynamic>();
    // params["roomId"] = roomId;
    return HttpManager.getInstance()
        .get(Address.getLiveInfo + roomId, params: params);
  }

  /*
   *7、获取zego房间登录token
    - 接口地址：/v1/zego/token/:roomId
    - 请求参 roomId  直播间Id
   */
  static Future getZegoToken(String roomId) {
    final params = SplayTreeMap<String, dynamic>();
    // params["roomId"] = roomId;
    return HttpManager.getInstance()
        .get(Address.getZegoToken + roomId, params: params);
  }

  /*
   *8、打赏礼物给播主
    - 接口地址：/v1/live/reward
    - 请求参 appType  number：应用类型：1-WEB网页、2-安卓、3-苹果
    - 请求参 giftId  number：礼物ID
    - 请求参 count  number：礼物数量，必须大于0
    - 请求参 roomId  string：直播间ID
   */
  static Future postLiveReward(
      int appType, int? giftId, int count, String? roomId) {
    final params = SplayTreeMap<String, dynamic>();
    params["appType"] = appType;
    params["giftId"] = giftId;
    params["count"] = count;
    params["roomId"] = roomId;
    return HttpManager.getInstance().post(Address.liveReward, params: params);
  }

  /*
   *9、获取礼物列表
    - 接口地址：/v1/live/gift_page_list
    - 请求参 pageSize
    - 请求参 pageNum
   */
  static Future getGiftPageList(int? pageSize, int pageNum) {
    final params = SplayTreeMap<String, dynamic>();
    params["pageSize"] = pageSize;
    params["pageNum"] = pageNum;
    return HttpManager.getInstance().get(Address.giftPageList, params: params);
  }

  /*
   *10、获取直播间在线用户数量
    - 接口地址：/v1/online/count/:roomId
    - 请求参 roomId  直播间Id
   */
  static Future getOnlineCount(String roomId, RoomInfon roomInfoObject) async {
    final params = SplayTreeMap<String, dynamic>();
    // params["roomId"] = roomId;
    final Map onlineData = await HttpManager.getInstance().get(
      Address.getOnlineCount + roomId,
      params: params,
      isToastShow: false,
    );
    if (onlineData["code"] == 200) {
      /// 修复
      if (onlineData["data"]['users'] != null) {
        final OnlineUserCount onlineUserCountModel =
            OnlineUserCount.fromJson(onlineData["data"]);
        fbApi.customEvent(
          actionEventId: 'real_time_traffic',
          actionEventSubId: '11002',
          pageId: 'traffic',
          actionEventSubParam: "onlineUserCountModel.total",
          extJson: {
            "total": onlineUserCountModel.total,
            "thumbCount": onlineUserCountModel.thumbCount,
            "userId": fbApi.getUserId(),
            "roomId": roomInfoObject.roomId,
            "channelId": roomInfoObject.channelId,
            "serverId": roomInfoObject.serverId,
          },
        );
      }
    }
    return onlineData;
  }

  /*
   *11、获取直播间在线用户列表
    - 接口地址：/v1/online/users
  */
  static Future getOnlineUserList(String? roomId, int pageSize, int pageNum) {
    final params = SplayTreeMap<String, dynamic>();
    params["roomId"] = roomId;
    params["pageSize"] = pageSize;
    params["pageNum"] = pageNum;
    return HttpManager.getInstance()
        .get(Address.getOnlineUserList, params: params);
  }

  /*
   *12、获取礼物记录列表
   - 接口地址：/v1/live/gift/page_list
  */
  static Future getGiftsRecordList(String? roomId, int pageSize, int? pageNum) {
    final params = SplayTreeMap<String, dynamic>();
    params["roomId"] = roomId;
    params["pageSize"] = pageSize;
    params["pageNum"] = pageNum;
    return HttpManager.getInstance().get(Address.giftRoced, params: params);
  }

  /*
   *13、统计直播间用户送礼物的虚拟币合计
    - 接口地址：/v1/live/gift/sum/:roomId
   */
  static Future getGiftscount(String roomId) {
    final params = SplayTreeMap<String, dynamic>();
    // params["roomId"] = roomId;
    return HttpManager.getInstance()
        .get(Address.giftsCount + roomId, params: params);
  }

  /*
  *14、查询乐豆账户余额
    - 接口地址：/v1/account/balance
    无参数
  */
  static Future getAccount() {
    return HttpManager.getInstance().get(Address.getBalance);
  }

  /*
   *15. 主播端结束直播
    - 接口地址：/v1/live/close/:roomId
   */
  static Future closeLiveRoom(String roomId) {
    final params = SplayTreeMap<String, dynamic>();
    // params["roomId"] = roomId;
    return HttpManager.getInstance()
        .post(Address.closeLive + roomId, params: params);
  }

  /*
   *16、上报用户进入直播间
    - 接口地址：/v1/live/enter
   */
  static Future liveEnter(String? roomId, String? userToken) {
    final params = SplayTreeMap<String, dynamic>();
    params["roomId"] = roomId;
    if (strNoEmpty(userToken)) {
      params["userToken"] = userToken ?? "";
    } else {
      final String? liveUserToken = fbApi.getSharePref("live_userToken");
      params["userToken"] = liveUserToken ?? "";
    }
    return HttpManager.getInstance().post(Address.liveEnter, params: params);
  }

  /*
   *17、上报用户退出直播间
    - 接口地址：/v1/live/exit
   */
  static Future liveExit(String? roomId, String? userToken, bool isAnchor,
      RoomInfon roomInfoObject) async {
    final params = SplayTreeMap<String, dynamic>();
    params["roomId"] = roomId ?? roomInfoObject.roomId;

    if (strNoEmpty(userToken)) {
      params["userToken"] = userToken ?? "";
    } else {
      final String? liveUserToken = fbApi.getSharePref("live_userToken");
      params["userToken"] = liveUserToken ?? "";
    }
    if (!isAnchor) LiveLogUp.liveLeave(roomId, roomInfoObject);
    return HttpManager.getInstance().post(Address.liveExit, params: params);
  }

  /*
   *18、直播开始
    - 接口地址：/v1/live/started/:roomId
   */
  static Future starteLive(String roomId) async {
    final params = SplayTreeMap<String, dynamic>();
    if (kIsWeb) {
      params["platform"] = 3;
    } else if (Platform.isAndroid) {
      params["platform"] = 1;
    } else if (Platform.isIOS) {
      params["platform"] = 2;
    }
    params["deviceId"] = await getDeviceInfo();
    params["clientVersion"] = await getVersionInfo();

    return HttpManager.getInstance()
        .post(Address.starteLive + roomId, params: params);
  }

  /*
   *19、获取快速充值金币列表
    — 接口地址：/v1/charge/coins/
   */
  static Future coinsList(String appType) {
    return HttpManager.getInstance().get(Address.coinsList + appType);
  }

  /*
   *20、充值预下单
    — 接口地址：/v1/charge/order
   */
  static Future order(int? coinId, int appType) {
    final params = SplayTreeMap<String, dynamic>();
    params["coinId"] = coinId;
    params["appType"] = appType;
    return HttpManager.getInstance().post(Address.order, params: params);
  }

  /*
   *21、查询乐豆账户余额
    — 接口地址：/v1/account/balance
   */
  static Future queryBalance() {
    return HttpManager.getInstance().get(Address.queryBalance);
  }

  /*
   *22、直播点赞
    — 接口地址：/v1/live/thumb
   */
  static Future thumbUp(String? roomId, int count) {
    if (count <= 0) {
      return Future.value({});
    }
    final Map params = SplayTreeMap<String, dynamic>();
    params["roomId"] = roomId;
    params["count"] = count;
    return HttpManager.getInstance().post(Address.thumbUp,
        params: params as Map<String, dynamic>?, isToastShow: false);
  }

  /*
   *23、4. 检查当前用户是否存在直播中的房间
    — 接口地址：/v1/live/check
   */
  static Future checkRoom() {
    return HttpManager.getInstance().get(Address.checkRoom, isToastShow: false);
  }

  /*
   *24、强制结束直播
    - 接口地址：/v1/live/mandatory_close/:roomId
   */
  static Future mandatoryClose(String roomId) {
    return HttpManager.getInstance().post(Address.mandatoryClose + roomId);
  }

  /*
   *28、获取OBS推流地址
    - 接口地址：/v1/live/obs/address/:roomId
   */
  static Future obsAddress(String roomId) {
    return HttpManager.getInstance().get(Address.obsAddress + roomId);
  }

  /*
   *29、开启OBS直播
    - 接口地址：/v1/live/obs/start/:roomId
   */
  static Future obsStartLive(String roomId) {
    return HttpManager.getInstance().post(Address.obsStartLive + roomId);
  }

  /*
   *30. 查询回放专辑
    - 接口地址：/v1/playback_album/page_list
   */
  static Future playbackAlbumList(int pageNum) {
    return HttpManager.getInstance().get(
      Address.playbackAlbumList,
      params: {
        "channelId": fbApi.getCurrentChannel()?.id,
        "pageSize": 10,
        "pageNum": pageNum,
      },
    );
  }

  /*
   * 31. 查询主播回放列表
    - 接口地址：/v1/playback/page_list
   */
  static Future playbackList(int pageNum, String? anchorId) {
    return HttpManager.getInstance().get(
      Address.playbackList,
      params: {
        "channelId": fbApi.getCurrentChannel()?.id,
        "anchorId": anchorId,
        "pageSize": 10,
        "pageNum": pageNum,
      },
    );
  }

  /*
   * 32. 用户观看回放
- 接口地址：/v1/playback/watch
  * roomId  string  是 直播间Id
   */
  static Future playbackWatch(String? roomId) {
    return HttpManager.getInstance().post(
      Address.playbackWatch,
      params: {"roomId": roomId},
    );
  }

  /*
   * 33. 主播设置回放可见范围
  - 接口地址：/v1/playback/set_visible
  * roomId  string  是 直播间Id
  * visibleScope  int 是  可见范围：1-全部可见、2-仅自己可见、3-已删除
   */
  static Future playbackSetVisible(int visibleScope, String? roomId) {
    return HttpManager.getInstance().post(
      Address.playbackSetVisible,
      params: {"visibleScope": visibleScope, "roomId": roomId},
    );
  }

  /*
   * 34. 违规回放申诉
- 接口地址：/v1/playback/appeal
   * roomId  string  是 直播间Id
   * reason  string  是 申诉理由
   */
  static Future playbackAppeal(String? roomId, String reason) {
    return HttpManager.getInstance().post(
      Address.playbackAppeal,
      params: {"reason": reason, "roomId": roomId},
    );
  }

  /*
   * 35. 是否完成了回放上诉
- 接口地址：/v1/playback/is_appeal
   * roomId  string  是 直播间Id
   */
  static Future playbackIsAppeal(String? roomId) {
    return HttpManager.getInstance().get(
      Address.playbackIsAppeal,
      params: {"roomId": roomId},
    );
  }

  /*
   * 36. 获取直播间带货地址
- 接口地址：/v1/live/commerce/:roomId
- 请求方式：GET
   */
  static Future liveCommerce(String roomId) {
    return HttpManager.getInstance().get(Address.liveCommerce + roomId);
  }

  /*
   * 38. 获取直播间概要信息
- 接口地址：/v1/live/simple/:roomId
- 请求方式：GET
   */
  static Future liveSimple(String roomId) {
    return HttpManager.getInstance().get(Address.liveSimple + roomId);
  }

  /*
   * 39. 上报直播间屏幕尺寸
- 接口地址：/v1/live/screen_size
- 请求方式：POST
roomId string 是直播间Id
width int 是 屏幕宽
height int 是 屏幕高
   */
  static Future liveScreenSize(String? roomId, int width, int height) {
    return HttpManager.getInstance().post(
      Address.liveScreenSize,
      params: {
        "roomId": roomId,
        "width": width,
        "height": height,
      },
    );
  }

  /*
   * 42. 获取我的直播间排名
   * - 接口地址：/v1/online/my_rank/:roomId
- 请求方式：GET
* roomId string 是 直播间Id
   */
  static Future onlineMyRank(String roomId) {
    return HttpManager.getInstance().get(Address.onlineMyRank + roomId);
  }

  // 21. 直播间统计数据
  // - 接口地址：/v1/live/data/:roomId
  // - 请求方式：GET
  static Future liveStatistics(String roomId) {
    return HttpManager.getInstance().get(Address.liveStatistics + roomId);
  }

  /// ======================直播带货======================
  // 43. 获取直播间带货信息（直播带货2.0）
  // - 接口地址：/v1/live/commerce2/:roomId
  // - 请求方式：GET
  static Future commerce2(String roomId) {
    return HttpManager.getInstance()
        .get(Address.commerce2 + roomId, isToastShow: false);
  }

  // 44. 是否是直播小助手
  // - 接口地址：/v1/live/is_assistant/:roomId
  // - 请求方式：GET
  static Future isAssistant(String roomId) {
    return HttpManager.getInstance().get(Address.isAssistant + roomId);
  }

  // 45. 主播是否具备带货能力
  // - 接口地址：/v1/anchor/has_commerce
  // - 请求方式：GET
  static Future hasCommerce() {
    return HttpManager.getInstance().get(Address.hasCommerce);
  }

  // 46. 查询店铺商品列表
  // - 接口地址：/v1/shop/goods_list
  // roomId string 是 直播间Id
  // keyword string 否 搜索关键词
  // isLive boolean 是 是否只查询直播商品
  // pageNum int 是 页码
  // pageSize int 是 分页大小，最大值50
  static Future shopGoodsList(
      {String? keyword,
      bool? isLive,
      int? pageNum,
      required String roomId}) async {
    return HttpManager.getInstance().get(
      Address.shopGoodsList,
      params: {
        "roomId": roomId,
        "keyword": keyword,
        "isLive": isLive,
        "pageNum": pageNum,
        "pageSize": 20,
      },
    );
  }

  // 47. 获取商品详情
  // - 接口地址：/v1/shop/goods_detail
  static Future shopGoodsDetail(int? shopId, int? itemId) async {
    if (shopId == null) {
      fbApi.fbLogger.warning('店铺id为空，获取商品详情失败');
      return {};
    }
    return HttpManager.getInstance().get(Address.shopGoodsDetail, params: {
      "itemId": itemId,
      "shopId": shopId,
    });
  }

  // 48. 查询直播间商品列表
  // - 接口地址：/v1/live/goods/list
  static Future liveGoodsList(int pageNum, String roomId) {
    return HttpManager.getInstance().get(Address.liveGoodsList, params: {
      "roomId": roomId,
      "pageNum": pageNum,
      "pageSize": 20,
    });
  }

  // 49. 新增直播间商品
  // - 接口地址：/v1/live/goods/add
  static Future liveGoodsAdd(List<int?> itemIds, String roomId) {
    return HttpManager.getInstance().post(Address.liveGoodsAdd, params: {
      "roomId": roomId,
      "itemIds": itemIds,
    });
  }

  // 50. 移除直播间商品
  // - 接口地址：/v1/live/goods/remove
  static Future liveGoodsRemove(List<int?> itemIds, String roomId) {
    return HttpManager.getInstance().post(Address.liveGoodsRemove, params: {
      "roomId": roomId,
      "itemIds": itemIds,
    });
  }

  // 51. 推荐直播间商品
  // - 接口地址：/v1/live/goods/recommend
  static Future liveGoodsRecommend(String? roomId, int? itemId, int index) {
    return HttpManager.getInstance().post(
      Address.liveGoodsRecommend,
      params: {
        "roomId": roomId,
        "itemId": itemId,
        "index": index,
      },
    );
  }

  // 52. 获取直播间推荐商品
  // - 接口地址：/v1/live/goods/recommend
  static Future liveGoodsGetRecommend(String roomId) {
    return HttpManager.getInstance().get(
      Address.liveGoodsGetRecommend,
      params: {"roomId": roomId},
      isToastShow: false,
    );
  }

  // 53. 获取直播间商品数量
  // - 接口地址：/v1/live/goods/count
  static Future liveGoodsGetCount(String roomId) {
    return HttpManager.getInstance().get(
      Address.liveGoodsGetCount,
      params: {"roomId": roomId},
    );
  }

  // 54. 查询店铺优惠券列表
  // - 接口地址：/v1/shop/coupon_list
  static Future shopCouponList(
      {int? couponType, int? pageNum, required String roomId}) {
    return HttpManager.getInstance().get(
      Address.shopCouponList,
      params: {
        "roomId": roomId,
        "couponType": couponType == 0 ? null : couponType,
        "pageNum": pageNum,
        "pageSize": 20,
      },
    );
  }

  // 55. 直播间优惠券列表
  // - 接口地址：/v1/live/coupon/list
  static Future liveCouponList(int couponType, int pageNum, String roomId) {
    return HttpManager.getInstance().get(
      Address.liveCouponList,
      params: {
        "roomId": roomId,
        "pageNum": pageNum,
        "pageSize": 6,
        "couponType": couponType == 0 ? null : couponType,
      },
    );
  }

  // 56. 新增直播间优惠券
  // - 接口地址：/v1/live/coupon/add
  static Future liveCouponAdd(List<int?> activityIds, String roomId) {
    return HttpManager.getInstance().post(
      Address.liveCouponAdd,
      params: {
        "roomId": roomId,
        "activityIds": activityIds,
      },
    );
  }

  // 57. 移除直播间优惠券
  // - 接口地址：/v1/live/coupon/remove
  static Future liveCouponRemove(List<int?> activityIds, String roomId) {
    return HttpManager.getInstance().post(
      Address.liveCouponRemove,
      params: {
        "roomId": roomId,
        "activityIds": activityIds,
      },
    );
  }

  // 58. 获取直播间优惠券数量
  // - 接口地址：/v1/live/coupon/count
  static Future liveCouponCount(int couponType, String roomId) {
    return HttpManager.getInstance().get(
      Address.liveCouponCount,
      params: {
        "roomId": roomId,
        "couponType": couponType == 0 ? null : couponType,
      },
    );
  }

  // 59. 获取优惠券最新库存
  // - 接口地址：/v1/shop/coupon_stock
  static Future shopCouponStock(int? shopId, int? activityId) {
    return HttpManager.getInstance().get(
      Address.shopCouponStock,
      params: {
        "shopId": shopId,
        "activityId": activityId,
      },
    );
  }

  // 60. 用户领取直播间优惠券
  // - 接口地址：/v1/live/coupon/send
  static Future liveCouponSend(int? activityId, String roomId) {
    return HttpManager.getInstance().post(
      Address.liveCouponSend,
      params: {
        "roomId": roomId,
        "activityId": activityId,
      },
    );
  }

  // 61. 向购物车添加商品
  // - 接口地址：/v1/live/cart/add
  static Future liveCartAdd(
      int? itemId, int? skuId, int num, List<String?> messages, String roomId) {
    return HttpManager.getInstance().post(
      Address.liveCartAdd,
      params: {
        "roomId": roomId,
        "itemId": itemId,
        "skuId": skuId,
        "num": num,
        "messages": messages,
      },
    );
  }

  // 62. 获取购物车商品数量
  // - 接口地址：/v1/live/cart/count
  static Future liveCartCount(String roomId) {
    return HttpManager.getInstance().get(
      Address.liveCartCount,
      params: {"roomId": roomId},
      isToastShow: false,
    );
  }

  // 63. 商品立即下单
  // - 接口地址：/v1/live/goods/order
  static Future liveGoodsOrder(int? itemId, int? skuId, int num,
      List<String?> messages, String roomId) async {
    /// mock
    // return Future.value({"jumpUrl": "1", "code": 200});
    return HttpManager.getInstance().post(
      Address.liveGoodsOrder,
      params: {
        "roomId": roomId,
        "itemId": itemId,
        "skuId": skuId,
        "num": num,
        "messages": messages,
      },
    );
  }

  // 64. 检查用户是否完成有赞店铺授权
  // - 接口地址：/v1/youzan/check_auth
  static Future youZanCheckAuth(int? shopId) {
    return HttpManager.getInstance().get(
      Address.youZanCheckAuth,
      params: {
        "shopId": shopId,
      },
    );
  }

  // 65. 获取ZEGO拉流模式
  // - 接口地址：/v1/zego/play_mode
  static Future zegoPlayMode() {
    return HttpManager.getInstance().get(Address.zegoPlayMode);
  }

  // 66. 【V3】刷新优惠券库存
  // - 接口地址：/v1/live/coupon/refresh_stock
  static Future couponRefreshStock(String roomId) {
    return HttpManager.getInstance().post(
      Address.couponRefreshStock,
      params: {"roomId": roomId},
    );
  }

  // 67. 【V3】上报用户进入直播回放
  // - 接口地址：/v1/playback/enter
  static Future playbackEnter(String? userId, String? roomId) {
    return HttpManager.getInstance().post(
      Address.playbackEnter,
      params: {
        "roomId": roomId,
        "userId": userId,
      },
    );
  }

  // 68. 【V3】上报用户退出直播回放
  // - 接口地址：/v1/playback/exit
  static Future playbackExit(
      String? userId, String? roomId, int? watchSeconds) {
    return HttpManager.getInstance().post(Address.playbackExit, params: {
      "roomId": roomId,
      "userId": userId,
      "watchSeconds": watchSeconds,
    });
  }

  // 69. 【V3】取消直播间推荐商品
  // - 接口地址：/v1/live/goods/cancel_recommend
  static Future goodsCancelRecommend(String? roomId) {
    return HttpManager.getInstance()
        .post(Address.goodsCancelRecommend, params: {
      "roomId": roomId,
    });
  }

  // 70. 【V3】查询主播生成中的回放列表
  // - 接口地址：/v1/playback/creating_list
  static Future playbackCreatingList(String? channelId) {
    return HttpManager.getInstance().get(Address.playbackCreatingList, params: {
      "channelId": channelId,
    });
  }
}
