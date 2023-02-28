/*
 * @FilePath       : /social/lib/app/modules/redpack/open_pack/binding/open_redpack_binding.dart
 * 
 * @Info           : 
 * 
 * @Author         : Whiskee Chan
 * @Date           : 2022-01-18 23:30:27
 * @Version        : 1.0.0
 * 
 * Copyright 2022 iDreamSky FanBook, All Rights Reserved.
 * 
 * @LastEditors    : Whiskee Chan
 * @LastEditTime   : 2022-01-18 23:55:27
 * 
 */
import 'package:get/get.dart';
import 'package:im/app/modules/redpack/open_pack/controllers/open_redpack_controller.dart';

class OpenRedPackDetailBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<OpenRedPackController>(
      () => OpenRedPackController(
          context: Get.context, redPackDetail: Get.arguments),
    );
  }
}
