import 'package:get/get.dart';

import '../controllers/bind_payment_controller.dart';

class BindPaymentBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<BindPaymentController>(
      () => BindPaymentController(),
    );
  }
}
