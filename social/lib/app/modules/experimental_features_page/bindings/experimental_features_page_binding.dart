import 'package:get/get.dart';

import '../controllers/experimental_features_page_controller.dart';

class ExperimentalFeaturesPageBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ExperimentalFeaturesPageController>(
      () => ExperimentalFeaturesPageController(),
    );
  }
}
