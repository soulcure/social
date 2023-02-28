/*
 * @FilePath       : /social/lib/app/modules/wallet/controllers/user_dao_card_controller.dart
 * 
 * @Info           : 业务逻辑：钱包 - 藏品详情
 * 
 * @Author         : Whiskee Chan
 * @Date           : 2022-04-07 17:36:12
 * @Version        : 1.0.0
 * 
 * Copyright 2022 iDreamSky FanBook, All Rights Reserved.
 * 
 * @LastEditors    : Whiskee Chan
 * @LastEditTime   : 2022-05-05 15:24:51
 * 
 */

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/api/wallet_api.dart';
import 'package:im/app/modules/wallet/models/wallet_home_model.dart';
import 'package:sliding_sheet/sliding_sheet.dart';

class UserDaoCardController extends GetxController {
  //  -
  final BuildContext context;

  //  - 用户id
  final String userId;

  /// - 藏品信息
  WalletHomeModel collect;

  UserDaoCardController(this.context, this.userId);

  @override
  void onInit() {
    super.onInit();
    _getCollect();
  }

  Future<void> _getCollect() async {
    collect = await WalletApi.queryUserWalletData(userId: userId);
    //  （参考UserRoleCard）卡片会因为内部视图比用户卡片弹窗更早的绘制导致弹窗卡片高度会出现问题，需要延迟展示，60版本的用户卡片有重构，合并至60版本后可去掉
    await Future.delayed(const Duration(milliseconds: 350));
    if (isClosed) return;
    update();
    //  重绘SheetDialog的高度
    SheetController.of(context)?.rebuild();
    // unawaited(SheetController.of(context)?.expand());
  }
}
