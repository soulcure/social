import 'package:get/get.dart';

import '../controllers/direct_message_controller.dart';

class DirectMessageBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<DirectMessageController>(
      () => DirectMessageController(),
    );
  }
}
