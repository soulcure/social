import 'package:get/get.dart';

import '../controllers/send_code_controller.dart';

class SendCodeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SendCodeController>(
      () => SendCodeController(),
    );
  }
}
