/*
 * @FilePath       : /social/lib/app/modules/redpack/open_pack/models/open_redpack_collected_item_model copy.dart
 * 
 * @Info           : 领取红包已领取人信息数据
 * 
 * @Author         : Whiskee Chan
 * @Date           : 2022-01-05 16:30:32
 * @Version        : 1.0.0
 * 
 * Copyright 2022 iDreamSky FanBook, All Rights Reserved.
 * 
 * @LastEditors    : Whiskee Chan
 * @LastEditTime   : 2022-01-13 15:04:23
 * 
 */

class OpenRedPackCollectedItemModel  {
  /// 已领取人id
  String userId;

  /// 已领取人名称
  String userName;

  /// 已领取人头像
  String userHeader;

  /// 领取时间
  int collectTime;

  /// 领取金额
  String money;

  /// 是否是手气最佳; 1 = 最佳手气，2 or other = 不是
  int isLuckGay;

  OpenRedPackCollectedItemModel({
    this.userId = '',
    this.userName = '',
    this.userHeader = '',
    this.collectTime = 0,
    this.money = '',
    this.isLuckGay = 0,
  });

  factory OpenRedPackCollectedItemModel.fromJson(Map<String, dynamic> json) =>
      OpenRedPackCollectedItemModel(
        userId: (json['user_id'] ?? '').toString(),
        userName: (json['nickname'] ?? '').toString(),
        userHeader: (json['avatar'] ?? '').toString(),
        collectTime: json['catch_time'] as int ?? 0,
        money: (json['sub_money'] ?? 0).toString(),
        isLuckGay: json['is_max'] as int ?? 0,
      );
}
