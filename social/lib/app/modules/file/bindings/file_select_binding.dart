import 'package:get/get.dart';

import '../controllers/file_select_controller.dart';

class FileSelectBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<FileSelectController>(
      () => FileSelectController(),
    );
  }
}
