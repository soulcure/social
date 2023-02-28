/*
 * @FilePath       : /social/lib/api/wallet_api.dart
 * 
 * @Info           : 网络接口：钱包
 * 
 * @Author         : Whiskee Chan
 * @Date           : 2022-04-12 19:11:08
 * @Version        : 1.0.0
 * 
 * Copyright 2022 iDreamSky FanBook, All Rights Reserved.
 * 
 * @LastEditors    : Whiskee Chan
 * @LastEditTime   : 2022-04-18 20:48:47
 * 
 */

import 'package:im/app/modules/wallet/models/wallet_collect_model.dart';
import 'package:im/app/modules/wallet/models/wallet_home_model.dart';
import 'package:im/core/http_middleware/http.dart';
import 'package:im/loggers.dart';

class WalletApi {
  /// 获取钱包首页数据
  static Future<WalletHomeModel> queryWalletHomeData({
    String userId,
  }) async {
    final res = await Http.request(
      "/api/wallet/detail",
      data: {
        'member_id': userId,
      },
    ).onError((error, stackTrace) {
      logger.warning(error);
      return null;
    });
    //  1、如果数据就返回空
    if (res == null) {
      return null;
    }
    //  2、数据不为空就转化为钱包模型
    return WalletHomeModel.fromMap(res['nft' ?? {}]);
  }

  /// 获取用户的钱包首页数据
  static Future<WalletHomeModel> queryUserWalletData({
    String userId,
  }) async {
    final res = await Http.request(
      "/api/wallet/dynamic",
      data: {
        'member_id': userId,
      },
    ).onError((error, stackTrace) {
      logger.warning(error);
      return null;
    });
    //  1、如果数据就返回空
    if (res == null) {
      return null;
    }
    //  2、数据不为空就转化为钱包模型
    return WalletHomeModel.fromMap(res['nft' ?? {}]);
  }

  /// 获取钱包-艺术藏品详情
  static Future<WalletCollectModel> queryWalletCollectData({
    String userId,
    String collectId,
  }) async {
    final res = await Http.request(
      "/api/wallet/collectDetail",
      data: {
        'member_id': userId,
        'nft_id': collectId,
      },
    ).onError((error, stackTrace) => {});
    return WalletCollectModel.fromMap(res);
  }
}
