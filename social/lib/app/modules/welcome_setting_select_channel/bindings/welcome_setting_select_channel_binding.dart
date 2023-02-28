import 'package:get/get.dart';
import 'package:im/app/modules/welcome_setting/controllers/welcome_setting_controller.dart';

class WelcomeSettingSelectChannelBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<WelcomeSettingController>(() {
      final String guildId = Get.parameters["guild_id"] ?? '';
      return WelcomeSettingController(guildId);
    });
  }
}
