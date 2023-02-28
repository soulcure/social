import 'package:get/get.dart';
import 'package:im/app/modules/document_online/controllers/online_document_controller.dart';

class OnlineDocumentBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<OnlineDocumentController>(
      () => OnlineDocumentController(),
    );
  }
}
