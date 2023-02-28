import 'dart:collection';
import 'package:flutter/cupertino.dart';
import 'package:fb_live_flutter/live/api/fblive_provider.dart';
import 'package:fb_live_flutter/live/net/http_manager.dart';
import 'package:fb_live_flutter/live/net/Api.dart';
import 'package:fb_live_flutter/live/pages/other/link_loading_page.dart';

// class BaseAPIResponse {
//   int code;
//   int msg;
//   dynamic data;
// }
//
// class JiGoResponse extends BaseAPIResponse {
//   JiGoResponse fromJson(Map json) {}
// }

class AccountDetailAdminView {
  int? id;
  String? bizId;
  String? nickName;
  String? avatarUrl;
  String? merchandiseName;
  int? tradeType;
  double? amount;
  DateTime? createdAt;

  AccountDetailAdminView(Map json) {
    id = json["id"];
    bizId = json["bizId"];
    nickName = json["nickName"];
    avatarUrl = json["avatarUrl"];
    tradeType = json["tradeType"];
    amount = double.parse(json["amount"]);
    merchandiseName = json["tradeDesc"];
    createdAt = DateTime.parse(json["createdAt"]);
  }
}

class JiGouLiveAPI {
  static Future tradeList(
    int tradeType,
    String memberId,
    int pageNum, {
    DateTime? startTime,
    DateTime? endTime,
    int? pageSize,
  }) async {
    final params = SplayTreeMap<String, dynamic>();
    params["tradeType"] = tradeType; //类型：1=充值、2=打赏礼物、3=直播收入
    params["memberId"] = memberId;
    params["pageNum"] = pageNum;
    params["startTime"] = startTime;
    params["endTime"] = endTime;
    params["pageSize"] = pageSize;

    return HttpManager.getInstance()
        .get("/v1/trade/page_list_account_detail", params: params);
  }

  /// 查询虚拟币交易记录详情
  static Future tradeDetail(String detailId) async {
    final params = SplayTreeMap<String, dynamic>();
    // params["detailId"] = detailId;
    return HttpManager.getInstance()
        .get("/v1/trade/detail/$detailId", params: params);
  }

  /// 查询用户账户信息
  static Future accountInfo() async {
    final params = SplayTreeMap<String, dynamic>();
    return HttpManager.getInstance().get("/v1/account/info", params: params);
  }

  /// 获取直播间基础信息
  static Future getLiveRoomInfo(String roomId) => Api.getRoomInfo(roomId);

  /// 根据服务器id，获取正在直播的统计数据
  static Future getLivingChannels(String guildId) {
    return HttpManager.getInstance().get('/v1/living/stat/$guildId');
  }

  /// 根据服务器id,获取直播间概要信息
  static Future getRoomSimpleInfo(String roomId) {
    return HttpManager.getInstance().get('/v1/live/simple/$roomId');
  }

  /*
  * 链接跳转直播
  *
  * @param roomId 房间id
  * */
  static void linkJumpLive(BuildContext context, String roomId) {
    fbApi.push(context, LinkLoadingPage(roomId), "/liveRoom");
  }
}
