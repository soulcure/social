import 'package:get/get.dart';
import 'package:im/app/modules/mute/controllers/mute_list_controller.dart';

class MuteListBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<MuteListController>(
      () => MuteListController(),
    );
  }
}
