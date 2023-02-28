/*
 * @FilePath       : /social/lib/app/modules/wallet/models/wallet_collect_model.dart
 * 
 * @Info           : 数据模型：钱包 - 藏品信息
 * 
 * @Author         : Whiskee Chan
 * @Date           : 2022-04-07 15:52:05
 * @Version        : 1.0.0
 * 
 * Copyright 2022 iDreamSky FanBook, All Rights Reserved.
 * 
 * @LastEditors    : Whiskee Chan
 * @LastEditTime   : 2022-04-20 15:23:39
 * 
 */

import 'package:date_format/date_format.dart';

class WalletCollectModel {
  //  收藏家id
  String collectorId = "";
  //  藏品id
  String nftId = "";
  //  藏品名称
  String name = "";
  //  藏品展示图（地址）
  String displayUrl = "";
  //  藏品入手序号（第几位买入）
  int seriesIndex = 0;
  //  出品方(艺术残品作者/单位/组织)
  String author = "";
  //  唯一编码
  String seriesId = "";
  //  作品Hash
  String hash = "";
  //  交易Hash
  String txHash = "";
  //  认证时间
  int chainCreatedAt;

  /// 非Json字段：
  //  - 收藏家名称
  String collectorName = "";

  /// 扩展属性：
  //  - 获取认证时间格式化字符
  String get verifyDateStr => formatDate(
      DateTime.fromMillisecondsSinceEpoch(chainCreatedAt).toLocal(),
      [yyyy, "-", mm, "-", dd]);

  WalletCollectModel({
    this.collectorId = "",
    this.nftId = "",
    this.name = "",
    this.displayUrl = "",
    this.seriesIndex = 0,
    this.author = "",
    this.seriesId = "",
    this.hash = "",
    this.txHash = "",
    this.chainCreatedAt = 0,
  });

  factory WalletCollectModel.fromMap(Map<String, dynamic> map) =>
      WalletCollectModel(
        collectorId: map['user_id'] as String ?? '',
        nftId: map['nft_id'] as String ?? '',
        name: map['name'] as String ?? '',
        displayUrl: map['display_url'] as String ?? '',
        seriesIndex: map['series_index'] as int ?? 0,
        author: map['author'] as String ?? '',
        seriesId: map['series_id'] as String ?? '',
        hash: map['hash'] as String ?? '',
        txHash: map['tx_hash'] as String ?? '',
        chainCreatedAt: map['chain_timestamp'] as int ?? 0,
      );
}
