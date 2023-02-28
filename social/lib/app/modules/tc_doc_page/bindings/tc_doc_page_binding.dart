import 'package:get/get.dart';

import '../controllers/tc_doc_page_controller.dart';

class TcDocPageBinding extends Bindings {
  @override
  void dependencies() {
    bool fromSelectPage = false;
    if (Get.arguments is Map && Get.arguments['fromSelectPage'] == true) {
      fromSelectPage = true;
    }
    Get.lazyPut<TcDocPageController>(
      () => TcDocPageController(fromSelectPage: fromSelectPage),
    );
  }
}
