/*
 * @FilePath       : /social/lib/app/modules/wallet/bindings/wallet_collect_detail_binding.dart
 * 
 * @Info           : 
 * 
 * @Author         : Whiskee Chan
 * @Date           : 2022-04-07 17:37:04
 * @Version        : 1.0.0
 * 
 * Copyright 2022 iDreamSky FanBook, All Rights Reserved.
 * 
 * @LastEditors    : Whiskee Chan
 * @LastEditTime   : 2022-04-07 21:47:30
 * 
 */

import 'package:get/get.dart';
import 'package:im/app/modules/wallet/controllers/wallet_collect_detail_controller.dart';
import 'package:im/app/modules/wallet/models/wallet_collect_model.dart';

class WalletCollectDetailBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<WalletCollectDetailController>(
      () =>
          WalletCollectDetailController(Get.arguments ?? WalletCollectModel()),
    );
  }
}
