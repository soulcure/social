import 'package:get/get.dart';

import '../controllers/task_introduction_ceremony_controller.dart';

class TaskIntroductionCeremonyBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<TaskIntroductionCeremonyController>(
      () => TaskIntroductionCeremonyController(),
    );
  }
}
