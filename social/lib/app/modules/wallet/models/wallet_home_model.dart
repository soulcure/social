/*
 * @FilePath       : /social/lib/app/modules/wallet/models/wallet_home_model.dart
 * 
 * @Info           : 数据模型：钱包首页数据
 * 
 * @Author         : Whiskee Chan
 * @Date           : 2022-04-12 19:43:54
 * @Version        : 1.0.0
 * 
 * Copyright 2022 iDreamSky FanBook, All Rights Reserved.
 * 
 * @LastEditors    : Whiskee Chan
 * @LastEditTime   : 2022-04-15 20:25:14
 * 
 */

import 'package:im/app/modules/wallet/models/wallet_collect_model.dart';

class WalletHomeModel {
  //  用户id
  String userId;
  //  钱包id
  String nftUserId;
  //  钱包地址
  String address;
  //  艺术藏品收藏总数量
  String collectTotal;
  //  艺术藏品数据
  List<WalletCollectModel> collects;

  WalletHomeModel({
    this.userId = "",
    this.nftUserId = "",
    this.address = "",
    this.collectTotal = "0",
    this.collects,
  });

  // ====== Method - Self : Factory ====== //

  /// data转model
  factory WalletHomeModel.fromMap(Map<String, dynamic> map) => WalletHomeModel(
        userId: map['user_id'] as String ?? '',
        nftUserId: map['nft_user_id'] as String ?? '',
        address: map['address'] as String ?? '',
        collectTotal: map['total'] as String ?? '0',
        collects: (map['list'] as List ?? [])
            .map((item) => WalletCollectModel.fromMap(item))
            .toList(),
      );

  // ====== Method - Self : Public ====== //

  //  data转model
  void copyWith(WalletHomeModel wallet) {
    userId = wallet.userId;
    nftUserId = wallet.nftUserId;
    address = wallet.address;
    collectTotal = wallet.collectTotal;
    collects = wallet.collects;
  }
}
