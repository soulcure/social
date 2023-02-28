import 'package:get/get.dart';

import '../controllers/private_channel_access_page_controller.dart';

class PrivateChannelAccessPageBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PrivateChannelAccessPageController>(
      () => PrivateChannelAccessPageController(),
    );
  }
}
