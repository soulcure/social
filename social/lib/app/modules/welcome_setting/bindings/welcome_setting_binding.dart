import 'package:get/get.dart';

import '../controllers/welcome_setting_controller.dart';

class WelcomeSettingBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<WelcomeSettingController>(() {
      final String guildId = Get.parameters["guild_id"] ?? '';
      return WelcomeSettingController(guildId);
    });
  }
}
