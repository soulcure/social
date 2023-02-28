import 'package:get/get.dart';

import '../controllers/config_guild_assistant_page_controller.dart';

class ConfigGuildAssistantPageBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ConfigGuildAssistantPageController>(
      () {
        return ConfigGuildAssistantPageController(Get.arguments);
      },
    );
  }
}
