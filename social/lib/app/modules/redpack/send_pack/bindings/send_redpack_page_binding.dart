import 'package:get/get.dart';
import 'package:im/app/modules/redpack/send_pack/controllers/send_redpack_controller.dart';

class SendRedPackPageBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SendRedPackController>(
      () => SendRedPackController(),
    );
  }
}
