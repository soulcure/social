import 'package:get/get.dart';

import '../controllers/dynamic_view_preview_controller.dart';

class DynamicViewPreviewBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<DynamicViewPreviewController>(
      () => DynamicViewPreviewController(),
    );
  }
}
