import 'package:get/get.dart';
import 'package:im/app/modules/document_online/info/controllers/view_document_info_controller.dart';

class ViewDocumentInfoBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ViewDocumentInfoController>(
      () => ViewDocumentInfoController(),
    );
  }
}
