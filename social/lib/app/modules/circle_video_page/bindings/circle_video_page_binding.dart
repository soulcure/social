import 'package:get/get.dart';

import '../controllers/circle_video_page_controller.dart';

class CircleVideoPageBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CircleVideoPageController>(
      () => CircleVideoPageController(Get.arguments),
    );
  }
}
