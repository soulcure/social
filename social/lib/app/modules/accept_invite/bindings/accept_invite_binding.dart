import 'package:get/get.dart';

import '../controllers/accept_invite_controller.dart';

class AcceptInviteBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AcceptInviteController>(
      () => AcceptInviteController(),
    );
  }
}
