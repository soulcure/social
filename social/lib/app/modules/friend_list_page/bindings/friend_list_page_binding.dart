import 'package:get/get.dart';

import '../controllers/friend_list_page_controller.dart';

class FriendListPageBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<FriendListPageController>(
      () => FriendListPageController(),
    );
  }
}
