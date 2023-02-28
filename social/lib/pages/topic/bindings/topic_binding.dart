import 'package:get/get.dart';
import 'package:im/pages/topic/controllers/topic_controller.dart';

class TopicPageBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<TopicController>(() => TopicController());
  }
}
