/*
 * @FilePath       : /social/lib/app/modules/redpack/open_pack/models/open_redpack_detail_model.dart
 * 
 * @Info           : 领取红包详情数据
 * 
 * @Author         : Whiskee Chan
 * @Date           : 2022-01-05 16:30:32
 * @Version        : 1.0.0
 * 
 * Copyright 2022 iDreamSky FanBook, All Rights Reserved.
 * 
 * @LastEditors    : Whiskee Chan
 * @LastEditTime   : 2022-01-17 20:19:37
 * 
 */

import 'package:im/app/modules/redpack/open_pack/models/open_redpack_collected_item_model.dart';
import 'package:im/pages/home/json/text_chat_json.dart';

/// 红包详情状态
class RedPackDetailStatus {
  static const int NER_RED_PACK = 0; //0 未开封
  static const int COLLECTING = 1; //1 进行中
  static const int OVER_DATE = 2; //2 超时结束
  static const int HAD_BEEN_COLLECTED = 3; //3 抢完结束
}

class OpenRedPackDetailModel {
  MessageEntity messageEntity;

  /// 服务器id
  String guildId;

  /// 频道id
  String channelId;

  /// 消息id
  String messageId;

  /// 红包id，对应服务端参数forder
  String redPackId;

  /// 红包类型: 1：群手气，2：群普通，3：私信红包
  int type;

  /// 红包发送者id
  String userId;

  /// 红包发送者名称
  String userName;

  /// 红包发送者头像
  String userHeader;

  /// 是否是自己的红包
  bool isOwner;

  /// 红包备注
  String remark;

  /// 红包总金额
  String amount;

  /// 当前用户领取到的金额
  String collectedMoney;

  /// 最大可领取红包数量,最低1个，不能少于1个
  int maxCollectNum;

  /// 已经收集红包数量
  String hadCollectedNum;

  /// 已经收集红包总金额
  String hadCollectedAmount;

  /// 红包详情状态
  int detailStatus;

  /// 领取红包的用户列表
  List<OpenRedPackCollectedItemModel> detailList;

  /// 是否需要动画效果
  bool isNeedAnimation = false;

  /// 子红包数据
  String lastRedPackId = "0";

  /// 总领取红包用户数量
  bool hadNextPage;

  //*========= Properties - Get *=========*//

  /// 是否是私信红包
  bool get isDmRedPack => type == 3;

  /// 是否是拼手气红包
  bool get isLuckRedPack => type == 1;

  /// 是否已经领取完了
  bool get hadAllCollected => maxCollectNum == int.parse(hadCollectedNum);

  OpenRedPackDetailModel({
    this.messageEntity,
    this.guildId = '',
    this.channelId = '',
    this.messageId = '',
    this.redPackId = '',
    this.type = 0,
    this.userId,
    this.userName = '',
    this.userHeader = '',
    this.isOwner = false,
    this.remark = '',
    this.amount = '',
    this.collectedMoney = '0.00',
    this.maxCollectNum = 1,
    this.hadCollectedNum = '0',
    this.hadCollectedAmount = '0.00',
    this.detailList,
  });
}
