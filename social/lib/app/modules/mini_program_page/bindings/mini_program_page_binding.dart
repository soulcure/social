import 'package:get/get.dart';

import '../controllers/mini_program_page_controller.dart';

class MiniProgramPageBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<MiniProgramPageController>(
      () => MiniProgramPageController(),
    );
  }
}
