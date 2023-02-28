import 'package:get/get.dart';
import 'package:im/app/modules/document_online/select/controllers/document_select_controller.dart';

class DocumentSelectBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<DocumentSelectController>(
      () => DocumentSelectController(),
    );
  }
}
