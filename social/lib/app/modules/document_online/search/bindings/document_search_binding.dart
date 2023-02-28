import 'package:get/get.dart';
import 'package:im/app/modules/document_online/search/controllers/document_search_controller.dart';

class DocumentSearchBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<DocumentSearchController>(
      () => DocumentSearchController(),
    );
  }
}
