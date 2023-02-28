import 'package:get/get.dart';

import '../controllers/circle_detail_controller.dart';

class CircleDetailBinding extends Bindings {
  /// [CircleDetailRouter.findAndRemoveExistingDetailPage] 情况特殊，手动销毁
  /// 了 controller，因此如果这里还有其他 controller 依赖，需要同步修改那边的 delete 代码
  @override
  void dependencies() {
    Get.lazyPut<CircleDetailController>(
      () => CircleDetailController(Get.arguments),
      tag: (Get.arguments as CircleDetailData).postId,
    );
  }
}
