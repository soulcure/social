import 'package:get/get.dart';
import 'package:im/app/modules/black_list/controllers/black_list_controller.dart';

class BlackListBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<BlackListController>(
      () => BlackListController(),
    );
  }
}
