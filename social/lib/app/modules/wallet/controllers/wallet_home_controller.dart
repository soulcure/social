/*
 * @FilePath       : /social/lib/app/modules/wallet/controllers/wallet_home_controller.dart
 * 
 * @Info           : 业务处理控制器：钱包首页
 * 
 * @Author         : Whiskee Chan
 * @Date           : 2022-04-07 15:46:48
 * @Version        : 1.0.0
 * 
 * Copyright 2022 iDreamSky FanBook, All Rights Reserved.
 * 
 * @LastEditors    : Whiskee Chan
 * @LastEditTime   : 2022-04-21 10:29:35
 * 
 */

import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:im/api/wallet_api.dart';
import 'package:im/app/modules/wallet/models/wallet_home_model.dart';
import 'package:im/global.dart';
import 'package:im/services/server_side_configuration.dart';

const String WALLER_HOME_PARAM_USER_ID = "waller_user_id";
const String WALLER_HOME_PARAM_USER_NAME = "waller_user_name";
const String WALLER_HOME_PARAM_IS_CHINESE_MOBILE = "waller_is_chinese_mobile";

class WalletHomeController extends GetxController {
  //  用户id
  final String userId;
  //  用户信息
  final String userName;
  //  是否是中国区域用户
  final bool isChineseMobile;

  //  钱包首页数据
  WalletHomeModel wallet;

  //  是否开始请求数据
  bool isStartRequest = true;

  /// get：
  //  - 是否已经实名认证: 如果为空，说明请求的数据
  bool get isVerified => wallet?.nftUserId?.isNotEmpty;
  //  - 是否是自己的钱包
  bool get isOwnWallet => userId == Global.user.id;

  WalletHomeController({
    @required this.userId,
    @required this.userName,
    @required this.isChineseMobile,
  });

  @override
  void onInit() {
    super.onInit();
    // 藏品信息不包含购买者的id和昵称需要手动添加
    updateWallet();
  }

  // ====== Method - Self : Static ====== //

  /// 入参模版
  static Map<String, dynamic> inputParams({
    String userId = "",
    String userName = "",
    bool isChineseMobile = true,
  }) =>
      {
        WALLER_HOME_PARAM_USER_ID: userId,
        WALLER_HOME_PARAM_USER_NAME: userName,
        WALLER_HOME_PARAM_IS_CHINESE_MOBILE: isChineseMobile,
      };

  // ====== Method - Self : Public ====== //

  /// 更新钱包数据
  Future updateWallet() async {
    //  实时展示loading视图
    isStartRequest = true;
    update();
    //  获取钱包数据
    wallet = await WalletApi.queryWalletHomeData(userId: userId);
    //  延迟200ms
    await Future.delayed(const Duration(milliseconds: 200));
    isStartRequest = false;
    // 藏品信息不包含购买者的id和昵称需要手动添加
    wallet?.collects?.forEach((collect) {
      collect.collectorId = userId;
      collect.collectorName = userName;
    });
    //  如果是自己的钱包就要更新应用配置-钱包信息数据
    if (userId == Global.user.id) {
      ServerSideConfiguration.to.nftId = wallet?.nftUserId;
      ServerSideConfiguration.to.nftCollectTotal = wallet?.collectTotal ?? "0";
    }
    update();
  }
}
