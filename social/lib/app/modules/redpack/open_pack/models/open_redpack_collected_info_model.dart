/*
 * @FilePath       : /social/lib/app/modules/redpack/open_pack/models/open_redpack_collected_info_model.dart
 * 
 * @Info           : 领取红包领取信息
 * 
 * @Author         : Whiskee Chan
 * @Date           : 2022-01-05 16:30:32
 * @Version        : 1.0.0
 * 
 * Copyright 2022 iDreamSky FanBook, All Rights Reserved.
 * 
 * @LastEditors    : Whiskee Chan
 * @LastEditTime   : 2022-01-17 20:59:15
 * 
 */

import 'package:im/app/modules/redpack/open_pack/models/open_redpack_collected_item_model.dart';
import 'package:im/app/modules/redpack/open_pack/models/open_redpack_detail_model.dart';

class OpenRedPackCollectedInfoModel {
  /// 红包状态
  /// - see [RedPackDetailStatus]
  final int status;

  /// 抢到的红包金额
  String collectedMoney;

  /// 红包总数
  final int totalNum;

  /// 已被抢红包数量
  final String hadCollectedNum;

  /// 已抢到到红包的总金额
  final String hadCollectedAmount;

  /// 下一页数据
  final String lastRedPackId;

  /// 领取红包的用户列表
  final List<OpenRedPackCollectedItemModel> items;

  OpenRedPackCollectedInfoModel({
    this.status = RedPackDetailStatus.NER_RED_PACK,
    this.collectedMoney = '0.00',
    this.totalNum = 0,
    this.hadCollectedNum = '0',
    this.hadCollectedAmount = '0.00',
    this.lastRedPackId = "0",
    this.items,
  });

  factory OpenRedPackCollectedInfoModel.fromJson(Map<String, dynamic> json) =>
      OpenRedPackCollectedInfoModel(
        status: json['status'] as int ?? RedPackDetailStatus.NER_RED_PACK,
        collectedMoney: (json['my_redbag_money'] ?? '0.00').toString(),
        totalNum: json['total_num'] as int ?? 1,
        hadCollectedNum: (json['had_catch_num'] ?? '0').toString(),
        hadCollectedAmount: (json['total_catch_money'] ?? '0.00').toString(),
        lastRedPackId: (json['last_sub_forder'] ?? '').toString(),
        items: (json['list'] as List)
            .map((item) => OpenRedPackCollectedItemModel.fromJson(item))
            .toList(),
      );
}
