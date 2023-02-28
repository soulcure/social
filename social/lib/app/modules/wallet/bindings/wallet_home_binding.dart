/*
 * @FilePath       : /social/lib/app/modules/wallet/bindings/wallet_home_binding.dart
 * 
 * @Info           : 
 * 
 * @Author         : Whiskee Chan
 * @Date           : 2022-04-07 17:25:41
 * @Version        : 1.0.0
 * 
 * Copyright 2022 iDreamSky FanBook, All Rights Reserved.
 * 
 * @LastEditors    : Whiskee Chan
 * @LastEditTime   : 2022-04-20 10:17:57
 * 
 */

import 'package:get/get.dart';
import 'package:get/get_instance/src/bindings_interface.dart';
import 'package:im/app/modules/wallet/controllers/wallet_home_controller.dart';

class WalletHomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<WalletHomeController>(() {
      final Map<String, dynamic> params =
          Get.arguments ?? WalletHomeController.inputParams();
      return WalletHomeController(
        userId: params[WALLER_HOME_PARAM_USER_ID],
        userName: params[WALLER_HOME_PARAM_USER_NAME],
        isChineseMobile: params[WALLER_HOME_PARAM_IS_CHINESE_MOBILE],
      );
    });
  }
}
