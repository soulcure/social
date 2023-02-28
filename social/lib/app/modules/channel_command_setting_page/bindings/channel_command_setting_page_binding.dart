import 'package:get/get.dart';
import 'package:im/pages/home/model/chat_target_model.dart';

import '../controllers/channel_command_setting_page_controller.dart';

class ChannelCommandSettingPageBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ChannelCommandSettingPageController>(
      () => ChannelCommandSettingPageController(Get.arguments as ChatChannel),
    );
  }
}
